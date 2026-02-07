## Quick orientation for AI coding agents

This repo is a single-package Flutter (Material 3) mobile app that uses Firebase (Auth + Firestore) for persistence and leaderboards. The goal here is to be pragmatic: change screens in `lib/screens/`, keep business logic near those screens, and follow the existing routing/auth patterns in `lib/main.dart`.

Key points
- App entry: `lib/main.dart` — initializes Firebase (`Firebase.initializeApp(...)`), performs anonymous auth, sets ColorScheme and named routes.
- Data & assets: `lib/data/flag_loader.dart`, `lib/data/flag_list.dart`, `lib/models/flag_question.dart`; flags live in `assets/flags/`.
- UI: screens live in `lib/screens/` and are registered by route name in `main.dart` (e.g., `SplashScreen.routeName`, `HomeScreen.routeName`). Keep UI logic in-screen; there is no global state manager.

Firestore & patterns (use these exact paths)
- User best scores: `users/{uid}/scores/{categoryKey}` → { bestScore, updatedAt }
- Leaderboard entries: `leaderboard/{categoryKey}/entries/{uid}` → { score, updatedAt }
- Pattern to follow: use transactions to compare-and-swap when updating `bestScore`, and use `FieldValue.serverTimestamp()` for `updatedAt` (see `README.md` for examples).

AdMob setup & patterns
- Add to pubspec.yaml: `google_mobile_ads: ^x.y.z`
- Android setup in android/app/src/main/AndroidManifest.xml:
  ```xml
  <manifest>
    <application>
      <meta-data
          android:name="com.google.android.gms.ads.APPLICATION_ID"
          android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
    </application>
  </manifest>
  ```
- iOS setup in ios/Runner/Info.plist:
  ```xml
  <dict>
    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
    <key>SKAdNetworkItems</key>
    <array>
      <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
      </dict>
    </array>
  </dict>
  ```
- Initialize in main.dart:
  ```dart
  import 'package:google_mobile_ads/google_mobile_ads.dart';
  
  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    // ... rest of initialization
  }
  ```
- Banner ad example (use test IDs during development):
  ```dart
  BannerAd(
    adUnitId: 'ca-app-pub-3940256099942544/6300978111', // test ID
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  )..load();
  ```

Integration files to check before editing Firebase code
- `firebase_options.dart` (generated)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Developer workflows (quick commands)
- Install deps: `flutter pub get`
- Run on device: `flutter run -d <device-id>`
- Launch Android emulator: `flutter emulators --launch Medium_Phone_API_36.0` (workspace task exists)
- Boot iOS Simulator: `open -a Simulator`
- Tests: `flutter test`

Debugging tips specific to this project
- Use hot reload (`r` in `flutter run`) frequently — screens are small and self-contained.
- Check `debugPrint` calls in `lib/main.dart` (auth success/failure) as primary checkpoints.
- If Firebase behaves oddly, confirm the platform config files above and that `firebase_options.dart` matches them.
- For ads: use test ad unit IDs in development, check logcat/Console for ad load failures.

Files to inspect when making changes
- `pubspec.yaml`, `README.md`, `lib/main.dart`, `lib/screens/*`, `lib/data/*`, `lib/models/*`, `assets/flags/`
- Platform manifests for ad setup: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

If anything here is unclear or you'd like me to expand a section (e.g., list of routes, per-screen summaries, or add minimal tests), tell me which part to expand and I will iterate.
## Quick orientation for AI coding agents

This file gives focused, actionable guidance for working in the Quiznetic Flutter app so an AI agent can be productive immediately.

### Big-picture architecture
- Flutter mobile app (Material 3), single-package app in `lib/` using Flutter routes (see `lib/main.dart`).
- Firebase-backed: app initializes Firebase in `lib/main.dart` (see `Firebase.initializeApp(...)`) and attempts anonymous auth (`firebase_auth`).
- Firestore is used for persistent user scores and leaderboards. See `README.md` Firestore schema:
  - `users/{uid}/scores/{categoryKey}` → { bestScore, updatedAt }
  - `leaderboard/{categoryKey}/entries/{uid}` → { score, updatedAt }
- UI is split into screens under `lib/screens/` (e.g. `home_screen.dart`, `quiz_screen.dart`, `result_screen.dart`, `user_profile_screen.dart`). Navigation uses `routes` in `main.dart`.

### Key integration points & files (use these as anchors)
- Firebase config: `firebase_options.dart` (generated) + `android/app/google-services.json` + `ios/Runner/GoogleService-Info.plist`.
- App entry & init: `lib/main.dart` — handles Firebase init, anonymous sign-in, app Theme (ColorScheme), and route table.
- Data & assets: `lib/data/flag_loader.dart`, `lib/data/flag_list.dart`, `lib/models/flag_question.dart` and assets under `assets/flags/` and `assets/images/`.
- Screens: `lib/screens/*` — each screen is a self-contained Stateful/Stateless widget and registered by route name in `main.dart`.

### Project-specific conventions and patterns
- Keep UI logic inside screen widgets in `lib/screens/`; business logic is lightweight and found near related screens (no global state management libraries present).
- Routing: use named routes defined in `main.dart` (e.g. `SplashScreen.routeName`, `HomeScreen.routeName`). Follow that pattern when adding screens.
- Firebase usage:
  - Initialize once in `main()` via `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  - The app uses anonymous sign-in by default; handle auth failures gracefully (see `main.dart` try/catch example).
- Assets: flags are stored in `assets/flags/` and referenced by the loader in `lib/data/`; add new flags by adding files and updating the loader/list if necessary.

### Build, run, and test commands (examples)
- Install dependencies: `flutter pub get` (run in repo root).
- Run on connected device: `flutter run -d <device-id>` (common devices: `flutter devices`).
- Launch Android emulator (project contains a workspace task): `flutter emulators --launch Medium_Phone_API_36.0` or use IDE task "Launch Android Emulator".
- Boot iOS Simulator: `open -a Simulator` or use provided IDE task "Boot & Launch iOS Simulator".
- Run unit/widget tests: `flutter test`.
- Build release APK: `flutter build apk`; iOS: `flutter build ios` (Xcode/mac machine required).

### Debugging hints
- Hot reload is supported; use `r` in `flutter run` or IDE hot reload.
- Look at debug prints emitted in `main.dart` during auth (`debugPrint('✅ Signed in as ...')`, auth error prints) as helpful checkpoints.
- For Firebase issues, confirm platform config files are present (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) and that `firebase_options.dart` matches the project.

### Code examples to reference
- Firebase init + anonymous auth (exact location): `lib/main.dart` top of `main()`.
- Firestore schema: `README.md` top-level section "Firestore schema".
- Routes & theme: `lib/main.dart` — shows how ColorScheme is built and routes are wired.

### Firestore query examples
Below are compact, copy-paste-friendly Dart examples using `cloud_firestore` (used in this project). These show common patterns used by the app: reading/updating a user's best score and maintaining the leaderboard.

- Imports you'll need:

  ```dart
  import 'package:cloud_firestore/cloud_firestore.dart';
  final db = FirebaseFirestore.instance;
  ```

- Write/update a user's best score (only replace if new score is higher — use a transaction to avoid races):

  ```dart
  final userScoreRef = db.collection('users').doc(uid).collection('scores').doc(categoryKey);
  await db.runTransaction((tx) async {
    final snapshot = await tx.get(userScoreRef);
    final current = snapshot.exists ? (snapshot.data()!['bestScore'] as int? ?? 0) : 0;
    if (score > current) {
      tx.set(userScoreRef, {
        'bestScore': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  });
  ```

- Update leaderboard entry (simple upsert):

  ```dart
  final leaderboardRef = db.collection('leaderboard').doc(categoryKey).collection('entries').doc(uid);
  await leaderboardRef.set({
    'score': score,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  ```

- Read top N entries for a category (descending by score):

  ```dart
  final top = await db
      .collection('leaderboard')
      .doc(categoryKey)
      .collection('entries')
      .orderBy('score', descending: true)
      .limit(10)
      .get();

  final results = top.docs.map((d) => {
    'uid': d.id,
    'score': d['score'],
    'updatedAt': d['updatedAt'],
  }).toList();
  ```

- Read a user's best score for a category:

  ```dart
  final doc = await db.collection('users').doc(uid).collection('scores').doc(categoryKey).get();
  if (doc.exists) {
    final best = doc.data()!['bestScore'];
  }
  ```

- Notes / best-practices applicable to this repo:
  - Use transactions when you must atomically compare-and-swap (bestScore update).
  - Use `FieldValue.serverTimestamp()` for `updatedAt` to keep leaderboard ordering consistent.
  - Paths in this repo follow the two-tier pattern: `users/{uid}/scores/{categoryKey}` and `leaderboard/{categoryKey}/entries/{uid}` (see `README.md`).

### Useful files to inspect when making changes
- `pubspec.yaml` — dependencies (Firebase, Firestore, shared_preferences, flutter_lints).
- `lib/main.dart`, `lib/screens/*`, `lib/data/*`, `lib/models/*`.
- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — Firebase platform configs.

### What not to assume
- There is no global state management package (Provider, Riverpod, Bloc). Expect screen-local state and simple API calls.
- Tests are present only via `flutter_test` dev-dependency; there are no extensive CI configs in repo for tests—run them locally.

If anything above is unclear or you want more detail (e.g. a summary of each screen file, list of routes, or sample Firestore queries used), tell me which area to expand and I will iterate.
