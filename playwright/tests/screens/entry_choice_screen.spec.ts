import { test, expect } from '@playwright/test';

test('routes to provider sign-in only after explicit sign-in choice', async ({
  page,
}) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  const signInChoice = page.getByRole('button', {
    name: 'Sign In / Create Account',
  });
  // Wait through splash to entry-choice screen.
  await expect(signInChoice).toBeVisible({ timeout: 15_000 });

  await signInChoice.click();
  await expect(page.getByText('Test your knowledge of world flags!')).toBeVisible(
    { timeout: 15_000 },
  );
});
