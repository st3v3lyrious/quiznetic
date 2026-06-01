# Auth Flows & Splash Screen Gating

## Firebase Auth Initialization

Firebase is initialized once in `main()` before `runApp`. Anonymous sign-in is attempted immediately if no session exists.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);

  // Establish baseline anonymous session if no user is present
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in error: $e');
    }
  }

  runApp(const QuizNeticApp());
}
```

---

## Splash Screen Auth Gate

`SplashScreen` uses `StreamBuilder<User?>` to gate navigation. Once a `User` is available (anonymous or signed-in), it navigates to `HomeScreen`.

```dart
class SplashScreen extends StatelessWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          // Use post-frame callback — never navigate during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          });
        }
        // Show splash content (logo, loading indicator)
        return const _SplashContent();
      },
    );
  }
}
```

### Why `StreamBuilder` not `FutureBuilder`?

- Auth state can change after app launch (token refresh, sign-out, account deletion from console).
- `StreamBuilder` reacts to all future changes; `FutureBuilder` captures a single snapshot and goes stale.
- Rule: **always use `StreamBuilder` for auth gating**.

---

## Auth State in Feature Screens

Feature screens **do not** listen to `authStateChanges`. The splash gate ensures a user exists before any feature screen loads. Feature screens receive `uid` via route arguments when needed:

```dart
Navigator.pushNamed(
  context,
  LeaderboardScreen.routeName,
  arguments: {'uid': AuthService.instance.uid},
);
```

If a feature screen needs to react to sign-in/sign-out (e.g., show a "Sign in for full access" banner), use a limited `StreamBuilder` scoped only to that widget — not for routing.

---

## Sign-In Flow (Google / Apple)

Triggered from `UserProfileScreen` or a dedicated `SignInScreen` — never from within quiz or game screens.

```dart
// In UserProfileScreen
Future<void> _handleGoogleSignIn(BuildContext context) async {
  try {
    final credential = await AuthService.instance.signInWithGoogle();
    if (credential == null) return; // user cancelled

    final isNew = credential.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      await FirestoreProfileService.instance.createProfile(credential.user!);
    } else {
      await FirestoreProfileService.instance.syncProfile(credential.user!);
    }
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign-in failed: ${e.message ?? e.code}')),
    );
  }
}
```

Key points:

- Check `context.mounted` before using `context` after any `await`.
- Handle `FirebaseAuthException` specifically — let other exceptions propagate.
- New user → create profile; returning user → sync profile.

---

## Auth Persistence

Firebase Auth persists sessions automatically on Android and iOS via the platform keychain / shared preferences. No additional configuration is needed.

Anonymous sessions persist across app restarts until:

- `signOut()` is called explicitly
- The app is uninstalled (iOS) or data is cleared (Android)
- The account is deleted from the Firebase console

---

## Token Refresh

`FirebaseAuth` handles ID token refresh (every hour) automatically. Do **not** manually manage ID tokens unless calling a custom backend. If you need the token for an API call:

```dart
// Only call when needed for a custom backend request — do not store
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
```

Never cache or persist ID tokens — always fetch fresh when needed.

---

## Sign-Out Flow

After sign-out, re-establish an anonymous session so the app is never in a fully signed-out state (preserves quiz progress without an account):

```dart
// In AuthService
Future<void> signOut() async {
  await _googleSignIn.signOut();
  await _auth.signOut();
  await signInAnonymously(); // re-establish baseline session
}
```

---

## Edge Cases

| Scenario | Handling |
| ---------- | ---------- |
| User is null after `initializeApp` | Should not happen after anonymous sign-in; guard with null check before navigating |
| Anonymous sign-in blocked (emulator/network) | Show a retry UI; do not navigate to HomeScreen without a valid user |
| Account deleted from Firebase console | `authStateChanges` emits `null` → route back to SplashScreen |
| `signInAnonymously` called when already signed in | Firebase ignores it safely; no error |
| Re-opened app with valid session | `currentUser` is non-null immediately; `authStateChanges` emits the user quickly |
