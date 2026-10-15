import { test, expect, type Page } from '@playwright/test';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

// Dedicated emulator build only. No production Firebase data is touched.
test.skip(process.env.NAVIGATION_EMULATORS !== 'true', 'Requires web_navigation_app.dart and Firebase emulators');
async function semantics(page: Page) {
  await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder, flt-semantics-host'));
  await page.locator('flt-semantics-placeholder').evaluateAll(nodes => nodes.forEach(node => (node as HTMLElement).click()));
}
async function open(page: Page, location: string) {
  await page.goto(`/#${location}`); await semantics(page);
}
async function guest(page: Page, location = '/home') {
  await open(page, location);
  await page.getByRole('button', { name: 'Continue as Guest', exact: true }).click();
}
async function capture(page: Page, name: string) {
  await page.screenshot({ path: path.join(process.env.NAVIGATION_SCREENSHOTS ?? 'test-results/navigation', `${name}.png`), fullPage: false });
}
test.beforeAll(async ({ request }) => {
  const database = 'projects/demo-quiznetic/databases/(default)/documents';
  const writes = ['flag_easy', 'capital_easy', 'capital_expert'].flatMap(scope =>
    [14, 12, 9].map((score, index) => ({ update: {
      name: `${database}/leaderboard/${scope}/entries/demo-player-${index}`,
      fields: {
        categoryKey: { stringValue: scope.split('_')[0] },
        difficulty: { stringValue: scope.split('_')[1] },
        score: { integerValue: String(score) }, isAnonymous: { booleanValue: false },
        displayName: { stringValue: ['Demo Alex', 'Demo Sam', 'Demo Camille'][index] },
        updatedAt: { timestampValue: '2026-10-15T09:00:00Z' },
      },
    } })),
  );
  const response = await request.post('http://127.0.0.1:8080/v1/projects/demo-quiznetic/databases/(default)/documents:commit', {
    headers: { Authorization: 'Bearer owner' }, data: { writes },
  });
  expect(response.ok()).toBeTruthy();
});
test.beforeEach(async ({ page }) => {
  // Optional SDK cache downloaded with normal TLS verification, for managed
  // environments whose browser store does not trust the session proxy CA.
  if (process.env.FIREBASE_SDK_CACHE) {
    await page.route('https://www.gstatic.com/firebasejs/*/*.js', async route => {
      const filename = new URL(route.request().url()).pathname.split('/').pop()!;
      await route.fulfill({ body: await readFile(path.join(process.env.FIREBASE_SDK_CACHE!, filename)), contentType: 'application/javascript', headers: { 'access-control-allow-origin': '*' } });
    });
  }
});
for (const [device, viewport] of Object.entries({ desktop: { width: 1280, height: 900 }, mobile: { width: 390, height: 844 } })) {
  test.describe(device, () => {
    test.use({ viewport });
    let errors: string[];
    test.beforeEach(async ({ page }) => {
      errors = []; page.on('pageerror', error => errors.push(error.message));
    });
    test.afterEach(() => expect(errors).toEqual([]));
    test('leaderboard survives guest authentication, filters and refresh', async ({ page }) => {
      await guest(page, '/leaderboard');
      await expect(page.getByText(/Showing top 3/)).toBeVisible();
      await page.getByRole('button', { name: 'Flag Quiz', exact: true }).click();
      await page.getByRole('menuitem', { name: 'Capital Quiz', exact: true }).click();
      await page.getByRole('button', { name: 'Easy', exact: true }).click();
      await page.getByRole('menuitem', { name: 'Expert', exact: true }).click();
      await expect(page).toHaveURL(/#\/leaderboard\?category=capital&difficulty=expert$/);
      await page.reload(); await semantics(page);
      await expect(page.getByText(/Showing top 3/)).toBeVisible();
      await expect(page.getByRole('button', { name: 'Capital Quiz', exact: true })).toBeVisible();
      await expect(page.getByRole('button', { name: 'Expert', exact: true })).toBeVisible();
      await capture(page, `${device}-leaderboard-refreshed`);
    });
    test('browser back and forward restore screens', async ({ page }) => {
      await guest(page);
      await expect(page.getByText('Choose Your Quiz', { exact: true })).toBeVisible();
      await page.getByRole('button', { name: 'Leaderboard', exact: true }).click();
      await expect(page.getByText('Global Leaderboard', { exact: true })).toBeVisible();
      await page.goBack();
      await expect(page.getByText('Choose Your Quiz', { exact: true })).toBeVisible();
      await page.goForward();
      await expect(page.getByText('Global Leaderboard', { exact: true })).toBeVisible();
      await page.getByRole('button', { name: 'Back', exact: true }).click();
      await expect(page.getByText('Choose Your Quiz', { exact: true })).toBeVisible();
    });
    test('profile, settings and difficulty restore on refresh', async ({ page }) => {
      await guest(page, '/settings');
      await expect(page.getByText('Settings', { exact: true })).toBeVisible();
      await page.reload(); await semantics(page);
      await expect(page.getByText('Settings', { exact: true })).toBeVisible();
      await capture(page, `${device}-settings-refreshed`);
      await open(page, '/profile');
      await expect(page.getByText('Your Profile', { exact: true })).toBeVisible();
      await page.reload(); await semantics(page);
      await expect(page.getByText('Your Profile', { exact: true })).toBeVisible();
      await open(page, '/difficulty?category=capital');
      await expect(page.getByRole('button', { name: 'Easy (15 questions)', exact: true })).toBeVisible();
      await page.reload(); await semantics(page);
      await expect(page.getByRole('button', { name: 'Easy (15 questions)', exact: true })).toBeVisible();
    });
    test('public legal document survives refresh and history', async ({ page }) => {
      await open(page, '/entry');
      await page.getByRole('button', { name: 'Privacy Policy', exact: true }).click();
      await expect(page).toHaveURL(/document=privacy/);
      await page.reload(); await semantics(page);
      await expect(page.getByRole('heading', { name: 'Privacy Policy', exact: true })).toBeVisible();
      await capture(page, `${device}-privacy-refreshed`);
      await page.goBack();
      await expect(page.getByRole('button', { name: 'Continue as Guest', exact: true })).toBeVisible();
      await page.goForward();
      await expect(page.getByRole('heading', { name: 'Privacy Policy', exact: true })).toBeVisible();
    });
    test('login refresh keeps the requested destination', async ({ page }) => {
      await open(page, '/leaderboard?category=capital&difficulty=expert');
      await page.getByRole('button', { name: 'Sign In / Create Account', exact: true }).click();
      await expect(page).toHaveURL(/#\/login\?next=/);
      await page.reload(); await semantics(page);
      await expect(page).toHaveURL(/next=.*leaderboard/);
      await page.goBack();
      await page.getByRole('button', { name: 'Continue as Guest', exact: true }).click();
      await expect(page.getByRole('button', { name: 'Expert', exact: true })).toBeVisible();
    });
    test('completed quiz is saved once and refreshing results cannot resubmit it', async ({ page, request }) => {
      const attempts = async () => {
        const response = await request.post('http://127.0.0.1:8080/v1/projects/demo-quiznetic/databases/(default)/documents:runQuery', {
          headers: { Authorization: 'Bearer owner' },
          data: { structuredQuery: { from: [{ collectionId: 'attempts', allDescendants: true }] } },
        });
        expect(response.ok()).toBeTruthy();
        return (await response.json()).filter((row: {document?: unknown}) => row.document).length;
      };
      const before = await attempts();
      await guest(page);
      await page.getByRole('button', { name: 'Flag Quiz', exact: true }).click();
      await page.getByRole('button', { name: 'Easy (15 flags)', exact: true }).click();
      for (let question = 0; question < 15; question++) {
        const answers = page.getByRole('button').filter({ hasNotText: /^(Back|Leaderboard)$/ });
        await answers.first().click();
        await page.getByRole('button', { name: question === 14 ? 'See Results' : 'Next', exact: true }).click();
      }
      await expect(page.getByRole('button', { name: 'Play Again', exact: true })).toBeVisible();
      await expect.poll(attempts).toBe(before + 1);
      await capture(page, `${device}-quiz-results`);
      await page.reload(); await semantics(page);
      await expect(page.getByText('This session is no longer available', { exact: true })).toBeVisible();
      expect(await attempts()).toBe(before + 1);
      await page.getByRole('button', { name: 'Choose a Quiz', exact: true }).click();
      await expect(page.getByText('Choose Your Quiz', { exact: true })).toBeVisible();
    });
    test('session and malformed links offer a safe recovery', async ({ page }) => {
      for (const location of ['/quiz', '/result?score=15&total=15', '/difficulty', '/unknown']) {
        await open(page, location);
        await expect(page.getByRole('button', { name: 'Choose a Quiz', exact: true })).toBeVisible();
        if (location.startsWith('/result')) await capture(page, `${device}-session-recovery`);
      }
      await page.getByRole('button', { name: 'Choose a Quiz', exact: true }).click();
      await expect(page.getByRole('button', { name: 'Continue as Guest', exact: true })).toBeVisible();
    });
  });
}

test.describe('tablet', () => {
  test.use({ viewport: { width: 768, height: 1024 } });
  test('direct leaderboard and session recovery render at tablet size', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', error => errors.push(error.message));
    await guest(page, '/leaderboard?category=capital&difficulty=expert');
    await expect(page.getByText(/Showing top 3/)).toBeVisible();
    await capture(page, 'tablet-leaderboard');
    await open(page, '/quiz');
    await expect(page.getByRole('button', { name: 'Choose a Quiz', exact: true })).toBeVisible();
    await capture(page, 'tablet-session-recovery');
    expect(errors).toEqual([]);
  });
});
