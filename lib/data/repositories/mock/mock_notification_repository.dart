import 'dart:async';

import '../../models/app_notification.dart';
import '../notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final StreamController<void> _tick = StreamController<void>.broadcast();
  late final List<AppNotification> _items = _seed();

  List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Day complete! 🎉',
        body: '+100 points earned. Streak: 12 days. Keep it going!',
        type: 'dayComplete',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Badge unlocked! 🏅',
        body: 'You earned the "Perfect Week" badge.',
        type: 'badge',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n3',
        title: '👟 Step goal check',
        body: 'Close in on your 10,000 steps today.',
        type: 'reminder',
        read: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      AppNotification(
        id: 'n4',
        title: '✨ Daily motivation',
        body: 'Small steps every day lead to big changes every year.',
        type: 'motivation',
        read: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
    ];
  }

  @override
  Stream<List<AppNotification>> watch(String uid) {
    scheduleMicrotask(() => _tick.add(null));
    return _tick.stream.map((_) => List<AppNotification>.of(_items));
  }

  @override
  Future<void> markRead(String uid, String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0 && !_items[i].read) {
      _items[i] = _items[i].copyWith(read: true);
      _tick.add(null);
    }
  }

  @override
  Future<void> markAllRead(String uid) async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    _tick.add(null);
  }

  int _broadcastSeq = 0;

  @override
  Future<void> addBroadcast(
      {required String title, required String body}) async {
    // The mock repo backs every participant with this one shared list, so the
    // announcement lands in the inbox immediately (in-memory for the demo).
    _items.insert(
      0,
      AppNotification(
        id: 'bcast-${_broadcastSeq++}',
        title: title,
        body: body,
        type: 'broadcast',
        createdAt: DateTime.now(),
      ),
    );
    _tick.add(null);
  }
}
