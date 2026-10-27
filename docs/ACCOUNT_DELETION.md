# M32 C3 — Account/data deletion on Spark

This is an operator procedure for a verified deletion request. It runs with
Firebase Admin privileges on a trusted operator machine using Application Default
Credentials (ADC). It does not require Cloud Functions, Blaze or client delete
permissions. Do not deploy the Functions folder to enable it.

## Support handling for the France-based project

The owner confirmed Steve Alomassor as controller and quizneticapp@gmail.com as
the requests channel. Follow the [France privacy review](FRANCE_PRIVACY_REVIEW.md)
for receipt/response tracking, proportionate identity verification and the
separate handling of provider records. The ordinary GDPR response deadline is
one month from receipt, not one month from the end of account verification.
Do not require identity-document copies by default, send credentials by email,
or put a player's request, UID or identity evidence in a public GitHub issue.
Completion of this script alone must not be described as immediate erasure of
all devices, GA4 records, provider logs and backups.

## Scope and preconditions

1. Verify the requester's identity and account ownership through an appropriate
   support process. An email message, display name or UID alone is not proof of
   ownership. Never request a password, refresh token or service-account key by
   email. Resolve the verified request to its exact Firebase Auth UID. Guest
   sessions require verifiable ownership; do not promise recovery after sign-out.
2. Use an operator identity with Firestore data administration, Firebase Auth user
   administration and read access to Firebase Security Rules. Select the intended
   project explicitly. Use the configured ADC/CLI identity; do not commit or share
   credentials. UID-only output is still personal data: keep terminal/support
   records private and minimize their retention.
3. Merge and deploy the reviewed `firestore.rules` before executing a real
   deletion. The tool reads the deployed default-database ruleset and compares
   its full source with this checkout, failing before any writes if it differs.
   This prevents running with old rules that permit stale clients to recreate
   deleted records. No production rule deployment is performed by this PR.
4. Pause any other privileged Admin writers for this UID. The lock constrains
   ordinary clients, not Admin SDKs. The MVP uses direct Firestore writes;
   backend-authoritative Functions remain disabled on Spark.
5. Run on the default Firestore database used by this app. The supported data
   locations are `users/{uid}` recursively and the user's document in every
   `leaderboard/{scope}/entries/{uid}`, including legacy scopes/missing parents
   and nested entry data. Any other datasets introduced later must be added to
   the inventory before this procedure is used for them.

The app's existing guest sign-out can delete its Auth record without cleaning up
Firestore on Spark. This procedure therefore supports a missing Auth user and
missing root documents. Do not rely on `cleanupOnUserDeleted`: it is not deployed
as part of the Spark MVP and its legacy implementation only targets `users`.
Signing out a permanent account is not a deletion request.

## Simulate first

From the repository root, install the locked operator dependencies:

```sh
cd functions
npm ci --ignore-scripts
node scripts/delete-account.cjs --project quiznetic-30734 --uid VERIFIED_UID
```

The default is a read-only inventory: Auth presence/disabled state, profile
presence, private subcollection names, leaderboard count and marker presence.
It does not print email addresses, passwords or document contents. Confirm the
project/UID against the verified request before continuing. The tool never
infers a project from a default CLI setting and never creates backup copies of
personal data as part of deletion.

## Execute and verify

```sh
node scripts/delete-account.cjs --project quiznetic-30734 --uid VERIFIED_UID \
  --execute --confirm quiznetic-30734:VERIFIED_UID
```

Execution is irreversible. Exact confirmation is required even on emulators.
The sequence is:

1. Verify deployed rules, then create `accountDeletions/{uid}` with a timestamp.
   The reviewed rules deny reads/writes for this UID even with a previously
   issued token, including score sync and leaderboard writes. Clients cannot
   create, change, read or delete the marker; unrelated accounts remain usable.
2. Disable the Auth user and revoke refresh tokens if the user still exists.
3. Recursively delete `users/{uid}`, including scores, attempts and unexpected
   nested subcollections. The Admin SDK handles large collections in chunks.
4. Enumerate leaderboard scope document references (including missing scope
   parents) and recursively delete only the selected UID's entries.
5. Delete Auth last. Verify that Auth, profile, private subcollections and all
   leaderboard entries are absent before recording completion.

On failure the process exits nonzero. Keep the marker and disabled account;
retry exactly the same UID after fixing the error. Repeated runs are safe and
also handle a user already deleted from Auth. Do not remove the marker to recover
from a partial deletion. A missing Auth identity is not evidence that Firestore
has been cleaned up.

## Minimal residual record and cleanup

A completed marker retains only its UID path, status and timestamps, not gameplay
or email. Keep it for **at least 65 minutes after completion** so all pre-existing
Firebase ID tokens (normally valid for up to one hour) expire. Then run:

```sh
node scripts/delete-account.cjs --project quiznetic-30734 --uid VERIFIED_UID \
  --execute --cleanup-marker --confirm quiznetic-30734:VERIFIED_UID
```

Cleanup rejects an early/incomplete marker or any remaining Auth/private/leaderboard
record. It is an explicit operator step; there is no TTL billing or scheduled
Cloud Function. Until the operator performs it, the minimal marker remains.
Record both deletion and marker cleanup in the restricted support follow-up.
The completion output describes the in-scope active Firebase records only.

This cannot remotely erase browser-local scores, other devices, provider backups,
hosting/security logs or already-collected GA4 events. Ask the requester to clear
Quiznetic site data on their devices; unsynchronized local scores may remain
there until cleared, although the deleted UID cannot sync them back after token
expiry. Handle any provider/Analytics erasure obligations separately using their
supported procedures. Exact log/backup/GA4 retention remains part of C4/V3; do not
promise erasure from datasets this tool does not control.

## Quotas and deployment

The rules add one deletion-marker dependent lookup to authenticated requests
(cached within a rule evaluation). Include it in Firestore read/quota estimates;
Spark quotas still apply. No Cloud Functions or billing upgrade is required.
Deploy only the reviewed Firestore rules, compare the deployed source, and smoke
test an unaffected account. Never deploy Functions or weaken the lock as a
workaround for permissions/quota failures. After an interrupted operation, do not
roll back rules until all pending deletions and token-expiry windows are resolved.

## Local verification only

Install locked dependencies in `functions/` and `firestore_tests/`, then from
`functions/` run `npm run test:deletion:emulator`. The root
`firebase.deletion.json` starts both emulators with the reviewed rules and an
isolated demo project. For an already running emulator, set **both** emulator
host variables. The CLI refuses mixed
emulator/production configuration or a non-`demo-` project in emulator mode.

```sh
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run test:deletion
```

Run the existing Firestore rules suite separately from `firestore_tests/` with
`FIRESTORE_EMULATOR_HOST` set. It includes stale-token and marker access checks.
Rules API source comparison is intentionally skipped only for this isolated
emulator mode, where the production Rules API is not available.

C3 remains open until PR merge, reviewed rules deployment/source verification,
and operator-readiness checks. Automated deletion tests must never target real
player data.

## Recorded implementation validation

- 10 operator/CLI tests pass against Auth and Firestore emulators, including
  read-only simulation, exact confirmation, 605 attempts, nested/missing parents,
  legacy leaderboard scopes, preservation of unrelated records, missing Auth,
  retry after partial failure, rules-source verification and delayed lock cleanup.
- 28 Firestore rules tests pass, including blocking an old authenticated context
  and denying client access to the operator markers.
- The Account Deletion Safety workflow runs both suites without credentials on
  pull requests affecting this procedure/rules. Node syntax, whitespace and
  repository review checks pass. No production data or rules were changed.
