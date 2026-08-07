// Mobile (dart:io) implementation of the platform selector.
//
// This is the ONLY file that imports the real Health Connect / HealthKit
// services (which in turn import `package:health/health.dart`). It is swapped
// in by the factory's `if (dart.library.io)` conditional import, so it — and
// everything it pulls in — is compiled only for Android/iOS, never for web.
import 'dart:io' show Platform;

import 'android_health_connect_service.dart';
import 'health_data_service.dart';
import 'ios_healthkit_service.dart';

HealthDataService? createPlatformHealthService() {
  if (Platform.isAndroid) return AndroidHealthConnectService();
  if (Platform.isIOS) return IOSHealthKitService();
  return null; // Desktop → mock fallback in the factory.
}
