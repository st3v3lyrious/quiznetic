# CocoaPods — Conflicts, Clean Sequences & Podfile Alignment

## How CocoaPods Resolves Dependencies

CocoaPods performs a constraint satisfaction pass across all `.podspec` files in your project (Flutter plugins are published as Pods). When two Pods require the same dependency at incompatible versions, CocoaPods fails with:

```text
[!] CocoaPods could not find compatible versions for pod "SomePod":
  In Podfile:
    plugin_a (from `...`) was resolved to 1.0, which depends on
      SomePod (~> 2.0)
    plugin_b (from `...`) was resolved to 2.0, which depends on
      SomePod (~> 3.0)
```

**Root cause:** Two Flutter plugins declare incompatible version constraints on a shared iOS dependency.

**Fix:** Align the Flutter package versions in `pubspec.yaml` until their Pod constraints agree. Never resolve this by modifying `.pub-cache/` files.

---

## Standard Clean Sequence

Run this first for any unexplained iOS build failure. It clears every layer of cached state:

```bash
# From repo root
flutter clean

cd ios
pod deintegrate          # removes Pod integration from Xcode project
pod cache clean --all    # wipes CocoaPods download cache
pod install --repo-update  # fetches fresh specs from all sources
cd ..

flutter pub get          # ensures Dart packages + generated iOS files are fresh
```

**Why each step matters:**

- `flutter clean` — removes `build/`, `.dart_tool/`, Flutter-generated files
- `pod deintegrate` — removes `Pods/` dir and unlinks Pods from `.xcworkspace`; safer than `rm -rf Pods/`
- `pod cache clean --all` — forces re-download of all Pod source; catches corrupted caches
- `pod install --repo-update` — updates the local CocoaPods spec repository before resolving

---

## Podfile.lock Conflicts

`Podfile.lock` records the exact resolved versions. When `pubspec.yaml` changes add or upgrade a plugin with different Pod requirements, the lock file becomes stale.

```bash
# If pod install fails citing a locked version conflict:
cd ios
rm Podfile.lock
pod install --repo-update
```

**When to commit `Podfile.lock`:** Always — it ensures the team and CI resolve to the same Pod versions. Commit the updated lock after every `pod install`.

---

## Deployment Target Conflicts

Flutter plugins declare minimum iOS deployment targets in their `.podspec`. If your `Podfile` target is lower, CocoaPods warns or fails:

```text
[!] Automatically assigning platform `iOS` with version `12.0`
    because no platform was specified. Please specify a platform
    for the `Runner` target in your Podfile.
```

**Fix:** Set the deployment target explicitly in `ios/Podfile`:

```ruby
platform :ios, '13.0'   # matches Flutter's minimum for Firebase + Sign-In packages
```

Also set it in Xcode: **Runner target → General → Minimum Deployments → iOS 13.0**.

---

## Aligning Versions via `pubspec.yaml`

When two plugins conflict on a shared Pod, update both plugin versions in `pubspec.yaml` until their constraints are compatible. Check release notes and the [FlutterFire compatibility matrix](https://github.com/firebase/flutterfire#compatibility).

```yaml
# pubspec.yaml — example alignment after GTMSessionFetcher conflict
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1   # must agree on GTMSessionFetcher with firebase_auth
```

After changing versions:

```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
```

---

## Podfile Overrides — Use as Last Resort

When version alignment is not possible (e.g., waiting on an upstream release), pin the conflicting Pod directly in `ios/Podfile`:

```ruby
# ios/Podfile
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # TEMPORARY: pin GTMSessionFetcher until google_sign_in >= 6.3 resolves the conflict
  # Remove this when google_sign_in >= 6.3.0 is released and adopted.
  pod 'GTMSessionFetcher/Core', '~> 3.3'
end
```

**Rules for Podfile overrides:**

- Always add a `# TEMPORARY:` comment explaining why and what removes the need for it.
- Include the version constraint range (`~>`) not an exact pin (`=`) to allow patch updates.
- Remove the override as soon as the upstream fix lands.

---

## `use_frameworks!` vs `use_modular_headers!`

Firebase and Google Sign-In require either `use_frameworks!` (dynamic frameworks) or `use_modular_headers!` (static libraries with module maps).

```ruby
# Recommended for Flutter + Firebase + Google Sign-In
use_frameworks!
use_modular_headers!
```

If you see `Module 'Firebase' not found` or `Umbrella header not found`, this is the likely cause. Ensure both lines are present in the `target 'Runner'` block.

---

## CocoaPods Version Requirements

```bash
# Check current version
pod --version    # should be >= 1.14

# Upgrade
sudo gem install cocoapods

# If gem is slow or blocked, use Homebrew
brew install cocoapods
```

If you have both gem and Homebrew CocoaPods, ensure your `$PATH` resolves to one consistently:

```bash
which pod   # should be /usr/local/bin/pod or /opt/homebrew/bin/pod
```

---

## Diagnosing with Verbose Output

```bash
cd ios
pod install --repo-update --verbose 2>&1 | grep -E '\[!\]|error:|conflict'
```

The `--verbose` flag shows every resolution step. Filter with `grep` to surface conflicts without scrolling through thousands of lines.
