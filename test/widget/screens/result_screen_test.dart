import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/upgrade_account_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/services/ads_service.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/services/entitlement_service.dart';
import 'package:quiznetic_flutter/services/leaderboard_band_service.dart';
import 'package:quiznetic_flutter/widgets/monetized_banner_ad.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  Future<void> pumpResult(
    WidgetTester tester, {
    required ResultScreenArgs args,
    required Future<int> Function({
      required String categoryKey,
      required String difficulty,
      required int score,
      required int totalQuestions,
    })
    saveScore,
    required Future<int> Function(String categoryKey, String difficulty)
    getHighScore,
    AuthService? authService,
    LeaderboardBandService? leaderboardBandService,
    WidgetBuilder? upgradeRouteBuilder,
    AdsService? adsService,
    EntitlementService? entitlementService,
    ResultInterstitialPresenter? presentResultInterstitialAd,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute(
            settings: RouteSettings(
              name: ResultScreen.routeName,
              arguments: args,
            ),
            builder: (_) => ResultScreen(
              saveScore: saveScore,
              getHighScore: getHighScore,
              authService: authService,
              leaderboardBandService: leaderboardBandService,
              adsService: adsService,
              entitlementService: entitlementService,
              presentResultInterstitialAd: presentResultInterstitialAd,
            ),
          ),
        ],
        routes: {
          QuizScreen.routeName: (_) => const _QuizArgsProbe(),
          DifficultyScreen.routeName: (_) => const _DifficultyArgsProbe(),
          HomeScreen.routeName: (_) => const _HomeProbe(),
          UserProfileScreen.routeName: (_) => const _ProfileProbe(),
          UpgradeAccountScreen.routeName:
              upgradeRouteBuilder ?? (_) => const _UpgradeProbe(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows missing-data placeholder when route args are absent', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ResultScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Missing result data'), findsOneWidget);
  });

  testWidgets('renders score summary and high-score message', (tester) async {
    var saveScoreCalled = false;
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 7,
        total: 10,
        difficulty: 'easy',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async {
            saveScoreCalled = true;
            return score;
          },
      getHighScore: (categoryKey, difficulty) async => 5,
    );

    expect(find.text('You scored 7 out of 10'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.textContaining('New High Score: 7!'), findsOneWidget);
    expect(find.byKey(const Key('result-summary-semantics')), findsOneWidget);
    expect(saveScoreCalled, isTrue);
  });

  testWidgets('play again button routes to quiz with expected args', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 4,
        total: 15,
        difficulty: 'intermediate',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async => 10,
      getHighScore: (categoryKey, difficulty) async => 10,
    );

    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:flag:15:intermediate'), findsOneWidget);
  });

  testWidgets('change difficulty button routes with category args', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 4,
        total: 15,
        difficulty: 'intermediate',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async => 10,
      getHighScore: (categoryKey, difficulty) async => 10,
    );

    await tester.tap(find.text('Change Difficulty'));
    await tester.pumpAndSettle();

    expect(find.text('difficulty:flag'), findsOneWidget);
  });

  testWidgets('change quiz type button routes to home', (tester) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 4,
        total: 15,
        difficulty: 'intermediate',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async => 10,
      getHighScore: (categoryKey, difficulty) async => 10,
    );

    await tester.tap(find.text('Change Quiz Type'));
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
  });

  testWidgets('blocks back navigation while on the result screen', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('base-screen')),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: ResultScreen.routeName,
          arguments: ResultScreenArgs(
            categoryKey: 'flag',
            score: 4,
            total: 15,
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
              }) async => 10,
          getHighScore: (categoryKey, difficulty) async => 10,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You scored 4 out of 15'), findsOneWidget);

    await navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('You scored 4 out of 15'), findsOneWidget);
    expect(find.text('base-screen'), findsNothing);
  });

  testWidgets('shows guest conversion CTA text for top-20 anonymous band', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 86,
        total: 100,
        difficulty: 'easy',
      ),
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
            _FakeUser(uid: 'guest123', isAnonymous: true),
      ),
      leaderboardBandService: LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 30),
      ),
    );

    expect(find.byKey(const Key('guest-conversion-cta')), findsOneWidget);
    expect(find.text("You're in the top 20 as a guest."), findsOneWidget);
    expect(find.text('Create an account to compete globally.'), findsOneWidget);
  });

  testWidgets(
    'shows outside-top100 guest message when score is below top band',
    (tester) async {
      await pumpResult(
        tester,
        args: ResultScreenArgs(
          categoryKey: 'flag',
          score: 0,
          total: 100,
          difficulty: 'easy',
        ),
        saveScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required totalQuestions,
            }) async => score,
        getHighScore: (categoryKey, difficulty) async => 20,
        authService: AuthService(
          currentUserProvider: () =>
              _FakeUser(uid: 'guest999', isAnonymous: true),
        ),
        leaderboardBandService: LeaderboardBandService(
          entriesLoader:
              ({
                required categoryKey,
                required difficulty,
                required limit,
              }) async => _seededEntries(count: 100),
        ),
      );

      expect(find.byKey(const Key('guest-conversion-cta')), findsOneWidget);
      expect(
        find.text("You're climbing the rankings as a guest."),
        findsOneWidget,
      );
      expect(
        find.text('Create an account to compete globally.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('create account CTA routes guests to upgrade screen', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 86,
        total: 100,
        difficulty: 'easy',
      ),
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
            _FakeUser(uid: 'guest-convert', isAnonymous: true),
      ),
      leaderboardBandService: LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 30),
      ),
    );

    await tester.tap(find.byKey(const Key('guest-conversion-cta-action')));
    await tester.pumpAndSettle();

    expect(find.text('upgrade-screen'), findsOneWidget);
  });

  testWidgets('hides guest CTA after successful account upgrade returns', (
    tester,
  ) async {
    User currentUser = _FakeUser(uid: 'guest-active', isAnonymous: true);

    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 86,
        total: 100,
        difficulty: 'easy',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async => score,
      getHighScore: (categoryKey, difficulty) async => 90,
      authService: AuthService(currentUserProvider: () => currentUser),
      leaderboardBandService: LeaderboardBandService(
        entriesLoader:
            ({
              required categoryKey,
              required difficulty,
              required limit,
            }) async => _seededEntries(count: 30),
      ),
      upgradeRouteBuilder: (_) => _UpgradeCompleteProbe(
        onComplete: () {
          currentUser = _FakeUser(uid: 'account-active', isAnonymous: false);
        },
      ),
    );

    expect(find.byKey(const Key('guest-conversion-cta')), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest-conversion-cta-action')));
    await tester.pumpAndSettle();

    expect(find.text('complete-upgrade'), findsOneWidget);
    await tester.tap(find.text('complete-upgrade'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-conversion-cta')), findsNothing);
  });

  testWidgets(
    'keeps result banner hidden when result interstitial shows successfully',
    (tester) async {
      await pumpResult(
        tester,
        args: ResultScreenArgs(
          categoryKey: 'flag',
          score: 6,
          total: 10,
          difficulty: 'easy',
        ),
        saveScore:
            ({
              required categoryKey,
              required difficulty,
              required score,
              required totalQuestions,
            }) async => score,
        getHighScore: (categoryKey, difficulty) async => 9,
        adsService: AdsService(
          enabled: true,
          resultInterstitialEnabled: true,
          androidBannerUnitId: '',
          iosBannerUnitId: '',
          androidHomeBannerUnitId: '',
          iosHomeBannerUnitId: '',
          androidResultBannerUnitId: 'android-result-banner',
          iosResultBannerUnitId: '',
          androidResultInterstitialUnitId:
              'ca-app-pub-3940256099942544/1033173712',
          iosResultInterstitialUnitId: '',
          supportsAds: () => true,
          initializeAdsSdk: () async => null,
        ),
        entitlementService: EntitlementService(initialRemoveAds: false),
        presentResultInterstitialAd: (_) async => true,
      );

      expect(find.byType(MonetizedBannerAd), findsNothing);
    },
  );

  testWidgets('falls back to result banner when result interstitial fails', (
    tester,
  ) async {
    await pumpResult(
      tester,
      args: ResultScreenArgs(
        categoryKey: 'flag',
        score: 6,
        total: 10,
        difficulty: 'easy',
      ),
      saveScore:
          ({
            required categoryKey,
            required difficulty,
            required score,
            required totalQuestions,
          }) async => score,
      getHighScore: (categoryKey, difficulty) async => 9,
      adsService: AdsService(
        enabled: true,
        resultInterstitialEnabled: true,
        androidBannerUnitId: '',
        iosBannerUnitId: '',
        androidHomeBannerUnitId: '',
        iosHomeBannerUnitId: '',
        androidResultBannerUnitId: 'android-result-banner',
        iosResultBannerUnitId: '',
        androidResultInterstitialUnitId:
            'ca-app-pub-3940256099942544/1033173712',
        iosResultInterstitialUnitId: '',
        supportsAds: () => true,
        initializeAdsSdk: () async => null,
      ),
      entitlementService: EntitlementService(initialRemoveAds: false),
      presentResultInterstitialAd: (_) async => false,
    );

    expect(find.byType(MonetizedBannerAd), findsOneWidget);
  });
}

class _QuizArgsProbe extends StatelessWidget {
  const _QuizArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizScreenArgs;
    return Scaffold(
      body: Text(
        'quiz:${args.categoryKey}:${args.flagsPerSession}:${args.difficulty}',
      ),
    );
  }
}

class _DifficultyArgsProbe extends StatelessWidget {
  const _DifficultyArgsProbe();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as DifficultyScreenArgs;
    return Scaffold(body: Text('difficulty:${args.categoryKey}'));
  }
}

class _ProfileProbe extends StatelessWidget {
  const _ProfileProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('profile-screen'));
  }
}

class _HomeProbe extends StatelessWidget {
  const _HomeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home-screen'));
  }
}

class _UpgradeProbe extends StatelessWidget {
  const _UpgradeProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('upgrade-screen'));
  }
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
