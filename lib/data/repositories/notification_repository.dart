import '../models/app_notification.dart';

/// Reads & updates the participant's in-app notification inbox.
abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch(String uid);
  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
}
