const {onCall, HttpsError} = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const ALLOWED_CATEGORIES = new Set(['flag', 'capital']);
const EXPECTED_TOTAL_QUESTIONS = {
  easy: 15,
  intermediate: 30,
  expert: 50,
};

const MIN_DURATION_MS = 5_000;
const MAX_DURATION_MS = 30 * 60_000;
const RATE_LIMIT_ATTEMPTS = 20;
const RATE_LIMIT_WINDOW_MS = 10 * 60_000;

function toTrimmedString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function toInt(value) {
  if (typeof value === 'number' && Number.isInteger(value)) {
    return value;
  }
  return null;
}

function parseClientTimestamp(value) {
  if (typeof value === 'string') {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  if (typeof value === 'number' && Number.isFinite(value)) {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  return null;
}

function isAnonymousRequest(authToken) {
  return authToken?.firebase?.sign_in_provider === 'anonymous';
}

function leaderboardDisplayName({uid, isAnonymous, displayName, email}) {
  const normalizedDisplayName = toTrimmedString(displayName);
  if (normalizedDisplayName.length > 0) {
    return normalizedDisplayName;
  }

  const normalizedEmail = toTrimmedString(email);
  if (normalizedEmail.length > 0) {
    return normalizedEmail.split('@')[0];
  }

  if (isAnonymous) {
    return `Guest-${uid.slice(0, 6)}`;
  }

  return 'Player';
}

function rejectedResponse(rejectionCode, message) {
  return {
    status: 'rejected',
    bestScoreUpdated: false,
    newBestScore: null,
    leaderboardScope: null,
    rejectionCode,
    riskFlags: [],
    message,
  };
}

function rateLimitedResponse() {
  return {
    status: 'rate_limited',
    bestScoreUpdated: false,
    newBestScore: null,
    leaderboardScope: null,
    rejectionCode: 'rate_limited',
    riskFlags: [],
    message: 'Too many score submissions. Please wait and try again.',
  };
}

function buildRiskFlags({correctCount, totalQuestions, durationMs}) {
  const riskFlags = [];

  if (correctCount === totalQuestions && durationMs < 8_000) {
    riskFlags.push('too_fast_perfect_score');
  }

  return riskFlags;
}

async function isRateLimited({uid, now}) {
  const windowStart = admin.firestore.Timestamp.fromMillis(
    now.getTime() - RATE_LIMIT_WINDOW_MS,
  );

  const attemptsSnap = await db
      .collection('users')
      .doc(uid)
      .collection('attempts')
      .where('createdAt', '>=', windowStart)
      .limit(RATE_LIMIT_ATTEMPTS)
      .get();

  return attemptsSnap.size >= RATE_LIMIT_ATTEMPTS;
}

exports.submitScore = onCall(
    {
      region: 'us-central1',
    },
    async (request) => {
      const auth = request.auth;
      if (!auth) {
        throw new HttpsError('unauthenticated', 'Authentication is required.');
      }

      const uid = auth.uid;
      const payload = request.data || {};

      const attemptId = toTrimmedString(payload.attemptId);
      const categoryKey = toTrimmedString(payload.categoryKey);
      const difficulty = toTrimmedString(payload.difficulty);
      const correctCount = toInt(payload.correctCount);
      const totalQuestions = toInt(payload.totalQuestions);
      const clientVersion = toTrimmedString(payload.clientVersion);
      const startedAtDate = parseClientTimestamp(payload.startedAt);
      const finishedAtDate = parseClientTimestamp(payload.finishedAt);

      if (attemptId.length < 1 || attemptId.length > 120) {
        return rejectedResponse(
            'invalid_attempt_id',
            'attemptId must be a non-empty string up to 120 chars.',
        );
      }

      if (!ALLOWED_CATEGORIES.has(categoryKey)) {
        return rejectedResponse(
            'unsupported_category',
            'Unsupported category key.',
        );
      }

      if (!(difficulty in EXPECTED_TOTAL_QUESTIONS)) {
        return rejectedResponse(
            'unsupported_difficulty',
            'Unsupported difficulty.',
        );
      }

      const expectedTotalQuestions = EXPECTED_TOTAL_QUESTIONS[difficulty];
      if (totalQuestions !== expectedTotalQuestions) {
        return rejectedResponse(
            'invalid_total_questions',
            `Expected totalQuestions=${expectedTotalQuestions} for ${difficulty}.`,
        );
      }

      if (
        correctCount === null ||
        correctCount < 0 ||
        correctCount > totalQuestions
      ) {
        return rejectedResponse(
            'invalid_score_bounds',
            'correctCount must be within 0..totalQuestions.',
        );
      }

      if (!startedAtDate || !finishedAtDate) {
        return rejectedResponse(
            'invalid_timestamps',
            'startedAt and finishedAt must be valid timestamps.',
        );
      }

      const durationMs = finishedAtDate.getTime() - startedAtDate.getTime();
      if (durationMs <= 0) {
        return rejectedResponse(
            'invalid_timestamps',
            'finishedAt must be greater than startedAt.',
        );
      }

      if (durationMs < MIN_DURATION_MS || durationMs > MAX_DURATION_MS) {
        return rejectedResponse(
            'invalid_duration',
            'Quiz duration is outside accepted bounds.',
        );
      }

      const scope = `${categoryKey}_${difficulty}`;
      const userScoreRef = db
          .collection('users')
          .doc(uid)
          .collection('scores')
          .doc(scope);
      const attemptRef = db
          .collection('users')
          .doc(uid)
          .collection('attempts')
          .doc(attemptId);
      const leaderboardRef = db
          .collection('leaderboard')
          .doc(scope)
          .collection('entries')
          .doc(uid);

      const existingAttempt = await attemptRef.get();
      if (existingAttempt.exists) {
        const existingScoreDoc = await userScoreRef.get();
        const existingBest = existingScoreDoc.exists ?
          Number(existingScoreDoc.data()?.bestScore || 0) : 0;
        return {
          status: 'duplicate',
          bestScoreUpdated: false,
          newBestScore: existingBest,
          leaderboardScope: scope,
          rejectionCode: null,
          riskFlags: [],
          message: null,
        };
      }

      const now = new Date();
      if (await isRateLimited({uid, now})) {
        return rateLimitedResponse();
      }

      const isAnonymous = isAnonymousRequest(auth.token);
      const source = isAnonymous ? 'guest' : 'account';
      const displayName = leaderboardDisplayName({
        uid,
        isAnonymous,
        displayName: auth.token?.name,
        email: auth.token?.email,
      });
      const riskFlags = buildRiskFlags({
        correctCount,
        totalQuestions,
        durationMs,
      });
      const attemptStatus = riskFlags.length > 0 ? 'flagged' : 'accepted';

      const txnResult = await db.runTransaction(async (tx) => {
        const existingAttempt = await tx.get(attemptRef);
        if (existingAttempt.exists) {
          const existingScoreDoc = await tx.get(userScoreRef);
          const existingBest = existingScoreDoc.exists ?
            Number(existingScoreDoc.data()?.bestScore || 0) : 0;
          return {
            status: 'duplicate',
            bestScoreUpdated: false,
            newBestScore: existingBest,
          };
        }

        tx.set(attemptRef, {
          attemptId,
          categoryKey,
          difficulty,
          correctCount,
          totalQuestions,
          startedAt: admin.firestore.Timestamp.fromDate(startedAtDate),
          finishedAt: admin.firestore.Timestamp.fromDate(finishedAtDate),
          durationMs,
          status: attemptStatus,
          source,
          riskFlags,
          clientVersion: clientVersion.length > 0 ? clientVersion : null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const scoreSnapshot = await tx.get(userScoreRef);
        const previousBest = scoreSnapshot.exists ?
          Number(scoreSnapshot.data()?.bestScore || 0) : 0;
        const bestScoreUpdated = correctCount > previousBest;
        const newBestScore = bestScoreUpdated ? correctCount : previousBest;

        if (bestScoreUpdated) {
          tx.set(userScoreRef, {
            categoryKey,
            difficulty,
            bestScore: correctCount,
            source,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});

          tx.set(leaderboardRef, {
            categoryKey,
            difficulty,
            score: correctCount,
            isAnonymous,
            displayName,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        }

        return {
          status: attemptStatus,
          bestScoreUpdated,
          newBestScore,
        };
      });

      logger.info('submitScore processed', {
        uid,
        attemptId,
        categoryKey,
        difficulty,
        status: txnResult.status,
        bestScoreUpdated: txnResult.bestScoreUpdated,
      });

      return {
        status: txnResult.status,
        bestScoreUpdated: txnResult.bestScoreUpdated,
        newBestScore: txnResult.newBestScore,
        leaderboardScope: scope,
        rejectionCode: null,
        riskFlags,
        message: null,
      };
    },
);
