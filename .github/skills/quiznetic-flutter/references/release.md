# Release & Versioning

## Version Numbering

In `pubspec.yaml`:

```yaml
version: 1.2.3+45
```

- `1.2.3` → marketing version (shown in App Store / Play Store)
- `45` → build number (must increment on every store upload; never reuse)

Convention:

| Change | Bump |
| -------- | ------ |
| Bug fix only | Patch: `1.2.x` |
| New feature, backward compatible | Minor: `1.x.0` |
| Breaking change or major redesign | Major: `x.0.0` |

---

## Pre-Release Checklist

- [ ] Version string and build number bumped in `pubspec.yaml`
- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — zero issues
- [ ] Release notes / changelog updated
- [ ] `.env` points to the **production** Firebase project
- [ ] AdMob IDs are production values (not test IDs)
- [ ] `./tools/sync_env.sh` run after any `.env` change
- [ ] `flutter build apk --release` (Android) completes without errors
- [ ] `flutter build ios --release` (iOS) completes without errors
- [ ] Tested on a physical device in release mode (not simulator)

---

## Environment Management

This repo uses `--dart-define-from-file=.env` for all environment-specific values.

| File | Environment | Notes |
| ------ | ------------- | ------- |
| `.env` | Production | Never commit to git |
| `.env.dev` | Development | Test AdMob IDs, dev Firebase project |

After editing `.env`:

```bash
./tools/sync_env.sh   # regenerates android/app/google-services.json and ios/Runner/GoogleService-Info.plist
```

---

## Android Release Build

```bash
# APK (direct install / Firebase App Distribution)
flutter build apk --release --dart-define-from-file=.env

# AAB (Google Play Store — preferred)
flutter build appbundle --release --dart-define-from-file=.env
```

Signing is configured in `android/app/build.gradle.kts` under `signingConfigs`. Keystore credentials come from `android/local.properties` (not committed to git).

---

## iOS Release Build

```bash
flutter build ios --release --dart-define-from-file=.env
```

Then in Xcode:

1. Select **Any iOS Device (arm64)** as the target
2. **Product → Archive**
3. **Distribute App → App Store Connect** (or Ad Hoc for internal testing)

---

## Firebase App Distribution (Beta Builds)

```bash
# Build
flutter build apk --release --dart-define-from-file=.env

# Upload to Firebase App Distribution
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers \
  --release-notes "Build $(grep '^version:' pubspec.yaml | awk '{print $2}')"
```

---

## Git Tagging

Tag every release on the branch it ships from:

```bash
git tag -a v1.2.3 -m "Release 1.2.3 — brief description"
git push origin v1.2.3
```

---

## FlutterFire Package Compatibility

Before upgrading any `firebase_*` package, check the [FlutterFire compatibility matrix](https://github.com/firebase/flutterfire/blob/master/CHANGELOG.md).

All Firebase packages should use the same major version of `firebase_core`. Mismatched versions cause runtime crashes on startup.

```bash
# Check for outdated packages
flutter pub outdated

# Upgrade all to latest compatible versions
flutter pub upgrade
```

---

## What NOT to Do

- Do not reuse a build number — stores reject duplicate build numbers.
- Do not commit `.env` or keystore files to git.
- Do not use development or test AdMob IDs in a release build (stores reject or suppress ads).
- Do not ship from `flutter run` — always build with `flutter build`.
- Do not manually edit `android/app/google-services.json` or `ios/Runner/GoogleService-Info.plist` — use `./tools/sync_env.sh`.
