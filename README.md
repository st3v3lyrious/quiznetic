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
- [x] Capital quiz category (`categoryKey: capital`)
- [x] Difficulty modes: easy (15), intermediate (30), expert (50)
- [x] Randomized quiz generation from `assets/flags/`
- [x] Per-session score tracking and progress indicator
- [x] Results flow prevents back navigation and requires explicit follow-up action buttons
- [x] Quiz answer feedback includes non-color states (icon + text)
- [x] Quiz progress and result summary expose live semantic announcements
- [x] Quiz-type switching action from difficulty/result screens back to category selection

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
- [x] Score submission validator enforces category, difficulty, question-count, and score bounds
- [x] Idempotent score-attempt records are persisted under users/{uid}/attempts/{attemptId}
- [x] Firestore rules enforce monotonic best-score updates, scope/doc-id consistency, and server-managed `updatedAt` timestamps
- [x] Leaderboard band service for top 10/20/100 rank messaging
- [x] Anonymous guest conversion CTA on result screen using leaderboard band messaging
- [x] Anonymous guest conversion CTA on profile screen using best-band leaderboard messaging
- [x] Anonymous guest conversion CTA in primary home flow (routes to `/upgrade`)
- [x] Guest conversion CTA actions route to account-upgrade flow (`/upgrade`)
- [x] Profile screen listing stored high scores
- [x] Profile screen uses full difficulty labels + deterministic score ordering
- [x] Profile screen empty/error states include in-place refresh/retry actions

## Planned Features

- [ ] Add Guess the Celebrity quiz category (Deferred outside MVP scope)
- [ ] Add Guess the Song from Lyrics quiz category (Deferred outside MVP scope)
- [ ] Add Guess the Anime quiz category
- [ ] Add Apple sign-in as a production-ready auth option
- [x] Implement a global leaderboard screen (with UX/design, category+difficulty filters, and ranking presentation)
- [ ] Create branded app icons for all target platforms
- [ ] Create branded splash screens for all target platforms
- [x] Configure branding asset pipeline (launcher icons + native splash generation runbook)
- [x] Create a Settings screen
- [x] Create an About screen
- [ ] Add product analytics instrumentation
- [ ] Add analytics event breadcrumbs for crash triage (screen views + critical actions)
- [x] Add crash reporting (Crashlytics baseline with compile-time kill switch)
- [ ] Integrate monetization via ads
- [ ] Integrate monetization via in-app purchases (IAP)
- [ ] Improve UI/UX polish (animations, progress bar behavior, answer feedback styling)
- [ ] Add content licensing + attribution pipeline for celebrity/song/anime datasets
- [x] Harden Firestore security rules with automated rule tests
- [ ] Add leaderboard integrity protections (anti-cheat heuristics, abuse controls, write throttling)
- [x] Add CI/CD quality gates (analyze, unit/widget/integration/e2e, coverage threshold + branch protection required checks)
- [x] Add privacy and legal readiness baseline (Privacy Policy, Terms, and consent links in entry/login/upgrade flows)
- [ ] Add Remote Config feature flags for staged rollout
- [ ] Implement localization by default (i18n-ready string resources + locale resolution)
- [ ] Add language selection in Settings (persisted user preference + fallback locale)
- [x] Add accessibility baseline (screen-reader labels, contrast checks, text-scaling support)
- [ ] Add release operations readiness (crash alert routing, KPI dashboard, rollback playbook)
  - [x] Baseline runbook + kill-switch checklist documented (`docs/RELEASE_OPS_RUNBOOK.md`)
  - [x] Alert routing + KPI threshold policy documented (`docs/ALERT_ROUTING_AND_KPI_THRESHOLDS.md`)
  - [x] CI failure webhook routing automation added (optional `ALERT_WEBHOOK_URL`)
  - [x] Incident postmortem template + cadence documented (`docs/INCIDENT_POSTMORTEM_TEMPLATE.md`)
  - [ ] Dedicated on-call paging + KPI dashboard automation pending
- [ ] Add user feedback collection loop (in-app feedback form + categorization + roadmap review input)
- [ ] Launch MVP
- [ ] Add Logo quiz category (Deferred: blocked by logo asset dataset + answer metadata map)

## Test Scaffolding

- [x] Manual testing agent that generates unit/widget test scaffolds under `test/`
- [x] Manual testing agent that generates integration scaffolds under `integration_test/`
- [x] Manual testing agent that generates Playwright smoke + per-screen e2e scaffolds under `playwright/`
- [x] Unit test coverage command/script (`flutter test test/unit --coverage`, `tools/run_unit_coverage.sh`)

## Screens

- **About Screen** — Shows app summary, version metadata, support contact, and legal links. (`lib/screens/about_screen.dart`)
- **Difficulty Screen** — Lets users choose difficulty and question count. (`lib/screens/difficulty_screen.dart`)
- **Entry Choice Screen** — Lets unauthenticated users choose between guest mode or provider sign-in. (`lib/screens/entry_choice_screen.dart`)
- **Home Screen** — Shows quiz categories, guest upgrade CTA, and routes to difficulty selection. (`lib/screens/home_screen.dart`)
- **Leaderboard Screen** — Displays global ranking with category+difficulty filters and user highlight. (`lib/screens/leaderboard_screen.dart`)
- **Legal Document Screen** — Displays local legal document text (terms or privacy policy). (`lib/screens/legal_document_screen.dart`)
- **Login Screen** — Handles provider-based sign-in and account creation. (`lib/screens/login_screen.dart`)
- **Quiz** — Presents questions, records answers, and handles scoring. (`lib/screens/quiz_screen.dart`)
- **Result Screen** — Shows result summary and next actions after a quiz. (`lib/screens/result_screen.dart`)
- **Settings Screen** — Provides account/session controls, legal links, and app preferences. (`lib/screens/settings_screen.dart`)
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

- **Unit/Widget tests:** `35` files
- **Integration tests:** `7` files

```bash
flutter test
flutter test test/unit --coverage
./tools/run_unit_coverage.sh   # optional helper
flutter test integration_test   # if present
cd playwright && npx playwright test   # if present
```

## Dependencies (summary)

- **deps:** flutter, sdk, firebase_core, firebase_auth, cloud_firestore, cloud_functions, firebase_crashlytics, shared_preferences, firebase_ui_auth, git, url, path…
- **dev_deps:** flutter_test, sdk, integration_test, sdk, flutter_lints, flutter_launcher_icons, flutter_native_splash

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
- [x] M3: Implement a second quiz category (Capitals) using current category-key pattern.
- [x] M3: Enable quiz-type switching in navigation/results flow.
- [x] M3: Expose anonymous-to-account upgrade in primary home UX flow.
- [x] M4: Replace template widget test with app-specific flow tests in `test/unit` and `test/widget`.
- [x] M4: Add non-scaffold integration assertions in `integration_test`.
- [x] M4: Add Playwright e2e assertions in `playwright/tests`.
- [x] M4: Auto-generate Playwright smoke + per-screen e2e scaffolds as screens are added.
- [x] M4: Regenerate README from docs (`FEATURES`, `ROADMAP`, `ARCHITECTURE`).
- [x] M5: Bump macOS deployment target to 10.15+ so FlutterFire integration tests can run on macOS.
- [ ] M6: Add Logo quiz category (deferred until curated/licensed logo asset set + mapping metadata are available).
- [ ] M7: Add Guess the Celebrity quiz category (deferred outside MVP scope; content set + quiz loader + tests).
- [ ] M8: Add Guess the Song from Lyrics quiz category (deferred outside MVP scope; licensed lyric snippets + answer metadata + tests).
- [ ] M9: Add Guess the Anime quiz category (content set + quiz loader + tests).
- [ ] M10: Ship Apple sign-in as a production-ready provider across supported platforms.
- [x] M11: Implement global leaderboard experience (data query strategy + screen design + filters).
- [ ] M12: Add branded app icons and splash screens for all target platforms.
  - [x] Baseline asset pipeline configured (`flutter_launcher_icons`, `flutter_native_splash`, and `tools/refresh_branding_assets.sh`).
  - [x] Brand color tokens centralized in `lib/config/brand_config.dart`.
  - [ ] Final artwork export + multi-platform visual QA pending.
  - Activation/update runbook: `docs/BRANDING_ASSETS.md`
- [x] M13: Build Settings and About screens.
  - Includes account/session controls, sign-out flow, legal links, and app metadata/support surface.
- [ ] M14: Add analytics and crash reporting instrumentation.
  - [x] Crash reporting baseline shipped (Firebase Crashlytics init + Flutter/zone unhandled error capture).
  - [x] Crash reporting kill switch added: `ENABLE_CRASH_REPORTING` (default `true`).
  - [ ] Add analytics event breadcrumbs for crash triage (screen views + critical flow actions).
  - [ ] Product analytics instrumentation still pending.
- [ ] M15: Integrate monetization stack (ads + in-app purchases).
- [ ] M16: Improve UI/UX polish (animations, progress indicators, feedback styling).
- [ ] M17: Launch MVP (release checklist, store metadata, and production rollout).
- [ ] M18: Build content licensing + attribution pipeline for celebrity/song/anime datasets.
- [x] M19: Harden Firestore security rules and add automated Firestore-rules tests in CI.
- [ ] M20: Add leaderboard integrity protections (anti-cheat scoring checks, abuse controls, rate limits).
  - Contract reference: docs/ANTI_CHEAT_CONTRACT.md
  - [x] Phase 1 baseline shipped: validator, idempotent attempt records, stricter Firestore score bounds/scope checks.
  - [ ] Phase 2 pending: backend-authoritative submitScore path + direct projection write lock for clients.
  - Blaze-gated partial implementation shipped: callable `submitScore` + app flag (`ENABLE_BACKEND_SUBMIT_SCORE`) default-off on Spark.
  - Activation/rollback conditions: docs/BLAZE_FEATURE_FLAGS.md
- [x] M21: Enforce CI/CD quality gates (GitHub Actions + branch protection required checks are active on `main`).
- [x] M22: Complete privacy/legal baseline (Privacy Policy, Terms, consent copy, and in-app legal links).
  - Formal legal counsel review and age-rating metadata can be finalized before public store launch.
- [ ] M23: Introduce Remote Config/feature flags for staged feature rollout.
- [ ] M24: Implement localization foundation (externalized strings, locale resolution, default i18n coverage).
- [ ] M25: Add user-selectable app language in Settings with persisted preference and safe fallback.
- [x] M26: Complete accessibility baseline (semantics labels, contrast, dynamic type/text scaling).
  - Added semantic labels for core logo/question imagery surfaces.
  - Added WCAG AA contrast unit checks for primary theme color pairs.
  - Added large text-scaling widget coverage for entry, settings, about, difficulty, home, quiz, result, leaderboard, and profile flows.
  - Added non-color quiz answer feedback (icon + text states) and live semantic announcements for quiz progress/result summary.
  - Follow-up audit and prioritized backlog: `docs/ACCESSIBILITY_AUDIT.md`.
- [ ] M27: Establish release operations readiness (alerts, KPI dashboard, rollback playbook, beta process).
  - [x] Baseline release ops runbook published: `docs/RELEASE_OPS_RUNBOOK.md`.
  - [x] Rollback playbook and kill-switch checklist documented.
  - [x] Alert routing policy + KPI thresholds documented: `docs/ALERT_ROUTING_AND_KPI_THRESHOLDS.md`.
  - [x] CI failure alert routing automation shipped (webhook via `ALERT_WEBHOOK_URL`).
  - [x] Incident postmortem template + review cadence documented: `docs/INCIDENT_POSTMORTEM_TEMPLATE.md`.
  - [ ] Dedicated pager/on-call automation and KPI dashboard automation still pending.
- [ ] M28: Build feedback intelligence loop (in-app feedback capture, tagged triage, and recurring roadmap review cadence).


---

_This README is generated by `tools/readme_agent.py`. Edit `docs/FEATURES.md` and `docs/ROADMAP.md` for human-written content._
