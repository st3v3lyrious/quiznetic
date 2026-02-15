#!/usr/bin/env python3
"""Seed missing flag-description metadata entries with baseline descriptors."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys


def normalize_key(raw: str) -> str:
    key = re.sub(r"[^a-z0-9]+", " ", raw.lower()).strip()
    return re.sub(r"\s+", " ", key)


BASELINE_TEMPLATES = (
    "Flag layout with geometric bands and symbolic elements in a structured composition.",
    "Distinctive field pattern combining bands, shaped motifs, and symbol markers.",
    "Structured flag design with clear bands, geometric forms, and symbolic features.",
    "Regional-style flag composition using bands, geometric shapes, and symbol elements.",
    "Banded flag structure with geometric sections and identifying symbolic motifs.",
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Add baseline descriptions for missing flag metadata keys.",
    )
    parser.add_argument(
        "--metadata",
        default="assets/metadata/flag_descriptions.json",
        help="Path to metadata JSON file.",
    )
    parser.add_argument(
        "--flags-dir",
        default="assets/flags",
        help="Directory containing flag assets.",
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

    metadata = {str(k): str(v) for k, v in data.items()}
    asset_keys = sorted(
        {
            normalize_key(path.stem)
            for path in flags_dir.iterdir()
            if path.is_file() and path.suffix
        }
    )

    added = 0
    for key in asset_keys:
        if key in metadata:
            continue
        digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
        template_idx = int(digest[:8], 16) % len(BASELINE_TEMPLATES)
        metadata[key] = BASELINE_TEMPLATES[template_idx]
        added += 1

    metadata_path.write_text(json.dumps(dict(sorted(metadata.items())), indent=2) + "\n")

    covered = sum(1 for key in asset_keys if key in metadata)
    coverage = covered / len(asset_keys) if asset_keys else 0.0
    print(f"Added entries: {added}")
    print(f"Metadata entries: {len(metadata)}")
    print(f"Coverage: {coverage * 100:.2f}% ({covered}/{len(asset_keys)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
