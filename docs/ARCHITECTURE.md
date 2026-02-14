# ARCHITECTURE

This document describes the current implementation architecture of Quiznetic.
It is intended to be source material for generated docs (including `README.md`).

## System Summary

- Platform: Flutter app (Material 3 UI).
- Backend: Firebase Auth + Cloud Firestore.
- Local persistence: `SharedPreferences` (currently used for high-score logic; planned extension for local-first score queue/projections).
- Current product scope: Flag + Capital quizzes with category-key based expansion path.

## Tech Stack

- Flutter SDK / Dart (`sdk: ^3.8.1`)
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_ui_auth` + OAuth provider packages (from forked repo ref)
- `shared_preferences`
- `cloud_functions` (backend score-submission path behind feature flag)

## Codebase Layout

- `lib/main.dart`: app bootstrap, Firebase init, route registration, global theme.
- `lib/config/brand_config.dart`: app branding tokens (app name, core colors, web/splash color values).
- `test/unit/config/accessibility_contrast_test.dart`: WCAG AA contrast guardrails for core theme pairs.
- `test/widget/screens/accessibility_text_scaling_test.dart`: dynamic type baseline coverage for key screens.
- `lib/screens/*`: UI flows (splash, entry choice, login, legal docs, home, leaderboard, difficulty, quiz, results, profile, upgrade).
- `lib/services/*`: auth, user creation checks, score persistence/retrieval, leaderboard reads, local profile helper.
- `lib/data/*`: quiz content loaders (`flag_loader.dart`, `capital_loader.dart`) and sample data.
- `lib/models/*`: domain models (`FlagQuestion`).
- `lib/widgets/*`: shared UI wrappers (`AuthGuard`).
- `docs/BLAZE_FEATURE_FLAGS.md`: operational guidance for Blaze-dependent feature flags.
- `docs/BRANDING_ASSETS.md`: branding pipeline (icon/splash source assets + generation/QA workflow).

## Route Map

- `/splash` -> `SplashScreen`
- `/entry` -> `EntryChoiceScreen`
- `/login` -> `LoginScreen`
- `/legal/document` -> `LegalDocumentScreen` (opened from consent links on entry/login/upgrade flows)
- `/home` -> `HomeScreen`
- `/leaderboard` -> `LeaderboardScreen`
- `/difficulty` -> `DifficultyScreen`
- `/quiz` -> `QuizScreen`
- `/result` -> `ResultScreen`
- `/profile` -> `UserProfileScreen`
- `/settings` -> `SettingsScreen`
- `/about` -> `AboutScreen`
- `/upgrade` -> guarded route; anonymous users see upgrade screen, authenticated non-anonymous users are redirected to home.

## Runtime Flow (Current)

1. `main()` initializes Firebase.
2. App starts on splash route.
3. Splash checks auth state after delay and navigates to home (if user exists) or entry choice.
4. If there is no session, entry-choice screen presents explicit user choice:
   - Continue as guest
   - Sign in / create account
5. If user selects sign-in, app routes to provider login screen.
6. Entry, login, and upgrade flows present legal consent copy with in-app links to Terms and Privacy documents.
7. On explicit auth choice, app ensures `users/{uid}` exists in Firestore.
8. Auth-guarded routes only allow authenticated users (guest or signed-in) to access gameplay/profile screens.
9. Home currently exposes two categories: `flag` and `capital`, shows a primary guest conversion CTA that routes anonymous users to `/upgrade`, and provides entry into global leaderboard.
10. Difficulty selects question count and difficulty key.
11. Difficulty also offers explicit "Change Quiz Type" action back to home category selection.
12. Quiz loads assets, randomizes questions/options, tracks score.
13. Results screen saves score, renders session summary, blocks back navigation via `PopScope`, and offers explicit "Change Quiz Type" back to category selection.
14. Profile screen fetches stored user scores from Firestore and exposes quick links to settings/about.
15. Settings screen provides account controls, sign-out flow, legal links, and app preference toggles.
16. About screen provides app metadata/support contact and legal links.

## Quiz Engine

- Question assets are discovered dynamically from `AssetManifest.json` for `assets/flags/`.
- Each quiz question is currently represented as a `FlagQuestion` with:
  - `imagePath`
  - `correctAnswer`
  - `options`
- `prepareQuiz()` creates 4-choice options per question for the flag quiz:
  - 1 correct answer
  - 3 randomized distractors
- `loadAllCapitals()` builds capital questions from available flag assets + capital mapping, and `prepareCapitalQuiz()` creates options:
  - 1 correct answer
  - 3 randomized distractors
- Difficulty currently maps to fixed session sizes:
  - easy: 15
  - intermediate: 30
  - expert: 50

## Data Model

Firestore collections in use:

- `users/{uid}`
- `users/{uid}/scores/{category_difficulty}`
- `users/{uid}/attempts/{attemptId}`
- `leaderboard/{category_difficulty}/entries/{uid}`

Firestore config assets in repo:

- `firestore.rules` (auth + ownership rules for `users`, nested `scores`/`attempts`, and `leaderboard/entries`)
- `firestore.indexes.json` (composite index for leaderboard ranking query: `score desc`, `updatedAt asc`)
- `firebase.json` maps Firestore deploy targets to these files

Current score document fields:

- `categoryKey`
- `difficulty`
- `bestScore`
- `source` (`guest` or `account`)
- `updatedAt`

Current leaderboard entry fields:

- `categoryKey`
- `difficulty`
- `score`
- `isAnonymous`
- `displayName`
- `updatedAt`

Current score-attempt fields:

- `attemptId`
- `categoryKey`
- `difficulty`
- `correctCount`
- `totalQuestions`
- `status`
- `source` (`guest` or `account`)
- `createdAt`

Anonymous user doc fields (created by `UserChecker`):

- `isAnonymous`
- `createdAt`
- `lastSeen`
- `displayName`

## Auth Model

- App does not auto-create guest sessions at startup.
- A user is authenticated only after explicit action in login flow:
  - Entry choice: Guest button -> anonymous auth + user document creation
  - Entry choice: Sign-in button -> routes to provider login screen
  - Provider sign-in -> account auth + user document creation
- Route-level guard strategy:
  - `/home`, `/difficulty`, `/quiz`, `/result`, `/profile` are wrapped in `AuthGuard` (anonymous allowed).
  - `/upgrade` is wrapped so anonymous users can upgrade while unauthenticated users are sent to entry choice.
- `EntryChoiceScreen` provides:
  - Guest button (`Continue as Guest`)
  - Provider-login button (`Sign In / Create Account`)
- `LoginScreen` provides:
  - Email provider
  - Google provider (enabled when `GOOGLE_OAUTH_CLIENT_ID` is provided via `--dart-define`)
  - Apple provider
- `UpgradeAccountScreen` provides:
  - provider linking for Email/Google/Apple using FirebaseUI credential-link flows
  - guest UID continuity guard so upgraded account keeps the original guest identity
  - post-link best-effort pending-score sync
- `SettingsScreen` provides:
  - account/session details and sign-out action
  - legal deep links and basic gameplay preference toggles
- `AboutScreen` provides:
  - app version/support metadata
  - legal deep links (Terms and Privacy)
- `LegalDocumentScreen` provides:
  - in-app rendering for local Terms and Privacy text assets
  - a fallback state when route args are missing
- `LegalConsentNotice` widget provides:
  - shared consent copy and deep links used by entry, login, and upgrade surfaces
- `AuthGuard` supports:
  - unauthenticated -> entry choice
  - anonymous disallowed -> upgrade screen
  - allowed -> protected child

## Score Handling

Current implementation uses a local-first repository:

- `LocalFirstScoreRepository` (app-facing):
  - validates score payload bounds before queueing/sync
  - saves score attempts locally first
  - stores local best-score projections per `category+difficulty`
  - attempts immediate Firestore sync for pending records
  - applies connectivity-aware retry backoff (`nextRetryAt`) after failed sync attempts
  - can retry pending sync via `syncPendingScores()`, with optional `forceRetry` for explicit flush flows
- `ScoreSyncScope` (runtime trigger layer):
  - triggers forced sync on startup
  - triggers forced sync on app resume
  - runs periodic retry sync while app is active (non-forced, respects backoff schedule)
  - triggers forced sync when auth state changes to signed-in
- `AuthService` and login flow:
  - trigger best-effort pending sync after anonymous sign-in, provider sign-in, and account-link success
- `ScoreService` (remote adapter):
  - validates category/difficulty/question-count/score bounds before remote write
  - callable submit path (`submitScore`) is gated by `ENABLE_BACKEND_SUBMIT_SCORE` and defaults off on Spark
  - uses direct Firestore write path when backend flag is disabled
  - records idempotent score attempts (`users/{uid}/attempts/{attemptId}`)
  - saves personal best docs (`users/{uid}/scores/{category_difficulty}`)
  - writes leaderboard docs only when best score improves (one row per uid/category+difficulty)
  - tags leaderboard entries with anonymous status and display name
  - reads user high scores for profile/merge
- `LeaderboardService`:
  - loads ranked entries for one `category+difficulty` scope
  - applies deterministic ordering (`score desc`, `updatedAt asc`, `uid asc`)
  - returns ranked rows with current-user highlight metadata
- `LeaderboardBandService`:
  - computes rank bands (`top 10`, `top 20`, `top 100`, `outside top 100`)
  - uses deterministic tie-breakers for equal scores (`updatedAt`, then `uid`)
- `SharedPreferences` (local store):
  - persists pending score queue
  - persists local/synced score projections
- `UserProfileScreen` presentation rules:
  - renders full difficulty labels (`Easy`, `Intermediate`, `Expert`)
  - sorts profile scores deterministically by category then difficulty order
  - shows hardened empty/error states with in-place refresh/retry actions

## Score Architecture (Local-First + Sync)

### Repository Contract

- Introduce a single app-level API (`ScoreRepository`) used by UI (`ResultScreen`, profile, future leaderboard screens).
- `ScoreRepository` responsibilities:
  - Save score attempts locally first.
  - Expose best-score projections for immediate UI reads.
  - Sync pending records to Firestore (best score + leaderboard) when allowed.
  - Return sync/queue state for UI messaging.

### Local Data Model (v1)

- `score_attempts` local records (stored in local persistence):
  - `id` (uuid)
  - `uidAtRecord` (nullable)
  - `categoryKey`
  - `difficulty`
  - `score`
  - `totalQuestions`
  - `playedAt`
  - `syncState` (`pending`, `retry_wait`)
  - `syncAttempts`
  - `lastSyncError` (nullable)
  - `lastTriedAt` (nullable)
  - `nextRetryAt` (nullable; backoff schedule)
- `score_projection` local records:
  - key: `categoryKey + difficulty`
  - `bestScoreLocal`
  - `bestScoreSynced`
  - `updatedAt`

### Firestore Model (target)

- Keep:
  - `users/{uid}/scores/{category_difficulty}`
  - `users/{uid}/attempts/{attemptId}`
  - `leaderboard/{category_difficulty}/entries/{uid}`
- Add/standardize fields:
  - score docs: `bestScore`, `updatedAt`, `source` (`guest` or `account`)
  - attempt docs: `attemptId`, `correctCount`, `totalQuestions`, `status`, `source`, `createdAt`
  - leaderboard docs: `score`, `updatedAt`, `isAnonymous`, `displayName`

### Leaderboard Semantics (Current)

- Ranking scope is per `category+difficulty` document id (`leaderboard/{category_difficulty}/entries/{uid}`).
- Each user has one leaderboard row per scope (`uid` document id).
- Leaderboard value reflects personal best, not latest attempt.
- Tie-breakers:
  - higher `score` ranks first
  - if equal score, earlier `updatedAt` ranks first
  - if still tied, lexicographically smaller `uid` ranks first
- Anonymous policy:
  - anonymous users are included in leaderboard ranking
  - anonymous entries are explicitly tagged with `isAnonymous: true`

### Sync State Machine

- `pending` -> `syncing`
  - Trigger: score saved, app resume, reconnect, explicit retry, post-upgrade/account-link.
- `syncing` -> `synced`
  - Firestore write(s) succeed.
- `syncing` -> `retry_wait`
  - Network/server error; apply backoff and retry.
- `retry_wait` -> `syncing`
  - Backoff delay elapsed and trigger fires.

### Guest Conversion Messaging (Current)

- On results/profile, compute a leaderboard rank band (`top 10`, `top 20`, `top 100`, or `outside top band`) for the selected category+difficulty.
- For anonymous users, show conversion CTA:
  - “Create account to compete globally.”
  - CTA action routes to `/upgrade` to continue as an upgraded account.
  - Keep continuity by linking anonymous auth to permanent credentials.
- Anonymous leaderboard participation policy is now fixed to include + tag.
- Current rollout status:
  - home screen CTA implemented
  - result screen CTA implemented
  - profile screen CTA implemented
  - CTA action wiring to `/upgrade` implemented

### Implementation Tasks

1. [x] Add `ScoreRepository` interface and default implementation in `lib/services/`.
2. [x] Add local score-attempt/projection persistence layer.
3. [x] Refactor `ResultScreen` and profile reads to repository-only APIs.
4. [x] Add sync coordinator (lifecycle/auth/periodic triggers).
5. [x] Add account-link/sign-in sync trigger to flush pending guest attempts.
6. [x] Add leaderboard band service for top-band computation.
7. [x] Add conversion CTA UI surfaces in results/profile.
   - [x] result screen
   - [x] profile screen
8. [x] Add tests:
   - unit: repository logic, sync state transitions, retry policy
9. [x] Add tests:
   - integration: offline scoring and reconnect sync behavior
10. [x] Add tests:
   - widget: result/profile messaging and CTA visibility by auth state
11. [ ] Add tests:
   - e2e: offline scoring + guest-to-account continuity assertions

## Architectural Extension Points

- Category expansion is already modeled with `categoryKey` in navigation and persistence.
- New quiz types can reuse the same:
  - Home category model
  - Difficulty route args
  - Result + score persistence flow
- Additional loaders can mirror `flag_loader.dart` while keeping shared quiz/session UI patterns.

## Known Constraints / Cleanup Targets

- Google sign-in requires environment-specific `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...` in local/dev/CI builds.
- Backend-authoritative score submission requires
  `--dart-define=ENABLE_BACKEND_SUBMIT_SCORE=true` and Blaze prerequisites
  documented in `docs/BLAZE_FEATURE_FLAGS.md`.
- Logo quiz category is intentionally deferred until curated/licensed logo assets and answer metadata mapping are available.
- `main.dart` still contains template `MyHomePage` counter code that is not used by app routing.
- `firebase_options.dart` is configured for Android/iOS/Web; macOS/Linux/Windows throw unsupported errors unless configured.

## Test Structure

- `test/unit/`: unit test scaffolds generated by `tools/testing_agent.py`.
- `test/widget/`: widget test scaffolds generated by `tools/testing_agent.py`.
- `integration_test/`: Flutter integration tests, including:
  - scaffold smoke file (`app_smoke_integration_test.dart`)
  - category routing assertion for capital quiz (`category_capital_flow_integration_test.dart`)
  - home-to-leaderboard route assertion (`leaderboard_flow_integration_test.dart`)
  - guest conversion/upgrade route assertions (`guest_conversion_upgrade_integration_test.dart`)
  - result-screen quiz-type switch assertion (`quiz_type_switch_integration_test.dart`)
  - profile state recovery assertions (`user_profile_states_integration_test.dart`)
  - score sync reconnect assertions (`score_sync_reconnect_integration_test.dart`)
- `playwright/`: Playwright e2e configuration and specs generated by `tools/testing_agent.py` (smoke + per-screen scaffolds in `playwright/tests/screens/`, including leaderboard), with critical-flow assertions progressively replacing scaffolds.
- `firestore_tests/`: emulator-backed security-rules tests for Firestore authorization and data-shape enforcement.
- Unit coverage command:
  - `flutter test test/unit --coverage` (generates `coverage/lcov.info`)
  - optional helper script: `./tools/run_unit_coverage.sh` (also generates HTML output when `genhtml` is installed)
