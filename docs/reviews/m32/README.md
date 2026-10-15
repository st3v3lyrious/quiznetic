# M32 — Web navigation review

This change restores hash URLs and browser back/forward navigation. It does not
close M32: production verification, Safari, Analytics dashboard receipt, legal
review and initial feedback remain separate checks.

## Behavior

- Stable pages (leaderboard, profile and settings) open directly and survive
  refresh. Leaderboard category/difficulty filters are encoded in the URL;
  changing them replaces the current history entry.
- Difficulty URLs require `?category=flag` or `?category=capital`.
- Legal documents use `?document=terms` or `?document=privacy`.
- Transient splash and authentication replacements do not add browser-history entries.
- Protected deep links retain their destination through guest entry and login,
  including refreshing the login page. Authentication persistence is awaited.
- Quiz/results are in-memory sessions. Refreshing them displays a recovery
  screen with a route back to quiz selection. It never reconstructs a result
  from URL parameters or resubmits a score. Completing a quiz replaces its route
  so a finished question cannot be replayed through the app back button.
- Unknown or incomplete links show recovery rather than a route exception.

The app keeps named Navigator calls behind Flutter's Router protocol; no routing
package or backend changes are required. The authentication guard keeps one
subscription across rebuilds, preserving open menus and active screens.

## Reproduce browser checks

Use local Firebase emulators only. The entrypoint below hardcodes the demo
project and emulator hosts and is never used by the production `lib/main.dart`.

1. Install the existing dependencies (`flutter pub get`, `npm ci` in
   `firestore_tests/` and `playwright/`, and `npx playwright install chromium`).
2. From `firestore_tests/`, run `npm run start:navigation`.
3. From the repository root, build and serve:

```sh
flutter build web --release --no-web-resources-cdn \
  --target=integration_test/web_navigation_app.dart \
  --dart-define=ENABLE_ANALYTICS=false \
  --dart-define=ENABLE_CRASH_REPORTING=false
python3 -m http.server 7357 --bind 127.0.0.1 --directory build/web
```

4. From `playwright/`, run `npm run test:navigation`.

The tests seed clearly named demo leaderboard entries in `demo-quiznetic`,
create isolated guest sessions, and check actual Auth/Firestore persistence.
The completed-quiz test counts persisted attempts before and after a results
refresh to detect duplicate submissions. Each viewport checks JavaScript page
errors. Screenshots default to `playwright/test-results/navigation/`.

If a managed browser does not trust its session proxy CA, download the Firebase
SDK modules using the environment's normal TLS trust and set `FIREBASE_SDK_CACHE`
to that directory. The optional fixture fulfills only the Firebase SDK module
requests from that verified cache; it does not disable certificate validation.
`NAVIGATION_SCREENSHOTS` can select another capture directory.

Production builds must use the normal entrypoint and the production configuration,
not the emulator build. No production deployment is part of this PR.

## Visual review

The captures in this directory show the actual app with emulator data. The red
Firebase emulator banner is a test-only indicator. Desktop is 1280×900 and mobile
is 390×844. Existing quiz, profile, settings and legal styling is preserved;
only the recovery page is new.

| Screen | Desktop | Mobile | Tablet |
| --- | --- | --- | --- |
| Leaderboard after refresh, Capital / Expert | [Capture](desktop-leaderboard-refreshed.png) | [Capture](mobile-leaderboard-refreshed.png) | [Capture](tablet-leaderboard.png) |
| Recovery after refreshing a session | [Capture](desktop-session-recovery.png) | [Capture](mobile-session-recovery.png) | [Capture](tablet-session-recovery.png) |
| Other existing screens | [Quiz results](desktop-quiz-results.png) | [Settings after refresh](mobile-settings-refreshed.png) | — |

## Recorded validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 249 tests passed.
- `tools/check_unit_coverage.sh`: 113 unit tests passed; 64.07% coverage,
  above the existing 25% minimum.
- `tools/review_agent.py --fail-on error`: no findings.
- Normal `lib/main.dart` and emulator release Web builds: passed. The existing
  SocialIcons font warning remains; production Firebase runtime credentials were
  not used for this local compile check.
- Playwright: 17 Chromium scenarios passed, with no JavaScript page errors.
  Desktop/mobile cover auth destinations, refresh, filters, back/forward, legal
  documents, malformed links and a complete 15-question quiz with exactly one
  persisted attempt after refreshing results. Tablet adds rendering checks.
- Screenshot capture uses the actual browser viewport, including the emulator
  warning where the Firebase SDK renders it. No mock UI or image editing.

Safari/WebKit, real-device browser QA, production rollout and a visual sign-off
remain pending. This change does not complete the rest of M32.
