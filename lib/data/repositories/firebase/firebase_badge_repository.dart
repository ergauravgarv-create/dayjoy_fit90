// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/badge.dart';
import '../badge_repository.dart';

class FirebaseBadgeRepository implements BadgeRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  @override
  Stream<List<AwardedBadge>> watch(String uid) => _fs
      .collection('participants')
      .doc(uid)
      .collection('badges')
      .orderBy('awardedAt')
      .snapshots()
      .map((q) => q.docs.map((d) {
            final data = {...d.data()};
            if (data['awardedAt'] is Timestamp) {
              data['awardedAt'] =
                  (data['awardedAt'] as Timestamp).toDate().toIso8601String();
            }
            data['id'] = d.id;
            return AwardedBadge.fromJson(data);
          }).toList());
}
