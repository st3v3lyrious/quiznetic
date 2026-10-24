import {test, expect} from '@playwright/test';
import {readFile} from 'node:fs/promises';
import path from 'node:path';

// Real Flutter emulator build; no production credentials or Firebase writes.
test.describe('browser consent UI', () => {
  test.skip(process.env.CONSENT_EMULATORS !== 'true', 'Requires the emulator release build');
  for (const [device, viewport] of Object.entries({desktop:{width:1280,height:900},mobile:{width:390,height:844},tablet:{width:768,height:1024}})) {
    test(device + ': before choice, refusal, refresh and public preferences', async ({page}) => {
      await page.setViewportSize(viewport);
      const analyticsRequests: string[] = [];
      page.on('request', r => {
        if (/firebase-analytics|googletagmanager|google-analytics\.com/.test(r.url())) analyticsRequests.push(r.url());
      });
      if (process.env.FIREBASE_SDK_CACHE) {
        await page.route('https://www.gstatic.com/firebasejs/*/*.js', async route => {
          const file = new URL(route.request().url()).pathname.split('/').pop()!;
          await route.fulfill({body: await readFile(path.join(process.env.FIREBASE_SDK_CACHE!, file)), contentType:'application/javascript',headers:{'access-control-allow-origin':'*'}});
        });
      }
      const semantics = async () => {
        await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder, flt-semantics-host'));
        await page.locator('flt-semantics-placeholder').evaluateAll(nodes=>nodes.forEach(n=>(n as HTMLElement).click()));
      };
      await page.goto('/#/entry'); await semantics();
      await expect(page.getByRole('button',{name:'Accept analytics',exact:true})).toBeVisible();
      await expect(page.getByRole('button',{name:'Refuse analytics',exact:true})).toBeVisible();
      expect(analyticsRequests).toEqual([]);
      await page.screenshot({path:`test-results/consent/${device}-before-choice.png`});
      await page.getByRole('button',{name:'Refuse analytics',exact:true}).click();
      await expect(page.getByRole('button',{name:'Analytics preferences · Off',exact:true})).toBeVisible();
      await page.reload(); await semantics();
      await expect(page.getByRole('button',{name:'Analytics preferences · Off',exact:true})).toBeVisible();
      await expect(page.getByRole('button',{name:'Accept analytics',exact:true})).toHaveCount(0);
      await page.getByRole('button',{name:'Analytics preferences · Off',exact:true}).click();
      await expect(page.getByRole('button',{name:'Accept analytics',exact:true})).toBeVisible();
      await page.getByRole('button',{name:'Privacy Policy',exact:true}).last().click();
      await expect(page).toHaveURL(/document=privacy/);
      await expect(page.getByRole('heading',{name:'Privacy Policy',exact:true})).toBeVisible();
      await page.screenshot({path:`test-results/consent/${device}-privacy-preferences.png`});
      expect(analyticsRequests).toEqual([]);
      expect(await page.context().cookies()).toEqual([]);
    });
  }
});

// Controlled Analytics module verifies the Flutter → bridge → SDK boundary,
// without sending test traffic to GA4. Auth/Core modules are real.
test('real Flutter UI accepts, restores and withdraws through the SDK bridge', async ({page}) => {
  test.skip(process.env.CONSENT_EMULATORS !== 'true', 'Requires emulator build');
  let imports = 0;
  await page.route('https://www.gstatic.com/firebasejs/*/*.js', async route => {
    const file = new URL(route.request().url()).pathname.split('/').pop()!;
    if (file === 'firebase-analytics.js') {
      imports++;
      await route.fulfill({contentType:'application/javascript',headers:{'access-control-allow-origin':'*'},body:`
        export function initializeAnalytics(app) { return {app}; }
        export function setAnalyticsCollectionEnabled(_, enabled) {
          window.consentSdkEnabled = enabled;
          if (enabled) document.cookie = '_ga=test-fixture; Path=/';
        }
        export function logEvent() {}
      `});
    } else if (process.env.FIREBASE_SDK_CACHE) {
      await route.fulfill({body:await readFile(path.join(process.env.FIREBASE_SDK_CACHE,file)),contentType:'application/javascript',headers:{'access-control-allow-origin':'*'}});
    } else await route.continue();
  });
  const semantics = async () => {
    await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder, flt-semantics-host'));
    await page.locator('flt-semantics-placeholder').evaluateAll(nodes=>nodes.forEach(n=>(n as HTMLElement).click()));
  };
  await page.goto('/#/entry'); await semantics();
  expect(imports).toBe(0);
  await page.getByRole('button',{name:'Accept analytics',exact:true}).click();
  await expect(page.getByRole('button',{name:'Analytics preferences · On',exact:true})).toBeVisible();
  expect(await page.evaluate(()=>(window as any).consentSdkEnabled)).toBe(true);
  await page.reload(); await semantics();
  await expect(page.getByRole('button',{name:'Analytics preferences · On',exact:true})).toBeVisible();
  expect(imports).toBe(2);
  await page.getByRole('button',{name:'Analytics preferences · On',exact:true}).click();
  await expect(page.getByText(/Refusing now reloads the page/)).toBeVisible();
  await Promise.all([page.waitForEvent('load'), page.getByRole('button',{name:'Refuse analytics',exact:true}).click()]);
  await semantics();
  await expect(page.getByRole('button',{name:'Analytics preferences · Off',exact:true})).toBeVisible();
  expect(imports).toBe(2);
  expect((await page.context().cookies()).filter(c=>c.name.startsWith('_ga'))).toEqual([]);
});

test('Web bridge delays SDK, denies ads, clears GA cookies, and cancels pending grant', async ({page}) => {
  let imports = 0;
  const script = await readFile(new URL('../../web/analytics_consent.js',import.meta.url),'utf8');
  await page.route('http://consent.test/', r=>r.fulfill({contentType:'text/html',body:'<!doctype html><html><body>Consent bridge fixture</body></html>'}));
  await page.route('https://www.gstatic.com/firebasejs/*/firebase-analytics.js', async r=>{
    imports++;
    await r.fulfill({contentType:'application/javascript',body:'export const fixture = true;',headers:{'access-control-allow-origin':'*'}});
  });
  await page.goto('http://consent.test/');
  await page.evaluate(() => { (window as any).firebase_core={SDK_VERSION:'12.19.0',getApp:()=>({options:{measurementId:'G-CONSENTTEST'}})}; });
  await page.addScriptTag({content:script});
  expect(imports).toBe(0);
  const initial = await page.evaluate(()=>(window as any).dataLayer.map((v:any)=>Array.from(v)));
  expect(initial[0]).toEqual(['consent','default',{analytics_storage:'denied',ad_storage:'denied',ad_user_data:'denied',ad_personalization:'denied'}]);
  await page.evaluate(()=> (window as any).quizneticAnalytics.load());
  expect(imports).toBe(1);
  expect(await page.evaluate(()=> (window as any)['ga-disable-G-CONSENTTEST'])).toBe(false);
  await page.context().addCookies([{name:'_ga',value:'test',url:'http://consent.test/'},{name:'_ga_SCOPE',value:'test',url:'http://consent.test/'},{name:'essential',value:'keep',url:'http://consent.test/'}]);
  await page.evaluate(()=> (window as any).quizneticAnalytics.disable());
  expect(await page.evaluate(()=> (window as any)['ga-disable-G-CONSENTTEST'])).toBe(true);
  expect((await page.context().cookies()).map(c=>c.name)).toEqual(['essential']);
  const cancelled = await page.evaluate(async ()=>{
    const pending=(window as any).quizneticAnalytics.load();
    (window as any).quizneticAnalytics.disable();
    try {await pending;return false;} catch {return true;}
  });
  expect(cancelled).toBe(true);
  const commands = await page.evaluate(()=>(window as any).dataLayer.map((v:any)=>Array.from(v)));
  expect(commands).toContainEqual(['set','allow_google_signals',false]);
  expect(commands).toContainEqual(['set','allow_ad_personalization_signals',false]);
});
