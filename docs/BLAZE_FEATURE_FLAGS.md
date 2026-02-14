# BLAZE FEATURE FLAGS

This document tracks features that require Firebase Blaze billing and are
therefore disabled by default for Spark-budget operation.

## Current Blaze-Dependent Flags

### `ENABLE_BACKEND_SUBMIT_SCORE`

- Type: `--dart-define` boolean
- Default: `false`
- App config source: `lib/config/app_config.dart`
- Runtime usage: `ScoreService.saveScore()` in `lib/services/score_service.dart`
- Backend dependency: callable Cloud Function `submitScore`

When `false`:

- App submits scores through direct Firestore writes (current Spark-safe path).
- App does not attempt callable `submitScore`.

When `true`:

- App attempts callable `submitScore`.
- If callable is temporarily unavailable (`not-found`, `unimplemented`,
  `unavailable`, `deadline-exceeded`), app falls back to direct Firestore writes.

## Activation Conditions

Enable `ENABLE_BACKEND_SUBMIT_SCORE=true` only when all are true:

1. Firebase project is upgraded to Blaze plan.
2. Required APIs are enabled in project:
   - `cloudfunctions.googleapis.com`
   - `cloudbuild.googleapis.com`
   - `artifactregistry.googleapis.com`
3. `submitScore` function is deployed successfully.
4. Smoke test confirms attempt + score + leaderboard writes via callable path.
5. Function logs show expected accepted/duplicate responses and no auth errors.

## How To Activate

1. Deploy backend:

```bash
firebase deploy --only functions:submitScore --project quiznetic-30734
```

2. Run app with feature flag enabled:

```bash
flutter run --dart-define=ENABLE_BACKEND_SUBMIT_SCORE=true
```

3. If Google sign-in is also needed in the same build:

```bash
flutter run \
  --dart-define=ENABLE_BACKEND_SUBMIT_SCORE=true \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=<your-client-id>
```

4. Verify function logs:

```bash
firebase functions:log --only submitScore --project quiznetic-30734
```

## How To Roll Back Fast

If callable path causes issues, remove the dart-define (or set false):

```bash
flutter run --dart-define=ENABLE_BACKEND_SUBMIT_SCORE=false
```

This immediately returns app behavior to direct Firestore score writes.

## Future Phase 2 Completion

After callable path is stable in production:

1. Remove direct-write fallback from `ScoreService`.
2. Tighten `firestore.rules` to deny client writes for:
   - `users/{uid}/scores/{docId}`
   - `leaderboard/{scope}/entries/{uid}`
   - (optionally) `users/{uid}/attempts/{attemptId}` once full migration is complete
3. Expand tests for callable-only behavior and denied direct projection writes.
