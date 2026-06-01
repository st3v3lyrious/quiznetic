---
name: quiznetic-release
description: 'Flutter release management for QuizNetic. Use when: preparing a release build, bumping version numbers, tagging Git, submitting to TestFlight or Play Store, separating Firebase environments, writing release notes, or verifying production readiness. Lightweight solo-developer workflow. Covers pubspec.yaml versioning, semantic version rules, iOS archive/TestFlight, Android AAB/Play Store, env separation, and pre-release checklist.'
argument-hint: 'Describe what kind of release you are preparing (patch, minor, major, iOS, Android, both)...'
---

# QuizNetic Release Management Skill

## When to Use
- Bumping version or build number before submitting a build
- Tagging a release in Git
- Preparing an iOS archive for TestFlight or App Store
- Preparing an Android AAB for Play Store
- Verifying Firebase is pointing at production (not dev)
- Running the pre-release checklist before submitting

## Quick Reference

| Area | Reference |
|------|-----------|
| Semantic versioning & pubspec.yaml | [versioning.md](./references/versioning.md) |
| iOS TestFlight & App Store | [ios-release.md](./references/ios-release.md) |
| Android Play Store | [android-release.md](./references/android-release.md) |
| Firebase environment separation | [firebase-env.md](./references/firebase-env.md) |

---

## Release Type Decision

| What changed | Version bump | Example |
|---|---|---|
| Bug fix, no new features | Patch `x.y.Z` | `1.3.2` → `1.3.3` |
| New feature, backward compatible | Minor `x.Y.0` | `1.3.2` → `1.4.0` |
| Major redesign or breaking change | Major `X.0.0` | `1.3.2` → `2.0.0` |
| Internal build for testing only | Build number only | `1.3.2+44` → `1.3.2+45` |

When in doubt: **patch**. Over-incrementing minor/major is more confusing than under-incrementing.

---

## Release Procedure (Solo Developer)

### 1. Decide Version
Determine the bump type from the table above. Update `pubspec.yaml`:
```yaml
version: 1.4.0+47   # x.y.z+buildNumber
```
See [versioning.md](./references/versioning.md) for rules.

### 2. Verify Firebase Environment
Confirm `.env` points to the **production** Firebase project. Run `./tools/sync_env.sh`.
See [firebase-env.md](./references/firebase-env.md).

### 3. Run the Pre-Release Checklist
Run all checks in order — do not skip:

```bash
flutter analyze          # zero issues required
flutter test             # all tests must pass
flutter build ios --release --dart-define-from-file=.env     # confirms iOS compiles
flutter build appbundle --release --dart-define-from-file=.env  # confirms Android compiles
```

### 4. Build the Release Artifacts
- iOS → [ios-release.md](./references/ios-release.md)
- Android → [android-release.md](./references/android-release.md)

### 5. Tag the Release in Git
```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.4.0+47"
git tag -a v1.4.0 -m "Release 1.4.0 — <one-line description>"
git push origin HEAD
git push origin v1.4.0
```

### 6. Submit Builds
- iOS: upload via Xcode Organizer or Transporter → TestFlight → App Store Review
- Android: upload AAB in Play Console → Internal Testing → Production

---

## Pre-Release Checklist

```
- [ ] Version string + build number bumped in pubspec.yaml
- [ ] Build number is unique — never reused
- [ ] flutter analyze: zero issues
- [ ] flutter test: all pass
- [ ] .env points to PRODUCTION Firebase project
- [ ] ./tools/sync_env.sh run after any .env change
- [ ] AdMob IDs are production (not test) values
- [ ] flutter build ios --release succeeds
- [ ] flutter build appbundle --release succeeds
- [ ] Tested on a physical device in release mode
- [ ] Git commit includes pubspec.yaml version bump
- [ ] Git tag pushed to origin
- [ ] Release notes written for TestFlight / Play Store
```
