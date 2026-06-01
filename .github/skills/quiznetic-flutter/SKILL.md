---
name: quiznetic-flutter
description: 'Production-ready Flutter + Firebase code for QuizNetic. Use when: writing screens, widgets, auth flows, Firestore queries, routing, AdMob integration, or any Dart code in this app. Enforces Material 3, clean architecture, centralized Firebase Auth, reusable widgets, performance-conscious patterns, no deprecated FlutterFire packages, iOS CocoaPods troubleshooting, and release/versioning guidance.'
argument-hint: 'Describe the screen, widget, or feature to build or review...'
---

# QuizNetic Flutter Skill

## When to Use
- Writing or reviewing any Dart/Flutter code in this repo
- Implementing or debugging Firebase Auth, Firestore, or AdMob
- Adding new screens or widgets
- Diagnosing iOS CocoaPods / build errors
- Preparing a release build or bumping version numbers
- Reviewing code for architecture or performance issues

## Quick Reference

| Area | Reference |
|------|-----------|
| Architecture & folder structure | [architecture.md](./references/architecture.md) |
| Firebase Auth + Firestore patterns | [firebase.md](./references/firebase.md) |
| Flutter performance rules | [performance.md](./references/performance.md) |
| iOS Pod & build troubleshooting | [ios-troubleshooting.md](./references/ios-troubleshooting.md) |
| Release & versioning | [release.md](./references/release.md) |

---

## Procedure

### 1. Understand the Request
- Is this UI, auth, data, or routing?
- Does an existing screen or widget already solve part of this? Check `lib/screens/` and `lib/widgets/` first.
- Is it a new Firebase operation? Refer to [firebase.md](./references/firebase.md) for exact path/pattern.

### 2. Place Code in the Right Layer

```
lib/
  config/         # AppConfig (env-driven), theme, constants
  data/           # Flag loader, static question data
  models/         # Pure Dart data classes (no Flutter imports)
  screens/        # One file per route; self-contained StatefulWidgets
  services/       # AdsService, AuthService, any singleton service
  widgets/        # Reusable UI components shared across screens
  main.dart       # Firebase init, anonymous auth, theme, routes
```

Rules:
- **Models** → no `import 'package:flutter/…'`. Pure Dart only.
- **Services** → no Widget tree dependencies. Return `Future<T>` or `Stream<T>`.
- **Screens** → own their local state; call services; use widgets from `lib/widgets/`.
- **Widgets** → stateless where possible; accept data via constructor, emit events via callbacks.

### 3. Follow Coding Standards

- Dart: `lowerCamelCase` for variables/methods, `UpperCamelCase` for types, `SCREAMING_SNAKE_CASE` for true constants.
- Prefer `const` constructors everywhere Flutter allows.
- Use `final` for all fields that are set once.
- Max function length: ~40 lines. Extract `_buildXxx()` helpers or dedicated widget classes.
- Do not use `dynamic`; always type explicitly.
- No `print()`; use `debugPrint()` in dev, `FirebaseCrashlytics.instance.log()` in release paths.

### 4. UI — Material 3

- Theme is defined once in `main.dart` via `ColorScheme.fromSeed(...)`. Never hardcode colors.
- Use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*` everywhere.
- Prefer `FilledButton`, `OutlinedButton`, `Card`, `NavigationBar` (M3 components) over their M2 equivalents.
- Use `SizedBox` for whitespace; avoid `Padding` nesting more than 2 levels deep.
- All scrollable lists **must** use `ListView.builder` (or `SliverList`). Never `Column` + `children: items.map(…).toList()` for dynamic content.

### 5. Performance

See [performance.md](./references/performance.md) for the full checklist. Key rules:
- `const` widgets everywhere possible.
- `ListView.builder` with `itemCount` + `itemBuilder` for any list of unknown length.
- Never call `setState` from inside `build`.
- Use `FutureBuilder`/`StreamBuilder` only where data changes; cache results locally with `setState` once loaded.
- Avoid rebuilding ancestor widgets when only leaf state changes — extract sub-widgets.

### 6. Firebase

See [firebase.md](./references/firebase.md) for full patterns. Key rules:
- One `FirebaseApp` instance, initialized in `main()`.
- Anonymous auth is the baseline; `AuthService` wraps Google/Apple sign-in flows.
- Use transactions for compare-and-swap on `bestScore`.
- Use `FieldValue.serverTimestamp()` for all `updatedAt` fields.
- Never use deprecated packages: `firebase_dynamic_links`, `firebase_ml_vision`, `cloud_functions` (unless explicitly needed).

### 7. Validate Output

Before presenting code:
- [ ] Correct `lib/` layer (model/service/screen/widget)?
- [ ] No hardcoded colors or strings (use theme / constants)?
- [ ] Lists use `ListView.builder`?
- [ ] `const` used on all eligible constructors?
- [ ] Firebase paths match schema: `users/{uid}/scores/{categoryKey}`, `leaderboard/{categoryKey}/entries/{uid}`?
- [ ] No deprecated FlutterFire packages imported?
- [ ] Dart types explicit — no `dynamic`?
