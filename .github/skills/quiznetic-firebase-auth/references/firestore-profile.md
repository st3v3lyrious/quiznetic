# Firestore Profile Sync & Account Deletion

## Schema

```text
users/{uid}                              → { displayName, email, photoUrl, provider, createdAt, updatedAt }
users/{uid}/scores/{categoryKey}         → { bestScore: int, updatedAt: Timestamp }
leaderboard/{categoryKey}/entries/{uid}  → { score: int, updatedAt: Timestamp, displayName: String }
```

---

## FirestoreProfileService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreProfileService {
  static final FirestoreProfileService instance = FirestoreProfileService._();
  FirestoreProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates or safely merges a profile document on first sign-in.
  Future<void> createProfile(User user) async {
    await _userRef(user.uid).set({
      'displayName': user.displayName ?? 'Player',
      'email': user.email,
      'photoUrl': user.photoURL,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'anonymous',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true is safe even if doc already exists
  }

  /// Syncs mutable fields for a returning user (display name / photo may change).
  Future<void> syncProfile(User user) async {
    await _userRef(user.uid).update({
      'displayName': user.displayName ?? 'Player',
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile(String uid) =>
      _userRef(uid).get();

  /// Deletes all Firestore data for a user — call before user.delete().
  Future<void> deleteUserData(String uid) async {
    // 1. Delete score subcollection (Firestore does NOT auto-delete subcollections)
    final scores = await _userRef(uid).collection('scores').get();
    final batch = _db.batch();
    for (final doc in scores.docs) {
      batch.delete(doc.reference);
    }
    // 2. Delete the profile document
    batch.delete(_userRef(uid));
    await batch.commit();

    // 3. Delete leaderboard entries across all known categories
    // For large category sets, prefer a Cloud Function triggered on user deletion.
    const categories = ['world_flags', 'europe_flags', 'asia_flags'];
    for (final cat in categories) {
      await _db
          .collection('leaderboard')
          .doc(cat)
          .collection('entries')
          .doc(uid)
          .delete();
    }
  }
}
```

---

## New User Detection

```dart
final credential = await AuthService.instance.signInWithGoogle();
if (credential == null) return;

final isNew = credential.additionalUserInfo?.isNewUser ?? false;
if (isNew) {
  await FirestoreProfileService.instance.createProfile(credential.user!);
} else {
  await FirestoreProfileService.instance.syncProfile(credential.user!);
}
```

**Note:** `isNewUser` is `true` on the first sign-in with a given provider. When an anonymous user links to Google, `isNewUser` may be `false` even though the Google account is new to your app. To distinguish truly new accounts, also check `user.metadata.creationTime`:

```dart
final isVeryNew = user.metadata.creationTime != null &&
    DateTime.now().difference(user.metadata.creationTime!).inSeconds < 30;
```

---

## Account Deletion

Deleting a Firebase Auth user requires:

1. Re-authentication (Firebase security requirement for sensitive operations)
2. Firestore data cleanup (Firebase does **not** auto-delete Firestore data on auth deletion)
3. `user.delete()` call — always last

```dart
Future<void> deleteAccount(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Step 1: Re-authenticate per provider
    await _reauthenticate(user);

    // Step 2: Delete Firestore data
    await FirestoreProfileService.instance.deleteUserData(user.uid);

    // Step 3: Delete Firebase Auth account
    await user.delete();

    // Navigate to splash — auth state stream emits null automatically
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        SplashScreen.routeName,
        (_) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      // Should not reach here since we re-authenticated above
      // but handle defensively
      debugPrint('Re-auth required: ${e.code}');
    }
    rethrow;
  }
}
```

---

## Re-Authentication Patterns

Re-auth is required by Firebase before `user.delete()` or `user.updatePassword()`.

```dart
Future<void> _reauthenticate(User user) async {
  final providerId = user.providerData.isNotEmpty
      ? user.providerData.first.providerId
      : 'anonymous';

  switch (providerId) {
    case 'google.com':
      await _reauthGoogle(user);
    case 'apple.com':
      await _reauthApple(user);
    case 'anonymous':
      // Anonymous users do not require re-auth before deletion
      break;
    default:
      throw UnsupportedError('Re-auth not implemented for provider: $providerId');
  }
}

Future<void> _reauthGoogle(User user) async {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) throw Exception('Re-auth cancelled by user');
  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  await user.reauthenticateWithCredential(credential);
}

Future<void> _reauthApple(User user) async {
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
  await user.reauthenticateWithCredential(oauthCredential);
}
```

---

## Edge Cases

| Scenario | Handling |
| ---------- | ---------- |
| Anonymous user deletes account | No re-auth required; go straight to `deleteUserData` → `user.delete()` |
| `credential-already-in-use` on link | Sign in directly (anonymous data is lost); document this trade-off clearly to the user |
| `requires-recent-login` error | Catch `FirebaseAuthException(code: 'requires-recent-login')` and trigger the re-auth flow |
| Firestore profile doc missing on sync | `update()` throws if doc doesn't exist — use `set(..., SetOptions(merge: true))` defensively |
| User deleted from Firebase console mid-session | `authStateChanges` emits `null`; gate navigates back to splash automatically |
| Large number of leaderboard categories | Move leaderboard entry cleanup to a Cloud Function triggered by `auth.user().onDelete()` |
| Apple sign-in: email only returned once | Store email in Firestore on `createProfile` — Apple does not return it on subsequent sign-ins |
