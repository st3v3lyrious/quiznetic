// Public names must never be derived from an account email address.
function leaderboardDisplayName({uid, isAnonymous, displayName}) {
  if (typeof displayName === 'string' && displayName.trim()) return displayName.trim();
  return isAnonymous ? `Guest-${uid.slice(0, 6)}` : 'Player';
}
module.exports = {leaderboardDisplayName};
