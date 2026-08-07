import 'package:flutter/foundation.dart';

import 'health_data_service.dart';
import 'mock_health_data_service.dart';
// Web-safe platform selection: the stub returns null (→ mock); on mobile the
// dart:io variant returns the real Health Connect / HealthKit service. Because
// only the io variant imports `package:health`, the web build never compiles
// the plugin and dart2js stays clean.
import 'platform_health_service.dart'
    if (dart.library.io) 'platform_health_service_io.dart';

/// Chooses the correct [HealthDataService] for the current platform.
///
/// • Web / desktop / unsupported → [MockHealthDataService] (deterministic demo).
/// • Android → AndroidHealthConnectService (real steps via Health Connect).
/// • iOS     → IOSHealthKitService (real steps via HealthKit).
class HealthDataServiceFactory {
  const HealthDataServiceFactory();

  /// Force the mock regardless of platform (tests / demo screenshots).
  static bool forceMock = false;

  HealthDataService create() {
    if (forceMock || kIsWeb) return MockHealthDataService();
    return createPlatformHealthService() ?? MockHealthDataService();
  }
}
