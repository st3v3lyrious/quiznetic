# quiznetic_flutter

Quiznetic project built with Flutter.

- **Version:** `1.0.0+1`

- **Environment:** Dart SDK: `^3.9.0`

## Features

# FEATURES

Use this as an editable feature checklist.

## Core Quiz Loop

- [x] Splash -> Home -> Difficulty -> Quiz -> Results flow <!--gh:issue=63-->
- [x] Flag quiz category (`categoryKey: flag`) <!--gh:issue=64-->
- [x] Capital quiz category (`categoryKey: capital`) <!--gh:issue=65-->
- [x] Difficulty modes: easy (15), intermediate (30), expert (50) <!--gh:issue=66-->
- [x] Randomized quiz generation from `assets/flags/` <!--gh:issue=67-->
- [x] Per-session score tracking and progress indicator <!--gh:issue=68-->
- [x] Results flow prevents back navigation and requires explicit follow-up action buttons <!--gh:issue=69-->
- [x] Quiz answer feedback includes non-color states (icon + text) <!--gh:issue=70-->
- [x] Quiz progress and result summary expose live semantic announcements <!--gh:issue=71-->
- [x] Optional `Describe Flag` accessibility affordance (opt-in via Settings) <!--gh:issue=72-->
- [x] Flag-description metadata quality gate (unit checks for description format + minimum asset coverage) <!--gh:issue=73-->
- [x] Curated flag-description coverage for all bundled flag assets (`263/263`) <!--gh:issue=74-->
- [x] Quiz-type switching action from difficulty/result screens back to category selection <!--gh:issue=75-->

## Accounts And Auth

- [x] Firebase initialization at app startup <!--gh:issue=76-->
- [x] Explicit first-entry auth choice screen when no session exists (guest or sign in) <!--gh:issue=77-->
- [x] Anonymous sign-in path with user doc creation (`users/{uid}`) <!--gh:issue=78-->
- [x] Provider sign-in path with user doc creation (`users/{uid}`) <!--gh:issue=79-->
- [x] Route-level auth guards on gameplay/profile routes (requires guest or signed-in session) <!--gh:issue=80-->
- [x] Entry choice screen with "Continue as Guest" and "Sign In / Create Account" <!--gh:issue=81-->
- [x] Provider login screen scaffold with Email, Google, Apple providers <!--gh:issue=82-->
- [x] Login screen uses valid logo asset and config-driven Google OAuth client ID <!--gh:issue=83-->
- [x] Upgrade account screen scaffold for anonymous users <!--gh:issue=84-->
- [x] Upgrade flow links anonymous guest to Email/Google/Apple while preserving UID continuity <!--gh:issue=85-->

## Scores And Profile

- [x] Local-first score repository for result/profile reads <!--gh:issue=86-->
- [x] Pending local score queue with retryable Firestore sync <!--gh:issue=87-->
- [x] Connectivity-aware retry backoff for offline/network sync failures <!--gh:issue=88-->
- [x] Forced pending-score sync on explicit reconnect triggers (startup, resume, auth success) <!--gh:issue=89-->
- [x] Save user best score per category+difficulty in Firestore <!--gh:issue=90-->
- [x] Save global leaderboard entry in Firestore (best-score semantics, one row per uid) <!--gh:issue=91-->
- [x] Leaderboard entries include anonymous tagging and normalized display names <!--gh:issue=92-->
- [x] Score submission validator enforces category, difficulty, question-count, and score bounds <!--gh:issue=93-->
- [x] Idempotent score-attempt records are persisted under users/{uid}/attempts/{attemptId} <!--gh:issue=94-->
- [x] Firestore rules enforce monotonic best-score updates, scope/doc-id consistency, and server-managed projection/attempt timestamps (`updatedAt`, `createdAt`) <!--gh:issue=95-->
- [x] Leaderboard band service for top 10/20/100 rank messaging <!--gh:issue=96-->
- [x] Anonymous guest conversion CTA on result screen using leaderboard band messaging <!--gh:issue=97-->
- [x] Anonymous guest conversion CTA on profile screen using best-band leaderboard messaging <!--gh:issue=98-->
- [x] Anonymous guest conversion CTA in primary home flow (routes to `/upgrade`) <!--gh:issue=99-->
- [x] Guest conversion CTA actions route to account-upgrade flow (`/upgrade`) <!--gh:issue=100-->
- [x] Profile screen listing stored high scores <!--gh:issue=101-->
- [x] Profile screen uses full difficulty labels + deterministic score ordering <!--gh:issue=102-->
- [x] Profile screen empty/error states include in-place refresh/retry actions <!--gh:issue=103-->

## Planned Features

- [ ] Add Guess the Celebrity quiz category (Deferred outside MVP scope) <!--gh:issue=104-->
- [ ] Add Guess the Song from Lyrics quiz category (Deferred outside MVP scope) <!--gh:issue=105-->
- [ ] Add Guess the Anime quiz category <!--gh:issue=106-->
- [ ] Add Apple sign-in as a production-ready auth option <!--gh:issue=107-->
  - [x] Runtime provider gating + rollback flag (`ENABLE_APPLE_SIGN_IN`, default `false`)
  - [x] iOS/macOS entitlement baseline committed for Sign in with Apple
  - [ ] Apple Developer + Firebase provider credentials/setup still required per environment
- [x] Implement a global leaderboard screen (with UX/design, category+difficulty filters, and ranking presentation) <!--gh:issue=108-->
- [ ] Create branded app icons for all target platforms <!--gh:issue=109-->
- [ ] Create branded splash screens for all target platforms <!--gh:issue=110-->
- [x] Configure branding asset pipeline (launcher icons + native splash generation runbook) <!--gh:issue=111-->
- [x] Create a Settings screen <!--gh:issue=112-->
- [x] Create an About screen <!--gh:issue=113-->
- [x] Add product analytics instrumentation (baseline auth + quiz + score funnel events) <!--gh:issue=114-->
- [x] Add analytics event breadcrumbs for crash triage (screen views + critical actions) <!--gh:issue=115-->
- [x] Add crash reporting (Crashlytics baseline with compile-time kill switch) <!--gh:issue=116-->
- [x] Historical ads baseline (removed in M30; reimplementation tracked by M15) <!--gh:issue=117-->
  - [x] Banner ad placements on home and result screens
  - [x] Placement-aware ad-unit mapping (Android+iOS home/result ids, with shared fallback ids)
  - [x] Runtime gating via `ENABLE_ADS` plus entitlement check (`remove_ads`)
  - [x] Non-release compliance guard blocks live `ca-app-pub-*` units unless explicitly allowed (`ALLOW_LIVE_AD_UNITS_IN_DEBUG=true`)
  - [x] Result-screen hybrid ad strategy behind dedicated flag (`ENABLE_RESULT_INTERSTITIAL_ADS`, default `false`): interstitial-first with banner fallback on failure
  - [x] Native AdMob app-id baseline configured (`com.google.android.gms.ads.APPLICATION_ID` / `GADApplicationIdentifier`)
- [x] Historical IAP baseline (removed in M30; reimplementation tracked by M15) <!--gh:issue=118-->
  - [x] Runtime gating via `ENABLE_IAP` (default `false`)
  - [x] Lifetime `Remove Ads` catalog + purchase/restore plumbing
  - [x] Persisted entitlement state (`entitlement_remove_ads`) to suppress ads post-purchase
  - [x] Hint monetization baseline in quiz flow (rewarded remove-2-wrong + paid fallback after session cap)
  - [x] Hint feature flags and defaults: `ENABLE_REWARDED_HINTS=false`, `ENABLE_PAID_HINTS=false`, `REWARDED_HINTS_PER_SESSION=3`
  - [ ] Store-side product/ad unit setup and sandbox QA still required before rollout
- [ ] Improve UI/UX polish (animations, progress bar behavior, answer feedback styling) <!--gh:issue=119-->
- [ ] Add content licensing + attribution pipeline for celebrity/song/anime datasets <!--gh:issue=120-->
- [x] Harden Firestore security rules with automated rule tests <!--gh:issue=121-->
- [ ] Add leaderboard integrity protections (anti-cheat heuristics, abuse controls, write throttling) <!--gh:issue=122-->
- [x] Add CI/CD quality gates (analyze, unit/widget/integration/e2e, coverage threshold + branch protection required checks) <!--gh:issue=123-->
- [x] Add privacy and legal readiness baseline (Privacy Policy, Terms, and consent links in entry/login/upgrade flows) <!--gh:issue=124-->
- [ ] Add Remote Config feature flags for staged rollout <!--gh:issue=125-->
- [ ] Implement localization by default (i18n-ready string resources + locale resolution) <!--gh:issue=126-->
- [ ] Add language selection in Settings (persisted user preference + fallback locale) <!--gh:issue=127-->
- [x] Add accessibility baseline (screen-reader labels, contrast checks, text-scaling support) <!--gh:issue=128-->
- [ ] Add release operations readiness (crash alert routing, KPI dashboard, rollback playbook) <!--gh:issue=129-->
  - [x] Baseline runbook + kill-switch checklist documented (`docs/RELEASE_OPS_RUNBOOK.md`)
  - [x] Alert routing + KPI threshold policy documented (`docs/ALERT_ROUTING_AND_KPI_THRESHOLDS.md`)
  - [x] CI failure webhook routing automation added (optional `ALERT_WEBHOOK_URL`)
  - [x] Incident postmortem template + cadence documented (`docs/INCIDENT_POSTMORTEM_TEMPLATE.md`)
  - [ ] Dedicated on-call paging + KPI dashboard automation pending
- [ ] Add user feedback collection loop (in-app feedback form + categorization + roadmap review input) <!--gh:issue=130-->
- [ ] Launch mobile MVP after Web validation (M17; Web launch tracked by M32) <!--gh:issue=131-->
- [ ] Add Logo quiz category (Deferred: blocked by logo asset dataset + answer metadata map) <!--gh:issue=132-->

## Test Scaffolding

- [x] Manual testing agent that generates unit/widget test scaffolds under `test/` <!--gh:issue=133-->
- [x] Manual testing agent that generates integration scaffolds under `integration_test/` <!--gh:issue=134-->
- [x] Manual testing agent that generates Playwright smoke + per-screen e2e scaffolds under `playwright/` <!--gh:issue=135-->
- [x] Unit test coverage command/script (`flutter test test/unit --coverage`, `tools/run_unit_coverage.sh`) <!--gh:issue=136-->

## Screens

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

- **Unit/Widget tests:** `40` files
- **Integration tests:** `7` files

```bash
flutter test
flutter test test/unit --coverage
./tools/run_unit_coverage.sh   # optional helper
flutter test integration_test   # if present
cd playwright && npx playwright test   # if present
```

## Dependencies (summary)

- **deps:** flutter, sdk, firebase_core, firebase_auth, cloud_firestore, cloud_functions, firebase_crashlytics, firebase_analytics, shared_preferences, package_info_plus, firebase_ui_auth, git…
- **dev_deps:** flutter_test, sdk, integration_test, sdk, flutter_lints, flutter_launcher_icons, flutter_native_splash

## Roadmap

# ROADMAP

Use this as a short, editable delivery plan.

## Current priorities — September 26, 2026

The September 16 Notion decision makes the EIRENYA Web MVP the first delivery
channel. Mobile stores follow product validation. Implemented app flows still
require production Web verification. Historical target dates are not new commitments.

| Priority | Milestones | Next outcome |
| --- | --- | --- |
| P0 | M32 | Production Web Firebase/OAuth, Web-safe crash reporting, release/browser QA and EIRENYA Web launch. |
| P1 | M20 | Review public leaderboard abuse exposure; decide backend billing/deployment and enforce authoritative writes. |
| P1 | M27, M28 | Web analytics/rollback checks and feedback collection; dashboard/paging automation can follow launch. |
| P2 | M12, M16, M29, M30 | Final visual QA, targeted UX polish, category configuration and resilience hardening. |
| P2 | M10, M17 | Mobile signing/store readiness and Apple setup after Web validation. |
| P2 | M6–M9, M15, M18, M23–M25, M31, M33 | Growth backlog; Web ads only after stable launch and measured traffic. |

## Milestones

- [x] M1: Stabilize entry auth flow (dedicated entry-choice screen, provider login on second step, no startup auto-guest auth). <!--gh:issue=15-->
- [x] M1: Implement local-first score repository (persist locally first for guest and signed-in users). <!--gh:issue=16-->
- [x] M1: Add pending score sync queue with retry for Firestore/network failures. <!--gh:issue=17-->
- [x] M1: Sync pending local scores on reconnect and on account-link/sign-in. <!--gh:issue=18-->
- [x] M1: Add connectivity-aware retry backoff with forced retry bypass on explicit sync triggers. <!--gh:issue=19-->
- [x] M1: Fix login setup issues (logo asset path and Google OAuth client ID via config). <!--gh:issue=20-->
- [x] M2: Clarify leaderboard semantics (best score per user per `category+difficulty`, tie-breakers by `score desc`, `updatedAt asc`, `uid asc`). <!--gh:issue=21-->
- [x] M2: Define anonymous leaderboard policy (included in global leaderboard and explicitly tagged). <!--gh:issue=22-->
- [x] M2: Implement leaderboard band service (`top 10/20/100` + outside) for conversion UX. <!--gh:issue=23-->
- [x] M2: Add guest conversion messaging from leaderboard bands (e.g., top 10/20/100) on results. <!--gh:issue=24-->
- [x] M2: Extend "Create account to compete globally" CTA to guest profile surface. <!--gh:issue=25-->
- [x] M2: Add guest CTA action flow to `/upgrade` from results/profile and preserve post-upgrade continuity. <!--gh:issue=26-->
- [x] M2: Upgrade screen performs anonymous-account linking (Email/Google/Apple) with guest UID continuity checks. <!--gh:issue=27-->
- [x] M2: Harden profile display (difficulty labels, ordering, empty/error states). <!--gh:issue=28-->
- [x] M2: Apply `AuthGuard` strategy consistently to protected routes. <!--gh:issue=29-->
- [x] M2: Replace deprecated result-screen back handling (`WillPopScope`) with `PopScope` and cover it with widget tests. <!--gh:issue=30-->
- [x] M3: Implement a second quiz category (Capitals) using current category-key pattern. <!--gh:issue=31-->
- [x] M3: Enable quiz-type switching in navigation/results flow. <!--gh:issue=32-->
- [x] M3: Expose anonymous-to-account upgrade in primary home UX flow. <!--gh:issue=33-->
- [x] M4: Replace template widget test with app-specific flow tests in `test/unit` and `test/widget`. <!--gh:issue=34-->
- [x] M4: Add non-scaffold integration assertions in `integration_test`. <!--gh:issue=35-->
- [x] M4: Add Playwright e2e assertions in `playwright/tests`. <!--gh:issue=36-->
- [x] M4: Auto-generate Playwright smoke + per-screen e2e scaffolds as screens are added. <!--gh:issue=37-->
- [x] M4: Regenerate README from docs (`FEATURES`, `ROADMAP`, `ARCHITECTURE`). <!--gh:issue=38-->
- [x] M5: Bump macOS deployment target to 10.15+ so FlutterFire integration tests can run on macOS. <!--gh:issue=39-->
- [ ] M6: Add Logo quiz category (deferred until curated/licensed logo asset set + mapping metadata are available). <!--gh:issue=40-->
- [ ] M7: Add Guess the Celebrity quiz category (deferred outside MVP scope; content set + quiz loader + tests). <!--gh:issue=41-->
- [ ] M8: Add Guess the Song from Lyrics quiz category (deferred outside MVP scope; licensed lyric snippets + answer metadata + tests). <!--gh:issue=42-->
- [ ] M9: Add Guess the Anime quiz category (content set + quiz loader + tests). <!--gh:issue=43-->
- [ ] M10: Ship Apple sign-in as a production-ready provider across supported platforms. <!--gh:issue=44-->
  - [x] App-side provider gating + rollback flag shipped (`ENABLE_APPLE_SIGN_IN`, default `false`).
  - [x] iOS/macOS entitlement baseline committed for Sign in with Apple capability.
  - [x] Login/upgrade auth failures now map to user-safe provider messages.
  - [ ] Apple Developer + Firebase provider credentials/configuration per environment still pending.
  - Manual pre-deployment checklist (required before enabling flag):
    - [ ] Enable `Sign in with Apple` capability on Apple App ID(s).
    - [ ] Create Apple sign-in key (`.p8`) and capture Team ID + Key ID.
    - [ ] Create/configure Apple Service ID and callback URL (`https://<project-id>.firebaseapp.com/__/auth/handler`).
    - [ ] Configure Firebase Auth Apple provider with Service ID/Team ID/Key ID/private key.
    - [ ] Run iOS + macOS login/upgrade smoke tests with `ENABLE_APPLE_SIGN_IN=true`.
  - Activation runbook: `docs/APPLE_SIGN_IN_SETUP.md`
- [x] M11: Implement global leaderboard experience (data query strategy + screen design + filters). <!--gh:issue=45-->
- [ ] M12: Add branded app icons and splash screens for all target platforms. <!--gh:issue=46-->
  - [x] Baseline asset pipeline configured (`flutter_launcher_icons`, `flutter_native_splash`, and `tools/refresh_branding_assets.sh`).
  - [x] Brand color tokens centralized in `lib/config/brand_config.dart`.
  - [x] Apply EIRENYA color scheme consistently across logo, banners, backgrounds, and buttons.
  - [x] Update support-contact email references to the current QuizNetic inbox across app UI and legal docs.
  - [ ] Final artwork export + multi-platform visual QA pending.
  - Activation/update runbook: `docs/BRANDING_ASSETS.md`
- [x] M13: Build Settings and About screens. <!--gh:issue=47-->
  - Includes account/session controls, sign-out flow, legal links, and app metadata/support surface.
- [x] M14: Add analytics and crash reporting instrumentation. <!--gh:issue=48-->
  - [x] Crash reporting baseline shipped (Firebase Crashlytics init + Flutter/zone unhandled error capture).
  - [x] Crash reporting kill switch added: `ENABLE_CRASH_REPORTING` (default `true`).
  - [x] Analytics event breadcrumbs shipped for crash triage (screen views + critical flow actions).
  - [x] Product analytics baseline shipped for auth, quiz, and score-submission funnels.
  - [x] Analytics kill switch added: `ENABLE_ANALYTICS` (default `true`).
- [ ] M15: Reintroduce mobile monetization stack (ads + in-app purchases) after Web validation. (**POST-MVP DEFERRED** — prior runtime integration was removed in M30.) <!--gh:issue=49-->
  - Priority: P2. Not a Web MVP launch gate; Web advertising belongs to M33.
  - [x] Previous implementation and activation guidance documented in docs/MONETIZATION_SETUP.md; this is historical work.
  - [ ] Reimplement mobile ads/IAP services, SDK dependencies, placements and consent when activated.
  - [ ] Complete provider/store setup, release ad validation, purchase/restore QA and physical-device checks.
- [ ] M16: Improve UI/UX polish (animations, progress indicators, feedback styling). <!--gh:issue=50-->
- [ ] M17: Launch mobile MVP (Play Store first; TestFlight when financially viable). <!--gh:issue=51-->
  - Priority: P2. Follows M32 Web validation.
  - [x] Launch preflight automation shipped (`tools/release_preflight.sh` + `.github/workflows/release_preflight.yml`).
  - [x] Manual launch test checklist published: `docs/MVP_LAUNCH_TEST_CHECKLIST.md`.
  - [x] Bug tracking split out from roadmap into dedicated issue log: `docs/ISSUES.md`.
  - [ ] Close all open MVP blockers in `docs/ISSUES.md` before public launch.
  - If Apple setup is not complete by launch date, keep `ENABLE_APPLE_SIGN_IN=false` for MVP and ship with Email/Google.
- [ ] M18: Build content licensing + attribution pipeline for celebrity/song/anime datasets. <!--gh:issue=52-->
- [x] M19: Harden Firestore security rules and add automated Firestore-rules tests in CI. <!--gh:issue=53-->
- [ ] M20: Add leaderboard integrity protections (anti-cheat scoring checks, abuse controls, rate limits). <!--gh:issue=54-->
  - Contract reference: docs/ANTI_CHEAT_CONTRACT.md
  - [x] Phase 1 baseline shipped: validator, idempotent attempt records, stricter Firestore score bounds/scope checks.
  - [ ] Phase 2 pending: backend-authoritative submitScore path + direct projection write lock for clients.
  - Blaze-gated partial implementation shipped: callable `submitScore` + app flag (`ENABLE_BACKEND_SUBMIT_SCORE`) default-off on Spark.
  - `cleanupOnUserDeleted` Cloud Function written and ready — recursively deletes `users/{uid}` Firestore data when any Auth account is deleted (covers anonymous sign-out and future account-deletion flows).
  - **TODO before/at launch:** Upgrade project `quiznetic-30734` to Blaze plan, then `cd functions && firebase deploy --only functions` to activate both functions.
  - Activation/rollback conditions: docs/BLAZE_FEATURE_FLAGS.md
- [x] M21: Enforce CI/CD quality gates (GitHub Actions + branch protection required checks are active on `main`). <!--gh:issue=55-->
- [x] M22: Complete privacy/legal baseline (Privacy Policy, Terms, consent copy, and in-app legal links). <!--gh:issue=56-->
  - Formal legal counsel review and age-rating metadata can be finalized before public store launch.
- [ ] M23: Introduce Remote Config/feature flags for staged feature rollout. <!--gh:issue=57-->
- [ ] M24: Implement localization foundation (externalized strings, locale resolution, default i18n coverage). <!--gh:issue=58-->
- [ ] M25: Add user-selectable app language in Settings with persisted preference and safe fallback. <!--gh:issue=59-->
- [x] M26: Complete accessibility baseline (semantics labels, contrast, dynamic type/text scaling). <!--gh:issue=60-->
  - Added semantic labels for core logo/question imagery surfaces.
  - Added WCAG AA contrast unit checks for primary theme color pairs.
  - Added large text-scaling widget coverage for entry, settings, about, difficulty, home, quiz, result, leaderboard, and profile flows.
  - Added non-color quiz answer feedback (icon + text states) and live semantic announcements for quiz progress/result summary.
  - Added opt-in flag-description accessibility support (`Settings > Accessibility > Show flag descriptions` + in-quiz `Describe Flag` affordance backed by metadata).
  - Expanded flag-description metadata baseline to `263` entries (`100%` current asset coverage) with unit QA guardrails for metadata quality + coverage floor (`>=70%`).
  - Replaced all seeded placeholder templates with curated per-flag structural descriptions (`0` generic seed-template entries remaining).
  - [ ] Manual visual QA sweep for flag-description accuracy (owner: user).
  - [ ] MVP+1 accessibility enhancements tracked in `docs/ISSUES.md` (for example `ISS-005` audio description mode).
  - Follow-up audit and prioritized backlog: `docs/ACCESSIBILITY_AUDIT.md`.
- [ ] M27: Establish release operations readiness (alerts, KPI dashboard, rollback playbook, beta process). <!--gh:issue=61-->
  - [x] Baseline release ops runbook published: `docs/RELEASE_OPS_RUNBOOK.md`.
  - [x] Rollback playbook and kill-switch checklist documented.
  - [x] Alert routing policy + KPI thresholds documented: `docs/ALERT_ROUTING_AND_KPI_THRESHOLDS.md`.
  - [x] CI failure alert routing automation shipped (webhook via `ALERT_WEBHOOK_URL`).
  - [x] Incident postmortem template + review cadence documented: `docs/INCIDENT_POSTMORTEM_TEMPLATE.md`.
  - [ ] Dedicated pager/on-call automation and KPI dashboard automation still pending.
- [ ] M28: Build feedback intelligence loop (in-app feedback capture, tagged triage, and recurring roadmap review cadence). <!--gh:issue=62-->
- [ ] M29: Centralize quiz category definitions under a single source of truth (JSON-first) with generated enforcement artifacts. <!--gh:issue=156-->
  - Canonical config file: `config/categories.json` (category keys, labels, enabled state, and difficulty/question-count constraints).
  - Generate/sync category allowlists for app validator, Cloud Functions `submitScore`, and Firestore rules from the canonical config.
  - Add CI drift guard so builds fail when generated artifacts are out of sync with `config/categories.json`.
- [ ] M30: Pre-MVP Architecture Fixes & Cleanup (MVP-blocking dependency removal + query performance + routing fixes). <!--gh:issue=157-->
  - [x] Remove ads monetization from MVP scope (merged through PR #153).
    - [x] Delete ads service files (`AdsService`, `AdConsentService`, `AdOverlayRecoveryService`, `HintMonetizationService`).
    - [x] Delete ads UI widgets (`MonetizedBannerAd`).
    - [x] Remove ads feature flags from `AppConfig` and native platform metadata.
    - [x] Clean up screens: remove ad placements from `HomeScreen`, `QuizScreen`, `ResultScreen`.
    - [x] Remove unused dependencies: `google_mobile_ads`, `in_app_purchase` from `pubspec.yaml`.
    - [x] Remove orphaned `ConsentService` (only used for ads UMP flow, no longer needed).
    - [x] Remove IAP/entitlement services and initialization together with SDK dependencies.
  - [x] Fix `UpgradeAccountScreen` route misconfiguration: should navigate to `UpgradeAccountScreen()` not `HomeScreen()` (line `lib/main.dart:117`).
  - [x] Validate and fix quiz screen route arguments: safe `is!` type-check in `didChangeDependencies`; recoverable error screen shown instead of crash when args are missing.
  - [x] Add Firestore query timeouts (10s) to prevent indefinite UI hangs:
    - [x] Leaderboard queries in `leaderboard_service.dart` (primary + fallback).
    - [x] Score queries in `score_service.dart` (`getHighScore`, `getAllHighScores`, `runTransaction`).
  - [x] Centralize app version management: `BrandConfig.initVersion()` reads from `package_info_plus` at startup; `pubspec.yaml` is now the single source of truth.
  - [x] Audit and document 88 `debugPrint` statements: replaced all call sites with `AppLogger` (`lib/utils/app_logger.dart`) guarded by `kDebugMode` — zero log output in release builds.
  - [ ] Add error handling enhancements:
    - [ ] Generic error messages → specific types (network, auth, notfound) with user-safe retry CTAs.
    - [x] Leaderboard error state: add retry mechanism (widget-test coverage).
    - [ ] Leaderboard error state: add offline cache display.
    - [ ] Quiz screen accessibility preferences: distinguish network vs. storage errors with fallback.
  - Test coverage additions (integration tests):
    - [ ] Firestore connection loss scenario (app resilience when DB unavailable).
    - [ ] Network timeout handling with actual timeout triggers.
    - [x] IAP disable-path validation superseded by full service removal; reactivation QA belongs to M15.
- [ ] M31: Add notification capabilities (**POST-MVP**). <!--gh:issue=158-->
  - [ ] Add push notifications.
  - [ ] Add email notifications for account creation and account confirmation.
- [ ] M32: Launch QuizNetic Web MVP on the EIRENYA domain. <!--gh:issue=159-->
  - Priority: P0. In progress in Notion; production rollout remains unverified.
  - [x] App baseline: Flags, Capitals, guest/account flows, scores, leaderboard, profile and settings implemented with automated coverage.
  - [ ] Choose public URL and matching `--base-href`.
  - [ ] Configure production `FIREBASE_WEB_*` and authorize EIRENYA domains in Firebase Auth/Google OAuth.
  - [ ] Guard unsupported Crashlytics operations on Web, including initialization and error capture.
  - [ ] Validate release build, responsive layouts, browser back/refresh/direct routes and Email/Google sign-in.
  - [ ] Verify deployed Firestore rules and leaderboard exposure (M20).
  - [ ] Verify Web analytics and current privacy/legal copy for the ad-free build.
  - [ ] Deploy an unannounced preview and smoke-test both categories, score persistence and leaderboard.
  - [ ] Publish Web MVP and collect initial feedback.
  - Notion: https://www.notion.so/3dd722c1b5b281eebc88de3b70635cfa
- [ ] M33: Validate Web advertising after establishing a real traffic baseline. <!--gh:issue=160-->
  - Priority: P2. Depends on M32 public/stable and measured traffic/retention.
  - [ ] Choose Web advertising provider and validate domain eligibility.
  - [ ] Review Web privacy/consent requirements and automated-traffic protections.
  - [ ] Test placements, responsive behavior, performance and quiz completion impact.
  - [ ] Measure revenue and retention before deciding whether to keep ads.
  - Notion: https://www.notion.so/3dd722c1b5b281fbbdedcd07fb82d126


---

_This README is generated by `tools/readme_agent.py`. Edit `docs/FEATURES.md` and `docs/ROADMAP.md` for human-written content._
