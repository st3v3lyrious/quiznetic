#!/usr/bin/env python3
"""Synchronize Markdown planning files with GitHub Issues.

Source files:
- docs/ROADMAP.md
- docs/FEATURES.md
- docs/ISSUES.md
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Optional

try:
    from github import Github
    try:
        from github import Auth
    except ImportError:
        Auth = None  # type: ignore[assignment]
    from github.GithubException import GithubException, UnknownObjectException
    from github.Issue import Issue
    from github.Label import Label
    from github.Milestone import Milestone
    from github.Repository import Repository

    PYGITHUB_IMPORT_ERROR: Optional[Exception] = None
except ModuleNotFoundError as exc:
    Github = None  # type: ignore[assignment]
    Auth = None  # type: ignore[assignment]
    PYGITHUB_IMPORT_ERROR = exc

    class GithubException(Exception):
        """Fallback GitHub exception type when PyGithub is unavailable."""

    class UnknownObjectException(GithubException):
        """Fallback unknown-object exception when PyGithub is unavailable."""

    Issue = object  # type: ignore[assignment]
    Label = object  # type: ignore[assignment]
    Milestone = object  # type: ignore[assignment]
    Repository = object  # type: ignore[assignment]


REQUIRED_TYPE_LABELS = {"roadmap", "feature", "bug"}
REQUIRED_PRIORITY_LABELS = {"p0", "p1", "p2"}
REQUIRED_AREA_LABELS = {
    "auth",
    "leaderboard",
    "scores",
    "profile",
    "navigation",
    "tests",
    "firebase",
    "firestore",
    "accessibility",
    "docs",
}
REQUIRED_LABELS = (
    REQUIRED_TYPE_LABELS | REQUIRED_PRIORITY_LABELS | REQUIRED_AREA_LABELS
)
REQUIRED_MILESTONES = ("MVP", "MVP+1")

ROADMAP_PATH = Path("docs/ROADMAP.md")
FEATURES_PATH = Path("docs/FEATURES.md")
ISSUES_PATH = Path("docs/ISSUES.md")

ANCHOR_RE = re.compile(r"\s*<!--gh:issue=(?P<number>\d+)-->\s*$")
ROADMAP_TASK_RE = re.compile(
    r"^- \[(?P<check>[ xX])\] (?P<phase>M(?P<phase_num>\d+)): "
    r"(?P<title>.*?)(?:\s*<!--gh:issue=(?P<issue>\d+)-->)?\s*$"
)
FEATURE_TASK_RE = re.compile(
    r"^- \[(?P<check>[ xX])\] "
    r"(?P<title>.*?)(?:\s*<!--gh:issue=(?P<issue>\d+)-->)?\s*$"
)
SECTION_RE = re.compile(r"^##\s+(?P<name>.+?)\s*$")

CONTEXT_EXAMPLE = (
    "Example local runs:\n"
    "  export GITHUB_TOKEN=ghp_xxx\n"
    "  export GITHUB_REPOSITORY=owner/repo\n"
    "  python sync_md_to_gh.py --dry-run\n\n"
    "Or authenticate with GitHub CLI:\n"
    "  gh auth login\n"
    "  python sync_md_to_gh.py --dry-run"
)

NO_GITHUB_TOKEN_ERROR = (
    "No GitHub token found.\n"
    "Set GITHUB_TOKEN or run 'gh auth login'."
)

_LAST_GH_AUTH_ERROR: Optional[str] = None

AREA_PATTERNS: dict[str, tuple[re.Pattern[str], ...]] = {
    "auth": (
        re.compile(r"\bauth\b", re.IGNORECASE),
        re.compile(r"\blogin\b", re.IGNORECASE),
        re.compile(r"\bgoogle\b", re.IGNORECASE),
        re.compile(r"\bapple\b", re.IGNORECASE),
    ),
    "leaderboard": (re.compile(r"\bleaderboard\b", re.IGNORECASE),),
    "scores": (
        re.compile(r"\bbest[-\s]?score\b", re.IGNORECASE),
        re.compile(r"\bscores?\b", re.IGNORECASE),
    ),
    "profile": (re.compile(r"\bprofile\b", re.IGNORECASE),),
    "navigation": (
        re.compile(r"\broute\b", re.IGNORECASE),
        re.compile(r"\bnavigation\b", re.IGNORECASE),
    ),
    "tests": (
        re.compile(r"\btests?\b", re.IGNORECASE),
        re.compile(r"\bunit\b", re.IGNORECASE),
        re.compile(r"\bwidget\b", re.IGNORECASE),
        re.compile(r"\bintegration\b", re.IGNORECASE),
        re.compile(r"\bplaywright\b", re.IGNORECASE),
        re.compile(r"\be2e\b", re.IGNORECASE),
    ),
    "firebase": (re.compile(r"\bfirebase\b", re.IGNORECASE),),
    "firestore": (re.compile(r"\bfirestore\b", re.IGNORECASE),),
    "accessibility": (
        re.compile(r"\baccessibility\b", re.IGNORECASE),
        re.compile(r"\bvisual\b", re.IGNORECASE),
        re.compile(r"\baudio\b", re.IGNORECASE),
        re.compile(r"\bvoice\b", re.IGNORECASE),
    ),
    "docs": (
        re.compile(r"\breadme\b", re.IGNORECASE),
        re.compile(r"\bdocs?\b", re.IGNORECASE),
        re.compile(r"\broadmap\b", re.IGNORECASE),
        re.compile(r"\bfeatures\b", re.IGNORECASE),
        re.compile(r"\barchitecture\b", re.IGNORECASE),
    ),
}


class SyncError(RuntimeError):
    """Raised when synchronization cannot proceed safely."""


@dataclass
class Stats:
    created: int = 0
    updated: int = 0
    closed: int = 0
    skipped: int = 0
    warnings: int = 0


@dataclass
class DesiredIssue:
    title: str
    body: str
    state: str  # "open" or "closed"
    labels: list[str]
    milestone_title: str


@dataclass
class RoadmapTask:
    line_index: int
    phase: str
    phase_num: int
    title: str
    checked: bool
    issue_ref: Optional[int]


@dataclass
class FeatureTask:
    line_index: int
    section: str
    title: str
    checked: bool
    issue_ref: Optional[int]
    nested_checklist: list[str] = field(default_factory=list)


@dataclass
class IssuesTableRow:
    line_index: int
    section: str
    header_index: dict[str, int]
    cells: list[str]


@dataclass
class CliOptions:
    dry_run: bool
    verbose: bool
    allow_reopen: bool
    check_labels: bool


def verbose_log(enabled: bool, message: str) -> None:
    if enabled:
        print(message)


def warn(stats: Stats, message: str) -> None:
    stats.warnings += 1
    print(f"WARNING: {message}", file=sys.stderr)


def normalize_header(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def strip_backticks(value: str) -> str:
    return value.strip().strip("`").strip()


def parse_issue_number(value: str) -> Optional[int]:
    text = value.strip()
    if not text:
        return None
    match = re.search(r"#(?P<n>\d+)", text)
    if match:
        return int(match.group("n"))
    if text.isdigit():
        return int(text)
    return None


def infer_area_labels(text: str) -> set[str]:
    labels: set[str] = set()
    for area, patterns in AREA_PATTERNS.items():
        if any(pattern.search(text) for pattern in patterns):
            labels.add(area)
    return labels


def read_lines(path: Path) -> list[str]:
    if not path.exists():
        raise SyncError(f"Missing required file: {path}")
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def write_lines(path: Path, lines: list[str]) -> None:
    path.write_text("".join(lines), encoding="utf-8")


def render_anchor_line(original_line: str, issue_number: int) -> str:
    newline = "\n" if original_line.endswith("\n") else ""
    base = ANCHOR_RE.sub("", original_line.rstrip("\n")).rstrip()
    return f"{base} <!--gh:issue={issue_number}-->{newline}"


def parse_roadmap_tasks(lines: list[str]) -> list[RoadmapTask]:
    tasks: list[RoadmapTask] = []
    for idx, line in enumerate(lines):
        match = ROADMAP_TASK_RE.match(line.rstrip("\n"))
        if not match:
            continue
        issue_ref = (
            int(match.group("issue")) if match.group("issue") is not None else None
        )
        tasks.append(
            RoadmapTask(
                line_index=idx,
                phase=match.group("phase"),
                phase_num=int(match.group("phase_num")),
                title=match.group("title").strip(),
                checked=match.group("check").lower() == "x",
                issue_ref=issue_ref,
            )
        )
    return tasks


def parse_feature_tasks(lines: list[str]) -> list[FeatureTask]:
    tasks: list[FeatureTask] = []
    current_section = "Uncategorized"
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        section_match = SECTION_RE.match(line.rstrip("\n"))
        if section_match:
            current_section = section_match.group("name").strip()

        match = FEATURE_TASK_RE.match(line.rstrip("\n"))
        if not match:
            idx += 1
            continue

        issue_ref = (
            int(match.group("issue")) if match.group("issue") is not None else None
        )
        nested: list[str] = []
        scan = idx + 1
        while scan < len(lines):
            next_line = lines[scan]
            if FEATURE_TASK_RE.match(next_line.rstrip("\n")):
                break
            if SECTION_RE.match(next_line.rstrip("\n")):
                break
            if next_line.startswith("  ") and re.match(
                r"^\s*-\s+\[[ xX]\]\s+", next_line
            ):
                nested.append(next_line.rstrip("\n"))
                scan += 1
                continue
            if next_line.startswith("    ") and re.match(
                r"^\s*-\s+\[[ xX]\]\s+", next_line
            ):
                nested.append(next_line.rstrip("\n"))
                scan += 1
                continue
            if next_line.strip() == "":
                scan += 1
                continue
            break

        tasks.append(
            FeatureTask(
                line_index=idx,
                section=current_section,
                title=match.group("title").strip(),
                checked=match.group("check").lower() == "x",
                issue_ref=issue_ref,
                nested_checklist=nested,
            )
        )
        idx += 1
    return tasks


def is_separator_row(line: str) -> bool:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return False
    cells = [cell.strip() for cell in stripped.strip("|").split("|")]
    if not cells:
        return False
    return all(bool(cell) and set(cell) <= {"-", ":"} for cell in cells)


def split_markdown_row(line: str) -> list[str]:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        raise ValueError(f"Not a markdown table row: {line!r}")
    return [cell.strip() for cell in stripped.strip("|").split("|")]


def render_markdown_row(cells: list[str], original_line: str) -> str:
    newline = "\n" if original_line.endswith("\n") else ""
    return f"| {' | '.join(cells)} |{newline}"


def parse_issues_rows(lines: list[str], stats: Stats) -> list[IssuesTableRow]:
    rows: list[IssuesTableRow] = []
    current_section = "Uncategorized"
    idx = 0
    required_columns = {
        "id",
        "severity",
        "scope",
        "status",
        "issue",
        "owner",
        "targetdate",
        "gh",
    }

    while idx < len(lines):
        line = lines[idx]
        section_match = SECTION_RE.match(line.rstrip("\n"))
        if section_match:
            current_section = section_match.group("name").strip()

        if idx + 1 < len(lines) and line.strip().startswith("|") and is_separator_row(
            lines[idx + 1]
        ):
            header_cells = split_markdown_row(line)
            header_index = {
                normalize_header(name): column for column, name in enumerate(header_cells)
            }
            if required_columns.issubset(header_index):
                idx += 2
                while idx < len(lines) and lines[idx].strip().startswith("|"):
                    row_line = lines[idx]
                    if is_separator_row(row_line):
                        idx += 1
                        continue
                    cells = split_markdown_row(row_line)
                    if len(cells) < len(header_cells):
                        warn(
                            stats,
                            f"Skipping malformed ISSUES.md row at line {idx + 1}: "
                            "column count mismatch.",
                        )
                        idx += 1
                        continue
                    rows.append(
                        IssuesTableRow(
                            line_index=idx,
                            section=current_section,
                            header_index=header_index,
                            cells=cells,
                        )
                    )
                    idx += 1
                continue
        idx += 1
    return rows


def parse_git_remote_owner_repo(remote_url: str) -> tuple[str, str]:
    url = remote_url.strip()
    if not url:
        raise SyncError("git remote origin URL is empty.")

    remainder: Optional[str] = None
    if url.startswith("git@github.com:"):
        remainder = url.split(":", 1)[1]
    elif "github.com/" in url:
        remainder = url.split("github.com/", 1)[1]

    if remainder is None:
        raise SyncError(
            "Unable to parse owner/repo from git origin URL. "
            f"Found: {remote_url!r}"
        )

    remainder = remainder.strip().strip("/")
    if remainder.endswith(".git"):
        remainder = remainder[:-4]

    parts = remainder.split("/")
    if len(parts) < 2:
        raise SyncError(
            "Unable to parse owner/repo from git origin URL. "
            f"Found: {remote_url!r}"
        )
    owner, repo = parts[0].strip(), parts[1].strip()
    if not owner or not repo:
        raise SyncError(
            "Unable to parse owner/repo from git origin URL. "
            f"Found: {remote_url!r}"
        )
    return owner, repo


def _set_last_gh_auth_error(value: str) -> None:
    global _LAST_GH_AUTH_ERROR
    _LAST_GH_AUTH_ERROR = value


def resolve_github_token() -> str:
    token = os.getenv("GITHUB_TOKEN", "").strip()
    if len(token) > 10:
        return token
    if token:
        _set_last_gh_auth_error("GITHUB_TOKEN is set but appears invalid (too short).")

    try:
        result = subprocess.run(
            ["gh", "auth", "token"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        _set_last_gh_auth_error("GitHub CLI not found in PATH.")
        raise RuntimeError(NO_GITHUB_TOKEN_ERROR)
    except subprocess.CalledProcessError as exc:
        detail = ""
        if exc.stderr:
            detail = exc.stderr.strip()
        if detail:
            _set_last_gh_auth_error(
                f"'gh auth token' failed (exit {exc.returncode}): {detail}"
            )
        else:
            _set_last_gh_auth_error(
                f"'gh auth token' failed (exit {exc.returncode})."
            )
        raise RuntimeError(NO_GITHUB_TOKEN_ERROR)

    gh_token = result.stdout.strip()
    if len(gh_token) > 10:
        return gh_token

    _set_last_gh_auth_error("'gh auth token' returned an empty/invalid token.")
    raise RuntimeError(NO_GITHUB_TOKEN_ERROR)


def resolve_github_context(verbose: bool = False) -> tuple[str, str, str]:
    """Resolve (token, owner, repo) from Actions/local context.

    Priority:
    - token via resolve_github_token() (env var, then `gh auth token`)
    - GITHUB_REPOSITORY env for owner/repo
    - fallback to parsing `git remote get-url origin`
    """
    try:
        token = resolve_github_token()
    except RuntimeError as exc:
        if verbose and _LAST_GH_AUTH_ERROR:
            verbose_log(verbose, f"Token resolution detail: {_LAST_GH_AUTH_ERROR}")
        raise SyncError(str(exc)) from exc

    repo_env = os.getenv("GITHUB_REPOSITORY", "").strip()
    if repo_env:
        if "/" not in repo_env:
            raise SyncError(
                "Invalid GITHUB_REPOSITORY format. Expected 'owner/repo', got "
                f"{repo_env!r}.\n{CONTEXT_EXAMPLE}"
            )
        owner, repo = repo_env.split("/", 1)
        owner, repo = owner.strip(), repo.strip()
        if not owner or not repo:
            raise SyncError(
                "Invalid GITHUB_REPOSITORY format. Expected 'owner/repo'.\n"
                f"{CONTEXT_EXAMPLE}"
            )
        return token, owner, repo

    try:
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise SyncError(
            "Could not run git to detect repository. "
            "Set GITHUB_REPOSITORY=owner/repo explicitly.\n"
            f"{CONTEXT_EXAMPLE}"
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise SyncError(
            "Could not infer repository from git origin. "
            "Set GITHUB_REPOSITORY=owner/repo explicitly.\n"
            f"{CONTEXT_EXAMPLE}"
        ) from exc

    owner, repo = parse_git_remote_owner_repo(result.stdout)
    return token, owner, repo


def load_labels(repo: Repository) -> dict[str, Label]:
    labels = {label.name: label for label in repo.get_labels()}
    return labels


def validate_required_labels(
    labels_by_name: dict[str, Label], check_only: bool
) -> None:
    missing = sorted(label for label in REQUIRED_LABELS if label not in labels_by_name)
    if missing:
        context = (
            "--check-labels validation failed" if check_only else "sync precheck failed"
        )
        raise SyncError(
            f"{context}: missing required labels: {', '.join(missing)}.\n"
            "Create the labels in GitHub first. This tool will not auto-create labels."
        )


def ensure_milestones(
    repo: Repository, dry_run: bool, verbose: bool
) -> dict[str, Optional[Milestone]]:
    milestones_by_title: dict[str, Optional[Milestone]] = {
        milestone.title: milestone for milestone in repo.get_milestones(state="all")
    }

    for title in REQUIRED_MILESTONES:
        if title in milestones_by_title:
            continue
        if dry_run:
            verbose_log(verbose, f"[dry-run] Would create milestone: {title}")
            milestones_by_title[title] = None
            continue
        milestone = repo.create_milestone(title=title, state="open")
        milestones_by_title[title] = milestone
        verbose_log(verbose, f"Created milestone: {title}")

    return milestones_by_title


def get_issue_or_none(
    repo: Repository,
    issue_number: int,
    stats: Stats,
    context: str,
) -> Optional[Issue]:
    try:
        issue = repo.get_issue(number=issue_number)
    except UnknownObjectException:
        warn(stats, f"{context}: referenced issue #{issue_number} not found.")
        return None
    except GithubException as exc:
        raise SyncError(
            f"{context}: failed to fetch issue #{issue_number}: {exc.data or exc}"
        ) from exc

    if issue.pull_request is not None:
        warn(
            stats,
            f"{context}: reference #{issue_number} points to a pull request; "
            "creating a new issue instead.",
        )
        return None
    return issue


def desired_milestone_title_for_roadmap(phase_num: int) -> str:
    return "MVP" if phase_num <= 5 else "MVP+1"


def desired_milestone_title_for_feature(title: str) -> str:
    if "deferred outside mvp scope" in title.lower():
        return "MVP+1"
    return "MVP"


def desired_milestone_title_for_issues_scope(scope: str) -> str:
    return "MVP+1" if "mvp+1" in scope.lower() else "MVP"


def desired_state_from_checkbox(checked: bool) -> str:
    return "closed" if checked else "open"


def build_roadmap_body(task: RoadmapTask) -> str:
    mark = "x" if task.checked else " "
    return (
        "Source: docs/ROADMAP.md\n"
        f"Phase: {task.phase}\n\n"
        "Task:\n"
        f"- [{mark}] {task.phase}: {task.title}\n"
    )


def build_feature_body(task: FeatureTask) -> str:
    mark = "x" if task.checked else " "
    lines = [
        "Source: docs/FEATURES.md",
        f"Section: {task.section}",
        "",
        "Task:",
        f"- [{mark}] {task.title}",
    ]
    if task.nested_checklist:
        lines.append("")
        lines.append("Nested checklist:")
        lines.extend(task.nested_checklist)
    return "\n".join(lines).rstrip() + "\n"


def build_issues_body(
    issue_id: str,
    severity: str,
    scope: str,
    status: str,
    issue_text: str,
    owner: str,
    target_date: str,
) -> str:
    return (
        "Source: docs/ISSUES.md\n"
        f"Issue ID: {issue_id}\n"
        f"Severity: {severity}\n"
        f"Scope: {scope}\n"
        f"Status: {status}\n"
        f"Owner: {owner}\n"
        f"Target Date: {target_date}\n\n"
        "Issue:\n"
        f"{issue_text}\n"
    )


def ensure_labels_exist(
    desired_labels: Iterable[str], labels_by_name: dict[str, Label], context: str
) -> None:
    missing = sorted(label for label in desired_labels if label not in labels_by_name)
    if missing:
        raise SyncError(
            f"{context}: required labels missing in repository: {', '.join(missing)}. "
            "Create labels manually; this tool does not auto-create labels."
        )


def maybe_edit_issue(
    issue: Issue,
    desired: DesiredIssue,
    labels_by_name: dict[str, Label],
    milestone_by_title: dict[str, Optional[Milestone]],
    opts: CliOptions,
    stats: Stats,
    context: str,
) -> None:
    desired_label_set = set(desired.labels)
    current_label_set = {label.name for label in issue.labels}
    current_milestone_title = issue.milestone.title if issue.milestone else None
    desired_milestone_title = desired.milestone_title

    metadata_changes: dict[str, object] = {}
    if issue.title != desired.title:
        metadata_changes["title"] = desired.title
    if (issue.body or "") != desired.body:
        metadata_changes["body"] = desired.body
    if current_label_set != desired_label_set:
        ensure_labels_exist(desired.labels, labels_by_name, context)
        metadata_changes["labels"] = [labels_by_name[name] for name in desired.labels]
    if current_milestone_title != desired_milestone_title:
        milestone_obj = milestone_by_title.get(desired_milestone_title)
        if milestone_obj is None and not opts.dry_run:
            raise SyncError(
                f"{context}: milestone '{desired_milestone_title}' is missing."
            )
        metadata_changes["milestone"] = milestone_obj

    desired_state = desired.state
    current_state = issue.state
    state_change: Optional[str] = None
    reopen_blocked = False

    if desired_state == "closed" and current_state != "closed":
        state_change = "closed"
    elif desired_state == "open" and current_state == "closed":
        if opts.allow_reopen:
            state_change = "open"
        else:
            reopen_blocked = True
            warn(
                stats,
                f"{context}: issue #{issue.number} is closed, desired state is open; "
                "skipping reopen because --allow-reopen is not set.",
            )

    has_metadata_updates = bool(metadata_changes)
    has_state_update = state_change is not None
    if not has_metadata_updates and not has_state_update:
        stats.skipped += 1
        return

    if opts.dry_run:
        if has_metadata_updates or state_change == "open":
            stats.updated += 1
        if state_change == "closed":
            stats.closed += 1
        if reopen_blocked and not has_metadata_updates:
            stats.skipped += 1
        return

    edit_kwargs = dict(metadata_changes)
    if state_change is not None:
        edit_kwargs["state"] = state_change

    if edit_kwargs:
        issue.edit(**edit_kwargs)
        if has_metadata_updates or state_change == "open":
            stats.updated += 1
        if state_change == "closed":
            stats.closed += 1


def sync_issue_reference(
    repo: Repository,
    issue_ref: Optional[int],
    desired: DesiredIssue,
    labels_by_name: dict[str, Label],
    milestone_by_title: dict[str, Optional[Milestone]],
    opts: CliOptions,
    stats: Stats,
    context: str,
) -> Optional[int]:
    issue: Optional[Issue] = None
    if issue_ref is not None:
        issue = get_issue_or_none(repo, issue_ref, stats=stats, context=context)

    if issue is None:
        ensure_labels_exist(desired.labels, labels_by_name, context)
        milestone_obj = milestone_by_title.get(desired.milestone_title)
        if milestone_obj is None and not opts.dry_run:
            raise SyncError(f"{context}: milestone '{desired.milestone_title}' missing.")

        if opts.dry_run:
            stats.created += 1
            if desired.state == "closed":
                stats.closed += 1
            return None

        issue = repo.create_issue(
            title=desired.title,
            body=desired.body,
            labels=[labels_by_name[name] for name in desired.labels],
            milestone=milestone_obj,
        )
        stats.created += 1
        if desired.state == "closed":
            issue.edit(state="closed")
            stats.closed += 1
        return issue.number

    maybe_edit_issue(
        issue=issue,
        desired=desired,
        labels_by_name=labels_by_name,
        milestone_by_title=milestone_by_title,
        opts=opts,
        stats=stats,
        context=context,
    )
    return issue.number


def sync_roadmap(
    repo: Repository,
    labels_by_name: dict[str, Label],
    milestone_by_title: dict[str, Optional[Milestone]],
    opts: CliOptions,
    stats: Stats,
    verbose: bool,
) -> None:
    lines = read_lines(ROADMAP_PATH)
    tasks = parse_roadmap_tasks(lines)
    changed = False

    for task in tasks:
        label_set = {"roadmap"} | infer_area_labels(task.title)
        desired = DesiredIssue(
            title=f"ROADMAP {task.phase}: {task.title}",
            body=build_roadmap_body(task),
            state=desired_state_from_checkbox(task.checked),
            labels=sorted(label_set),
            milestone_title=desired_milestone_title_for_roadmap(task.phase_num),
        )
        context = f"ROADMAP line {task.line_index + 1} ({task.phase})"
        number = sync_issue_reference(
            repo=repo,
            issue_ref=task.issue_ref,
            desired=desired,
            labels_by_name=labels_by_name,
            milestone_by_title=milestone_by_title,
            opts=opts,
            stats=stats,
            context=context,
        )
        if number is not None and task.issue_ref != number:
            if opts.dry_run:
                verbose_log(
                    verbose,
                    f"[dry-run] Would set anchor in {ROADMAP_PATH} line "
                    f"{task.line_index + 1} to issue #{number}",
                )
            else:
                lines[task.line_index] = render_anchor_line(lines[task.line_index], number)
                changed = True

    if changed and not opts.dry_run:
        write_lines(ROADMAP_PATH, lines)


def sync_features(
    repo: Repository,
    labels_by_name: dict[str, Label],
    milestone_by_title: dict[str, Optional[Milestone]],
    opts: CliOptions,
    stats: Stats,
    verbose: bool,
) -> None:
    lines = read_lines(FEATURES_PATH)
    tasks = parse_feature_tasks(lines)
    changed = False

    for task in tasks:
        label_set = {"feature"} | infer_area_labels(task.title)
        desired = DesiredIssue(
            title=f"FEATURE: {task.title}",
            body=build_feature_body(task),
            state=desired_state_from_checkbox(task.checked),
            labels=sorted(label_set),
            milestone_title=desired_milestone_title_for_feature(task.title),
        )
        context = f"FEATURES line {task.line_index + 1}"
        number = sync_issue_reference(
            repo=repo,
            issue_ref=task.issue_ref,
            desired=desired,
            labels_by_name=labels_by_name,
            milestone_by_title=milestone_by_title,
            opts=opts,
            stats=stats,
            context=context,
        )
        if number is not None and task.issue_ref != number:
            if opts.dry_run:
                verbose_log(
                    verbose,
                    f"[dry-run] Would set anchor in {FEATURES_PATH} line "
                    f"{task.line_index + 1} to issue #{number}",
                )
            else:
                lines[task.line_index] = render_anchor_line(lines[task.line_index], number)
                changed = True

    if changed and not opts.dry_run:
        write_lines(FEATURES_PATH, lines)


def sync_issues_table(
    repo: Repository,
    labels_by_name: dict[str, Label],
    milestone_by_title: dict[str, Optional[Milestone]],
    opts: CliOptions,
    stats: Stats,
    verbose: bool,
) -> None:
    lines = read_lines(ISSUES_PATH)
    rows = parse_issues_rows(lines, stats=stats)
    changed = False

    for row in rows:
        header = row.header_index

        issue_id = strip_backticks(row.cells[header["id"]])
        severity = strip_backticks(row.cells[header["severity"]])
        scope = strip_backticks(row.cells[header["scope"]])
        status = strip_backticks(row.cells[header["status"]])
        issue_text = strip_backticks(row.cells[header["issue"]])
        owner = strip_backticks(row.cells[header["owner"]])
        target_date = strip_backticks(row.cells[header["targetdate"]])
        gh_ref_text = row.cells[header["gh"]].strip()

        if not issue_id or not issue_text:
            warn(
                stats,
                f"ISSUES line {row.line_index + 1}: missing ID or Issue text; skipping row.",
            )
            continue

        severity_lower = severity.lower()
        if severity_lower not in {"p0", "p1", "p2"}:
            warn(
                stats,
                f"ISSUES line {row.line_index + 1}: unknown severity {severity!r}; "
                "defaulting to p2.",
            )
            priority = "p2"
        else:
            priority = severity_lower

        desired = DesiredIssue(
            title=f"[{issue_id}] {issue_text}",
            body=build_issues_body(
                issue_id=issue_id,
                severity=severity,
                scope=scope,
                status=status,
                issue_text=issue_text,
                owner=owner,
                target_date=target_date,
            ),
            state="closed" if status.lower() == "done" else "open",
            labels=sorted({"bug", priority} | infer_area_labels(issue_text)),
            milestone_title=desired_milestone_title_for_issues_scope(scope),
        )

        issue_ref = parse_issue_number(gh_ref_text)
        if gh_ref_text and issue_ref is None:
            warn(
                stats,
                f"ISSUES line {row.line_index + 1}: invalid GH reference "
                f"{gh_ref_text!r}; creating a new issue.",
            )

        context = f"ISSUES line {row.line_index + 1} ({issue_id})"
        number = sync_issue_reference(
            repo=repo,
            issue_ref=issue_ref,
            desired=desired,
            labels_by_name=labels_by_name,
            milestone_by_title=milestone_by_title,
            opts=opts,
            stats=stats,
            context=context,
        )

        if number is not None:
            desired_gh = f"#{number}"
            if gh_ref_text != desired_gh:
                if opts.dry_run:
                    verbose_log(
                        verbose,
                        f"[dry-run] Would update {ISSUES_PATH} line {row.line_index + 1} "
                        f"GH cell to {desired_gh}",
                    )
                else:
                    row.cells[header["gh"]] = desired_gh
                    lines[row.line_index] = render_markdown_row(
                        row.cells, lines[row.line_index]
                    )
                    changed = True

    if changed and not opts.dry_run:
        write_lines(ISSUES_PATH, lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sync docs/ROADMAP.md, docs/FEATURES.md, and docs/ISSUES.md "
        "with GitHub Issues."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show planned actions without writing to GitHub or files.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logs.",
    )
    parser.add_argument(
        "--allow-reopen",
        action="store_true",
        help="Allow reopening closed issues when Markdown indicates open state.",
    )
    parser.add_argument(
        "--check-labels",
        action="store_true",
        help="Validate required labels exist and exit.",
    )
    return parser


def run(opts: CliOptions) -> int:
    stats = Stats()
    if Github is None:
        raise SyncError(
            "PyGithub is not installed. Install dependencies first:\n"
            "  python3.11 -m pip install -r requirements.txt"
        ) from PYGITHUB_IMPORT_ERROR

    token, owner, repo_name = resolve_github_context(verbose=opts.verbose)
    verbose_log(opts.verbose, f"Resolved repository: {owner}/{repo_name}")

    if Auth is not None:
        gh = Github(auth=Auth.Token(token))
    else:
        # Backward compatibility for older PyGithub versions without Auth API.
        gh = Github(login_or_token=token)
    try:
        repo = gh.get_repo(f"{owner}/{repo_name}")
    except GithubException as exc:
        raise SyncError(
            f"Failed to access repository {owner}/{repo_name}: {exc.data or exc}"
        ) from exc

    labels_by_name = load_labels(repo)
    validate_required_labels(labels_by_name, check_only=opts.check_labels)
    if opts.check_labels:
        print("Required labels are present.")
        return 0

    milestone_by_title = ensure_milestones(
        repo=repo,
        dry_run=opts.dry_run,
        verbose=opts.verbose,
    )

    sync_roadmap(
        repo=repo,
        labels_by_name=labels_by_name,
        milestone_by_title=milestone_by_title,
        opts=opts,
        stats=stats,
        verbose=opts.verbose,
    )
    sync_features(
        repo=repo,
        labels_by_name=labels_by_name,
        milestone_by_title=milestone_by_title,
        opts=opts,
        stats=stats,
        verbose=opts.verbose,
    )
    sync_issues_table(
        repo=repo,
        labels_by_name=labels_by_name,
        milestone_by_title=milestone_by_title,
        opts=opts,
        stats=stats,
        verbose=opts.verbose,
    )

    print(
        "Sync summary: "
        f"created={stats.created} "
        f"updated={stats.updated} "
        f"closed={stats.closed} "
        f"skipped={stats.skipped} "
        f"warnings={stats.warnings}"
    )
    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    opts = CliOptions(
        dry_run=args.dry_run,
        verbose=args.verbose,
        allow_reopen=args.allow_reopen,
        check_labels=args.check_labels,
    )
    try:
        return run(opts)
    except SyncError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
