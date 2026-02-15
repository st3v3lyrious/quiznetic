# FLAG DESCRIPTION METADATA

This document defines how optional flag descriptions are authored for accessibility support.

## Purpose

- Provide non-color visual cues for flag quiz questions.
- Keep descriptions opt-in via `Settings > Accessibility > Show flag descriptions`.
- Preserve gameplay by describing layout/symbols, not answer text hints.

## Metadata Source

- File: `assets/metadata/flag_descriptions.json`
- Key format:
  - normalized country key (lowercase, spaces only)
  - example: `bosnia and herzegovina`
- Value format:
  - concise plain-language description of layout/symbols
  - include structural cues (e.g., stripes, cross, triangle, star, emblem)

## Quality Guardrails

Automated checks run in unit tests (`test/unit/data/flag_description_metadata_test.dart`):

- keys are normalized
- descriptions are non-empty and not placeholders
- descriptions include structural cue terms
- coverage floor is enforced (currently `>= 70%` of flag assets)
- metadata keys must map to existing flag assets

## Local Audit Command

```bash
python3 tools/check_flag_description_coverage.py
```

Optional threshold override:

```bash
python3 tools/check_flag_description_coverage.py --min-coverage 0.5
```

## Baseline Seeding

To seed baseline descriptions for newly added assets:

```bash
python3 tools/seed_missing_flag_descriptions.py
```

This script intentionally writes generic structural descriptions for missing keys.
Use it as a bootstrap, then curate high-priority entries for specificity.

Current repository status:

- `263/263` assets have descriptions.
- Generic seed-template placeholders have been fully replaced with curated entries.
