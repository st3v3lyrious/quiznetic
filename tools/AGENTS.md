# Manual Agents

These agents are manual-run scripts in `tools/`.

## 1) Documentation Agent

Script:
- `tools/documentation_agent.py`

Purpose:
- Adds structured header docs to Dart files that are missing them.
- Adds function/method doc comments where missing.
- Regenerates `docs/CODEMAP.md` with file purposes and doc coverage.

Usage:
```bash
# Dry-run + codemap refresh
python3 tools/documentation_agent.py

# Apply missing header docs + refresh codemap
python3 tools/documentation_agent.py --apply

# Apply missing function/method docs + refresh codemap
python3 tools/documentation_agent.py --apply-functions

# Apply both file and function docs in one run
python3 tools/documentation_agent.py --apply --apply-functions

# Check mode (non-zero exit if undocumented files remain)
python3 tools/documentation_agent.py --check

# Check function docs too
python3 tools/documentation_agent.py --check-functions

# Limit to specific paths
python3 tools/documentation_agent.py --apply --apply-functions --paths lib/screens lib/services/auth_service.dart
```

## 2) Testing Agent

Script:
- `tools/testing_agent.py`

Purpose:
- Scaffolds unit tests for service/data/model/util files.
- Scaffolds widget tests for screen/widget files.
- Scaffolds e2e smoke test under `integration_test/`.

Usage:
```bash
# Dry-run
python3 tools/testing_agent.py

# Generate missing test scaffolds
python3 tools/testing_agent.py --apply

# Overwrite existing scaffold files
python3 tools/testing_agent.py --apply --overwrite

# Limit generation to changed/new source files
python3 tools/testing_agent.py --apply --targets lib/screens/quiz_screen.dart lib/services/score_service.dart

# Skip e2e scaffold
python3 tools/testing_agent.py --apply --skip-e2e
```

## Suggested Workflow

When adding a new behavior:
1. Implement code changes.
2. Run `python3 tools/documentation_agent.py --apply`.
3. Run `python3 tools/testing_agent.py --apply --targets <changed files>`.
4. Replace scaffold TODOs with real assertions.
