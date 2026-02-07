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
