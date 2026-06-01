# iOS CocoaPods & Build Troubleshooting

## Quick Fix Sequence

Run this first for any unexplained iOS build failure:

```bash
flutter clean
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
cd ..
flutter pub get
```

If the issue persists after the quick fix, consult the specific sections below.

---

## Common Issues & Fixes

### Pod Install Fails / Dependency Conflict

```bash
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
```

If that fails, delete `Podfile.lock` and retry:

```bash
rm Podfile.lock
pod install --repo-update
```

### Xcode Build Fails After Flutter or FlutterFire Upgrade

The cached Pod artifacts can conflict with new package versions.

```bash
flutter clean
cd ios && pod deintegrate && pod install && cd ..
flutter pub get
```

Then do a full Xcode clean: **Product → Clean Build Folder** (⇧⌘K).

### `GoogleService-Info.plist` Missing or Stale

- Ensure `ios/Runner/GoogleService-Info.plist` matches the Firebase project for the current environment.
- After updating the file, run `flutter clean` — Xcode caches the embedded copy in the build folder.
- Verify: `GOOGLE_APP_ID`, `BUNDLE_ID`, `GCM_SENDER_ID` match the Firebase console values.
- After any `.env` change, run `./tools/sync_env.sh` to regenerate native Firebase config files.

### CocoaPods Version Out of Date

```bash
sudo gem install cocoapods
pod --version   # should be >= 1.14
```

### `DT_TOOLCHAIN_DIR` Error (Xcode 15+)

A known FlutterFire incompatibility with older `firebase_core` versions.

1. Update `firebase_core` (and all `firebase_*` packages) to the latest compatible versions in `pubspec.yaml`.
2. Run `flutter pub get && cd ios && pod install`.
3. If it persists, add to `ios/Podfile` inside the `post_install` block:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

### `Sign in with Apple` Capability Missing

In Xcode → **Signing & Capabilities** → add **Sign In with Apple** for both Debug and Release.

Verify `ios/Runner/Runner.entitlements` contains:

```xml
<key>com.apple.developer.appleseed.sign-in-with-apple</key>
<string>Default</string>
```

### Google Sign-In: Reverse Client ID Not Configured

In `ios/Runner/Info.plist`, ensure `CFBundleURLTypes` contains the reversed client ID from `GoogleService-Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

The `YOUR_CLIENT_ID` value is the `REVERSED_CLIENT_ID` field in `GoogleService-Info.plist`.

### AdMob iOS Build Errors

- `GADApplicationIdentifier` must be set in `Info.plist` (injected via `ios/Flutter/Env.xcconfig`).
- Do not hardcode `ca-app-pub-*` values — use `--dart-define-from-file=.env`.
- Ensure `google_mobile_ads` version is compatible with the current `firebase_core` version (check the FlutterFire compatibility matrix).
- If ads cause linker errors, run the full clean sequence above.

### Simulator Not Found / Not Booting

```bash
# List available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 16"

# Open Simulator app
open -a Simulator
```

Or use the VS Code workspace task: **Boot & Launch iOS Simulator**.

---

## Diagnostic Commands

```bash
# Full environment check
flutter doctor -v

# Check installed Xcode SDKs
xcodebuild -showsdks

# Check CocoaPods version
pod --version

# List connected/available Flutter devices
flutter devices

# Verbose Flutter run (shows native build output)
flutter run -v
```

---

## Warp / VS Code Workflow Tips

- Use the VS Code task **Boot & Launch iOS Simulator** to avoid typing `open -a Simulator` each session.
- Run `flutter run -d iPhone` (or the device ID from `flutter devices`) — Flutter auto-selects a booted simulator.
- After any `pubspec.yaml` change: always run `flutter pub get` before `flutter run`.
- Hot reload (`r`) works for UI changes; hot restart (`R`) is needed for `initState` / Firebase re-init changes.
- Use `flutter logs` in a separate Warp pane to tail device logs while running.
