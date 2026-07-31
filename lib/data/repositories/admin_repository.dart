import '../models/admin_models.dart';
import '../models/participant.dart';

/// Admin data access — dashboard stats, roster, verification queue, exports.
abstract interface class AdminRepository {
  Stream<AdminStats> watchStats();
  Stream<List<Participant>> watchParticipants();
  Stream<List<SubmissionReview>> watchVerificationQueue();

  /// Approve or reject a queued submission.
  Future<void> setSubmissionApproved(String id, bool approved);

  /// Kick off an export; returns a download URL (mock returns a placeholder;
  /// Firebase calls the `exportParticipantsCsv` function).
  Future<String> exportParticipantsCsv();
}
