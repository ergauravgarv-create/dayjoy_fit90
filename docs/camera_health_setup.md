# Camera & Health Engine — Setup

This document contains everything needed to move the camera + health engine from
the **runnable mock build** to a **live device build**. The Dart architecture is
already in place (`lib/services/…`, `lib/data/models/…`, `lib/state/health_providers.dart`);
these steps enable the real plugins and native permissions.

---

## 1. Enable the dependencies

In `pubspec.yaml`, uncomment:

```yaml
camera: ^0.11.0
image: ^4.2.0
crypto: ^3.0.3
health: ^11.0.0
permission_handler: ^11.3.1
```

Then:

```bash
flutter pub get
```

## 2. Turn off the mock

In `lib/services/health/health_data_service_factory.dart`:

- Uncomment the `dart:io` + `android_health_connect_service.dart` + `ios_healthkit_service.dart` imports and the `Platform.isAndroid / isIOS` branches.
- Set `HealthDataServiceFactory.forceMock = false`.

Swap the mock service providers in `lib/state/health_providers.dart` (camera,
upload, compression, permissions) for the real implementations as you wire each
one up. The UI does not change — only the provider bodies.

---

## 3. Android configuration

### `android/app/src/main/AndroidManifest.xml`

Inside `<manifest>` (above `<application>`):

```xml
<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Health Connect: request ONLY what the challenge needs (read-only) -->
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_DISTANCE" />
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />

<!-- Do NOT add broad storage permissions. The system photo picker
     (used only when gallery upload is enabled) needs no storage permission. -->
```

Inside `<application>`, declare the Health Connect privacy-policy intent so the
Health Connect app can link to your policy:

```xml
<activity
    android:name=".MainActivity"
    ... >
    <!-- Health Connect permission rationale -->
    <intent-filter>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent-filter>
</activity>

<!-- Android 14+ alternative: -->
<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
    <intent-filter>
        <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
        <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
    </intent-filter>
</activity-alias>
```

### `android/app/build.gradle`
- `minSdkVersion 26` (Health Connect requires 26+).
- `compileSdkVersion 34` or higher.

### Health Connect availability
On devices without Health Connect, `getHealthConnectSdkStatus()` returns
`sdkUnavailableProviderUpdateRequired` — deep-link the user to the Play Store
listing `com.google.android.apps.healthdata`. The engine already falls back to
the screenshot flow when unavailable.

---

## 4. iOS configuration

### `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Dayjoy Fit90 uses your camera to capture daily challenge activities and weekly progress photographs.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Dayjoy Fit90 lets you attach a step-count screenshot when automatic health sync is unavailable.</string>

<key>NSHealthShareUsageDescription</key>
<string>Dayjoy Fit90 reads your steps, distance, active energy and workouts to track your daily challenge progress. It only reads what you approve.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Dayjoy Fit90 does not write to Apple Health; access is read-only.</string>
```

### Capabilities (Xcode → Signing & Capabilities)
- Add **HealthKit**.
- Add **Push Notifications** + **Background Modes → Remote notifications** (for FCM).

### `ios/Runner/Runner.entitlements`
```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

---

## 5. Permission-denied UX (already implemented)

`ConnectHealthScreen` handles every state gracefully — never a blank screen:

| State | UI |
|---|---|
| Not determined | "Connect & grant permissions" |
| Denied | Error text + **Try Again** |
| Permanently denied | **Open Settings** |
| Unavailable | Explanation + screenshot fallback |
| Connected | Steps, distance, calories, last sync, Sync Now / Manage / Disconnect |

The 10,000-step task (`StepTaskScreen`) always offers **Screenshot** and
(admin-gated) **Manual** modes when auto-sync isn't available.

---

## 6. Privacy commitments enforced in code

- Read-only health access; request the **minimum** data types.
- Camera does **not** require location; location is a separate optional consent
  (`ConsentManagementService`).
- EXIF stripped before upload (`ImageCompressionService.compress(stripExif: true)`).
- Original submission timestamp stored separately (`PhotoSubmission.capturedAt`).
- Duplicate detection by content hash, never filename
  (`DuplicateImageDetectionService`).
- Every health-data read is audit-logged (`HealthAuditService`).
- Health data is never sold, shared, or used for ads — enforce in Firestore
  security rules + privacy policy.
