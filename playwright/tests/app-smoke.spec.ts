import { test, expect } from '@playwright/test';

test('loads either entry choice or home screen', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

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
      { timeout: 15_000 },
    )
    .not.toBe('pending');
});
