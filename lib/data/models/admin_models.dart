import 'health_enums.dart';

/// Aggregate numbers for the admin dashboard.
class AdminStats {
  const AdminStats({
    required this.totalParticipants,
    required this.activeToday,
    required this.submissionsToday,
    required this.avgCompletion, // 0..1
    required this.pendingVerifications,
    required this.totalWeightLostKg,
    required this.appointmentsToday,
    required this.completionSeries, // last 7 days, 0..1
  });

  final int totalParticipants;
  final int activeToday;
  final int submissionsToday;
  final double avgCompletion;
  final int pendingVerifications;
  final double totalWeightLostKg;
  final int appointmentsToday;
  final List<double> completionSeries;
}

/// One row in the admin verification queue.
class SubmissionReview {
  const SubmissionReview({
    required this.id,
    required this.participantName,
    required this.taskTitle,
    required this.method,
    required this.submittedAt,
    this.status = AdminVerificationStatus.pending,
    this.flaggedDuplicate = false,
    this.isLate = false,
  });

  final String id;
  final String participantName;
  final String taskTitle;
  final VerificationMethod method;
  final DateTime submittedAt;
  final AdminVerificationStatus status;
  final bool flaggedDuplicate;
  final bool isLate;

  SubmissionReview copyWith({AdminVerificationStatus? status}) => SubmissionReview(
        id: id,
        participantName: participantName,
        taskTitle: taskTitle,
        method: method,
        submittedAt: submittedAt,
        status: status ?? this.status,
        flaggedDuplicate: flaggedDuplicate,
        isLate: isLate,
      );
}
