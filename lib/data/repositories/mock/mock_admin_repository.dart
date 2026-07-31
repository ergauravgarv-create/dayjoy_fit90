import 'dart:async';

import '../../mock/mock_data.dart';
import '../../models/admin_models.dart';
import '../../models/health_enums.dart';
import '../../models/participant.dart';
import '../admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  final StreamController<List<SubmissionReview>> _queue =
      StreamController<List<SubmissionReview>>.broadcast();

  @override
  Stream<AdminStats> watchStats() =>
      Stream<AdminStats>.value(MockData.adminStats);

  @override
  Stream<List<Participant>> watchParticipants() =>
      Stream<List<Participant>>.value(MockData.roster);

  @override
  Stream<List<SubmissionReview>> watchVerificationQueue() {
    scheduleMicrotask(() => _queue.add(MockData.verificationQueue));
    return _queue.stream;
  }

  @override
  Future<void> setSubmissionApproved(String id, bool approved) async {
    final i = MockData.verificationQueue.indexWhere((s) => s.id == id);
    if (i >= 0) {
      MockData.verificationQueue[i] = MockData.verificationQueue[i].copyWith(
        status: approved
            ? AdminVerificationStatus.approved
            : AdminVerificationStatus.rejected,
      );
      _queue.add(List.of(MockData.verificationQueue));
    }
  }

  @override
  Future<String> exportParticipantsCsv() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'https://mock.storage/dayjoy/exports/participants.csv';
  }
}
