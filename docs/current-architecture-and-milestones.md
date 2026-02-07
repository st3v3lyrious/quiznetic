# Quiznetic: Current Architecture and Immediate Milestones

Last updated: 2026-02-07

## Purpose

This document captures:
- What Quiznetic appears to be building.
- What is currently implemented in the codebase.
- Gaps and inconsistencies that should be resolved next.
- A practical milestone plan to move from current state to a stable v1.

## Product Direction (Inferred From Current Code)

Quiznetic is a mobile-first trivia app with:
- A guest-first onboarding model so users can start immediately.
- Expandable quiz categories (currently flags, later logo/capitals).
- Difficulty levels per category.
- Personal best score tracking and global leaderboards.
- An eventual path for anonymous users to upgrade to full accounts.

## Current Implementation Map

## 1) App Boot and Routing

Primary entry point:
- `lib/main.dart`

Current behavior:
- Initializes Firebase.
- Attempts anonymous sign-in at startup when no user exists.
- Registers named routes for splash, home, difficulty, quiz, results, profile, and login.

Primary route flow in code:
- `SplashScreen` -> `HomeScreen` (if auth user exists) or `LoginScreen`

Notes:
- Because anonymous sign-in is attempted in `main.dart`, most cold starts will already have a user by the time splash routing runs.

## 2) Authentication Model

Files:
- `lib/services/auth_service.dart`
- `lib/services/user_checker.dart`
- `lib/screens/login_screen.dart`
- `lib/widgets/auth_guard.dart`
- `lib/screens/upgrade_account_screen.dart`

Implemented:
- Anonymous sign-in via `AuthService.signInAnonymously()`.
- Firestore user doc creation for anonymous users (`users/{uid}`).
- Login UI scaffolded with Firebase UI Auth providers:
  - Email
  - Google OAuth
  - Apple
- Upgrade account screen exists for converting anonymous users.

Current caveats:
- Google provider uses placeholder client ID.
- `AuthGuard` is implemented but not broadly used as a route-level protection pattern yet.

## 3) Quiz Domain (Flags)

Files:
- `lib/screens/home_screen.dart`
- `lib/screens/difficulty_screen.dart`
- `lib/screens/quiz_screen.dart`
- `lib/data/flag_loader.dart`
- `lib/models/flag_question.dart`

Implemented:
- Category selector screen with only `flag` active.
- Difficulty presets:
  - easy: 15
  - intermediate: 30
  - expert: 50
- Runtime flag question generation from `assets/flags/` using `AssetManifest.json`.
- Four-option multiple choice question generation with randomized distractors.
- Quiz progress indicator and score tracking during a session.

Notes:
- The architecture is already category-key based (`categoryKey`) so additional quiz types can reuse the same flow.

## 4) Score and Profile Persistence

Files:
- `lib/services/score_service.dart`
- `lib/services/user_profile.dart`
- `lib/screens/result_screen.dart`
- `lib/screens/user_profile_screen.dart`
- `README.md` (Firestore schema note)

Implemented:
- On quiz completion, score is written to:
  - User best score doc: `users/{uid}/scores/{category_difficulty}`
  - Global leaderboard entry: `leaderboard/{category_difficulty}/entries/{uid}`
- Profile screen reads all current-user score docs and displays one card per category+difficulty.

Current caveat:
- Two high score systems are active:
  - Firestore-based high scores (`ScoreService`)
  - Local `SharedPreferences` high scores (`UserProfile`)
- Result screen currently reads/updates local high score while also writing Firestore score data, which can produce inconsistent "new high score" messaging.

## 5) UI/Asset Status

Implemented:
- App branding assets included in `assets/images/`.
- Large flag image set in `assets/flags/`.

Known issue:
- `LoginScreen` references `assets/images/logo.png`, but current image set appears to use `logo-no-background.*`, `logo-color.*`, etc.

## Current End-to-End User Journey

1. App launch initializes Firebase and signs in anonymously if needed.
2. Splash screen checks auth user presence.
3. Home screen allows selecting quiz category (only Flag Quiz enabled).
4. Difficulty screen chooses session size.
5. Quiz screen runs the session and computes score.
6. Result screen:
   - saves score to Firestore best + leaderboard
   - displays score and high score messaging
7. Profile screen shows historical best scores by category+difficulty.

## Gaps and Risks to Address

Priority 1:
- Unify high score source of truth (Firestore vs local `SharedPreferences`).
- Resolve startup auth flow conflict (auto-anon in `main.dart` vs explicit login-first flow).
- Fix login header asset path (`logo.png` mismatch).
- Configure real Google OAuth client ID.

Priority 2:
- Decide whether leaderboards should store only best score per user or latest score.
- Enforce route-level auth guard strategy consistently.
- Improve difficulty label formatting in profile (currently first-letter capitalization only).

Priority 3:
- Implement additional categories (logo/capital) using existing category-key architecture.
- Add dedicated quiz type selection from result screen when multiple categories are ready.

## Immediate Milestone Plan

## Milestone 1: Data Consistency and Auth Flow Baseline

Goal:
- Make score and auth behavior deterministic and easy to reason about.

Scope:
- Remove or deprecate local high score writes/reads in result flow.
- Use Firestore score state as the single source of truth.
- Finalize one startup auth strategy:
  - Option A: true guest-first auto anonymous sign-in
  - Option B: explicit login/guest choice at entry
- Fix login logo asset reference.

Acceptance criteria:
- Same score and high score values appear on result and profile consistently.
- Cold start path always matches intended product behavior.
- Login screen renders correctly without missing asset errors.

## Milestone 2: Auth Provider Readiness

Goal:
- Make non-guest sign-in paths production-ready.

Scope:
- Configure Google OAuth client ID and verify sign-in on target platforms.
- Verify Apple sign-in flow where supported.
- Validate anonymous-to-credential account linking flow.

Acceptance criteria:
- Email/Google/Apple sign-in tested successfully on intended platforms.
- Anonymous user can upgrade account without losing existing score history.

## Milestone 3: Leaderboard and Profile Hardening

Goal:
- Ensure score surfaces are reliable and scalable.

Scope:
- Confirm leaderboard write semantics (best vs latest).
- Add optional sort/filter in profile (category, difficulty, highest first).
- Add graceful empty and error states across results/profile.

Acceptance criteria:
- Leaderboard semantics are documented and reflected in implementation.
- Profile renders stable output for empty, partial, and full user data.

## Milestone 4: Multi-Category Expansion

Goal:
- Move from single-quiz app to quiz platform.

Scope:
- Implement at least one additional category (logo or capitals).
- Reuse shared quiz/session infrastructure through `categoryKey`.
- Enable "Change Quiz Type" action in results once supported.

Acceptance criteria:
- Home shows multiple working categories.
- Each category supports difficulty and score persistence.

## Milestone 5: Quality and Release Readiness

Goal:
- Reduce regressions and prepare for broader usage.

Scope:
- Replace default template test in `test/widget_test.dart` with app-specific tests.
- Add critical flow tests:
  - app boot and routing
  - quiz session progression
  - score save and profile retrieval behavior
- Document Firebase security rules expectations for current collections.

Acceptance criteria:
- Core user journey is covered by automated tests.
- Firestore/Auth assumptions are documented and validated.

## Recommended Next Execution Order

1. Milestone 1 (consistency first).
2. Milestone 2 (auth provider readiness).
3. Milestone 3 (data and UX hardening).
4. Milestone 4 (feature expansion).
5. Milestone 5 (test and release hardening).

