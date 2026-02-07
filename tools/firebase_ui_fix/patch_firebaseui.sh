#!/usr/bin/env bash
set -euo pipefail

# Patch script for FirebaseUI-Flutter fork
# Usage:
#   ./patch_firebaseui.sh [local-clone-path]
# If local-clone-path is omitted the script will clone your fork to ./FirebaseUI-Flutter

FORK_URL="https://github.com/st3v3lyrious/FirebaseUI-Flutter.git"
CLONE_DIR="${1:-./FirebaseUI-Flutter}"
BRANCH="fix/material-imports"

echo "Using fork: $FORK_URL"
echo "Local clone path: $CLONE_DIR"

auth_check() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git not found. Please install git." >&2
    exit 1
  fi
}

auth_check

if [ ! -d "$CLONE_DIR/.git" ]; then
  echo "Cloning fork into $CLONE_DIR"
  git clone "$FORK_URL" "$CLONE_DIR"
fi

cd "$CLONE_DIR"

echo "Fetching latest from origin..."
git fetch origin --prune

# Create/checkout branch
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git checkout "$BRANCH"
  git reset --hard origin/$BRANCH 2>/dev/null || true
else
  git checkout -b "$BRANCH"
fi

# Find candidate files that reference Brightness or ThemeData (common culprits)
echo "Searching for files referencing Brightness or ThemeData under packages/*/lib..."
mapfile -t candidates < <(grep -RIl --exclude-dir=.git -e "\bBrightness\b" -e "\bThemeData\b" packages/*/lib || true)

if [ ${#candidates[@]} -eq 0 ]; then
  echo "No candidate files found. You can still run this script against a local checkout with a path argument."
else
  echo "Found ${#candidates[@]} candidate files. Will add import if missing."
fi

patched=0
for f in "${candidates[@]}"; do
  # Only operate on Dart files
  if [[ "$f" != *.dart ]]; then
    continue
  fi

  if ! grep -q "package:flutter/material.dart" "$f"; then
    echo "Patching $f"
    # Prepend the import to the file (idempotent because we checked above)
    printf "import 'package:flutter/material.dart';\n\n" | cat - "$f" > "$f.patched" && mv "$f.patched" "$f"
    git add "$f"
    patched=$((patched+1))
  else
    echo "Skipping $f (already imports material.dart)"
  fi
done

if [ $patched -eq 0 ]; then
  echo "No files needed patching."
else
  echo "Committing $patched patched files"
  git commit -m "fix: add missing material import to avoid Brightness type errors" || true
  echo "Pushing branch $BRANCH to origin"
  git push -u origin "$BRANCH"
  echo "Patch branch pushed: $BRANCH"
fi

echo
echo "Next steps:"
echo "1) In your app repo's pubspec.yaml point firebase_ui packages to your fork and the branch 'fix/material-imports' (example in the README)."
echo "2) From your app repo run: flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ios --no-codesign"

echo
echo "If you prefer to use a specific commit hash, replace 'ref: fix/material-imports' in pubspec.yaml with the commit id after you verify builds."

exit 0
