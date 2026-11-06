const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');
const clientRequire = require('node:module').createRequire(path.resolve(__dirname, '../../firestore_tests/package.json'));
const {initializeTestEnvironment, assertFails} = clientRequire('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, deleteDoc, runTransaction} = clientRequire('firebase/firestore');
const {createPlan, executePlan, digest, monthsBefore, parseMode, privateManifestPath, RECEIPT} = require('../scripts/prune-attempt-history.cjs');
const project = 'demo-quiznetic-retention', uid = 'retention-fixture-user';
const now = new Date('2026-11-06T12:00:00Z');
let env, app, db, services;
const attempt = id => db.doc('users/' + uid + '/attempts/' + id);
const payload = (id, createdAt = '2024-01-01T00:00:00Z') => ({
  attemptId: id, categoryKey: 'flag', difficulty: 'easy', correctCount: 14, totalQuestions: 15,
  source: 'account', status: 'accepted', createdAt: admin.firestore.Timestamp.fromDate(new Date(createdAt)),
});
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Firestore emulator required; no production tests');
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  env = await initializeTestEnvironment({projectId: project, firestore: {host, port: Number(port),
    rules: readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8')}});
  app = admin.initializeApp({projectId: project}, 'retention-emulator');
  db = admin.firestore(app);
  // Auth lookup is stubbed; all document operations use the real Firestore emulator.
  services = {project, db, auth: {getUser: async id => {
    assert.equal(id, uid); return {disabled: false};
  }}, verifyRules: async () => {}};
});
beforeEach(async () => {
  await env.clearFirestore();
  await db.doc('users/' + uid).set({displayName: 'Fixture', lastSeen: admin.firestore.Timestamp.fromDate(now)});
  await db.doc('users/' + uid + '/scores/flag_easy').set({bestScore: 14, source: 'account'});
  await db.doc('leaderboard/flag_easy/entries/' + uid).set({score: 14, displayName: 'Fixture'});
  await attempt('old').set(payload('old'));
  await attempt('recent').set(payload('recent', '2026-11-05T00:00:00Z'));
});
after(async () => { await app?.delete(); await env?.cleanup(); });
test('calendar retention and CLI require explicit reviewed digest', () => {
  assert.equal(monthsBefore(new Date('2024-02-29T12:00:00Z'), 12).toISOString(), '2023-02-28T12:00:00.000Z');
  assert.deepEqual(parseMode(['--plan']), {mode: 'plan'});
  for (const args of [[], ['--execute'], ['--plan', '--execute'], ['--execute', '--confirm', 'bad']]) {
    assert.throws(() => parseMode(args));
  }
});
test('compaction removes all details and leaves projections/profile/leaderboard unchanged', async () => {
  const paths = ['users/' + uid, 'users/' + uid + '/scores/flag_easy', 'leaderboard/flag_easy/entries/' + uid];
  const before = await Promise.all(paths.map(async p => (await db.doc(p).get()).data()));
  const plan = await createPlan(services, uid, now);
  assert.equal(plan.attempts.length, 1);
  assert.equal(JSON.stringify(plan).includes('correctCount'), false);
  assert.deepEqual(await executePlan(services, uid, plan, digest(plan), now),
    {selected: 1, compacted: 1, alreadyCompacted: 0});
  assert.deepEqual((await attempt('old').get()).data(), RECEIPT);
  assert.deepEqual(await Promise.all(paths.map(async p => (await db.doc(p).get()).data())), before);
  assert.equal((await attempt('recent').get()).data().correctCount, 14);
});
test('old client offline replay resolves as duplicate; receipt cannot be overwritten or deleted', async () => {
  const plan = await createPlan(services, uid, now);
  await executePlan(services, uid, plan, digest(plan), now);
  const client = env.authenticatedContext(uid, {firebase: {sign_in_provider: 'password'}}).firestore();
  const pending = ['old'];
  const replay = () => runTransaction(client, async tx => {
    const [old, score, leader] = await Promise.all([
      tx.get(doc(client, 'users/' + uid + '/attempts/old')),
      tx.get(doc(client, 'users/' + uid + '/scores/flag_easy')),
      tx.get(doc(client, 'leaderboard/flag_easy/entries/' + uid)),
    ]);
    if (old.exists()) return 'duplicate'; // Existing Dart ScoreService contract.
    throw new Error('Receipt disappeared; old submission could be replayed');
  });
  assert.equal(await replay(), 'duplicate'); pending.shift();
  assert.equal(pending.length, 0);
  await assertFails(setDoc(doc(client, 'users/' + uid + '/attempts/old'), {...payload('old'), createdAt: new Date('2024-01-01T00:00:00Z')}));
  await assertFails(deleteDoc(doc(client, 'users/' + uid + '/attempts/old')));
  await assertFails(setDoc(doc(client, 'users/' + uid + '/attempts/fake-receipt'), RECEIPT));
  assert.equal((await db.doc('users/' + uid + '/scores/flag_easy').get()).data().bestScore, 14);
});
test('repeat execution is idempotent and does not recreate details', async () => {
  const plan = await createPlan(services, uid, now);
  await executePlan(services, uid, plan, digest(plan), now);
  assert.deepEqual(await executePlan(services, uid, plan, digest(plan), now),
    {selected: 1, compacted: 0, alreadyCompacted: 1});
});
test('missing dates, exact boundary and recent records are never selected', async () => {
  await attempt('old').delete();
  await attempt('missing-date').set({attemptId: 'missing-date'});
  await attempt('boundary').set(payload('boundary', monthsBefore(now, 12).toISOString()));
  const plan = await createPlan(services, uid, now);
  assert.equal(plan.attempts.length, 0);
  assert.deepEqual(await executePlan(services, uid, plan, digest(plan), now),
    {selected: 0, compacted: 0, alreadyCompacted: 0});
  assert.ok((await attempt('missing-date').get()).exists);
});
test('stale plan fails atomically when selected data changed', async () => {
  await attempt('second-old').set(payload('second-old'));
  const plan = await createPlan(services, uid, now);
  await attempt('second-old').update({correctCount: 13});
  await assert.rejects(executePlan(services, uid, plan, digest(plan), now), /Selection changed/);
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});
test('deleted selection is not recreated', async () => {
  const plan = await createPlan(services, uid, now);
  await attempt('old').delete();
  await assert.rejects(executePlan(services, uid, plan, digest(plan), now), /Selection changed/);
  assert.equal((await attempt('old').get()).exists, false);
});
test('tampering, traversal, wrong project/UID and expired manifest fail before changes', async () => {
  const plan = await createPlan(services, uid, now);
  const changed = {...plan, uid: 'another-user'};
  await assert.rejects(executePlan(services, uid, changed, digest(changed), now));
  const escaped = {...plan, attempts: [{id: '../scores/flag_easy', version: '1:0'}]};
  await assert.rejects(executePlan(services, uid, escaped, digest(escaped), now));
  await assert.rejects(executePlan(services, uid, plan, '0'.repeat(64), now));
  await assert.rejects(executePlan(services, uid, plan, digest(plan), new Date(now.getTime() + 24 * 3600000)));
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});
test('account deletion lock and absent rules verification stop execution', async () => {
  const plan = await createPlan(services, uid, now);
  await assert.rejects(executePlan({...services, verifyRules: undefined}, uid, plan, digest(plan), now));
  await db.doc('accountDeletions/' + uid).set({status: 'pending'});
  await assert.rejects(createPlan(services, uid, now));
  await assert.rejects(executePlan(services, uid, plan, digest(plan), now));
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});
test('unknown legacy fields or nested data require a separate manual review', async () => {
  await attempt('old').update({unexpectedLegacyField: 'do not silently discard'});
  await assert.rejects(createPlan(services, uid, now), /Unknown legacy payload/);
  await attempt('old').set(payload('old'));
  await attempt('old').collection('answers').doc('one').set({content: 'fixture'});
  await assert.rejects(createPlan(services, uid, now), /Nested attempt data/);
});
test('oversized batches are refused rather than silently partially selected', async () => {
  const batch = db.batch();
  for (let i = 0; i < 100; i++) batch.set(attempt('extra-' + i), payload('extra-' + i));
  await batch.commit();
  await assert.rejects(createPlan(services, uid, now), /Batch exceeds limit/);
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});

test('private manifest refuses checkout paths, public directories and symlinked checkout ancestors', () => {
  const fs = require('node:fs'), os = require('node:os');
  const outside = fs.mkdtempSync(path.join(os.tmpdir(), 'retention-private-'));
  const inside = fs.mkdtempSync(path.resolve(__dirname, '../retention-private-'));
  fs.chmodSync(inside, 0o700);
  try {
    assert.equal(privateManifestPath(path.join(outside, 'plan.json')), path.join(outside, 'plan.json'));
    assert.throws(() => privateManifestPath(path.join(inside, 'plan.json')));
    fs.chmodSync(outside, 0o755);
    assert.throws(() => privateManifestPath(path.join(outside, 'plan.json')));
    fs.chmodSync(outside, 0o700);
    fs.symlinkSync(path.resolve(__dirname, '../..'), path.join(outside, 'checkout'));
    assert.throws(() => privateManifestPath(path.join(outside, 'checkout', 'functions', path.basename(inside), 'plan.json')));
  } finally {
    fs.rmSync(outside, {recursive: true, force: true});
    fs.rmSync(inside, {recursive: true, force: true});
  }
});

test('a missing score summary cannot discard the only stored progress', async () => {
  await db.doc('users/' + uid + '/scores/flag_easy').delete();
  await assert.rejects(createPlan(services, uid, now), /Missing or inconsistent summary/);
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});
test('summary reduction after approval stops the entire compaction', async () => {
  const plan = await createPlan(services, uid, now);
  await db.doc('users/' + uid + '/scores/flag_easy').update({bestScore: 0});
  await assert.rejects(executePlan(services, uid, plan, digest(plan), now), /Missing or inconsistent summary/);
  assert.equal((await attempt('old').get()).data().correctCount, 14);
});
