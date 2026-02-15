#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

MIN_UNIT_COVERAGE="${MIN_UNIT_COVERAGE:-25}"

mkdir -p coverage
rm -f coverage/lcov.info

echo "Running unit tests with coverage..."
flutter test test/unit --coverage

if [[ ! -f "coverage/lcov.info" ]]; then
  echo "Coverage file not found: coverage/lcov.info"
  exit 1
fi

read -r lines_hit lines_found < <(
  awk -F: '
    /^LH:/ { hit += $2 }
    /^LF:/ { found += $2 }
    END { printf "%d %d\n", hit, found }
  ' coverage/lcov.info
)

coverage_percent="$(
  awk -v hit="${lines_hit}" -v found="${lines_found}" '
    BEGIN {
      if (found == 0) {
        printf "0.00"
      } else {
        printf "%.2f", (hit / found) * 100
      }
    }
  '
)"

echo "Unit coverage: ${coverage_percent}%"
echo "Required minimum: ${MIN_UNIT_COVERAGE}%"

if ! awk -v current="${coverage_percent}" -v minimum="${MIN_UNIT_COVERAGE}" '
  BEGIN { exit((current + 0 >= minimum + 0) ? 0 : 1) }
'; then
  echo "Coverage gate failed."
  exit 1
fi

echo "Coverage gate passed."
