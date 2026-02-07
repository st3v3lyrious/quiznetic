FirebaseUI Flutter - quick patch helper

What this does

- Automates creating `fix/material-imports` branch on your fork `https://github.com/st3v3lyrious/FirebaseUI-Flutter.git`.
- Scans `packages/*/lib` for files referencing `Brightness` or `ThemeData`.
- Adds `import 'package:flutter/material.dart';` to files that don't already import it.
- Commits and pushes the branch to your fork.

Why this helps

Some Firebase UI files reference `Brightness` (or other types) but omit the `package:flutter/material.dart` import, which leads to build errors when using the latest Flutter/Firebase versions. This script automates adding the missing import lines so you can use the latest dependencies.

How to use (recommended)

1. Make sure you have a fork at: https://github.com/st3v3lyrious/FirebaseUI-Flutter
   - If you haven't forked the upstream repo, open the upstream repo in your browser and click "Fork".

2. Run the patch script (you can provide a local clone path if you already cloned the fork):

```bash
# from your app repo (this repo)
cd tools/firebase_ui_fix
chmod +x patch_firebaseui.sh
./patch_firebaseui.sh

# or if you already cloned your fork somewhere else:
./patch_firebaseui.sh /path/to/local/fork
```

3. After the script finishes it will have pushed branch `fix/material-imports` to your fork.

4. Update your app `pubspec.yaml` to use your fork. Replace the firebase_ui entries with this snippet:

```yaml
# Firebase UI packages (use your fork with fixes)
firebase_ui_auth:
  git:
    url: https://github.com/st3v3lyrious/FirebaseUI-Flutter.git
    path: packages/firebase_ui_auth
    ref: fix/material-imports

firebase_ui_oauth_google:
  git:
    url: https://github.com/st3v3lyrious/FirebaseUI-Flutter.git
    path: packages/firebase_ui_oauth_google
    ref: fix/material-imports

firebase_ui_oauth_apple:
  git:
    url: https://github.com/st3v3lyrious/FirebaseUI-Flutter.git
    path: packages/firebase_ui_oauth_apple
    ref: fix/material-imports

# Recommended dependency_overrides so all firebase_ui pieces come from your fork
dependency_overrides:
  firebase_ui_shared:
    git:
      url: https://github.com/st3v3lyrious/FirebaseUI-Flutter.git
      path: packages/firebase_ui_shared
      ref: fix/material-imports
  firebase_ui_localizations:
    git:
      url: https://github.com/st3v3lyrious/FirebaseUI-Flutter.git
      path: packages/firebase_ui_localizations
      ref: fix/material-imports
```

5. Verify from your app root:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --no-codesign
# or run on emulator/device
```

Fallback: quick pub-cache patch (temporary)

If you need immediate progress and don't want to maintain a fork, you can patch your local pub-cache (what you did previously). That approach is fast but not repeatable across machines or CI.

Notes & follow-ups

- After you confirm the fork + patch works, consider replacing the branch ref with a commit hash for stability.
- If `flutter pub get` shows version constraints mismatch, open the forked packages' `pubspec.yaml` and update the firebase_* constraints to the Firebase versions you want, commit, and push — then update your app `pubspec.yaml`.

If you want, I can also:
- Prepare a PR patch (diff) that you can copy into your fork if you prefer manual application instead of the script.
- Run the patch script here if you provide a reachable fork URL/credentials (I can't push to your account).