# Spark security baseline

## Budget decision — September 26, 2026

Keep `quiznetic-30734` on Firebase Spark. Do not enable billing or deploy Cloud
Functions as part of the Web MVP. `ENABLE_BACKEND_SUBMIT_SCORE` stays false.
Authoritative scoring is deferred; the public leaderboard is not cheat-proof.

## Production audit

The deployed Firestore rules matched the repository byte-for-byte before this
hardening change (SHA-256
`0879a114ef5d1320fdb598e864c66e27483396a344717b72b575228edd1684d0`).
Cloud Billing reported `billingEnabled: false`. Firestore and Authentication
App Check enforcement were `UNENFORCED`.

Ownership, supported categories/difficulties, score bounds, server timestamps
and strictly increasing best scores were already enforced. Clients could still
publish arbitrary leaderboard scores within those bounds independently of their
personal scores, spoof guest/account metadata, and list unbounded leaderboards.

## Hardening prepared for review

- Score, attempt and leaderboard documents accept only the fields the app writes.
- Attempt IDs are limited to 120 characters, matching the submission validator.
- Score/attempt source must match the authenticated guest/account provider.
- Only permanent accounts can publish leaderboard entries, matching the current
  app behavior. Guests can still save scores and read rankings.
- A leaderboard entry must be positive, marked non-anonymous and equal to the
  user's saved best score for the same category/difficulty. `getAfter` supports
  both atomic score/leaderboard writes and publication of a saved guest score
  after linking an account.
- Leaderboard collection queries require an explicit limit of at most 100.
  Individual entry reads remain available to signed-in users.

These changes use Firestore rules and require no billing upgrade, Functions
deployment, new credentials or Web build. A leaderboard write adds a dependent
rules read of the personal score; this can consume Firestore read quota,
including on rejected writes. This is a consistency check, not a rate limiter.

## Remaining limits

Clients still supply scores and can fabricate a bounded personal score and its
matching leaderboard entry. No server verifies answers or quiz completion.
Clients can create multiple accounts/attempts and repeat bounded read queries;
there is no global or per-user enforced request rate limit. Profiles retain their
existing owner-only write policy. Field allowlists cover scoring documents only.

App Check is a separate Spark follow-up: register the Web app with an attestation
provider, initialize the app SDK, monitor valid/invalid requests, then decide
whether to enforce. Do not switch enforcement on before compatible clients are
deployed. App Check reduces unauthorized-client traffic but does not prove that
a quiz score was earned.

## Validation and rollout

The Firestore emulator suite covers allowed guest/account writes, denied source
spoofing and unknown fields, leaderboard consistency, atomic writes, guest upgrade,
ownership, timestamps, score bounds, attempt immutability and bounded queries.
It also explicitly demonstrates that a fabricated bounded score remains possible.

After PR merge:

1. Inspect existing scoring document field names for compatibility with the
   allowlists; resolve any legacy extra fields before deploying.
2. Deploy only Firestore rules with
   `firebase deploy --only firestore:rules --project quiznetic-30734`.
3. Re-fetch the deployed rules and verify they match the merged rules.
4. Smoke-test guest quiz persistence, account quiz/leaderboard writes and
   guest-to-account upgrade. Check Firestore read/write usage.
5. If normal clients are blocked, redeploy the previous reviewed rules and
   investigate before retrying. Do not enable Blaze as a workaround.

## Deferred authoritative scoring (M20)

The staged callable is not ready for activation. Its transaction writes an
attempt before reading score/leaderboard documents, violating Firestore's
read-before-write requirement. Its rate check runs outside the transaction and
can be bypassed by concurrent requests. It still trusts client-reported correct
counts and timestamps, and currently projects flagged scores.

Before any future activation, fix and test these behaviors, define stronger
server validation, remove the direct-write fallback and deny client projection
writes in rules. Choose a backend and budget explicitly. Firebase Functions
deployment requires Blaze; upgrading remains an owner decision, not a launch
prerequisite.

References:
- https://firebase.google.com/docs/firestore/security/rules-conditions
- https://firebase.google.com/docs/firestore/security/rules-query
- https://firebase.google.com/docs/functions/get-started
- https://firebase.google.com/docs/app-check
