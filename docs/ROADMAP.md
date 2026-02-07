# ROADMAP

Use this as a short, editable delivery plan.

- [x] M1: Stabilize entry auth flow (implemented explicit login/guest choice; no startup auto-guest auth).
- [ ] M1: Make Firestore the single high-score source and remove local score divergence.
- [ ] M1: Fix login setup issues (logo asset path and Google OAuth client ID).
- [ ] M2: Clarify leaderboard semantics (best score vs latest score per user).
- [ ] M2: Harden profile display (difficulty labels, ordering, empty/error states).
- [x] M2: Apply `AuthGuard` strategy consistently to protected routes.
- [ ] M3: Implement a second quiz category (Logo or Capitals) using current category-key pattern.
- [ ] M3: Enable quiz-type switching in navigation/results flow.
- [ ] M4: Replace template widget test with app-specific flow tests in `test/unit` and `test/widget`.
- [ ] M4: Add non-scaffold integration assertions in `integration_test`.
- [ ] M4: Add Playwright e2e assertions in `playwright/tests`.
- [x] M4: Regenerate README from docs (`FEATURES`, `ROADMAP`, `ARCHITECTURE`).
