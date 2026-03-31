import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'database_helper.dart';

abstract class FocusRepository {
  Future<List<Task>> getAllTasks();

  Future<void> insertTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> softDeleteTask(String id);

  Future<void> clearAllData();

  Future<void> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType,
  });
}

class DatabaseFocusRepository implements FocusRepository {
  final DatabaseHelper _databaseHelper;

  DatabaseFocusRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> clearAllData() async {
    await _databaseHelper.clearAllData();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return _databaseHelper.getAllTasks();
  }

  @override
  Future<void> insertPomodoroSession({
    String? taskId,
    required DateTime startTime,
    DateTime? endTime,
    required int duration,
    required bool completed,
    required String sessionType,
  }) async {
    await _databaseHelper.insertPomodoroSession(
      taskId: taskId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      completed: completed,
      sessionType: sessionType,
    );
  }

  @override
  Future<void> insertTask(Task task) async {
    await _databaseHelper.insertTask(task);
  }

  @override
  Future<void> softDeleteTask(String id) async {
    await _databaseHelper.softDeleteTask(id);
  }

  @override
  Future<void> updateTask(Task task) async {
    await _databaseHelper.updateTask(task);
  }
}

final Provider<FocusRepository> focusRepositoryProvider =
    Provider<FocusRepository>((Ref ref) {
      return DatabaseFocusRepository();
    });
