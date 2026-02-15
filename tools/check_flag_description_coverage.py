#!/usr/bin/env python3
"""Check flag-description metadata coverage against bundled flag assets."""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys


def normalize_key(raw: str) -> str:
    key = re.sub(r"[^a-z0-9]+", " ", raw.lower()).strip()
    return re.sub(r"\s+", " ", key)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate accessibility flag-description metadata coverage.",
    )
    parser.add_argument(
        "--metadata",
        default="assets/metadata/flag_descriptions.json",
        help="Path to description metadata JSON.",
    )
    parser.add_argument(
        "--flags-dir",
        default="assets/flags",
        help="Directory containing flag image assets.",
    )
    parser.add_argument(
        "--min-coverage",
        type=float,
        default=0.70,
        help="Minimum required coverage ratio (0.0 to 1.0).",
    )
    args = parser.parse_args()

    metadata_path = pathlib.Path(args.metadata)
    flags_dir = pathlib.Path(args.flags_dir)

    if not metadata_path.exists():
        print(f"ERROR: metadata file not found: {metadata_path}")
        return 2
    if not flags_dir.exists():
        print(f"ERROR: flags directory not found: {flags_dir}")
        return 2

    data = json.loads(metadata_path.read_text())
    if not isinstance(data, dict):
        print("ERROR: metadata JSON root must be an object.")
        return 2

    metadata_keys = {str(k) for k in data.keys()}
    asset_keys = {
        normalize_key(path.stem)
        for path in flags_dir.iterdir()
        if path.is_file() and path.suffix
    }

    covered = len(asset_keys & metadata_keys)
    coverage = covered / len(asset_keys) if asset_keys else 0.0
    missing = sorted(asset_keys - metadata_keys)
    orphan = sorted(metadata_keys - asset_keys)

    print(f"Flag assets: {len(asset_keys)}")
    print(f"Metadata entries: {len(metadata_keys)}")
    print(f"Coverage: {coverage * 100:.2f}%")
    print(f"Missing descriptions: {len(missing)}")
    if missing:
        print(f"Missing sample: {missing[:15]}")
    print(f"Orphan metadata keys: {len(orphan)}")
    if orphan:
        print(f"Orphan sample: {orphan[:15]}")

    if coverage < args.min_coverage:
        print(
            "ERROR: coverage below minimum "
            f"({coverage * 100:.2f}% < {args.min_coverage * 100:.2f}%)."
        )
        return 1

    if orphan:
        print("ERROR: metadata contains keys without matching assets.")
        return 1

    print("Flag description coverage check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
