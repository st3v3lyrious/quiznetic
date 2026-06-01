# ISSUES

Use this file as the bug/issue tracker, separate from milestone planning in
`docs/ROADMAP.md`.

## Status Legend

- `Open`: identified and not started
- `In Progress`: actively being fixed
- `Blocked`: waiting on dependency/decision
- `Done`: fixed and validated

## MVP Launch Blockers

| ID | Severity | Scope | Status | Issue | Owner | Target Date | GH |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ISS-001 | P1 | MVP | Done | Leaderboard should be reachable from all primary app surfaces (not home-only). | `You` | `February 27, 2026` | #137 |
| ISS-002 | P0 | MVP | Done | Score-scope bug: Flag quiz results can affect Capital scores. | `You` | `February 24, 2026` | #138 |
| ISS-003 | P0 | MVP | Done | Best-score update regression for same user + same difficulty scope. | `You` | `February 25, 2026` | #139 |
| ISS-004 | P1 | MVP | Done | `Describe Flag` toggle should persist for the rest of the current game session until user hides it again. | `You` | `February 28, 2026` | #140 |
| ISS-006 | P0 | MVP | Done | Android real device: Google sign-in fails from login/upgrade flow with unknown error state. | `You` | `March 2, 2026` |  |
| ISS-007 | P1 | MVP | Done | Rewarded hint flow migrated from classic rewarded ads to rewarded interstitial after real-device reward delivery proved unreliable with the old format. *Note: ads code removed from MVP scope in M30; this fix will need re-evaluation when ads are re-enabled post-MVP.* | `You` | `March 2, 2026` |  |
| ISS-008 | P1 | MVP | Done | Android real device home-banner QA issue was traced to invalid live-unit testing assumptions in non-release builds; sample-unit policy/QA path is now the source of truth for debug validation. *Note: ads code removed from MVP scope in M30; re-evaluate when ads are re-enabled post-MVP.* | `You` | `March 3, 2026` |  |
| ISS-009 | P1 | MVP | Done | Android real device result-interstitial QA issue was traced to invalid live-unit testing assumptions in non-release builds; sample-unit policy/QA path is now the source of truth for debug validation. *Note: ads code removed from MVP scope in M30; re-evaluate when ads are re-enabled post-MVP.* | `You` | `March 3, 2026` |  |
| ISS-010 | P2 | MVP | Done | App branding name mismatch: installed app shows `quiznetic_flutter`/`Quiznetic Flutter` instead of `Quiznetic`. | `You` | `March 2, 2026` |  |
| ISS-011 | P0 | MVP | Done | Leaderboard appears stale after quiz completion: verify forced pending-score sync + investigate persistent sync failures from diagnostics. | `You` | `March 3, 2026` |  |
| ISS-012 | P0 | MVP | Done | Security hardening before MVP deploy: rotate exposed Firebase/AdMob/OAuth credentials, then purge leaked credential artifacts from git history and validate no active secrets remain reachable from prior commits/tags. | `You` | `March 6, 2026` |  |
| ISS-013 | P1 | MVP | Done | Quiz answer flow on common phone heights can hide the post-answer `Next` CTA below the fold; keep the action visible without requiring manual scroll. | `You` | `March 14, 2026` |  |
| ISS-014 | P1 | MVP | Done | Monetization gap: Google UMP/GDPR consent baseline is shipped end-to-end (app-side consent flow plus AdMob `Privacy & messaging` publication and privacy-policy URL wiring). | `You` | `March 16, 2026` |  |
| ISS-015 | P1 | MVP | Done | Google sign-in account-collision flow: when a user tries Google sign-in for an email already associated with another account/provider, the app surfaces `This provider is associated with a different user account` instead of guiding or resolving the existing-account sign-in path. | `You` | `March 15, 2026` |  |
| ISS-016 | P0 | MVP | Done | **Architecture Audit - Pre-MVP Readiness** (See M30 in ROADMAP): Remove unused dependencies (`google_mobile_ads`, `in_app_purchase`, orphaned `ConsentService`, `IapService`, `EntitlementService`); fix route issues; add query timeouts; fix version sync. | `You` | `June 1, 2026` |  |
| ISS-017 | P0 | MVP | Done | Leaderboard queries lack timeout protection: UI can hang indefinitely on slow networks (>3s). Added 10s `.timeout()` to all unbounded Firestore `.get()` calls in `leaderboard_service.dart` (primary + fallback queries) and `score_service.dart` (`getHighScore`, `getAllHighScores`, `runTransaction`). | `You` | `June 5, 2026` |  |
| ISS-018 | P1 | MVP | Done | `UpgradeAccountScreen` routes to `HomeScreen()` instead of `UpgradeAccountScreen()` (line `lib/main.dart:117`): potential infinite loop if user denies auth. | `You` | `June 1, 2026` |  |
| ISS-019 | P1 | MVP | Done | App version hardcoded in 2 places (`pubspec.yaml` + `brand_config.dart`): easy to desync during release. Added `package_info_plus`; `BrandConfig.initVersion()` reads from the compiled binary at startup — `pubspec.yaml` is now the single source of truth. | `You` | `June 5, 2026` |  |
| ISS-020 | P2 | MVP | Done | 88 `debugPrint` statements left in production code (reduced to ~50 after ads removal). Added `AppLogger` utility (`lib/utils/app_logger.dart`) guarded by `kDebugMode`; replaced all call sites across 18 files. Release builds produce zero log output. | `You` | `June 7, 2026` |  |
| ISS-021 | P1 | MVP | Done | Quiz screen route arguments not validated: silent crash if `QuizScreenArgs` not provided. Added `_argsInvalid` flag + safe `is!` type-check in `didChangeDependencies`; `build` shows a recoverable error screen before any `args` access. | `You` | `June 5, 2026` |  |
| ISS-022 | P2 | MVP | Done | IAP service initializes even when `ENABLE_IAP=false`: wastes resources, potential crash if store config missing. Skip init when disabled. | `You` | `June 1, 2026` |  |
| ISS-023 | P2 | MVP | Open | Generic error messages across result screen, leaderboard, legal docs: users can't retry or understand failures. Implement specific error types + retry CTAs. | `You` | `June 6, 2026` |  |
| ISS-024 | P2 | MVP | Open | Leaderboard offline: shows empty state instead of cached data with stale indicator. Implement offline cache + "Data from last sync" banner. | `You` | `June 7, 2026` |  |
| ISS-025 | P2 | MVP | Open | Leaderboard repair logic has silent failures: if repair fails, only logs via `AppLogger` (no output in release builds). No user feedback. Consider adding repair status badge or warning. | `You` | `June 7, 2026` |  |
| ISS-026 | P2 | MVP | Open | No network state detection UI: ROADMAP M1 promises "connectivity-aware" but users don't see offline indicator. Would benefit from "Offline Mode" badge in critical screens. | `You` | `June 8, 2026` |  |
| ISS-027 | P2 | MVP | Open | No sync progress indicator: users don't know when pending scores are syncing. Consider adding small badge in HomeScreen during sync. | `You` | `June 8, 2026` |  |
| ISS-028 | P2 | MVP | Open | Test coverage gaps: ConsentService, error handling paths, and leaderboard repair logic lack integration test coverage for network failure scenarios. | `You` | `June 7, 2026` |  |

### Recommended Execution Order (MVP)

The dates below keep the original target dates for historical tracking.

**CRITICAL PATH (Complete by June 5, 2026)**
1. `ISS-016` (Audit blockers: dependency removal, route fixes, query timeouts) — foundation for clean release build
   - Subtask: `ISS-017` (Add Firestore query timeouts)
   - Subtask: `ISS-018` (Fix UpgradeAccountScreen route)
   - Subtask: `ISS-019` (Centralize app version)
   - Subtask: `ISS-021` (Quiz route args validation)
2. `ISS-022` (Skip IAP init when disabled) — prevents wasted init calls
3. `ISS-020` (Reduce debugPrint noise) — optional but recommended for production build

**DEFERRED - NOT CRITICAL FOR MVP**
- `ISS-015` **MARKED DONE** (Google sign-in account collision already implemented)
- `ISS-023` (Specific error messages) — polish for post-MVP if time permits
- `ISS-024` (Offline leaderboard cache) — UX enhancement for post-MVP
- `ISS-025` (Leaderboard repair feedback) — minor UX gap
- `ISS-026` (Network state indicator) — nice-to-have
- `ISS-027` (Sync progress indicator) — polish for post-MVP
- `ISS-028` (Test coverage gaps) — can be addressed in post-MVP hardening

## MVP+1 Backlog

| ID | Severity | Scope | Status | Issue | Owner | Target Date | GH |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ISS-005 | P2 | MVP+1 | Open | Add optional audio description mode for visually impaired users (spoken flag/context cues). | `You` | `March 20, 2026` | #141 |
| ISS-029 | P1 | MVP+1 | Open | No unit tests for `_retryDelay()` and `_looksLikeConnectivityError()` in `score_repository.dart`: these control exponential backoff — a bug here silently breaks offline recovery. | `You` | `TBD` | |
| ISS-030 | P1 | MVP+1 | Open | No unit tests for leaderboard fallback query client-side sort in `leaderboard_service.dart`: if composite index is missing, results could be mis-ordered and the bug is invisible. | `You` | `TBD` | |
| ISS-031 | P1 | MVP+1 | Open | No unit tests for flag/capital asset manifest parsing or quiz preparation (`flag_loader.dart`, `capital_loader.dart`): country key normalization and option shuffling are untested. | `You` | `TBD` | |
| ISS-032 | P1 | MVP+1 | Open | No integration tests for `UserChecker` Firestore permission-denied or quota-exceeded paths: boolean return value masks error type from callers; retry scenarios untested. | `You` | `TBD` | |
| ISS-033 | P1 | MVP+1 | Open | No unit tests verifying `LeaderboardScreen` uses injected repository vs. creates default exactly once (`leaderboard_screen.dart` lines 59-81). | `You` | `TBD` | |
| ISS-034 | P2 | MVP+1 | Open | Quiz screen question loading uses `.then()` callback (`quiz_screen.dart`): mounted check is inside callback and easy to miss in future edits. Refactor to async/await for safer control flow. | `You` | `TBD` | |
| ISS-035 | P2 | MVP+1 | Open | Malformed ISO 8601 timestamp in SharedPreferences causes `DateTime.tryParse()` to return null in `score_repository.dart`, treated as "retry due" — could trigger aggressive retry loops on corrupted data. | `You` | `TBD` | |
| ISS-036 | P2 | MVP+1 | Open | `_isResolvingExistingAccountCollision` flag not reset in a `finally` block (`upgrade_account_screen.dart`): if user navigates away during AlertDialog, flag stays `true` and blocks future collision recovery. | `You` | `TBD` | |
| ISS-037 | P2 | MVP+1 | Open | Profile bootstrap cleanup in `login_screen.dart` uses `catch (_)` — silently swallows unexpected errors including `FirebaseException` without logging. Should use `catch (e, stackTrace)` + `AppLogger`. | `You` | `TBD` | |
| ISS-038 | P2 | MVP+1 | Open | Firestore `runTransaction().timeout(10s)` is hardcoded in `score_service.dart`. Should be extracted as a named constant or added to `AppConfig` for visibility. | `You` | `TBD` | |
| ISS-039 | P2 | MVP+1 | Open | `runZonedGuarded` error capture in `main.dart` activates before `crashReportingService.initialize()` completes: an error during Firebase init could be captured before Crashlytics is ready. | `You` | `TBD` | |
| ISS-040 | P2 | MVP+1 | Open | No unit tests for `LeaderboardBandService.getBandForScore()`: wrong band assignment silently shows wrong guest conversion prompt. Needs edge case coverage (empty leaderboard, candidate at various ranks). | `You` | `TBD` | |
| ISS-041 | P2 | MVP+1 | Open | No unit tests for `accessibility_preferences.dart` SharedPreferences round-trip: default value (key not found → false) is untested. | `You` | `TBD` | |
| ISS-042 | P2 | MVP+1 | Open | Dart package name is `quiznetic_flutter` (template name) in `pubspec.yaml`: app display name is correct but all 60+ import paths use the template identifier. Worth renaming before repo grows further. | `You` | `TBD` | |
| ISS-043 | P2 | MVP+1 | Open | Stale guest rank band on result screen: band CTA ("You're in the top 10!") is computed from Firestore after `saveScore()` returns. If the score hasn't synced yet (slow/offline network), the band is computed without the user's own entry and can be optimistic. Consider computing band from local projected score instead of Firestore. | `You` | `TBD` | |
| ISS-044 | P2 | MVP+1 | Open | Profile screen score staleness: `UserProfileScreen` loads scores once in `initState` and doesn't auto-refresh. If a user plays offline and navigates to profile, best scores won't reflect the new attempt until manual refresh. Consider subscribing to local score projections or showing a "last updated" timestamp. | `You` | `TBD` | |
| ISS-045 | P2 | MVP+1 | Open | Post-upgrade score docs retain `source: 'guest'`: when a guest upgrades, existing Firestore score and leaderboard docs keep `source: 'guest'`; new submissions show `source: 'account'`. No gameplay impact but analytics filtering by source will be inconsistent for users who upgrade. Consider backfill on upgrade or document in analytics notes. | `You` | `TBD` | |
| ISS-046 | P2 | MVP+1 | Open | Display name fallback inconsistency: `score_service.dart` generates `"Guest-{uid[:6]}"` while `leaderboard_screen.dart` falls back to `"Player {uid[:4]}"`. Firestore rules require `displayName` to always be set so this path shouldn't be reached in practice, but the two fallbacks are out of sync. Consolidate into a shared utility. | `You` | `TBD` | |
| ISS-047 | P2 | MVP+1 | Open | Double sync trigger on account upgrade: `auth_service.dart` and `upgrade_account_screen.dart` both fire pending-score sync after account link. Harmless due to idempotency but redundant. Consolidate to a single sync call in the auth service layer. | `You` | `TBD` | |
