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
- [ ] M2: Harden profile display (difficulty labels, ordering, empty/error states).
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
