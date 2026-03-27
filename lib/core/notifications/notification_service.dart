import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

abstract final class NotificationIds {
  static const focusPhaseEnd = 9001;
}

/// Phase-end reminders when the app is backgrounded.
/// Android uses inexact scheduling where supported.
final class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(),
        macOS: const DarwinInitializationSettings(),
        linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'Mindfulness',
          appUserModelId: 'com.mindfulness.app.mindfulness',
          guid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> requestPermissionsIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedulePhaseEnd({
    required DateTime whenLocal,
    required String title,
    required String body,
  }) async {
    await cancelPhaseEnd();
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'focus_timer_v1',
        'Focus timer',
        channelDescription: 'Phase completion',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final scheduled = tz.TZDateTime.from(whenLocal, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: NotificationIds.focusPhaseEnd,
        scheduledDate: scheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } on UnsupportedError {
      // Linux has no zonedSchedule in the federated implementation.
    }
  }

  Future<void> cancelPhaseEnd() =>
      _plugin.cancel(id: NotificationIds.focusPhaseEnd);
}
