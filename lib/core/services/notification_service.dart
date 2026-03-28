import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Wraps flutter_local_notifications for local notification scheduling.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Stream of notification action IDs (e.g. 'add_expense', 'add_income')
  static final StreamController<String> actionStream =
      StreamController<String>.broadcast();

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'quick_add',
          actions: [
            DarwinNotificationAction.plain(
              'add_expense',
              'Add Expense',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'add_income',
              'Add Income',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Check if app was launched from a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse != null) {
      _onNotificationResponse(launchDetails!.notificationResponse!);
    }

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      actionStream.add(actionId);
    } else if (response.payload != null && response.payload!.isNotEmpty) {
      // Tapped on notification body - emit payload as action
      actionStream.add(response.payload!);
    }
  }

  /// Request notification permissions (iOS).
  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Android notification details with quick-add action buttons.
  static const _androidDetailsWithActions = AndroidNotificationDetails(
    'cachium_scheduled',
    'Cachium Reminders',
    channelDescription: 'Scheduled reminders',
    importance: Importance.high,
    priority: Priority.high,
    actions: [
      AndroidNotificationAction('add_expense', 'Add Expense'),
      AndroidNotificationAction('add_income', 'Add Income'),
    ],
  );

  /// Show an immediate notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool includeQuickAdd = false,
  }) async {
    final androidDetails = includeQuickAdd
        ? _androidDetailsWithActions
        : const AndroidNotificationDetails(
            'cachium_general',
            'Cachium',
            channelDescription: 'Cachium notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

    final iosDetails = includeQuickAdd
        ? const DarwinNotificationDetails(categoryIdentifier: 'quick_add')
        : const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule a notification at a specific time.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool includeQuickAdd = false,
  }) async {
    final androidDetails = includeQuickAdd
        ? _androidDetailsWithActions
        : const AndroidNotificationDetails(
            'cachium_scheduled',
            'Cachium Reminders',
            channelDescription: 'Scheduled reminders',
            importance: Importance.high,
            priority: Priority.high,
          );

    final iosDetails = includeQuickAdd
        ? const DarwinNotificationDetails(categoryIdentifier: 'quick_add')
        : const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel a specific notification.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Get pending notifications count (iOS limit is 64).
  Future<int> getPendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
