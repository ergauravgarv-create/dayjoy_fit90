# Apple App Store — Submission Checklist

App: **Dayjoy Fit90** · Bundle ID: `com.dayjoy.fit90` · Category: Health & Fitness

## Build & capabilities
- [ ] Release **IPA** archived and uploaded via Xcode Organizer / Transporter
- [ ] Signing team + provisioning profile set
- [ ] Capabilities: **HealthKit**, **Push Notifications**, **Background Modes → Remote notifications**
- [ ] `Runner.entitlements` includes `com.apple.developer.healthkit`
- [ ] Build number incremented per upload

## Info.plist usage strings (must be specific)
- [ ] `NSCameraUsageDescription` — "…capture daily challenge activities and weekly progress photographs."
- [ ] `NSPhotoLibraryUsageDescription` — only if gallery upload enabled
- [ ] `NSHealthShareUsageDescription` — steps/distance/active energy/workouts, read-only
- [ ] `NSHealthUpdateUsageDescription` — "…access is read-only." (no writes)
- [ ] No location strings unless the optional location feature is enabled

## App Store Connect listing
- [ ] App name, subtitle, promotional text, description, keywords
- [ ] App icon 1024×1024 (no alpha, no rounded corners)
- [ ] Screenshots for 6.7" and 5.5" iPhone (and iPad if supported)
- [ ] Support URL + Marketing URL
- [ ] Age rating questionnaire → expected 4+

## Privacy
- [ ] **Privacy Policy URL** live
- [ ] **App Privacy "nutrition label"** completed:
  - Data collected: Contact info (name/phone/email), **Health & Fitness**, Photos, User Content, Identifiers
  - **Health data not used for tracking/ads; not sold**
  - Data linked to the user; used for app functionality only
- [ ] **HealthKit privacy rules** honored: health data not used for advertising/marketing,
      not shared with third parties, not written back (read-only)
- [ ] Account deletion available in-app (App Review Guideline 5.1.1(v))

## App Review guideline hotspots
- [ ] **Sign in with Apple** — required *only if* you offer third-party social login;
      phone-OTP alone does not trigger it (documented for the reviewer)
- [ ] Demo: provide a **test phone number + OTP** (or a reviewer account for each role:
      participant / coach / doctor / admin) in App Review notes
- [ ] No medical-diagnosis claims; disclaimer that automatic health data may not be
      medically accurate
- [ ] Permission pre-prompts explain value before the system dialog
- [ ] Graceful handling when permissions are denied (screenshot/manual fallback)
- [ ] Push notifications are not required to use the app

## TestFlight
- [ ] Internal testers validate phone OTP, camera capture, HealthKit sync on device
- [ ] Export compliance answered (uses standard encryption → typically exempt)

## Submit
- [ ] Version, build, "What's New" text
- [ ] Manual or automatic release after approval
- [ ] Respond to Review messages promptly; keep the reviewer demo account active
