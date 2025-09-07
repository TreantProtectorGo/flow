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

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

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
      
      _tasks = tasksJson
          .map((taskString) => Task.fromJson(jsonDecode(taskString)))
          .toList();
      
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
