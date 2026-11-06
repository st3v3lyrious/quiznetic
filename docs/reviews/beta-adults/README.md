# Adult invited beta — November 6, 2026

## Release

- PR #178 retention tooling merged as `fe60c8f`, no production purge.
- PR #182 beta feedback/plan merged as `93893cf` after Flutter Quality Gates
  and Release Preflight passed on signed head `0a7ab14`.
- PR #186 SDK ownership correction merged as `c223b75` after both CI workflows
  passed on signed head `065189d`.
- Production READY: `dpl_HnRuQ1o8uGcpdyUx9vwjQvE9UJhb`, source `c223b75`,
  https://quiznetic.eirenya.com. The first build attempt failed on SDK archive
  ownership before publication; the corrected extraction uses --no-same-owner.
- Canonical Vercel build command: `bash tools/vercel-web-build.sh`, Flutter
  3.47.7 with archive checksum verification. Eight scoped sensitive build
  variables are present; no variable values were read back or put in Git.

## Validation and limits

141 widget tests and six Node tests passed locally. Required CI analysis,
widgets, unit coverage, rules tests and release preflight passed. Local analysis
could not write its home cache; the CI analysis result supplies that check.

A controlled guest completed Flags and refreshed results on the previous public
source `67502a6` during release preparation. Exactly one attempt was observed
privately after refresh. The first automation attempt timed out because its
answer locator included navigation buttons; the corrected accessible-name
selector passed. No application defect is inferred from that harness failure.
The controlled Auth account and its gameplay data were deleted through C3.
The minimal protective deletion marker remains until its 65-minute expiry;
a separate local cleanup process rechecks absence before removing it.

Browser harness corrections are kept distinct from product defects: semantic
live announcements duplicate status text in the DOM, so the test selects the
visible status once; dialog dismissal waits for the closing animation. Clipboard
permission denial is a supported fallback, not a failed copy promise.

## Feedback UI on the released public build

Chromium 145 / Playwright 1.58.2, source `c223b75`, verified at
2026-11-06T10:27:59Z. [Machine-readable result](live-feedback-report.json).

| Viewport | Open dialog | Copy template with permission | Close |
| --- | --- | --- | --- |
| Desktop 1280×900 | Pass | Pass | Pass |
| Tablet 820×1180 | Pass | Pass | Pass |
| Mobile 390×844 | Pass | Pass | Pass |

The public bundle was also compared in memory with the replacement Firebase Web
key resource: exact match, with no key value exported or written to Git.

The denied-clipboard fallback was also observed on the public build. Permission
was then explicitly granted in the test browser and the copied template read
back and checked. No page errors or Analytics requests were observed. The served
bundle returned HTTP 200 with the feedback UI; .fr returned HTTP 308.

The additional controlled anonymous accounts used for feedback checks were
removed with C3, with Auth/private data/leaderboard absence verified. Their
minimal protection markers keep the same 65-minute expiry and separate local
cleanup; these are test markers, not retained player profiles. QA sandboxes were
stopped. No account tokens or identifiers are included in these artifacts.

## Scope

First cohort: invited adults, owner decision. No invitation allowlist or age
verification is implemented. #174 remains open for minors. No invitation or
email sent. #175 effective provider/editor review and M28 real-user feedback
remain open. Native Safari is untested with the owner's launch waiver.
Web Analytics stays suspended; App Check/signup/score-integrity risks remain M20.
No real player data changed, no Function deployed and Spark retained.
