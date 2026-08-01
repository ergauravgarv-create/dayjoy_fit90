import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

NotificationService createNotificationService() => _LocalNotificationService();

/// Mobile implementation backed by flutter_local_notifications. All calls are
/// safe to invoke repeatedly; [init] runs once. Failures are swallowed so a
/// device quirk never crashes the app.
class _LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'dayjoy_reminders',
    'Daily reminders',
    channelDescription: 'Reminders for your daily Fit90 habits',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      // The programme is India-based, so schedule in IST.
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (_) {
      // Leave _ready false; scheduling calls will simply no-op.
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool? androidGranted =
          await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final bool? iosGranted = await ios?.requestPermissions(
          alert: true, badge: true, sound: true);

      return androidGranted ?? iosGranted ?? true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (_) {
      // Ignore scheduling failures (e.g. permission not granted yet).
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
