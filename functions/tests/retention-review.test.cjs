const {test} = require('node:test');
const assert = require('node:assert/strict');
const {monthsBefore, assessActivity, inspectRetention, parseArgs} = require('../scripts/review-retention.cjs');

test('calendar retention clamps leap-day and month-end boundaries', () => {
  assert.equal(monthsBefore(new Date('2024-02-29T12:30:00Z'), 12).toISOString(), '2023-02-28T12:30:00.000Z');
  assert.equal(monthsBefore(new Date('2026-03-31T12:30:00Z'), 1).toISOString(), '2026-02-28T12:30:00.000Z');
});

test('recent gameplay prevents selection based on an old sign-in', () => {
  const now = new Date('2026-10-27T12:00:00Z');
  assert.equal(assessActivity(['2023-01-01', '2026-10-26'], now).status, 'recent_activity');
  assert.deepEqual(assessActivity(['2024-10-27T12:00:00Z'], now), {status: 'review_candidate', deletionAuthorized: false});
  for (const signals of [[], ['invalid'], ['2027-01-01']]) {
    assert.equal(assessActivity(signals, now).status, 'manual_review');
  }
});

test('CLI has no execution mode and refuses ambiguous project/UID inputs', () => {
  assert.deepEqual(parseArgs(['--uid', 'synthetic-user', '--project', 'demo-retention']), {project: 'demo-retention', uid: 'synthetic-user'});
  for (const args of [[], ['--execute'], ['--project', 'demo-retention', '--uid', 'a/b'], ['--project', 'demo-retention', '--uid', 'x', '--uid', 'y']]) {
    assert.throws(() => parseArgs(args));
  }
});

test('review uses only bounded reads and omits account identity from output', async () => {
  const calls = [];
  const doc = fields => ({get: key => fields[key]});
  const query = name => ({
    orderBy: (...args) => { calls.push(['orderBy', name, ...args]); return query(name); },
    where: (...args) => { calls.push(['where', name, ...args]); return query('old'); },
    limit: count => { calls.push(['limit', name, count]); return query(name); },
    get: async () => ({size: name === 'old' ? 101 : 1, docs: [doc({createdAt: new Date('2026-10-26'), updatedAt: new Date('2026-10-26')})]}),
  });
  const root = {get: async () => ({exists: true, get: () => new Date('2020-01-01')}), collection: query};
  const db = {collection: name => { assert.equal(name, 'users'); return {doc: uid => {assert.equal(uid, 'synthetic-user'); return root;}}; }};
  const auth = {getUser: async () => ({metadata: {lastSignInTime: '2020-01-01'}})};
  const result = await inspectRetention({db, auth}, 'synthetic-user', new Date('2026-10-27'));
  assert.equal(result.activity.status, 'recent_activity');
  assert.equal(result.oldAttemptsObserved, 100);
  assert.equal(result.oldAttemptsExceedLimit, true);
  assert.equal(result.completeInventory, false);
  assert.equal(JSON.stringify(result).includes('synthetic-user'), false);
  assert.deepEqual(calls.filter(call => call[0] === 'limit').map(call => call[2]), [1, 1, 101]);
});
