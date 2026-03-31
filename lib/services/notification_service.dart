import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import 'notification_client.dart';

/// NotificationService - Manages local notifications for timer completion
/// Provides cross-platform notification support for iOS, Android, macOS, and Linux
class NotificationService implements NotificationClient {
  static const String _timerChannelId = 'timer_channel';
  static const String _taskReminderChannelId = 'task_reminder_channel';
  static const String _taskReminderPayloadPrefix = 'task_reminder:';

  /// Singleton instance
  static final NotificationService instance = NotificationService._init();

  /// The flutter_local_notifications plugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Whether the service has been initialized
  bool _isInitialized = false;

  NotificationService._init();

  /// Initialize the notification service
  /// Must be called before showing any notifications
  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      await _requestPermissions();
      await _configureLocalTimeZone();

      _isInitialized = true;
      debugPrint('[NOTIFICATION] Service initialized successfully');
    } catch (e) {
      debugPrint('[NOTIFICATION] Failed to initialize: $e');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  }

  /// Request notification permissions for iOS and macOS
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('[NOTIFICATION] iOS permission granted: $granted');
    } else if (Platform.isMacOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('[NOTIFICATION] macOS permission granted: $granted');
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? granted = await androidPlugin
          ?.requestNotificationsPermission();
      debugPrint('[NOTIFICATION] Android permission granted: $granted');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NOTIFICATION] Tapped: ${response.payload}');
  }

  @override
  Future<void> showFocusCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NOTIFICATION] Service not initialized');
      return;
    }

    await _showNotification(
      id: 1,
      title: title,
      body: body,
      payload: 'focus_complete',
      notificationDetails: _buildTimerNotificationDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
    );
  }

  @override
  Future<void> showBreakCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NOTIFICATION] Service not initialized');
      return;
    }

    await _showNotification(
      id: 2,
      title: title,
      body: body,
      payload: 'break_complete',
      notificationDetails: _buildTimerNotificationDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
    );
  }

  @override
  Future<void> showTaskCompleteNotification({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NOTIFICATION] Service not initialized');
      return;
    }

    await _showNotification(
      id: 3,
      title: title,
      body: body,
      payload: 'task_complete',
      notificationDetails: _buildTimerNotificationDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
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
    if (!_isInitialized || task.dailyReminderTime == null) {
      return;
    }

    final int notificationId = _taskReminderNotificationId(task.id);
    final tz.TZDateTime scheduledDate = _nextInstanceOfReminderTime(
      task.dailyReminderTime!,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      _buildTaskReminderNotificationDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      payload: '$_taskReminderPayloadPrefix${task.id}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
      '[NOTIFICATION] Scheduled daily task reminder for "${task.title}" at ${task.dailyReminderTime}',
    );
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_isInitialized) {
      return;
    }

    await _flutterLocalNotificationsPlugin.cancel(
      _taskReminderNotificationId(taskId),
    );
  }

  @override
  Future<void> cancelAllTaskReminders() async {
    if (!_isInitialized) {
      return;
    }

    final List<PendingNotificationRequest> pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (final PendingNotificationRequest request in pending) {
      if (request.payload?.startsWith(_taskReminderPayloadPrefix) ?? false) {
        await _flutterLocalNotificationsPlugin.cancel(request.id);
      }
    }
  }

  @override
  Future<void> reconcileTaskReminders({
    required Iterable<Task> tasks,
    required bool notificationsEnabled,
    required String title,
    required String Function(Task task) bodyBuilder,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_isInitialized) {
      return;
    }

    if (!notificationsEnabled) {
      await cancelAllTaskReminders();
      return;
    }

    final List<Task> eligibleTasks = tasks
        .where(
          (Task task) =>
              task.dailyReminderTime != null &&
              task.status != TaskStatus.completed &&
              task.deletedAt == null,
        )
        .toList(growable: false);

    final List<PendingNotificationRequest> pending =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final Set<int> desiredIds = eligibleTasks
        .map((Task task) => _taskReminderNotificationId(task.id))
        .toSet();

    for (final PendingNotificationRequest request in pending) {
      final bool isTaskReminder =
          request.payload?.startsWith(_taskReminderPayloadPrefix) ?? false;
      if (isTaskReminder && !desiredIds.contains(request.id)) {
        await _flutterLocalNotificationsPlugin.cancel(request.id);
      }
    }

    for (final Task task in eligibleTasks) {
      await scheduleDailyTaskReminder(
        task: task,
        title: title,
        body: bodyBuilder(task),
        channelName: channelName,
        channelDescription: channelDescription,
      );
    }
  }

  NotificationDetails _buildTimerNotificationDetails({
    required String channelName,
    required String channelDescription,
  }) {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _timerChannelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    return NotificationDetails(
      android: androidDetails,
      iOS: _darwinNotificationDetails,
      macOS: _darwinNotificationDetails,
      linux: _linuxNotificationDetails,
    );
  }

  NotificationDetails _buildTaskReminderNotificationDetails({
    required String channelName,
    required String channelDescription,
  }) {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _taskReminderChannelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    return NotificationDetails(
      android: androidDetails,
      iOS: _darwinNotificationDetails,
      macOS: _darwinNotificationDetails,
      linux: _linuxNotificationDetails,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('[NOTIFICATION] Shown: $title');
    } catch (e) {
      debugPrint('[NOTIFICATION] Failed to show notification: $e');
    }
  }

  static const DarwinNotificationDetails _darwinNotificationDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  static const LinuxNotificationDetails _linuxNotificationDetails =
      LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical);

  int _taskReminderNotificationId(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }

  tz.TZDateTime _nextInstanceOfReminderTime(String reminderTime) {
    final List<String> parts = reminderTime.split(':');
    final int hour = int.parse(parts.first);
    final int minute = int.parse(parts.last);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  @override
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
