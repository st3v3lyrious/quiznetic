#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LIB_DIR = ROOT / "lib"
DOCS_DIR = ROOT / "docs"
CODEMAP_MD = DOCS_DIR / "CODEMAP.md"

IGNORED_FILES = {"firebase_options.dart"}
DOC_KIND_BY_FOLDER = {
    "screens": "Screen",
    "services": "Service",
    "data": "DataSource",
    "models": "Model",
    "widgets": "Widget",
    "utils": "Utility",
}

FILE_PURPOSE_HINTS = {
    "main.dart": "Initializes Firebase and boots the app with routes and theme.",
    "splash_screen.dart": "Shows startup branding and routes users based on auth state.",
    "login_screen.dart": "Handles sign-in providers and guest sign-in entry.",
    "home_screen.dart": "Shows quiz categories and routes to difficulty selection.",
    "difficulty_screen.dart": "Lets users choose difficulty and question count.",
    "quiz_screen.dart": "Runs a quiz session and tracks answers and score.",
    "result_screen.dart": "Shows result summary and next actions after a quiz.",
    "user_profile_screen.dart": "Displays user profile and saved high-score records.",
    "upgrade_account_screen.dart": "Lets anonymous users upgrade to a linked account.",
    "auth_service.dart": "Wraps authentication operations and auth-state helpers.",
    "score_service.dart": "Persists and reads quiz scores and leaderboard data.",
    "user_checker.dart": "Creates and checks Firestore user documents.",
    "user_profile.dart": "Stores and retrieves local profile/high-score preferences.",
    "flag_loader.dart": "Loads flag assets and builds randomized quiz question sets.",
    "flag_list.dart": "Contains static sample flag question data.",
    "flag_question.dart": "Defines the data model for a single flag question.",
    "auth_guard.dart": "Guards widget trees based on authentication state.",
    "helpers.dart": "Provides shared helper utilities used across the app.",
}

DECL_EXCLUDED_PREFIXES = (
    "if ",
    "for ",
    "while ",
    "switch ",
    "catch ",
    "return ",
    "assert ",
    "else ",
    "try ",
    "do ",
    "on ",
    "case ",
)
DECL_EXCLUDED_STARTS = (
    "class ",
    "enum ",
    "mixin ",
    "extension ",
    "typedef ",
    "import ",
    "export ",
    "part ",
)


@dataclass
class DocEntry:
    rel_path: Path
    kind: str
    title: str
    purpose: str
    documented: bool


@dataclass
class FunctionDocEntry:
    rel_path: Path
    name: str
    line: int
    insert_at_line: int
    documented: bool
    signature: str


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def title_from_stem(stem: str) -> str:
    return " ".join(word.capitalize() for word in stem.split("_"))


def detect_kind(rel_path: Path) -> str:
    if rel_path.name == "main.dart":
        return "AppEntry"
    top = rel_path.parts[1] if len(rel_path.parts) > 1 else ""
    return DOC_KIND_BY_FOLDER.get(top, "Module")


def default_purpose(rel_path: Path) -> str:
    return FILE_PURPOSE_HINTS.get(
        rel_path.name,
        "TODO: Describe this file's responsibility and key behavior.",
    )


def parse_doc_header(file_text: str) -> dict[str, str]:
    head = file_text[:2400]
    block_match = re.search(r"/\*(.*?)\*/", head, re.DOTALL)
    if not block_match:
        return {}

    block = block_match.group(1)
    values: dict[str, str] = {}
    for raw in block.splitlines():
        line = raw.strip().lstrip("*").strip()
        if not line:
            continue
        kv = re.match(r"^([A-Za-z0-9_ -]+)\s*:\s*(.+)$", line)
        if not kv:
            continue
        key = kv.group(1).strip().lower().replace(" ", "_").replace("-", "_")
        values[key] = kv.group(2).strip()
    return values


def build_header(entry: DocEntry) -> str:
    return "\n".join(
        [
            "/*",
            f" DOC: {entry.kind}",
            f" Title: {entry.title}",
            f" Purpose: {entry.purpose}",
            "*/",
            "",
        ]
    )


def build_function_doc_comment(indent: str, name: str) -> str:
    return f"{indent}/// TODO: Describe the behavior of `{name}`."


def should_include(rel_path: Path, filters: list[str]) -> bool:
    if rel_path.name in IGNORED_FILES:
        return False
    if not filters:
        return True

    rel = rel_path.as_posix()
    for target in filters:
        normalized = target.strip().lstrip("./")
        if rel == normalized:
            return True
        if rel.startswith(f"{normalized.rstrip('/')}/"):
            return True
    return False


def _is_declaration_start(stripped: str) -> bool:
    if not stripped:
        return False
    if stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*"):
        return False
    if stripped.startswith(DECL_EXCLUDED_STARTS):
        return False
    if any(stripped.startswith(prefix) for prefix in DECL_EXCLUDED_PREFIXES):
        return False
    return "(" in stripped


def _join_signature(lines: list[str], start: int) -> tuple[str, int]:
    parts = [lines[start]]
    end = start
    while end + 1 < len(lines):
        joined = " ".join(part.strip() for part in parts)
        if "{" in joined or "=>" in joined or ";" in joined:
            break
        if len(parts) >= 8:
            break
        end += 1
        parts.append(lines[end])

    joined = " ".join(part.strip() for part in parts)
    joined = re.sub(r"\s+", " ", joined).strip()
    return joined, end


def _has_doc_comment(lines: list[str], signature_start: int) -> tuple[bool, int]:
    insert_at = signature_start
    while insert_at > 0 and lines[insert_at - 1].lstrip().startswith("@"):
        insert_at -= 1

    cursor = insert_at - 1
    while cursor >= 0 and not lines[cursor].strip():
        cursor -= 1

    if cursor < 0:
        return False, insert_at

    prev = lines[cursor].strip()
    if prev.startswith("///") or prev.endswith("*/"):
        return True, insert_at
    return False, insert_at


def extract_function_entries(file_text: str, rel_path: Path) -> list[FunctionDocEntry]:
    lines = file_text.splitlines()
    out: list[FunctionDocEntry] = []
    i = 0

    while i < len(lines):
        stripped = lines[i].strip()
        if not _is_declaration_start(stripped):
            i += 1
            continue

        signature, end = _join_signature(lines, i)
        if "(" not in signature:
            i += 1
            continue

        semicolon_pos = signature.find(";")
        body_positions = [p for p in (signature.find("{"), signature.find("=>")) if p != -1]
        body_pos = min(body_positions) if body_positions else -1
        if semicolon_pos != -1 and (body_pos == -1 or semicolon_pos < body_pos):
            i += 1
            continue
        if body_pos == -1:
            i += 1
            continue

        prefix = signature.split("(", 1)[0].strip()
        lower_prefix = prefix.lower()
        if any(lower_prefix.startswith(x) for x in DECL_EXCLUDED_PREFIXES):
            i += 1
            continue
        if any(lower_prefix.startswith(x) for x in DECL_EXCLUDED_STARTS):
            i += 1
            continue
        if lower_prefix.startswith("const ") or lower_prefix.startswith("factory "):
            i += 1
            continue
        if "=" in prefix:
            i += 1
            continue

        match = re.match(
            r"^(?:external\s+)?(?:static\s+)?(?:late\s+)?(?:covariant\s+)?"
            r"(?:[\w<>\[\]\?,\.]+\s+)+([A-Za-z_]\w*)(?:<[^>]+>)?$",
            prefix,
        )
        if not match:
            i += 1
            continue

        name = match.group(1)
        documented, insert_at = _has_doc_comment(lines, i)
        out.append(
            FunctionDocEntry(
                rel_path=rel_path,
                name=name,
                line=i + 1,
                insert_at_line=insert_at,
                documented=documented,
                signature=signature,
            )
        )
        i = end + 1

    return out


def collect_entries(filters: list[str]) -> tuple[list[DocEntry], list[FunctionDocEntry]]:
    entries: list[DocEntry] = []
    function_entries: list[FunctionDocEntry] = []

    for file in sorted(LIB_DIR.rglob("*.dart")):
        rel = file.relative_to(ROOT)
        if not should_include(rel, filters):
            continue

        text = read_text(file)
        header = parse_doc_header(text)

        kind = header.get("doc", detect_kind(rel))
        title = header.get("title", title_from_stem(file.stem))
        purpose = header.get("purpose", default_purpose(rel))
        documented = "doc" in header and "title" in header and "purpose" in header

        entries.append(
            DocEntry(
                rel_path=rel,
                kind=kind,
                title=title,
                purpose=purpose,
                documented=documented,
            )
        )
        function_entries.extend(extract_function_entries(text, rel))

    return entries, function_entries


def apply_headers(entries: list[DocEntry]) -> list[Path]:
    updated: list[Path] = []
    for entry in entries:
        if entry.documented:
            continue
        abs_path = ROOT / entry.rel_path
        existing = read_text(abs_path)
        new_content = build_header(entry) + existing
        write_text(abs_path, new_content)
        updated.append(entry.rel_path)
    return updated


def apply_function_docs(function_entries: list[FunctionDocEntry]) -> list[tuple[Path, int]]:
    updates: list[tuple[Path, int]] = []
    by_file: dict[Path, list[FunctionDocEntry]] = {}
    for entry in function_entries:
        if entry.documented:
            continue
        by_file.setdefault(entry.rel_path, []).append(entry)

    for rel_path, entries in by_file.items():
        abs_path = ROOT / rel_path
        original = read_text(abs_path)
        lines = original.splitlines()

        inserted = 0
        for entry in sorted(entries, key=lambda e: e.insert_at_line, reverse=True):
            if entry.insert_at_line >= len(lines):
                indent = ""
            else:
                match = re.match(r"^(\s*)", lines[entry.insert_at_line])
                indent = match.group(1) if match else ""
            comment = build_function_doc_comment(indent, entry.name)
            lines.insert(entry.insert_at_line, comment)
            inserted += 1

        updated_text = "\n".join(lines)
        if original.endswith("\n"):
            updated_text += "\n"
        write_text(abs_path, updated_text)
        updates.append((rel_path, inserted))

    return updates


def render_codemap(entries: list[DocEntry], function_entries: list[FunctionDocEntry]) -> str:
    grouped: dict[str, list[DocEntry]] = {}
    for entry in entries:
        grouped.setdefault(entry.kind, []).append(entry)

    total_files = len(entries)
    documented_files = sum(1 for e in entries if e.documented)
    missing_files = total_files - documented_files

    total_functions = len(function_entries)
    documented_functions = sum(1 for f in function_entries if f.documented)
    missing_functions = total_functions - documented_functions

    out: list[str] = []
    out.append("# CODEMAP\n")
    out.append("Auto-generated by `tools/documentation_agent.py`.\n")
    out.append(
        f"- Total Dart files scanned: **{total_files}**\n"
        f"- Fully documented file headers: **{documented_files}**\n"
        f"- Missing file headers: **{missing_files}**\n"
        f"- Total functions/methods scanned: **{total_functions}**\n"
        f"- Functions/methods with doc comments: **{documented_functions}**\n"
        f"- Functions/methods missing doc comments: **{missing_functions}**\n"
    )

    for kind in sorted(grouped.keys()):
        out.append(f"## {kind}\n")
        for entry in grouped[kind]:
            status = "documented" if entry.documented else "needs header"
            out.append(
                f"- `{entry.rel_path.as_posix()}`"
                f" — {entry.purpose} _(status: {status})_"
            )
        out.append("")

    if missing_functions:
        out.append("## Missing Function Docs\n")
        missing_by_file: dict[Path, list[FunctionDocEntry]] = {}
        for f in function_entries:
            if f.documented:
                continue
            missing_by_file.setdefault(f.rel_path, []).append(f)
        for rel_path in sorted(missing_by_file.keys()):
            names = ", ".join(
                f"`{entry.name}` (L{entry.line})"
                for entry in missing_by_file[rel_path][:8]
            )
            extra = ""
            if len(missing_by_file[rel_path]) > 8:
                extra = f", +{len(missing_by_file[rel_path]) - 8} more"
            out.append(f"- `{rel_path.as_posix()}`: {names}{extra}")
        out.append("")

    return "\n".join(out).strip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Documentation agent: inserts structured file headers, can scaffold "
            "function docs, and generates docs/CODEMAP.md."
        )
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write missing file header docs into Dart files.",
    )
    parser.add_argument(
        "--apply-functions",
        action="store_true",
        help="Write missing function/method doc comments into Dart files.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit with code 1 if any files are missing structured file headers.",
    )
    parser.add_argument(
        "--check-functions",
        action="store_true",
        help="Exit with code 1 if any functions/methods are missing doc comments.",
    )
    parser.add_argument(
        "--paths",
        nargs="*",
        default=[],
        help="Optional relative paths to limit processing (files or folders).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    before_entries, _ = collect_entries(args.paths)

    if args.apply:
        updated = apply_headers(before_entries)
        if updated:
            print(f"Inserted file headers in {len(updated)} file(s):")
            for rel in updated:
                print(f"- {rel.as_posix()}")
        else:
            print("No missing file headers found. No file-header changes made.")

    if args.apply_functions:
        _, current_functions = collect_entries(args.paths)
        function_updates = apply_function_docs(current_functions)
        if function_updates:
            total = sum(count for _, count in function_updates)
            print(
                f"Inserted function doc comments in {total} location(s) across "
                f"{len(function_updates)} file(s):"
            )
            for rel, count in function_updates:
                print(f"- {rel.as_posix()} ({count})")
        else:
            print("No missing function docs found. No function-doc changes made.")

    after_entries, after_functions = collect_entries(args.paths)
    codemap = render_codemap(after_entries, after_functions)
    write_text(CODEMAP_MD, codemap)
    print(f"Updated {CODEMAP_MD.relative_to(ROOT).as_posix()}.")

    missing_headers = [entry.rel_path for entry in after_entries if not entry.documented]
    missing_function_docs = [f for f in after_functions if not f.documented]

    if missing_headers:
        print("\nFiles still missing structured headers:")
        for rel in missing_headers:
            print(f"- {rel.as_posix()}")
    else:
        print("\nAll scanned files have structured file headers.")

    if missing_function_docs:
        print("\nFunctions/methods still missing doc comments:")
        for f in missing_function_docs[:30]:
            print(f"- {f.rel_path.as_posix()}: {f.name} (line {f.line})")
        if len(missing_function_docs) > 30:
            print(f"- ... and {len(missing_function_docs) - 30} more")
    else:
        print("\nAll scanned functions/methods have doc comments.")

    failed = False
    if args.check and missing_headers:
        failed = True
    if args.check_functions and missing_function_docs:
        failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
