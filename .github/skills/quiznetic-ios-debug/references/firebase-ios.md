# Firebase iOS Integration & GTMSessionFetcher Conflicts

## How Firebase iOS Works in a Flutter Project

FlutterFire plugins wrap the native Firebase iOS SDK via CocoaPods. The dependency chain is:

```text
flutter plugin (Dart)
  └── Flutter plugin Pod (.podspec)
        └── Firebase iOS SDK Pod (e.g. FirebaseAuth, FirebaseFirestore)
              └── Shared transitive Pods (GTMSessionFetcher, GoogleUtilities, etc.)
```

When multiple FlutterFire plugins or `google_sign_in` depend on **different versions** of a shared transitive Pod, CocoaPods fails to resolve.

---

## GTMSessionFetcher Conflicts — Root Cause & Fix

`GTMSessionFetcher` is a shared dependency of:

- `firebase_auth` → `FirebaseAuth` → `GTMSessionFetcher`
- `google_sign_in` → `GoogleSignIn` → `GTMSessionFetcher`
- `firebase_storage`, `firebase_functions`, and others

Each plugin version declares a different minimum `GTMSessionFetcher` version. When they are misaligned, you see:

```text
[!] CocoaPods could not find compatible versions for pod "GTMSessionFetcher":
  In snapshot (Podfile.lock):
    GTMSessionFetcher (= 3.3.0)
  In Podfile:
    google_sign_in_ios (from `...`) was resolved to 7.1.0, which depends on
      GoogleSignIn (~> 7.0) which depends on
        GTMSessionFetcher/Core (>= 3.4)
```

### Diagnosis

```bash
cd ios
# Show the full resolution tree for GTMSessionFetcher
pod install --repo-update --verbose 2>&1 | grep -i gtmsession
```

### Fix Step 1 — Align via pubspec.yaml (Preferred)

Check the [FlutterFire compatibility matrix](https://github.com/firebase/flutterfire#compatibility) and align `google_sign_in` with the `firebase_auth` version:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1  # verify this version agrees on GTMSessionFetcher
```

```bash
flutter pub get
cd ios && rm Podfile.lock && pod install --repo-update && cd ..
```

### Fix Step 2 — Podfile Pin (Temporary Fallback)

If alignment via pubspec.yaml is blocked by an upstream release:

```ruby
# ios/Podfile — inside target 'Runner' do block
# TEMPORARY: GTMSessionFetcher conflict between google_sign_in 7.x and firebase_auth 5.x
# Remove when google_sign_in >= 6.3 is adopted.
pod 'GTMSessionFetcher/Core', '~> 3.4'
pod 'GTMSessionFetcher/Full', '~> 3.4'
```

### What NOT to Do

- Do not edit `GTMSessionFetcher.podspec` in `.pub-cache/` — it is overwritten by `flutter pub get`.
- Do not delete `.pub-cache/hosted/pub.dev/google_sign_in_ios-*/` and recreate it — same problem.
- Do not pin to an exact version (`= 3.4.0`) — use pessimistic constraint (`~> 3.4`) to allow patches.

---

## GoogleService-Info.plist Setup

Firebase on iOS requires `GoogleService-Info.plist` to be embedded in the app bundle.

### Verification Checklist

1. File exists at `ios/Runner/GoogleService-Info.plist`.
2. File is added to the **Runner target** in Xcode (check: Runner → Build Phases → Copy Bundle Resources).
3. `BUNDLE_ID` in the plist matches the app bundle identifier in Xcode (`com.yourcompany.quiznetic`).
4. `GOOGLE_APP_ID`, `GCM_SENDER_ID`, `API_KEY` match the Firebase console for the correct project/environment.

```bash
# Confirm the file is present
ls -la ios/Runner/GoogleService-Info.plist

# Check bundle ID in plist
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist

# Check bundle ID in Xcode project
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -3
```

After updating `.env`:

```bash
./tools/sync_env.sh   # regenerates GoogleService-Info.plist from env values
flutter clean         # clears any cached copy from build/
```

---

## Module Not Found — `Module 'Firebase' not found`

**Root cause:** Pods are compiled as static libraries but the Xcode project expects dynamic frameworks, or vice versa. Also happens when `use_frameworks!` is missing.

```bash
# Step 1: Ensure Podfile has both lines inside target block
grep -A5 "target 'Runner'" ios/Podfile
# Should see: use_frameworks! and use_modular_headers!

# Step 2: Full clean + reinstall
flutter clean
cd ios && pod deintegrate && pod install --repo-update && cd ..
```

If the error persists after clean:

- Open `ios/Runner.xcworkspace` in Xcode (NOT `.xcodeproj`).
- **Product → Clean Build Folder** (⇧⌘K).
- Build again from Xcode to see the full compiler error.

---

## Firebase Crashes on Cold Launch

**Symptoms:** App starts, then immediately crashes with `NSException` or `EXC_BAD_ACCESS` related to Firebase.

**Checklist:**

1. `Firebase.initializeApp()` is called in `main()` **before** `runApp()`.
2. `AppFirebaseOptions.currentPlatform` is derived from `lib/firebase_env_options.dart` — not a stale `DefaultFirebaseOptions`.
3. `GOOGLE_APP_ID` in `GoogleService-Info.plist` matches the initialized `FirebaseApp`.

```bash
# Verify the plist GOOGLE_APP_ID
/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist
```

Compare against `lib/firebase_env_options.dart` → `appId` for iOS. They must match exactly.

---

## FlutterFire Compatibility Matrix — Version Alignment Rules

All `firebase_*` packages must use the same **major version** of `firebase_core`. Mixing major versions causes runtime crashes.

```bash
# Check current versions
flutter pub deps | grep firebase

# Check for outdated packages
flutter pub outdated
```

Upgrade all Firebase packages together:

```bash
# In pubspec.yaml, update all firebase_* packages to latest compatible
flutter pub upgrade firebase_core firebase_auth cloud_firestore firebase_analytics firebase_crashlytics
flutter pub get
cd ios && pod install --repo-update && cd ..
```

**Never upgrade one Firebase package in isolation** without checking the others.

---

## `FirebaseAppDelegateProxyEnabled` — Method Swizzling

Firebase swizzles `AppDelegate` methods by default to capture push notification tokens and analytics events. If this conflicts with your own `AppDelegate` code:

```xml
<!-- ios/Runner/Info.plist -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

If you disable swizzling, you must manually forward `AppDelegate` methods to Firebase — see the [Firebase iOS docs](https://firebase.google.com/docs/cloud-messaging/ios/client#method_swizzling_in_firebase_cloud_messaging).

For QuizNetic (no push notifications in MVP), leaving swizzling enabled (default) is correct.
