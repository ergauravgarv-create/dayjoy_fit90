# 👋 Start Here — Dayjoy Fit90 (for a non-technical owner)

This guide gets you a **real installable Android app (APK)** and a **shareable
web demo link** for senior management — **without installing anything** on your
computer. Everything runs in the cloud, for free, on GitHub.

The app is prepared in **Demo Mode**: it opens with realistic sample data, a
demo login (any phone number + any 6-digit code), and a small **"DEMO DATA"**
badge at the bottom so no one mistakes it for real patient data. It cannot
upload real health information in this mode.

---

## Option A — One-click cloud build (recommended, no tools needed)

**Step 1. Create a free GitHub account** at https://github.com (skip if you have one).

**Step 2. Create a new repository**
- Click the **+** (top-right) → **New repository**
- Name it `dayjoy-fit90` → keep it **Private** → click **Create repository**

**Step 3. Upload the project**
- On the new repo page, click **"uploading an existing file"**
- Drag the **entire `dayjoy_fit90` folder contents** into the page
  (or zip it, upload, and GitHub will keep the structure)
- Click **Commit changes**

**Step 4. Turn on Pages (for the web demo link)**
- Repo → **Settings** → **Pages** (left menu)
- Under "Build and deployment", set **Source = GitHub Actions** → Save

**Step 5. Run the build**
- Repo → **Actions** tab
- If asked, click **"I understand my workflows, enable them"**
- Click **"Build Demo (APK + Web)"** → **Run workflow** → **Run workflow**
- Wait ~10–15 minutes for the green tick ✅

**Step 6. Get your results**
- **Android APK**: open the finished run → scroll to **Artifacts** →
  download **`dayjoy-fit90-demo-apk`**. Send that `.apk` file to any Android
  phone, tap it, allow "install from this source", and it installs.
- **Web demo link**: open the finished run → the **web-demo** job shows a
  **URL** (also under Settings → Pages). Share that link with management.

> Tip: To rebuild after any change, just click **Run workflow** again.

---

## Option B — Hand it to a Flutter developer (fastest, ~1 hour)

Give the developer this project folder and say:

> "Run `flutter pub get` then `flutter run` to demo it. For an installable file
> run `flutter build apk --release`. The app is in Demo Mode (mock data) — see
> `lib/core/env/app_config.dart`."

Everything is already wired; there is no code left to write for the demo.

---

## What is NOT included / what you must arrange later (for the REAL app)

The demo needs none of these. You only need them to go live with real accounts,
real health sync, and the app stores:

1. A **Firebase** project (free to start) — for login, database, storage, push.
2. **Google Play Console** account ($25 one-time) — to publish on Android.
3. An **Apple Developer** account ($99/year) **and a Mac computer** — the iPhone
   app can only be finished and uploaded from a Mac (this is an Apple rule, not a
   limitation of this project).
4. Your **brand logo** image — to replace the placeholder app icon.

See `docs/deployment.md` and `.env.example` for the exact list. Any developer can
connect these in a day using the guides already in the `docs/` folder.

---

## Honest status

The person who prepared this project **could not run the build on their machine**
(no Flutter/Android tools were installed there), so **no APK was produced in
advance**. Instead, the project was made fully build-ready and a one-click cloud
build was set up so **you** can generate the APK and web link yourself with the
steps above. The first cloud run is also the real proof that it compiles.
