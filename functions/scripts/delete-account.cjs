#!/usr/bin/env node
// Operator-only Spark procedure. No Cloud Functions deployment is required.
const {readFileSync} = require('node:fs');
const {resolve} = require('node:path');
const {createHash} = require('node:crypto');
const admin = require('firebase-admin');
const RETENTION_MS = 65 * 60 * 1000;
const missingUser = error => error.code === 'auth/user-not-found';

async function findUser(auth, uid) {
  try { return await auth.getUser(uid); } catch (e) { if (missingUser(e)) return null; throw e; }
}

// listDocuments includes missing parent documents with existing subcollections.
async function leaderboardRefs(db, uid) {
  const scopes = await db.collection('leaderboard').listDocuments();
  return scopes.map(scope => scope.collection('entries').doc(uid));
}

async function inspect({db, auth}, uid) {
  const user = await findUser(auth, uid);
  const root = db.collection('users').doc(uid);
  const refs = await leaderboardRefs(db, uid);
  let leaderboardEntries = 0;
  for (const ref of refs) if ((await ref.get()).exists) leaderboardEntries++;
  return {authExists: !!user, authDisabled: user?.disabled ?? null,
    profileExists: (await root.get()).exists,
    privateCollections: (await root.listCollections()).map(c => c.id),
    leaderboardEntries, deletionMarker: (await db.doc(`accountDeletions/${uid}`).get()).exists};
}

async function verifyRules(app, fetchRules = () => admin.securityRules(app).getFirestoreRuleset()) {
  // Fail before any write if stale production rules would let old tokens rewrite data.
  const ruleset = await fetchRules();
  const expected = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8').replace(/\r\n/g, '\n').trim();
  const sources = ruleset.source;
  if (!sources.some(file => file.content.replace(/\r\n/g, '\n').trim() === expected)) {
    throw new Error('Deployed Firestore rules differ from this checkout. Deploy and verify the reviewed rules first.');
  }
  return createHash('sha256').update(expected).digest('hex');
}

async function removeAccount({db, auth, verify = async () => { throw new Error('Rules verification required'); }, now = () => Date.now()}, uid) {
  await verify();
  const marker = db.doc(`accountDeletions/${uid}`);
  await db.runTransaction(async tx => {
    const current = await tx.get(marker);
    if (!current.exists) {
      tx.create(marker, {status: 'pending', startedAt: admin.firestore.Timestamp.fromMillis(now())});
    } else {
      // A privileged writer may have recreated Auth/data since a previous run.
      // Re-establish the full token-expiry window for every completed deletion.
      tx.update(marker, {status: 'pending', completedAt: admin.firestore.FieldValue.delete(),
        purgeAfter: admin.firestore.FieldValue.delete()});
    }
  });
  // The marker blocks stale ID tokens before Auth or Firestore are changed.
  if (await findUser(auth, uid)) {
    await auth.updateUser(uid, {disabled: true});
    await auth.revokeRefreshTokens(uid);
  }
  await db.recursiveDelete(db.doc(`users/${uid}`));
  for (const ref of await leaderboardRefs(db, uid)) {
    // Also handle legacy subcollections under an entry, if present.
    await db.recursiveDelete(ref);
  }
  // Keep Auth until data removal succeeds, so failures remain identifiable/retryable.
  try { await auth.deleteUser(uid); } catch (e) { if (!missingUser(e)) throw e; }
  const remaining = await inspect({db, auth}, uid);
  if (remaining.authExists || remaining.profileExists || remaining.privateCollections.length || remaining.leaderboardEntries) {
    throw new Error('Deletion incomplete. Marker retained; retry the same UID.');
  }
  await marker.update({status: 'complete', completedAt: admin.firestore.Timestamp.fromMillis(now()),
    purgeAfter: admin.firestore.Timestamp.fromMillis(now() + RETENTION_MS)});
  return remaining;
}

async function cleanupMarker({db, auth, now = () => Date.now()}, uid) {
  const ref = db.doc(`accountDeletions/${uid}`);
  const marker = await ref.get();
  if (!marker.exists) return;
  if (marker.get('status') !== 'complete' || !marker.get('purgeAfter') || marker.get('purgeAfter').toMillis() > now()) {
    throw new Error('Marker must remain for at least 65 minutes after completed deletion.');
  }
  const remaining = await inspect({db, auth}, uid);
  if (remaining.authExists || remaining.profileExists || remaining.privateCollections.length || remaining.leaderboardEntries) {
    throw new Error('Data/Auth still present; keep marker and rerun deletion.');
  }
  await ref.delete();
}

function parseArgs(args) {
  const options = {};
  for (let i = 0; i < args.length; i++) {
    const key = args[i];
    if (['--execute', '--cleanup-marker'].includes(key)) options[key.slice(2)] = true;
    else if (['--project', '--uid', '--confirm'].includes(key) && args[i + 1] && !args[i + 1].startsWith('--')) options[key.slice(2)] = args[++i];
    else throw new Error(`Unknown/missing argument: ${key}`);
  }
  if (!options.project || !options.uid || !/^[^/\s]{1,128}$/.test(options.uid)) throw new Error('Explicit --project and a valid --uid are required.');
  if (options['cleanup-marker'] && !options.execute) throw new Error('--cleanup-marker requires --execute');
  if (options.execute && options.confirm !== `${options.project}:${options.uid}`) throw new Error('--execute requires --confirm PROJECT:UID');
  return options;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const emulated = !!(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST);
  if (emulated && !(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST && options.project.startsWith('demo-'))) {
    throw new Error('Emulator mode requires both emulator hosts and an explicit demo- project.');
  }
  const app = admin.initializeApp({projectId: options.project});
  const services = {db: admin.firestore(app), auth: admin.auth(app),
    verify: emulated ? async () => {} : () => verifyRules(app)};
  try {
    if (!options.execute) console.log(JSON.stringify({mode: 'dry-run', project: options.project, uid: options.uid, ...await inspect(services, options.uid)}));
    else if (options['cleanup-marker']) { await cleanupMarker(services, options.uid); console.log('Deletion marker removed after expiry and verification.'); }
    else console.log(JSON.stringify({mode: 'completed', project: options.project, uid: options.uid, ...await removeAccount(services, options.uid)}));
  } finally { await app.delete(); }
}
if (require.main === module) main().catch(e => { console.error(`Deletion stopped: ${e.message}`); process.exitCode = 1; });
module.exports = {inspect, removeAccount, cleanupMarker, parseArgs, verifyRules, RETENTION_MS};
