# AuthService — Design & Implementation

## Location

`lib/services/auth_service.dart`

## Singleton Pattern

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Reactive auth state — use with StreamBuilder in UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Synchronous current user — can be null before first emission.
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
}
```

## Anonymous Sign-In

Called once at app start in `main()` if no user session exists.

```dart
Future<UserCredential?> signInAnonymously() async {
  try {
    return await _auth.signInAnonymously();
  } on FirebaseAuthException catch (e) {
    debugPrint('Anonymous sign-in failed: ${e.code}');
    return null;
  }
}
```

## Google Sign-In (Link Anonymous → Google)

Link the anonymous account to Google credentials to preserve any accumulated data.

```dart
Future<UserCredential?> signInWithGoogle() async {
  final googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null; // user cancelled

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final currentUser = _auth.currentUser;
  try {
    if (currentUser != null && currentUser.isAnonymous) {
      // Upgrade anonymous session — preserves uid and data
      return await currentUser.linkWithCredential(credential);
    }
    return await _auth.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'credential-already-in-use') {
      // Google account already linked to a different uid — sign in directly.
      // Anonymous data from the current session will be lost.
      return await _auth.signInWithCredential(credential);
    }
    rethrow;
  }
}
```

## Apple Sign-In

```dart
Future<UserCredential?> signInWithApple() async {
  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  );

  final oauthCredential = OAuthProvider('apple.com').credential(
    idToken: appleCredential.identityToken,
    accessToken: appleCredential.authorizationCode,
  );

  final currentUser = _auth.currentUser;
  try {
    if (currentUser != null && currentUser.isAnonymous) {
      return await currentUser.linkWithCredential(oauthCredential);
    }
    return await _auth.signInWithCredential(oauthCredential);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'credential-already-in-use') {
      return await _auth.signInWithCredential(oauthCredential);
    }
    rethrow;
  }
}
```

## Sign-Out

```dart
Future<void> signOut() async {
  await _googleSignIn.signOut();
  await _auth.signOut();
  // After sign-out, re-establish anonymous session so the app is never in a signed-out state
  await signInAnonymously();
}
```

## Account Deletion

See [firestore-profile.md → Account Deletion](./firestore-profile.md) for the Firestore cleanup step that must happen first.

```dart
Future<void> deleteAccount() async {
  final user = _auth.currentUser;
  if (user == null) return;

  // 1. Re-authenticate (Firebase requires this before sensitive operations)
  //    Call _reauthenticate(user) per provider — see firestore-profile.md
  // 2. Clean up Firestore data — see FirestoreProfileService.deleteUserData()
  // 3. Delete the Firebase Auth account last
  await user.delete();
}
```

## What NOT to Do

- Do not store `BuildContext` in `AuthService` — it outlives widget lifetimes.
- Do not call `FirebaseAuth.instance` directly in screens or widgets.
- Do not import `firebase_ui_auth` or `flutterfire_ui` — use `firebase_auth` directly with custom UI.
- Do not use `await _auth.currentUser` as a method — `currentUser` is a synchronous getter.
- Do not re-create `GoogleSignIn()` per call — reuse the instance field.
