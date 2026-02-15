# Apple Sign-In Setup

This runbook covers production setup for Sign in with Apple in Quiznetic.

## What Is Already Shipped In Code

- Apple provider is wired in `LoginScreen` and `UpgradeAccountScreen`.
- Provider visibility is guarded by `ENABLE_APPLE_SIGN_IN` (default `false`).
- iOS entitlement file added: `ios/Runner/Runner.entitlements`.
- macOS entitlements include Apple sign-in capability:
  - `macos/Runner/DebugProfile.entitlements`
  - `macos/Runner/Release.entitlements`
- Auth failure handling now shows user-safe messages (no raw exception text).

## External Setup (Required Before Release)

1. Apple Developer: enable capability
   - Open Apple Developer portal.
   - Enable `Sign in with Apple` on your App ID(s) used by this app.
   - Ensure bundle identifiers match Xcode/Firebase app settings.
2. Apple Developer: create sign-in key
   - Create a `Sign in with Apple` key (`.p8`).
   - Record:
     - Team ID
     - Key ID
     - Private key contents (`.p8`)
3. Apple Developer: create Service ID (required for Firebase Apple provider)
   - Configure return URL:
     - `https://<firebase-project-id>.firebaseapp.com/__/auth/handler`
4. Firebase Console: configure Apple auth provider
   - Go to Authentication -> Sign-in method -> Apple.
   - Enter Service ID, Team ID, Key ID, and private key.
   - Save and enable provider.

## Build-Time Feature Flag

- Default behavior (disabled until setup is complete):
  - `--dart-define=ENABLE_APPLE_SIGN_IN=false`
- Enable when ready:
  - `--dart-define=ENABLE_APPLE_SIGN_IN=true`
- Emergency rollback (hide Apple provider UI):
  - `--dart-define=ENABLE_APPLE_SIGN_IN=false`

## Validation Checklist

1. iOS: sign in with Apple from `/login`, verify user reaches `/home`.
2. iOS: anonymous user upgrade via `/upgrade`, verify UID continuity is preserved.
3. macOS: repeat login + upgrade smoke checks.
4. Firebase Auth console: verify new Apple provider users appear.
5. Crash/analytics: verify no spike in `auth_signin_failed` or `auth_upgrade_failed`.

## Rollback

If Apple sign-in starts failing in production:

1. Disable provider UI with `ENABLE_APPLE_SIGN_IN=false`.
2. Rebuild/redeploy affected client targets.
3. Keep Email/Google sign-in paths active while investigating provider config.
