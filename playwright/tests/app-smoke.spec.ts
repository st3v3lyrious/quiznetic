import { test, expect } from '@playwright/test';

test('loads either entry choice or home screen', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  const guestButton = page.getByRole('button', { name: 'Continue as Guest' });
  const homePrompt = page.getByText('Choose Your Quiz');

  const guestVisible = await guestButton.isVisible().catch(() => false);
  const homeVisible = await homePrompt.isVisible().catch(() => false);

  expect(guestVisible || homeVisible).toBeTruthy();
});
