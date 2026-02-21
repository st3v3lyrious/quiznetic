#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class Finding:
  level: str
  rule_id: str
  path: str
  line: int
  message: str
  suggestion: str


def read_text(path: Path) -> str:
  return path.read_text(encoding="utf-8")


def line_for_index(text: str, index: int) -> int:
  return text.count("\n", 0, index) + 1


def relative_path(root: Path, path: Path) -> str:
  try:
    return path.relative_to(root).as_posix()
  except ValueError:
    return path.as_posix()


def add_finding(
  findings: list[Finding],
  *,
  level: str,
  rule_id: str,
  path: Path,
  line: int,
  message: str,
  suggestion: str,
  root: Path,
) -> None:
  findings.append(
    Finding(
      level=level,
      rule_id=rule_id,
      path=relative_path(root, path),
      line=max(1, line),
      message=message,
      suggestion=suggestion,
    ),
  )


def extract_function_body(text: str, function_name: str) -> tuple[str | None, int]:
  match = re.search(
    rf"function\s+{re.escape(function_name)}\s*\([^)]*\)\s*\{{",
    text,
    re.MULTILINE,
  )
  if not match:
    return None, 1

  start_line = line_for_index(text, match.start())
  opening_brace = text.find("{", match.end() - 1)
  if opening_brace < 0:
    return None, start_line

  depth = 0
  for idx in range(opening_brace, len(text)):
    ch = text[idx]
    if ch == "{":
      depth += 1
    elif ch == "}":
      depth -= 1
      if depth == 0:
        return text[opening_brace + 1 : idx], start_line

  return None, start_line


def scan_firestore_timestamp_rules(root: Path, findings: list[Finding]) -> None:
  rules_path = root / "firestore.rules"
  if not rules_path.exists():
    return

  text = read_text(rules_path)
  required = {
    "validUserScore": "request.resource.data.updatedAt == request.time",
    "validLeaderboardEntry": "request.resource.data.updatedAt == request.time",
    "validScoreAttempt": "request.resource.data.createdAt == request.time",
  }

  for function_name, required_token in required.items():
    body, line = extract_function_body(text, function_name)
    if body is None:
      add_finding(
        findings,
        level="error",
        rule_id="firestore-rules-missing-function",
        path=rules_path,
        line=line,
        message=f"Unable to parse `{function_name}` in firestore rules.",
        suggestion="Ensure the function exists and is syntactically valid.",
        root=root,
      )
      continue

    if required_token not in body:
      add_finding(
        findings,
        level="error",
        rule_id="firestore-rules-server-timestamp",
        path=rules_path,
        line=line,
        message=(
          f"`{function_name}` does not enforce server-managed timestamp equality "
          f"(`{required_token}`)."
        ),
        suggestion=(
          "Require request timestamp equality to prevent client-selected "
          "audit/tie-break timestamps."
        ),
        root=root,
      )


def scan_runzonedguarded_async_handler(root: Path, findings: list[Finding]) -> None:
  main_path = root / "lib/main.dart"
  if not main_path.exists():
    return

  text = read_text(main_path)
  pattern = re.compile(
    r"runZonedGuarded\s*\([\s\S]*?,\s*\(\s*[^)]*\)\s*async\s*\{",
    re.MULTILINE,
  )
  for match in pattern.finditer(text):
    add_finding(
      findings,
      level="error",
      rule_id="runzonedguarded-async-onerror",
      path=main_path,
      line=line_for_index(text, match.start()),
      message="`runZonedGuarded` onError callback is `async`.",
      suggestion=(
        "Use a synchronous callback and call async crash logging with "
        "`unawaited(...)`."
      ),
      root=root,
    )


def scan_snackbar_exception_leaks(root: Path, findings: list[Finding]) -> None:
  screens_dir = root / "lib" / "screens"
  if not screens_dir.exists():
    return

  pattern = re.compile(
    r"SnackBar\s*\([\s\S]{0,260}?Text\s*\(\s*['\"][^'\"]*"
    r"\$(?:\{)?(?:e|error|exception)\b",
    re.MULTILINE,
  )

  for path in sorted(screens_dir.glob("*.dart")):
    text = read_text(path)
    for match in pattern.finditer(text):
      add_finding(
        findings,
        level="warning",
        rule_id="snackbar-raw-exception",
        path=path,
        line=line_for_index(text, match.start()),
        message="Snackbar text appears to include a raw exception value.",
        suggestion=(
          "Show a generic user-facing message and log the exception separately."
        ),
        root=root,
      )


def scan_repeated_quiz_feedback_calls(root: Path, findings: list[Finding]) -> None:
  quiz_path = root / "lib" / "screens" / "quiz_screen.dart"
  if not quiz_path.exists():
    return

  text = read_text(quiz_path)
  token = "_answerFeedbackFor(q)"
  occurrences = [m.start() for m in re.finditer(re.escape(token), text)]
  if len(occurrences) <= 1:
    return

  add_finding(
    findings,
    level="warning",
    rule_id="quiz-feedback-recompute",
    path=quiz_path,
    line=line_for_index(text, occurrences[0]),
    message=f"`{token}` is called multiple times in build output paths.",
    suggestion=(
      "Cache feedback in a local variable when `_answered` is true and reuse it "
      "for semantics/icon/text."
    ),
    root=root,
  )


def scan_xcode_asset_symbol_setting(root: Path, findings: list[Finding]) -> None:
  pbxproj = root / "ios" / "Runner.xcodeproj" / "project.pbxproj"
  if not pbxproj.exists():
    return

  text = read_text(pbxproj)
  pattern = re.compile(
    r"ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS\s*=\s*([^;]+);",
  )
  for match in pattern.finditer(text):
    value = match.group(1).strip()
    if value in {"YES", "NO"}:
      continue
    add_finding(
      findings,
      level="error",
      rule_id="xcode-invalid-asset-symbol-setting",
      path=pbxproj,
      line=line_for_index(text, match.start()),
      message=(
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS must be "
        f"YES/NO, found `{value}`."
      ),
      suggestion="Set this build setting to YES or NO.",
      root=root,
    )


def scan_workflow_job_if_secrets(root: Path, findings: list[Finding]) -> None:
  workflow_dir = root / ".github" / "workflows"
  if not workflow_dir.exists():
    return

  for path in sorted(workflow_dir.glob("*.yml")):
    lines = read_text(path).splitlines()
    for index, line in enumerate(lines):
      if not re.match(r"^\s{4}if:\s*", line):
        continue

      expression_parts = [line.split("if:", 1)[1].strip()]
      cursor = index + 1
      while cursor < len(lines):
        nxt = lines[cursor]
        if not nxt.strip():
          cursor += 1
          continue
        indent = len(nxt) - len(nxt.lstrip(" "))
        if indent <= 4:
          break
        expression_parts.append(nxt.strip())
        cursor += 1

      expression = " ".join(expression_parts)
      if "secrets." not in expression:
        continue

      add_finding(
        findings,
        level="error",
        rule_id="workflow-job-if-secrets-context",
        path=path,
        line=index + 1,
        message=(
          "Job-level `if` expression references `secrets.*`, which is not "
          "available in this context."
        ),
        suggestion=(
          "Move secret checks into a step script/step-level guard and keep "
          "job-level `if` based on `needs`/event context."
        ),
        root=root,
      )


def scan_banner_double_dispose(root: Path, findings: list[Finding]) -> None:
  banner_path = root / "lib" / "widgets" / "monetized_banner_ad.dart"
  if not banner_path.exists():
    return

  text = read_text(banner_path)
  pattern = re.compile(
    r"onAdFailedToLoad\s*:\s*\(\s*ad\s*,\s*error\s*\)\s*\{([\s\S]*?)\}",
    re.MULTILINE,
  )

  for match in pattern.finditer(text):
    body = match.group(1)
    if "ad.dispose()" in body and "_disposeBannerAd(" in body:
      add_finding(
        findings,
        level="warning",
        rule_id="banner-double-dispose",
        path=banner_path,
        line=line_for_index(text, match.start()),
        message=(
          "`onAdFailedToLoad` disposes `ad` directly and also calls "
          "`_disposeBannerAd(...)`, which can double-dispose the same instance."
        ),
        suggestion=(
          "Use one disposal path (for example `_disposeBannerAd(ad)`) and avoid "
          "an extra direct `ad.dispose()` call."
        ),
        root=root,
      )


def scan_ads_policy_guard(root: Path, findings: list[Finding]) -> None:
  app_config_path = root / "lib" / "config" / "app_config.dart"
  ads_service_path = root / "lib" / "services" / "ads_service.dart"
  if not app_config_path.exists() or not ads_service_path.exists():
    return

  app_config_text = read_text(app_config_path)
  if "ALLOW_LIVE_AD_UNITS_IN_DEBUG" not in app_config_text:
    add_finding(
      findings,
      level="warning",
      rule_id="ads-policy-guard-missing-flag",
      path=app_config_path,
      line=1,
      message=(
        "Missing `ALLOW_LIVE_AD_UNITS_IN_DEBUG` compile-time override for ad "
        "policy controls."
      ),
      suggestion=(
        "Keep an explicit non-release override flag so live ad serving requires "
        "deliberate opt-in during internal validation."
      ),
      root=root,
    )

  ads_service_text = read_text(ads_service_path)
  required_tokens = [
    "_allowLiveAdUnitsInDebug",
    "kReleaseMode",
    "_looksLikeAdMobUnitId",
    "_isOfficialGoogleTestAdUnit",
  ]
  for token in required_tokens:
    if token in ads_service_text:
      continue
    add_finding(
      findings,
      level="warning",
      rule_id="ads-policy-guard-missing-enforcement",
      path=ads_service_path,
      line=1,
      message=(
        "Ads policy/compliance guard appears incomplete for non-release ad unit "
        f"validation (missing `{token}`)."
      ),
      suggestion=(
        "Preserve guard logic that blocks live `ca-app-pub-*` units in "
        "non-release builds unless explicitly overridden."
      ),
      root=root,
    )


def escape_annotation(text: str) -> str:
  return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def emit_annotations(findings: list[Finding]) -> None:
  level_to_command = {
    "error": "error",
    "warning": "warning",
    "notice": "notice",
  }
  for finding in findings:
    command = level_to_command.get(finding.level, "notice")
    detail = f"{finding.message} Suggestion: {finding.suggestion}"
    print(
      f"::{command} file={finding.path},line={finding.line},title={finding.rule_id}::"
      f"{escape_annotation(detail)}",
    )


def render_summary_markdown(findings: list[Finding]) -> str:
  if not findings:
    return (
      "## Review Agent Report\n\n"
      "No findings detected.\n"
    )

  lines = [
    "## Review Agent Report",
    "",
    f"Findings: **{len(findings)}**",
    "",
    "| Level | Rule | Location | Message |",
    "| --- | --- | --- | --- |",
  ]

  for finding in findings:
    location = f"`{finding.path}:{finding.line}`"
    lines.append(
      f"| {finding.level.upper()} | `{finding.rule_id}` | {location} | "
      f"{finding.message} |",
    )

  lines.append("")
  return "\n".join(lines)


def should_fail(findings: list[Finding], fail_on: str) -> bool:
  if fail_on == "none":
    return False
  if fail_on == "warning":
    return any(f.level in {"warning", "error"} for f in findings)
  return any(f.level == "error" for f in findings)


def run(root: Path) -> list[Finding]:
  findings: list[Finding] = []
  scan_firestore_timestamp_rules(root, findings)
  scan_runzonedguarded_async_handler(root, findings)
  scan_snackbar_exception_leaks(root, findings)
  scan_repeated_quiz_feedback_calls(root, findings)
  scan_xcode_asset_symbol_setting(root, findings)
  scan_workflow_job_if_secrets(root, findings)
  scan_banner_double_dispose(root, findings)
  scan_ads_policy_guard(root, findings)

  level_rank = {"error": 0, "warning": 1, "notice": 2}
  findings.sort(
    key=lambda f: (level_rank.get(f.level, 3), f.path.lower(), f.line, f.rule_id),
  )
  return findings


def main() -> int:
  default_root = Path(__file__).resolve().parents[1]
  parser = argparse.ArgumentParser(
    description="Repository review agent with line-level CI annotations.",
  )
  parser.add_argument("--root", type=Path, default=default_root)
  parser.add_argument("--emit-annotations", action="store_true")
  parser.add_argument("--summary-file", type=Path)
  parser.add_argument("--json-file", type=Path)
  parser.add_argument(
    "--fail-on",
    choices=["none", "error", "warning"],
    default="error",
    help="Exit non-zero when findings at/above this severity are present.",
  )
  args = parser.parse_args()

  root = args.root.resolve()
  findings = run(root)

  errors = sum(1 for f in findings if f.level == "error")
  warnings = sum(1 for f in findings if f.level == "warning")
  notices = sum(1 for f in findings if f.level == "notice")
  print(
    "Review agent findings: "
    f"{len(findings)} total ({errors} errors, {warnings} warnings, {notices} notices)",
  )
  for finding in findings:
    print(
      f"[{finding.level.upper()}] {finding.rule_id} "
      f"{finding.path}:{finding.line} - {finding.message}",
    )

  if args.emit_annotations:
    emit_annotations(findings)

  summary = render_summary_markdown(findings)
  if args.summary_file:
    args.summary_file.write_text(summary, encoding="utf-8")

  if args.json_file:
    args.json_file.write_text(
      json.dumps([asdict(f) for f in findings], indent=2),
      encoding="utf-8",
    )

  return 1 if should_fail(findings, args.fail_on) else 0


if __name__ == "__main__":
  raise SystemExit(main())
