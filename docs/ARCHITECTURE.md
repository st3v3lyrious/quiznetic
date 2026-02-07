# ARCHITECTURE

This document describes the current implementation architecture of Quiznetic.
It is intended to be source material for generated docs (including `README.md`).

## System Summary

- Platform: Flutter app (Material 3 UI).
- Backend: Firebase Auth + Cloud Firestore.
- Local persistence: `SharedPreferences` (currently used for legacy high-score logic).
- Current product scope: Flag quiz with category-key based expansion path.

## Tech Stack

- Flutter SDK / Dart (`sdk: ^3.8.1`)
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_ui_auth` + OAuth provider packages (from forked repo ref)
- `shared_preferences`

## Codebase Layout

- `lib/main.dart`: app bootstrap, Firebase init, route registration, global theme.
- `lib/screens/*`: UI flows (splash, login, home, difficulty, quiz, results, profile, upgrade).
- `lib/services/*`: auth, user creation checks, score persistence/retrieval, local profile helper.
- `lib/data/*`: quiz content loaders (`flag_loader.dart`) and sample data.
- `lib/models/*`: domain models (`FlagQuestion`).
- `lib/widgets/*`: shared UI wrappers (`AuthGuard`).

## Route Map

- `/splash` -> `SplashScreen`
- `/login` -> `LoginScreen`
- `/home` -> `HomeScreen`
- `/difficulty` -> `DifficultyScreen`
- `/quiz` -> `QuizScreen`
- `/result` -> `ResultScreen`
- `/profile` -> `UserProfileScreen`
- `/upgrade` exists as a screen constant (`UpgradeAccountScreen`) but is not registered in `main.dart` routes.

## Runtime Flow (Current)

1. `main()` initializes Firebase.
2. If no auth user exists, app attempts anonymous sign-in (`AuthService.signInAnonymously()`).
3. App starts on splash route.
4. Splash checks auth state after delay and navigates to home (if user exists) or login.
5. Home currently exposes one category: `flag`.
6. Difficulty selects question count and difficulty key.
7. Quiz loads assets, randomizes questions/options, tracks score.
8. Results screen saves score and renders session summary.
9. Profile screen fetches stored user scores from Firestore.

## Quiz Engine

- Question assets are discovered dynamically from `AssetManifest.json` for `assets/flags/`.
- Each quiz question is a `FlagQuestion` with:
  - `imagePath`
  - `correctAnswer`
  - `options`
- `prepareQuiz()` creates 4-choice options per question:
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
- `leaderboard/{category_difficulty}/entries/{uid}`

Current score document fields:

- `categoryKey`
- `difficulty`
- `bestScore`
- `updatedAt`

Current leaderboard entry fields:

- `categoryKey`
- `difficulty`
- `score`
- `updatedAt`

Anonymous user doc fields (created by `UserChecker`):

- `isAnonymous`
- `createdAt`
- `lastSeen`
- `displayName`

## Auth Model

- Guest-first behavior is implemented at app startup in `main.dart`.
- `LoginScreen` provides:
  - Email provider
  - Google provider (placeholder client ID currently in code)
  - Apple provider
  - Guest button (`Continue as Guest`)
- `AuthGuard` supports:
  - unauthenticated -> login
  - anonymous disallowed -> upgrade screen
  - allowed -> protected child

## Score Handling

Current implementation uses two score stores:

- Firestore via `ScoreService`:
  - saves personal best (transaction)
  - writes leaderboard entry
  - reads all high scores for profile
- Local `SharedPreferences` via `UserProfile`:
  - used by `ResultScreen` for high-score messaging

This is a known consistency risk and should be unified.

## Architectural Extension Points

- Category expansion is already modeled with `categoryKey` in navigation and persistence.
- New quiz types can reuse the same:
  - Home category model
  - Difficulty route args
  - Result + score persistence flow
- Additional loaders can mirror `flag_loader.dart` while keeping shared quiz/session UI patterns.

## Known Constraints / Cleanup Targets

- `LoginScreen` references `assets/images/logo.png`; current assets use `logo-*` naming.
- Google OAuth client ID is a placeholder.
- `main.dart` still contains template `MyHomePage` counter code that is not used by app routing.
- `ResultScreen` relies on local high score while profile uses Firestore high scores.
- `firebase_options.dart` is configured for Android/iOS/Web; macOS/Linux/Windows throw unsupported errors unless configured.
