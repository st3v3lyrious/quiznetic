# ACCESSIBILITY AUDIT

Audit date: February 14, 2026  
Scope: Flutter app UI and automated tests in this repo.

## Executive Summary

Current accessibility baseline is a solid start for MVP, but it is not full accessibility coverage yet.

- Baseline readiness estimate: `~65%` of a practical "MVP-accessible" target.
- Strengths: theme contrast checks, semantic labels on core visual assets, non-color quiz feedback, and expanded large-text coverage across critical screens.
- Biggest gap: visual quiz content still lacks optional descriptive metadata for blind/low-vision support.

## What The Baseline Currently Covers

### 1) Screen-reader semantics (partial)

- Explicit semantic labels exist for the app logo on:
  - `lib/screens/splash_screen.dart`
  - `lib/screens/entry_choice_screen.dart`
  - `lib/screens/home_screen.dart`
  - `lib/screens/login_screen.dart`
  - `lib/screens/about_screen.dart`
- Quiz question image has a semantic label in:
  - `lib/screens/quiz_screen.dart`
- Automated semantics assertions exist in:
  - `test/widget/screens/splash_screen_test.dart`
  - `test/widget/screens/entry_choice_screen_test.dart`
  - `test/widget/screens/about_screen_test.dart`
  - `test/widget/screens/quiz_screen_test.dart`

Coverage note: explicit image semantics in `6/13` screen files.

Progress update:

- Quiz question progress is now announced via a live semantic region.
- Result summary is now announced via a live semantic region.

### 2) Color contrast guardrails (good baseline)

- WCAG AA contrast checks are enforced for primary theme pairs in:
  - `test/unit/config/accessibility_contrast_test.dart`
- The test verifies contrast ratio `>= 4.5` for key foreground/background pairs.

### 3) Dynamic type / text scaling (partial)

- Large-text smoke tests at `TextScaler.linear(1.8)` exist for:
  - Entry choice
  - Settings
  - About
  - Difficulty
- Test file:
  - `test/widget/screens/accessibility_text_scaling_test.dart`

Coverage note: dynamic text explicitly tested on `4/13` screens.

Progress update:

- Large-text smoke coverage now includes `home`, `quiz`, `result`, `leaderboard`, and `profile`.
- Dynamic text is now explicitly tested on `9/13` screens.

### 4) Non-color answer feedback (new)

- Quiz now provides explicit icon + text answer state after selection:
  - `Correct` and `Incorrect` states with detailed text.
  - Includes live semantic announcement for the feedback message.
- Implemented in:
  - `lib/screens/quiz_screen.dart`

### 5) Additional helpful baseline behaviors

- Icon-only app bar actions include tooltips in multiple screens (helps discoverability and semantics).
- Legal docs use `SelectableText` in:
  - `lib/screens/legal_document_screen.dart`

## Gaps And Risks

### High Priority

- Quiz image semantics are generic, not descriptive.
  - Current label is "Quiz question image", which does not help blind or low-vision users.
- Large text is not yet covered across critical gameplay/result/ranking surfaces.
  - Remaining missing explicit tests: `login`, `upgrade`, `legal`, `splash`.

### Medium Priority

- No keyboard/focus traversal tests for web/desktop.
- No explicit high-contrast mode or reduced-motion handling.

### Low Priority

- No dedicated accessibility QA checklist/runbook in docs yet.
- No accessibility-specific user preference group in Settings.

## Color-Blind And Low-Vision Support For Flag Questions

Your idea is correct: add a way to describe the flag. The important part is to do it in a way that helps accessibility without breaking gameplay.

Recommended approach (low cost, incremental):

1. Add optional flag-description metadata.
   - New asset: `assets/metadata/flag_descriptions.json`
   - Store short descriptions with non-color cues first (layout, symbols, counts, orientation), then color words where useful.
2. Add a user setting.
   - `Settings > Accessibility > Show flag descriptions`
3. Add an in-quiz affordance.
   - In `QuizScreen`, show a secondary control like `Describe Flag`.
   - When enabled, show/read the description text under the image.
4. Keep default behavior unchanged.
   - Descriptions stay opt-in to preserve current quiz feel and leaderboard expectations.

If desired later, add an "Accessibility Assist Mode" that marks attempts separately from standard ranked attempts.

## Prioritized Improvement Plan

### Phase A (quick wins, 1-2 days)

- [x] Add non-color feedback in quiz answers (icon + text state like "Correct", "Incorrect", "Selected").
- [x] Add semantic announcements for question progress and result summary.
- [x] Add large-text tests for `home`, `quiz`, `result`, `leaderboard`, `profile`.

### Phase B (core accessibility expansion, 2-4 days)

- Ship opt-in flag description metadata and UI.
- Add accessibility preferences section in Settings (description toggle at minimum).
- Add semantics tests for high-value screens beyond image labels.

### Phase C (hardening, post-MVP)

- Keyboard/focus traversal audit and tests for web/desktop.
- High-contrast theme option and reduced-motion alignment.
- Accessibility QA runbook and regression checklist in CI process.

## Suggested Definition Of Done For "Accessible MVP+"

- All critical flows usable with screen reader without visual dependency.
- Quiz correctness is not color-only.
- Large text (`>=1.8`) works on all gameplay-critical screens.
- Flag description feature is available as opt-in accessibility support.
- Accessibility checks are documented and repeatable.
