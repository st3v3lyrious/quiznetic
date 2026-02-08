import { test, expect } from '@playwright/test';

test('loads either entry choice or home screen', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // Flutter web may require explicitly enabling semantics before text/role
  // selectors become visible to Playwright.
  const semanticsToggleExists =
    (await page.locator('flt-semantics-placeholder').count()) > 0;
  if (semanticsToggleExists) {
    await page.evaluate(() => {
      const toggle = document.querySelector(
        'flt-semantics-placeholder',
      ) as HTMLElement | null;
      toggle?.click();
    });
    await page.waitForTimeout(300);
  }

  const guestButton = page.getByRole('button', { name: 'Continue as Guest' });
  const homePrompt = page.getByText('Choose Your Quiz');

  // Splash shows first; wait until post-splash state is visible.
  await expect
    .poll(
      async () => {
        const guestVisible = await guestButton.isVisible().catch(() => false);
        if (guestVisible) return 'entry';

        const homeVisible = await homePrompt.isVisible().catch(() => false);
        if (homeVisible) return 'home';

        return 'pending';
      },
      { timeout: 60_000 },
    )
    .not.toBe('pending');
});
