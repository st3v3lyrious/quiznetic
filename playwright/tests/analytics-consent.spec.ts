import {test, expect} from '@playwright/test';
import {readFile} from 'node:fs/promises';
import path from 'node:path';

test.describe('all-ages Web measurement pause', () => {
  test.skip(process.env.CONSENT_EMULATORS !== 'true', 'Requires the emulator release build');
  for (const [device, viewport] of Object.entries({
    desktop: {width: 1280, height: 900},
    mobile: {width: 390, height: 844},
    tablet: {width: 768, height: 1024},
  })) {
    test(device + ': earlier acceptance cannot restore measurement', async ({page}) => {
      await page.setViewportSize(viewport);
      await page.addInitScript(() => {
        localStorage.setItem('flutter.analytics_consent_v1', 'true');
        localStorage.setItem('flutter.analytics_consent_v1_at', String(Date.now()));
      });
      const requests: string[] = [];
      page.on('request', request => {
        if (/firebase-analytics|googletagmanager|google-analytics\.com/.test(request.url())) requests.push(request.url());
      });
      if (process.env.FIREBASE_SDK_CACHE) {
        await page.route('https://www.gstatic.com/firebasejs/*/*.js', async route => {
          const file = new URL(route.request().url()).pathname.split('/').pop()!;
          await route.fulfill({
            body: await readFile(path.join(process.env.FIREBASE_SDK_CACHE!, file)),
            contentType: 'application/javascript',
            headers: {'access-control-allow-origin': '*'},
          });
        });
      }
      const semantics = async () => {
        await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder, flt-semantics-host'));
        await page.locator('flt-semantics-placeholder').evaluateAll(nodes => nodes.forEach(node => (node as HTMLElement).click()));
      };
      await page.goto('/#/entry');
      await semantics();
      await expect(page.getByRole('button', {name: 'Analytics off · Privacy Policy', exact: true})).toBeVisible();
      await expect(page.getByRole('button', {name: 'Accept analytics', exact: true})).toHaveCount(0);
      await page.reload();
      await semantics();
      await expect(page.getByRole('button', {name: 'Analytics off · Privacy Policy', exact: true})).toBeVisible();
      await page.getByRole('button', {name: 'Analytics off · Privacy Policy', exact: true}).click();
      await expect(page).toHaveURL(/document=privacy/);
      await expect(page.getByRole('heading', {name: 'Privacy Policy', exact: true})).toBeVisible();
      expect(requests).toEqual([]);
      expect((await page.context().cookies()).filter(cookie => /^_ga|^_gid|^_gat/.test(cookie.name))).toEqual([]);
    });
  }
});

test('paused bridge refuses direct SDK loading and clears only GA cookies', async ({page}) => {
  const script = await readFile(new URL('../../web/analytics_consent.js', import.meta.url), 'utf8');
  const requests: string[] = [];
  page.on('request', request => {
    if (/firebase-analytics|googletagmanager|google-analytics\.com/.test(request.url())) requests.push(request.url());
  });
  await page.route('http://consent.test/', route => route.fulfill({
    contentType: 'text/html', body: '<!doctype html><html><body>Privacy fixture</body></html>',
  }));
  await page.goto('http://consent.test/');
  await page.evaluate(() => {
    (window as any).firebase_core = {getApp: () => ({options: {measurementId: 'G-CONSENTTEST'}})};
  });
  await page.addScriptTag({content: script});
  await page.context().addCookies([
    {name: '_ga', value: 'old', url: 'http://consent.test/'},
    {name: '_ga_SCOPE', value: 'old', url: 'http://consent.test/'},
    {name: 'essential', value: 'keep', url: 'http://consent.test/'},
  ]);
  const rejected = await page.evaluate(async () => {
    try { await (window as any).quizneticAnalytics.load(); return false; }
    catch { return true; }
  });
  expect(rejected).toBe(true);
  await page.evaluate(() => (window as any).quizneticAnalytics.disable());
  expect((await page.context().cookies()).map(cookie => cookie.name)).toEqual(['essential']);
  expect(await page.evaluate(() => (window as any)['ga-disable-G-CONSENTTEST'])).toBe(true);
  const commands = await page.evaluate(() => (window as any).dataLayer.map((entry: any) => Array.from(entry)));
  expect(commands.some((entry: any[]) => entry[0] === 'consent' && entry[2]?.analytics_storage === 'granted')).toBe(false);
  expect(requests).toEqual([]);
});
