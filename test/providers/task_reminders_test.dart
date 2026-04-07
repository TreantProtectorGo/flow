import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/models/task.dart';
import 'package:focus/providers/settings_provider.dart';
import 'package:focus/providers/task_completion_event_provider.dart';
import 'package:focus/providers/task_provider.dart';
import 'package:focus/services/focus_repository.dart';
import 'package:focus/services/notification_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFocusRepository implements FocusRepository {
  final List<Task> tasks;

  _FakeFocusRepository({List<Task>? tasks}) : tasks = tasks ?? <Task>[];

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
  }) async {}

  @override
  Future<void> insertTask(Task task) async {
    tasks.add(task);
  }

  @override
  Future<void> softDeleteTask(String id) async {
    final int index = tasks.indexWhere((Task task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        deletedAt: DateTime(2026, 3, 31, 12, 0),
      );
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    final int index = tasks.indexWhere((Task item) => item.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
  }
}

class _FakeNotificationClient implements NotificationClient {
  final List<String> scheduledTaskIds = <String>[];
  final List<String> canceledTaskIds = <String>[];
  final List<List<String>> reconcileTaskIds = <List<String>>[];
  int cancelAllTaskRemindersCount = 0;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllTaskReminders() async {
    cancelAllTaskRemindersCount += 1;
  }

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
  }) async {
    if (!notificationsEnabled) {
      return;
    }
    reconcileTaskIds.add(
      tasks.map((Task task) => task.id).toList(growable: false),
    );
  }

  @override
  Future<void> scheduleDailyTaskReminder({
    required Task task,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    scheduledTaskIds.add(task.id);
  }

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

void main() {
  group('Task reminders', () {
    test(
      'selecting current task applies the default session reminder',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'settings_notifications': true,
          'settings_default_task_reminder_enabled': true,
          'settings_default_task_reminder_time': '09:00',
        });
        final _FakeFocusRepository repository = _FakeFocusRepository(
          tasks: <Task>[
            Task(
              id: 'task-1',
              title: 'Plan day',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 3, 31, 9, 0),
            ),
          ],
        );
        final _FakeNotificationClient notifications = _FakeNotificationClient();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            focusRepositoryProvider.overrideWithValue(repository),
            notificationClientProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        await container.read(taskProvider.notifier).reloadTasks();
        await _flushMicrotasks();
        await container.read(taskProvider.notifier).setCurrentTask('task-1');

        expect(
          container.read(taskProvider).currentTask?.dailyReminderTime,
          '09:00',
        );
        expect(notifications.scheduledTaskIds, contains('task-1'));
      },
    );

    test('adding a task with daily reminder schedules a reminder', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _FakeFocusRepository repository = _FakeFocusRepository();
      final _FakeNotificationClient notifications = _FakeNotificationClient();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          focusRepositoryProvider.overrideWithValue(repository),
          notificationClientProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(container.dispose);

      await container.read(taskProvider.notifier).reloadTasks();
      await _flushMicrotasks();
      await container
          .read(taskProvider.notifier)
          .addTask(
            title: 'Write report',
            pomodoroCount: 2,
            priority: TaskPriority.medium,
            reminderTime: '09:15',
          );

      expect(notifications.scheduledTaskIds, hasLength(1));
      expect(repository.tasks.single.dailyReminderTime, equals('09:15'));
    });

    test(
      'completing a task cancels reminder and emits celebration event',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'currentTaskId': 'task-1',
        });
        final _FakeFocusRepository repository = _FakeFocusRepository(
          tasks: <Task>[
            Task(
              id: 'task-1',
              title: 'Ship release',
              pomodoroCount: 3,
              priority: TaskPriority.high,
              status: TaskStatus.inProgress,
              createdAt: DateTime(2026, 3, 31, 9, 0),
              dailyReminderTime: '18:00',
            ),
          ],
        );
        final _FakeNotificationClient notifications = _FakeNotificationClient();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            focusRepositoryProvider.overrideWithValue(repository),
            notificationClientProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        await container.read(taskProvider.notifier).reloadTasks();
        await _flushMicrotasks();
        await container
            .read(taskProvider.notifier)
            .markTaskAsCompleted('task-1');

        final Task completedTask = container
            .read(taskProvider)
            .completedTasks
            .single;
        final TaskCompletionEvent? event = container.read(
          taskCompletionEventProvider,
        );

        expect(completedTask.status, equals(TaskStatus.completed));
        expect(notifications.canceledTaskIds, contains('task-1'));
        expect(event?.taskId, equals('task-1'));
        expect(event?.taskTitle, equals('Ship release'));
      },
    );

    test(
      'completing the current reminded task moves reminder to the next unfinished task',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'currentTaskId': 'task-1',
          'settings_notifications': true,
          'settings_default_task_reminder_enabled': true,
        });
        final _FakeFocusRepository repository = _FakeFocusRepository(
          tasks: <Task>[
            Task(
              id: 'task-1',
              title: 'Task 1',
              pomodoroCount: 1,
              priority: TaskPriority.high,
              status: TaskStatus.inProgress,
              createdAt: DateTime(2026, 3, 31, 11, 0),
              isAIGenerated: true,
              aiSessionId: 'session-a',
              dailyReminderTime: '09:00',
            ),
            Task(
              id: 'task-2',
              title: 'Task 2',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 3, 31, 10, 0),
              isAIGenerated: true,
              aiSessionId: 'session-a',
            ),
          ],
        );
        final _FakeNotificationClient notifications = _FakeNotificationClient();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            focusRepositoryProvider.overrideWithValue(repository),
            notificationClientProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        await container.read(taskProvider.notifier).reloadTasks();
        await _flushMicrotasks();
        await container
            .read(taskProvider.notifier)
            .markTaskAsCompleted('task-1');

        final Task nextTask = container.read(taskProvider).pendingTasks.single;

        expect(nextTask.id, equals('task-2'));
        expect(nextTask.dailyReminderTime, equals('09:00'));
        expect(notifications.canceledTaskIds, contains('task-1'));
        expect(notifications.scheduledTaskIds, contains('task-2'));
      },
    );

    test(
      'reminder does not jump to another section after the section is completed',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'currentTaskId': 'task-2',
          'settings_notifications': true,
          'settings_default_task_reminder_enabled': true,
        });
        final _FakeFocusRepository repository = _FakeFocusRepository(
          tasks: <Task>[
            Task(
              id: 'task-3',
              title: 'Other section task',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 3, 31, 12, 0),
              isAIGenerated: true,
              aiSessionId: 'session-b',
            ),
            Task(
              id: 'task-2',
              title: 'Last task in section',
              pomodoroCount: 1,
              priority: TaskPriority.high,
              status: TaskStatus.inProgress,
              createdAt: DateTime(2026, 3, 31, 11, 0),
              isAIGenerated: true,
              aiSessionId: 'session-a',
              dailyReminderTime: '09:00',
            ),
          ],
        );
        final _FakeNotificationClient notifications = _FakeNotificationClient();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            focusRepositoryProvider.overrideWithValue(repository),
            notificationClientProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        await container.read(taskProvider.notifier).reloadTasks();
        await _flushMicrotasks();
        await container
            .read(taskProvider.notifier)
            .markTaskAsCompleted('task-2');

        final Task remainingTask = repository.tasks.firstWhere(
          (Task task) => task.id == 'task-3',
        );
        expect(remainingTask.dailyReminderTime, isNull);
        expect(notifications.scheduledTaskIds, isNot(contains('task-3')));
        expect(notifications.canceledTaskIds, contains('task-2'));
      },
    );

    test(
      'notification setting off cancels reminders and on reconciles active tasks',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'settings_notifications': true,
        });
        final _FakeFocusRepository repository = _FakeFocusRepository(
          tasks: <Task>[
            Task(
              id: 'task-a',
              title: 'Task A',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 3, 31, 9, 0),
              dailyReminderTime: '09:00',
            ),
            Task(
              id: 'task-b',
              title: 'Task B',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.completed,
              createdAt: DateTime(2026, 3, 31, 9, 0),
              dailyReminderTime: '10:00',
            ),
            Task(
              id: 'task-c',
              title: 'Task C',
              pomodoroCount: 1,
              priority: TaskPriority.medium,
              status: TaskStatus.pending,
              createdAt: DateTime(2026, 3, 31, 9, 0),
            ),
          ],
        );
        final _FakeNotificationClient notifications = _FakeNotificationClient();
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            focusRepositoryProvider.overrideWithValue(repository),
            notificationClientProvider.overrideWithValue(notifications),
          ],
        );
        addTearDown(container.dispose);

        await container.read(taskProvider.notifier).reloadTasks();
        await _flushMicrotasks();
        notifications.reconcileTaskIds.clear();

        container.read(settingsProvider.notifier).setNotifications(false);
        await _flushMicrotasks();
        container.read(settingsProvider.notifier).setNotifications(true);
        await _flushMicrotasks();

        expect(notifications.cancelAllTaskRemindersCount, equals(1));
        expect(notifications.reconcileTaskIds, hasLength(1));
        expect(
          notifications.reconcileTaskIds.single,
          equals(<String>['task-a']),
        );
      },
    );
  });
}
