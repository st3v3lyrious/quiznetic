# Markdown Issue Sync Agent

This runbook documents `sync_md_to_gh.py`, the CLI tool that synchronizes
Markdown planning files with GitHub Issues.

## Purpose

- Keep Markdown as the single source of truth.
- Create/update/close GitHub issues based on:
  - `docs/ROADMAP.md`
  - `docs/FEATURES.md`
  - `docs/ISSUES.md`
- Never delete issues.
- Never auto-reopen closed issues unless `--allow-reopen` is explicitly set.
- Never manage GitHub Projects (repository auto-add handles that).

## Source Mapping

### `docs/ROADMAP.md`

- Parses top-level checklist lines like:
  - `- [ ] M2: ...`
  - `- [x] M10: ...`
- Issue title format: `ROADMAP M#: <task title>`
- Labels: `roadmap` + inferred area labels
- Milestone:
  - `M1..M5` => `MVP`
  - `M6+` => `MVP+1`
- Idempotency: inline anchor comment on each mapped line:
  - `<!--gh:issue=123-->`

### `docs/FEATURES.md`

- Creates issues only for top-level checklist tasks.
- Nested subtasks are included in issue body (not separate issues).
- Issue title format: `FEATURE: <task title>`
- Labels: `feature` + inferred area labels
- Milestone:
  - title contains `Deferred outside MVP scope` => `MVP+1`
  - otherwise => `MVP`
- Idempotency: inline anchor comment:
  - `<!--gh:issue=123-->`

### `docs/ISSUES.md`

- Parses issue tables with columns:
  - `ID | Severity | Scope | Status | Issue | Owner | Target Date | GH`
- Issue title format: `[ISS-001] <Issue text>`
- Labels:
  - `bug`
  - priority from severity (`p0/p1/p2`)
  - inferred area labels
- Milestone:
  - `Scope` contains `MVP+1` => `MVP+1`
  - otherwise => `MVP`
- `GH` column mapping:
  - empty => create issue and write `#<number>`
  - existing `#123` => update referenced issue

## Required Labels

The tool validates labels and fails fast if missing (it does not auto-create):

- Type: `roadmap`, `feature`, `bug`
- Priority: `p0`, `p1`, `p2`
- Area:
  - `auth`, `leaderboard`, `scores`, `profile`, `navigation`
  - `tests`, `firebase`, `firestore`, `accessibility`, `docs`

Check only:

```bash
python3 sync_md_to_gh.py --check-labels
```

## Milestones

Required milestones:

- `MVP`
- `MVP+1`

If missing, the tool creates them (except in `--dry-run` mode).

## Authentication

Token resolution order is:

1. `GITHUB_TOKEN` env var
2. `gh auth token` (GitHub CLI session)

If neither is available, execution fails with:

`No GitHub token found. Set GITHUB_TOKEN or run 'gh auth login'.`

Security behavior:

- Token value is never printed.
- Token value is never logged.
- Token value is never included in exceptions.
- `gh` stderr details are surfaced only in `--verbose` mode.

## Local Usage

Recommended Python: 3.11+

```bash
python3 -m pip install -r requirements.txt

# Option A: env token
export GITHUB_TOKEN=ghp_xxx
export GITHUB_REPOSITORY=st3v3lyrious/quiznetic

# Option B: GitHub CLI auth
gh auth login -h github.com
```

Dry run:

```bash
python3 sync_md_to_gh.py --dry-run --verbose
```

Apply:

```bash
python3 sync_md_to_gh.py --verbose
```

## CLI Flags

- `--dry-run`: no writes to GitHub or Markdown files.
- `--verbose`: verbose logs and diagnostic details.
- `--allow-reopen`: allows reopening closed issues when Markdown says open.
- `--check-labels`: validate labels and exit.

## Optional GitHub Actions Job

```yaml
name: Sync markdown to issues
on:
  push:
    paths:
      - "docs/*.md"
permissions:
  contents: write
  issues: write
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install -r requirements.txt
      - run: python sync_md_to_gh.py
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

`GITHUB_REPOSITORY` is provided automatically in GitHub Actions.

## Troubleshooting

- `No GitHub token found...`
  - Set `GITHUB_TOKEN`, or run `gh auth login -h github.com`.
- `missing required labels: ...`
  - Create labels manually in repository settings, then re-run.
- `invalid GH reference` in `docs/ISSUES.md`
  - Tool warns and creates a new issue, then updates `GH` cell.
- `referenced issue #... not found`
  - Tool warns and creates a replacement issue, then updates anchor/GH cell.

