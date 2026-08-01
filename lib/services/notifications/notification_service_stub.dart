import 'notification_service.dart';

/// Web (and any dart:io-less platform) build: reminders are a no-op. The
/// settings UI still works and persists; scheduling simply does nothing.
NotificationService createNotificationService() => _NoopNotificationService();

class _NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
