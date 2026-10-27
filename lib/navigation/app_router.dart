import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/brand_config.dart';
import '../screens/difficulty_screen.dart';
import '../screens/entry_choice_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/legal_document_screen.dart';
import '../screens/login_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/result_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/upgrade_account_screen.dart';
import '../screens/user_profile_screen.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_consent_panel.dart';
import '../widgets/auth_guard.dart';

/// Browser locations contain navigation context, never scores or quiz answers.
class AppLocation {
  const AppLocation(this.uri, {this.arguments, this.needsRecovery = false});

  final Uri uri;
  final Object? arguments;
  final bool needsRecovery;

  static const paths = {
    '/splash',
    '/entry',
    '/login',
    '/home',
    '/leaderboard',
    '/difficulty',
    '/quiz',
    '/result',
    '/profile',
    '/settings',
    '/upgrade',
    '/legal/document',
  };

  static bool _category(String? value) => value == 'flag' || value == 'capital';
  static bool _difficulty(String? value) =>
      const {'easy', 'intermediate', 'expert'}.contains(value);

  static AppLocation resolve(RouteSettings settings) {
    var uri = Uri.tryParse(settings.name ?? '/') ?? Uri(path: '/');
    if (uri.path == '/' || uri.path.isEmpty) uri = Uri(path: '/splash');
    final path = uri.path;
    final query = <String, String>{};
    Object? args = settings.arguments;
    var recovery = !paths.contains(path) || uri.hasScheme || uri.hasAuthority;

    if (path == '/leaderboard') {
      final category = args is LeaderboardScreenArgs
          ? args.categoryKey
          : uri.queryParameters['category'];
      final difficulty = args is LeaderboardScreenArgs
          ? args.difficulty
          : uri.queryParameters['difficulty'];
      if (_category(category)) query['category'] = category!;
      if (_difficulty(difficulty)) query['difficulty'] = difficulty!;
      args = LeaderboardScreenArgs(
        categoryKey: query['category'] ?? 'flag',
        difficulty: query['difficulty'] ?? 'easy',
      );
    } else if (path == '/difficulty') {
      final category = args is DifficultyScreenArgs
          ? args.categoryKey
          : uri.queryParameters['category'];
      recovery = recovery || !_category(category);
      if (!recovery) {
        query['category'] = category!;
        args = DifficultyScreenArgs(categoryKey: category);
      }
    } else if (path == '/quiz' || path == '/result') {
      // A refreshed URL cannot prove a completed attempt or restore a session.
      recovery =
          recovery ||
          (path == '/quiz'
              ? args is! QuizScreenArgs
              : args is! ResultScreenArgs);
    } else if (path == '/legal/document') {
      final document = args is LegalDocumentScreenArgs
          ? (args.assetPath == LegalDocumentScreen.privacyAssetPath
                ? 'privacy'
                : 'terms')
          : uri.queryParameters['document'];
      recovery = recovery || (document != 'privacy' && document != 'terms');
      if (!recovery) {
        query['document'] = document!;
        args = document == 'privacy'
            ? LegalDocumentScreen.privacyArgs
            : LegalDocumentScreen.termsArgs;
      }
    } else if (path == '/login' || path == '/entry') {
      final next = args is String ? args : uri.queryParameters['next'];
      final destination = Uri.tryParse(next ?? '');
      if (destination != null &&
          !destination.hasScheme &&
          !destination.hasAuthority &&
          paths.contains(destination.path) &&
          !const {'/login', '/entry', '/splash'}.contains(destination.path)) {
        query['next'] = destination.toString();
        args = destination.toString();
      } else {
        args = null;
      }
    }
    return AppLocation(
      Uri(path: path, queryParameters: query.isEmpty ? null : query),
      arguments: args,
      needsRecovery: recovery,
    );
  }
}

class AppRouteParser extends RouteInformationParser<Uri> {
  const AppRouteParser();

  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(routeInformation.uri);

  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    final next = configuration.queryParameters['next'];
    // Flutter Web decodes the complete reported URI before writing history.
    // Protect the nested destination so its '&' stays inside `next` on reload.
    return RouteInformation(
      uri: next == null
          ? configuration
          : configuration.replace(
              queryParameters: {
                ...configuration.queryParameters,
                'next': Uri.encodeComponent(next),
              },
            ),
    );
  }
}

/// Bridges existing named navigation to Router's browser history protocol.
/// Back navigation reuses retained routes; forward visits rebuild stable pages.
class AppRouter extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  AppRouter({required this.routes, this.observers = const []}) {
    _observer = _HistoryObserver(this);
  }

  final Map<String, WidgetBuilder> routes;
  final List<NavigatorObserver> observers;
  late final _HistoryObserver _observer;
  final List<Route<dynamic>> _history = [];
  final Map<Route<dynamic>, Uri> _locations = {};
  Uri _initial = Uri(path: '/splash');
  bool _started = false;
  bool _notificationScheduled = false;
  bool _replacePending = true;
  bool _disposed = false;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri get currentConfiguration {
    final named = _history.where((route) => route.settings.name != null);
    final location = named.isEmpty ? _initial : _location(named.last);
    // Splash is transient startup UI, not a destination in browser history.
    return location.path == '/splash' ? Uri(path: '/') : location;
  }

  Uri _location(Route<dynamic> route) =>
      _locations[route] ?? Uri.parse(route.settings.name!);

  void updateLeaderboardScope(
    BuildContext context,
    String category,
    String difficulty,
  ) {
    final route = ModalRoute.of(context);
    if (route == null) return;
    _locations[route] = Uri(
      path: '/leaderboard',
      queryParameters: {'category': category, 'difficulty': difficulty},
    );
    Router.neglect(context, notifyListeners);
  }

  Route<dynamic> _route(RouteSettings settings) {
    final location = AppLocation.resolve(settings);
    final builder = routes[location.uri.path];
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: location.uri.toString(),
        arguments: location.arguments,
      ),
      builder: location.needsRecovery || builder == null
          ? (_) => NavigationRecoveryScreen(path: location.uri.path)
          : builder,
    );
  }

  void _changed({bool replace = false}) {
    _replacePending = _replacePending || replace;
    if (_notificationScheduled || _disposed) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      final replace = _replacePending;
      _replacePending = false;
      if (_disposed) return;
      final context = navigatorKey.currentContext;
      if (replace && context != null) {
        Router.neglect(context, notifyListeners);
      } else {
        notifyListeners();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    if (!_started) {
      _initial = configuration;
      return;
    }
    final target = AppLocation.resolve(
      RouteSettings(name: configuration.toString()),
    ).uri;
    if (target == currentConfiguration) return;
    final existing = _history.where(
      (r) => r.settings.name != null && _location(r) == target,
    );
    if (existing.isNotEmpty) {
      navigatorKey.currentState!.popUntil((r) => r == existing.last);
    } else {
      navigatorKey.currentState!.pushNamed(target.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    initialRoute: _initial.toString(),
    onGenerateInitialRoutes: (_, name) {
      _started = true;
      final target = AppLocation.resolve(RouteSettings(name: name));
      return [
        if (!const {
          '/splash',
          '/home',
          '/entry',
          '/login',
          '/legal/document',
        }.contains(target.uri.path))
          _route(const RouteSettings(name: '/home')),
        _route(RouteSettings(name: name)),
      ];
    },
    onGenerateRoute: _route,
    observers: [_observer, ...observers],
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _HistoryObserver extends NavigatorObserver {
  _HistoryObserver(this.router);
  final AppRouter router;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._history.add(route);
    if (route.settings.name != null) router._changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._history.remove(route);
    router._locations.remove(route);
    if (route.settings.name != null) router._changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    router._history.remove(route);
    router._locations.remove(route);
    if (route.settings.name != null) router._changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : router._history.indexOf(oldRoute);
    router._locations.remove(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        router._history.removeAt(index);
      } else {
        router._history[index] = newRoute;
      }
    }
    if (oldRoute?.settings.name != null || newRoute?.settings.name != null) {
      router._changed(replace: true);
    }
  }
}

class NavigationRecoveryScreen extends StatelessWidget {
  const NavigationRecoveryScreen({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final session = path == '/quiz' || path == '/result';
    return Scaffold(
      appBar: AppBar(title: const Text(BrandConfig.appName)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  session
                      ? 'This session is no longer available'
                      : 'Choose a quiz to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  session
                      ? 'After refreshing or opening a session link, start a new quiz. Your saved scores are kept.'
                      : 'This link is incomplete or unavailable. You can choose a quiz from the home screen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    HomeScreen.routeName,
                    (_) => false,
                  ),
                  child: const Text('Choose a Quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key, required this.theme});
  final ThemeData theme;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  late final AppRouter _router = AppRouter(
    observers: [AnalyticsNavigationObserver()],
    routes: {
      '/splash': (_) => const SplashScreen(),
      '/entry': (_) => const EntryChoiceScreen(),
      '/login': (_) => const LoginScreen(),
      '/home': (_) => const AuthGuard(child: HomeScreen()),
      '/leaderboard': (_) => AuthGuard(
        child: Builder(
          builder: (context) => LeaderboardScreen(
            onScopeChanged: (category, difficulty) =>
                _router.updateLeaderboardScope(context, category, difficulty),
          ),
        ),
      ),
      '/difficulty': (_) => const AuthGuard(child: DifficultyScreen()),
      '/quiz': (_) => const AuthGuard(child: QuizScreen()),
      '/result': (_) => const AuthGuard(child: ResultScreen()),
      '/profile': (_) => const AuthGuard(child: UserProfileScreen()),
      '/settings': (_) => const AuthGuard(child: SettingsScreen()),
      '/upgrade': (_) => const AuthGuard(child: UpgradeAccountScreen()),
      '/legal/document': (_) => const LegalDocumentScreen(),
    },
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: BrandConfig.appName,
    theme: widget.theme,
    builder: (context, child) => kIsWeb
        ? AnalyticsConsentPanel(
            onPrivacy: () => _router.navigatorKey.currentState!.pushNamed(
              LegalDocumentScreen.routeName,
              arguments: LegalDocumentScreen.privacyArgs,
            ),
            child: child ?? const SizedBox.shrink(),
          )
        : child ?? const SizedBox.shrink(),
    routerDelegate: _router,
    routeInformationParser: const AppRouteParser(),
  );
}
