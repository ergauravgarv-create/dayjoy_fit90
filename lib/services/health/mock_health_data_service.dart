import '../../data/models/health_enums.dart';
import 'health_data_service.dart';

/// Runnable, deterministic health source for the demo build and for tests.
/// Simulates a device that has ~8,450 steps so far today; call [bumpToGoal] to
/// simulate crossing 10,000 (used by the "Sync Now" button in the demo).
class MockHealthDataService implements HealthDataService {
  MockHealthDataService({
    this.available = true,
    this.startingSteps = 8450,
    PermissionStatus initialPermission = PermissionStatus.notDetermined,
  }) : _permission = initialPermission;

  final bool available;
  int startingSteps;
  PermissionStatus _permission;
  DateTime? _lastSync;

  @override
  HealthPlatform get platform => HealthPlatform.android;

  @override
  IntegrationType get integrationType => IntegrationType.healthConnect;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<PermissionStatus> permissionStatus() async => _permission;

  @override
  Future<bool> requestPermissions() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!available) {
      _permission = PermissionStatus.unavailable;
      return false;
    }
    _permission = PermissionStatus.granted;
    return true;
  }

  @override
  Future<int> getTodaySteps() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _lastSync = DateTime.now();
    return startingSteps;
  }

  @override
  Future<double?> getTodayDistanceKm() async => 6.2;

  @override
  Future<double?> getTodayActiveCalories() async => 420;

  @override
  Future<Duration?> getTodayWorkoutDuration() async =>
      const Duration(minutes: 38);

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSync;

  @override
  Future<void> openPermissionSettings() async {}

  /// Demo helper: simulate more activity so the 10k goal completes.
  void bumpToGoal() => startingSteps = 10450;
}
