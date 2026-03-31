import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';
import 'package:focus/providers/statistics_provider.dart';
import 'package:focus/providers/task_completion_event_provider.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/providers/timer_provider.dart';
import 'package:focus/services/focus_repository.dart';
import 'package:focus/services/notification_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFocusRepository implements FocusRepository {
  final List<Task> tasks;
  int insertedPomodoroSessions = 0;

  _FakeFocusRepository({required this.tasks});

  @override
  Future<void> clearAllData() async {
    tasks.clear();
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return List<Task>.from(tasks);
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
    insertedPomodoroSessions += 1;
  }

  @override
  Future<void> insertTask(Task task) async {
    tasks.add(task);
  }

  @override
  Future<void> softDeleteTask(String id) async {}

  @override
  Future<void> updateTask(Task task) async {
    final int index = tasks.indexWhere((Task item) => item.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
  }
}

class _FakeNotificationClient implements NotificationClient {
  final List<String> canceledTaskIds = <String>[];

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllTaskReminders() async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> reconcileTaskReminders({
    required Iterable<Task> tasks,
    required bool notificationsEnabled,
    required String title,
    required String Function(Task task) bodyBuilder,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> scheduleDailyTaskReminder({
    required Task task,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> showFocusCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> showTaskCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeStatisticsNotifier extends StatisticsNotifier {
  @override
  Future<void> loadStatistics() async {}
}

void main() {
  test(
    'final pomodoro completion cancels reminder and emits celebration event',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'currentTaskId': 'task-1',
      });
      final _FakeFocusRepository repository = _FakeFocusRepository(
        tasks: <Task>[
          Task(
            id: 'task-1',
            title: 'Close sprint',
            pomodoroCount: 1,
            completedPomodoros: 0,
            priority: TaskPriority.high,
            status: TaskStatus.inProgress,
            createdAt: DateTime(2026, 3, 31, 9, 0),
            dailyReminderTime: '20:00',
          ),
        ],
      );
      final _FakeNotificationClient notifications = _FakeNotificationClient();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(notifications),
          statisticsProvider.overrideWith(
            (Ref ref) => _FakeStatisticsNotifier(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      container.read(timerProvider.notifier).startTimer();
      container.read(timerProvider.notifier).skipTimer();
      await _flushMicrotasks();

      final Task completedTask = container
          .read(taskProvider)
          .completedTasks
          .single;
      final TaskCompletionEvent? event = container.read(
        taskCompletionEventProvider,
      );

      expect(repository.insertedPomodoroSessions, equals(1));
      expect(completedTask.status, equals(TaskStatus.completed));
      expect(notifications.canceledTaskIds, contains('task-1'));
      expect(event?.taskTitle, equals('Close sprint'));
    },
  );
}
