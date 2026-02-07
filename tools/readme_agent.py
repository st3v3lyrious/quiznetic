#!/usr/bin/env python3
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"

DOCS_DIR = ROOT / "docs"
FEATURES_MD = DOCS_DIR / "FEATURES.md"
ROADMAP_MD = DOCS_DIR / "ROADMAP.md"


@dataclass
class PubspecInfo:
  name: str | None = None
  description: str | None = None
  version: str | None = None
  environment: str | None = None
  dependencies: list[str] | None = None
  dev_dependencies: list[str] | None = None


# -----------------
# File helpers
# -----------------
def read_text(p: Path) -> str:
  return p.read_text(encoding="utf-8")


def safe_write_text(p: Path, content: str) -> None:
  p.write_text(content, encoding="utf-8")


def read_optional_md(p: Path) -> str | None:
  if not p.exists():
    return None
  txt = read_text(p).strip()
  return txt if txt else None


def ensure_docs_folder() -> None:
  if not DOCS_DIR.exists():
    DOCS_DIR.mkdir(parents=True, exist_ok=True)


# -----------------
# pubspec parsing (minimal)
# -----------------
def parse_pubspec_minimal(pubspec_path: Path) -> PubspecInfo:
  text = read_text(pubspec_path)

  def grab_scalar(key: str) -> str | None:
    m = re.search(rf"(?m)^\s*{re.escape(key)}\s*:\s*(.+?)\s*$", text)
    if not m:
      return None
    val = m.group(1).strip().strip('"').strip("'")
    if val.startswith("{") or val.startswith("["):
      return None
    return val

  def grab_section_keys(section: str) -> list[str]:
    m = re.search(rf"(?ms)^\s*{re.escape(section)}\s*:\s*\n(.*?)(?=^\S|\Z)", text)
    if not m:
      return []
    block = m.group(1)
    keys: list[str] = []
    for line in block.splitlines():
      if not line.strip() or line.lstrip().startswith("#"):
        continue
      mm = re.match(r"^\s{2,}([a-zA-Z0-9_]+)\s*:", line)
      if mm:
        keys.append(mm.group(1))
    return keys

  return PubspecInfo(
    name=grab_scalar("name"),
    description=grab_scalar("description"),
    version=grab_scalar("version"),
    environment=None,
    dependencies=grab_section_keys("dependencies"),
    dev_dependencies=grab_section_keys("dev_dependencies"),
  )


def parse_environment(pubspec_path: Path) -> str | None:
  text = read_text(pubspec_path)
  m = re.search(r"(?ms)^\s*environment\s*:\s*\n(.*?)(?=^\S|\Z)", text)
  if not m:
    return None
  block = m.group(1)
  sdk = re.search(r"(?m)^\s{2,}sdk\s*:\s*(.+?)\s*$", block)
  flutter = re.search(r"(?m)^\s{2,}flutter\s*:\s*(.+?)\s*$", block)
  parts = []
  if sdk:
    parts.append(f"Dart SDK: `{sdk.group(1).strip()}`")
  if flutter:
    parts.append(f"Flutter: `{flutter.group(1).strip()}`")
  return " | ".join(parts) if parts else None


# -----------------
# Repo scanning
# -----------------
IGNORED_NAMES = {".DS_Store"}
IGNORED_PATH_PARTS = {".dart_tool", "build", "Pods"}


def is_ignored_path(p: Path) -> bool:
  if p.name in IGNORED_NAMES:
    return True
  parts = set(p.parts)
  return any(x in parts for x in IGNORED_PATH_PARTS)


def iter_dart_files(folder: Path) -> Iterable[Path]:
  if not folder.exists():
    return []
  out: list[Path] = []
  for p in folder.rglob("*.dart"):
    if p.is_file() and not is_ignored_path(p):
      out.append(p)
  return sorted(out)


def count_tests(test_dir: Path) -> int:
  return len(list(iter_dart_files(test_dir)))


def title_from_filename(name: str) -> str:
  base = name.replace(".dart", "")
  base = base.replace("_screen", "")
  words = base.split("_")
  return " ".join(w.capitalize() for w in words)


def extract_doc_block_comment(file_text: str) -> dict[str, str]:
  """
  Extracts a top-of-file block comment like:

  /*
  DOC: Screen
  Title: Login
  Purpose: Authenticate user
  */

  Returns: {"doc": "Screen", "title": "...", "purpose": "..."}
  """
  out: dict[str, str] = {}

  # Only inspect the first ~2KB to avoid scanning whole files
  head = file_text[:2000]

  m = re.search(r"/\*(.*?)\*/", head, re.DOTALL)
  if not m:
    return out

  block = m.group(1)

  for raw_line in block.splitlines():
    line = raw_line.strip().lstrip("*").strip()
    if not line:
      continue

    kv = re.match(r"^([A-Za-z0-9_ -]+)\s*:\s*(.+)$", line)
    if kv:
      key = kv.group(1).strip().lower().replace(" ", "_").replace("-", "_")
      value = kv.group(2).strip()
      out[key] = value

  return out



def list_screens() -> list[dict[str, str]]:
  screens_dir = ROOT / "lib" / "screens"
  if not screens_dir.exists():
    return []
  items = []
  for p in sorted(screens_dir.glob("*.dart")):
    if is_ignored_path(p):
      continue
    txt = read_text(p)
    doc = extract_doc_block_comment(txt)
    title = doc.get("title") or title_from_filename(p.name)
    purpose = doc.get("purpose") or ""
    items.append({
      "title": title,
      "purpose": purpose,
      "file": p.relative_to(ROOT).as_posix(),
    })
  return items


def list_models() -> list[dict[str, str]]:
  models_dir = ROOT / "lib" / "models"
  if not models_dir.exists():
    return []
  items = []
  for p in sorted(models_dir.glob("*.dart")):
    if is_ignored_path(p):
      continue
    txt = read_text(p)
    classes = re.findall(r"(?m)^\s*class\s+([A-Za-z0-9_]+)\b", txt)
    if classes:
      items.append({
        "file": p.relative_to(ROOT).as_posix(),
        "classes": ", ".join(classes[:8]) + ("…" if len(classes) > 8 else ""),
      })
  return items


def detect_stack(deps: list[str]) -> list[str]:
  d = set(deps)
  stack = ["Flutter"]
  if "firebase_core" in d:
    stack.append("Firebase Core")
  if "firebase_auth" in d:
    stack.append("Firebase Auth")
  if "cloud_firestore" in d:
    stack.append("Cloud Firestore")
  if "shared_preferences" in d:
    stack.append("Shared Preferences")
  if "go_router" in d:
    stack.append("GoRouter")
  if "riverpod" in d or "flutter_riverpod" in d:
    stack.append("Riverpod")
  if "flutter_bloc" in d or "bloc" in d:
    stack.append("Bloc")
  return stack


# -----------------
# README generation (full)
# -----------------
def render_section(title: str, body: str) -> str:
  body = body.strip()
  return f"## {title}\n\n{body}\n"


def generate_readme() -> str:
  pubspec_path = ROOT / "pubspec.yaml"
  info = parse_pubspec_minimal(pubspec_path) if pubspec_path.exists() else PubspecInfo()
  info.environment = parse_environment(pubspec_path) if pubspec_path.exists() else None

  deps = info.dependencies or []
  dev_deps = info.dev_dependencies or []

  screens = list_screens()
  models = list_models()

  unit_widget_count = count_tests(ROOT / "test")
  integration_count = count_tests(ROOT / "integration_test")

  stack = detect_stack(deps)

  # Optional human-maintained sections
  features_md = read_optional_md(FEATURES_MD)
  roadmap_md = read_optional_md(ROADMAP_MD)

  # Top header
  name = info.name or "Flutter App"
  version = info.version or "unknown"
  desc = info.description or "TODO: Add a meaningful `description:` in `pubspec.yaml`."

  out = []
  out.append(f"# {name}\n")
  out.append(f"{desc}\n")
  out.append(f"- **Version:** `{version}`\n")
  out.append(f"- **Environment:** {info.environment or '`unknown`'}\n")

  # Features
  if features_md:
    out.append(render_section("Features", features_md))
  else:
    out.append(render_section(
      "Features",
      "- TODO: Create `docs/FEATURES.md` (bullet list) to populate this section."
    ))

  # Screens / user flows
  if screens:
    lines = []
    for s in screens:
      if s["purpose"]:
        lines.append(f"- **{s['title']}** — {s['purpose']} (`{s['file']}`)")
      else:
        lines.append(f"- **{s['title']}** (`{s['file']}`) — _Add `/// Purpose:` in the file header._")
    out.append(render_section("Screens", "\n".join(lines)))
  else:
    out.append(render_section("Screens", "_No screens found in `lib/screens/`._"))

  # Tech stack
  out.append(render_section("Tech stack", "- " + ", ".join(stack)))

  # Project structure (human-readable)
  structure_lines = [
    "- `lib/screens/` — UI screens",
    "- `lib/models/` — domain models",
    "- `lib/data/` — data sources/loaders",
    "- `test/` — unit + widget tests",
    "- `integration_test/` — integration tests (E2E-style) if present",
    "- `playwright/` — Playwright E2E tests",
  ]
  out.append(render_section("Project structure", "\n".join(structure_lines)))

  # Models
  if models:
    out.append(render_section(
      "Key models",
      "\n".join([f"- `{m['classes']}` (`{m['file']}`)" for m in models])
    ))

  # How to run
  out.append(render_section(
    "Run locally",
    "```bash\nflutter pub get\nflutter run\n```"
  ))

  # Testing
  out.append(render_section(
    "Testing",
    "\n".join([
      f"- **Unit/Widget tests:** `{unit_widget_count}` files",
      f"- **Integration tests:** `{integration_count}` files",
      "",
      "```bash",
      "flutter test",
      "flutter test test/unit --coverage",
      "./tools/run_unit_coverage.sh   # optional helper",
      "flutter test integration_test   # if present",
      "cd playwright && npx playwright test   # if present",
      "```"
    ])
  ))

  # Dependencies (keep it short)
  out.append(render_section(
    "Dependencies (summary)",
    "\n".join([
      f"- **deps:** {', '.join(deps[:12])}{'…' if len(deps) > 12 else ''}",
      f"- **dev_deps:** {', '.join(dev_deps[:12])}{'…' if len(dev_deps) > 12 else ''}",
    ])
  ))

  # Roadmap
  if roadmap_md:
    out.append(render_section("Roadmap", roadmap_md))
  else:
    out.append(render_section(
      "Roadmap",
      "- TODO: Create `docs/ROADMAP.md` to populate this section."
    ))

  # Footer
  out.append("\n---\n")
  out.append("_This README is generated by `tools/readme_agent.py`. Edit `docs/FEATURES.md` and `docs/ROADMAP.md` for human-written content._\n")

  return "\n".join(out).strip() + "\n"


def update_readme() -> None:
  ensure_docs_folder()
  content = generate_readme()
  safe_write_text(README, content)
  print("README generated successfully.")


if __name__ == "__main__":
  update_readme()
