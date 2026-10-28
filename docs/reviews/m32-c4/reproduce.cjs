const {chromium}=require(process.env.QA_PLAYWRIGHT_MODULE || '../../../playwright/node_modules/playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const base=process.env.WEB_QA_URL || 'http://127.0.0.1:7362';
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.QA_BROWSER_EXECUTABLE,proxy:process.env.HTTPS_PROXY?{server:process.env.HTTPS_PROXY,bypass:'127.0.0.1,localhost'}:undefined});
 const report=[];
 try {
  for(const [device,viewport] of Object.entries({desktop:{width:1280,height:900},mobile:{width:390,height:844},tablet:{width:768,height:1024}})){
   const context=await browser.newContext({viewport,locale:'en-US'});
   const page=await context.newPage();
   const errors=[],analytics=[],writes=[];
   const checks=[];
   page.setDefaultTimeout(30000);
   page.on('pageerror',e=>errors.push(e.message));
   page.on('request',r=>{
    if(/firebase-analytics|googletagmanager|google-analytics\.com/.test(r.url()))analytics.push(new URL(r.url()).host);
    if(/firestore.googleapis.com/.test(r.url())&&/Write|commit/.test(r.url()))writes.push('firestore-write');
   });
   await page.route('https://**/*',async route=>{
    const response=await route.fetch({timeout:90000});await route.fulfill({response});
   });
   await context.addCookies([{name:'_ga',value:'old-fixture',url:base+'/'},{name:'essential_fixture',value:'keep',url:base+'/'}]);
   await page.addInitScript(()=>{
    if(!sessionStorage.getItem('pause-fixture-seeded')){
     localStorage.setItem('flutter.analytics_consent_v1','true');
     localStorage.setItem('flutter.analytics_consent_v1_at',String(Date.now()));
     sessionStorage.setItem('pause-fixture-seeded','true');
    }
   });
   const semantics=async()=>{
    await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder,flt-semantics-host'));
    await page.locator('flt-semantics-placeholder').evaluateAll(nodes=>nodes.forEach(n=>n.click()));
   };
   await page.goto(base+'/#/entry');await semantics();
   await page.getByRole('button',{name:'Analytics off · Privacy Policy',exact:true}).waitFor();
   assert.equal(await page.getByRole('button',{name:'Accept analytics',exact:true}).count(),0);
   await page.getByText(/Keep your real name out of your nickname/).waitFor();checks.push('child_notice_and_no_opt_in');
   await page.waitForFunction(()=>localStorage.getItem('flutter.analytics_consent_v1')===null);
   checks.push('previous_choice_invalidated');
   const cookies=await context.cookies();
   assert.equal(cookies.some(c=>c.name==='_ga'),false);assert.equal(cookies.some(c=>c.name==='essential_fixture'),true);checks.push('ga_cookie_removed_essential_kept');
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);checks.push('entry_no_document_horizontal_overflow');
   await page.screenshot({path:path.join(__dirname,device+'-entry.png'),fullPage:true});
   await page.reload();await semantics();await page.getByRole('button',{name:'Analytics off · Privacy Policy',exact:true}).waitFor();checks.push('reload_stays_off');
   await page.getByRole('button',{name:'Analytics off · Privacy Policy',exact:true}).click();
   await page.getByRole('heading',{name:'Privacy Policy',exact:true}).waitFor();
   assert.ok(page.url().includes('document=privacy'));checks.push('public_privacy_route');
   assert.equal(await page.evaluate(()=>!!window.firebase_analytics),false);
   const rejected=await page.evaluate(async()=>{try{await window.quizneticAnalytics.load();return false;}catch{return true;}});
   assert.equal(rejected,true);checks.push('direct_bridge_load_rejected');
   assert.equal(analytics.length,0);assert.equal(writes.length,0);assert.equal(errors.length,0);checks.push('no_sdk_events_writes_or_page_errors');
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);checks.push('no_document_horizontal_overflow');
   report.push({engine:'chromium',version:browser.version(),device,checks,analyticsRequests:analytics.length,observedFirestoreWrites:writes.length,pageErrors:errors});
   await context.close();
  }
  fs.writeFileSync(path.join(__dirname,'browser-report.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
