#!/usr/bin/env bash
# Build-time configuration only; Firebase Web settings are visible to clients.
set -euo pipefail
set +x
export DASH__SUPPRESS_ANALYTICS=true FLUTTER_SUPPRESS_ANALYTICS=true

# Fail before downloading tools if the scoped Vercel configuration is incomplete.
node <<'JS'
const required = ['FIREBASE_WEB_API_KEY', 'FIREBASE_WEB_APP_ID',
  'FIREBASE_WEB_MESSAGING_SENDER_ID', 'FIREBASE_WEB_PROJECT_ID',
  'FIREBASE_WEB_AUTH_DOMAIN', 'FIREBASE_WEB_STORAGE_BUCKET',
  'FIREBASE_WEB_MEASUREMENT_ID', 'GOOGLE_WEB_CLIENT_ID'];
const missing = required.filter(key => !process.env[key]?.trim());
if (missing.length) { console.error('Missing build variables: ' + missing.join(', ')); process.exit(1); }
JS

build_tools_dir="$(mktemp -d)"
build_defines_file="$(mktemp)"
trap 'rm -rf "$build_tools_dir"; rm -f "$build_defines_file"' EXIT
export QUIZNETIC_BUILD_DEFINES_FILE="$build_defines_file"
node <<'JS'
const fs = require('node:fs');
const names = ['FIREBASE_WEB_API_KEY', 'FIREBASE_WEB_APP_ID',
  'FIREBASE_WEB_MESSAGING_SENDER_ID', 'FIREBASE_WEB_PROJECT_ID',
  'FIREBASE_WEB_AUTH_DOMAIN', 'FIREBASE_WEB_STORAGE_BUCKET',
  'FIREBASE_WEB_MEASUREMENT_ID', 'GOOGLE_WEB_CLIENT_ID'];
const config = Object.fromEntries(names.map(name => [name, process.env[name].trim()]));
config.ENABLE_ANALYTICS = 'false';
config.ENABLE_APPLE_SIGN_IN = 'false';
fs.writeFileSync(process.env.QUIZNETIC_BUILD_DEFINES_FILE, JSON.stringify(config), {mode: 0o600});
JS
curl -fsS --retry 2 'https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz' -o "$build_tools_dir/flutter.tar.xz"
printf '%s  %s\n' 'af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230' "$build_tools_dir/flutter.tar.xz" | sha256sum -c -
tar -xJf "$build_tools_dir/flutter.tar.xz" -C "$build_tools_dir"
"$build_tools_dir/flutter/bin/flutter" pub get
"$build_tools_dir/flutter/bin/flutter" build web --release --base-href / --dart-define-from-file="$build_defines_file"
