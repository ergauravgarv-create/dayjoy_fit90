// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/weekly_report.dart';
import '../weekly_report_repository.dart';

class FirebaseWeeklyReportRepository implements WeeklyReportRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final Map<String, List<WeeklyReport>> _cache = {};

  @override
  Stream<List<WeeklyReport>> watchAll(String uid) => _fs
      .collection('participants')
      .doc(uid)
      .collection('weeklyReports')
      .orderBy('weekNumber')
      .snapshots()
      .map((q) {
        final list = q.docs.map((d) => WeeklyReport.fromJson(d.data())).toList();
        _cache[uid] = list;
        return list;
      });

  @override
  List<WeeklyReport>? currentSnapshot(String uid) => _cache[uid];
}
