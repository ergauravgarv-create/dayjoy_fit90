import 'package:flutter/foundation.dart';

import 'health_data_service.dart';
import 'mock_health_data_service.dart';

// ---------------------------------------------------------------------------
// GOING LIVE: uncomment these imports and the branches below, and enable the
// `health` + `permission_handler` dependencies in pubspec.yaml. The real
// implementations live in android_health_connect_service.dart /
// ios_healthkit_service.dart. Until then everything runs on the mock so the
// app builds with zero native/health dependencies.
// ---------------------------------------------------------------------------
// import 'dart:io' show Platform;
// import 'android_health_connect_service.dart';
// import 'ios_healthkit_service.dart';

/// Chooses the correct [HealthDataService] for the current platform.
class HealthDataServiceFactory {
  const HealthDataServiceFactory();

  /// Set true in tests / demo to force the mock regardless of platform.
  static bool forceMock = true;

  HealthDataService create() {
    if (forceMock || kIsWeb) return MockHealthDataService();

    // if (Platform.isAndroid) return AndroidHealthConnectService();
    // if (Platform.isIOS) return IOSHealthKitService();

    return MockHealthDataService();
  }
}
