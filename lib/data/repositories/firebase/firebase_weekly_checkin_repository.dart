// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/weekly_checkin.dart';
import '../weekly_checkin_repository.dart';

class FirebaseWeeklyCheckInRepository implements WeeklyCheckInRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final Map<String, WeeklyCheckIn> _latest = {};

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _fs.collection('participants').doc(uid).collection('weeklyCheckins');

  @override
  Stream<List<WeeklyCheckIn>> watchAll(String uid) =>
      _col(uid).orderBy('weekNumber').snapshots().map((q) {
        final list = q.docs.map((d) => WeeklyCheckIn.fromJson(d.data())).toList();
        if (list.isNotEmpty) _latest[uid] = list.last;
        return list;
      });

  @override
  WeeklyCheckIn? latestSnapshot(String uid) => _latest[uid];

  @override
  Future<void> submit(String uid, WeeklyCheckIn checkin) =>
      _col(uid).doc(checkin.weekId).set(checkin.toJson(), SetOptions(merge: true));
}
