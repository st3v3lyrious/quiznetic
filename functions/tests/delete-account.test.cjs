const {test, before, after} = require('node:test');
const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const admin = require('firebase-admin');
const {inspect, removeAccount, cleanupMarker, parseArgs, verifyRules, RETENTION_MS} = require('../scripts/delete-account.cjs');
const projectId = 'demo-quiznetic-deletion';
let app, db, auth;
before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Both local emulators required');
  for (const url of [
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`
  ]) {
    const response = await fetch(url, {method: 'DELETE'});
    assert.ok(response.ok, 'Could not reset isolated demo test project');
  }
  app = admin.initializeApp({projectId}); db = admin.firestore(app); auth = admin.auth(app);
});
after(async () => { if (app) await app.delete(); });
const services = () => ({db, auth, verify: async () => {}});
async function seed(uid, count = 3) {
  await auth.createUser({uid, email: `${uid}@example.test`, password: 'Test-only-1234'});
  const writer = db.bulkWriter();
  writer.set(db.doc(`users/${uid}`), {test: true});
  writer.set(db.doc('users/unrelated/scores/flag_easy'), {keep: true});
  for (let i = 0; i < count; i++) writer.set(db.doc(`users/${uid}/attempts/a${i}`), {test: true});
  writer.set(db.doc(`users/${uid}/scores/flag_easy`), {test: true});
  // Missing root/scope parents must not hide nested records from deletion.
  writer.set(db.doc(`users/${uid}/legacy/item/nested/data`), {test: true});
  for (const scope of ['flag_easy', 'capital_expert', 'legacy_scope']) {
    writer.set(db.doc(`leaderboard/${scope}/entries/${uid}`), {test: true});
    writer.set(db.doc(`leaderboard/${scope}/entries/unrelated`), {keep: true});
  }
  await writer.close();
}
test('CLI defaults to read-only and requires exact project:uid confirmation', () => {
  assert.equal(parseArgs(['--project', projectId, '--uid', 'A']).execute, undefined);
  assert.throws(() => parseArgs(['--project', projectId, '--uid', 'A', '--execute']));
  assert.throws(() => parseArgs(['--project', projectId, '--uid', 'A/B']));
  assert.throws(() => parseArgs(['--project', projectId, '--uid', 'A', '--cleanup-marker']));
});
test('dry-run CLI reports data and leaves Auth/Firestore unchanged', async () => {
  const uid = 'dry-run'; await seed(uid);
  const before = await inspect({db, auth}, uid);
  const output = execFileSync(process.execPath, ['scripts/delete-account.cjs', '--project', projectId, '--uid', uid], {cwd: __dirname + '/..', env: process.env, encoding: 'utf8'});
  assert.equal(JSON.parse(output).mode, 'dry-run');
  assert.deepEqual(await inspect({db, auth}, uid), before);
});
test('recursive deletion covers >500 attempts, missing parents, all scopes and Auth; retries are safe', async () => {
  const uid = 'large-delete'; await seed(uid, 605);
  const result = await removeAccount(services(), uid);
  assert.equal(result.authExists, false); assert.equal(result.profileExists, false);
  assert.deepEqual(result.privateCollections, []); assert.equal(result.leaderboardEntries, 0);
  assert.equal((await db.doc(`users/${uid}/legacy/item/nested/data`).get()).exists, false);
  assert.equal((await db.doc('leaderboard/legacy_scope/entries/unrelated').get()).exists, true);
  assert.equal((await db.doc('users/unrelated/scores/flag_easy').get()).get('keep'), true);
  await removeAccount(services(), uid);
  assert.equal((await db.doc(`accountDeletions/${uid}`).get()).get('status'), 'complete');
});
test('orphaned Firestore data is removable even when Auth record is absent', async () => {
  const uid = 'orphan';
  await db.doc(`users/${uid}/attempts/leftover`).set({test: true});
  await db.doc(`leaderboard/legacy_only/entries/${uid}`).set({test: true});
  await removeAccount(services(), uid);
  assert.equal((await db.doc(`users/${uid}/attempts/leftover`).get()).exists, false);
  assert.equal((await db.doc(`leaderboard/legacy_only/entries/${uid}`).get()).exists, false);
});
test('failed rules verification performs no writes or Auth changes', async () => {
  const uid = 'bad-rules'; await seed(uid);
  await assert.rejects(removeAccount({...services(), verify: async () => {throw Error('rules mismatch');}}, uid));
  assert.equal((await auth.getUser(uid)).disabled, false);
  assert.equal((await db.doc(`accountDeletions/${uid}`).get()).exists, false);
});
test('mid-operation failure keeps account disabled/marker pending and can be retried', async () => {
  const uid = 'retry'; await seed(uid);
  const broken = {...services(), auth: {
    getUser: u => auth.getUser(u), updateUser: (...a) => auth.updateUser(...a),
    revokeRefreshTokens: u => auth.revokeRefreshTokens(u), deleteUser: async () => {throw Error('network');}
  }};
  await assert.rejects(removeAccount(broken, uid));
  assert.equal((await auth.getUser(uid)).disabled, true);
  assert.equal((await db.doc(`accountDeletions/${uid}`).get()).get('status'), 'pending');
  await removeAccount(services(), uid);
  assert.equal(await auth.getUser(uid).catch(e => e.code), 'auth/user-not-found');
});
test('marker cannot be removed early; expiry cleanup rechecks Auth and data', async () => {
  const uid = 'marker'; await seed(uid); let time = Date.now();
  await removeAccount({...services(), now: () => time}, uid);
  await assert.rejects(cleanupMarker({...services(), now: () => time}, uid));
  time += RETENTION_MS + 1;
  await db.doc(`users/${uid}`).set({unexpected: true});
  await assert.rejects(cleanupMarker({...services(), now: () => time}, uid));
  await db.doc(`users/${uid}`).delete();
  await cleanupMarker({...services(), now: () => time}, uid);
  assert.equal((await db.doc(`accountDeletions/${uid}`).get()).exists, false);
});

test('production gate compares full deployed rules source and fails closed', async () => {
  const rules = require('node:fs').readFileSync(__dirname + '/../../firestore.rules', 'utf8');
  const hash = await verifyRules(null, async () => ({source: [{content: rules}]}));
  assert.match(hash, /^[a-f0-9]{64}$/);
  await assert.rejects(verifyRules(null, async () => ({source: [{content: 'old rules'}]})));
  await assert.rejects(verifyRules(null, async () => {throw Error('permission denied');}));
});

test('CLI rejects mixed emulator and production targets before initialization', () => {
  for (const [project, authHost] of [[projectId, ''], ['real-project', '127.0.0.1:9099']]) {
    assert.throws(() => execFileSync(process.execPath, ['scripts/delete-account.cjs', '--project', project, '--uid', 'A'], {
      cwd: __dirname + '/..', env: {...process.env, FIREBASE_AUTH_EMULATOR_HOST: authHost}, stdio: 'pipe'
    }));
  }
});

test('confirmed CLI execution deletes only the selected demo account', async () => {
  const uid = 'cli-execute'; await seed(uid);
  const output = execFileSync(process.execPath, ['scripts/delete-account.cjs', '--project', projectId, '--uid', uid,
    '--execute', '--confirm', `${projectId}:${uid}`], {cwd: __dirname + '/..', env: process.env, encoding: 'utf8'});
  const result = JSON.parse(output);
  assert.equal(result.mode, 'completed'); assert.equal(result.authExists, false);
  assert.equal(result.leaderboardEntries, 0); assert.deepEqual(result.privateCollections, []);
  assert.equal((await db.doc('users/unrelated/scores/flag_easy').get()).get('keep'), true);
});
