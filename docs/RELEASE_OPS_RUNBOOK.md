# RELEASE OPS RUNBOOK

This runbook defines the minimum release-safety operations baseline for MVP.
It prioritizes low-cost, high-impact controls for a budget-constrained launch.

## Scope (Current Slice)

- Crash reporting instrumentation (Firebase Crashlytics)
- Rollback playbook
- Kill-switch checklist
- Lightweight beta progression
- Alert routing baseline (CI failure webhook notifications)
- MVP KPI threshold policy (severity triggers + response SLAs)
- Incident postmortem template + review cadence

## Runtime Safety Flags

Current compile-time kill switches:

- `ENABLE_BACKEND_SUBMIT_SCORE` (default: `false`)
  - Purpose: disable callable score-submit path and stay on direct Firestore writes.
  - Details: `docs/BLAZE_FEATURE_FLAGS.md`
- `ENABLE_CRASH_REPORTING` (default: `true`)
  - Purpose: enable/disable Crashlytics collection quickly for emergency rollback builds.
  - Source: `lib/config/app_config.dart`

## Crash Reporting Baseline

### What is instrumented

- Flutter framework errors are forwarded to Crashlytics.
- Unhandled zone errors are forwarded to Crashlytics.
- Collection toggle is controlled by `ENABLE_CRASH_REPORTING`.

### Activation

Default behavior is active (`ENABLE_CRASH_REPORTING=true`).

Example:

```bash
flutter run --dart-define=ENABLE_CRASH_REPORTING=true
```

### Emergency disable (hotfix build)

```bash
flutter run --dart-define=ENABLE_CRASH_REPORTING=false
```

## Alert Routing + KPI Baseline

Policy source of truth:

- `docs/ALERT_ROUTING_AND_KPI_THRESHOLDS.md`

Implemented routing automation:

- `.github/workflows/flutter_quality_gates.yml`
- `.github/workflows/extended_tests.yml`

Activation requirement:

- Set repository secret `ALERT_WEBHOOK_URL` (webhook not sent when unset).

## Pre-Release Checklist (MVP)

1. `flutter analyze` passes.
2. `flutter test test/widget` passes.
3. `flutter test test/unit` passes.
4. Firestore rules tests pass (`npm run test:emulator` in `firestore_tests`).
5. Feature flags reviewed for target build:
   - `ENABLE_BACKEND_SUBMIT_SCORE=false` (Spark-safe baseline)
   - `ENABLE_CRASH_REPORTING=true` (unless actively debugging SDK issues)
6. Manual smoke:
   - Guest path: splash -> entry -> guest -> quiz -> result
   - Account path: entry -> login -> home -> quiz -> result
   - Score save + leaderboard load + profile high-score visibility
7. Store/build metadata verified (version, build number, privacy/legal links).

## Post-Release Monitoring (First 24-72h)

Monitor at least every 4-8 hours:

1. Crashlytics fatal events (new issue count and affected users).
2. Authentication failures (login/upgrade flow regression signals).
3. Firestore write/read failures impacting score or leaderboard flows.

Escalate immediately when:

- Crash spike blocks startup or core gameplay flow.
- Auth/score failures materially block sign-in or result saving.

## Rollback Playbook

### Severity Levels

- `SEV-1`: Startup crash / cannot play core loop.
- `SEV-2`: Core feature degraded but app still usable.
- `SEV-3`: Non-critical UI/UX defect.

### Immediate actions

1. Confirm blast radius (platform/build/channel).
2. Apply relevant kill switch in hotfix build.
3. Cut patch release with minimum diff.
4. Verify with smoke checklist before re-rollout.

### Fast kill-switch matrix

1. Score-submit backend issues:
   - set `ENABLE_BACKEND_SUBMIT_SCORE=false`
2. Crashlytics SDK suspicion:
   - set `ENABLE_CRASH_REPORTING=false`
3. OAuth instability in one provider:
   - exclude provider config in build (e.g., remove/blank Google client id for temporary disable)

## Beta Progression (Low-Cost)

1. Internal QA build:
   - core flow + scoring + leaderboard + upgrade smoke.
2. Closed beta:
   - limited testers, monitor Crashlytics for 24-48h.
3. Public rollout:
   - staged percentage rollout where store tooling allows.

## Incident Postmortems

Template source of truth:

- `docs/INCIDENT_POSTMORTEM_TEMPLATE.md`

Cadence baseline:

- Draft within 24 hours of mitigation.
- Complete root-cause and corrective actions within 72 hours.
- Review open actions weekly until closure.
- Run 7-day and 30-day follow-up checks for severe incidents.

## Open Items To Reach Full M27

- Dedicated on-call pager schedule/automation.
- KPI dashboard automation (currently policy-driven manual checks).
