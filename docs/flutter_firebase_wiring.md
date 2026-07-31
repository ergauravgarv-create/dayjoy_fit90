# Wiring the Flutter app onto Firebase

The app talks only to **repository interfaces**. Mock implementations are the
default (runs today, no Firebase). Firebase implementations are written and ready
— going live is a switch plus enabling the dependencies. Nothing in the UI or
providers changes.

```
UI (screens)
   │  reads providers (providers.dart) — identical for both backends
   ▼
Repository interfaces (data/repositories/*.dart)
   │  chosen by AppConfig.backend in state/repository_providers.dart
   ├── mock/*          ← default, in-memory
   └── firebase/*      ← Firestore / Auth / Storage / FCM
```

## What's already wired

| Concern | Interface | Mock | Firebase |
|---|---|---|---|
| Auth (phone OTP) | `AuthRepository` | `MockAuthRepository` | `FirebaseAuthRepository` |
| Profile | `ParticipantRepository` | `MockParticipantRepository` | `FirebaseParticipantRepository` |
| Daily checklist | `ChecklistRepository` | `MockChecklistRepository` | `FirebaseChecklistRepository` |
| Leaderboard | `LeaderboardRepository` | `MockLeaderboardRepository` | `FirebaseLeaderboardRepository` |
| Push | `FcmService` | `MockFcmService` | `FirebaseFcmService` |

- `AuthController` (in `providers.dart`) runs send-OTP → verify → post-sign-in
  (fetch profile, register FCM token). The login/OTP screens already use it.
- `ChecklistNotifier.setTask` optimistically toggles, then persists to
  `participants/{uid}/days/{yyyy-MM-dd}` in the exact shape `awardDailyPoints`
  expects (tasks map + `pointsAwarded: 0` on create). Points/streak/badges come
  back from the function.
- Provider surface (`participantProvider`, `checklistProvider`,
  `leaderboardProvider`, `streakProvider`, …) is unchanged, so every screen works
  in both modes.

## Go-live checklist

1. **Enable deps** — uncomment in `pubspec.yaml`, then `flutter pub get`:
   ```yaml
   firebase_core: ^3.3.0
   firebase_auth: ^5.1.4
   cloud_firestore: ^5.2.1
   firebase_storage: ^12.1.3
   firebase_messaging: ^15.0.4
   firebase_analytics: ^11.2.1
   ```
2. **Native config** — `flutterfire configure` (or drop in `google-services.json`
   / `GoogleService-Info.plist`). For Android also add the Google Services Gradle
   plugin; for iOS add the `GoogleService-Info.plist` to the Runner target.
3. **Uncomment the branches**:
   - `lib/state/repository_providers.dart` — the 5 firebase imports + `return
     Firebase…()` lines.
   - `lib/main.dart` — the `firebase_core` import + `Firebase.initializeApp()`.
4. **Flip the switch** — `lib/core/env/app_config.dart`:
   ```dart
   static const BackendMode backend = BackendMode.firebase;
   ```
5. **Phone Auth prerequisites**
   - Enable **Phone** provider in Firebase Auth.
   - Android: add SHA-1/SHA-256 to the Firebase project (Play Integrity / SafetyNet).
   - iOS: upload the APNs auth key; enable Push Notifications + Background Modes.
   - For testing, add fictional test numbers in the Auth console.
6. **First run** — a new user signs in, then calls `claimParticipantRole` and
   writes their `participants/{uid}` profile. That registration form is the next
   slice; until it exists, seed a participant doc manually or reuse an existing one.

## Notes & gaps (by design, for the next slice)

- **Registration form** — in Firebase mode a brand-new user has no
  `participants/{uid}` doc yet, so `fetch` returns null. Build the registration
  flow (collecting the profile fields) to create it right after first sign-in.
- **Health steps** — `stepsProvider` still returns the mock value; wire it to the
  health engine's `HealthConnectionController` in a follow-up.
- **FCM background handler** — register a top-level
  `FirebaseMessaging.onBackgroundMessage` handler in `main.dart` when you enable
  push, and route taps via the notification `data.type`.
- **Weekly check-in & progress photos** — repositories for
  `weeklyCheckins` / Storage `progress/` follow the same interface pattern.
