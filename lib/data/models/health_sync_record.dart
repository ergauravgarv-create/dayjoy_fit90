import 'health_enums.dart';

/// A snapshot of health data read from Health Connect / HealthKit at one point
/// in time. Mirrors the Firestore `healthSyncs/{syncId}` document.
///
/// IMPORTANT: this is deliberately a SEPARATE object from
/// [DailyChallengeSnapshot]. Raw synced health data and challenge-completion
/// records must never be the same database entity — the challenge snapshot is
/// an auditable scoring record, this is just the sensor read that fed it.
class HealthSyncRecord {
  const HealthSyncRecord({
    required this.syncId,
    required this.participantId,
    required this.platform,
    required this.integrationType,
    required this.syncDate,
    required this.localDate,
    required this.timezone,
    required this.stepCount,
    this.distanceKm,
    this.activeCalories,
    this.workoutMinutes,
    this.weightKg,
    this.sourceType = SourceType.unknown,
    this.permissionStatus = PermissionStatus.notDetermined,
    required this.lastSyncAt,
    this.syncStatus = SyncStatus.idle,
    this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });

  final String syncId;
  final String participantId;
  final HealthPlatform platform;
  final IntegrationType integrationType;

  /// Instant the sync ran (UTC).
  final DateTime syncDate;

  /// The local calendar day (yyyy-MM-dd) the data belongs to.
  final String localDate;
  final String timezone;

  final int stepCount;
  final double? distanceKm;
  final double? activeCalories;
  final int? workoutMinutes;
  final double? weightKg;

  final SourceType sourceType;
  final PermissionStatus permissionStatus;
  final DateTime lastSyncAt;
  final SyncStatus syncStatus;
  final String? syncError;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthSyncRecord copyWith({
    int? stepCount,
    double? distanceKm,
    double? activeCalories,
    int? workoutMinutes,
    double? weightKg,
    SyncStatus? syncStatus,
    String? syncError,
    DateTime? lastSyncAt,
    DateTime? updatedAt,
    PermissionStatus? permissionStatus,
    SourceType? sourceType,
  }) {
    return HealthSyncRecord(
      syncId: syncId,
      participantId: participantId,
      platform: platform,
      integrationType: integrationType,
      syncDate: syncDate,
      localDate: localDate,
      timezone: timezone,
      stepCount: stepCount ?? this.stepCount,
      distanceKm: distanceKm ?? this.distanceKm,
      activeCalories: activeCalories ?? this.activeCalories,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      weightKg: weightKg ?? this.weightKg,
      sourceType: sourceType ?? this.sourceType,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'participantId': participantId,
        'platform': platform.name,
        'integrationType': integrationType.name,
        'syncDate': syncDate.toIso8601String(),
        'localDate': localDate,
        'timezone': timezone,
        'stepCount': stepCount,
        'distanceKm': distanceKm,
        'activeCalories': activeCalories,
        'workoutMinutes': workoutMinutes,
        'weightKg': weightKg,
        'sourceType': sourceType.name,
        'permissionStatus': permissionStatus.name,
        'lastSyncAt': lastSyncAt.toIso8601String(),
        'syncStatus': syncStatus.name,
        'syncError': syncError,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory HealthSyncRecord.fromJson(Map<String, dynamic> j) => HealthSyncRecord(
        syncId: j['syncId'] as String,
        participantId: j['participantId'] as String,
        platform: HealthPlatform.values.byName(j['platform'] as String),
        integrationType:
            IntegrationType.values.byName(j['integrationType'] as String),
        syncDate: DateTime.parse(j['syncDate'] as String),
        localDate: j['localDate'] as String,
        timezone: j['timezone'] as String,
        stepCount: (j['stepCount'] as num).toInt(),
        distanceKm: (j['distanceKm'] as num?)?.toDouble(),
        activeCalories: (j['activeCalories'] as num?)?.toDouble(),
        workoutMinutes: (j['workoutMinutes'] as num?)?.toInt(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        sourceType: SourceType.values.byName(j['sourceType'] as String),
        permissionStatus:
            PermissionStatus.values.byName(j['permissionStatus'] as String),
        lastSyncAt: DateTime.parse(j['lastSyncAt'] as String),
        syncStatus: SyncStatus.values.byName(j['syncStatus'] as String),
        syncError: j['syncError'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}
