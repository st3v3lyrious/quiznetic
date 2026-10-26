# M32 — C5/C6 fixes and remaining launch checks

Related to GitHub #159. These corrections preserve the Spark/direct-write model.

## Public pseudonyms (C5)

- The Dart score writer and callable backend use `Player` when a permanent
  account has no explicitly chosen name. Email is not an input to this fallback.
- New email/password accounts get an empty nickname field with a public-use
  explanation; the email prefix is not suggested or silently saved.
- Explicit names and existing guest labels are preserved. The backend helper is
  tested but the callable is not deployed/enabled on Spark.
- Previously stored public names are not silently rewritten. Reviewing legacy
  data requires Firebase access and distinguishing chosen names from old automatic
  fallbacks; an email-like chosen name is not automatically evidence of a leak.

## Submission telemetry (C6)

- Direct Firestore transactions return `accepted` or `duplicate` only after the
  transaction resolves. Replaying an existing attempt does not write another
  attempt, improve a score or emit `score_submit_success` again.
- Both callable and direct outcomes use `score_submit_duplicate` for duplicates;
  callable `flagged` responses use `score_submit_flagged`. New accepted attempts
  retain `score_submit_success`. Existing category/difficulty/score/status
  parameters remain; no email, name or attempt/UID is added to Analytics.
- GA4 reporting should count `score_submit_success` for accepted submissions and
  keep duplicate/flagged events separate. Dashboard configuration/receipt remains
  a distinct check requiring GA4 access.

## Reproduce the actual-service check

Start Auth/Firestore with `firebase.deletion.json` and demo project
`demo-quiznetic`. Build the emulator-only harness:

```sh
flutter build web --release --no-web-resources-cdn \
  --target=integration_test/score_replay_app.dart \
  --dart-define=ENABLE_ANALYTICS=false
python3 -m http.server 7359 --bind 127.0.0.1 --directory build/web
```

Open the harness and run verification. It creates an isolated demo account with
an email but no display name, submits 13/15, replays the same ID with 15/15 and
then submits a different attempt at 14/15. It asserts exactly two persisted
attempts, score 14, public name `Player`, two accepted Analytics events and one
duplicate event. Analytics is an injected recorder, not GA4 production traffic.
This entrypoint must never be used for the production build.

Recorded validation: Chromium actual-service harness passes. The existing
Results-refresh/no-second-submission browser scenarios remain relevant for the
normal navigation flow. Native Safari and production account/score tests are
separate from this emulator check.

[Actual emulator harness capture](score-replay.png).

Local validation: 259 Flutter tests passed; static analysis clean; 2 backend
pseudonym tests passed; C3's 10 operator and 28 rules tests still pass. The new
callable outcome tests assert accepted/duplicate/flagged event contracts. The
real Auth/Firestore Chromium harness verifies the direct-write replay path.

Outstanding owner facts/access are listed in
[LEGAL_OWNER_INPUT.md](../../LEGAL_OWNER_INPUT.md). No real player deletion or
legacy-name migration was performed. The new C3 rules still require authorized
Firebase deployment; no Cloud Functions or billing upgrade is part of this work.
