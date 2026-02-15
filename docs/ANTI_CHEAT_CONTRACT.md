# ANTI_CHEAT_CONTRACT

This document defines how score submissions are trusted, validated, and persisted.
It is the implementation contract for roadmap item **M20**.

## Why This Exists

Without anti-cheat controls, leaderboard value drops quickly.
This contract ensures:

- fair ranking
- predictable backend behavior
- testable security rules
- clear rejection reasons

## One-Line Contract

Only **validated server-accepted attempts** are allowed to affect user best score and global leaderboard.


## Current State (Today)

- Client-side validator enforces category, difficulty, question-count, and score bounds before persistence.
- Firestore rules enforce auth/ownership, score bounds, scope consistency, and monotonic best-score updates.
- Leaderboard stores one best row per user per `category+difficulty`.
- Tie-breakers already defined (`score desc`, `updatedAt asc`, `uid asc`).
- Backend callable `submitScore` is implemented but gated behind
  `ENABLE_BACKEND_SUBMIT_SCORE` and defaults to off for Spark-plan compatibility.

This baseline is stronger, but full integrity protection still needs a backend-authoritative submit path and server-side rate limiting.

## Target Security Model

## 1) Authoritative Write Path

Preferred:

- client calls a backend endpoint (`submitScore`) (Callable Function / HTTPS Function)
- backend validates payload
- backend writes attempt + best score + leaderboard projection

Rules impact:

- deny direct client writes to:
  - `users/{uid}/scores/{docId}`
  - `leaderboard/{scope}/entries/{uid}`
- allow read access as already defined

Interim fallback (if backend path is not yet shipped):

- allow tightly constrained client writes with strict validation (temporary only)

## 2) Submission Schema (Input Contract)

Required request payload:

- `attemptId` (string, client-generated UUID; idempotency key)
- `categoryKey` (enum, e.g. `flag`, `capital`)
- `difficulty` (enum: `easy`, `intermediate`, `expert`)
- `correctCount` (int)
- `totalQuestions` (int)
- `startedAt` (timestamp)
- `finishedAt` (timestamp)
- `clientVersion` (string, optional but recommended)

Never trusted from client:

- final leaderboard rank
- final best score projection
- status flags

## 3) Validation Rules (Hard Fail)

Submission is rejected if any fail:

1. Authentication
- user must be authenticated (anonymous allowed)
- backend user UID must match submission ownership

2. Category + Difficulty Whitelist
- `categoryKey` must exist in allowed set
- `difficulty` must exist in allowed set

3. Score Bounds
- `0 <= correctCount <= totalQuestions`
- `totalQuestions` must match difficulty:
  - `easy = 15`
  - `intermediate = 30`
  - `expert = 50`

4. Time Sanity
- `finishedAt > startedAt`
- duration within plausible range:
  - minimum (example): `>= 5s`
  - maximum (example): `<= 30m`

5. Idempotency
- same `(uid, attemptId)` may be processed once only
- duplicates return deterministic response (`duplicate`)

6. Rate Limit
- max attempts per user per time window (example: `20 / 10min`)
- overflow returns `rate_limited`

## 4) Processing Outcomes

Each submission resolves to exactly one status:

- `accepted`
- `duplicate`
- `rejected`
- `rate_limited`
- `flagged` (accepted attempt recorded, but marked suspicious)

Response payload (example):

```json
{
  "status": "accepted",
  "bestScoreUpdated": true,
  "newBestScore": 14,
  "leaderboardScope": "capital_easy",
  "rejectionCode": null,
  "riskFlags": []
}
```

## 5) Persistence Contract

## Attempt Record (immutable)

Path:

- `users/{uid}/attempts/{attemptId}`

Stores:

- raw validated payload
- computed fields (`score`, `durationMs`)
- outcome status
- optional risk flags
- `createdAt` (server timestamp)

## Best Score Projection

Path:

- `users/{uid}/scores/{category_difficulty}`

Write rule:

- update only if accepted score strictly improves current best

## Leaderboard Projection

Path:

- `leaderboard/{category_difficulty}/entries/{uid}`

Write rule:

- update only on accepted best-score improvement
- keep existing tie-break semantics via `updatedAt`

## 6) Suspicion Policy (Soft Anti-Cheat)

Do not auto-ban in MVP. First do observability + controlled exclusion.

Initial risk flags:

- `too_fast_perfect_score`
- `abnormal_attempt_burst`
- `timestamp_anomaly`

Policy:

- flagged attempts are stored
- optionally do not project flagged attempts to leaderboard until reviewed

## 7) Firestore Rules Contract (Post-Migration)

Client permissions should be:

- read:
  - own user docs/scores/attempts
  - leaderboard entries (auth-only or public-by-choice)
- write:
  - **no direct client write** to scores/leaderboard projections
  - attempts writable only via backend (or temporary strict rules if backend not yet ready)

## 8) Testing Contract

Required automated coverage:

1. Unit tests (backend validator)
- bounds, whitelist, duration, idempotency decisions

2. Firestore rules tests
- direct projection writes denied
- ownership checks enforced
- attempt write policy enforced

3. Integration tests
- accepted attempt updates projection
- duplicate attempt no-op
- invalid payload rejected

## 9) Rollout Plan (Recommended)

Phase 1 (safe baseline):

- document contract (this file)
- add submission validator module
- add attempt record schema

Phase 2 (enforcement):

- move score submission to backend authoritative path
- lock Firestore rules for direct projection writes
- activation/rollback conditions are tracked in `docs/BLAZE_FEATURE_FLAGS.md`

Phase 3 (hardening):

- rate limit + risk flags
- moderation/admin review tools (optional)

## 10) Example Decisions

Accepted:

- user plays `easy`
- `totalQuestions=15`, `correctCount=14`, duration plausible
- new best improves from 12 to 14

Rejected:

- `difficulty=easy` but `totalQuestions=50`
- `correctCount > totalQuestions`
- `finishedAt <= startedAt`

Duplicate:

- same `attemptId` resent due network retry
- backend returns `duplicate` without score inflation

## 11) Scope Notes

- This contract focuses on score integrity and leaderboard abuse controls.
- It does not include account fraud, device attestation, or payment abuse controls.
- Those can be layered later without changing this core contract.
