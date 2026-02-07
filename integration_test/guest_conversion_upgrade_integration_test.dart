import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest CTA opens upgrade flow from result screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: ResultScreen.routeName,
              arguments: ResultScreenArgs(
                categoryKey: 'flag',
                score: 86,
                total: 100,
                difficulty: 'easy',
              ),
            ),
            builder: (_) => ResultScreen(
              saveScore:
                  ({
                    required categoryKey,
                    required difficulty,
                    required score,
                    required totalQuestions,
                  }) async => score,
              getHighScore: (categoryKey, difficulty) async => 90,
              authService: AuthService(
                currentUserProvider: () =>
                    _FakeUser(uid: 'guest-int', isAnonymous: true),
              ),
              leaderboardBandService: LeaderboardBandService(
                entriesLoader:
                    ({
                      required categoryKey,
                      required difficulty,
                      required limit,
                    }) async => _seededEntries(count: 30),
              ),
            ),
          ),
        ],
        routes: {
          UpgradeAccountScreen.routeName: (_) =>
              const Scaffold(body: Text('upgrade-screen')),
        },
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guest-conversion-cta-action')));
    await tester.pumpAndSettle();

    expect(find.text('upgrade-screen'), findsOneWidget);
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

class _FakeUser implements User {
  _FakeUser({required this.uid, required this.isAnonymous});

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  String? get displayName => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
