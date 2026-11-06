#!/usr/bin/env node
// Operator-only history compaction. No scheduled job or production run is installed.
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const MAX_ATTEMPTS = 100;
const PLAN_LIFETIME_MS = 24 * 60 * 60 * 1000;
const RECEIPT = Object.freeze({retentionMarkerVersion: 1});
function monthsBefore(now, months) {
  const d = new Date(now), day = d.getUTCDate();
  d.setUTCDate(1); d.setUTCMonth(d.getUTCMonth() - months);
  d.setUTCDate(Math.min(day, new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate()));
  return d;
}
function validIdentity(project, uid) {
  if (!/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/.test(project || '') ||
      !/^[^/\s]{1,128}$/.test(uid || '')) throw new Error('Explicit project and UID required');
}
function isReceipt(data) {
  return data && Object.keys(data).length === 1 && data.retentionMarkerVersion === 1;
}
function version(snapshot) {
  const t = snapshot.updateTime;
  if (!t || !Number.isInteger(t.seconds) || !Number.isInteger(t.nanoseconds)) throw new Error('Missing version');
  return String(t.seconds) + ':' + String(t.nanoseconds);
}
function eligible(snapshot, cutoff) {
  if (!snapshot.exists) return false;
  const data = snapshot.data();
  const allowed = ['attemptId', 'categoryKey', 'difficulty', 'correctCount', 'totalQuestions',
    'status', 'source', 'createdAt', 'startedAt', 'finishedAt', 'durationMs', 'riskFlags', 'clientVersion'];
  return Object.keys(data).every(k => allowed.includes(k)) &&
    data.attemptId === snapshot.id &&
    ['flag', 'capital'].includes(data.categoryKey) &&
    ['easy', 'intermediate', 'expert'].includes(data.difficulty) &&
    Number.isInteger(data.correctCount) && data.correctCount >= 0 &&
    data.totalQuestions === ({easy: 15, intermediate: 30, expert: 50})[data.difficulty] &&
    data.correctCount <= data.totalQuestions &&
    data.createdAt && typeof data.createdAt.toMillis === 'function' &&
    Number.isFinite(data.createdAt.toMillis()) && data.createdAt.toMillis() < cutoff.getTime();
}
function summaryCovers(snapshot, attempt) {
  if (!snapshot.exists) return attempt.correctCount === 0;
  const best = snapshot.data().bestScore;
  return Number.isInteger(best) && best >= attempt.correctCount;
}
function digest(plan) { return createHash('sha256').update(JSON.stringify(plan)).digest('hex'); }
async function accountReady({db, auth, project}, uid) {
  validIdentity(project, uid);
  const user = await auth.getUser(uid);
  if (user.disabled) throw new Error('Disabled account: manual review');
  const [profile, marker] = await Promise.all([
    db.doc('users/' + uid).get(), db.doc('accountDeletions/' + uid).get(),
  ]);
  if (!profile.exists || marker.exists) throw new Error('Missing profile or account deletion in progress');
}
async function createPlan(services, uid, now = new Date()) {
  if (!Number.isFinite(now.getTime())) throw new Error('Invalid date');
  await accountReady(services, uid);
  const cutoff = monthsBefore(now, 12);
  const snapshot = await services.db.collection('users').doc(uid).collection('attempts')
    .where('createdAt', '<', cutoff).orderBy('createdAt').limit(MAX_ATTEMPTS + 1).get();
  if (snapshot.size > MAX_ATTEMPTS) throw new Error('Batch exceeds limit: narrow and review separately');
  const attempts = [];
  for (const doc of snapshot.docs) {
    if (!eligible(doc, cutoff)) throw new Error('Unknown legacy payload: manual review');
    if ((await doc.ref.listCollections()).length) throw new Error('Nested attempt data: manual review');
    const data = doc.data();
    const score = await services.db.doc('users/' + uid + '/scores/' + data.categoryKey + '_' + data.difficulty).get();
    if (!summaryCovers(score, data)) throw new Error('Missing or inconsistent summary: manual review');
    attempts.push({id: doc.id, version: version(doc)});
  }
  return {version: 1, project: services.project, uid, plannedAt: now.toISOString(),
    cutoff: cutoff.toISOString(), expiresAt: new Date(now.getTime() + PLAN_LIFETIME_MS).toISOString(), attempts};
}
function validatePlan(plan, project, uid, confirmation, now) {
  validIdentity(project, uid);
  if (!plan || Object.keys(plan).sort().join(',') !==
      ['version', 'project', 'uid', 'plannedAt', 'cutoff', 'expiresAt', 'attempts'].sort().join(',') ||
      plan.version !== 1 || plan.project !== project || plan.uid !== uid ||
      !/^[a-f0-9]{64}$/.test(confirmation || '') || digest(plan) !== confirmation) {
    throw new Error('Explicit reviewed manifest digest and matching project/UID required');
  }
  const planned = new Date(plan.plannedAt), expiry = new Date(plan.expiresAt);
  if (![planned, expiry, now].every(d => Number.isFinite(d.getTime())) ||
      planned > now || expiry <= now || expiry.getTime() !== planned.getTime() + PLAN_LIFETIME_MS ||
      plan.cutoff !== monthsBefore(planned, 12).toISOString()) throw new Error('Invalid or expired review');
  if (!Array.isArray(plan.attempts) || plan.attempts.length > MAX_ATTEMPTS ||
      new Set(plan.attempts.map(a => a.id)).size !== plan.attempts.length ||
      plan.attempts.some(a => Object.keys(a).sort().join(',') !== 'id,version' ||
        !/^[^/\s]{1,120}$/.test(a.id || '') || !/^\d+:\d+$/.test(a.version || ''))) {
    throw new Error('Invalid exact selection');
  }
}
async function executePlan(services, uid, plan, confirmation, now = new Date()) {
  validatePlan(plan, services.project, uid, confirmation, now);
  if (typeof services.verifyRules !== 'function') throw new Error('Rules verification required');
  await services.verifyRules();
  await accountReady(services, uid);
  const refs = plan.attempts.map(a => services.db.doc('users/' + uid + '/attempts/' + a.id));
  for (const ref of refs) if ((await ref.listCollections()).length) throw new Error('Nested data requires review');
  return services.db.runTransaction(async tx => {
    // Read the deletion lock and every selected document before any write.
    const marker = await tx.get(services.db.doc('accountDeletions/' + uid));
    const profile = await tx.get(services.db.doc('users/' + uid));
    if (marker.exists || !profile.exists) throw new Error('Account state changed');
    const snapshots = refs.length ? await tx.getAll(...refs) : [];
    const pending = []; const detailed = []; let alreadyCompacted = 0;
    for (let i = 0; i < snapshots.length; i++) {
      const snapshot = snapshots[i];
      if (snapshot.exists && isReceipt(snapshot.data())) { alreadyCompacted++; continue; }
      if (!eligible(snapshot, new Date(plan.cutoff)) || version(snapshot) !== plan.attempts[i].version) {
        throw new Error('Selection changed: review a new plan');
      }
      pending.push(refs[i]); detailed.push(snapshot.data());
    }
    const scopes = [...new Set(detailed.map(d => d.categoryKey + '_' + d.difficulty))];
    const summaryRefs = scopes.map(scope => services.db.doc('users/' + uid + '/scores/' + scope));
    const summaries = summaryRefs.length ? await tx.getAll(...summaryRefs) : [];
    const byScope = new Map(scopes.map((scope, i) => [scope, summaries[i]]));
    for (const data of detailed) {
      if (!summaryCovers(byScope.get(data.categoryKey + '_' + data.difficulty), data)) {
        throw new Error('Missing or inconsistent summary: manual review');
      }
    }
    for (const ref of pending) tx.set(ref, RECEIPT);
    return {selected: refs.length, compacted: pending.length, alreadyCompacted};
  });
}
function parseMode(args) {
  if (args.length === 1 && args[0] === '--plan') return {mode: 'plan'};
  if (args.length === 3 && args[0] === '--execute' && args[1] === '--confirm' &&
      /^[a-f0-9]{64}$/.test(args[2])) return {mode: 'execute', confirmation: args[2]};
  throw new Error('Use --plan or --execute --confirm SHA256');
}
function privateManifestPath(filename) {
  if (!filename) throw new Error('Private manifest path required');
  const resolved = path.resolve(filename), checkout = fs.realpathSync(path.resolve(__dirname, '../..'));
  const canonical = path.join(fs.realpathSync(path.dirname(resolved)), path.basename(resolved));
  if (canonical === checkout || canonical.startsWith(checkout + path.sep)) throw new Error('Keep manifests outside checkout');
  const parent = fs.lstatSync(path.dirname(resolved));
  if (!parent.isDirectory() || parent.isSymbolicLink() || (parent.mode & 0o077)) throw new Error('Private directory required');
  return resolved;
}
async function main() {
  const mode = parseMode(process.argv.slice(2));
  const project = process.env.RETENTION_PROJECT, uid = process.env.RETENTION_UID;
  validIdentity(project, uid);
  const filename = privateManifestPath(process.env.RETENTION_MANIFEST);
  const emulated = !!(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST);
  if (emulated && !(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST &&
      project.startsWith('demo-'))) throw new Error('Both emulator hosts and demo project required');
  const admin = require('firebase-admin');
  const app = admin.initializeApp({projectId: project});
  const services = {project, db: admin.firestore(app), auth: admin.auth(app),
    verifyRules: emulated ? async () => {} : () => require('./delete-account.cjs').verifyRules(app)};
  try {
    if (mode.mode === 'plan') {
      const plan = await createPlan(services, uid);
      const fd = fs.openSync(filename, 'wx', 0o600);
      try { fs.writeFileSync(fd, JSON.stringify(plan)); } finally { fs.closeSync(fd); }
      console.log(JSON.stringify({mode: 'read-only', selected: plan.attempts.length,
        manifestDigest: digest(plan), expiresAt: plan.expiresAt, completeInventory: false,
        warning: 'Missing dates excluded; no deletion authorized by planning.'}));
    } else {
      const stat = fs.lstatSync(filename);
      if (!stat.isFile() || stat.isSymbolicLink() || (stat.mode & 0o077) || stat.size > 1000000) {
        throw new Error('Private bounded regular manifest required');
      }
      const plan = JSON.parse(fs.readFileSync(filename, 'utf8'));
      console.log(JSON.stringify({mode: 'completed',
        ...await executePlan(services, uid, plan, mode.confirmation)}));
    }
  } finally { await app.delete(); }
}
if (require.main === module) main().catch(() => {
  console.error('Retention operation stopped. Check private manifest, authorization, rules and operator credentials.');
  process.exitCode = 1;
});
module.exports = {createPlan, executePlan, validatePlan, digest, isReceipt, monthsBefore, parseMode, privateManifestPath, RECEIPT, MAX_ATTEMPTS};
