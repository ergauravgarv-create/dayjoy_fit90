# CI/CD

GitHub Actions workflows live in `.github/workflows/` (repo root = the
`dayjoy_fit90` Flutter project).

## `ci.yml` — on every push / PR to `main` or `develop`
- **Flutter**: `pub get` → `gen-l10n` → `flutter analyze` → `flutter test --coverage`
  (coverage uploaded as an artifact).
- **Cloud Functions**: `npm install` → `npm run build` (TypeScript typecheck).

> `flutter analyze` excludes the ready-to-enable `lib/data/repositories/firebase/**`
> and `firebase_fcm_service.dart` (they import firebase_* packages that stay
> commented in pubspec until go-live — see `analysis_options.yaml`). Remove those
> excludes when you enable Firebase so they're linted too.

## `release.yml` — on pushing a version tag (`v1.2.3`)
- **android**: builds a release **App Bundle** and uploads it as an artifact.
  - If the native `android/` folder is committed (with your release
    `signingConfig` wired to `key.properties` in `build.gradle`), CI uses it.
  - Otherwise it runs `flutter create --platforms=android .` and builds with
    debug signing (fine for testing, **not** for store upload).
- **functions**: builds and deploys Cloud Functions **only if** the
  `FIREBASE_TOKEN` secret and `FIREBASE_PROJECT_ID` variable are set.

### Required GitHub secrets / variables (for signed release + deploy)
| Name | Type | Purpose |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | secret | `base64 -w0 upload-keystore.jks` |
| `ANDROID_STORE_PASSWORD` | secret | keystore password |
| `ANDROID_KEY_ALIAS` | secret | key alias (e.g. `upload`) |
| `ANDROID_KEY_PASSWORD` | secret | key password |
| `FIREBASE_TOKEN` | secret | `firebase login:ci` token |
| `FIREBASE_PROJECT_ID` | variable | e.g. `dayjoy-fit90-prod` |

All secrets are optional — without them the release job still builds an
(unsigned) artifact and skips the deploy.

## `dependabot.yml`
Weekly dependency PRs for pub (`/`), npm (`/functions`), and github-actions.

## Recommended branch protection
Require the **CI / Flutter · analyze & test** and **CI / Cloud Functions · build**
checks to pass before merging to `main`.

## Local pre-commit equivalent
```bash
flutter pub get && flutter gen-l10n && flutter analyze && flutter test
( cd functions && npm install && npm run build )
```
