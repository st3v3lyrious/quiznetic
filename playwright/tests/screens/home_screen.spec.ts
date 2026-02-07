import { test, expect } from '@playwright/test';

test.skip('Home Screen critical flow', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // TODO: Navigate to Home Screen and assert user-visible behavior.
  await expect(page).toHaveTitle(/.+/);
});
