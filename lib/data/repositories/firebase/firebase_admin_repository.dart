// REAL IMPLEMENTATION — enable with cloud_firestore + cloud_functions. Not
// compiled in mock mode.
//
// Operational counters (active today, submissions today, appointments today,
// the 7-day series) are best served from a small aggregated doc maintained by a
// Cloud Function; here they're derived where cheap and left at 0 otherwise.
//
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/admin_models.dart';
import '../../models/health_enums.dart';
import '../../models/participant.dart';
import '../admin_repository.dart';

class FirebaseAdminRepository implements AdminRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Participant _participant(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = {...(d.data() ?? {}), 'id': d.id};
    if (data['startDate'] is Timestamp) {
      data['startDate'] = (data['startDate'] as Timestamp).toDate().toIso8601String();
    }
    return Participant.fromJson(data);
  }

  @override
  Stream<AdminStats> watchStats() =>
      _fs.collection('participants').snapshots().map((q) {
        final parts = q.docs.map((d) => d.data());
        double totalLost = 0;
        double completionSum = 0;
        for (final p in parts) {
          final double start = (p['startWeightKg'] as num?)?.toDouble() ?? 0.0;
          final double current =
              (p['currentWeightKg'] as num?)?.toDouble() ?? start;
          totalLost += (start - current).clamp(0.0, 999.0);
          completionSum += (p['completionRate'] as num?)?.toDouble() ?? 0.0;
        }
        final n = q.size;
        return AdminStats(
          totalParticipants: n,
          activeToday: 0, // ← from aggregated stats doc in production
          submissionsToday: 0,
          avgCompletion: n == 0 ? 0 : completionSum / n,
          pendingVerifications: 0,
          totalWeightLostKg: double.parse(totalLost.toStringAsFixed(1)),
          appointmentsToday: 0,
          completionSeries: const [0, 0, 0, 0, 0, 0, 0],
        );
      });

  @override
  Stream<List<Participant>> watchParticipants() =>
      _fs.collection('participants').snapshots().map(
            (q) => q.docs.map(_participant).toList(),
          );

  @override
  Stream<List<SubmissionReview>> watchVerificationQueue() => _fs
      .collectionGroup('submissions')
      .where('adminVerificationStatus', isEqualTo: 'pending')
      .snapshots()
      .map((q) => q.docs.map((d) {
            final m = d.data();
            return SubmissionReview(
              // Full path so setSubmissionApproved can target it directly.
              id: d.reference.path,
              participantName: m['participantName'] as String? ??
                  (d.reference.parent.parent?.id ?? 'Participant'),
              taskTitle: m['taskTitle'] as String? ?? m['taskKey'] as String? ?? 'Task',
              method: _method(m['method'] as String?),
              submittedAt:
                  (m['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              flaggedDuplicate: m['duplicate'] == true,
              isLate: m['isLate'] == true,
            );
          }).toList());

  VerificationMethod _method(String? raw) {
    switch (raw) {
      case 'automaticHealthSync':
        return VerificationMethod.automaticHealthSync;
      case 'manualEntry':
        return VerificationMethod.manualEntry;
      default:
        return VerificationMethod.screenshot;
    }
  }

  @override
  Future<void> setSubmissionApproved(String id, bool approved) => _fs.doc(id).set(
        {'adminVerificationStatus': approved ? 'approved' : 'rejected'},
        SetOptions(merge: true),
      );

  @override
  Future<String> exportParticipantsCsv() async {
    final callable =
        FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('exportParticipantsCsv');
    final res = await callable.call<Map<String, dynamic>>();
    return res.data['url'] as String? ?? '';
  }
}
