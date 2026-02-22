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
- [x] Integrate monetization baseline via ads <!--gh:issue=117-->
  - [x] Banner ad placements on home and result screens
  - [x] Placement-aware ad-unit mapping (Android+iOS home/result ids, with shared fallback ids)
  - [x] Runtime gating via `ENABLE_ADS` plus entitlement check (`remove_ads`)
  - [x] Non-release compliance guard blocks live `ca-app-pub-*` units unless explicitly allowed (`ALLOW_LIVE_AD_UNITS_IN_DEBUG=true`)
  - [x] Result-screen hybrid ad strategy behind dedicated flag (`ENABLE_RESULT_INTERSTITIAL_ADS`, default `false`): interstitial-first with banner fallback on failure
  - [x] Native AdMob app-id baseline configured (`com.google.android.gms.ads.APPLICATION_ID` / `GADApplicationIdentifier`)
- [x] Integrate monetization baseline via in-app purchases (IAP) <!--gh:issue=118-->
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
- [ ] Launch MVP <!--gh:issue=131-->
- [ ] Add Logo quiz category (Deferred: blocked by logo asset dataset + answer metadata map) <!--gh:issue=132-->

## Test Scaffolding

- [x] Manual testing agent that generates unit/widget test scaffolds under `test/` <!--gh:issue=133-->
- [x] Manual testing agent that generates integration scaffolds under `integration_test/` <!--gh:issue=134-->
- [x] Manual testing agent that generates Playwright smoke + per-screen e2e scaffolds under `playwright/` <!--gh:issue=135-->
- [x] Unit test coverage command/script (`flutter test test/unit --coverage`, `tools/run_unit_coverage.sh`) <!--gh:issue=136-->
