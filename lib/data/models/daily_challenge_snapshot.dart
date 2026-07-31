import 'health_enums.dart';

/// The auditable challenge-scoring record for a single day's step goal (and,
/// by extension, any verified activity). Mirrors Firestore
/// `dailySnapshots/{participantId}_{challengeDay}`.
///
/// This is intentionally distinct from [HealthSyncRecord]: it stores the value
/// that was *used for scoring* plus how it was verified, and it keeps an audit
/// trail so a later health re-sync can never silently rewrite history.
class DailyChallengeSnapshot {
  const DailyChallengeSnapshot({
    required this.participantId,
    required this.challengeDay,
    required this.activityDate,
    required this.verifiedStepCount,
    required this.stepGoal,
    required this.stepGoalCompleted,
    required this.verificationMethod,
    this.healthSyncReference,
    this.screenshotReference,
    this.adminVerificationStatus = AdminVerificationStatus.pending,
    this.completionTime,
    this.pointsAwarded = 0,
    this.auditTrail = const [],
  });

  final String participantId;
  final int challengeDay;
  final String activityDate; // yyyy-MM-dd local
  final int verifiedStepCount;
  final int stepGoal;
  final bool stepGoalCompleted;
  final VerificationMethod verificationMethod;

  /// Pointer to the [HealthSyncRecord.syncId] that produced this, if auto.
  final String? healthSyncReference;

  /// Storage path of the screenshot proof, if screenshot/manual.
  final String? screenshotReference;

  final AdminVerificationStatus adminVerificationStatus;
  final DateTime? completionTime;
  final int pointsAwarded;

  /// Append-only history of value changes (never overwrite the daily value
  /// without recording why). See [reconcileSteps].
  final List<StepAuditEntry> auditTrail;

  double get progress =>
      stepGoal == 0 ? 0.0 : (verifiedStepCount / stepGoal).clamp(0.0, 1.0);

  /// Apply a fresh verified step reading. Historical values are never lowered
  /// merely because a later sync reports fewer steps (e.g. sync delay); the
  /// change is always appended to [auditTrail].
  DailyChallengeSnapshot reconcileSteps({
    required int incomingSteps,
    required VerificationMethod method,
    String? healthSyncReference,
    required DateTime at,
    required String reason,
  }) {
    final int resolved =
        incomingSteps > verifiedStepCount ? incomingSteps : verifiedStepCount;
    final bool completed = resolved >= stepGoal;
    return DailyChallengeSnapshot(
      participantId: participantId,
      challengeDay: challengeDay,
      activityDate: activityDate,
      verifiedStepCount: resolved,
      stepGoal: stepGoal,
      stepGoalCompleted: completed,
      verificationMethod: method,
      healthSyncReference: healthSyncReference ?? this.healthSyncReference,
      screenshotReference: screenshotReference,
      adminVerificationStatus: method == VerificationMethod.automaticHealthSync
          ? AdminVerificationStatus.autoVerified
          : adminVerificationStatus,
      completionTime: completed ? (completionTime ?? at) : completionTime,
      pointsAwarded: completed && pointsAwarded == 0 ? 20 : pointsAwarded,
      auditTrail: [
        ...auditTrail,
        StepAuditEntry(
          at: at,
          previous: verifiedStepCount,
          next: resolved,
          method: method,
          reason: reason,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'participantId': participantId,
        'challengeDay': challengeDay,
        'activityDate': activityDate,
        'verifiedStepCount': verifiedStepCount,
        'stepGoal': stepGoal,
        'stepGoalCompleted': stepGoalCompleted,
        'verificationMethod': verificationMethod.name,
        'healthSyncReference': healthSyncReference,
        'screenshotReference': screenshotReference,
        'adminVerificationStatus': adminVerificationStatus.name,
        'completionTime': completionTime?.toIso8601String(),
        'pointsAwarded': pointsAwarded,
        'auditTrail': auditTrail.map((e) => e.toJson()).toList(),
      };

  factory DailyChallengeSnapshot.fresh({
    required String participantId,
    required int challengeDay,
    required String activityDate,
    required int stepGoal,
  }) =>
      DailyChallengeSnapshot(
        participantId: participantId,
        challengeDay: challengeDay,
        activityDate: activityDate,
        verifiedStepCount: 0,
        stepGoal: stepGoal,
        stepGoalCompleted: false,
        verificationMethod: VerificationMethod.automaticHealthSync,
      );
}

/// One entry in a snapshot's audit trail.
class StepAuditEntry {
  const StepAuditEntry({
    required this.at,
    required this.previous,
    required this.next,
    required this.method,
    required this.reason,
  });

  final DateTime at;
  final int previous;
  final int next;
  final VerificationMethod method;
  final String reason;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'previous': previous,
        'next': next,
        'method': method.name,
        'reason': reason,
      };
}
