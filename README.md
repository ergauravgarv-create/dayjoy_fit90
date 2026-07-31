# Dayjoy Fit90 🌿

**90 Days Weight Transformation Challenge** — *Transform Yourself. One Day at a Time.*

A premium Flutter wellness app that replaces WhatsApp reporting for the Dayjoy
90-day challenge. This repository is the **runnable app skeleton**: the design
system, navigation shell, onboarding/auth flow, and the five core participant
screens — all wired with Riverpod and **backed by mock data so it runs before
Firebase is even configured**.

---

## ▶️ Run it in 3 steps

This repo currently contains `lib/`, tests, and config. Generate the native
platform folders (android/ios/web) and run:

```bash
cd dayjoy_fit90
flutter create .        # generates android/, ios/, web/ around the existing lib/
flutter pub get
flutter run             # boots straight into the app with demo data
```

> `flutter create .` will **not** overwrite the files already here — it only
> adds the missing platform scaffolding. Requires Flutter 3.19+ / Dart 3.3+.

Walk the flow: **Splash → Onboarding → Phone → OTP** (any 6 digits) **→ Home**,
then explore the 5 tabs. On the **Today** tab, tap all five tasks to trigger the
confetti + "Day Completed" celebration.

Run the tests:

```bash
flutter test
```

---

## 🗂 Project structure

```
lib/
├─ main.dart                      # entry + (commented) Firebase bootstrap
├─ app.dart                       # MaterialApp.router, light/dark themes
├─ core/
│  ├─ constants/                  # app constants, roles, task enums
│  ├─ router/app_router.dart      # go_router + StatefulShellRoute (bottom nav)
│  └─ theme/                      # colors, typography, spacing, Material 3 theme
├─ data/
│  ├─ models/                     # Participant, DailyTask/Checklist, Leaderboard
│  └─ mock/mock_data.dart         # seed data for the runnable demo
├─ state/providers.dart          # Riverpod providers (single source of truth)
├─ shared/widgets/               # GlassCard, ProgressRing, StatTile, charts…
└─ features/
   ├─ splash/  onboarding/  auth/ # phone + OTP
   ├─ shell/                      # bottom-navigation scaffold
   ├─ home/                       # dashboard: progress ring, stats, weight graph
   ├─ checklist/                  # 5 daily tasks + confetti celebration
   ├─ progress/                   # charts, BMI, transformation gallery
   ├─ leaderboard/                # podium + ranked list
   └─ profile/                    # care team, settings, logout
```

## 🎨 Design system

| Token        | Value                         |
|--------------|-------------------------------|
| Primary      | `#0D8B6F`                     |
| Secondary    | `#1FBF75`                     |
| Accent       | `#FFB800`                     |
| Background   | `#F7FAF9`                     |
| Type         | Plus Jakarta Sans + Inter     |
| Radius       | 12 / 18 / 24 / 32, pill       |

Everything lives in `lib/core/theme/`. Re-brand by editing `app_colors.dart` and
`app_typography.dart` — no other file references raw colors or fonts.

## 🔌 Going live with Firebase

1. `flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage firebase_messaging firebase_analytics` (or uncomment them in `pubspec.yaml`).
2. `dart pub global activate flutterfire_cli && flutterfire configure` — generates `lib/firebase_options.dart`.
3. Uncomment the `Firebase.initializeApp(...)` block in `main.dart`.
4. Replace the mock notifiers in `lib/state/providers.dart` with
   Firestore-backed repositories — the UI does not change, only the data source.

## 🧭 What's here vs. what's next

**In this skeleton**
- ✅ Full design system, light + dark, Material 3
- ✅ Splash, onboarding, phone + OTP flow (mock)
- ✅ Bottom-nav shell + 5 participant screens with real charts & animations
- ✅ Daily checklist with points, streak pill, confetti celebration
- ✅ Riverpod state, immutable models, unit tests

**Camera + Health engine (now included)** — service-based, runs on mocks today
- `HealthDataService` interface + `MockHealthDataService`, plus ready-to-enable
  `AndroidHealthConnectService` / `IOSHealthKitService` (behind the `health` dep)
- `CameraService`, `ImageCompressionService` (EXIF strip), content-hash
  `DuplicateImageDetectionService`, `ImageUploadService`, `OfflineUploadQueue`
  (retry + connectivity), `PermissionService`, consent & audit services
- `HealthSyncRecord` + `DailyChallengeSnapshot` models (kept separate, with an
  audit trail so a delayed sync can never un-complete a goal)
- Screens: **Connect Health** (adapts Health Connect / Apple Health), **Activity
  submission** (capture → preview → retake/use → compress → dedup → upload), and
  the **10,000-step task** with Auto / Screenshot / Manual modes
- Native permission config in [docs/camera_health_setup.md](docs/camera_health_setup.md)
- Engine logic covered by `test/health_engine_test.dart`

> Try it: **Today → any photo task → Open Camera → Use Photo** (mock capture runs
> the full pipeline), and **Today → Daily Step Goal → Auto → "Demo: simulate
> reaching 10,000"** to complete via health sync.

**Firebase backend (now included)** — server-authoritative, in `functions/` + root rules
- `firestore.rules` + `storage.rules` — role-based (participant/coach/doctor/admin),
  with medical/progress data locked to self + doctor + admin
- `firestore.indexes.json`, `firebase.json` (incl. emulators)
- Cloud Functions (TypeScript, `functions/src/`): `awardDailyPoints`
  (points/streak/badges), `rebuildLeaderboards` (9 boards), `generateWeeklyReports`,
  FCM reminders + `dailyMotivation`, appointment + duplicate-photo guards,
  `setUserRole` / `claimParticipantRole`, `exportParticipantsCsv`
- Schema in [docs/firestore_schema.md](docs/firestore_schema.md), architecture +
  deploy in [docs/backend_architecture.md](docs/backend_architecture.md)

> The TypeScript wasn't compiled in this environment — run `cd functions && npm
> install && npm run build` to typecheck before first deploy.

**App ↔ backend wiring (now included)** — repository pattern, mock default
- Repository interfaces (`AuthRepository`, `ParticipantRepository`,
  `ChecklistRepository`, `LeaderboardRepository`, `FcmService`) with **mock impls
  wired as default** and **Firebase impls ready to enable**
- One composition root ([lib/state/repository_providers.dart](lib/state/repository_providers.dart))
  selects the backend from [AppConfig](lib/core/env/app_config.dart) — the UI is
  identical for both
- `AuthController` drives phone-OTP → verify → profile fetch → FCM token; the
  checklist persists in the exact shape `awardDailyPoints` expects
- Flip `AppConfig.backend = BackendMode.firebase`, enable the deps, uncomment 6
  lines → live. Full steps in
  [docs/flutter_firebase_wiring.md](docs/flutter_firebase_wiring.md)

**Coach / Doctor / Admin dashboards (now included)** — role-based
- Role-aware routing: after sign-in each role lands on its own dashboard
  (`Routes.forRole`). Role comes from the Firebase auth-token claim in live mode;
  in mock mode a **"Demo: sign in as" picker** on the login screen reaches all four.
- **Coach** ([coach_dashboard.dart](lib/features/staff/coach/coach_dashboard.dart)) —
  KPIs, appointment requests (confirm/decline), today's schedule, participant roster
- **Doctor** ([doctor_dashboard.dart](lib/features/staff/doctor/doctor_dashboard.dart)) —
  consultation requests, today's consults, patient list with medical actions
- **Admin** ([admin_dashboard.dart](lib/features/staff/admin/admin_dashboard.dart)) —
  KPI grid, 7-day completion chart, searchable participants, submission
  verification queue (approve/reject, duplicate/late flags), reports + CSV/PDF export
- Backed by `StaffRepository` / `AdminRepository` (mock-wired, Firebase-ready).

> Try it: on the login screen tap **Coach / Doctor / Admin**, send OTP, enter any
> 6 digits.

**Registration, weekly check-in & staff Firebase impls (now included)**
- **Registration** ([registration_screen.dart](lib/features/registration/registration_screen.dart)) —
  full profile form (photo, demographics, body/goals, food & activity, program,
  health, consent). New Firebase participants are routed here after first sign-in
  (`AuthState.needsRegistration`); it also powers **Profile → Edit profile**.
- **Weekly check-in** ([weekly_checkin_screen.dart](lib/features/checkin/weekly_checkin_screen.dart)) —
  weight/waist, front & side progress photos (camera pipeline), energy/sleep/
  digestion/mood ratings, notes, then a BMI + weight-lost summary. Reachable from
  the Home CTA.
- **Firebase impls** for `StaffRepository`, `AdminRepository`, and the new
  `WeeklyCheckInRepository` — ready-to-enable, same one-line-switch pattern.

**Badges, notifications & release docs (now included)**
- **Badges gallery** ([badges_gallery_screen.dart](lib/features/badges/badges_gallery_screen.dart)) —
  earned vs. locked grid with unlock progress; reachable from Profile → Badges.
- **Notifications inbox** ([notifications_screen.dart](lib/features/notifications/notifications_screen.dart)) —
  read/unread, mark-all-read, per-type icons; a **bell with unread badge** on Home.
- Both backed by `BadgeRepository` / `NotificationRepository` (mock + Firebase).
- Release docs: [deployment.md](docs/deployment.md),
  [google_play_checklist.md](docs/google_play_checklist.md),
  [app_store_checklist.md](docs/app_store_checklist.md).

**Localization (now included)** — `flutter_localizations` + gen-l10n
- ARB files in `lib/l10n/` for **English, Hindi, Marathi** (`app_en.arb` is the
  template); config in [l10n.yaml](l10n.yaml), `generate: true` in pubspec.
- Generated `AppLocalizations` is wired into `MaterialApp.router`
  ([app.dart](lib/app.dart)); an in-app **Language switcher** (Profile → Language)
  drives `localeProvider` (System / English / हिंदी / मराठी).
- **Every screen is localized** (~180 keys): splash, onboarding, login, OTP, nav,
  home, checklist + task tiles, activity submission, step task, progress,
  leaderboard, connect-health, registration, weekly check-in, badges,
  notifications, profile, and the coach/doctor/admin dashboards. Pattern:
  `final l = AppLocalizations.of(context);` then `l.someKey`. Enum labels
  (tasks, badges, statuses) map through helpers so stored values stay canonical.
- ⚠️ Run `flutter pub get` first — it generates `lib/l10n/gen/` (git-ignored);
  the app won't compile until that runs.

**Report charts + CI/CD (now included)**
- `WeeklyReport` model + repository (mock + Firebase) reading the
  `weeklyReports` docs the `generateWeeklyReports` function writes. The
  **Progress screen** now renders real report data: weight trend from weekly
  end-weights, a **weekly-completion bar chart**, and a "This week" summary
  (days completed, steps, active calories, completion rate).
- **GitHub Actions**: [ci.yml](.github/workflows/ci.yml) (analyze + test +
  functions build), [release.yml](.github/workflows/release.yml) (tag → signed
  AAB + optional functions deploy), and Dependabot. Details in
  [docs/ci_cd.md](docs/ci_cd.md).

**This completes the full build.** Only optional polish remains (e.g. a
native-speaker review of the hi/mr strings, real transformation-photo thumbnails).
- Full registration form, weekly check-in, badges gallery.
- Coach, Doctor, and Admin role dashboards.
- Deployment + Play/App Store checklists.

---

_Built as a production foundation, not a throwaway demo._
