// The concrete factory `createNotificationService()` comes from the mobile
// implementation on platforms with dart:io, and a web no-op otherwise. This
// keeps flutter_local_notifications (which imports dart:io) out of the web
// build entirely.
export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_io.dart';

/// Schedules repeating daily local notifications. Real on mobile, no-op on web.
abstract class NotificationService {
  Future<void> init();

  /// Ask the OS for permission to post notifications. Returns true if granted
  /// (or not required on the platform).
  Future<bool> requestPermission();

  /// Schedule (or replace) a notification that repeats every day at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });

  Future<void> cancel(int id);
}
