#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LIB_DIR = ROOT / "lib"
TEST_DIR = ROOT / "test"
UNIT_TEST_DIR = TEST_DIR / "unit"
WIDGET_TEST_DIR = TEST_DIR / "widget"
INTEGRATION_TEST_DIR = ROOT / "integration_test"
PLAYWRIGHT_ROOT = ROOT / "playwright"
PLAYWRIGHT_TEST_DIR = PLAYWRIGHT_ROOT / "tests"
PLAYWRIGHT_SCREEN_TEST_DIR = PLAYWRIGHT_TEST_DIR / "screens"
PUBSPEC = ROOT / "pubspec.yaml"

UNIT_SOURCE_FOLDERS = {"services", "data", "models", "utils"}
WIDGET_SOURCE_FOLDERS = {"screens", "widgets"}
IGNORED_LIB_FILES = {"firebase_options.dart"}


@dataclass
class Scaffold:
    source: Path | None
    destination: Path
    kind: str
    content: str


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def title_from_stem(stem: str) -> str:
    return " ".join(word.capitalize() for word in stem.split("_"))


def package_name() -> str:
    if not PUBSPEC.exists():
        return "app"
    text = read_text(PUBSPEC)
    match = re.search(r"(?m)^\s*name\s*:\s*([a-zA-Z0-9_]+)\s*$", text)
    return match.group(1) if match else "app"


def has_integration_test_dependency() -> bool:
    if not PUBSPEC.exists():
        return False
    text = read_text(PUBSPEC)
    return bool(re.search(r"(?m)^\s*integration_test\s*:\s*$", text))


def should_include(rel_path: Path, filters: list[str]) -> bool:
    if rel_path.name in IGNORED_LIB_FILES:
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


def classify_source(rel_path: Path) -> str | None:
    if len(rel_path.parts) < 3:
        return None
    top_folder = rel_path.parts[1]
    if top_folder in UNIT_SOURCE_FOLDERS:
        return "unit"
    if top_folder in WIDGET_SOURCE_FOLDERS:
        return "widget"
    return None


def import_for_source(pkg: str, source_rel: Path) -> str:
    lib_rel = source_rel.relative_to("lib")
    return f"package:{pkg}/{lib_rel.as_posix()}"


def unit_test_destination(source_rel: Path) -> Path:
    sub = source_rel.relative_to("lib")
    return UNIT_TEST_DIR / sub.parent / f"{source_rel.stem}_test.dart"


def widget_test_destination(source_rel: Path) -> Path:
    sub = source_rel.relative_to("lib")
    return WIDGET_TEST_DIR / sub.parent / f"{source_rel.stem}_test.dart"


def integration_test_destination() -> Path:
    return INTEGRATION_TEST_DIR / "app_smoke_integration_test.dart"


def playwright_package_destination() -> Path:
    return PLAYWRIGHT_ROOT / "package.json"


def playwright_config_destination() -> Path:
    return PLAYWRIGHT_ROOT / "playwright.config.ts"


def playwright_test_destination() -> Path:
    return PLAYWRIGHT_TEST_DIR / "app-smoke.spec.ts"


def playwright_screen_test_destination(source_rel: Path) -> Path:
    sub = source_rel.relative_to("lib/screens")
    return PLAYWRIGHT_SCREEN_TEST_DIR / sub.parent / f"{source_rel.stem}.spec.ts"


def make_unit_scaffold(pkg: str, source_rel: Path) -> Scaffold:
    title = title_from_stem(source_rel.stem)
    source_import = import_for_source(pkg, source_rel)
    destination = unit_test_destination(source_rel)
    content = f"""// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import '{source_import}';

void main() {{
  group('{title} unit tests', () {{
    test('TODO: add behavioral assertions', () {{
      // TODO: Replace this scaffold with real unit tests.
      expect(true, isTrue);
    }}, skip: true);
  }});
}}
"""
    return Scaffold(source=source_rel, destination=destination, kind="unit", content=content)


def make_widget_scaffold(pkg: str, source_rel: Path) -> Scaffold:
    title = title_from_stem(source_rel.stem)
    source_import = import_for_source(pkg, source_rel)
    destination = widget_test_destination(source_rel)
    content = f"""// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import '{source_import}';

void main() {{
  testWidgets('TODO: {title} renders expected behavior', (tester) async {{
    // TODO: Pump the widget under test and assert visible behavior.
  }}, skip: true);
}}
"""
    return Scaffold(source=source_rel, destination=destination, kind="widget", content=content)


def make_integration_scaffold(pkg: str) -> Scaffold:
    destination = integration_test_destination()
    content = f"""import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:{pkg}/main.dart' as app;

void main() {{
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TODO: app launch integration flow', (tester) async {{
    app.main();
    await tester.pumpAndSettle();

    // TODO: Add integration assertions for startup and first navigation steps.
  }}, skip: true);
}}
"""
    return Scaffold(source=None, destination=destination, kind="integration", content=content)


def make_playwright_package_scaffold() -> Scaffold:
    destination = playwright_package_destination()
    content = """{
  "name": "quiznetic-playwright-e2e",
  "private": true,
  "type": "module",
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:headed": "playwright test --headed",
    "test:e2e:list": "playwright test --list",
    "install:browsers": "PLAYWRIGHT_BROWSERS_PATH=0 playwright install chromium"
  },
  "devDependencies": {
    "@playwright/test": "^1.50.0"
  }
}
"""
    return Scaffold(source=None, destination=destination, kind="e2e-playwright", content=content)


def make_playwright_config_scaffold() -> Scaffold:
    destination = playwright_config_destination()
    content = """import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
  },
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? 'http://127.0.0.1:7357',
    trace: 'on-first-retry',
  },
});
"""
    return Scaffold(source=None, destination=destination, kind="e2e-playwright", content=content)


def make_playwright_test_scaffold() -> Scaffold:
    destination = playwright_test_destination()
    content = """import { test, expect } from '@playwright/test';

test('loads either entry choice or home screen', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  const guestButton = page.getByRole('button', { name: 'Continue as Guest' });
  const homePrompt = page.getByText('Choose Your Quiz');

  const guestVisible = await guestButton.isVisible().catch(() => false);
  const homeVisible = await homePrompt.isVisible().catch(() => false);

  expect(guestVisible || homeVisible).toBeTruthy();
});
"""
    return Scaffold(source=None, destination=destination, kind="e2e-playwright", content=content)


def make_playwright_screen_test_scaffold(source_rel: Path) -> Scaffold:
    destination = playwright_screen_test_destination(source_rel)
    title = title_from_stem(source_rel.stem)
    content = f"""import {{ test, expect }} from '@playwright/test';

test.skip('{title} critical flow', async ({{ page }}) => {{
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // TODO: Navigate to {title} and assert user-visible behavior.
  await expect(page).toHaveTitle(/.+/);
}});
"""
    return Scaffold(
        source=source_rel,
        destination=destination,
        kind="e2e-playwright",
        content=content,
    )


def collect_source_files(filters: list[str]) -> list[Path]:
    out: list[Path] = []
    for path in sorted(LIB_DIR.rglob("*.dart")):
        rel = path.relative_to(ROOT)
        if classify_source(rel) is None:
            continue
        if not should_include(rel, filters):
            continue
        out.append(rel)
    return out


def build_scaffolds(
    filters: list[str],
    include_integration: bool,
    include_e2e: bool,
) -> list[Scaffold]:
    pkg = package_name()
    sources = collect_source_files(filters)
    screen_sources = [s for s in sources if len(s.parts) > 1 and s.parts[1] == "screens"]
    scaffolds: list[Scaffold] = []

    for source_rel in sources:
        kind = classify_source(source_rel)
        if kind == "unit":
            scaffolds.append(make_unit_scaffold(pkg, source_rel))
        elif kind == "widget":
            scaffolds.append(make_widget_scaffold(pkg, source_rel))

    if include_integration:
        scaffolds.append(make_integration_scaffold(pkg))

    if include_e2e:
        scaffolds.append(make_playwright_package_scaffold())
        scaffolds.append(make_playwright_config_scaffold())
        scaffolds.append(make_playwright_test_scaffold())
        for source_rel in screen_sources:
            scaffolds.append(make_playwright_screen_test_scaffold(source_rel))

    return scaffolds


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Testing agent: scaffolds unit/widget tests plus separated "
            "integration and Playwright e2e tests under test/, "
            "integration_test/, and playwright/."
        )
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write scaffold files. Without this flag, runs as dry-run.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing scaffold files instead of skipping them.",
    )
    parser.add_argument(
        "--skip-integration",
        action="store_true",
        help="Skip generating Flutter integration test scaffold.",
    )
    parser.add_argument(
        "--skip-e2e",
        action="store_true",
        help="Skip generating Playwright e2e scaffolds.",
    )
    parser.add_argument(
        "--targets",
        nargs="*",
        default=[],
        help="Optional relative paths to limit source scanning (files or folders).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    include_integration = not args.skip_integration
    include_e2e = not args.skip_e2e
    scaffolds = build_scaffolds(
        filters=args.targets,
        include_integration=include_integration,
        include_e2e=include_e2e,
    )

    creates: list[Scaffold] = []
    updates: list[Scaffold] = []
    skips: list[Path] = []

    for scaffold in scaffolds:
        if scaffold.destination.exists():
            if args.overwrite:
                updates.append(scaffold)
            else:
                skips.append(scaffold.destination.relative_to(ROOT))
        else:
            creates.append(scaffold)

    print("Testing agent plan:")
    print(f"- create: {len(creates)}")
    print(f"- update: {len(updates)}")
    print(f"- skip:   {len(skips)}")

    if skips:
        print("\nSkipped existing files:")
        for path in skips:
            print(f"- {path.as_posix()}")

    pending = creates + updates
    if pending:
        print("\nScaffolds to write:")
        for scaffold in pending:
            rel = scaffold.destination.relative_to(ROOT)
            print(f"- [{scaffold.kind}] {rel.as_posix()}")
    else:
        print("\nNo scaffold files needed.")

    if include_integration and not has_integration_test_dependency():
        print(
            "\nWarning: `integration_test` dependency not found in pubspec.yaml. "
            "Add it before running integration tests."
        )

    if include_e2e:
        print(
            "\nPlaywright note: install dependencies with "
            "`cd playwright && npm install` before running e2e tests."
        )

    if not args.apply:
        print("\nDry-run only. Re-run with --apply to write files.")
        return 0

    for scaffold in pending:
        scaffold.destination.parent.mkdir(parents=True, exist_ok=True)
        write_text(scaffold.destination, scaffold.content)

    print("\nScaffold files written.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
