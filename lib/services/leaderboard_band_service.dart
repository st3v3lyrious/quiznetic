/*
 DOC: Service
 Title: Leaderboard Band Service
 Purpose: Computes leaderboard rank bands (top 10/20/100) from leaderboard data.
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum LeaderboardBand { top10, top20, top100, outsideTop100 }

extension LeaderboardBandLabel on LeaderboardBand {
  /// Returns a short label for this leaderboard rank band.
  String get label {
    return switch (this) {
      LeaderboardBand.top10 => 'top 10',
      LeaderboardBand.top20 => 'top 20',
      LeaderboardBand.top100 => 'top 100',
      LeaderboardBand.outsideTop100 => 'outside top 100',
    };
  }
}

class LeaderboardEntry {
  final String uid;
  final int score;
  final DateTime updatedAt;
  final bool isAnonymous;
  final String? displayName;

  LeaderboardEntry({
    required this.uid,
    required this.score,
    required this.updatedAt,
    required this.isAnonymous,
    this.displayName,
  });

  /// Builds a leaderboard entry from Firestore fields.
  factory LeaderboardEntry.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final score = ((data['score'] as num?) ?? 0).toInt();
    return LeaderboardEntry(
      uid: uid,
      score: score,
      updatedAt: _toDateTime(data['updatedAt']),
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      displayName: data['displayName'] as String?,
    );
  }

  /// Parses Firestore timestamp-like values with a safe epoch fallback.
  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class LeaderboardBandResult {
  final String categoryKey;
  final String difficulty;
  final int rank;
  final int score;
  final LeaderboardBand band;
  final int sampledEntries;

  LeaderboardBandResult({
    required this.categoryKey,
    required this.difficulty,
    required this.rank,
    required this.score,
    required this.band,
    required this.sampledEntries,
  });

  /// Returns true when the candidate qualifies inside tracked leaderboard ranks.
  bool get isTop100 => rank <= 100;
}

typedef LeaderboardEntriesLoader =
    Future<List<LeaderboardEntry>> Function({
      required String categoryKey,
      required String difficulty,
      required int limit,
    });
typedef NowProvider = DateTime Function();

class LeaderboardBandService {
  final LeaderboardEntriesLoader _entriesLoader;
  final NowProvider _nowProvider;
  final int _maxRankTracked;

  LeaderboardBandService({
    FirebaseFirestore? firestore,
    LeaderboardEntriesLoader? entriesLoader,
    NowProvider? nowProvider,
    int maxRankTracked = 100,
  }) : _entriesLoader =
           entriesLoader ?? _defaultEntriesLoader(firestore: firestore),
       _nowProvider = nowProvider ?? DateTime.now,
       _maxRankTracked = maxRankTracked;

  /// Computes the candidate's current leaderboard band for category+difficulty.
  Future<LeaderboardBandResult> getBandForScore({
    required String categoryKey,
    required String difficulty,
    required int score,
    required String candidateUid,
    DateTime? candidateUpdatedAt,
    bool candidateIsAnonymous = true,
    String? candidateDisplayName,
  }) async {
    final entries = await _entriesLoader(
      categoryKey: categoryKey,
      difficulty: difficulty,
      limit: _maxRankTracked,
    );

    final comparable =
        entries.where((entry) => entry.uid != candidateUid).toList()
          ..add(
            LeaderboardEntry(
              uid: candidateUid,
              score: score,
              updatedAt: candidateUpdatedAt ?? _nowProvider(),
              isAnonymous: candidateIsAnonymous,
              displayName: candidateDisplayName,
            ),
          )
          ..sort(compareLeaderboardEntries);

    final rank =
        comparable.indexWhere((entry) => entry.uid == candidateUid) + 1;
    return LeaderboardBandResult(
      categoryKey: categoryKey,
      difficulty: difficulty,
      rank: rank,
      score: score,
      band: bandForRank(rank),
      sampledEntries: entries.length,
    );
  }

  /// Maps a rank value to a display-ready leaderboard band.
  @visibleForTesting
  static LeaderboardBand bandForRank(int rank) {
    if (rank <= 10) return LeaderboardBand.top10;
    if (rank <= 20) return LeaderboardBand.top20;
    if (rank <= 100) return LeaderboardBand.top100;
    return LeaderboardBand.outsideTop100;
  }

  /// Sorts leaderboard entries by score, then earlier timestamp, then uid.
  @visibleForTesting
  static int compareLeaderboardEntries(LeaderboardEntry a, LeaderboardEntry b) {
    final scoreComp = b.score.compareTo(a.score);
    if (scoreComp != 0) return scoreComp;

    final updatedAtComp = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtComp != 0) return updatedAtComp;

    return a.uid.compareTo(b.uid);
  }

  /// Creates the default Firestore-backed leaderboard entries loader.
  static LeaderboardEntriesLoader _defaultEntriesLoader({
    FirebaseFirestore? firestore,
  }) {
    return ({
      required String categoryKey,
      required String difficulty,
      required int limit,
    }) async {
      final db = firestore ?? FirebaseFirestore.instance;
      final entriesRef = db
          .collection('leaderboard')
          .doc('${categoryKey}_$difficulty')
          .collection('entries');

      try {
        final snap = await entriesRef
            .orderBy('score', descending: true)
            .orderBy('updatedAt')
            .limit(limit)
            .get();
        return snap.docs
            .map(
              (doc) =>
                  LeaderboardEntry.fromFirestore(uid: doc.id, data: doc.data()),
            )
            .toList();
      } on FirebaseException catch (e) {
        // Fallback path if composite index is not created yet.
        debugPrint(
          'Leaderboard query fallback for $categoryKey/$difficulty: ${e.code}',
        );
        final snap = await entriesRef
            .orderBy('score', descending: true)
            .limit(limit)
            .get();
        final entries =
            snap.docs
                .map(
                  (doc) => LeaderboardEntry.fromFirestore(
                    uid: doc.id,
                    data: doc.data(),
                  ),
                )
                .toList()
              ..sort(compareLeaderboardEntries);
        return entries.take(limit).toList();
      }
    };
  }
}
