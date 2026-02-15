import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';

void main() {
  group('LeaderboardBandService', () {
    test('band labels expose user-facing rank strings', () {
      expect(LeaderboardBand.top10.label, 'top 10');
      expect(LeaderboardBand.top20.label, 'top 20');
      expect(LeaderboardBand.top100.label, 'top 100');
      expect(LeaderboardBand.outsideTop100.label, 'outside top 100');
    });

    test('maps rank into expected band', () {
      expect(LeaderboardBandService.bandForRank(1), LeaderboardBand.top10);
      expect(LeaderboardBandService.bandForRank(10), LeaderboardBand.top10);
      expect(LeaderboardBandService.bandForRank(11), LeaderboardBand.top20);
      expect(LeaderboardBandService.bandForRank(20), LeaderboardBand.top20);
      expect(LeaderboardBandService.bandForRank(21), LeaderboardBand.top100);
      expect(LeaderboardBandService.bandForRank(100), LeaderboardBand.top100);
      expect(
        LeaderboardBandService.bandForRank(101),
        LeaderboardBand.outsideTop100,
      );
    });

    test('LeaderboardEntry.fromFirestore parses timestamp-backed payloads', () {
      final updatedAt = DateTime.utc(2025, 1, 1, 8, 30, 0);
      final entry = LeaderboardEntry.fromFirestore(
        uid: 'u-timestamp',
        data: {
          'score': 42,
          'updatedAt': Timestamp.fromDate(updatedAt),
          'isAnonymous': true,
          'displayName': 'Guest-u',
        },
      );

      expect(entry.uid, 'u-timestamp');
      expect(entry.score, 42);
      expect(
        entry.updatedAt.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
      );
      expect(entry.isAnonymous, isTrue);
      expect(entry.displayName, 'Guest-u');
    });

    test(
      'LeaderboardEntry.fromFirestore handles DateTime and fallback values',
      () {
        final dateTime = DateTime.utc(2025, 1, 2, 8, 0, 0);
        final withDateTime = LeaderboardEntry.fromFirestore(
          uid: 'u-datetime',
          data: {'score': 7, 'updatedAt': dateTime},
        );
        final withFallback = LeaderboardEntry.fromFirestore(
          uid: 'u-fallback',
          data: {'score': 3, 'updatedAt': 'invalid'},
        );

        expect(withDateTime.updatedAt, dateTime);
        expect(
          withFallback.updatedAt,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        expect(withFallback.isAnonymous, isFalse);
        expect(withFallback.displayName, isNull);
      },
    );

    test('LeaderboardBandResult.isTop100 reflects rank threshold', () {
      final top = LeaderboardBandResult(
        categoryKey: 'flag',
        difficulty: 'easy',
        rank: 100,
        score: 50,
        band: LeaderboardBand.top100,
        sampledEntries: 100,
      );
      final outside = LeaderboardBandResult(
        categoryKey: 'flag',
        difficulty: 'easy',
        rank: 101,
        score: 49,
        band: LeaderboardBand.outsideTop100,
        sampledEntries: 100,
      );

      expect(top.isTop100, isTrue);
      expect(outside.isTop100, isFalse);
    });

    test(
      'sort comparator applies score then updatedAt then uid tie-breakers',
      () {
        final first = LeaderboardEntry(
          uid: 'u2',
          score: 10,
          updatedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
          isAnonymous: false,
        );
        final second = LeaderboardEntry(
          uid: 'u1',
          score: 10,
          updatedAt: DateTime.utc(2025, 1, 1, 10, 0, 0),
          isAnonymous: false,
        );
        final third = LeaderboardEntry(
          uid: 'u3',
          score: 12,
          updatedAt: DateTime.utc(2025, 1, 1, 9, 0, 0),
          isAnonymous: false,
        );

        final entries = [first, second, third]
          ..sort(LeaderboardBandService.compareLeaderboardEntries);

        expect(entries.map((e) => e.uid).toList(), ['u3', 'u1', 'u2']);
      },
    );

    test('computes top10 band for strong candidate score', () async {
      final service = LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 30),
      );

      final result = await service.getBandForScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 200,
        candidateUid: 'candidate',
        candidateUpdatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
      );

      expect(result.rank, lessThanOrEqualTo(10));
      expect(result.band, LeaderboardBand.top10);
    });

    test(
      'uses nowProvider when candidateUpdatedAt is omitted for candidate row',
      () async {
        final now = DateTime.utc(2025, 1, 1, 12, 0, 0);
        final service = LeaderboardBandService(
          nowProvider: () => now,
          entriesLoader:
              ({
                required categoryKey,
                required difficulty,
                required limit,
              }) async => [
                LeaderboardEntry(
                  uid: 'u-a',
                  score: 50,
                  updatedAt: now,
                  isAnonymous: false,
                ),
              ],
        );

        final result = await service.getBandForScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: 50,
          candidateUid: 'candidate',
        );

        expect(result.rank, 1);
        expect(result.band, LeaderboardBand.top10);
      },
    );

    test('computes top20 band for mid candidate score', () async {
      final service = LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 30),
      );

      final result = await service.getBandForScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 86,
        candidateUid: 'candidate',
        candidateUpdatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
      );

      expect(result.rank, greaterThan(10));
      expect(result.rank, lessThanOrEqualTo(20));
      expect(result.band, LeaderboardBand.top20);
    });

    test('computes top100 band for lower candidate score', () async {
      final service = LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 90),
      );

      final result = await service.getBandForScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 5,
        candidateUid: 'candidate',
        candidateUpdatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
      );

      expect(result.rank, greaterThan(20));
      expect(result.rank, lessThanOrEqualTo(100));
      expect(result.band, LeaderboardBand.top100);
    });

    test(
      'computes outsideTop100 when candidate does not reach sampled board',
      () async {
        final service = LeaderboardBandService(
          entriesLoader:
              ({
                required categoryKey,
                required difficulty,
                required limit,
              }) async => _seededEntries(count: 100),
        );

        final result = await service.getBandForScore(
          categoryKey: 'flag',
          difficulty: 'easy',
          score: -1,
          candidateUid: 'candidate',
          candidateUpdatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
        );

        expect(result.rank, greaterThan(100));
        expect(result.band, LeaderboardBand.outsideTop100);
      },
    );

    test('replaces existing candidate entry before ranking', () async {
      final service = LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => [
              LeaderboardEntry(
                uid: 'candidate',
                score: 12,
                updatedAt: DateTime.utc(2025, 1, 1, 5, 0, 0),
                isAnonymous: true,
              ),
              ..._seededEntries(count: 20),
            ],
      );

      final result = await service.getBandForScore(
        categoryKey: 'flag',
        difficulty: 'easy',
        score: 95,
        candidateUid: 'candidate',
        candidateUpdatedAt: DateTime.utc(2025, 1, 1, 0, 0, 0),
      );

      expect(result.rank, lessThanOrEqualTo(10));
      expect(result.band, LeaderboardBand.top10);
    });
  });
}

List<LeaderboardEntry> _seededEntries({required int count}) {
  return List.generate(count, (index) {
    final rank = index + 1;
    return LeaderboardEntry(
      uid: 'u$rank',
      score: 101 - rank,
      updatedAt: DateTime.utc(2025, 1, 1, 0, rank, 0),
      isAnonymous: false,
      displayName: 'User$rank',
    );
  });
}
