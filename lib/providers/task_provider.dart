import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

// Riverpod provider
final taskProvider = ChangeNotifierProvider<TaskProvider>((ref) {
  return TaskProvider();
});

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _currentTaskId; // 當前正在進行的任務ID

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
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];
      final currentTaskId = prefs.getString('currentTaskId');
      
      _tasks = tasksJson
          .map((taskString) => Task.fromJson(jsonDecode(taskString)))
          .toList();
      
      _currentTaskId = currentTaskId;
      
      // 按創建時間排序
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('載入任務時發生錯誤: $e');
      _tasks = _getDefaultTasks();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks
          .map((task) => jsonEncode(task.toJson()))
          .toList();
      
      await prefs.setStringList('tasks', tasksJson);
      
      // 保存當前任務ID
      if (_currentTaskId != null) {
        await prefs.setString('currentTaskId', _currentTaskId!);
      } else {
        await prefs.remove('currentTaskId');
      }
    } catch (e) {
      debugPrint('保存任務時發生錯誤: $e');
    }
  }

  Future<void> addTask({
    required String title,
    String? description,
    required int pomodoroCount,
    required TaskPriority priority,
    TaskStatus status = TaskStatus.pending,
  }) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      pomodoroCount: pomodoroCount,
      priority: priority,
      status: status,
      createdAt: DateTime.now(),
    );

    _tasks.insert(0, task);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
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

      _tasks[index] = task.copyWith(
        status: newStatus,
        completedAt: completedAt,
      );
      
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> moveTaskToInProgress(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.inProgress);
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> markTaskAsCompleted(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      
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

  // 完成番茄鐘後，為當前任務增加一個番茄鐘
  Future<void> completePomodoroForCurrentTask() async {
    if (_currentTaskId == null) return;
    
    final index = _tasks.indexWhere((task) => task.id == _currentTaskId);
    if (index != -1) {
      final task = _tasks[index];
      // 這裡可以添加完成的番茄鐘計數邏輯
      // 暫時只確保任務狀態為進行中
      _tasks[index] = task.copyWith(status: TaskStatus.inProgress);
      
      notifyListeners();
      await _saveTasks();
    }
  }

  List<Task> _getDefaultTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        title: '撰寫產品需求文件 - 第一章節',
        pomodoroCount: 2,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Task(
        id: '2',
        title: '準備明天的會議簡報',
        pomodoroCount: 3,
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Task(
        id: '3',
        title: '回覆客戶郵件',
        pomodoroCount: 1,
        priority: TaskPriority.low,
        status: TaskStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      Task(
        id: '4',
        title: '檢查並回覆 Slack 訊息',
        pomodoroCount: 1,
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(hours: 3)),
        completedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
