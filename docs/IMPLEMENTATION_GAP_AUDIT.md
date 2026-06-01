# Implementation Gap Audit: ROADMAP vs Code

**Date**: June 1, 2026 (v1 — pre-M30 cleanup)
**Updated**: June 1, 2026 (v2 — post-M30 cleanup, full re-audit)
**Scope**: All gaps between documented ROADMAP/ISSUES and actual implementation

> **v1 historical note:** BUG-001 (UpgradeAccountScreen route), BUG-002 (orphaned ConsentService),
> BUG-003 (missing query timeouts), GAP-003 (IAP init), GAP-004 (debugPrint), and GAP-010
> (pubspec dependencies) from the original audit are all resolved as of this re-audit.

---

## Executive Summary (v2)

- **MVP P0/P1 blockers**: All resolved in this session (ISS-016 through ISS-022).
- **Remaining open issues**: All P2, all explicitly deferred to post-MVP or MVP+1.
- **New gaps found**: 14 new issues identified — primarily test coverage gaps and minor
  architecture hardening items. None are launch blockers.
- **Code health**: Analyze reports zero issues. No dead service references remain.
  All `debugPrint` calls replaced with `AppLogger`. Firestore queries have 10s timeouts.

---

## Findings

### P1 — Test Coverage (Critical Paths Untested)

| ID | File | Description |
|---|---|---|
| ISS-029 | `lib/services/score_repository.dart` | No unit tests for `_retryDelay()` and `_looksLikeConnectivityError()`. These control exponential backoff — a bug here silently breaks offline recovery. |
| ISS-030 | `lib/services/leaderboard_service.dart` | No unit tests for fallback query client-side sort. If composite index is missing, results could be mis-ordered. |
| ISS-031 | `lib/data/flag_loader.dart`, `capital_loader.dart` | No unit tests for asset manifest parsing or quiz preparation. Country key normalization and option shuffling are untested. |
| ISS-032 | `lib/services/user_checker.dart` | No integration tests for Firestore permission-denied or quota-exceeded paths. Boolean return value masks the error type from callers. |
| ISS-033 | `lib/screens/leaderboard_screen.dart` | No unit tests verifying injected repository is used when provided vs. default is created once and reused. |

### P2 — Architecture / Correctness

| ID | File | Description |
|---|---|---|
| ISS-034 | `lib/screens/quiz_screen.dart` | Question loading uses `.then()` callback. If widget is disposed mid-load, the callback still fires. The current `mounted` check is inside `.then()` but is easy to miss in future changes. Should use async/await for clearer control flow. |
| ISS-035 | `lib/services/score_repository.dart` | Malformed ISO 8601 timestamp in SharedPreferences causes `DateTime.tryParse()` to return null, which is treated as "retry is due". Could cause aggressive retry storms on corrupted data. |
| ISS-036 | `lib/screens/upgrade_account_screen.dart` | `_isResolvingExistingAccountCollision` flag is not reset in a `finally` block. If user navigates away during the AlertDialog, the flag stays `true` and blocks future collision recovery. |
| ISS-037 | `lib/screens/login_screen.dart` | Cleanup during profile bootstrap failure uses `catch (_)` — silently swallows unexpected errors including FirebaseException without logging. Should be `catch (e, stackTrace)` with `AppLogger`. |
| ISS-038 | `lib/services/score_service.dart` | Firestore `runTransaction().timeout(10s)` is hardcoded. On very slow networks this may abort valid transactions. Should be documented or extracted as a named constant. |
| ISS-039 | `lib/main.dart` | `runZonedGuarded` sets up error capture before `crashReportingService.initialize()` awaits. An error thrown during Firebase init could be captured before Crashlytics is ready. Low probability but worth documenting. |

### P2 — Test Coverage

| ID | File | Description |
|---|---|---|
| ISS-040 | `lib/services/leaderboard_band_service.dart` | No unit tests for `getBandForScore()`. Critical for guest CTA messaging — wrong band assignment silently shows wrong conversion prompt. |
| ISS-041 | `lib/services/accessibility_preferences.dart` | No unit tests for SharedPreferences round-trip. Default value (key not found) is untested. |

### P2 — Release Readiness

| ID | File | Description |
|---|---|---|
| ISS-042 | `pubspec.yaml` | Package name is `quiznetic_flutter` (template name). App display name is correct (`Quiznetic`), but the Dart package identifier and all import paths use the template name. Renaming post-release would require updating all 60+ import paths. Worth doing before public repo growth. |

### Already tracked — confirmed still open (P2, deferred)

| Existing ID | Description |
|---|---|
| ISS-023 | Generic error messages — result screen and leaderboard still show undifferentiated errors |
| ISS-024 | No offline leaderboard cache — fails to show stale data when network unavailable |
| ISS-025 | Leaderboard repair failures silent in release builds — no user-visible feedback |
| ISS-026 | No network state detection UI |
| ISS-027 | No sync progress indicator |
| ISS-028 | Test coverage gaps for network failure scenarios |

---

## ROADMAP Alignment Check

| Milestone | Claim | Code Reality |
|---|---|---|
| M30: error handling enhancements | `[ ]` open | Legitimately open — ISS-023/024/025 cover these; retry CTAs and offline cache not yet implemented |
| M30: all ads removal sub-tasks | `[x]` done | Verified — no ads/IAP services, widgets, or SDK deps remain |
| M26: accessibility baseline | `[x]` done | Verified — semantic labels, contrast tests, text scaling tests, flag descriptions all present |
| M19: Firestore security rules | `[x]` done | `firestore.rules` present with auth + ownership guards |
| M21: CI/CD quality gates | `[x]` done | `.github/workflows/` present with required check workflows |

---

## Code Health Verification

```
dart analyze lib/   → No issues found
debugPrint in lib/  → 2 occurrences (both inside app_logger.dart — correct)
Deleted services    → None of ConsentService, IapService, EntitlementService, AdsService present
Firestore timeouts  → .timeout(10s) present on all unbounded .get() calls and runTransaction()
```

---

## Priority Execution Order

**MVP+1 / Hardening Sprint (post-launch):**
1. ISS-029, ISS-030, ISS-031, ISS-032, ISS-033 — critical-path test coverage
2. ISS-035, ISS-036 — correctness hardening (timestamp resilience, state machine reset)
3. ISS-034, ISS-037, ISS-039 — minor code quality
4. ISS-040, ISS-041 — additional test coverage
5. ISS-038 — document/extract timeout constant
6. ISS-042 — package rename (plan carefully, touches all import paths)
