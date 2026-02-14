/*
 DOC: Service
 Title: Score Service
 Purpose: Persists and reads quiz scores and leaderboard data.
*/
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'score_submission_validator.dart';

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
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final bool _enableBackendSubmitScore;

  ScoreService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    bool? enableBackendSubmitScore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _enableBackendSubmitScore =
           enableBackendSubmitScore ?? AppConfig.enableBackendSubmitScore;

  /// Call this after a quiz completes.
  Future<void> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    String? attemptId,
    int? totalQuestions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final normalizedAttemptId = normalizeAttemptId(attemptId);

    final resolvedTotalQuestions =
        totalQuestions ??
        ScoreSubmissionValidator.expectedTotalQuestions(difficulty) ??
        0;
    final validation = ScoreSubmissionValidator.validate(
      categoryKey: categoryKey,
      difficulty: difficulty,
      score: score,
      totalQuestions: resolvedTotalQuestions,
    );
    if (!validation.isValid) {
      throw ScoreSubmissionValidationException(
        rejectionCode: validation.rejectionCode ?? 'invalid_submission',
        message: validation.message ?? 'Invalid score submission.',
      );
    }

    if (_enableBackendSubmitScore) {
      final finishedAt = DateTime.now().toUtc();
      final estimatedDurationSec = math.max(
        5,
        math.min(resolvedTotalQuestions * 2, 30 * 60),
      );
      final startedAt = finishedAt.subtract(
        Duration(seconds: estimatedDurationSec),
      );

      try {
        await _saveScoreViaCallable(
          categoryKey: categoryKey,
          difficulty: difficulty,
          score: score,
          totalQuestions: resolvedTotalQuestions,
          attemptId: normalizedAttemptId,
          startedAt: startedAt,
          finishedAt: finishedAt,
        );
        return;
      } on FirebaseFunctionsException catch (e) {
        // Temporary migration fallback while backend submitScore is rolling out.
        if (!_shouldFallbackToDirectWrite(e)) {
          rethrow;
        }
        debugPrint(
          'submitScore callable unavailable (${e.code}); '
          'falling back to direct client writes.',
        );
      }
    } else {
      debugPrint(
        'ENABLE_BACKEND_SUBMIT_SCORE is disabled; '
        'using direct Firestore writes for score submission.',
      );
    }

    await _saveScoreDirect(
      user: user,
      categoryKey: categoryKey,
      difficulty: difficulty,
      score: score,
      totalQuestions: resolvedTotalQuestions,
      attemptId: normalizedAttemptId,
    );
  }

  /// Submits score through backend callable function (`submitScore`).
  Future<void> _saveScoreViaCallable({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
    required String attemptId,
    required DateTime startedAt,
    required DateTime finishedAt,
  }) async {
    final callable = _functions.httpsCallable('submitScore');
    final response = await callable.call({
      'attemptId': attemptId,
      'categoryKey': categoryKey,
      'difficulty': difficulty,
      'correctCount': score,
      'totalQuestions': totalQuestions,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'clientVersion': 'flutter-1.0.0',
    });

    final payload = _asMap(response.data);
    final status = ((payload['status'] as String?) ?? '').trim();
    final rejectionCode = payload['rejectionCode'] as String?;
    final message = payload['message'] as String?;

    switch (status) {
      case 'accepted':
      case 'duplicate':
      case 'flagged':
        return;
      case 'rate_limited':
      case 'rejected':
        throw ScoreSubmissionValidationException(
          rejectionCode: rejectionCode ?? status,
          message: message ?? 'Score submission was rejected.',
        );
      default:
        throw Exception('submitScore returned unexpected status: $status');
    }
  }

  /// Uses legacy direct writes as a temporary fallback while callable rolls out.
  Future<void> _saveScoreDirect({
    required User user,
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
    required String attemptId,
  }) async {
    final uid = user.uid;
    final now = FieldValue.serverTimestamp();
    final userDoc = _db
        .collection('users')
        .doc(uid)
        .collection('scores')
        .doc('${categoryKey}_$difficulty');

    final attemptDoc = _db
        .collection('users')
        .doc(uid)
        .collection('attempts')
        .doc(attemptId);

    final leadDoc = _db
        .collection('leaderboard')
        .doc('${categoryKey}_$difficulty')
        .collection('entries')
        .doc(uid);

    await _db.runTransaction((tx) async {
      final attemptSnapshot = await tx.get(attemptDoc);
      if (attemptSnapshot.exists) {
        return;
      }

      tx.set(attemptDoc, {
        'attemptId': attemptId,
        'categoryKey': categoryKey,
        'difficulty': difficulty,
        'correctCount': score,
        'totalQuestions': totalQuestions,
        'status': 'accepted',
        'source': user.isAnonymous ? 'guest' : 'account',
        'createdAt': now,
      });

      final scoreSnapshot = await tx.get(userDoc);
      final prevBest = scoreSnapshot.exists
          ? ((scoreSnapshot.data()?['bestScore'] as num?) ?? 0).toInt()
          : 0;

      if (!shouldUpdateBestScore(previousBest: prevBest, newScore: score)) {
        return;
      }

      tx.set(userDoc, {
        'categoryKey': categoryKey,
        'difficulty': difficulty,
        'bestScore': score,
        'source': user.isAnonymous ? 'guest' : 'account',
        'updatedAt': now,
      }, SetOptions(merge: true));

      tx.set(leadDoc, {
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
    });
  }

  /// True when callable is not ready in the current environment.
  @visibleForTesting
  static bool shouldFallbackToDirectWrite(String code) {
    return code == 'not-found' ||
        code == 'unimplemented' ||
        code == 'unavailable' ||
        code == 'deadline-exceeded';
  }

  bool _shouldFallbackToDirectWrite(FirebaseFunctionsException error) {
    return shouldFallbackToDirectWrite(error.code);
  }

  /// Coerces callable response data into a map for status parsing.
  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
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

  /// Generates an idempotency-safe attempt id when client does not provide one.
  @visibleForTesting
  static String normalizeAttemptId(String? attemptId, {DateTime? now}) {
    final trimmed = attemptId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final timestamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    return 'auto-$timestamp';
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
