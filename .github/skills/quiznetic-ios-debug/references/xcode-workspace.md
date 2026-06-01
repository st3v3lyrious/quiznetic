# Xcode Workspace, Build Cache & SDK Compatibility

## Always Open the Workspace, Not the Project

Flutter iOS builds require `Runner.xcworkspace` (includes CocoaPods integration). Opening `Runner.xcodeproj` directly will fail to compile Firebase and other Pod-based dependencies.

```bash
# Correct
open ios/Runner.xcworkspace

# Wrong — missing Pods, will fail with "Module not found"
open ios/Runner.xcodeproj
```

---

## Build Cache Layers

There are three independent caches that can hold stale artifacts. Clear them in order:

### Layer 1 — Flutter Build Cache

```bash
flutter clean
# Removes: build/, .dart_tool/, generated plugin registrant files
```

### Layer 2 — CocoaPods Cache

```bash
cd ios
pod deintegrate          # unlinks Pods from Xcode project
pod cache clean --all    # wipes downloaded Pod source cache
pod install --repo-update
cd ..
```

### Layer 3 — Xcode Derived Data

```bash
# Delete DerivedData for this project only
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Or delete all DerivedData (safe — Xcode rebuilds on next build)
rm -rf ~/Library/Developer/Xcode/DerivedData
```

In Xcode: **Product → Clean Build Folder** (⇧⌘K) clears only the current scheme's build products — equivalent to deleting the project's DerivedData subfolder.

### Full Nuclear Clean (all three layers)

```bash
flutter clean
cd ios
pod deintegrate
pod cache clean --all
rm -f Podfile.lock
pod install --repo-update
cd ..
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
flutter pub get
```

Use this when simpler fixes haven't worked and the error is clearly stale-artifact related.

---

## DT_TOOLCHAIN_DIR Error (Xcode 15+)

**Error:**

```text
DT_TOOLCHAIN_DIR cannot be used to evaluate LIBRARY_SEARCH_PATHS,
use TOOLCHAIN_DIR instead
```

**Root cause:** Older versions of some Firebase/Google Pods reference the deprecated `DT_TOOLCHAIN_DIR` build variable. Xcode 15 removed this variable.

**Fix Step 1 — Update packages (preferred):**

```bash
flutter pub upgrade firebase_core firebase_auth google_sign_in cloud_firestore
flutter pub get
cd ios && pod install --repo-update && cd ..
```

**Fix Step 2 — Podfile `post_install` patch (if Step 1 is blocked):**

```ruby
# ios/Podfile — add/update the post_install block
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Fix DT_TOOLCHAIN_DIR for Xcode 15
      xcconfig_path = config.base_configuration_reference&.real_path
      next unless xcconfig_path&.exist?
      xcconfig = File.read(xcconfig_path)
      fixed = xcconfig.gsub('DT_TOOLCHAIN_DIR', 'TOOLCHAIN_DIR')
      File.write(xcconfig_path, fixed) if fixed != xcconfig

      # Ensure deployment target is set
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

After editing `Podfile`:

```bash
cd ios && pod install && cd ..
```

---

## Deployment Target Conflicts

**Error:**

```text
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 11.0,
but the range of supported deployment target versions is 12.0 to 17.5.99
```

**Root cause:** A Pod requires a higher minimum iOS version than what's set in the `Podfile` or Xcode project.

**Fix:**

In `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

In Xcode: **Runner target → General → Minimum Deployments → iOS 13.0**

In `Podfile` post_install (enforces on all Pod targets):

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

---

## Flutter SDK Compatibility Issues

**Symptom:** Build fails after upgrading Flutter SDK with errors in generated files or plugin interfaces.

```bash
# Check current Flutter and Dart versions
flutter --version

# Check what packages expect
flutter pub deps | head -30

# Upgrade Flutter channel (match team's channel)
flutter channel stable
flutter upgrade

# After upgrade, always regenerate everything
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
```

**Check the Flutter version constraint in `pubspec.yaml`:**

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.22.0'
```

If a package requires a newer Flutter SDK, either upgrade Flutter or constrain the package version.

---

## Architecture Issues — arm64 vs x86_64

**Symptom:** Build succeeds on simulator but fails on device, or vice versa.

```bash
# Check which architectures are being targeted
flutter build ios --release --verbose 2>&1 | grep -i "arch\|arm64\|x86"
```

Firebase iOS SDK (from FlutterFire >= 10.x) no longer supports x86_64 simulator. Ensure you are using an arm64 simulator (Apple Silicon Mac) or a physical device.

```bash
# List available simulators by architecture
xcrun simctl list devices | grep -i "iphone 1"

# Use arm64 simulator on Apple Silicon
flutter run -d "iPhone 16"
```

If running on an Intel Mac, you may need to run under Rosetta for some combinations — but a physical device is preferred for Firebase testing.

---

## Code Signing Conflicts

**Error:**

```text
Code signing is required for product type 'Application' in SDK 'iOS 17.x'
Signing for "Runner" requires a development team.
```

**Fix:**

1. In Xcode: **Runner target → Signing & Capabilities → Team** — select your Apple Developer account.
2. Enable **Automatically manage signing**.
3. Ensure your device is registered in the portal or use a personal team (free) for testing.

```bash
# Check signing from command line
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -showBuildSettings 2>&1 | grep -E "DEVELOPMENT_TEAM|CODE_SIGN"
```

---

## Useful Diagnostic Commands

```bash
# Full Flutter environment check
flutter doctor -v

# Show all iOS build settings for Runner
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -showBuildSettings 2>&1 | grep -E "DEPLOYMENT_TARGET|TOOLCHAIN|BUNDLE"

# List booted simulators
xcrun simctl list devices | grep Booted

# Boot a simulator by name
xcrun simctl boot "iPhone 16"

# Open Simulator app
open -a Simulator

# Verbose flutter run (shows full native Xcode output)
flutter run -d <device-id> --verbose 2>&1 | tee /tmp/flutter_run.log

# Show Xcode version
xcodebuild -version

# Show installed SDKs
xcodebuild -showsdks
```

---

## Warp Workflow Tips

- Split pane: run `flutter run --verbose` in one pane, `tail -f /tmp/flutter_run.log | grep error` in another.
- Use Warp's command palette to re-run the last clean sequence without retyping.
- Pin the nuclear clean command as a Warp workflow for one-click resets:

  ```bash
  flutter clean && cd ios && pod deintegrate && pod cache clean --all && pod install --repo-update && cd .. && flutter pub get
  ```
  
- After any iOS fix, always test on a **physical device** — simulators can mask signing and URL scheme issues.
