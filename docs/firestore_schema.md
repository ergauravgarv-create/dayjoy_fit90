# Dayjoy Fit90 — Firestore Schema

Document-oriented model. Sensitive data (medical, doctor notes, progress body
photos) is isolated into its own paths so security rules can restrict it to
`self + doctor + admin` — coaches and distributors never gain access.

Legend: 🔒 = server-authoritative (Cloud Functions only write it).

---

## `config/{doc}`  — public read, admin write
```
config/app {
  stepGoal: 10000, pointsPerTask: 20, tasksPerDay: 5,
  galleryUploadAllowed: bool, manualEntryAllowed: bool,
  reminderTimes: { yoga, morningShake, workout, steps, nightShake },
  policyVersion: "1.0"
}
```

## `quotes/{id}`  — signed-in read, admin write
```
{ text: string, author?: string }
```

## `users/{uid}`  — self + staff read
```
{ uid, role: 'participant'|'coach'|'doctor'|'admin',   // 🔒 role via custom claim
  displayName, phone, email, fcmTokens: string[], createdAt }
  └─ notifications/{id} { title, body, data, read, createdAt }   // staff inbox
```

## `participants/{uid}`  — self + staff read
```
{ id, name, mobile, email?, photoUrl?,
  age, gender, heightCm, waistCm?,
  startWeightKg, currentWeightKg, targetWeightKg, weightLostKg,
  city, distributorName, sponsorId, foodPreference,
  healthConditions?, physicalActivityLevel?,
  startDate, currentDay,
  streak 🔒, totalPoints 🔒, lastCompletedDate 🔒, completionRate 🔒,
  fcmTokens: string[], consent: { dataProcessing, health, camera },
  createdAt, updatedAt }
```

### Subcollections
```
participants/{uid}/medical/{id}          // 🔒 access: self + doctor + admin ONLY
  { condition, notes, uploadedBy, createdAt }

participants/{uid}/consultations/{id}    // access: self(read) + doctor + admin
  { doctorId, type, notes, dietPlan?, createdAt }

participants/{uid}/days/{yyyy-MM-dd}      // the daily checklist
  { participantId, challengeDay, activityDate,
    tasks: {
      morningYoga:      { completed, proofUrl?, captureSource?, completedAt },
      morningNutrition: { completed, proofUrl?, completedAt },
      fitnessActivity:  { completed, proofUrl?, type?, durationMin?, completedAt },
      dailySteps:       { completed, verifiedSteps?, method?, completedAt },
      nightNutrition:   { completed, proofUrl?, completedAt }
    },
    completionPercent, pointsAwarded 🔒, scoredAt 🔒 }

participants/{uid}/submissions/{id}       // flat proof log for dup detection
  { taskKey, imageHash, capturedAt, captureSource, storagePath,
    duplicate? 🔒, duplicateOf? 🔒, adminVerificationStatus 🔒 }

participants/{uid}/healthSyncs/{syncId}   // HealthSyncRecord (client-written)
  { participantId, platform, integrationType, syncDate, localDate, timezone,
    stepCount, distanceKm?, activeCalories?, workoutMinutes?, weightKg?,
    sourceType, permissionStatus, lastSyncAt, syncStatus, syncError? }

participants/{uid}/snapshots/{yyyy-MM-dd} // 🔒 DailyChallengeSnapshot (scoring)
  { participantId, challengeDay, activityDate,
    verifiedStepCount, stepGoal, stepGoalCompleted,
    verificationMethod, healthSyncReference?, screenshotReference?,
    adminVerificationStatus, completionTime, pointsAwarded, auditTrail[] }

participants/{uid}/weeklyCheckins/{week-NN}   // self-authored
  { weightKg, waistCm, frontPhoto, sidePhoto,
    energyLevel, sleepQuality, digestion, mood, notes, createdAt }

participants/{uid}/weeklyReports/{week-NN}    // 🔒 generated
  { weekNumber, startDate, endDate, daysCompleted, completionRate,
    totalSteps, activeCalories, workoutMinutes,
    startWeightKg, endWeightKg, weightChangeKg, bmi, bmiChange,
    pointsEarned, generatedAt }

participants/{uid}/badges/{badgeId}           // 🔒 awarded
  { id, label, awardedAt }

participants/{uid}/notifications/{id}         // 🔒 written, self read/mark-read
  { title, body, data, read, createdAt }
```

## `appointments/{id}`  — participant + provider + admin
```
{ participantId, providerId, providerName, providerRole: 'coach'|'doctor',
  type, requestedAt, scheduledAt, status: 'requested'|'confirmed'|'rescheduled'
  |'completed'|'cancelled', notes?, reminderSent? }
```

## `leaderboards/{period}`  — signed-in read, 🔒 write
```
period ∈ { overall, highestStreak, maxWeightLost, mostConsistent,
           daily, weekly, monthly, cities, distributors }
{ entries: [ { rank, participantId, name, city, photoUrl, points, streak,
               weightLostKg } ], day, updatedAt }
```

## `auditLogs/{id}`  — admin read, 🔒 write
```
{ type, participantId, actorId?, imageHash?, submissionPath?, at }
```

---

## Index requirements
See `firestore.indexes.json`. Key composite/collection-group indexes:
- `days` (group) — `adminVerificationStatus` + `activityDate` (verification queue)
- `snapshots` (group) — `activityDate` + `participantId` (period leaderboards)
- `submissions` (group) — `imageHash` + `capturedAt` (duplicate detection)
- `appointments` — `providerId`+`scheduledAt`, `participantId`+`scheduledAt`, `status`+`scheduledAt`
- `participants` — `city`+`totalPoints`, `distributorName`+`totalPoints`
