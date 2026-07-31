// ---------------------------------------------------------------------------
// REAL IMPLEMENTATION — Android Health Connect.
//
// NOT part of the default build. To enable:
//   1. Add to pubspec.yaml:  health: ^11.0.0   permission_handler: ^11.3.1
//   2. Uncomment the import + branch in health_data_service_factory.dart
//   3. Set HealthDataServiceFactory.forceMock = false
//   4. Add the Health Connect permissions to AndroidManifest (see
//      docs/camera_health_setup.md).
//
// The `health` package unifies Health Connect + HealthKit. API names below
// target health ^11; adjust if your resolved version differs.
// ---------------------------------------------------------------------------
//
// ignore_for_file: unused_import
import 'dart:io' show Platform;

import '../../data/models/health_enums.dart';
import 'health_data_service.dart';

// import 'package:health/health.dart';

class AndroidHealthConnectService implements HealthDataService {
  // final Health _health = Health();
  DateTime? _lastSync;

  // The read-only data types Dayjoy requests initially. Keep this MINIMAL —
  // request only what the challenge actually needs (data minimisation).
  // static final List<HealthDataType> _types = <HealthDataType>[
  //   HealthDataType.STEPS,
  //   HealthDataType.DISTANCE_DELTA,
  //   HealthDataType.ACTIVE_ENERGY_BURNED,
  //   HealthDataType.WORKOUT,
  //   HealthDataType.WEIGHT, // only when the user chooses to import
  // ];

  @override
  HealthPlatform get platform => HealthPlatform.android;

  @override
  IntegrationType get integrationType => IntegrationType.healthConnect;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    // final status = await _health.getHealthConnectSdkStatus();
    // return status == HealthConnectSdkStatus.sdkAvailable;
    throw UnimplementedError('Enable the `health` package to use this class.');
  }

  @override
  Future<bool> requestPermissions() async {
    // final permissions = _types.map((_) => HealthDataAccess.READ).toList();
    // final granted = await _health.requestAuthorization(_types,
    //     permissions: permissions);
    // return granted;
    throw UnimplementedError();
  }

  @override
  Future<PermissionStatus> permissionStatus() async {
    // final has = await _health.hasPermissions(_types,
    //     permissions: _types.map((_) => HealthDataAccess.READ).toList());
    // if (has == null) return PermissionStatus.notDetermined;
    // return has ? PermissionStatus.granted : PermissionStatus.denied;
    throw UnimplementedError();
  }

  @override
  Future<int> getTodaySteps() async {
    // Use Health Connect's AGGREGATED total for the local day so phone + watch
    // are merged without double counting.
    // final now = DateTime.now();
    // final midnight = DateTime(now.year, now.month, now.day);
    // final steps = await _health.getTotalStepsInInterval(midnight, now);
    // _lastSync = DateTime.now();
    // return steps ?? 0;
    throw UnimplementedError();
  }

  @override
  Future<double?> getTodayDistanceKm() async {
    // Sum DISTANCE_DELTA for the local day, convert metres → km.
    throw UnimplementedError();
  }

  @override
  Future<double?> getTodayActiveCalories() async {
    // Sum ACTIVE_ENERGY_BURNED for the local day (kcal).
    throw UnimplementedError();
  }

  @override
  Future<Duration?> getTodayWorkoutDuration() async {
    // Sum WORKOUT session durations for the local day.
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSync;

  @override
  Future<void> openPermissionSettings() async {
    // await _health.hasPermissions(_types); // triggers HC permission UI, or
    // use permission_handler openAppSettings().
    throw UnimplementedError();
  }
}
