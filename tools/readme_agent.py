#!/usr/bin/env python3
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]  # repo root (tools/..)
README = ROOT / "README.md"

START = "<!-- DOC_AGENT_START -->"
END = "<!-- DOC_AGENT_END -->"


@dataclass
class PubspecInfo:
  name: str | None = None
  description: str | None = None
  version: str | None = None
  environment: str | None = None
  dependencies: list[str] | None = None
  dev_dependencies: list[str] | None = None


def read_text(p: Path) -> str:
  return p.read_text(encoding="utf-8")


def safe_write_text(p: Path, content: str) -> None:
  p.write_text(content, encoding="utf-8")


def parse_pubspec_minimal(pubspec_path: Path) -> PubspecInfo:
  """
  Minimal YAML-ish parsing without external deps.
  Assumes common pubspec formatting.
  """
  text = read_text(pubspec_path)

  def grab_scalar(key: str) -> str | None:
    m = re.search(rf"(?m)^\s*{re.escape(key)}\s*:\s*(.+?)\s*$", text)
    if not m:
      return None
    val = m.group(1).strip().strip('"').strip("'")
    # ignore complex values
    if val.startswith("{") or val.startswith("["):
      return None
    return val

  def grab_section_keys(section: str) -> list[str]:
    # Find section block: dependencies: ... until next top-level key
    m = re.search(rf"(?ms)^\s*{re.escape(section)}\s*:\s*\n(.*?)(?=^\S|\Z)", text)
    if not m:
      return []
    block = m.group(1)
    keys = []
    for line in block.splitlines():
      if not line.strip() or line.lstrip().startswith("#"):
        continue
      # dependency line like "http: ^1.2.0"
      mm = re.match(r"^\s{2,}([a-zA-Z0-9_]+)\s*:", line)
      if mm:
        keys.append(mm.group(1))
    return keys

  return PubspecInfo(
    name=grab_scalar("name"),
    description=grab_scalar("description"),
    version=grab_scalar("version"),
    environment=None,  # computed below
    dependencies=grab_section_keys("dependencies"),
    dev_dependencies=grab_section_keys("dev_dependencies"),
  )


def parse_environment(pubspec_path: Path) -> str | None:
  text = read_text(pubspec_path)
  m = re.search(r"(?ms)^\s*environment\s*:\s*\n(.*?)(?=^\S|\Z)", text)
  if not m:
    return None
  block = m.group(1)
  # try to find sdk/flutter constraints
  sdk = re.search(r"(?m)^\s{2,}sdk\s*:\s*(.+?)\s*$", block)
  flutter = re.search(r"(?m)^\s{2,}flutter\s*:\s*(.+?)\s*$", block)
  parts = []
  if sdk:
    parts.append(f"Dart SDK: `{sdk.group(1).strip()}`")
  if flutter:
    parts.append(f"Flutter: `{flutter.group(1).strip()}`")
  return " | ".join(parts) if parts else None


def iter_dart_files(folder: Path) -> Iterable[Path]:
  if not folder.exists():
    return []
  return sorted([p for p in folder.rglob("*.dart") if p.is_file()])


def summarize_tree(folder: Path, max_entries: int = 120) -> str:
  """
  Lightweight tree list (not a full ASCII tree) to avoid huge README updates.
  """
  if not folder.exists():
    return "_(missing)_"
  entries = []
  for p in sorted(folder.rglob("*")):
    if p.is_dir():
      continue
    rel = p.relative_to(ROOT).as_posix()
    # skip build artifacts
    if rel.startswith("build/") or "/.dart_tool/" in rel:
      continue
    entries.append(rel)
    if len(entries) >= max_entries:
      entries.append("…")
      break
  return "\n".join(f"- `{e}`" for e in entries)


def count_tests(test_dir: Path) -> int:
  return len(list(iter_dart_files(test_dir)))


def generate_doc_block() -> str:
  pubspec_path = ROOT / "pubspec.yaml"
  info = parse_pubspec_minimal(pubspec_path) if pubspec_path.exists() else PubspecInfo()
  info.environment = parse_environment(pubspec_path) if pubspec_path.exists() else None

  lib_dir = ROOT / "lib"
  test_dir = ROOT / "test"
  it_dir = ROOT / "integration_test"

  unit_widget_count = count_tests(test_dir)
  integration_count = count_tests(it_dir)

  deps = ", ".join(info.dependencies[:12]) + ("…" if info.dependencies and len(info.dependencies) > 12 else "")
  dev_deps = ", ".join(info.dev_dependencies[:12]) + ("…" if info.dev_dependencies and len(info.dev_dependencies) > 12 else "")

  # You can expand this later with “features list”, “screens”, “routes”, etc.
  parts = [
    "## Project Snapshot (auto)",
    "",
    f"- **Package:** `{info.name or 'unknown'}`",
    f"- **Version:** `{info.version or 'unknown'}`",
    f"- **Environment:** {info.environment or '`unknown`'}",
    "",
    "### Dependencies (auto)",
    f"- **deps:** {deps or '_(none found)_'}",
    f"- **dev_deps:** {dev_deps or '_(none found)_'}",
    "",
    "### Test Status (auto)",
    f"- **Unit/Widget tests:** `{unit_widget_count}` files in `test/`",
    f"- **Integration tests:** `{integration_count}` files in `integration_test/`",
    "",
    "### Key Files (auto)",
    "",
    "**lib/**",
    summarize_tree(lib_dir, max_entries=80),
    "",
    "**test/**",
    summarize_tree(test_dir, max_entries=40),
    "",
    "**integration_test/**",
    summarize_tree(it_dir, max_entries=40),
    "",
    "### How to run (auto)",
    "",
    "```bash",
    "flutter pub get",
    "flutter test",
    "# Integration tests (if present):",
    "flutter test integration_test",
    "```",
  ]
  return "\n".join(parts).strip() + "\n"


def update_readme() -> None:
  if not README.exists():
    raise SystemExit(f"README not found at: {README}")

  content = read_text(README)

  if START not in content or END not in content:
    raise SystemExit(
      "README markers not found.\n"
      f"Add:\n{START}\n...\n{END}\n"
    )

  new_block = generate_doc_block()
  pattern = re.compile(rf"{re.escape(START)}.*?{re.escape(END)}", re.DOTALL)
  replacement = f"{START}\n{new_block}{END}"
  updated = re.sub(pattern, replacement, content)

  if updated == content:
    print("README already up to date.")
    return

  safe_write_text(README, updated)
  print("README updated successfully.")


if __name__ == "__main__":
  update_readme()
