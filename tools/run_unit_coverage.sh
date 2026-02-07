#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "Running unit tests with coverage..."
flutter test test/unit --coverage

if command -v genhtml >/dev/null 2>&1; then
  echo "Generating HTML coverage report..."
  genhtml coverage/lcov.info -o coverage/html >/dev/null
  echo "Coverage reports:"
  echo "- LCOV: coverage/lcov.info"
  echo "- HTML: coverage/html/index.html"
else
  echo "Coverage report generated at coverage/lcov.info"
  echo "Install lcov (genhtml) to generate an HTML report."
fi
