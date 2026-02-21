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
- [x] Optional `Describe Flag` accessibility affordance (opt-in via Settings)
- [x] Flag-description metadata quality gate (unit checks for description format + minimum asset coverage)
- [x] Curated flag-description coverage for all bundled flag assets (`263/263`)
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
- [x] Firestore rules enforce monotonic best-score updates, scope/doc-id consistency, and server-managed projection/attempt timestamps (`updatedAt`, `createdAt`)
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
  - [x] Runtime provider gating + rollback flag (`ENABLE_APPLE_SIGN_IN`, default `false`)
  - [x] iOS/macOS entitlement baseline committed for Sign in with Apple
  - [ ] Apple Developer + Firebase provider credentials/setup still required per environment
- [x] Implement a global leaderboard screen (with UX/design, category+difficulty filters, and ranking presentation)
- [ ] Create branded app icons for all target platforms
- [ ] Create branded splash screens for all target platforms
- [x] Configure branding asset pipeline (launcher icons + native splash generation runbook)
- [x] Create a Settings screen
- [x] Create an About screen
- [x] Add product analytics instrumentation (baseline auth + quiz + score funnel events)
- [x] Add analytics event breadcrumbs for crash triage (screen views + critical actions)
- [x] Add crash reporting (Crashlytics baseline with compile-time kill switch)
- [x] Integrate monetization baseline via ads
  - [x] Banner ad placements on home and result screens
  - [x] Placement-aware ad-unit mapping (Android+iOS home/result ids, with shared fallback ids)
  - [x] Runtime gating via `ENABLE_ADS` plus entitlement check (`remove_ads`)
  - [x] Non-release compliance guard blocks live `ca-app-pub-*` units unless explicitly allowed (`ALLOW_LIVE_AD_UNITS_IN_DEBUG=true`)
  - [x] Result-screen hybrid ad strategy behind dedicated flag (`ENABLE_RESULT_INTERSTITIAL_ADS`, default `false`): interstitial-first with banner fallback on failure
  - [x] Native AdMob app-id baseline configured (`com.google.android.gms.ads.APPLICATION_ID` / `GADApplicationIdentifier`)
- [x] Integrate monetization baseline via in-app purchases (IAP)
  - [x] Runtime gating via `ENABLE_IAP` (default `false`)
  - [x] Lifetime `Remove Ads` catalog + purchase/restore plumbing
  - [x] Persisted entitlement state (`entitlement_remove_ads`) to suppress ads post-purchase
  - [x] Hint monetization baseline in quiz flow (rewarded remove-2-wrong + paid fallback after session cap)
  - [x] Hint feature flags and defaults: `ENABLE_REWARDED_HINTS=false`, `ENABLE_PAID_HINTS=false`, `REWARDED_HINTS_PER_SESSION=3`
  - [ ] Store-side product/ad unit setup and sandbox QA still required before rollout
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
