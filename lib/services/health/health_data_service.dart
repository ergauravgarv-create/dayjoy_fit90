import '../../data/models/health_enums.dart';

/// Common interface over Android Health Connect and Apple HealthKit. The exact
/// contract from the product brief, plus a few status accessors the UI needs.
///
/// Platform-specific implementations live behind this:
///   • [MockHealthDataService]      — default, runnable, for tests & demo
///   • AndroidHealthConnectService  — real, `health` package (guarded)
///   • IOSHealthKitService          — real, `health` package (guarded)
abstract interface class HealthDataService {
  /// Whether the platform health store is present & usable on this device.
  Future<bool> isAvailable();

  /// Request the read-only permissions Dayjoy needs. Returns true if usable
  /// (fully or partially granted).
  Future<bool> requestPermissions();

  /// Cumulative steps for the current *local* calendar day, aggregated across
  /// phone + watch without double counting.
  Future<int> getTodaySteps();

  Future<double?> getTodayDistanceKm();
  Future<double?> getTodayActiveCalories();
  Future<Duration?> getTodayWorkoutDuration();

  /// Timestamp of the last successful sync, or null if never synced.
  Future<DateTime?> getLastSyncTime();

  /// Open the platform's health-permission management screen.
  Future<void> openPermissionSettings();

  // --- Status accessors used by the Connect Health UI ------------------------

  HealthPlatform get platform;
  IntegrationType get integrationType;
  Future<PermissionStatus> permissionStatus();
}
