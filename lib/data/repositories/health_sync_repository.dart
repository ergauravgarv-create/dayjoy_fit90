import '../../services/audit/health_audit_service.dart';
import '../../services/health/health_data_service.dart';
import '../../services/health/step_aggregation_service.dart';
import '../models/health_enums.dart';
import '../models/health_sync_record.dart';

/// Reads the platform health source and produces [HealthSyncRecord]s. Persist
/// the returned record to Firestore (`healthSyncs`) in production. Every read
/// is written to the audit log.
class HealthSyncRepository {
  HealthSyncRepository({
    required HealthDataService health,
    required HealthAuditService audit,
    StepAggregationService aggregator = const StepAggregationService(),
  })  : _health = health,
        _audit = audit,
        _agg = aggregator;

  final HealthDataService _health;
  final HealthAuditService _audit;
  final StepAggregationService _agg;

  HealthSyncRecord? _latest;
  HealthSyncRecord? get latest => _latest;

  /// Pull today's metrics and build a sync record. Throws are caught and
  /// surfaced as a failed record so the UI never crashes on an unavailable
  /// permission or missing data.
  Future<HealthSyncRecord> syncNow(String participantId) async {
    final DateTime now = DateTime.now();
    final String localDate = _agg.localDateKey(now);
    final String syncId = '${participantId}_${localDate}_${now.millisecondsSinceEpoch}';

    await _audit.log(HealthAuditEvent(
      at: now,
      actorId: participantId,
      action: 'sync',
      participantId: participantId,
      detail: _health.integrationType.name,
    ));

    try {
      final PermissionStatus perm = await _health.permissionStatus();
      final int steps = await _health.getTodaySteps();
      final double? distance = await _health.getTodayDistanceKm();
      final double? calories = await _health.getTodayActiveCalories();
      final Duration? workout = await _health.getTodayWorkoutDuration();
      final DateTime? lastSync = await _health.getLastSyncTime();

      final HealthSyncRecord record = HealthSyncRecord(
        syncId: syncId,
        participantId: participantId,
        platform: _health.platform,
        integrationType: _health.integrationType,
        syncDate: now.toUtc(),
        localDate: localDate,
        timezone: now.timeZoneName,
        stepCount: steps,
        distanceKm: distance,
        activeCalories: calories,
        workoutMinutes: workout?.inMinutes,
        sourceType: SourceType.phone,
        permissionStatus: perm,
        lastSyncAt: lastSync ?? now,
        syncStatus: SyncStatus.success,
        createdAt: now,
        updatedAt: now,
      );
      _latest = record;
      return record;
    } catch (e) {
      final HealthSyncRecord failed = HealthSyncRecord(
        syncId: syncId,
        participantId: participantId,
        platform: _health.platform,
        integrationType: _health.integrationType,
        syncDate: now.toUtc(),
        localDate: localDate,
        timezone: now.timeZoneName,
        stepCount: _latest?.stepCount ?? 0,
        permissionStatus: PermissionStatus.denied,
        lastSyncAt: _latest?.lastSyncAt ?? now,
        syncStatus: SyncStatus.failed,
        syncError: e.toString(),
        createdAt: now,
        updatedAt: now,
      );
      // Keep the previous good value visible; only overwrite the status.
      _latest = _latest?.copyWith(
            syncStatus: SyncStatus.failed,
            syncError: e.toString(),
            updatedAt: now,
          ) ??
          failed;
      return failed;
    }
  }
}
