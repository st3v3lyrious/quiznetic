import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/services/score_service.dart';

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

  testWidgets('guest profile CTA completes upgrade and hides CTA', (
    tester,
  ) async {
    User currentUser = _FakeUser(uid: 'guest-profile-int', isAnonymous: true);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          UpgradeAccountScreen.routeName: (_) => _UpgradeCompleteProbe(
            onComplete: () {
              // Simulate anonymous-account linking: same uid, no longer anonymous.
              currentUser = _FakeUser(
                uid: 'guest-profile-int',
                isAnonymous: false,
              );
            },
          ),
        },
        home: UserProfileScreen(
          scoreLoader: () async => [
            CategoryScore(
              categoryKey: 'flag',
              difficulty: 'easy',
              highScore: 86,
            ),
          ],
          authService: AuthService(currentUserProvider: () => currentUser),
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
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('guest-profile-conversion-cta')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('guest-profile-conversion-cta-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('complete-upgrade'), findsOneWidget);

    await tester.tap(find.text('complete-upgrade'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-profile-conversion-cta')), findsNothing);
    expect(currentUser.uid, equals('guest-profile-int'));
    expect(currentUser.isAnonymous, isFalse);
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

class _UpgradeCompleteProbe extends StatelessWidget {
  final VoidCallback onComplete;

  const _UpgradeCompleteProbe({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            onComplete();
            Navigator.of(context).pop();
          },
          child: const Text('complete-upgrade'),
        ),
      ),
    );
  }
}
