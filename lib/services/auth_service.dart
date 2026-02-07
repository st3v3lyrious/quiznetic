/*
 DOC: Service
 Title: Auth Service
 Purpose: Wraps authentication operations and auth-state helpers.
*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_checker.dart';

/// Service class that handles all authentication-related operations.
/// This includes sign in, sign out, and auth state management.
class AuthService {
  final _auth = FirebaseAuth.instance;

  // Get the current user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  // Check if the current user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  // Check if user is signed in (either anonymous or with credentials)
  bool get isSignedIn => currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  /// Sign in anonymously and create a user document.
  /// Returns the UserCredential if successful.
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Wait for the user to be created in Firebase Auth
      if (credential.user != null) {
        final uid = credential.user!.uid;
        final userExists = await UserChecker.userExists(uid: uid);
        if (!userExists) {
          // Only create document if it doesn't exist. Pass uid directly to avoid
          // any race where FirebaseAuth.instance.currentUser isn't populated yet.
          final created = await UserChecker.createAnonymousUser(uid: uid);
          if (!created) {
            debugPrint('❌ Failed to create anonymous user document for $uid');
          }
        }
      }

      return credential;
    } catch (e) {
      debugPrint('❌ Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  // Sign out (works for both anonymous and authenticated users)
  /// TODO: Describe the behavior of `signOut`.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('❌ Sign-out failed: $e');
      rethrow;
    }
  }

  // Convert anonymous account to permanent account
  /// TODO: Describe the behavior of `linkAnonymousWithCredential`.
  Future<UserCredential> linkAnonymousWithCredential(
    AuthCredential credential,
  ) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Not signed in');
      if (!user.isAnonymous) throw Exception('User is not anonymous');

      return await user.linkWithCredential(credential);
    } catch (e) {
      debugPrint('❌ Account linking failed: $e');
      rethrow;
    }
  }
}
