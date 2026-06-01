---
name: quiznetic-ios-debug
description: 'iOS build and runtime debugging for QuizNetic Flutter + Firebase app. Use when: CocoaPods install fails, Podfile conflicts, GTMSessionFetcher version conflicts, FlutterFire dependency mismatches, Firebase iOS integration errors, Google Sign-In iOS issues, Xcode workspace errors, DT_TOOLCHAIN_DIR, build cache problems, or Flutter SDK compatibility issues on iOS. Explains root causes, prefers proper dependency alignment over hacky fixes, provides Warp-ready terminal commands.'
argument-hint: 'Paste the error message or describe the iOS build symptom...'
---

# QuizNetic iOS Debug Skill

## When to Use
- `pod install` fails with version conflict or dependency error
- Xcode build fails after `flutter pub get` or a package upgrade
- `GTMSessionFetcher` version conflict between `google_sign_in` and Firebase
- `GoogleService-Info.plist` not found or wrong project
- Google Sign-In produces "The operation couldn't be completed" on device
- `DT_TOOLCHAIN_DIR` or `IPHONEOS_DEPLOYMENT_TARGET` build errors (Xcode 15+)
- FlutterFire packages fail to compile after upgrading `firebase_core`
- Build succeeds but Firebase crashes on launch
- Derived Data / build cache causing stale artifact errors

## Quick Reference

| Area | Reference |
|------|-----------|
| CocoaPods conflicts & clean sequences | [cocoapods.md](./references/cocoapods.md) |
| Firebase iOS integration & GTMSessionFetcher | [firebase-ios.md](./references/firebase-ios.md) |
| Google Sign-In iOS setup & errors | [google-signin-ios.md](./references/google-signin-ios.md) |
| Xcode workspace, cache & SDK compatibility | [xcode-workspace.md](./references/xcode-workspace.md) |

---

## Diagnostic Procedure

### Step 1 — Read the Full Error
Never fix the first line of an error. Scroll to the **root cause** — it is almost always the last `error:` block or the `[!]` line in CocoaPods output.

Common root cause signatures:

| Error fragment | Go to |
|----------------|-------|
| `CocoaPods could not find compatible versions` | [cocoapods.md → Dependency Conflict](./references/cocoapods.md) |
| `GTMSessionFetcher` version mismatch | [firebase-ios.md → GTMSessionFetcher](./references/firebase-ios.md) |
| `DT_TOOLCHAIN_DIR` | [xcode-workspace.md → Xcode 15](./references/xcode-workspace.md) |
| `IPHONEOS_DEPLOYMENT_TARGET` below minimum | [xcode-workspace.md → Deployment Target](./references/xcode-workspace.md) |
| `GoogleService-Info.plist` missing | [firebase-ios.md → Plist Setup](./references/firebase-ios.md) |
| `CFBundleURLTypes` / Google Sign-In | [google-signin-ios.md](./references/google-signin-ios.md) |
| `Module 'Firebase' not found` | [firebase-ios.md → Module Not Found](./references/firebase-ios.md) |
| Stale `.o` / symbol not found after clean | [xcode-workspace.md → Build Cache](./references/xcode-workspace.md) |

### Step 2 — Run the Standard Clean Sequence First
Most iOS build failures are resolved by this sequence. Run it before investigating further:

```bash
flutter clean
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
cd ..
flutter pub get
```

Then attempt `flutter build ios` or `flutter run` again.

### Step 3 — If the Clean Sequence Didn't Fix It
- Dependency conflict → check `pubspec.yaml` package versions against the [FlutterFire compatibility matrix](https://github.com/firebase/flutterfire#compatibility).
- `GTMSessionFetcher` conflict → align `google_sign_in` and `firebase_auth` versions (see [firebase-ios.md](./references/firebase-ios.md)).
- Persistent Xcode error → delete Derived Data (see [xcode-workspace.md](./references/xcode-workspace.md)).
- `GoogleService-Info.plist` error → verify file and run `./tools/sync_env.sh`.

### Step 4 — Validate the Fix
After applying any fix:
1. `flutter build ios --release --dart-define-from-file=.env` must complete without errors.
2. Run on a physical device (not just simulator) before closing the issue.
3. Test Google Sign-In and Firebase Auth flows end-to-end.

---

## Core Principles

1. **Never modify files in `.pub-cache/`** — they are owned by the Flutter SDK and are overwritten by `flutter pub get`. Any fix made there is invisible, fragile, and will break for other developers.
2. **Prefer version alignment over Podfile overrides** — add `pod 'SomePod', '~> x.y'` to the Podfile only when alignment via `pubspec.yaml` is not possible.
3. **Mark temporary fixes explicitly** — if a Podfile workaround is unavoidable, add a comment: `# TEMPORARY: remove when google_sign_in >= x.y is released`.
4. **Fix at the highest level possible** — `pubspec.yaml` version constraints first, then `Podfile` overrides, then `post_install` script patches as a last resort.

---

## Validation Checklist

- [ ] `flutter analyze` — zero issues after the fix?
- [ ] `flutter build ios --release` completes without errors?
- [ ] `pod install` output shows no `[!]` warnings?
- [ ] No `.pub-cache` files were modified?
- [ ] If a Podfile workaround was used, is it commented as temporary?
- [ ] `GoogleService-Info.plist` matches the current Firebase project?
- [ ] Google Sign-In and Apple Sign-In tested on a physical device?
- [ ] Firebase initializes without crash on cold launch?
