# iOS Release — TestFlight & App Store Preparation

## Overview

The iOS release path:

```text
flutter build ios --release
→ Xcode Archive (Product → Archive)
→ Xcode Organizer → Distribute App
→ App Store Connect → TestFlight
→ App Store Review → Production
```

---

## Step 1 — Verify iOS Prerequisites

```bash
# Check code signing and provisioning
open ios/Runner.xcworkspace
# Xcode → Runner target → Signing & Capabilities
# Confirm: Team, Bundle Identifier, "Automatically manage signing" checked

# Verify Info.plist has correct values
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" ios/Runner/Info.plist
# These should match the marketing version and build number in pubspec.yaml.
# Flutter injects them automatically during build — do not manually set them in Info.plist.
```

---

## Step 2 — Build for Release

Always build with the production env file:

```bash
flutter build ios --release --dart-define-from-file=.env
```

Common flags:

```bash
# Build for a specific device only (faster, not suitable for Archive)
flutter build ios --release --dart-define-from-file=.env

# If you see "Xcode's output" errors, add verbose:
flutter build ios --release --dart-define-from-file=.env --verbose
```

**Important:** `flutter build ios` produces the compiled `.app` bundle but does NOT create the Xcode Archive. The Archive step happens inside Xcode.

---

## Step 3 — Create the Xcode Archive

```bash
# Open the workspace (must be .xcworkspace, not .xcodeproj)
open ios/Runner.xcworkspace
```

In Xcode:

1. Set the scheme target to **"Any iOS Device (arm64)"** — not a simulator.
2. **Product → Archive** (⌘ + Shift + B opens the build settings; Archive is under Product menu).
3. Wait for the archive to complete — Xcode Organizer opens automatically.

```bash
# Alternatively, archive from the command line:
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

---

## Step 4 — Upload to App Store Connect

In Xcode Organizer:

1. Select the newly created archive.
2. Click **"Distribute App"**.
3. Choose **"App Store Connect"** → **"Upload"**.
4. Leave all checkboxes at their defaults (symbol upload, bitcode if prompted).
5. Follow the wizard — Xcode manages signing automatically if "Automatically manage signing" is enabled.

**Alternatively — Transporter app:**

```bash
# Export the .ipa from Organizer first:
# Organizer → archive → Distribute App → App Store Connect → Export

# Then upload with Transporter (App Store app)
open -a Transporter
# Drag the exported .ipa into Transporter and click Deliver
```

---

## Step 5 — TestFlight

After the build uploads:

1. Open [App Store Connect](https://appstoreconnect.apple.com) → your app → **TestFlight**.
2. Wait for the build to process (typically 5–15 minutes; you'll get an email).
3. If prompted, answer the Export Compliance question (usually "No encryption" for most apps).
4. Add the build to an **Internal Testing** group for fast distribution (no review required).
5. For external testers: add to an **External Testing** group → submit for **Beta App Review** (typically 1 business day).

---

## Step 6 — App Store Submission

In App Store Connect:

1. **My Apps → your app → iOS App → + Version** (if it's a new marketing version).
2. Fill in: **What's New** text, screenshots (if changed), age rating, privacy details.
3. Select the TestFlight build for this version.
4. Click **"Submit for Review"**.

---

## Common iOS Release Issues

### "No accounts with iTunes Connect access"

Sign in to Xcode with your Apple ID: **Xcode → Settings → Accounts → +**.

### "Missing Compliance" / Export Compliance Loop

Answer "No" when asked if the app uses encryption beyond standard OS networking. Most Firebase + standard HTTPS apps qualify for the exemption. Add to Info.plist to skip the prompt automatically:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Build Rejected — Missing Privacy Manifest

As of iOS 17 / Spring 2024, Apple requires a `PrivacyInfo.xcprivacy` file for apps using certain APIs. Flutter and Firebase generate these automatically for known APIs — ensure `flutter build ios` succeeds without privacy warnings.

### Version / Build Number Mismatch

If Xcode shows a different version than `pubspec.yaml`, run:

```bash
flutter clean
flutter pub get
flutter build ios --release --dart-define-from-file=.env
```

Flutter injects the version from `pubspec.yaml` at build time. Do not hardcode the version in `ios/Runner/Info.plist`.

---

## TestFlight Release Notes Template

```text
What's new in this build:
- [Feature or fix description]
- [Second item if applicable]

Testing focus:
- [What to test specifically in this build]

Build: 1.4.0 (47)
Firebase: Production
```

---

## Pre-Archive Checklist (iOS)

```text
- [ ] Xcode scheme set to "Any iOS Device (arm64)" — not a simulator
- [ ] Build number incremented in pubspec.yaml
- [ ] flutter build ios --release --dart-define-from-file=.env succeeds with no warnings
- [ ] REVERSED_CLIENT_ID URL scheme present in Info.plist
- [ ] GoogleService-Info.plist is the PRODUCTION file
- [ ] ITSAppUsesNonExemptEncryption set to false in Info.plist
- [ ] Code signing: valid Distribution certificate + correct provisioning profile
- [ ] App version in Organizer matches pubspec.yaml version
```
