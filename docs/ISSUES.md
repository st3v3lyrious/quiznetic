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
| ISS-007 | P1 | MVP | Blocked | Android real device: rewarded hint flow can fail to grant hint after ad reward/close sequence. | `You` | `March 2, 2026` |  |
| ISS-008 | P1 | MVP | Blocked | Android real device: home banner ad renders as broken/blank test creative. | `You` | `March 3, 2026` |  |
| ISS-009 | P1 | MVP | Blocked | Android real device: result interstitial appears visually broken/blank during QA. | `You` | `March 3, 2026` |  |
| ISS-010 | P2 | MVP | Done | App branding name mismatch: installed app shows `quiznetic_flutter`/`Quiznetic Flutter` instead of `Quiznetic`. | `You` | `March 2, 2026` |  |
| ISS-011 | P0 | MVP | Done | Leaderboard appears stale after quiz completion: verify forced pending-score sync + investigate persistent sync failures from diagnostics. | `You` | `March 3, 2026` |  |
| ISS-012 | P0 | MVP | Done | Security hardening before MVP deploy: rotate exposed Firebase/AdMob/OAuth credentials, then purge leaked credential artifacts from git history and validate no active secrets remain reachable from prior commits/tags. | `You` | `March 6, 2026` |  |
| ISS-013 | P1 | MVP | Done | Quiz answer flow on common phone heights can hide the post-answer `Next` CTA below the fold; keep the action visible without requiring manual scroll. | `You` | `March 14, 2026` |  |
| ISS-014 | P1 | MVP | In Progress | Monetization gap: app-side Google UMP/GDPR consent flow is now shipped, but AdMob `Privacy & messaging` still needs a published European regulations message + public privacy-policy URL for live EEA/UK validation. | `You` | `March 16, 2026` |  |
| ISS-015 | P1 | MVP | Open | Google sign-in account-collision flow: when a user tries Google sign-in for an email already associated with another account/provider, the app surfaces `This provider is associated with a different user account` instead of guiding or resolving the existing-account sign-in path. | `You` | `April 6, 2026` |  |

### Recommended Execution Order (MVP)

The dates below keep the original target dates for historical tracking. Steps
2-4 are currently past due and remain blocked pending monetization direction
and validation.

1. `ISS-014` by **March 16, 2026** (app-side consent gap is closed; remaining work is AdMob console privacy-message setup and live EEA/UK validation).
2. `ISS-015` by **April 6, 2026** (Google sign-in should handle existing-account/provider collisions without dropping the user into a dead-end auth error).
3. `ISS-007` original target **March 2, 2026** (past due; blocked pending monetization direction and release-mode/live-serving validation).
4. `ISS-008` original target **March 3, 2026** (past due; blocked pending monetization direction and release-mode/live-serving validation).
5. `ISS-009` original target **March 3, 2026** (past due; blocked pending monetization direction and release-mode/live-serving validation).

## MVP+1 Backlog

| ID | Severity | Scope | Status | Issue | Owner | Target Date | GH |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ISS-005 | P2 | MVP+1 | Open | Add optional audio description mode for visually impaired users (spoken flag/context cues). | `You` | `March 20, 2026` | #141 |
