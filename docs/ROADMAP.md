# ROADMAP

Use this as a short, editable delivery plan.

## Current priorities — September 26, 2026

The September 16 Notion decision makes the EIRENYA Web MVP the first delivery
channel. Mobile stores follow product validation. Implemented app flows still
require production Web verification. Historical target dates are not new commitments.

| Priority | Milestones | Next outcome |
| --- | --- | --- |
| P0 | M32 | Production Web Firebase/OAuth, Web-safe crash reporting, release/browser QA and EIRENYA Web launch. |
| P1 | M20 | Harden scoring rules on Spark; authoritative scoring and any billing upgrade are deferred. |
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
  - Priority: P1 for Spark rule hardening; backend migration deferred pending an explicit budget decision.
  - Contract references: docs/ANTI_CHEAT_CONTRACT.md and docs/SPARK_SECURITY.md.
  - [x] Phase 1 baseline shipped: validator, idempotent attempt records, Firestore ownership/bounds/scope checks.
  - [x] Production audit: deployed rules matched main; billing disabled; App Check unenforced.
  - [x] PR #163 merged; Spark hardening deployed and exact rules match verified on September 26: field allowlists, auth-derived source, account-only leaderboard publication, personal-score consistency and queries capped at 100.
  - [x] Live guest/account score writes and upgrade verified after deployment: UID and guest score preserved, account attempt saved and matching leaderboard entry displayed; test account/data removed.
  - [ ] Spark follow-up: initialize Web App Check, monitor compatibility, then consider enforcement (not an anti-cheat guarantee).
  - [ ] Deferred: authoritative backend scoring, enforced rate limits, direct-write lock and automated account-data cleanup (GitHub #122, P2 / Deferred).
  - Keep ENABLE_BACKEND_SUBMIT_SCORE=false. No Blaze upgrade is required for Web launch.
  - Staged submitScore is not activation-ready: fix reads after writes, rate-limit concurrency, flagged-score projection and client-trusted correct counts before any migration.
  - Client-supplied bounded scores remain forgeable on Spark; retain this limitation explicitly.
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
  - Priority: P0. Deployed on quiznetic.eirenya.com; analytics/legal checks, browser matrix and initial feedback remain.
  - [x] App baseline: Flags, Capitals, guest/account flows, scores, leaderboard, profile and settings implemented with automated coverage.
  - [x] Public URL: quiznetic.eirenya.com with root base href; quiznetic.eirenya.fr redirects with HTTP 308.
  - [x] Configure production Firebase Web app and authorize quiznetic.eirenya.com; owner validated Email/Google login and password reset.
  - [x] Guard unsupported Crashlytics operations on Web, including initialization, error capture and Analytics breadcrumbs (PR #162 merged and deployed).
  - [x] Release build and core browser flows validated; owner tested categories, login, scores, leaderboard and mobile flows. Guest upgrade preserves UID and score after refresh/sign-in.
  - [x] Audit deployed Firestore rules and leaderboard exposure (M20); record Spark limitations.
  - [x] Merge/deploy Spark hardening and recheck live score flows (M20, PR #163).
  - [x] Analytics enabled; live SDK queue contains quiz_started, quiz_completed and score_submit_success with Google Analytics collection requests. Dashboard receipt remains unverified.
  - [ ] Complete browser/responsive matrix; refreshing /#/leaderboard currently returns Home rather than restoring the route.
  - [ ] Verify Web analytics and current privacy/legal copy for the ad-free build.
  - [x] Deploy production build from merge 81df9ce and smoke-test categories, persistence, leaderboard and guest upgrade.
  - [x] Publish Web MVP on the EIRENYA domain.
  - [ ] Collect initial feedback (M28); analytics/legal checks remain open.
  - Notion: https://www.notion.so/3dd722c1b5b281eebc88de3b70635cfa
- [ ] M33: Validate Web advertising after establishing a real traffic baseline. <!--gh:issue=160-->
  - Priority: P2. Depends on M32 public/stable and measured traffic/retention.
  - [ ] Choose Web advertising provider and validate domain eligibility.
  - [ ] Review Web privacy/consent requirements and automated-traffic protections.
  - [ ] Test placements, responsive behavior, performance and quiz completion impact.
  - [ ] Measure revenue and retention before deciding whether to keep ads.
  - Notion: https://www.notion.so/3dd722c1b5b281fbbdedcd07fb82d126
