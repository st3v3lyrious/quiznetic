/*
 DOC: Service
 Title: Leaderboard Service
 Purpose: Loads ranked leaderboard rows for category+difficulty scopes.
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';

typedef CurrentUserLoader = User? Function();

class LeaderboardRow {
  final int rank;
  final LeaderboardEntry entry;

  LeaderboardRow({required this.rank, required this.entry});

  String get uid => entry.uid;
  int get score => entry.score;
}

class LeaderboardSnapshot {
  final String categoryKey;
  final String difficulty;
  final int limit;
  final List<LeaderboardRow> rows;
  final String? currentUserUid;
  final LeaderboardRow? currentUserRow;

  LeaderboardSnapshot({
    required this.categoryKey,
    required this.difficulty,
    required this.limit,
    required this.rows,
    required this.currentUserUid,
    required this.currentUserRow,
  });
}

class LeaderboardService {
  static const defaultLimit = 100;

  final LeaderboardEntriesLoader _entriesLoader;
  final CurrentUserLoader _currentUserLoader;

  LeaderboardService({
    FirebaseFirestore? firestore,
    LeaderboardEntriesLoader? entriesLoader,
    CurrentUserLoader? currentUserLoader,
  }) : _entriesLoader =
           entriesLoader ?? _defaultEntriesLoader(firestore: firestore),
       _currentUserLoader =
           currentUserLoader ?? (() => FirebaseAuth.instance.currentUser);

  /// Loads ranked rows for one leaderboard scope.
  Future<LeaderboardSnapshot> load({
    required String categoryKey,
    required String difficulty,
    int limit = defaultLimit,
  }) async {
    final entries = await _entriesLoader(
      categoryKey: categoryKey,
      difficulty: difficulty,
      limit: limit,
    );

    final sorted = List<LeaderboardEntry>.from(entries)..sort(_compareEntries);
    final rows = List<LeaderboardRow>.generate(
      sorted.length,
      (index) => LeaderboardRow(rank: index + 1, entry: sorted[index]),
    );
    final currentUserUid = _currentUserLoader()?.uid;
    LeaderboardRow? currentUserRow;
    if (currentUserUid != null) {
      for (final row in rows) {
        if (row.uid == currentUserUid) {
          currentUserRow = row;
          break;
        }
      }
    }

    return LeaderboardSnapshot(
      categoryKey: categoryKey,
      difficulty: difficulty,
      limit: limit,
      rows: rows,
      currentUserUid: currentUserUid,
      currentUserRow: currentUserRow,
    );
  }

  /// Creates the default Firestore-backed loader for leaderboard entries.
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
        // Fallback if composite index isn't available yet.
        debugPrint(
          'LeaderboardService query fallback for $categoryKey/$difficulty: ${e.code}',
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
              ..sort(_compareEntries);
        return entries.take(limit).toList();
      }
    };
  }

  /// Sorts leaderboard entries by score desc, updatedAt asc, then uid asc.
  static int _compareEntries(LeaderboardEntry a, LeaderboardEntry b) {
    final scoreComp = b.score.compareTo(a.score);
    if (scoreComp != 0) return scoreComp;

    final updatedAtComp = a.updatedAt.compareTo(b.updatedAt);
    if (updatedAtComp != 0) return updatedAtComp;

    return a.uid.compareTo(b.uid);
  }
}
