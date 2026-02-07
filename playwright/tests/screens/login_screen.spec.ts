import { test, expect } from '@playwright/test';

test.skip('Login Screen critical flow', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // TODO: Navigate to Login Screen and assert user-visible behavior.
  await expect(page).toHaveTitle(/.+/);
});
