import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'notification_service.dart';

abstract class NotificationClient {
  Future<void> initialize();

  Future<void> showFocusCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<void> showTaskCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<void> scheduleDailyTaskReminder({
    required Task task,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<void> cancelTaskReminder(String taskId);

  Future<void> cancelAllTaskReminders();

  Future<void> reconcileTaskReminders({
    required Iterable<Task> tasks,
    required bool notificationsEnabled,
    required String title,
    required String Function(Task task) bodyBuilder,
    required String channelName,
    required String channelDescription,
  });

  Future<void> cancelAll();

  Future<void> cancel(int id);
}

final Provider<NotificationClient> notificationClientProvider =
    Provider<NotificationClient>((Ref ref) {
      return NotificationService.instance;
    });
