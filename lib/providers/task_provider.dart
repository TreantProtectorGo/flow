import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/database_helper.dart';
import '../services/data_migration_helper.dart';
import '../services/sync_service.dart';

// Riverpod provider
final taskProvider = ChangeNotifierProvider<TaskProvider>((ref) {
  return TaskProvider();
});

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _currentTaskId; // 當前正在進行的任務ID
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Optional sync service — set by AuthProvider when user is signed in.
  SyncService? syncService;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get currentTaskId => _currentTaskId;

  // 獲取當前正在進行的任務
  Task? get currentTask {
    if (_currentTaskId == null) return null;

    try {
      return _tasks.firstWhere((task) => task.id == _currentTaskId);
    } catch (e) {
      // 如果找不到指定的任務，清除當前任務ID並返回null
      _currentTaskId = null;
      return null;
    }
  }

  List<Task> get pendingTasks =>
      _tasks.where((task) => task.status == TaskStatus.pending).toList();

  List<Task> get inProgressTasks =>
      _tasks.where((task) => task.status == TaskStatus.inProgress).toList();

  List<Task> get completedTasks =>
      _tasks.where((task) => task.status == TaskStatus.completed).toList();

  TaskProvider() {
    _initializeAndLoadTasks();
  }

  Future<void> _initializeAndLoadTasks() async {
    // 檢查是否需要資料遷移
    if (await DataMigrationHelper.needsMigration()) {
      debugPrint('🔄 需要執行資料遷移');
      try {
        await DataMigrationHelper.migrate();
      } catch (e) {
        debugPrint('❌ 資料遷移失敗，將繼續載入: $e');
      }
    }

    // 載入任務
    await _loadTasks();
  }

  /// Reload tasks from local DB. Called after remote sync applies changes.
  Future<void> reloadTasks() async {
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 從 SQLite 資料庫載入任務
      _tasks = await _db.getAllTasks();

      // 從 SharedPreferences 載入當前任務ID
      final prefs = await SharedPreferences.getInstance();
      _currentTaskId = prefs.getString('currentTaskId');

      // 按創建時間排序（資料庫查詢已排序，但保留以防萬一）
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('載入任務時發生錯誤: $e');
      _tasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      // SQLite 會自動保存，這裡只需保存當前任務ID
      final prefs = await SharedPreferences.getInstance();

      if (_currentTaskId != null) {
        await prefs.setString('currentTaskId', _currentTaskId!);
      } else {
        await prefs.remove('currentTaskId');
      }
    } catch (e) {
      debugPrint('保存任務時發生錯誤: $e');
    }
  }

  /// Push task to cloud if sync is active (fire-and-forget).
  void _pushIfSyncing(Task task) {
    syncService?.pushTask(task);
  }

  Future<void> addTask({
    required String title,
    String? description,
    required int pomodoroCount,
    required TaskPriority priority,
    TaskStatus status = TaskStatus.pending,
    bool isAIGenerated = false,
    String? aiSessionId,
    String? aiSessionTitle,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      pomodoroCount: pomodoroCount,
      priority: priority,
      status: status,
      createdAt: now,
      updatedAt: now,
      isAIGenerated: isAIGenerated,
      aiSessionId: aiSessionId,
      aiSessionTitle: aiSessionTitle,
    );

    // 保存到資料庫
    await _db.insertTask(task);
    _pushIfSyncing(task);

    // 更新記憶體中的列表
    _tasks.insert(0, task);

    // 重新排序以確保一致性
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      final taskWithTimestamp = updatedTask.copyWith(updatedAt: DateTime.now());
      // 更新資料庫
      await _db.updateTask(taskWithTimestamp);
      _pushIfSyncing(taskWithTimestamp);

      // 更新記憶體中的列表
      _tasks[index] = taskWithTimestamp;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    // 軟刪除（設置 deleted_at）以支援雲端同步
    final now = DateTime.now();
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    await _db.softDeleteTask(taskId);
    if (taskIndex != -1) {
      _pushIfSyncing(
        _tasks[taskIndex].copyWith(deletedAt: now, updatedAt: now),
      );
    }

    // 從記憶體中移除
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      TaskStatus newStatus;
      DateTime? completedAt;

      switch (task.status) {
        case TaskStatus.pending:
          newStatus = TaskStatus.inProgress;
          break;
        case TaskStatus.inProgress:
          newStatus = TaskStatus.completed;
          completedAt = DateTime.now();
          break;
        case TaskStatus.completed:
          newStatus = TaskStatus.pending;
          completedAt = null;
          break;
      }

      final updatedTask = task.copyWith(
        status: newStatus,
        completedAt: completedAt,
        updatedAt: DateTime.now(),
      );

      // 更新資料庫
      await _db.updateTask(updatedTask);
      _pushIfSyncing(updatedTask);

      // 更新記憶體
      _tasks[index] = updatedTask;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> moveTaskToInProgress(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(
        status: TaskStatus.inProgress,
        updatedAt: DateTime.now(),
      );

      // 更新資料庫
      await _db.updateTask(updatedTask);
      _pushIfSyncing(updatedTask);

      // 更新記憶體
      _tasks[index] = updatedTask;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> markTaskAsCompleted(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 更新資料庫
      await _db.updateTask(updatedTask);
      _pushIfSyncing(updatedTask);

      // 更新記憶體
      _tasks[index] = updatedTask;

      // 如果完成的是當前任務，清除當前任務
      if (_currentTaskId == taskId) {
        _currentTaskId = null;
      }

      notifyListeners();
      await _saveTasks();
    }
  }

  // 設置當前正在進行的任務
  Future<void> setCurrentTask(String? taskId) async {
    _currentTaskId = taskId;

    // 如果設置了新的當前任務，自動將其狀態設為進行中
    if (taskId != null) {
      await moveTaskToInProgress(taskId);
    }

    notifyListeners();
    await _saveTasks();
  }

  /// Clear all local data and Firestore data (if syncing).
  /// Returns true on success, false on failure.
  Future<bool> clearAllData() async {
    try {
      if (syncService != null) {
        await syncService!.clearFirestoreData();
      }
      await _db.clearAllData();
      _tasks = [];
      _currentTaskId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentTaskId');
      debugPrint('🧹 [TASK] All data cleared');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🧹 [TASK] Failed to clear data: $e');
      return false;
    }
  }

  // 完成番茄鐘後，為當前任務增加一個番茄鐘
  Future<void> completePomodoroForCurrentTask() async {
    if (_currentTaskId == null) return;

    final index = _tasks.indexWhere((task) => task.id == _currentTaskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        completedPomodoros: task.completedPomodoros + 1,
        updatedAt: DateTime.now(),
      );

      // 更新資料庫
      await _db.updateTask(updatedTask);
      _pushIfSyncing(updatedTask);

      // 更新記憶體
      _tasks[index] = updatedTask;

      debugPrint(
        '🍅 [TASK] Pomodoro completed for "${task.title}" (${updatedTask.completedPomodoros}/${task.pomodoroCount})',
      );

      notifyListeners();
      await _saveTasks();
    }
  }
}
