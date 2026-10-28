#!/usr/bin/env bash
# One-off build helper for #172. Public Web configuration only; no operator credentials.
set -euo pipefail

# Configure these values in the deployment environment; keep literal values out of Git.
: "${FIREBASE_WEB_API_KEY:?Set FIREBASE_WEB_API_KEY in the deployment environment}"
: "${FIREBASE_WEB_APP_ID:?Set FIREBASE_WEB_APP_ID in the deployment environment}"
: "${FIREBASE_WEB_MESSAGING_SENDER_ID:?Set FIREBASE_WEB_MESSAGING_SENDER_ID in the deployment environment}"
: "${FIREBASE_WEB_PROJECT_ID:?Set FIREBASE_WEB_PROJECT_ID in the deployment environment}"
: "${FIREBASE_WEB_AUTH_DOMAIN:?Set FIREBASE_WEB_AUTH_DOMAIN in the deployment environment}"
: "${FIREBASE_WEB_STORAGE_BUCKET:?Set FIREBASE_WEB_STORAGE_BUCKET in the deployment environment}"
: "${FIREBASE_WEB_MEASUREMENT_ID:?Set FIREBASE_WEB_MEASUREMENT_ID in the deployment environment}"
: "${GOOGLE_OAUTH_CLIENT_ID:?Set GOOGLE_OAUTH_CLIENT_ID in the deployment environment}"

curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz -o /tmp/quiznetic-flutter.tar.xz
printf '%s  %s\n' af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230 /tmp/quiznetic-flutter.tar.xz | sha256sum -c -
mkdir -p /tmp/quiznetic-sdk
tar -xf /tmp/quiznetic-flutter.tar.xz -C /tmp/quiznetic-sdk
git config --global --add safe.directory /tmp/quiznetic-sdk/flutter
/tmp/quiznetic-sdk/flutter/bin/flutter config --no-analytics
/tmp/quiznetic-sdk/flutter/bin/flutter build web --release --dart-define=ENABLE_ANALYTICS=true "--dart-define=FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY}" "--dart-define=FIREBASE_WEB_APP_ID=${FIREBASE_WEB_APP_ID}" "--dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=${FIREBASE_WEB_MESSAGING_SENDER_ID}" "--dart-define=FIREBASE_WEB_PROJECT_ID=${FIREBASE_WEB_PROJECT_ID}" "--dart-define=FIREBASE_WEB_AUTH_DOMAIN=${FIREBASE_WEB_AUTH_DOMAIN}" "--dart-define=FIREBASE_WEB_STORAGE_BUCKET=${FIREBASE_WEB_STORAGE_BUCKET}" "--dart-define=FIREBASE_WEB_MEASUREMENT_ID=${FIREBASE_WEB_MEASUREMENT_ID}" "--dart-define=GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_OAUTH_CLIENT_ID}"
