#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

MIN_UNIT_COVERAGE="${MIN_UNIT_COVERAGE:-25}"
RUN_REVIEW_AGENT="${RUN_REVIEW_AGENT:-1}"
RUN_ANALYZE="${RUN_ANALYZE:-1}"
RUN_WIDGET_TESTS="${RUN_WIDGET_TESTS:-1}"
RUN_UNIT_COVERAGE="${RUN_UNIT_COVERAGE:-1}"
RUN_FIRESTORE_RULES="${RUN_FIRESTORE_RULES:-0}"
RUN_RELEASE_CONFIG_CHECKS="${RUN_RELEASE_CONFIG_CHECKS:-1}"

run_step() {
  local title="$1"
  shift
  echo
  echo "==> ${title}"
  "$@"
}

assert_file_exists() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}"
    exit 1
  fi
}

check_release_config() {
  echo "Validating release configuration and documentation prerequisites..."

  assert_file_exists "docs/legal/PRIVACY_POLICY.md"
  assert_file_exists "docs/legal/TERMS_OF_SERVICE.md"
  assert_file_exists "docs/RELEASE_OPS_RUNBOOK.md"
  assert_file_exists "docs/BLAZE_FEATURE_FLAGS.md"
  assert_file_exists "docs/APPLE_SIGN_IN_SETUP.md"
  assert_file_exists "docs/ROADMAP.md"
  assert_file_exists "lib/config/app_config.dart"
  assert_file_exists "test/unit/config/app_config_test.dart"

  if ! rg -q "Manual pre-deployment checklist" docs/ROADMAP.md; then
    echo "Expected manual pre-deployment checklist section in docs/ROADMAP.md"
    exit 1
  fi

  if ! rg -q "ENABLE_APPLE_SIGN_IN=false" docs/ROADMAP.md; then
    echo "Expected MVP fallback note for ENABLE_APPLE_SIGN_IN=false in docs/ROADMAP.md"
    exit 1
  fi

  run_step \
    "Validate app config feature-flag defaults" \
    flutter test test/unit/config/app_config_test.dart
}

run_step "Install Flutter dependencies" flutter pub get

if [[ "${RUN_RELEASE_CONFIG_CHECKS}" == "1" ]]; then
  run_step "Validate release configuration baseline" check_release_config
fi

if [[ "${RUN_REVIEW_AGENT}" == "1" ]]; then
  run_step \
    "Run review agent (fail on errors)" \
    python3 tools/review_agent.py --emit-annotations --fail-on error
fi

if [[ "${RUN_ANALYZE}" == "1" ]]; then
  run_step "Run static analysis" flutter analyze
fi

if [[ "${RUN_WIDGET_TESTS}" == "1" ]]; then
  run_step "Run widget tests" flutter test test/widget
fi

if [[ "${RUN_UNIT_COVERAGE}" == "1" ]]; then
  run_step \
    "Enforce unit coverage gate (${MIN_UNIT_COVERAGE}%)" \
    env MIN_UNIT_COVERAGE="${MIN_UNIT_COVERAGE}" ./tools/check_unit_coverage.sh
fi

if [[ "${RUN_FIRESTORE_RULES}" == "1" ]]; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required when RUN_FIRESTORE_RULES=1"
    exit 1
  fi

  pushd firestore_tests >/dev/null
  run_step "Install Firestore rules test dependencies" npm ci
  run_step \
    "Run Firestore rules emulator tests" \
    env FIREBASE_SKIP_UPDATE_CHECK=true npm run test:emulator
  popd >/dev/null
fi

echo
echo "Release preflight passed."
