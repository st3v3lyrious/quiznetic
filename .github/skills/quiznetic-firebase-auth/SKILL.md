---
name: quiznetic-firebase-auth
description: 'Firebase Auth patterns for QuizNetic Flutter app. Use when: implementing sign-in (Google, Apple, anonymous), auth state gating, splash screen auth checks, new user detection, Firestore profile creation/sync, user deletion edge cases, or any FirebaseAuth/firebase_ui_auth integration. Enforces centralized AuthService, StreamBuilder auth gates, no auth routing inside feature screens, avoidance of deprecated flutterfire_ui packages.'
argument-hint: 'Describe the auth flow or problem to solve...'
---

# QuizNetic Firebase Auth Skill

## When to Use
- Implementing or debugging any sign-in flow (Google, Apple, anonymous)
- Setting up or reviewing splash screen / auth gate logic
- Detecting new vs. returning users
- Creating or synchronizing Firestore user profiles
- Handling Firebase user deletion edge cases
- Reviewing or writing `StreamBuilder` auth state patterns
- Migrating away from deprecated `flutterfire_ui` / `firebase_ui_auth` packages

## Quick Reference

| Area | Reference |
|------|-----------|
| AuthService class design | [auth-service.md](./references/auth-service.md) |
| Sign-in flows & auth gating | [auth-flows.md](./references/auth-flows.md) |
| Firestore profile sync & deletion | [firestore-profile.md](./references/firestore-profile.md) |

---

## Core Rules

1. **All auth logic lives in `lib/services/auth_service.dart`** — screens never call `FirebaseAuth.instance` directly.
2. **Auth gates use `StreamBuilder<User?>`** — never a one-time `await` check for auth state.
3. **Feature screens are auth-agnostic** — they receive `uid` or `User` via constructor or route args; they do not redirect to sign-in themselves.
4. **Use `firebase_auth` + `google_sign_in` + `sign_in_with_apple`** — never the deprecated `flutterfire_ui` or `firebase_ui_auth` packages.
5. **Anonymous auth is the baseline** — signed-in anonymously by default; upgrade to Google/Apple on demand via account linking.

---

## Procedure

### 1. Initialize Firebase Auth
Firebase is initialized once in `main()`. Auth state is available immediately after.
See [auth-flows.md → Initialization](./references/auth-flows.md).

### 2. Structure the AuthService
`AuthService` is a singleton in `lib/services/auth_service.dart`:
- Exposes `authStateChanges` stream
- Wraps `signInWithGoogle()`, `signInWithApple()`, `signInAnonymously()`, `signOut()`, `deleteAccount()`

See [auth-service.md](./references/auth-service.md) for the full class template.

### 3. Gate the Splash Screen
`SplashScreen` listens to `authStateChanges` and routes to `HomeScreen` once a user is present (anonymous or signed-in). Never use `FutureBuilder` for auth gating — use `StreamBuilder`.

See [auth-flows.md → Splash Screen Gate](./references/auth-flows.md).

### 4. Detect New vs. Returning Users
Check `additionalUserInfo?.isNewUser` from `UserCredential` after Google/Apple sign-in. On first sign-in, create the Firestore profile.

See [firestore-profile.md → New User Detection](./references/firestore-profile.md).

### 5. Synchronize Firestore Profile
On sign-in (new user) or account recovery, write/merge a profile doc at `users/{uid}`. Use `SetOptions(merge: true)` to avoid overwriting fields on returning users.

See [firestore-profile.md](./references/firestore-profile.md).

### 6. Handle User Deletion Edge Cases
When deleting a Firebase user:
- Re-authenticate first (required by Firebase for sensitive ops).
- Delete Firestore docs: `users/{uid}`, `users/{uid}/scores/*`, `leaderboard/*/entries/{uid}`.
- Call `user.delete()` last.

See [firestore-profile.md → Account Deletion](./references/firestore-profile.md).

---

## Validation Checklist

- [ ] Auth calls go through `AuthService`, not raw `FirebaseAuth.instance` in screens?
- [ ] `StreamBuilder<User?>` used for auth gating (not `FutureBuilder` or `await getCurrentUser()`)?
- [ ] `firebase_ui_auth` / `flutterfire_ui` **not** imported anywhere?
- [ ] New user detection uses `UserCredential.additionalUserInfo?.isNewUser`?
- [ ] Firestore profile write uses `SetOptions(merge: true)`?
- [ ] Account deletion re-authenticates before calling `user.delete()`?
- [ ] Anonymous user is linked (not replaced) when upgrading to Google/Apple?
