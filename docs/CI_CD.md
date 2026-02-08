# CI/CD

This document defines the intended development flow for this repository.

## Goal

- Stop direct pushes to `main`.
- Require automated quality checks before merge.

## Workflows

- `.github/workflows/flutter_quality_gates.yml`
  - Trigger: pull requests to `main` + pushes to `main`
  - Jobs:
    - `Analyze` (`flutter analyze`)
    - `Tests And Coverage` (`flutter test test/widget` + unit coverage gate)
- `.github/workflows/extended_tests.yml`
  - Trigger: manual (`workflow_dispatch`) + weekly schedule
  - Jobs:
    - `Flutter Integration Tests` (`flutter test integration_test`)
    - `Playwright E2E` (`npm run test:e2e` under `playwright/`)

## Coverage Gate

- Script: `tools/check_unit_coverage.sh`
- Default threshold: `25%` (configurable via `MIN_UNIT_COVERAGE`)
- Current command path in CI:
  - `./tools/check_unit_coverage.sh`

## Required GitHub Branch Rules (manual setup)

In GitHub repository settings:

1. Go to `Settings` -> `Branches` -> `Add branch protection rule` for `main`.
2. Enable `Require a pull request before merging`.
3. Enable `Require status checks to pass before merging`.
4. Mark these checks as required:
   - `Analyze`
   - `Tests And Coverage`
5. Enable `Require branches to be up to date before merging`.
6. Enable `Restrict who can push to matching branches` (optional but recommended).
7. Disable direct pushes to `main` for regular contributors.

## Daily Dev Flow

1. Create feature branch from `main`.
2. Commit and push branch.
3. Open PR to `main`.
4. Wait for required checks to pass.
5. Merge PR (squash or merge commit per team preference).
