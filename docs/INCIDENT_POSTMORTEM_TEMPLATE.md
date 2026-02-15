# INCIDENT POSTMORTEM TEMPLATE

Use this template for any production incident that meets postmortem criteria.

Recommended workflow:

1. Create a copy of this template in `docs/incidents/` as
   `YYYY-MM-DD_short-incident-title.md`.
2. Fill incident details within 24 hours of mitigation.
3. Complete root-cause and action items within 72 hours.
4. Review status in weekly release-ops check-in until all actions are done.

## Postmortem Required When

- Any `SEV-1` incident.
- Any `SEV-2` incident lasting more than 30 minutes.
- Any repeated `SEV-2` incident type occurring 2+ times within 14 days.
- Any rollback/hotfix requiring a kill switch in production.

## 1. Incident Summary

- Incident title:
- Date:
- Incident commander:
- Severity (`SEV-1` / `SEV-2` / `SEV-3`):
- Status (resolved / monitoring / action items open):
- Systems affected:
- User impact summary:

## 2. Timeline (UTC)

| Time (UTC) | Event |
| --- | --- |
| | |
| | |
| | |

Minimum events to include:

- First signal detected (alert/manual report).
- Triage start.
- Mitigation applied (feature flag/rollback/hotfix).
- Service restored.
- Monitoring confirmed stable.

## 3. Detection And Escalation

- Detection source (Crashlytics, CI alert webhook, manual QA, user report):
- Was routing/threshold policy triggered correctly? (yes/no + notes):
- Escalation path used:
- Any delay between detection and acknowledgment:

## 4. Root Cause Analysis

- Primary root cause:
- Contributing factors:
- Why controls did not prevent this earlier:
- Why detection time was acceptable/unacceptable:

Optional structured analysis:

- 5 Whys:
  1.
  2.
  3.
  4.
  5.

## 5. Mitigation And Recovery

- Immediate mitigation steps:
- Kill switches/feature flags used:
- Rollback/hotfix details:
- Validation steps run after mitigation:
- Residual risk after recovery:

## 6. Corrective Actions

| Action | Owner | Priority | Due Date | Status |
| --- | --- | --- | --- | --- |
| | | P0/P1/P2 | YYYY-MM-DD | Open/In Progress/Done |
| | | P0/P1/P2 | YYYY-MM-DD | Open/In Progress/Done |

Quality bar:

- At least one prevention action.
- At least one detection/observability action.
- At least one test/process action (when applicable).

## 7. Communication

- Internal update links (chat/thread/doc):
- User-facing communication needed? (yes/no):
- If yes, link and timestamp:

## 8. Closure Checklist

- [ ] Root cause is documented clearly and reviewable.
- [ ] Corrective actions have owners and due dates.
- [ ] Related runbooks/docs updated.
- [ ] Related roadmap items updated if scope changed.
- [ ] Follow-up review date scheduled.

## 9. Follow-Up Cadence

- First follow-up review: within 7 days of incident closure.
- Second follow-up review: within 30 days for `SEV-1` and high-impact `SEV-2`.
- Weekly release-ops check-in should track open actions until all are done.
