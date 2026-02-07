import { test, expect } from '@playwright/test';

test('routes to provider sign-in only after explicit sign-in choice', async ({
  page,
}) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  const signInChoice = page.getByRole('button', {
    name: 'Sign In / Create Account',
  });
  await expect(signInChoice).toBeVisible();

  await signInChoice.click();
  await expect(
    page.getByText('Welcome back! Please sign in to continue.'),
  ).toBeVisible();
});
