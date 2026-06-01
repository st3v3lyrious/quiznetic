# Architecture & Folder Structure

## Folder Layout

```text
lib/
  config/
    app_config.dart        # Env-driven values (--dart-define-from-file=.env)
  data/
    flag_list.dart         # Static data, no business logic
    flag_loader.dart       # Asset loading helpers
  models/
    flag_question.dart     # Pure Dart: no Flutter imports
  screens/
    splash_screen.dart
    home_screen.dart
    quiz_screen.dart
    result_screen.dart
    user_profile_screen.dart
    leaderboard_screen.dart
  services/
    ads_service.dart       # Google Mobile Ads lifecycle
    auth_service.dart      # Wraps FirebaseAuth, Google/Apple sign-in
  widgets/
    monetized_banner_ad.dart
    # ... shared, reusable widgets only
  main.dart                # Entry point: Firebase init, auth, theme, routes
```

## Layer Rules

### `models/`

- **Pure Dart only** — zero Flutter imports.
- Immutable where possible (`final` fields, no setters).
- Include `copyWith`, `fromJson`/`toJson` only when actually needed (don't add speculatively).

```dart
// Good
class FlagQuestion {
  final String countryCode;
  final String correctAnswer;
  final List<String> choices;
  const FlagQuestion({required this.countryCode, required this.correctAnswer, required this.choices});
}
```

### `services/`

- No widget-tree dependencies (no `BuildContext` stored as field).
- Return `Future<T>` or `Stream<T>`; let screens decide how to display.
- Singletons via `static final _instance` pattern or plain top-level instances — keep it simple.

```dart
// Good: AuthService exposes clean async API
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<UserCredential?> signInWithGoogle() async { ... }
  Future<void> signOut() async => FirebaseAuth.instance.signOut();
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();
}
```

### `screens/`

- One file per named route.
- Expose `static const routeName = '/route-name';` on the class.
- Own local state (`StatefulWidget`); call services; build UI via widgets.
- No direct Firestore calls inside `build()` — load in `initState` or `FutureBuilder`.

```dart
class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
```

### `widgets/`

- Stateless where possible. Promote to `StatefulWidget` only when the widget itself owns animation or user interaction state.
- Accept data and callbacks via constructor — never read global services directly inside a widget.
- Name files `snake_case_widget.dart`; class names `UpperCamelCaseWidget`.

### `main.dart`

Contains only:

1. Firebase initialization
2. Anonymous sign-in (with try/catch)
3. `MaterialApp` with `theme` and `routes`
4. Nothing else — no business logic, no Firestore queries

## Routing

Register all routes in `main.dart` `routes` map:

```dart
routes: {
  SplashScreen.routeName: (_) => const SplashScreen(),
  HomeScreen.routeName:   (_) => const HomeScreen(),
  QuizScreen.routeName:   (_) => const QuizScreen(),
  ResultScreen.routeName: (_) => const ResultScreen(),
},
```

Navigate with `Navigator.pushNamed(context, HomeScreen.routeName)` — never with raw strings.

## Dart Conventions

| Item | Convention |
| ------ | ------------ |
| Variables / methods | `lowerCamelCase` |
| Types / classes | `UpperCamelCase` |
| Constants | `lowerCamelCase` (prefer) or `SCREAMING_SNAKE_CASE` only for true compile-time constants |
| Private members | `_prefixWithUnderscore` |
| File names | `snake_case.dart` |
| Max function body | ~40 lines; extract helpers |
| Avoid | `dynamic`, `var` (unless type is obvious from RHS), implicit `Object` |

## What NOT to Do

- Do not create a global state management package (Provider, Riverpod, Bloc) unless complexity demands it — the app uses screen-local state.
- Do not put Firestore queries directly in widget `build()` methods.
- Do not put routing logic (named strings) inline — always use `Screen.routeName`.
- Do not add abstraction layers "for the future" — solve the current problem at the simplest layer that works.
