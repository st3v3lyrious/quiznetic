#!/usr/bin/env bash
# One-off build helper for #172. Public Web configuration only; no operator credentials.
set -eu
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz -o /tmp/quiznetic-flutter.tar.xz
printf '%s  %s\n' af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230 /tmp/quiznetic-flutter.tar.xz | sha256sum -c -
mkdir -p /tmp/quiznetic-sdk
tar -xf /tmp/quiznetic-flutter.tar.xz -C /tmp/quiznetic-sdk
git config --global --add safe.directory /tmp/quiznetic-sdk/flutter
/tmp/quiznetic-sdk/flutter/bin/flutter config --no-analytics
/tmp/quiznetic-sdk/flutter/bin/flutter build web --release --dart-define=ENABLE_ANALYTICS=true '--dart-define=FIREBASE_WEB_API_KEY=AIzaSyBp3WPInwQh_1gw_EmRCaD_aNWOcJW3pPw' '--dart-define=FIREBASE_WEB_APP_ID=1:989742825315:web:87d554d851ed89a717dd56' '--dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=989742825315' '--dart-define=FIREBASE_WEB_PROJECT_ID=quiznetic-30734' '--dart-define=FIREBASE_WEB_AUTH_DOMAIN=quiznetic-30734.firebaseapp.com' '--dart-define=FIREBASE_WEB_STORAGE_BUCKET=quiznetic-30734.firebasestorage.app' '--dart-define=FIREBASE_WEB_MEASUREMENT_ID=G-W0CM8C9NE5' '--dart-define=GOOGLE_OAUTH_CLIENT_ID=989742825315-pat9hhouf3n72orn51icos861d67lpin.apps.googleusercontent.com'
