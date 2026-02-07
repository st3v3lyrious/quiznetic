# FEATURES

Use this as an editable feature checklist.

## Core Quiz Loop

- [x] Splash -> Home -> Difficulty -> Quiz -> Results flow
- [x] Flag quiz category (`categoryKey: flag`)
- [x] Difficulty modes: easy (15), intermediate (30), expert (50)
- [x] Randomized quiz generation from `assets/flags/`
- [x] Per-session score tracking and progress indicator

## Accounts And Auth

- [x] Firebase initialization at app startup
- [x] Anonymous sign-in path with user doc creation (`users/{uid}`)
- [x] Login screen scaffold with Email, Google, Apple providers
- [x] "Continue as Guest" path from login screen
- [x] Upgrade account screen scaffold for anonymous users

## Scores And Profile

- [x] Save user best score per category+difficulty in Firestore
- [x] Save global leaderboard entry in Firestore
- [x] Profile screen listing stored high scores

## Known Gaps / Partial

- [ ] Unify high-score source of truth (Firestore + SharedPreferences are both used)
- [ ] Configure real Google OAuth client ID
- [ ] Fix login header image reference (`assets/images/logo.png`)
- [ ] Apply `AuthGuard` consistently on protected routes

## Planned Features

- [ ] Add Logo quiz category
- [ ] Add Capitals quiz category
- [ ] Enable "Change Quiz Type" flow when multiple categories are live
- [ ] Expose anonymous-to-account upgrade in primary UX flow
