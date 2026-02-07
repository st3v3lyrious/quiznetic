import { test, expect } from '@playwright/test';

test.skip('Splash Screen critical flow', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // TODO: Navigate to Splash Screen and assert user-visible behavior.
  await expect(page).toHaveTitle(/.+/);
});
