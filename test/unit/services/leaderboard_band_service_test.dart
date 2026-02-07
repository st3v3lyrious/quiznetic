import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';

void main() {
  group('LeaderboardBandService', () {
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
