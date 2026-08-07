// ---------------------------------------------------------------------------
// REAL IMPLEMENTATION — Android Health Connect (via the `health` package).
//
// This file imports `package:health/health.dart` + dart:io, so it is compiled
// ONLY on mobile. It is reachable exclusively through
// platform_health_service_io.dart, which the factory swaps in behind a
// `if (dart.library.io)` conditional import — the web build never sees it.
//
// Requirements (already wired in this repo):
//   • pubspec:   health: ^11.0.0
//   • Manifest:  android.permission.health.READ_* + rationale intent-filter
//   • MainActivity extends FlutterFragmentActivity (Health Connect needs it)
// ---------------------------------------------------------------------------
import 'dart:io' show Platform;

import 'package:health/health.dart';

import '../../data/models/health_enums.dart' as app;
import 'health_data_service.dart';

class AndroidHealthConnectService implements HealthDataService {
  final Health _health = Health();
  bool _configured = false;
  DateTime? _lastSync;

  // Read-only types Dayjoy needs. Keep MINIMAL (data minimisation).
  static final List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_ASLEEP,
  ];

  List<HealthDataAccess> get _access =>
      _types.map((_) => HealthDataAccess.READ).toList();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  app.HealthPlatform get platform => app.HealthPlatform.android;

  @override
  app.IntegrationType get integrationType => app.IntegrationType.healthConnect;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(_types, permissions: _access);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<app.PermissionStatus> permissionStatus() async {
    try {
      await _ensureConfigured();
      final bool? has =
          await _health.hasPermissions(_types, permissions: _access);
      if (has == null) return app.PermissionStatus.notDetermined;
      return has ? app.PermissionStatus.granted : app.PermissionStatus.denied;
    } catch (_) {
      return app.PermissionStatus.notDetermined;
    }
  }

  ({DateTime start, DateTime end}) get _today {
    final now = DateTime.now();
    return (start: DateTime(now.year, now.month, now.day), end: now);
  }

  @override
  Future<int> getTodaySteps() async {
    try {
      await _ensureConfigured();
      final t = _today;
      // Aggregated total merges phone + watch without double counting.
      final int? steps = await _health.getTotalStepsInInterval(t.start, t.end);
      _lastSync = DateTime.now();
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _sumNumeric(HealthDataType type) async {
    await _ensureConfigured();
    final t = _today;
    final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
      types: [type],
      startTime: t.start,
      endTime: t.end,
    );
    final deduped = _health.removeDuplicates(points);
    double total = 0;
    for (final p in deduped) {
      final v = p.value;
      if (v is NumericHealthValue) total += v.numericValue.toDouble();
    }
    return total;
  }

  @override
  Future<double?> getTodayDistanceKm() async {
    try {
      final metres = await _sumNumeric(HealthDataType.DISTANCE_DELTA);
      return metres > 0 ? metres / 1000.0 : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getTodayActiveCalories() async {
    try {
      final kcal = await _sumNumeric(HealthDataType.ACTIVE_ENERGY_BURNED);
      return kcal > 0 ? kcal : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Duration?> getTodayWorkoutDuration() async {
    try {
      await _ensureConfigured();
      final t = _today;
      final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: t.start,
        endTime: t.end,
      );
      int minutes = 0;
      for (final p in points) {
        minutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
      return minutes > 0 ? Duration(minutes: minutes) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Duration?> getTodaySleep() async {
    try {
      await _ensureConfigured();
      // Sleep happens overnight, so look back from yesterday midday to now.
      final now = DateTime.now();
      final start =
          DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 12));
      final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: now,
      );
      final deduped = _health.removeDuplicates(points);
      int minutes = 0;
      for (final p in deduped) {
        minutes += p.dateTo.difference(p.dateFrom).inMinutes;
      }
      return minutes > 0 ? Duration(minutes: minutes) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSync;

  @override
  Future<void> openPermissionSettings() async {
    // Nudge the user to (re)install / open Health Connect if the provider is
    // missing; the OS handles the permission-management screen from there.
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      if (status ==
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        await _health.installHealthConnect();
      }
    } catch (_) {
      // Best-effort only.
    }
  }
}
