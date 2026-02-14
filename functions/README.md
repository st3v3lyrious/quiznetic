# Cloud Functions

This folder contains backend-authoritative score submission APIs.

## submitScore

Callable function name: `submitScore`

Input payload:

- `attemptId`
- `categoryKey`
- `difficulty`
- `correctCount`
- `totalQuestions`
- `startedAt`
- `finishedAt`
- `clientVersion` (optional)

The function validates submissions, enforces idempotency by `attemptId`,
applies basic rate limiting, and writes attempts/scores/leaderboard with
Admin SDK privileges.

## Local setup

```bash
cd functions
npm install
```

## Deploy

```bash
firebase deploy --only functions --project quiznetic-30734
```
