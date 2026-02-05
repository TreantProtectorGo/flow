import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService - Manages local notifications for timer completion
/// Provides cross-platform notification support for iOS, Android, macOS, and Linux
class NotificationService {
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
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android settings - uses default app icon
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS settings
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Linux settings
      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux,
          );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions on iOS/macOS
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('[NOTIFICATION] Service initialized successfully');
    } catch (e) {
      debugPrint('[NOTIFICATION] Failed to initialize: $e');
    }
  }

  /// Request notification permissions for iOS and macOS
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NOTIFICATION] Tapped: ${response.payload}');
  }

  /// Show a notification when focus session completes
  /// [title] - Localized title
  /// [body] - Localized body message
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
      channelName: channelName,
      channelDescription: channelDescription,
    );
  }

  /// Show a notification when break session completes
  /// [title] - Localized title
  /// [body] - Localized body message
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
      channelName: channelName,
      channelDescription: channelDescription,
    );
  }

  /// Internal method to show a notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'timer_channel',
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

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

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancel a specific notification by ID
  Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
