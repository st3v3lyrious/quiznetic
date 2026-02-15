# ALERT ROUTING AND KPI THRESHOLDS

This document defines the MVP incident-alert routing policy and launch KPI
thresholds for Quiznetic release operations.

It is intentionally lightweight and low-cost. It assumes:

- GitHub Actions is the CI source of truth.
- Firebase Crashlytics is the runtime crash signal source of truth.
- Optional webhook alerts are enabled only when `ALERT_WEBHOOK_URL` is set.

## Severity Model

- `SEV-1`:
  - Startup crash or core quiz loop unavailable for a significant user segment.
  - Authentication or score persistence fully blocked for signed-in users.
  - Required action window: immediate triage, begin mitigation within 30 minutes.
- `SEV-2`:
  - Core functionality degraded but viable workaround exists.
  - Elevated crash/non-fatal error trend that risks conversion or retention.
  - Required action window: triage same day, mitigation within 4 hours.
- `SEV-3`:
  - Non-critical UX issues, minor regressions, or low-impact telemetry noise.
  - Required action window: include in next planned patch cycle.

## Alert Routing Policy

### Channels

- Primary:
  - Team chat channel via incoming webhook (`ALERT_WEBHOOK_URL`).
- Secondary:
  - GitHub workflow notifications and pull-request status checks.
- Fallback (if webhook is not configured):
  - Manual monitoring cadence from `docs/RELEASE_OPS_RUNBOOK.md`.

### Routing Matrix

| Signal | Trigger | Severity | Route | Owner |
| --- | --- | --- | --- | --- |
| CI required-gate failure | Any failure in `flutter_quality_gates.yml` | SEV-2 | Webhook + GitHub Checks | Current release engineer |
| Extended test failure | Any failure in `extended_tests.yml` | SEV-2 | Webhook + GitHub Actions | Current release engineer |
| Crash-free users drop | Crash-free users below threshold (see KPI table) | SEV-1/2 | Crashlytics console + chat escalation | Current release engineer |
| Auth or score regression | Error trend breaches KPI threshold | SEV-1/2 | Manual escalation in team channel | Current release engineer |

## KPI Thresholds (MVP)

| KPI | Target | SEV-2 Trigger | SEV-1 Trigger | Source |
| --- | --- | --- | --- | --- |
| Crash-free users (24h) | >= 99.5% | < 99.5% for 2 consecutive checks | < 98.5% at any check | Firebase Crashlytics |
| Fatal crash count (24h) | 0 | >= 2 new fatal issues affecting core routes | >= 1 startup/core-loop fatal issue | Firebase Crashlytics |
| Auth success rate (rolling) | >= 99% | < 98.5% for 1 hour | < 97% for 30 minutes | Firebase/Auth logs + support reports |
| Score save success rate (rolling) | >= 99% | < 98.5% for 1 hour | < 97% for 30 minutes | Firestore errors + app diagnostics |
| Leaderboard load success rate (rolling) | >= 99% | < 98.5% for 1 hour | < 97% for 30 minutes | Firestore errors + app diagnostics |
| Required CI checks | 100% pass on merge path | Any required check failure | Sustained inability to merge hotfix | GitHub Actions |

## Response SLAs

- `SEV-1`:
  - Acknowledge within 15 minutes.
  - Containment plan started within 30 minutes.
  - Hotfix or rollback decision within 60 minutes.
- `SEV-2`:
  - Acknowledge within 60 minutes.
  - Mitigation plan within 4 hours.
- `SEV-3`:
  - Triage in normal backlog grooming.

## Mitigation And Rollback Controls

When alert thresholds are breached, use kill switches first when they can reduce
blast radius safely:

- `ENABLE_BACKEND_SUBMIT_SCORE=false`
  - Use when backend-authoritative score-submit path is unstable.
  - Reference: `docs/BLAZE_FEATURE_FLAGS.md`.
- `ENABLE_CRASH_REPORTING=false`
  - Use only if Crashlytics integration itself is suspected to introduce
    instability.
  - Source: `lib/config/app_config.dart`.

Follow full response flow in `docs/RELEASE_OPS_RUNBOOK.md`.

## CI Alert Automation

CI alert routing is implemented in:

- `.github/workflows/flutter_quality_gates.yml`
- `.github/workflows/extended_tests.yml`

Behavior:

- On any upstream job failure, workflow posts a webhook alert.
- No webhook call occurs if `ALERT_WEBHOOK_URL` is unset.

Required repository secret:

- `ALERT_WEBHOOK_URL`
  - Expected payload contract: JSON body with at least a `text` field.
  - Recommended target: team chat incoming webhook endpoint.

## Activation Steps

1. Create an incoming webhook endpoint in your team communication tool.
2. Add `ALERT_WEBHOOK_URL` in GitHub repository secrets.
3. Trigger a controlled failing run in a branch and verify alert delivery.
4. Confirm runbook owners and acknowledgment expectations with the team.

## Known Gaps (Post-MVP)

- No dedicated on-call scheduler/pager rotation yet.
- KPI dashboard aggregation is still manual/lightweight.
- Product analytics breadcrumbs are now available for auth/quiz/score funnels; SLO dashboards still need automated aggregation.
