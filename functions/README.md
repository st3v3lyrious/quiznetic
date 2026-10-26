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

## Spark account deletion (M32 C3)

The operator-only script runs without deploying Functions:
`npm run account:delete -- --project PROJECT --uid VERIFIED_UID` (dry-run).
Read [the complete deletion procedure](../docs/ACCOUNT_DELETION.md) before using
`--execute`. It requires deployed deletion-lock rules and exact project/UID
confirmation. Test only against the Auth/Firestore emulators with
`npm run test:deletion`.
