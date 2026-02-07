/*
 DOC: Service
 Title: Score Service
 Purpose: Persists and reads quiz scores and leaderboard data.
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CategoryScore {
  final String categoryKey;
  final String difficulty;
  final int highScore;
  CategoryScore({
    required this.categoryKey,
    required this.difficulty,
    required this.highScore,
  });
}

class ScoreService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Call this after a quiz completes.
  Future<void> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final uid = user.uid;
    final now = FieldValue.serverTimestamp();

    // Update user’s personal best for this category
    final userDoc = _db
        .collection('users')
        .doc(uid)
        .collection('scores')
        .doc('${categoryKey}_$difficulty');

    var didWriteBest = false;
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(userDoc);
      final prevBest = snapshot.exists
          ? (snapshot.data()!['bestScore'] as int)
          : 0;

      if (shouldUpdateBestScore(previousBest: prevBest, newScore: score)) {
        didWriteBest = true;
        tx.set(userDoc, {
          'categoryKey': categoryKey, // leave for querying
          'difficulty': difficulty, // store for display
          'bestScore': score,
          'source': user.isAnonymous ? 'guest' : 'account',
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    });

    // Keep leaderboard semantics aligned with personal-best semantics.
    if (!didWriteBest) {
      return;
    }

    // Also write into a global leaderboard
    final leadDoc = _db
        .collection('leaderboard')
        .doc('${categoryKey}_$difficulty')
        .collection('entries')
        .doc(uid);

    await leadDoc.set({
      'categoryKey': categoryKey,
      'difficulty': difficulty,
      'score': score,
      'isAnonymous': user.isAnonymous,
      'displayName': leaderboardDisplayName(
        uid: uid,
        isAnonymous: user.isAnonymous,
        displayName: user.displayName,
        email: user.email,
      ),
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Fetches one high score for the current user and category+difficulty pair.
  Future<int> getHighScore({
    required String categoryKey,
    required String difficulty,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 0;
    }

    final docId = '${categoryKey}_$difficulty';
    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('scores')
        .doc(docId)
        .get();

    final data = snap.data();
    if (data == null) {
      return 0;
    }
    return ((data['bestScore'] as num?) ?? 0).toInt();
  }

  /// Fetches *one* high score per category for the current user.
  Future<List<CategoryScore>> getAllHighScores() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final uid = user.uid;
    // Helpful debug info for diagnosing permission issues
    debugPrint(
      'ScoreService.getAllHighScores() for uid=$uid anonymous=${user.isAnonymous}',
    );

    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('scores')
          .get();

      return snap.docs
          .map((doc) => parseCategoryScore(docId: doc.id, data: doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error reading user scores for $uid: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied when reading your scores. Please ensure you are signed in and Firestore rules allow access to your user document.',
        );
      }
      rethrow;
    }
  }

  /// Returns true when [newScore] beats [previousBest].
  @visibleForTesting
  static bool shouldUpdateBestScore({
    required int previousBest,
    required int newScore,
  }) {
    return newScore > previousBest;
  }

  /// Converts a Firestore score document into a [CategoryScore].
  @visibleForTesting
  static CategoryScore parseCategoryScore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final parts = docId.split('_');
    final categoryKey = parts[0];
    final difficulty = parts.length > 1 ? parts[1] : 'unknown';
    final bestScore = (data['bestScore'] as int);
    return CategoryScore(
      categoryKey: categoryKey,
      difficulty: difficulty,
      highScore: bestScore,
    );
  }

  /// Returns the display name used for leaderboard entries.
  @visibleForTesting
  static String leaderboardDisplayName({
    required String uid,
    required bool isAnonymous,
    String? displayName,
    String? email,
  }) {
    final normalizedDisplayName = displayName?.trim();
    if (normalizedDisplayName != null && normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail.split('@').first;
    }

    if (isAnonymous) {
      final suffix = uid.length >= 6 ? uid.substring(0, 6) : uid;
      return 'Guest-$suffix';
    }

    return 'Player';
  }
}
