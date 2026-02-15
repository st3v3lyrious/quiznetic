# ACCESSIBILITY AUDIT

Audit date: February 15, 2026  
Scope: Flutter app UI and automated tests in this repo.

## Executive Summary

Current accessibility baseline is a solid start for MVP, but it is not full accessibility coverage yet.

- Baseline readiness estimate: `~84%` of a practical "MVP-accessible" target.
- Strengths: theme contrast checks, semantic labels on core visual assets, non-color quiz feedback, and expanded large-text coverage across critical screens.
- Biggest gap: description accuracy still needs manual visual QA despite complete metadata coverage.

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
- Opt-in flag descriptions are now supported with:
  - metadata seed file: `assets/metadata/flag_descriptions.json`
  - authoring guide: `docs/FLAG_DESCRIPTION_METADATA.md`
  - setting toggle: `Settings > Accessibility > Show flag descriptions`
  - in-quiz control: `Describe Flag`
  - coverage baseline: `263/263` assets (`100%`) with quality checks in `test/unit/data/flag_description_metadata_test.dart`
  - seed-template placeholders removed (`0` remaining); current entries are curated structural descriptions
  - optional local audit command: `python3 tools/check_flag_description_coverage.py`

## Gaps And Risks

### High Priority

- Verify and refine flag-description accuracy via manual QA pass.
  - Coverage and baseline quality checks are complete, but textual descriptions should be spot-checked against rendered assets.
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

- [x] Ship opt-in flag description metadata and UI.
- [x] Add accessibility preferences section in Settings (description toggle at minimum).
- [x] Add quiz widget coverage for the description affordance and behavior.
- [x] Expand metadata coverage for additional flags and add QA pass for description quality.
- [x] Continue metadata expansion toward broader long-tail flag coverage (>70% target).
- [x] Curate long-tail descriptions for higher specificity (territories/regions first).
- [ ] Execute manual visual QA sweep for description accuracy against top-traffic and long-tail flags.

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
