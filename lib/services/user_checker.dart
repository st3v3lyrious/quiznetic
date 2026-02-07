import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserChecker {
  /// Checks if the current Firebase user exists in the Firestore 'users' collection.
  /// Returns true if the user document exists, false otherwise.
  /// Checks whether a user document exists for [uid].
  /// If [uid] is null, checks the currently-signed-in user.
  static Future<bool> userExists({String? uid}) async {
    final resolvedUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUid == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(resolvedUid)
        .get();
    return doc.exists;
  }

  /// Creates a new user document in Firestore for anonymous users.
  /// Returns true if successful, false otherwise.
  /// Creates a user document for [uid] (or the current user if [uid] is null).
  /// Returns true on success.
  static Future<bool> createAnonymousUser({String? uid}) async {
    try {
      final resolvedUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (resolvedUid == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(resolvedUid)
          .set({
            'isAnonymous': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'displayName': 'Guest ${resolvedUid.substring(0, 4)}',
          });

      return true;
    } catch (e) {
      debugPrint('Error creating anonymous user: $e');
      return false;
    }
  }
}
