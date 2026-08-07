// Default (web / non-io) implementation of the platform selector.
//
// On the web there is no Health Connect / HealthKit, so we return null and the
// factory falls back to the mock. This file imports nothing platform-specific,
// keeping the dart2js web build free of dart:io and the `health` package.
import 'health_data_service.dart';

HealthDataService? createPlatformHealthService() => null;
