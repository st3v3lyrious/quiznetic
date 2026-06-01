# Semantic Versioning & pubspec.yaml Management

## Version String Format

```yaml
# pubspec.yaml
version: 1.4.0+47
#        ^^^^^ ^^
#        |     └── build number (integer, always incrementing)
#        └──────── marketing version (shown in stores)
```

These are two independent numbers with different audiences:

- **Marketing version** (`1.4.0`) — shown to users in the App Store and Play Store. Follows semantic versioning.
- **Build number** (`47`) — used internally by Apple and Google to distinguish builds. Must be an integer that increases monotonically. **Never reuse a build number** — both stores reject duplicate build numbers for the same app.

---

## Semantic Versioning — Pragmatic Rules for a Solo App

| Change type | Bump | Reset |
| ------------- | ------ | ------- |
| Bug fix, crash fix, copy change | `PATCH` (`x.y.Z+1`) | — |
| New screen, new feature, new quiz category | `MINOR` (`x.Y.0+n`) | Reset PATCH to 0 |
| Major redesign, monetization model change, breaking backend schema | `MAJOR` (`X.0.0+n`) | Reset MINOR and PATCH to 0 |
| TestFlight / internal test build with no visible change | Build number only | Marketing version stays |

**Practical examples:**

```yaml
# Fixed a crash on the result screen
version: 1.3.2+44  →  1.3.3+45

# Added a new quiz category
version: 1.3.3+45  →  1.4.0+46

# Rewrote the quiz engine + new scoring system
version: 1.4.0+46  →  2.0.0+47

# Second TestFlight build for 2.0.0 (no user-visible change from first)
version: 2.0.0+47  →  2.0.0+48
```

---

## Updating pubspec.yaml

Edit the version line directly:

```yaml
name: quiznetic
description: A quiz app.
version: 1.4.0+47   # ← update this line
```

After editing:

```bash
flutter pub get   # updates pubspec.lock; required before building
```

---

## Tracking Build Numbers

For a solo developer, a simple incrementing integer is sufficient. Keep a record to avoid reuse:

```bash
# Check the current version before bumping
grep '^version:' pubspec.yaml

# What was the last tag?
git tag --sort=-creatordate | head -5
```

A pragmatic approach: keep build number in sync with a rough commit count or increment by 1 per submission. The rule is only that it must be higher than any previously submitted build.

---

## Git Tagging

Tag every build that is submitted to a store or sent to external testers. Not every internal build needs a tag.

```bash
# Annotated tag (recommended — includes message and tagger info)
git tag -a v1.4.0 -m "Release 1.4.0 — added Europe quiz category"

# Push the tag to origin
git push origin v1.4.0

# Push all local tags at once (use carefully)
git push origin --tags
```

### Tag Naming Convention

| Build type | Tag format | Example |
| ------------ | ----------- | --------- |
| App Store / Play Store release | `v{major}.{minor}.{patch}` | `v1.4.0` |
| TestFlight / internal beta | `v{version}-beta.{n}` | `v1.4.0-beta.2` |
| Hotfix | `v{version}` with patch bump | `v1.4.1` |

### Listing and Navigating Tags

```bash
# List all tags, newest first
git tag --sort=-creatordate

# Show what a tag points to
git show v1.4.0 --stat

# Check out a specific release (read-only)
git checkout v1.4.0

# Return to your branch
git checkout mvp_readiness_step_one
```

---

## Git Workflow for a Release (Solo)

```bash
# 1. Ensure you are on the correct branch and it is clean
git status
git pull origin mvp_readiness_step_one   # or main

# 2. Bump version in pubspec.yaml (edit manually)
# version: 1.4.0+47

# 3. Commit the version bump — keep it atomic (version bump only)
git add pubspec.yaml
git commit -m "chore: bump version to 1.4.0+47"

# 4. Build and test (see SKILL.md checklist)

# 5. Tag after successful build and submission
git tag -a v1.4.0 -m "Release 1.4.0 — <description>"
git push origin HEAD
git push origin v1.4.0
```

**Why commit before tagging?** The tag should point to the exact commit that produced the submitted build — including the version bump. Tagging before committing leaves the tag on the wrong commit.

---

## Release Branch Strategy (Lightweight)

For a solo developer, branching per release is optional. A pragmatic approach:

- Develop on `main` (or a feature branch like `mvp_readiness_step_one`)
- Merge to `main` before tagging a release
- Tag on `main`
- Cherry-pick hotfixes to `main` and re-tag with a patch bump

This avoids maintaining long-lived release branches while keeping the tag history clean.

---

## What NOT to Do

- Do not reuse a build number — both stores reject duplicate build numbers.
- Do not tag before the build is confirmed to compile and pass `flutter analyze`.
- Do not push a tag before pushing the commit it points to (`git push origin HEAD` first).
- Do not amend a commit that has already been tagged — the tag will point to the wrong commit SHA.
- Do not use lightweight tags (`git tag v1.4.0`) for releases — use annotated tags (`-a`) so the tagger, date, and message are recorded.
