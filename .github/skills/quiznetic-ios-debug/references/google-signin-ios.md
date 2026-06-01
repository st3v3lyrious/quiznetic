# Google Sign-In iOS — Setup & Error Diagnosis

## How Google Sign-In Works on iOS

The `google_sign_in` Flutter plugin uses the native `GoogleSignIn` iOS SDK, which:

1. Reads the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` to register a URL scheme.
2. Opens Safari/`ASWebAuthenticationSession` for the OAuth flow.
3. Returns control to the app via the registered URL scheme.

If any part of this chain is misconfigured, the sign-in either silently cancels or throws a cryptic error.

---

## Required Setup Checklist

### 1. `CFBundleURLTypes` — Reversed Client ID URL Scheme

Google Sign-In returns the OAuth result to the app via a custom URL scheme. Without this, the sign-in flow opens a browser but the app never receives the result.

```xml
<!-- ios/Runner/Info.plist -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- This value comes from REVERSED_CLIENT_ID in GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID_HERE</string>
    </array>
  </dict>
</array>
```

```bash
# Get the correct REVERSED_CLIENT_ID value:
/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist
```

The value looks like: `com.googleusercontent.apps.123456789-abcdefghij`. Copy it exactly — any typo causes a silent sign-in failure.

**Verify it's in Info.plist:**

```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" ios/Runner/Info.plist
```

### 2. Bundle ID Match

The bundle ID in Xcode must match the OAuth client registered in Google Cloud Console and the `BUNDLE_ID` in `GoogleService-Info.plist`.

```bash
# Check plist bundle ID
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist

# Check Xcode project bundle ID
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -3
```

Both must be identical (e.g. `com.yourcompany.quiznetic`).

### 3. `GIDClientID` in Info.plist (google_sign_in >= 6.0)

Newer versions of `google_sign_in` require the OAuth client ID to be declared explicitly in `Info.plist`:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

```bash
# Get the CLIENT_ID value (without the 'com.googleusercontent.apps.' prefix reversal)
/usr/libexec/PlistBuddy -c "Print :CLIENT_ID" ios/Runner/GoogleService-Info.plist
```

---

## Common Errors & Root Causes

### "The operation couldn't be completed. (com.google.GIDSignIn error 10.)"

**Root cause:** The URL scheme (`REVERSED_CLIENT_ID`) is not registered or doesn't match.

```bash
# Verify
/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" ios/Runner/Info.plist
# These two values must match exactly.
```

### Sign-In Sheet Appears, Then Immediately Dismisses

**Root cause:** Usually a bundle ID mismatch between the OAuth client (Google Cloud Console) and the app.

1. Open Google Cloud Console → APIs & Services → Credentials → find the iOS OAuth client.
2. Confirm the `Bundle ID` field matches `PRODUCT_BUNDLE_IDENTIFIER` in Xcode exactly.
3. If not: either fix the bundle ID in Xcode, or create a new iOS OAuth client with the correct bundle ID.

### "PlatformException(sign_in_failed, ...)"  

**Root cause:** OAuth consent screen not configured, or the app is in "Testing" mode with restricted test users.

- Google Cloud Console → OAuth consent screen → verify status is "In production" or add your test account to the test users list.

### Sign-In Works on Simulator but Fails on Device

**Root cause:** Signing configuration mismatch. The reverse URL scheme must be registered under the correct provisioning profile.

- Ensure the app's bundle ID in the provisioning profile matches Xcode's `PRODUCT_BUNDLE_IDENTIFIER`.
- Run on device with `flutter run -d <device-id> --verbose` and look for URL scheme registration errors in the log.

### `google_sign_in` Hangs After Upgrade  

**Root cause:** `GIDSignIn.sharedInstance.configuration` must be set before calling `signIn()` in `google_sign_in >= 6.0`. The plugin handles this automatically via `Info.plist` if `GIDClientID` is set correctly (see checklist above).

---

## Verifying Sign-In Setup End-to-End

```bash
# 1. Confirm REVERSED_CLIENT_ID is in Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes" ios/Runner/Info.plist

# 2. Confirm GIDClientID is in Info.plist
/usr/libexec/PlistBuddy -c "Print :GIDClientID" ios/Runner/Info.plist

# 3. Confirm bundle ID alignment
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1

# 4. Run on physical device with verbose logging
flutter run -d <device-id> --verbose 2>&1 | grep -i "google\|sign.in\|GID\|scheme"
```

---

## Apple Sign-In — Entitlement & Capability

Apple Sign-In requires a capability that must be enabled in both Xcode and the Apple Developer portal.

**In Xcode:** Runner target → **Signing & Capabilities** → **+** → **Sign In with Apple**.

This writes to `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.appleseed.sign-in-with-apple</key>
<string>Default</string>
```

**Verify:**

```bash
cat ios/Runner/Runner.entitlements | grep -A1 "apple"
```

If the entitlement is missing, Apple Sign-In will throw `ASAuthorizationError` code 1000 or silently fail.

**Apple Developer Portal:** The App ID for your bundle ID must have "Sign In with Apple" enabled under **Capabilities**. After enabling, regenerate and re-download your provisioning profiles.

---

## `sign_in_with_apple` Package — Nonce Requirement

Apple requires a SHA256-hashed nonce in the auth request for security. The `sign_in_with_apple` package handles this automatically, but if you're calling the native API directly, omitting the nonce causes rejection:

```dart
// Always use the sign_in_with_apple package pattern — do not call native APIs directly
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final credential = await SignInWithApple.getAppleIDCredential(
  scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
  // nonce is generated and hashed internally by the package
);
```
