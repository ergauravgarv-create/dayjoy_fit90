import '../../services/health/step_aggregation_service.dart';
import '../models/daily_challenge_snapshot.dart';
import '../models/health_enums.dart';
import '../models/health_sync_record.dart';

/// Owns the [DailyChallengeSnapshot] scoring records. Kept separate from health
/// sync data on purpose — this is the auditable "what counted, and how it was
/// verified" record. In-memory here; back with Firestore (`dailySnapshots`).
class DailyActivityRepository {
  DailyActivityRepository({
    StepAggregationService aggregator = const StepAggregationService(),
    this.stepGoal = 10000,
  }) : _agg = aggregator;

  final StepAggregationService _agg;
  final int stepGoal;

  final Map<String, DailyChallengeSnapshot> _snapshots = {};

  String _key(String participantId, int day) => '${participantId}_$day';

  DailyChallengeSnapshot snapshotFor({
    required String participantId,
    required int challengeDay,
    required DateTime date,
  }) {
    return _snapshots.putIfAbsent(
      _key(participantId, challengeDay),
      () => DailyChallengeSnapshot.fresh(
        participantId: participantId,
        challengeDay: challengeDay,
        activityDate: _agg.localDateKey(date),
        stepGoal: stepGoal,
      ),
    );
  }

  /// Apply an automatic health sync to the day's step snapshot. Never lowers
  /// the stored value (delayed syncs can't un-complete the goal).
  DailyChallengeSnapshot applyHealthSync({
    required int challengeDay,
    required HealthSyncRecord sync,
  }) {
    final DailyChallengeSnapshot current = snapshotFor(
      participantId: sync.participantId,
      challengeDay: challengeDay,
      date: DateTime.now(),
    );
    final DailyChallengeSnapshot updated = current.reconcileSteps(
      incomingSteps: sync.stepCount,
      method: VerificationMethod.automaticHealthSync,
      healthSyncReference: sync.syncId,
      at: DateTime.now(),
      reason: 'Health sync (${sync.integrationType.name})',
    );
    _snapshots[_key(sync.participantId, challengeDay)] = updated;
    return updated;
  }

  /// Record a screenshot / manual step submission pending admin review.
  DailyChallengeSnapshot applyManualOrScreenshot({
    required String participantId,
    required int challengeDay,
    required int steps,
    required VerificationMethod method,
    String? screenshotReference,
    required String reason,
  }) {
    final DailyChallengeSnapshot current = snapshotFor(
      participantId: participantId,
      challengeDay: challengeDay,
      date: DateTime.now(),
    );
    var updated = current.reconcileSteps(
      incomingSteps: steps,
      method: method,
      at: DateTime.now(),
      reason: reason,
    );
    // Screenshot/manual entries are unverified until an admin approves.
    updated = DailyChallengeSnapshot(
      participantId: updated.participantId,
      challengeDay: updated.challengeDay,
      activityDate: updated.activityDate,
      verifiedStepCount: updated.verifiedStepCount,
      stepGoal: updated.stepGoal,
      stepGoalCompleted: updated.stepGoalCompleted,
      verificationMethod: method,
      healthSyncReference: updated.healthSyncReference,
      screenshotReference: screenshotReference,
      adminVerificationStatus: AdminVerificationStatus.pending,
      completionTime: updated.completionTime,
      pointsAwarded: updated.pointsAwarded,
      auditTrail: updated.auditTrail,
    );
    _snapshots[_key(participantId, challengeDay)] = updated;
    return updated;
  }
}
