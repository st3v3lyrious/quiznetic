# Planning reconciliation — September 26, 2026

## Sources and scope

Compared main `4436cd6` (equal to fetched origin/main), docs/ROADMAP.md,
docs/ISSUES.md, docs/FEATURES.md, open GitHub issues and all 67 Notion board rows.
The September 16 Notion decision and September 21 project direction prioritize
Web validation on EIRENYA before additional mobile-store spending.

## Applied changes

- GitHub #139 closed as completed: ISS-003 was already Done in the repository;
  best-score comparison and local-first repository tests pass.
- Notion quiz Next-button overflow task marked Done: the small-phone-height
  widget test passes (ISS-013).
- ISS-031, ISS-036, ISS-040 and ISS-041 marked Done in the issue log: loader and
  preparation tests, collision flag finally reset, band-service edge cases and
  accessibility preference persistence are present and validated.
- ISS-029 remains open, narrowed to exhaustive retry growth/cap and error
  classification coverage; existing backoff/forced-retry tests are acknowledged.
- ISS-023 through ISS-028 moved to MVP+1, matching their already documented
  nonblocking execution order. Removed ConsentService coverage from ISS-028.
- GitHub M29–M33 created as #156–#160 and anchored in ROADMAP.md.
- All open roadmap issues assigned priorities: M32 P0; M20/M27/M28 P1;
  remaining open milestones P2. M32 belongs to MVP; the other open milestones
  belong to MVP+1. All 28 unfinished Notion tasks received a Priority property.
- M17 and feature #131 explicitly track mobile launch after Web validation.
- M15 describes reimplementation; closed #117/#118 retain historical completion
  with explicit removal notes. Mobile monetization is not a Web launch gate.
- M30 acknowledges completed removal and leaderboard retry; cache and real
  network-failure coverage remain open. M20/M27 also remain partially complete.

## Validation and limits

70 targeted Flutter unit/widget tests passed across score repository/service,
band service, accessibility preferences, flag/capital loaders, quiz and upgrade
screens. This is local automated validation, not production Web/device QA.

Production Firebase/OAuth setup, public URL, browser release verification,
responsive smoke tests, analytics, deployed security and public rollout remain
unchecked in M32. CrashReportingService currently lacks a Web guard.

No new target dates were assigned. Existing target dates are historical.
The June IMPLEMENTATION_GAP_AUDIT.md remains a historical audit; use this
reconciliation for current closure decisions.

## Synchronization tooling caveats

The project sync script was run in dry-run mode only. Its current milestone
mapping puts every M6+ milestone in MVP+1 and does not preserve roadmap priority
labels, so rerunning it unchanged would undo M32's MVP classification and these
priority assignments. Future automation should support explicit milestone and
priority metadata before applying it to this revised roadmap.

Notion accepted the Priority schema/property updates. Updating the existing
board's sort/display failed twice with an API validation error involving its
aggregate configuration; its original layout is preserved. Priorities are
stored on the tasks even though automatic sorting was not applied.
