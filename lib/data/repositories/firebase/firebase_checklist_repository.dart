// REAL IMPLEMENTATION — enable with cloud_firestore. Not compiled in mock mode.
//
// Writes land in participants/{uid}/days/{yyyy-MM-dd} in the exact shape the
// `awardDailyPoints` Cloud Function expects (tasks map + pointsAwarded=0 on
// create). Points/streak/badges are then computed server-side.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/daily_task.dart';
import '../checklist_repository.dart';

class FirebaseChecklistRepository implements ChecklistRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final Map<int, DailyChecklist> _cache = {};

  CollectionReference<Map<String, dynamic>> _days(String uid) =>
      _fs.collection('participants').doc(uid).collection('days');

  String _dateId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DailyChecklist _fromDoc(int day, DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return DailyChecklist.freshFor(day, DateTime.now());
    final data = snap.data() ?? {};
    final tasks = (data['tasks'] as Map?)?.cast<String, dynamic>() ?? const {};
    return DailyChecklist(
      day: (data['challengeDay'] as num?)?.toInt() ?? day,
      date: DateTime.now(),
      tasks: [
        for (final t in DailyTaskType.values)
          DailyTask(
            type: t,
            completed: (tasks[t.name] as Map?)?['completed'] == true,
            proofUrl: (tasks[t.name] as Map?)?['proofUrl'] as String?,
          ),
      ],
    );
  }

  @override
  Stream<DailyChecklist> watchToday(String uid, int day) {
    return _days(uid).doc(_dateId(DateTime.now())).snapshots().map((snap) {
      final c = _fromDoc(day, snap);
      _cache[day] = c;
      return c;
    });
  }

  @override
  DailyChecklist? currentSnapshot(String uid, int day) => _cache[day];

  @override
  Future<void> setTask(
    String uid,
    int day,
    DailyTaskType type, {
    required bool completed,
    String? proofUrl,
    int? verifiedSteps,
    String? verificationMethod,
  }) async {
    final dateId = _dateId(DateTime.now());
    final ref = _days(uid).doc(dateId);

    final taskPayload = <String, dynamic>{
      'completed': completed,
      if (proofUrl != null) 'proofUrl': proofUrl,
      if (verifiedSteps != null) 'verifiedSteps': verifiedSteps,
      if (verificationMethod != null) 'method': verificationMethod,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
    };

    // Transaction so the create path can set pointsAwarded=0 (required by the
    // security rule) without ever overwriting the server-set points on updates.
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, {
          'participantId': uid,
          'challengeDay': day,
          'activityDate': dateId,
          'pointsAwarded': 0,
          'tasks': {type.name: taskPayload},
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(
          ref,
          {
            'tasks': {type.name: taskPayload},
          },
          SetOptions(merge: true),
        );
      }
    });
  }
}
