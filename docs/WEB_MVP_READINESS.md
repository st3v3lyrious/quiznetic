# Web MVP readiness

## Compatibility audit — September 26, 2026

CrashReportingService now skips every Crashlytics operation on Web, including
collection configuration when the feature flag is off. It preserves Flutter's
existing framework error handler. Analytics keeps collection, product events and
screen views; Crashlytics breadcrumbs are suppressed on Web and when native crash
reporting is disabled. Other native Crashlytics behavior remains covered by tests.

The installed Crashlytics plugin declares Android, iOS and macOS implementations,
but no Web implementation. Firebase's platform matrix is the reference:
https://firebase.google.com/docs/flutter/setup#available-plugins

The app has no dart:io or Platform calls in lib/. FirebaseUI's Web OAuth path
uses Firebase Auth signInWithPopup/linkWithPopup. Its production domain/provider
configuration and real login still need validation.

## Checks completed

- 19 targeted Crashlytics, Analytics and Firebase configuration tests pass.
- Full release preflight passes: static analysis, review checks, widget tests,
  unit tests and the unit coverage gate (27.29%, minimum 25%).
- Release build passes with the existing registered Firebase Web app and root
  base href. The local API key was missing and has been filled from Firebase's
  read-only SDK configuration response. No environment values are committed.
- Chromium loads the entry and login screens without JavaScript exceptions.
- Email and Google controls render; login was checked at desktop size and
  390 × 844. Browser back returns from login to entry.

The compiler reports a missing SocialIcons font. The Google icon renders in the
tested login screen; other provider/icon surfaces have not been fully audited.

These checks do not validate actual sign-in, account linking, Firestore writes,
quiz completion, analytics delivery or a public deployment. No public deployment
was performed. The root base href is provisional pending the final public URL.

## Owner actions before deployment

1. Choose the exact public hostname. A dedicated subdomain is recommended; for a
   path such as /quiznetic/, rebuild with that path as the base href.
2. Confirm where that hostname will be hosted and arrange its DNS record once
   the hosting target is known.
3. In Firebase Console, Authentication → Settings → Authorized domains, add
   the preview and production hostnames. Confirm Email/Password and Google are
   enabled under Sign-in method. Keep the support email current.
4. If using a custom OAuth authDomain, complete Firebase's custom-domain setup
   and authorize its exact callback in Google Cloud; do not change authDomain
   merely because the app is hosted on a new domain.
5. After preview deployment, test Email and Google with a real test account and
   verify upgrade continuity, quiz completion, score sync and leaderboard.

Firebase Web auth reference:
https://firebase.google.com/docs/auth/web/google-signin

## Remaining launch checks

- Production URL and hosting/base-href decision.
- Public-domain OAuth, browser refresh and direct-route behavior.
- Real device/browser matrix, including Safari and mobile browsers.
- Flags/Capitals, guest/account, score and leaderboard end-to-end checks.
- Web analytics events received and ad-free privacy/legal copy reviewed.
- Deployed Firestore security and leaderboard abuse exposure (M20).
- Preview deployment, rollback and public release.

Rebuild locally with the ignored configuration file:

```bash
flutter build web --release --dart-define-from-file=.env --base-href=/
python3 -m http.server 7357 --bind 127.0.0.1 --directory build/web
```
