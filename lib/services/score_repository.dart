/*
 DOC: Service
 Title: Score Repository
 Purpose: Provides local-first score persistence with retryable Firestore sync.
*/
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'score_service.dart';

typedef SaveRemoteScoreAction =
    Future<void> Function({
      required String categoryKey,
      required String difficulty,
      required int score,
    });
typedef LoadRemoteScoresAction = Future<List<CategoryScore>> Function();
typedef LoadRemoteBestScoreAction =
    Future<int> Function({
      required String categoryKey,
      required String difficulty,
    });
typedef PrefsLoader = Future<SharedPreferences> Function();
typedef CurrentUserProvider = User? Function();
typedef NowProvider = DateTime Function();
typedef IdProvider = String Function();

enum ScoreSyncState { pending, retryWait }

class ScoreSaveResult {
  final int bestScore;
  final bool synced;
  final bool queuedForSync;
  final String? syncError;

  ScoreSaveResult({
    required this.bestScore,
    required this.synced,
    required this.queuedForSync,
    this.syncError,
  });
}

class ScoreAttemptRecord {
  final String id;
  final String categoryKey;
  final String difficulty;
  final int score;
  final int totalQuestions;
  final String playedAtIso;
  final ScoreSyncState syncState;
  final int syncAttempts;
  final String? lastSyncError;
  final String? lastTriedAtIso;
  final String? nextRetryAtIso;

  ScoreAttemptRecord({
    required this.id,
    required this.categoryKey,
    required this.difficulty,
    required this.score,
    required this.totalQuestions,
    required this.playedAtIso,
    required this.syncState,
    required this.syncAttempts,
    required this.lastSyncError,
    required this.lastTriedAtIso,
    required this.nextRetryAtIso,
  });

  /// Parses a pending score-attempt record from local JSON data.
  factory ScoreAttemptRecord.fromJson(Map<String, dynamic> json) {
    final rawState = (json['syncState'] as String?) ?? 'pending';
    return ScoreAttemptRecord(
      id: (json['id'] as String?) ?? '',
      categoryKey: (json['categoryKey'] as String?) ?? 'unknown',
      difficulty: (json['difficulty'] as String?) ?? 'unknown',
      score: ((json['score'] as num?) ?? 0).toInt(),
      totalQuestions: ((json['totalQuestions'] as num?) ?? 0).toInt(),
      playedAtIso: (json['playedAt'] as String?) ?? '',
      syncState: rawState == 'retry_wait'
          ? ScoreSyncState.retryWait
          : ScoreSyncState.pending,
      syncAttempts: ((json['syncAttempts'] as num?) ?? 0).toInt(),
      lastSyncError: json['lastSyncError'] as String?,
      lastTriedAtIso: json['lastTriedAt'] as String?,
      nextRetryAtIso: json['nextRetryAt'] as String?,
    );
  }

  /// Converts this score-attempt record into local JSON data.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryKey': categoryKey,
      'difficulty': difficulty,
      'score': score,
      'totalQuestions': totalQuestions,
      'playedAt': playedAtIso,
      'syncState': syncState == ScoreSyncState.retryWait
          ? 'retry_wait'
          : 'pending',
      'syncAttempts': syncAttempts,
      'lastSyncError': lastSyncError,
      'lastTriedAt': lastTriedAtIso,
      'nextRetryAt': nextRetryAtIso,
    };
  }

  /// Returns a copy with selected fields updated.
  ScoreAttemptRecord copyWith({
    ScoreSyncState? syncState,
    int? syncAttempts,
    String? lastSyncError,
    String? lastTriedAtIso,
    String? nextRetryAtIso,
  }) {
    return ScoreAttemptRecord(
      id: id,
      categoryKey: categoryKey,
      difficulty: difficulty,
      score: score,
      totalQuestions: totalQuestions,
      playedAtIso: playedAtIso,
      syncState: syncState ?? this.syncState,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      lastTriedAtIso: lastTriedAtIso ?? this.lastTriedAtIso,
      nextRetryAtIso: nextRetryAtIso ?? this.nextRetryAtIso,
    );
  }
}

class ScoreProjection {
  final String categoryKey;
  final String difficulty;
  final int bestScoreLocal;
  final int bestScoreSynced;
  final String updatedAtIso;

  ScoreProjection({
    required this.categoryKey,
    required this.difficulty,
    required this.bestScoreLocal,
    required this.bestScoreSynced,
    required this.updatedAtIso,
  });

  /// Parses a local score projection from JSON.
  factory ScoreProjection.fromJson(Map<String, dynamic> json) {
    return ScoreProjection(
      categoryKey: (json['categoryKey'] as String?) ?? 'unknown',
      difficulty: (json['difficulty'] as String?) ?? 'unknown',
      bestScoreLocal: ((json['bestScoreLocal'] as num?) ?? 0).toInt(),
      bestScoreSynced: ((json['bestScoreSynced'] as num?) ?? 0).toInt(),
      updatedAtIso: (json['updatedAt'] as String?) ?? '',
    );
  }

  /// Serializes this projection to JSON.
  Map<String, dynamic> toJson() {
    return {
      'categoryKey': categoryKey,
      'difficulty': difficulty,
      'bestScoreLocal': bestScoreLocal,
      'bestScoreSynced': bestScoreSynced,
      'updatedAt': updatedAtIso,
    };
  }

  /// Returns a copy with selected fields updated.
  ScoreProjection copyWith({
    int? bestScoreLocal,
    int? bestScoreSynced,
    String? updatedAtIso,
  }) {
    return ScoreProjection(
      categoryKey: categoryKey,
      difficulty: difficulty,
      bestScoreLocal: bestScoreLocal ?? this.bestScoreLocal,
      bestScoreSynced: bestScoreSynced ?? this.bestScoreSynced,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
    );
  }
}

abstract class ScoreRepository {
  /// Saves a completed quiz score locally, then tries syncing to Firestore.
  Future<ScoreSaveResult> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  });

  /// Returns the best known score for the given category+difficulty pair.
  Future<int> getBestScore({
    required String categoryKey,
    required String difficulty,
  });

  /// Returns merged high scores for profile display.
  Future<List<CategoryScore>> getAllHighScores();

  /// Retries syncing pending local score attempts.
  Future<int> syncPendingScores({bool forceRetry = false});
}

class LocalFirstScoreRepository implements ScoreRepository {
  static const _attemptsKey = 'score_attempts_v1';
  static const _projectionKey = 'score_projection_v1';

  final SaveRemoteScoreAction _saveRemoteScore;
  final LoadRemoteScoresAction _loadRemoteScores;
  final LoadRemoteBestScoreAction _loadRemoteBestScore;
  final PrefsLoader _prefsLoader;
  final CurrentUserProvider _currentUserProvider;
  final NowProvider _nowProvider;
  final IdProvider _idProvider;

  LocalFirstScoreRepository({
    SaveRemoteScoreAction? saveRemoteScore,
    LoadRemoteScoresAction? loadRemoteScores,
    LoadRemoteBestScoreAction? loadRemoteBestScore,
    PrefsLoader? prefsLoader,
    CurrentUserProvider? currentUserProvider,
    NowProvider? nowProvider,
    IdProvider? idProvider,
  }) : _saveRemoteScore = saveRemoteScore ?? _defaultSaveRemoteScore,
       _loadRemoteScores = loadRemoteScores ?? _defaultLoadRemoteScores,
       _loadRemoteBestScore =
           loadRemoteBestScore ?? _defaultLoadRemoteBestScore,
       _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
       _currentUserProvider =
           currentUserProvider ?? (() => FirebaseAuth.instance.currentUser),
       _nowProvider = nowProvider ?? DateTime.now,
       _idProvider =
           idProvider ??
           (() => DateTime.now().microsecondsSinceEpoch.toString());

  /// Uses [ScoreService.saveScore] as the default remote persistence action.
  static Future<void> _defaultSaveRemoteScore({
    required String categoryKey,
    required String difficulty,
    required int score,
  }) {
    return ScoreService().saveScore(
      categoryKey: categoryKey,
      difficulty: difficulty,
      score: score,
    );
  }

  /// Uses [ScoreService.getAllHighScores] as the default remote loader.
  static Future<List<CategoryScore>> _defaultLoadRemoteScores() {
    return ScoreService().getAllHighScores();
  }

  /// Uses [ScoreService.getHighScore] as the default remote best-score loader.
  static Future<int> _defaultLoadRemoteBestScore({
    required String categoryKey,
    required String difficulty,
  }) {
    return ScoreService().getHighScore(
      categoryKey: categoryKey,
      difficulty: difficulty,
    );
  }

  /// Saves score locally and retries syncing all pending score attempts.
  @override
  Future<ScoreSaveResult> saveScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    required int totalQuestions,
  }) async {
    final prefs = await _prefsLoader();
    final attempts = _readAttempts(prefs);
    final projections = _readProjections(prefs);
    final nowIso = _nowProvider().toIso8601String();
    final key = _projectionEntryKey(categoryKey, difficulty);

    final current =
        projections[key] ??
        ScoreProjection(
          categoryKey: categoryKey,
          difficulty: difficulty,
          bestScoreLocal: 0,
          bestScoreSynced: 0,
          updatedAtIso: nowIso,
        );
    projections[key] = current.copyWith(
      bestScoreLocal: score > current.bestScoreLocal
          ? score
          : current.bestScoreLocal,
      updatedAtIso: nowIso,
    );

    final attempt = ScoreAttemptRecord(
      id: _idProvider(),
      categoryKey: categoryKey,
      difficulty: difficulty,
      score: score,
      totalQuestions: totalQuestions,
      playedAtIso: nowIso,
      syncState: ScoreSyncState.pending,
      syncAttempts: 0,
      lastSyncError: null,
      lastTriedAtIso: null,
      nextRetryAtIso: null,
    );
    attempts.add(attempt);
    await _persist(prefs, attempts: attempts, projections: projections);

    final synced = await _syncPendingInMemory(
      attempts: attempts,
      projections: projections,
    );
    await _persist(prefs, attempts: attempts, projections: projections);

    final savedProjection = projections[key]!;
    final stillQueued = attempts.any((a) => a.id == attempt.id);
    ScoreAttemptRecord? updatedAttempt;
    for (final queuedAttempt in attempts) {
      if (queuedAttempt.id == attempt.id) {
        updatedAttempt = queuedAttempt;
        break;
      }
    }

    return ScoreSaveResult(
      bestScore: savedProjection.bestScoreLocal,
      synced: synced > 0 && !stillQueued,
      queuedForSync: stillQueued,
      syncError: updatedAttempt?.lastSyncError,
    );
  }

  /// Returns the best known score (local projection merged with remote).
  @override
  Future<int> getBestScore({
    required String categoryKey,
    required String difficulty,
  }) async {
    final prefs = await _prefsLoader();
    final projections = _readProjections(prefs);
    final nowIso = _nowProvider().toIso8601String();
    final key = _projectionEntryKey(categoryKey, difficulty);

    var projection =
        projections[key] ??
        ScoreProjection(
          categoryKey: categoryKey,
          difficulty: difficulty,
          bestScoreLocal: 0,
          bestScoreSynced: 0,
          updatedAtIso: nowIso,
        );

    final legacyCategoryBest = prefs.getInt('highscore_$categoryKey') ?? 0;
    if (legacyCategoryBest > projection.bestScoreLocal) {
      projection = projection.copyWith(
        bestScoreLocal: legacyCategoryBest,
        updatedAtIso: nowIso,
      );
      projections[key] = projection;
    }

    if (_currentUserProvider() != null) {
      try {
        final remoteBest = await _loadRemoteBestScore(
          categoryKey: categoryKey,
          difficulty: difficulty,
        );
        final mergedBest = remoteBest > projection.bestScoreLocal
            ? remoteBest
            : projection.bestScoreLocal;
        projection = projection.copyWith(
          bestScoreLocal: mergedBest,
          bestScoreSynced: remoteBest > projection.bestScoreSynced
              ? remoteBest
              : projection.bestScoreSynced,
          updatedAtIso: nowIso,
        );
        projections[key] = projection;
      } catch (e) {
        debugPrint('ScoreRepository.getBestScore remote read failed: $e');
      }
    }

    await _persist(prefs, projections: projections);
    return projection.bestScoreLocal;
  }

  /// Returns merged local+remote high scores for profile display.
  @override
  Future<List<CategoryScore>> getAllHighScores() async {
    final prefs = await _prefsLoader();
    final projections = _readProjections(prefs);
    final nowIso = _nowProvider().toIso8601String();

    if (_currentUserProvider() != null) {
      try {
        final remoteScores = await _loadRemoteScores();
        for (final remote in remoteScores) {
          final key = _projectionEntryKey(
            remote.categoryKey,
            remote.difficulty,
          );
          final current =
              projections[key] ??
              ScoreProjection(
                categoryKey: remote.categoryKey,
                difficulty: remote.difficulty,
                bestScoreLocal: 0,
                bestScoreSynced: 0,
                updatedAtIso: nowIso,
              );
          projections[key] = current.copyWith(
            bestScoreLocal: remote.highScore > current.bestScoreLocal
                ? remote.highScore
                : current.bestScoreLocal,
            bestScoreSynced: remote.highScore > current.bestScoreSynced
                ? remote.highScore
                : current.bestScoreSynced,
            updatedAtIso: nowIso,
          );
        }
      } catch (e) {
        debugPrint('ScoreRepository.getAllHighScores remote read failed: $e');
      }
    }

    await _persist(prefs, projections: projections);

    final merged =
        projections.values
            .where((p) => p.bestScoreLocal > 0)
            .map(
              (p) => CategoryScore(
                categoryKey: p.categoryKey,
                difficulty: p.difficulty,
                highScore: p.bestScoreLocal,
              ),
            )
            .toList()
          ..sort((a, b) {
            final categoryComp = a.categoryKey.compareTo(b.categoryKey);
            if (categoryComp != 0) return categoryComp;
            return a.difficulty.compareTo(b.difficulty);
          });

    return merged;
  }

  /// Attempts to sync all pending score attempts to Firestore.
  @override
  Future<int> syncPendingScores({bool forceRetry = false}) async {
    final prefs = await _prefsLoader();
    final attempts = _readAttempts(prefs);
    final projections = _readProjections(prefs);
    final synced = await _syncPendingInMemory(
      attempts: attempts,
      projections: projections,
      forceRetry: forceRetry,
    );
    await _persist(prefs, attempts: attempts, projections: projections);
    return synced;
  }

  /// Retries each pending attempt and updates queue/projections in memory.
  Future<int> _syncPendingInMemory({
    required List<ScoreAttemptRecord> attempts,
    required Map<String, ScoreProjection> projections,
    bool forceRetry = false,
  }) async {
    if (_currentUserProvider() == null) {
      return 0;
    }

    final now = _nowProvider();
    final nowIso = now.toIso8601String();
    final updated = <ScoreAttemptRecord>[];
    var syncedCount = 0;

    for (final attempt in attempts) {
      if (!forceRetry && !_isRetryDue(attempt, now)) {
        updated.add(attempt);
        continue;
      }

      try {
        await _saveRemoteScore(
          categoryKey: attempt.categoryKey,
          difficulty: attempt.difficulty,
          score: attempt.score,
        );
        final key = _projectionEntryKey(
          attempt.categoryKey,
          attempt.difficulty,
        );
        final current =
            projections[key] ??
            ScoreProjection(
              categoryKey: attempt.categoryKey,
              difficulty: attempt.difficulty,
              bestScoreLocal: 0,
              bestScoreSynced: 0,
              updatedAtIso: nowIso,
            );
        projections[key] = current.copyWith(
          bestScoreSynced: attempt.score > current.bestScoreSynced
              ? attempt.score
              : current.bestScoreSynced,
          bestScoreLocal: attempt.score > current.bestScoreLocal
              ? attempt.score
              : current.bestScoreLocal,
          updatedAtIso: nowIso,
        );
        syncedCount++;
      } catch (e) {
        final nextDelay = _retryDelay(
          attemptNumber: attempt.syncAttempts + 1,
          connectivityError: _looksLikeConnectivityError(e),
        );
        updated.add(
          attempt.copyWith(
            syncState: ScoreSyncState.retryWait,
            syncAttempts: attempt.syncAttempts + 1,
            lastSyncError: e.toString(),
            lastTriedAtIso: nowIso,
            nextRetryAtIso: now.add(nextDelay).toIso8601String(),
          ),
        );
      }
    }

    attempts
      ..clear()
      ..addAll(updated);
    return syncedCount;
  }

  /// Returns true when this attempt can be retried at the current time.
  bool _isRetryDue(ScoreAttemptRecord attempt, DateTime now) {
    final nextRetryAtIso = attempt.nextRetryAtIso;
    if (nextRetryAtIso == null || nextRetryAtIso.isEmpty) {
      return true;
    }

    final parsed = DateTime.tryParse(nextRetryAtIso);
    if (parsed == null) {
      return true;
    }
    return !parsed.isAfter(now);
  }

  /// Calculates retry delay with slower growth for known connectivity failures.
  Duration _retryDelay({
    required int attemptNumber,
    required bool connectivityError,
  }) {
    final boundedAttempt = attemptNumber < 1 ? 1 : attemptNumber;
    if (connectivityError) {
      final minutes = switch (boundedAttempt) {
        1 => 2,
        2 => 5,
        3 => 10,
        4 => 20,
        _ => 30,
      };
      return Duration(minutes: minutes);
    }

    final seconds = switch (boundedAttempt) {
      1 => 30,
      2 => 60,
      3 => 120,
      4 => 300,
      _ => 600,
    };
    return Duration(seconds: seconds);
  }

  /// Detects common transient connectivity signatures from thrown remote errors.
  bool _looksLikeConnectivityError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('unavailable') ||
        message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection reset') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable');
  }

  /// Parses persisted pending attempts from shared preferences.
  List<ScoreAttemptRecord> _readAttempts(SharedPreferences prefs) {
    final raw = prefs.getString(_attemptsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final out = <ScoreAttemptRecord>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        out.add(ScoreAttemptRecord.fromJson(Map<String, dynamic>.from(item)));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Parses persisted local score projections from shared preferences.
  Map<String, ScoreProjection> _readProjections(SharedPreferences prefs) {
    final raw = prefs.getString(_projectionKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final out = <String, ScoreProjection>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final projection = ScoreProjection.fromJson(
          Map<String, dynamic>.from(item),
        );
        out[_projectionEntryKey(
              projection.categoryKey,
              projection.difficulty,
            )] =
            projection;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Persists queue and projection state into local shared preferences.
  Future<void> _persist(
    SharedPreferences prefs, {
    List<ScoreAttemptRecord>? attempts,
    Map<String, ScoreProjection>? projections,
  }) async {
    if (attempts != null) {
      final jsonAttempts = jsonEncode(attempts.map((e) => e.toJson()).toList());
      await prefs.setString(_attemptsKey, jsonAttempts);
    }
    if (projections != null) {
      final jsonProjections = jsonEncode(
        projections.values.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_projectionKey, jsonProjections);
    }
  }

  /// Builds the stable projection key for category+difficulty entries.
  static String _projectionEntryKey(String categoryKey, String difficulty) {
    return '$categoryKey::$difficulty';
  }
}
