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
- [x] Firestore rules enforce monotonic best-score updates and scope/doc-id consistency
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
- [ ] Add crash reporting
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
- [ ] Add user feedback collection loop (in-app feedback form + categorization + roadmap review input)
- [ ] Launch MVP
- [ ] Add Logo quiz category (Deferred: blocked by logo asset dataset + answer metadata map)

## Test Scaffolding

- [x] Manual testing agent that generates unit/widget test scaffolds under `test/`
- [x] Manual testing agent that generates integration scaffolds under `integration_test/`
- [x] Manual testing agent that generates Playwright smoke + per-screen e2e scaffolds under `playwright/`
- [x] Unit test coverage command/script (`flutter test test/unit --coverage`, `tools/run_unit_coverage.sh`)
