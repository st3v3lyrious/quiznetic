/*
 DOC: Service
 Title: Auth Service
 Purpose: Wraps authentication operations and auth-state helpers.
*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_checker.dart';

typedef CurrentUserProvider = User? Function();
typedef AuthStateChangesProvider = Stream<User?> Function();
typedef AnonymousSignInProvider = Future<UserCredential> Function();
typedef SignOutProvider = Future<void> Function();
typedef EnsureUserDocumentProvider =
    Future<bool> Function({required User user});
typedef LinkWithCredentialProvider =
    Future<UserCredential> Function(User user, AuthCredential credential);

/// Service class that handles all authentication-related operations.
/// This includes sign in, sign out, and auth state management.
class AuthService {
  final CurrentUserProvider _currentUserProvider;
  final AuthStateChangesProvider _authStateChangesProvider;
  final AnonymousSignInProvider _anonymousSignInProvider;
  final SignOutProvider _signOutProvider;
  final EnsureUserDocumentProvider _ensureUserDocumentProvider;
  final LinkWithCredentialProvider _linkWithCredentialProvider;

  AuthService({
    CurrentUserProvider? currentUserProvider,
    AuthStateChangesProvider? authStateChangesProvider,
    AnonymousSignInProvider? anonymousSignInProvider,
    SignOutProvider? signOutProvider,
    EnsureUserDocumentProvider? ensureUserDocumentProvider,
    LinkWithCredentialProvider? linkWithCredentialProvider,
  }) : _currentUserProvider =
           currentUserProvider ?? (() => FirebaseAuth.instance.currentUser),
       _authStateChangesProvider =
           authStateChangesProvider ??
           (() => FirebaseAuth.instance.authStateChanges()),
       _anonymousSignInProvider =
           anonymousSignInProvider ??
           (() => FirebaseAuth.instance.signInAnonymously()),
       _signOutProvider =
           signOutProvider ?? (() => FirebaseAuth.instance.signOut()),
       _ensureUserDocumentProvider =
           ensureUserDocumentProvider ?? UserChecker.ensureUserDocument,
       _linkWithCredentialProvider =
           linkWithCredentialProvider ??
           ((user, credential) => user.linkWithCredential(credential));

  // Get the current user (null if not signed in)
  User? get currentUser => _currentUserProvider();

  // Check if the current user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  // Check if user is signed in (either anonymous or with credentials)
  bool get isSignedIn => currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _authStateChangesProvider();

  // Sign in anonymously
  /// Sign in anonymously and create a user document.
  /// Returns the UserCredential if successful.
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _anonymousSignInProvider();

      // Wait for the user to be created in Firebase Auth
      if (credential.user != null) {
        final created = await _ensureUserDocumentProvider(
          user: credential.user!,
        );
        if (!created) {
          throw Exception(
            'Failed to create user profile for ${credential.user!.uid}',
          );
        }
      }

      return credential;
    } catch (e) {
      debugPrint('❌ Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  // Sign out (works for both anonymous and authenticated users)
  /// Signs out the current user session.
  Future<void> signOut() async {
    try {
      await _signOutProvider();
    } catch (e) {
      debugPrint('❌ Sign-out failed: $e');
      rethrow;
    }
  }

  // Convert anonymous account to permanent account
  /// Links the anonymous user to a permanent auth credential.
  Future<UserCredential> linkAnonymousWithCredential(
    AuthCredential credential,
  ) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Not signed in');
      if (!user.isAnonymous) throw Exception('User is not anonymous');

      return await _linkWithCredentialProvider(user, credential);
    } catch (e) {
      debugPrint('❌ Account linking failed: $e');
      rethrow;
    }
  }
}
