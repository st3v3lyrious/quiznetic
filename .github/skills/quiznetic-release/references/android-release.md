# Android Release — Play Store Preparation

## Overview

The Android release path:

```text
flutter build appbundle --release
→ Play Console → Create new release
→ Internal testing → Production
```

Use **AAB (Android App Bundle)** for Play Store submissions — not APK. AAB lets Google optimize the download size per device.

---

## Step 1 — Keystore Setup (One-Time)

Every release build must be signed with a keystore. **Do this once and never lose the keystore file.**

```bash
# Generate a new keystore (run once, keep the output file safe)
keytool -genkey -v \
  -keystore ~/keys/quiznetic-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias quiznetic
```

Store the resulting `.jks` file in a secure location **outside the repository** (e.g., `~/keys/` or a password manager). Never commit it to Git.

### Configure Signing in `android/app/build.gradle.kts`

```kotlin
// android/app/build.gradle.kts
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "../keys/quiznetic-release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: "quiznetic"
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

Set the values via environment variables or a `key.properties` file (not committed):

```bash
# Option: set env vars in your shell session
export KEYSTORE_PATH=~/keys/quiznetic-release.jks
export KEYSTORE_PASSWORD=yourpassword
export KEY_ALIAS=quiznetic
export KEY_PASSWORD=yourkeypassword
```

---

## Step 2 — Build the AAB

Always build with the production env file:

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

Output: `build/app/outputs/bundle/release/app-release.aab`

```bash
# Confirm the AAB was built successfully and check size
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### Build an APK (for direct device testing only)

```bash
flutter build apk --release --dart-define-from-file=.env
# Output: build/app/outputs/flutter-apk/app-release.apk

# Install directly on a connected device for smoke-testing the release build
flutter install --release
```

---

## Step 3 — Verify the Build

Before uploading, verify the signed AAB:

```bash
# Check the APK/AAB is signed
cd build/app/outputs/bundle/release
jarsigner -verify -verbose -certs app-release.aab | head -20

# Check version code and version name
cd ../../../../
grep 'versionName\|versionCode' android/app/build.gradle.kts
# Flutter injects these automatically from pubspec.yaml — do not hardcode them.
```

---

## Step 4 — Upload to Play Console

1. Open [Play Console](https://play.google.com/console) → select Quiznetic.
2. **Release → Testing → Internal testing** → **Create new release**.
3. Upload `app-release.aab`.
4. Write release notes (required for production, optional for internal).
5. **Save → Review release → Start rollout to Internal testing**.

### Release Tracks (Recommended Progression)

| Track | Who sees it | Review required | Rollout |
| ------- | ------------- | ----------------- | --------- |
| Internal testing | Up to 100 tester accounts | No | Instant |
| Closed testing (Alpha) | Invited groups | No | Instant |
| Open testing (Beta) | Anyone who opts in | No | Instant |
| Production | All users | **Yes** | Staged or 100% |

For a solo developer: go **Internal → Production** with a brief staged rollout (20% → 100% over a day).

### Staged Rollout

Start at 20% and watch crash rates in Play Console → Android vitals. Increase to 100% after 24 hours with no spike.

```text
Play Console → Production → Manage release → Increase rollout
```

---

## Step 5 — App Signing by Google (Play App Signing)

If you enrolled in **Play App Signing** (recommended), Google re-signs the AAB with the deployment key. You upload with your upload key; users receive the build signed with Google's key.

**Never disable Play App Signing once enrolled** — it cannot be reversed.

```bash
# Verify which signing key the store will use:
# Play Console → Setup → App signing → view App signing key certificate
```

---

## Common Android Release Issues

### "Upload failed — version code already exists"

Build number (`versionCode`) must be higher than any previously uploaded build.

```bash
# Check current versionCode in pubspec.yaml build number
grep '^version:' pubspec.yaml
# Flutter maps the build number (after +) to versionCode automatically.
```

### "AAB is not signed" or "INSTALL_PARSE_FAILED_NO_CERTIFICATES"

The release signing config was not applied. Confirm:

```bash
# Check signingConfig is set for the release buildType
grep -A5 'release' android/app/build.gradle.kts | grep signingConfig
```

### "Resources missing" after minification

`isMinifyEnabled = true` (R8/ProGuard) can strip classes needed at runtime. Add ProGuard rules if needed:

```text
# android/app/proguard-rules.pro
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
```

### Google Sign-In Fails in Release Build

Release builds use a different SHA-1 fingerprint than debug builds. Add the **release SHA-1** to Firebase Console → Project settings → Android app.

```bash
# Get the release SHA-1 from your keystore
keytool -list -v \
  -keystore ~/keys/quiznetic-release.jks \
  -alias quiznetic 2>/dev/null | grep SHA1
```

---

## Play Store Release Notes Template

```text
What's new:
• [Feature or fix description]
• [Second item if applicable]
```

Keep it user-facing and brief — what changed, not how it was fixed.

---

## Pre-Upload Checklist (Android)

```text
- [ ] Build number incremented in pubspec.yaml (maps to versionCode)
- [ ] Keystore available and signing config set in build.gradle.kts
- [ ] flutter build appbundle --release --dart-define-from-file=.env succeeds
- [ ] google-services.json is the PRODUCTION file
- [ ] Release SHA-1 registered in Firebase Console for Google Sign-In
- [ ] AAB file exists at build/app/outputs/bundle/release/app-release.aab
- [ ] AAB verified with jarsigner
- [ ] Release notes written in Play Console
- [ ] Internal testing rollout confirms app launches on a test device
```
