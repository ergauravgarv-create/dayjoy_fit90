// ---------------------------------------------------------------------------
// REAL IMPLEMENTATION — Apple HealthKit (via the `health` package).
//
// Compiled ONLY on mobile (imports dart:io + package:health). Reached through
// platform_health_service_io.dart behind the factory's `if (dart.library.io)`
// conditional import, so the web build never compiles it.
//
// iOS setup (done in Xcode when you build for Apple):
//   • Enable the HealthKit capability under Signing & Capabilities.
//   • Add NSHealthShareUsageDescription to Info.plist.
// ---------------------------------------------------------------------------
import 'dart:io' show Platform;

import 'package:health/health.dart';

import '../../data/models/health_enums.dart' as app;
import 'health_data_service.dart';

class IOSHealthKitService implements HealthDataService {
  final Health _health = Health();
  bool _configured = false;
  DateTime? _lastSync;

  static final List<HealthDataType> _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
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
  app.HealthPlatform get platform => app.HealthPlatform.ios;

  @override
  app.IntegrationType get integrationType => app.IntegrationType.healthKit;

  @override
  Future<bool> isAvailable() async => Platform.isIOS;

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
    // HealthKit deliberately hides read authorization for privacy. Treat a
    // positive hasPermissions as granted, otherwise notDetermined; the UI
    // always keeps the screenshot fallback available.
    try {
      await _ensureConfigured();
      final bool? has =
          await _health.hasPermissions(_types, permissions: _access);
      return (has ?? false)
          ? app.PermissionStatus.granted
          : app.PermissionStatus.notDetermined;
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
      // Correctly aggregates iPhone + Apple Watch.
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
      final metres = await _sumNumeric(HealthDataType.DISTANCE_WALKING_RUNNING);
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
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(hours: 12));
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
    // iOS can't deep-link to the Health permission screen; the Connect screen
    // instructs the user to open Settings → Health → Data Access & Devices.
  }
}
