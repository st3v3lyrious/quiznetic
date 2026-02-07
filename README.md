# quiznetic_flutter

Quiznetic project built with Flutter.

- **Version:** `1.0.0+1`

- **Environment:** Dart SDK: `^3.8.1`

## Features

# FEATURES

Use this as an editable feature checklist.

## Core Quiz Loop

- [x] Splash -> Home -> Difficulty -> Quiz -> Results flow
- [x] Flag quiz category (`categoryKey: flag`)
- [x] Difficulty modes: easy (15), intermediate (30), expert (50)
- [x] Randomized quiz generation from `assets/flags/`
- [x] Per-session score tracking and progress indicator
- [x] Results flow prevents back navigation and requires explicit follow-up action buttons

## Accounts And Auth

- [x] Firebase initialization at app startup
- [x] Explicit first-entry auth choice screen when no session exists (guest or sign in)
- [x] Anonymous sign-in path with user doc creation (`users/{uid}`)
- [x] Provider sign-in path with user doc creation (`users/{uid}`)
- [x] Route-level auth guards on gameplay/profile routes (requires guest or signed-in session)
- [x] Entry choice screen with "Continue as Guest" and "Sign In / Create Account"
- [x] Provider login screen scaffold with Email, Google, Apple providers
- [x] Login screen uses valid logo asset and config-driven Google OAuth client ID
- [x] Upgrade account screen scaffold for anonymous users
- [x] Upgrade flow links anonymous guest to Email/Google/Apple while preserving UID continuity

## Scores And Profile

- [x] Local-first score repository for result/profile reads
- [x] Pending local score queue with retryable Firestore sync
- [x] Connectivity-aware retry backoff for offline/network sync failures
- [x] Forced pending-score sync on explicit reconnect triggers (startup, resume, auth success)
- [x] Save user best score per category+difficulty in Firestore
- [x] Save global leaderboard entry in Firestore (best-score semantics, one row per uid)
- [x] Leaderboard entries include anonymous tagging and normalized display names
- [x] Leaderboard band service for top 10/20/100 rank messaging
- [x] Anonymous guest conversion CTA on result screen using leaderboard band messaging
- [x] Anonymous guest conversion CTA on profile screen using best-band leaderboard messaging
- [x] Guest conversion CTA actions route to account-upgrade flow (`/upgrade`)
- [x] Profile screen listing stored high scores
- [x] Profile screen uses full difficulty labels + deterministic score ordering
- [x] Profile screen empty/error states include in-place refresh/retry actions

## Planned Features

- [ ] Add Logo quiz category
- [ ] Add Capitals quiz category
- [ ] Enable "Change Quiz Type" flow when multiple categories are live
- [ ] Expose anonymous-to-account upgrade in primary UX flow

## Test Scaffolding

- [x] Manual testing agent that generates unit/widget test scaffolds under `test/`
- [x] Manual testing agent that generates integration scaffolds under `integration_test/`
- [x] Manual testing agent that generates Playwright smoke + per-screen e2e scaffolds under `playwright/`
- [x] Unit test coverage command/script (`flutter test test/unit --coverage`, `tools/run_unit_coverage.sh`)

## Screens

- **Difficulty Screen** — Lets users choose difficulty and question count. (`lib/screens/difficulty_screen.dart`)
- **Entry Choice Screen** — Lets unauthenticated users choose between guest mode or provider sign-in. (`lib/screens/entry_choice_screen.dart`)
- **Home Screen** — Shows quiz categories and routes to difficulty selection. (`lib/screens/home_screen.dart`)
- **Login Screen** — Handles provider-based sign-in and account creation. (`lib/screens/login_screen.dart`)
- **Quiz** — Presents questions, records answers, and handles scoring. (`lib/screens/quiz_screen.dart`)
- **Result Screen** — Shows result summary and next actions after a quiz. (`lib/screens/result_screen.dart`)
- **Splash Screen** — Shows startup branding and routes users based on auth state. (`lib/screens/splash_screen.dart`)
- **Upgrade Account Screen** — Lets anonymous users link a permanent provider account while preserving guest identity. (`lib/screens/upgrade_account_screen.dart`)
- **User Profile Screen** — Displays user profile, saved high-score records, and guest conversion CTA. (`lib/screens/user_profile_screen.dart`)

## Tech stack

- Flutter, Firebase Core, Firebase Auth, Cloud Firestore, Shared Preferences

## Project structure

- `lib/screens/` — UI screens
- `lib/models/` — domain models
- `lib/data/` — data sources/loaders
- `test/` — unit + widget tests
- `integration_test/` — integration tests (E2E-style) if present
- `playwright/` — Playwright E2E tests

## Key models

- `FlagQuestion` (`lib/models/flag_question.dart`)

## Run locally

```bash
flutter pub get
flutter run
```

## Testing

- **Unit/Widget tests:** `22` files
- **Integration tests:** `4` files

```bash
flutter test
flutter test test/unit --coverage
./tools/run_unit_coverage.sh   # optional helper
flutter test integration_test   # if present
cd playwright && npx playwright test   # if present
```

## Dependencies (summary)

- **deps:** flutter, sdk, firebase_core, firebase_auth, cloud_firestore, shared_preferences, firebase_ui_auth, git, url, path, ref, firebase_ui_oauth_google…
- **dev_deps:** flutter_test, sdk, integration_test, sdk, flutter_lints

## Roadmap

# ROADMAP

Use this as a short, editable delivery plan.

- [x] M1: Stabilize entry auth flow (dedicated entry-choice screen, provider login on second step, no startup auto-guest auth).
- [x] M1: Implement local-first score repository (persist locally first for guest and signed-in users).
- [x] M1: Add pending score sync queue with retry for Firestore/network failures.
- [x] M1: Sync pending local scores on reconnect and on account-link/sign-in.
- [x] M1: Add connectivity-aware retry backoff with forced retry bypass on explicit sync triggers.
- [x] M1: Fix login setup issues (logo asset path and Google OAuth client ID via config).
- [x] M2: Clarify leaderboard semantics (best score per user per `category+difficulty`, tie-breakers by `score desc`, `updatedAt asc`, `uid asc`).
- [x] M2: Define anonymous leaderboard policy (included in global leaderboard and explicitly tagged).
- [x] M2: Implement leaderboard band service (`top 10/20/100` + outside) for conversion UX.
- [x] M2: Add guest conversion messaging from leaderboard bands (e.g., top 10/20/100) on results.
- [x] M2: Extend "Create account to compete globally" CTA to guest profile surface.
- [x] M2: Add guest CTA action flow to `/upgrade` from results/profile and preserve post-upgrade continuity.
- [x] M2: Upgrade screen performs anonymous-account linking (Email/Google/Apple) with guest UID continuity checks.
- [x] M2: Harden profile display (difficulty labels, ordering, empty/error states).
- [x] M2: Apply `AuthGuard` strategy consistently to protected routes.
- [x] M2: Replace deprecated result-screen back handling (`WillPopScope`) with `PopScope` and cover it with widget tests.
- [ ] M3: Implement a second quiz category (Logo or Capitals) using current category-key pattern.
- [ ] M3: Enable quiz-type switching in navigation/results flow.
- [ ] M4: Replace template widget test with app-specific flow tests in `test/unit` and `test/widget`.
- [x] M4: Add non-scaffold integration assertions in `integration_test`.
- [x] M4: Add Playwright e2e assertions in `playwright/tests`.
- [x] M4: Auto-generate Playwright smoke + per-screen e2e scaffolds as screens are added.
- [x] M4: Regenerate README from docs (`FEATURES`, `ROADMAP`, `ARCHITECTURE`).
- [x] M5: Bump macOS deployment target to 10.15+ so FlutterFire integration tests can run on macOS.


---

_This README is generated by `tools/readme_agent.py`. Edit `docs/FEATURES.md` and `docs/ROADMAP.md` for human-written content._
