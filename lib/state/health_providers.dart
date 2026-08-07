import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/health_enums.dart';
import '../data/repositories/daily_activity_repository.dart';
import '../data/repositories/health_sync_repository.dart';
import '../services/audit/health_audit_service.dart';
import '../services/camera/camera_service.dart';
import '../services/camera/mock_camera_service.dart';
import '../services/consent/consent_management_service.dart';
import '../services/health/health_data_service.dart';
import '../services/health/health_data_service_factory.dart';
import '../services/health/mock_health_data_service.dart';
import '../services/image/duplicate_image_detection_service.dart';
import '../services/image/image_compression_service.dart';
import '../services/permission/permission_service.dart';
import '../services/upload/image_upload_service.dart';
import '../services/upload/offline_upload_queue.dart';

/// -------------------------------------------------------------------------
/// Service providers. Every one returns a mock/pure implementation by default,
/// so the whole engine is exercisable without native plugins. Swap the bodies
/// (or flip HealthDataServiceFactory.forceMock) to go live.
/// -------------------------------------------------------------------------

final healthServiceProvider = Provider<HealthDataService>((ref) {
  return const HealthDataServiceFactory().create();
});

final permissionServiceProvider =
    Provider<PermissionService>((ref) => MockPermissionService());

final cameraServiceProvider =
    Provider<CameraService>((ref) => MockCameraService());

final imageCompressionProvider = Provider<ImageCompressionService>(
    (ref) => const PassthroughImageCompressionService());

final duplicateDetectionProvider = Provider<DuplicateImageDetectionService>(
    (ref) => const ContentHashDuplicateService());

final imageUploadServiceProvider =
    Provider<ImageUploadService>((ref) => MockImageUploadService());

final offlineQueueProvider = Provider<OfflineUploadQueue>((ref) {
  final queue = OfflineUploadQueue(uploader: ref.watch(imageUploadServiceProvider));
  ref.onDispose(queue.dispose);
  return queue;
});

final consentServiceProvider =
    Provider<ConsentManagementService>((ref) => InMemoryConsentService());

final healthAuditServiceProvider =
    Provider<HealthAuditService>((ref) => InMemoryHealthAuditService());

final healthSyncRepositoryProvider = Provider<HealthSyncRepository>((ref) {
  return HealthSyncRepository(
    health: ref.watch(healthServiceProvider),
    audit: ref.watch(healthAuditServiceProvider),
  );
});

final dailyActivityRepositoryProvider =
    Provider<DailyActivityRepository>((ref) => DailyActivityRepository());

/// -------------------------------------------------------------------------
/// Connection state exposed to the Connect-Health screen & the step task.
/// -------------------------------------------------------------------------

class HealthConnectionState {
  const HealthConnectionState({
    this.available = false,
    this.permission = PermissionStatus.notDetermined,
    this.syncStatus = SyncStatus.idle,
    this.todaySteps = 0,
    this.distanceKm,
    this.activeCalories,
    this.workoutMinutes,
    this.sleepMinutes,
    this.lastSyncAt,
    this.error,
    this.integrationType = IntegrationType.none,
  });

  final bool available;
  final PermissionStatus permission;
  final SyncStatus syncStatus;
  final int todaySteps;
  final double? distanceKm;
  final double? activeCalories;
  final int? workoutMinutes;
  final int? sleepMinutes;
  final DateTime? lastSyncAt;
  final String? error;
  final IntegrationType integrationType;

  bool get connected => permission.isUsable;
  bool get goalReached => todaySteps >= 10000;
  double get stepProgress => (todaySteps / 10000).clamp(0.0, 1.0);

  HealthConnectionState copyWith({
    bool? available,
    PermissionStatus? permission,
    SyncStatus? syncStatus,
    int? todaySteps,
    double? distanceKm,
    double? activeCalories,
    int? workoutMinutes,
    int? sleepMinutes,
    DateTime? lastSyncAt,
    String? error,
    IntegrationType? integrationType,
  }) {
    return HealthConnectionState(
      available: available ?? this.available,
      permission: permission ?? this.permission,
      syncStatus: syncStatus ?? this.syncStatus,
      todaySteps: todaySteps ?? this.todaySteps,
      distanceKm: distanceKm ?? this.distanceKm,
      activeCalories: activeCalories ?? this.activeCalories,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error,
      integrationType: integrationType ?? this.integrationType,
    );
  }
}

final healthConnectionControllerProvider =
    NotifierProvider<HealthConnectionController, HealthConnectionState>(
        HealthConnectionController.new);

class HealthConnectionController extends Notifier<HealthConnectionState> {
  static const String _participantId = 'demo-user';

  @override
  HealthConnectionState build() {
    final service = ref.watch(healthServiceProvider);
    // Fire-and-forget: read availability/permission (and sync if already
    // granted) the first time anything watches this. No OS prompt is shown —
    // refresh() only reads status; connect() is what asks for permission.
    Future.microtask(refresh);
    return HealthConnectionState(integrationType: service.integrationType);
  }

  HealthDataService get _service => ref.read(healthServiceProvider);

  /// Read current availability + permission + values without prompting.
  Future<void> refresh() async {
    final bool available = await _service.isAvailable();
    final PermissionStatus perm = await _service.permissionStatus();
    state = state.copyWith(
      available: available,
      permission: perm,
      integrationType: _service.integrationType,
    );
    if (perm.isUsable) await syncNow();
  }

  /// Request permissions (shows the OS sheet), then sync.
  Future<void> connect() async {
    final bool available = await _service.isAvailable();
    if (!available) {
      state = state.copyWith(
        available: false,
        permission: PermissionStatus.unavailable,
        error: 'Health service is not available on this device.',
      );
      return;
    }
    final bool granted = await _service.requestPermissions();
    final PermissionStatus perm = await _service.permissionStatus();
    state = state.copyWith(available: true, permission: perm);
    if (granted) await syncNow();
  }

  /// Pull today's metrics into a HealthSyncRecord and into state.
  Future<void> syncNow() async {
    state = state.copyWith(syncStatus: SyncStatus.syncing, error: null);
    final record =
        await ref.read(healthSyncRepositoryProvider).syncNow(_participantId);
    if (record.syncStatus == SyncStatus.failed) {
      state = state.copyWith(
          syncStatus: SyncStatus.failed, error: record.syncError);
      return;
    }
    state = state.copyWith(
      syncStatus: SyncStatus.success,
      todaySteps: record.stepCount,
      distanceKm: record.distanceKm,
      activeCalories: record.activeCalories,
      workoutMinutes: record.workoutMinutes,
      sleepMinutes: record.sleepMinutes,
      lastSyncAt: record.lastSyncAt,
      permission: record.permissionStatus,
    );
  }

  /// Demo helper: simulate crossing the 10k goal, then sync.
  Future<void> simulateReachGoal() async {
    final service = _service;
    if (service is MockHealthDataService) service.bumpToGoal();
    await syncNow();
  }

  /// Clear app-side connection. Full revocation happens in OS settings.
  void disconnect() {
    state = HealthConnectionState(
      available: state.available,
      integrationType: state.integrationType,
    );
  }
}
