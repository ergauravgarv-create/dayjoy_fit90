# Dayjoy Fit90 — Backend Architecture

Firebase-native backend. The client never computes anything that affects
fairness — points, streaks, verification, leaderboards, and reports are all
produced by Cloud Functions using the Admin SDK (which bypasses security rules).
Clients only submit their own proofs and read what the rules allow.

```
┌────────────┐   phone OTP    ┌──────────────┐
│  Flutter   │ ─────────────▶ │ Firebase Auth │  (role = custom claim)
│  app       │                └──────────────┘
│            │  read/write (rules-gated)     ▲ setCustomUserClaims
│            │ ─────────────▶ ┌──────────────┐│
│            │                │  Firestore    │┼──────────┐ triggers
│            │ ◀───────────── │  + Storage    ││          ▼
└────────────┘   FCM push     └──────────────┘│   ┌───────────────┐
        ▲                             ▲        └──▶│ Cloud Functions│
        └─────────────────────────────┴───────────│  (asia-south1) │
                                                    └───────────────┘
```

## Function catalog

| Function | Trigger | Purpose |
|---|---|---|
| `awardDailyPoints` | Firestore write `days/{date}` | Recompute points by delta, advance streak on full completion, award streak badges, notify. Idempotent. |
| `rebuildLeaderboards` | Schedule (hourly) | Rebuild all 9 leaderboard boards. |
| `rebuildLeaderboardsNow` | Callable (admin) | Manual leaderboard rebuild. |
| `generateWeeklyReports` | Schedule (Mon 07:00 IST) | Per-participant weekly summary + BMI/weight change. |
| `generateMyWeeklyReport` | Callable (self/admin) | On-demand weekly report. |
| `remind*` (6) | Schedules (IST) | Task reminders to users who haven't done that task today. |
| `dailyMotivation` | Schedule (12:00 IST) | Daily quote push. |
| `onAppointmentWrite` | Firestore write `appointments/{id}` | Notify provider on request, participant on status change. |
| `appointmentReminders` | Schedule (30 min) | Remind both parties ~1h before. |
| `onSubmissionCreated` | Firestore create `submissions/{id}` | Cross-account duplicate-photo detection + audit. |
| `setUserRole` | Callable (admin) | Assign role (custom claim + `users` doc). |
| `claimParticipantRole` | Callable (new user) | Self-assign `participant` if roleless. |
| `exportParticipantsCsv` | Callable (admin) | CSV export → Storage → signed URL. |

## Ranking algorithm

One `participants` read + one `snapshots` collection-group scan per rebuild:

- **overall / highestStreak / maxWeightLost / mostConsistent** — sort participants
  by `totalPoints` / `streak` / (`startWeight − currentWeight`) / `completionRate`.
- **daily / weekly / monthly** — sum `snapshots.pointsAwarded` where
  `activityDate` ∈ window, grouped by `participantId`.
- **cities / distributors** — group participants by `city` / `distributorName`,
  sum points, rank.

Top `leaderboardSize` (100) written per board. For 10k+ participants, migrate the
period sums to incremental counters updated in `awardDailyPoints` instead of a
full scan.

## Weekly report algorithm

For the 7-day window ending Sunday:
`daysCompleted` (days with 100 pts) · `completionRate` · `totalSteps` (Σ snapshot
steps) · `activeCalories`/`workoutMinutes` (Σ healthSyncs) · `weightChange` &
`bmiChange` (this vs. previous week's check-in). Persists to
`weeklyReports/{week-NN}` and updates `participant.completionRate` (feeds the
"Most Consistent" board).

## Notification schedule (Asia/Kolkata)

| Time | Notification |
|---|---|
| 06:30 | Morning Yoga |
| 08:00 | Morning Shake |
| 12:00 | Daily motivation |
| 17:00 | Workout |
| 19:00 | Step goal |
| 21:30 | Night Shake |
| Sun 09:00 | Weekly check-in |
| Mon 07:00 | Weekly report generated |
| every 30 min | Due appointment reminders |

Reminders skip anyone who already completed that task today.

## Security model

- **Roles** in Auth custom claims (`request.auth.token.role`), set only by
  `setUserRole` (admin). Rules read the claim directly — no extra DB lookup.
- **Server-authoritative fields** (`pointsAwarded`, `streak`, `totalPoints`,
  leaderboards, reports, snapshots) are denied to clients in the rules; functions
  write them via the Admin SDK.
- **Medical isolation**: `medical/`, `consultations/`, and Storage `progress/` +
  `medical/` paths are `self + doctor + admin` only. Coaches are explicitly
  excluded; distributors have no role and no access.
- **Health data** is read-only from the device, audit-logged, never sold/shared.

## Deployment

```bash
# 1. Create the project & enable Auth (Phone), Firestore, Storage, Functions, FCM
firebase login
firebase use --add            # select your project

# 2. Install & build functions
cd functions && npm install && npm run build && cd ..

# 3. Deploy rules, indexes, and functions
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions

# 4. Seed roles (first admin) — run once from a trusted shell:
#    firebase functions:shell → setUserRole({uid:'<uid>', role:'admin'})
#    or set the claim directly with the Admin SDK.

# 5. Local development
cd functions && npm run serve     # emulators: auth, firestore, functions, storage, pubsub
```

## Connecting the Flutter app

1. `flutterfire configure` → generates `lib/firebase_options.dart`.
2. Enable the `firebase_*` deps in `pubspec.yaml`, uncomment the
   `Firebase.initializeApp(...)` block in `main.dart`.
3. Replace the mock notifiers in `lib/state/providers.dart` with Firestore-backed
   repositories that read/write the collections above. The service interfaces in
   `lib/services/` and models in `lib/data/models/` already match this schema
   (`toJson`/`fromJson` are in place).
4. After phone sign-in, call `claimParticipantRole`, then write the
   `participants/{uid}` profile.
5. Register the device FCM token into `participants/{uid}.fcmTokens`.
