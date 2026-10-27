#!/usr/bin/env node
// Read-only operator review. No deletion, notifications or account mutation.
function monthsBefore(now, months) {
  const result = new Date(now);
  const day = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() - months);
  const last = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(day, last));
  return result;
}

function milliseconds(value) {
  if (value == null) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'string') return Date.parse(value);
  return NaN;
}

function assessActivity(values, now) {
  const times = values.filter(value => value != null).map(milliseconds);
  if (!times.length || times.some(time => !Number.isFinite(time) || time > now.getTime())) {
    return {status: 'manual_review', deletionAuthorized: false};
  }
  const latest = Math.max(...times);
  return {
    status: latest <= monthsBefore(now, 24).getTime() ? 'review_candidate' : 'recent_activity',
    deletionAuthorized: false,
  };
}

async function inspectRetention({db, auth}, uid, now = new Date()) {
  if (!Number.isFinite(now.getTime())) throw new Error('Invalid review date');
  let user;
  try { user = await auth.getUser(uid); }
  catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
  const root = db.collection('users').doc(uid);
  const [profile, attempts, scores, oldAttempts] = await Promise.all([
    root.get(),
    root.collection('attempts').orderBy('createdAt', 'desc').limit(1).get(),
    root.collection('scores').orderBy('updatedAt', 'desc').limit(1).get(),
    root.collection('attempts').where('createdAt', '<', monthsBefore(now, 12)).limit(101).get(),
  ]);
  const signals = [
    user?.metadata?.creationTime, user?.metadata?.lastSignInTime,
    user?.metadata?.lastRefreshTime,
    profile.get('createdAt'), profile.get('lastSeen'),
    ...attempts.docs.map(doc => doc.get('createdAt')),
    ...scores.docs.map(doc => doc.get('updatedAt')),
  ];
  return {
    mode: 'read-only', reviewedAt: now.toISOString(),
    authExists: !!user, profileExists: profile.exists,
    activity: assessActivity(signals, now),
    oldAttemptsObserved: Math.min(oldAttempts.size, 100),
    oldAttemptsExceedLimit: oldAttempts.size > 100,
    completeInventory: false,
    warning: 'Review only: timestamps cannot prove absence of all activity. Missing timestamp fields are not included in ordered queries. Recheck activity, notice and authorization before any separate deletion.',
  };
}

function parseArgs(args) {
  const options = {};
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index];
    const value = args[index + 1];
    if (!['--project', '--uid'].includes(key) || !value || value.startsWith('--') || options[key]) {
      throw new Error('Only explicit --project PROJECT --uid UID are accepted; no execution mode exists.');
    }
    options[key] = value;
  }
  if (!/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/.test(options['--project'] || '') ||
      !/^[^/\s]{1,128}$/.test(options['--uid'] || '')) {
    throw new Error('Explicit valid project and UID are required.');
  }
  return {project: options['--project'], uid: options['--uid']};
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const emulated = !!(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST);
  if (emulated && !(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST && options.project.startsWith('demo-'))) {
    throw new Error('Emulator mode requires both hosts and a demo- project.');
  }
  const admin = require('firebase-admin');
  const app = admin.initializeApp({projectId: options.project});
  try {
    const result = await inspectRetention({db: admin.firestore(app), auth: admin.auth(app)}, options.uid);
    console.log(JSON.stringify({project: options.project, ...result}));
  } finally { await app.delete(); }
}

if (require.main === module) main().catch(() => {
  console.error('Retention review stopped. Check project, arguments and private operator credentials; no writes performed.');
  process.exitCode = 1;
});
module.exports = {monthsBefore, assessActivity, inspectRetention, parseArgs};
