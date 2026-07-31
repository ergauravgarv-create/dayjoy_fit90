// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_notification.dart';
import '../notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _fs.collection('participants').doc(uid).collection('notifications');

  @override
  Stream<List<AppNotification>> watch(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map((d) {
            final data = {...d.data()};
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] =
                  (data['createdAt'] as Timestamp).toDate().toIso8601String();
            }
            return AppNotification.fromJson(d.id, data);
          }).toList());

  @override
  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).set({'read': true}, SetOptions(merge: true));

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).get();
    final batch = _fs.batch();
    for (final d in unread.docs) {
      batch.set(d.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
