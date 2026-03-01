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
| ISS-006 | P0 | MVP | In Progress | Android real device: Google sign-in fails from login/upgrade flow with unknown error state. | `You` | `March 2, 2026` |  |
| ISS-007 | P1 | MVP | In Progress | Android real device: rewarded hint flow can fail to grant hint after ad reward/close sequence. | `You` | `March 2, 2026` |  |
| ISS-008 | P1 | MVP | Open | Android real device: home banner ad renders as broken/blank test creative. | `You` | `March 3, 2026` |  |
| ISS-009 | P1 | MVP | Open | Android real device: result interstitial appears visually broken/blank during QA. | `You` | `March 3, 2026` |  |
| ISS-010 | P2 | MVP | In Progress | App branding name mismatch: installed app shows `quiznetic_flutter`/`Quiznetic Flutter` instead of `Quiznetic`. | `You` | `March 2, 2026` |  |
| ISS-011 | P0 | MVP | In Progress | Leaderboard appears stale after quiz completion: verify forced pending-score sync + investigate persistent sync failures from diagnostics. | `You` | `March 3, 2026` |  |
| ISS-012 | P0 | MVP | Open | Security hardening before MVP deploy: rotate exposed Firebase/AdMob/OAuth credentials, then purge leaked credential artifacts from git history and validate no active secrets remain reachable from prior commits/tags. | `You` | `March 6, 2026` |  |

### Recommended Execution Order (MVP)

1. `ISS-006` by **March 2, 2026** (auth conversion blocker).
2. `ISS-012` by **March 6, 2026** (credential rotation + history cleanup before public release).
3. `ISS-011` by **March 3, 2026** (leaderboard freshness and score-sync reliability on real devices).
4. `ISS-007` by **March 2, 2026** (rewarded hint reliability before monetization launch gate).
5. `ISS-008` by **March 3, 2026** (home banner render stability on real device).
6. `ISS-009` by **March 3, 2026** (result interstitial render stability on real device).
7. `ISS-010` by **March 2, 2026** (brand-name consistency on installed app icon/title).

## MVP+1 Backlog

| ID | Severity | Scope | Status | Issue | Owner | Target Date | GH |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ISS-005 | P2 | MVP+1 | Open | Add optional audio description mode for visually impaired users (spoken flag/context cues). | `You` | `March 20, 2026` | #141 |
