import { test, expect } from '@playwright/test';

test.skip('Leaderboard Screen critical flow', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // TODO: Navigate to leaderboard screen and assert ranking/filter behavior.
  await expect(page).toHaveTitle(/.+/);
});
