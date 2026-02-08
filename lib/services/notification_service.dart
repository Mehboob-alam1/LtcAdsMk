import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Shows local notifications when mining starts and when mining ends.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _idMiningStarted = 1;
  static const int _idMiningEnded = 2;
  static const int _idMiningEndScheduled = 3;
  static const int _idBoostActivated = 10;
  static const int _idShopNotification = 11;
  /// Hourly reminder IDs: 20..43 (24 notifications, one per hour).
  static const int _hourlyIdStart = 20;
  static const int _hourlyIdCount = 24;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true);
    }
    _initialized = true;
    scheduleHourlyReminders();
  }

  /// Android channel for hourly reminders (so user can mute if desired).
  AndroidNotificationDetails get _hourlyAndroidDetails => const AndroidNotificationDetails(
        'hourly_reminder_channel',
        'Hourly reminders',
        channelDescription: 'Reminders to check your mining progress',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  NotificationDetails get _hourlyDetails => NotificationDetails(
        android: _hourlyAndroidDetails,
        iOS: _iosDetails,
      );

  /// Schedule one notification per hour for the next 24 hours. Fires even when app is closed.
  Future<void> scheduleHourlyReminders() async {
    final now = DateTime.now();
    for (int i = 0; i < _hourlyIdCount; i++) {
      final scheduled = now.add(Duration(hours: i + 1));
      final utc = scheduled.toUtc();
      final tzDate = tz.TZDateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
        utc.minute,
        utc.second,
      );
      await _plugin.zonedSchedule(
        _hourlyIdStart + i,
        'GIGA BTC Mining',
        _hourlyBodies[i % _hourlyBodies.length],
        tzDate,
        _hourlyDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static const List<String> _hourlyBodies = [
    'Check your mining progress – tap to open.',
    'Your balance is updating. Open the app to see.',
    'Mining in progress – tap to view your earnings.',
    'Don’t forget to check your GIGA BTC Mining balance.',
  ];

  /// Cancel all scheduled hourly reminders.
  Future<void> cancelHourlyReminders() async {
    for (int i = 0; i < _hourlyIdCount; i++) {
      await _plugin.cancel(_hourlyIdStart + i);
    }
  }

  AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
        'mining_channel',
        'Mining',
        channelDescription: 'Mining session notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  DarwinNotificationDetails get _iosDetails => const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
      );

  NotificationDetails get _details => NotificationDetails(
        android: _androidDetails,
        iOS: _iosDetails,
      );

  /// Call when user starts mining. Schedules "Mining ended" at [sessionEndsAt].
  Future<void> showMiningStarted({
    required int sessionHours,
    required DateTime sessionEndsAt,
  }) async {
    await _plugin.show(
      _idMiningStarted,
      'Mining started',
      '$sessionHours hour session running. You will be notified when it ends.',
      _details,
    );
    await _scheduleMiningEnded(sessionEndsAt);
  }

  /// Call when mining ends (user stopped or session expired).
  Future<void> showMiningEnded() async {
    await _plugin.cancel(_idMiningEndScheduled);
    await _plugin.show(
      _idMiningEnded,
      'Mining ended',
      'Your mining session has finished. Open the app to see your balance.',
      _details,
    );
  }

  Future<void> _scheduleMiningEnded(DateTime scheduledDate) async {
    await _plugin.cancel(_idMiningEndScheduled);
    final delay = scheduledDate.difference(DateTime.now());
    if (delay.isNegative || delay.inSeconds < 1) return;
    final utc = scheduledDate.toUtc();
    final tzDate = tz.TZDateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
    await _plugin.zonedSchedule(
      _idMiningEndScheduled,
      'Mining ended',
      'Your mining session has finished. Open the app to see your balance.',
      tzDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelScheduledMiningEnded() async {
    await _plugin.cancel(_idMiningEndScheduled);
  }

  /// Notify user that a boost was activated (so they know it's active).
  Future<void> showBoostActivated({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _idBoostActivated,
      title,
      body,
      _details,
    );
  }

  /// Notify user about a shop unlock or purchase (so they know what they got).
  Future<void> showShopNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _idShopNotification,
      title,
      body,
      _details,
    );
  }

  static const int _idFcm = 50;

  /// Show a notification for an FCM message received in foreground.
  Future<void> showFcmNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _idFcm,
      title,
      body,
      _details,
    );
  }
}
