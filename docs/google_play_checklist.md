# Google Play — Submission Checklist

App: **Dayjoy Fit90** · Package: `com.dayjoy.fit90` · Category: Health & Fitness

## Build & signing
- [ ] Release **AAB** built (`flutter build appbundle --release`)
- [ ] Play App Signing enrolled; upload key backed up
- [ ] `targetSdkVersion` meets Play's current requirement (34+)
- [ ] `minSdkVersion 26` (Health Connect)
- [ ] Version code incremented for each upload

## Store listing
- [ ] App name, short description (≤80 chars), full description (≤4000)
- [ ] App icon 512×512 PNG
- [ ] Feature graphic 1024×500
- [ ] Phone screenshots (min 2; use Home, Today, Progress, Leaderboard, Coach/Doctor)
- [ ] Optional promo video
- [ ] Contact email + website

## Content & policy
- [ ] **Privacy Policy URL** (public, reachable) — required (app requests sensitive perms)
- [ ] Data safety form completed:
  - Collects: name, phone, email, photos, **health & fitness (steps/weight)**, approximate app activity
  - Health data: **not sold, not shared** for ads; used only for the challenge
  - Encryption in transit; account + data deletion available in-app
- [ ] **Health Connect** declaration form (data types read: steps, distance, active calories, exercise, weight) + privacy-policy link
- [ ] Permissions justified: `CAMERA` (activity/progress photos), `POST_NOTIFICATIONS` (reminders), Health Connect read perms
- [ ] No background location; location only via separate explicit opt-in
- [ ] Content rating questionnaire (IARC) completed → expected: Everyone
- [ ] Target audience & content: adults; not directed at children
- [ ] Ads declaration: **No ads**
- [ ] Financial features / UGC declarations as applicable (photos are UGC — moderation via admin verification)

## Health apps policy
- [ ] Meets Play's Health Connect + Health apps requirements (no medical diagnosis
      claims; "not medically accurate" disclaimer shown)
- [ ] Sensitive health data access matches declared use

## Account deletion (required)
- [ ] In-app **Delete account** (Profile) removes participant data
- [ ] Web deletion URL listed in the Data safety section

## Testing & rollout
- [ ] Internal testing track validated on real devices (phone OTP, camera, Health Connect)
- [ ] Pre-launch report reviewed (no crashes/policy flags)
- [ ] Countries/regions selected (India first)
- [ ] Staged rollout (e.g. 10% → 50% → 100%)

## Post-submission
- [ ] Respond to any policy review requests within the deadline
- [ ] Monitor Android vitals (ANRs/crashes) after launch
