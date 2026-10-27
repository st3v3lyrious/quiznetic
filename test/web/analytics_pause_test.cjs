// No Firebase credentials, network or player data. Run: node --test test/web/*.cjs
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');

test('paused bridge never imports or grants; removes GA cookies only', async () => {
  const cookies = new Map([
    ['_ga', 'old'], ['_ga_SCOPE', 'old'], ['_gid', 'old'], ['essential', 'keep'],
  ]);
  const document = {};
  Object.defineProperty(document, 'cookie', {
    get: () => [...cookies].map(([key, value]) => key + '=' + value).join('; '),
    set: value => {
      if (value.includes('Max-Age=0')) cookies.delete(value.split('=')[0]);
    },
  });
  const window = {
    firebase_core: {getApp: () => ({options: {measurementId: 'G-TEST'}})},
  };
  const context = vm.createContext({
    window, document, location: {hostname: 'quiznetic.example.test'},
  });
  let imports = 0;
  const source = readFileSync('web/analytics_consent.js', 'utf8');
  new vm.Script(source, {
    importModuleDynamically: () => { imports++; throw new Error('Unexpected import'); },
  }).runInContext(context);
  await assert.rejects(window.quizneticAnalytics.load(), /paused/);
  window.quizneticAnalytics.disable();
  assert.equal(imports, 0);
  assert.equal(window['ga-disable-G-TEST'], true);
  assert.deepEqual([...cookies], [['essential', 'keep']]);
  const commands = window.dataLayer.map(entry => Array.from(entry));
  assert.ok(commands.length >= 2);
  for (const command of commands) {
    if (command[0] === 'consent') {
      assert.equal(command[2].analytics_storage, 'denied');
      assert.equal(command[2].ad_storage, 'denied');
    }
  }
});

test('pause initializes safely before Firebase is available', async () => {
  const window = {};
  const context = vm.createContext({
    window, document: {cookie: ''}, location: {hostname: 'localhost'},
  });
  new vm.Script(readFileSync('web/analytics_consent.js', 'utf8')).runInContext(context);
  window.quizneticAnalytics.disable();
  await assert.rejects(window.quizneticAnalytics.load(), /paused/);
});
