# Dayjoy Fit90 — Deployment Guide

End-to-end steps to build, release, and operate the app + backend.

---

## 0. Prerequisites

- Flutter 3.19+ / Dart 3.3+, Android Studio + Xcode (for iOS)
- Node 20 (Cloud Functions), Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project (Blaze plan — required for Cloud Functions + outbound FCM)
- Apple Developer account ($99/yr) and Google Play Console account ($25 once)

## 1. Configure Firebase

```bash
firebase login
firebase use --add                 # pick/create the project, alias "prod"
dart pub global activate flutterfire_cli
flutterfire configure              # writes lib/firebase_options.dart + native config
```

Enable in the Firebase console:
- **Authentication → Phone** (add test numbers for QA)
- **Firestore** (production mode), **Storage**, **Cloud Messaging**, **Analytics**
- **App Check** (Play Integrity + DeviceCheck/App Attest) — recommended

## 2. Flip the app to the live backend

1. Uncomment the `firebase_*` deps in `pubspec.yaml`; `flutter pub get`.
2. Uncomment the Firebase branches + imports in
   `lib/state/repository_providers.dart`, and `Firebase.initializeApp()` in
   `lib/main.dart` (see `docs/flutter_firebase_wiring.md`).
3. Set `AppConfig.backend = BackendMode.firebase` in `lib/core/env/app_config.dart`.
4. For camera/health, follow `docs/camera_health_setup.md`.

## 3. Deploy rules, indexes, functions

```bash
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions
```

Seed the first admin (once) from a trusted shell:
```bash
firebase functions:shell
# > setUserRole({ uid: '<uid>', role: 'admin' })
```

Seed `quotes/*` and `config/app` docs (step goal, reminder times, toggles).

## 4. Android build

`android/app/build.gradle`:
- `applicationId "com.dayjoy.fit90"`, `minSdkVersion 26`, `targetSdkVersion 34+`
- Add the Google Services plugin; ensure `google-services.json` is in `android/app/`.

Signing (`android/key.properties` + keystore, **never** commit):
```
storeFile=../keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Build the release bundle:
```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

## 5. iOS build

- Xcode → Runner → Signing & Capabilities: set team, bundle id `com.dayjoy.fit90`,
  add **HealthKit** + **Push Notifications** + **Background Modes → Remote notifications**.
- Upload the **APNs auth key (.p8)** to Firebase → Cloud Messaging.
- Set version/build, then:
```bash
flutter build ipa --release
# open build/ios/archive/*.xcarchive in Xcode Organizer → Distribute → App Store Connect
```

## 6. Versioning

`pubspec.yaml` `version: 1.0.0+1` → `1.0.0` is the store version, `+1` the build
number. Bump the build number every upload; bump the semver for user-facing releases.

## 7. Environments (recommended)

Use two Firebase projects (`dayjoy-dev`, `dayjoy-prod`) and Flutter flavors, or
`--dart-define=ENV=prod`. Point `flutterfire configure` at each project and keep
separate `google-services.json` / `GoogleService-Info.plist` per flavor.

## 8. CI/CD (optional)

- GitHub Actions: `flutter analyze`, `flutter test`, build AAB/IPA on tags.
- Fastlane for store uploads; Firebase App Distribution for internal QA builds.
- `firebase deploy --only functions` on merge to `main` (functions folder changes).

## 9. Post-launch operations

- **Monitoring**: Crashlytics, Cloud Functions logs (`firebase functions:log`),
  Firestore usage dashboard.
- **Scheduled functions**: verify the reminder/report/ranking schedules ran
  (Cloud Scheduler console).
- **Cost control**: watch Firestore reads from the hourly `rebuildLeaderboards`;
  migrate to incremental counters if the participant count grows large.
- **Backups**: enable scheduled Firestore exports to GCS.

## 10. Release checklist

- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Rules + indexes deployed and tested with the emulator suite
- [ ] Functions deployed; schedules confirmed; first admin seeded
- [ ] Phone auth works on a real device (SHA keys / APNs configured)
- [ ] Camera + health permissions prompt correctly on Android & iOS
- [ ] Privacy Policy + Terms URLs live and linked in-app
- [ ] Store listings complete (see the Play & App Store checklists)
