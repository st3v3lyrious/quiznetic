const {test} = require('node:test');
const assert = require('node:assert/strict');
const {leaderboardDisplayName} = require('../privacy.cjs');
test('public fallback never derives a name from an email', () => {
  assert.equal(leaderboardDisplayName({uid:'abc123', isAnonymous:false, email:'private.person@example.test'}),'Player');
  assert.equal(leaderboardDisplayName({uid:'abc123', isAnonymous:false, displayName:'  ',email:'private@example.test'}),'Player');
});
test('explicit pseudonyms and guest labels are preserved', () => {
  assert.equal(leaderboardDisplayName({uid:'abc1234', isAnonymous:false, displayName:'  Quiz Fan  '}),'Quiz Fan');
  assert.equal(leaderboardDisplayName({uid:'abc1234', isAnonymous:true}),'Guest-abc123');
});
