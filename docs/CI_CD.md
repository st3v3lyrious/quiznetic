# CI/CD

This document defines the repository quality gates and the intended merge flow.

## Goals

- Block direct pushes to `main`.
- Enforce automated quality checks before merge.
- Keep heavier tests available in CI even when local hardware is constrained.

## Test Layout

- `test/`: Flutter unit + widget tests (`flutter test`)
- `integration_test/`: Flutter integration tests (`flutter test integration_test`)
- `playwright/`: Playwright E2E tests (`npx playwright test`)

## Workflows

- `.github/workflows/flutter_quality_gates.yml` (required on PRs)
  - `Analyze`: `flutter analyze`
  - `Tests And Coverage`: `flutter test test/widget` + `./tools/check_unit_coverage.sh`
- `.github/workflows/extended_tests.yml` (manual + weekly scheduled)
  - `Flutter Integration Tests`: Linux desktop run of `integration_test/*_integration_test.dart`
  - `Playwright E2E`: web build + static server + `npm run test:e2e` in `playwright/`

## Integration CI Notes

- Runner is pinned to `ubuntu-22.04`.
  - Reason: current desktop webview/auth plugin dependencies require `webkit2gtk-4.0` packages that are not reliably available on `ubuntu-24.04` CI images.
- Linux desktop dependencies are installed explicitly (`libgtk-3-dev`, `libwebkit2gtk-4.0-dev`, `libjavascriptcoregtk-4.0-dev`, `libsoup2.4-dev`, `libsecret-1-dev`, `xvfb`, etc.).
- Integration tests run serially (one file at a time, `--concurrency=1`).
  - Reason: reduces CI flakiness around Linux debug connection/log reader startup.

## Playwright CI Notes

- Flutter web app is built first and served from `build/web` on `http://127.0.0.1:7357`.
- Tests use `PLAYWRIGHT_BASE_URL` so URL changes are config-driven.
- Flutter web semantics may need explicit enabling in tests (`flt-semantics-placeholder`) before role/text selectors become stable.
- CI uploads both:
  - `playwright/playwright-report`
  - `playwright/test-results`

## Coverage Gate

- Script: `tools/check_unit_coverage.sh`
- Default threshold: `25%` (override via `MIN_UNIT_COVERAGE`)

## Branch Protection (GitHub Manual Setup)

1. Go to `Settings` -> `Branches` -> `Add branch protection rule` for `main`.
2. Enable `Require a pull request before merging`.
3. Enable `Require status checks to pass before merging`.
4. Mark as required:
   - `Analyze`
   - `Tests And Coverage`
5. Enable `Require branches to be up to date before merging`.
6. Enable `Require signed commits` (recommended).
7. Enable `Restrict who can push to matching branches` (recommended).

## Daily Flow

1. Create a feature branch from `main`.
2. Commit and push branch changes.
3. Open PR into `main`.
4. Wait for required checks to pass.
5. Merge PR.
