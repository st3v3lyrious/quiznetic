#!/usr/bin/env bash
set -euo pipefail

echo "Resolving dependencies..."
flutter pub get

echo "Generating launcher icons..."
dart run flutter_launcher_icons

echo "Generating native splash screens..."
dart run flutter_native_splash:create

echo "Branding assets refreshed."
