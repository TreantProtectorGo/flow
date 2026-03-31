import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/data_migration_helper.dart';
import '../services/focus_repository.dart';
import '../services/notification_client.dart';
import '../services/sync_service.dart';
import 'notification_strings_provider.dart';
import 'settings_provider.dart';
import 'task_completion_event_provider.dart';

final ChangeNotifierProvider<TaskProvider> taskProvider =
    ChangeNotifierProvider<TaskProvider>((Ref ref) {
      final TaskProvider notifier = TaskProvider(
        ref,
        repository: ref.watch(focusRepositoryProvider),
        notificationClient: ref.watch(notificationClientProvider),
      );

      ref.listen<AppSettings>(settingsProvider, (
        AppSettings? previous,
        AppSettings next,
      ) {
        if (previous?.notifications != next.notifications) {
          notifier.handleNotificationsSettingChanged(next.notifications);
        }
      });

      return notifier;
    });

class TaskProvider with ChangeNotifier {
  final Ref _ref;
  final FocusRepository _repository;
  final NotificationClient _notificationClient;

  List<Task> _tasks = <Task>[];
  bool _isLoading = false;
  String? _currentTaskId;

  /// Optional sync service — set by AuthProvider when user is signed in.
  SyncService? syncService;

  TaskProvider(
    this._ref, {
    required FocusRepository repository,
    required NotificationClient notificationClient,
  }) : _repository = repository,
       _notificationClient = notificationClient {
    _initializeAndLoadTasks();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get currentTaskId => _currentTaskId;

  Task? get currentTask {
    if (_currentTaskId == null) {
      return null;
    }

    try {
      return _tasks.firstWhere((Task task) => task.id == _currentTaskId);
    } catch (e) {
      _currentTaskId = null;
      return null;
    }
  }

  List<Task> get pendingTasks =>
      _tasks.where((Task task) => task.status == TaskStatus.pending).toList();

  List<Task> get inProgressTasks => _tasks
      .where((Task task) => task.status == TaskStatus.inProgress)
      .toList();

  List<Task> get completedTasks =>
      _tasks.where((Task task) => task.status == TaskStatus.completed).toList();

  Future<void> _initializeAndLoadTasks() async {
    try {
      if (await DataMigrationHelper.needsMigration()) {
        debugPrint('🔄 需要執行資料遷移');
        try {
          await DataMigrationHelper.migrate();
        } catch (e) {
          debugPrint('❌ 資料遷移失敗，將繼續載入: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ 跳過資料遷移檢查: $e');
    }

    await _loadTasks();
  }

  Future<void> reloadTasks() async {
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getAllTasks();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentTaskId = prefs.getString('currentTaskId');
      _sortTasks();
      await _reconcileTaskReminders();
    } catch (e) {
      debugPrint('載入任務時發生錯誤: $e');
      _tasks = <Task>[];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      if (_currentTaskId != null) {
        await prefs.setString('currentTaskId', _currentTaskId!);
      } else {
        await prefs.remove('currentTaskId');
      }
    } catch (e) {
      debugPrint('保存任務時發生錯誤: $e');
    }
  }

  void _sortTasks() {
    _tasks.sort((Task a, Task b) => b.createdAt.compareTo(a.createdAt));
  }

  void _pushIfSyncing(Task task) {
    syncService?.pushTask(task);
  }

  Future<void> handleNotificationsSettingChanged(bool enabled) async {
    if (!enabled) {
      await _notificationClient.cancelAllTaskReminders();
      return;
    }

    await _reconcileTaskReminders();
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
    String? reminderTime,
  }) async {
    final DateTime now = DateTime.now();
    final Task task = Task(
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
      dailyReminderTime: reminderTime,
    );

    await _repository.insertTask(task);
    _pushIfSyncing(task);

    _tasks.insert(0, task);
    _sortTasks();
    await _syncReminderForTask(task);

    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(Task updatedTask) async {
    final int index = _tasks.indexWhere(
      (Task task) => task.id == updatedTask.id,
    );
    if (index == -1) {
      return;
    }

    final Task previousTask = _tasks[index];
    final Task taskWithTimestamp = updatedTask.copyWith(
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(taskWithTimestamp);
    _pushIfSyncing(taskWithTimestamp);

    _tasks[index] = taskWithTimestamp;
    _sortTasks();
    _handleCurrentTaskCompletion(taskWithTimestamp);
    _emitCompletionEventIfNeeded(previousTask, taskWithTimestamp);
    await _syncReminderForTask(taskWithTimestamp);

    notifyListeners();
    await _saveTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final DateTime now = DateTime.now();
    final int taskIndex = _tasks.indexWhere((Task task) => task.id == taskId);

    await _repository.softDeleteTask(taskId);
    await _notificationClient.cancelTaskReminder(taskId);

    if (taskIndex != -1) {
      _pushIfSyncing(
        _tasks[taskIndex].copyWith(deletedAt: now, updatedAt: now),
      );
    }

    _tasks.removeWhere((Task task) => task.id == taskId);
    if (_currentTaskId == taskId) {
      _currentTaskId = null;
    }

    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final int index = _tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    final Task task = _tasks[index];
    late final TaskStatus newStatus;
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

    final Task updatedTask = task.copyWith(
      status: newStatus,
      completedAt: completedAt,
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(updatedTask);
    _pushIfSyncing(updatedTask);

    _tasks[index] = updatedTask;
    _sortTasks();
    _handleCurrentTaskCompletion(updatedTask);
    _emitCompletionEventIfNeeded(task, updatedTask);
    await _syncReminderForTask(updatedTask);

    notifyListeners();
    await _saveTasks();
  }

  Future<void> moveTaskToInProgress(String taskId) async {
    final int index = _tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    final Task previousTask = _tasks[index];
    final Task updatedTask = previousTask.copyWith(
      status: TaskStatus.inProgress,
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(updatedTask);
    _pushIfSyncing(updatedTask);

    _tasks[index] = updatedTask;
    _sortTasks();
    await _syncReminderForTask(updatedTask);

    notifyListeners();
    await _saveTasks();
  }

  Future<void> markTaskAsCompleted(String taskId) async {
    final int index = _tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    final Task previousTask = _tasks[index];
    final Task updatedTask = previousTask.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(updatedTask);
    _pushIfSyncing(updatedTask);

    _tasks[index] = updatedTask;
    _handleCurrentTaskCompletion(updatedTask);
    _emitCompletionEventIfNeeded(previousTask, updatedTask);
    await _syncReminderForTask(updatedTask);

    notifyListeners();
    await _saveTasks();
  }

  Future<void> setCurrentTask(String? taskId) async {
    _currentTaskId = taskId;

    if (taskId != null) {
      await moveTaskToInProgress(taskId);
    }

    notifyListeners();
    await _saveTasks();
  }

  Future<bool> clearAllData() async {
    try {
      if (syncService != null) {
        await syncService!.clearFirestoreData();
      }
      await _repository.clearAllData();
      await _notificationClient.cancelAllTaskReminders();
      _tasks = <Task>[];
      _currentTaskId = null;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentTaskId');
      debugPrint('🧹 [TASK] All data cleared');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('🧹 [TASK] Failed to clear data: $e');
      return false;
    }
  }

  Future<void> completePomodoroForCurrentTask() async {
    if (_currentTaskId == null) {
      return;
    }

    final int index = _tasks.indexWhere(
      (Task task) => task.id == _currentTaskId,
    );
    if (index == -1) {
      return;
    }

    final Task task = _tasks[index];
    final Task updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      completedPomodoros: task.completedPomodoros + 1,
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(updatedTask);
    _pushIfSyncing(updatedTask);

    _tasks[index] = updatedTask;

    debugPrint(
      '🍅 [TASK] Pomodoro completed for "${task.title}" (${updatedTask.completedPomodoros}/${task.pomodoroCount})',
    );

    notifyListeners();
    await _saveTasks();
  }

  Future<void> _syncReminderForTask(Task task) async {
    if (task.status == TaskStatus.completed ||
        task.deletedAt != null ||
        task.dailyReminderTime == null ||
        !_ref.read(settingsProvider).notifications) {
      await _notificationClient.cancelTaskReminder(task.id);
      return;
    }

    final NotificationStrings strings = _ref.read(notificationStringsProvider);
    await _notificationClient.scheduleDailyTaskReminder(
      task: task,
      title: strings.taskReminderTitle,
      body: strings.taskReminderBody(task.title),
      channelName: strings.taskReminderChannelName,
      channelDescription: strings.taskReminderChannelDescription,
    );
  }

  Future<void> _reconcileTaskReminders() async {
    final NotificationStrings strings = _ref.read(notificationStringsProvider);
    await _notificationClient.reconcileTaskReminders(
      tasks: _tasks.where(
        (Task task) =>
            task.dailyReminderTime != null &&
            task.status != TaskStatus.completed &&
            task.deletedAt == null,
      ),
      notificationsEnabled: _ref.read(settingsProvider).notifications,
      title: strings.taskReminderTitle,
      bodyBuilder: (Task task) => strings.taskReminderBody(task.title),
      channelName: strings.taskReminderChannelName,
      channelDescription: strings.taskReminderChannelDescription,
    );
  }

  void _handleCurrentTaskCompletion(Task task) {
    if (task.status == TaskStatus.completed && _currentTaskId == task.id) {
      _currentTaskId = null;
    }
  }

  void _emitCompletionEventIfNeeded(Task previousTask, Task updatedTask) {
    if (previousTask.status == TaskStatus.completed ||
        updatedTask.status != TaskStatus.completed) {
      return;
    }

    _ref.read(taskCompletionEventProvider.notifier).state = TaskCompletionEvent(
      eventId: DateTime.now().microsecondsSinceEpoch.toString(),
      taskId: updatedTask.id,
      taskTitle: updatedTask.title,
    );
  }
}
