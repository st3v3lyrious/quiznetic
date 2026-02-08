import { test, expect } from '@playwright/test';

test('routes to provider sign-in only after explicit sign-in choice', async ({
  page,
}) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');

  // Flutter web may render into canvas until semantics are enabled.
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

  const signInChoice = page.getByRole('button', {
    name: 'Sign In / Create Account',
  });
  // Wait through splash to entry-choice screen.
  await expect(signInChoice).toBeVisible({ timeout: 60_000 });

  await signInChoice.click();
  await expect(
    page.getByText('Test your knowledge of world flags!'),
  ).toBeVisible({
    timeout: 30_000,
  });
});
