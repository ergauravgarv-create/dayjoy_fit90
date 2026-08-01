import '../models/app_notification.dart';

/// Reads & updates the participant's in-app notification inbox.
abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);

  /// Post an announcement to every participant's inbox (admin/staff action).
  Future<void> addBroadcast({required String title, required String body});
}
