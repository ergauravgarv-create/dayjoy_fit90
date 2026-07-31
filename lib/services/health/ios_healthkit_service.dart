// ---------------------------------------------------------------------------
// REAL IMPLEMENTATION — Apple HealthKit.
//
// NOT part of the default build. To enable:
//   1. Add to pubspec.yaml:  health: ^11.0.0
//   2. Uncomment the import + branch in health_data_service_factory.dart
//   3. Set HealthDataServiceFactory.forceMock = false
//   4. Add HealthKit capability + NSHealth*UsageDescription to Info.plist
//      and enable HealthKit under Signing & Capabilities in Xcode.
//      (See docs/camera_health_setup.md.)
// ---------------------------------------------------------------------------
//
// ignore_for_file: unused_import
import 'dart:io' show Platform;

import '../../data/models/health_enums.dart';
import 'health_data_service.dart';

// import 'package:health/health.dart';

class IOSHealthKitService implements HealthDataService {
  // final Health _health = Health();
  DateTime? _lastSync;

  // static final List<HealthDataType> _types = <HealthDataType>[
  //   HealthDataType.STEPS,
  //   HealthDataType.DISTANCE_WALKING_RUNNING,
  //   HealthDataType.ACTIVE_ENERGY_BURNED,
  //   HealthDataType.WORKOUT,
  //   HealthDataType.WEIGHT, // only when the user chooses
  // ];

  @override
  HealthPlatform get platform => HealthPlatform.ios;

  @override
  IntegrationType get integrationType => IntegrationType.healthKit;

  @override
  Future<bool> isAvailable() async => Platform.isIOS;

  @override
  Future<bool> requestPermissions() async {
    // final granted = await _health.requestAuthorization(_types,
    //     permissions: _types.map((_) => HealthDataAccess.READ).toList());
    // return granted;
    throw UnimplementedError('Enable the `health` package to use this class.');
  }

  @override
  Future<PermissionStatus> permissionStatus() async {
    // HealthKit deliberately does NOT reveal read authorization for privacy;
    // treat "no data returned after a granted request" as partiallyGranted and
    // always offer the screenshot fallback.
    // final has = await _health.hasPermissions(_types);
    // return (has ?? false)
    //     ? PermissionStatus.granted
    //     : PermissionStatus.notDetermined;
    throw UnimplementedError();
  }

  @override
  Future<int> getTodaySteps() async {
    // getTotalStepsInInterval correctly aggregates iPhone + Apple Watch.
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);
    // final steps = await _health.getTotalStepsInInterval(midnight, now);
    // _lastSync = DateTime.now();
    // return steps ?? 0;
    throw UnimplementedError();
  }

  @override
  Future<double?> getTodayDistanceKm() async => throw UnimplementedError();

  @override
  Future<double?> getTodayActiveCalories() async => throw UnimplementedError();

  @override
  Future<Duration?> getTodayWorkoutDuration() async =>
      throw UnimplementedError();

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSync;

  @override
  Future<void> openPermissionSettings() async {
    // iOS can't deep-link to the Health permission screen; instruct the user
    // to open Settings → Health → Data Access & Devices → Dayjoy Fit90.
    throw UnimplementedError();
  }
}
