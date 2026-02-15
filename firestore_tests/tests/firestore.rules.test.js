import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rulesPath = path.resolve(__dirname, '../../firestore.rules');

const projectId = 'quiznetic-firestore-rules-test';
let testEnv;

function parseEmulatorHost() {
  const value = process.env.FIRESTORE_EMULATOR_HOST;
  if (!value) {
    throw new Error(
      'FIRESTORE_EMULATOR_HOST is not set. Run via `npm run test:emulator`.',
    );
  }

  const [host, portRaw] = value.split(':');
  const port = Number(portRaw);
  if (!host || Number.isNaN(port)) {
    throw new Error(`Invalid FIRESTORE_EMULATOR_HOST value: ${value}`);
  }
  return { host, port };
}

function scorePayload({ categoryKey = 'flag', difficulty = 'easy', bestScore = 14 } = {}) {
  return {
    categoryKey,
    difficulty,
    bestScore,
    source: 'guest',
    updatedAt: serverTimestamp(),
  };
}

function leaderboardPayload({
  uid = 'userA',
  categoryKey = 'flag',
  difficulty = 'easy',
  score = 14,
  isAnonymous = true,
} = {}) {
  return {
    categoryKey,
    difficulty,
    score,
    isAnonymous,
    displayName: `Guest-${uid.slice(0, 6)}`,
    updatedAt: serverTimestamp(),
  };
}

function attemptPayload({
  attemptId = 'attempt-1',
  categoryKey = 'flag',
  difficulty = 'easy',
  correctCount = 14,
  totalQuestions = 15,
  status = 'accepted',
} = {}) {
  return {
    attemptId,
    categoryKey,
    difficulty,
    correctCount,
    totalQuestions,
    status,
    source: 'guest',
    createdAt: Timestamp.now(),
  };
}

before(async () => {
  const rules = await readFile(rulesPath, 'utf8');
  const emulator = parseEmulatorHost();
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules,
      host: emulator.host,
      port: emulator.port,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

describe('Firestore security rules', () => {
  test('owner can create and read their own user document', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const userDoc = doc(db, 'users/userA');

    await assertSucceeds(
      setDoc(userDoc, {
        isAnonymous: true,
        createdAt: Timestamp.now(),
        lastSeen: Timestamp.now(),
        displayName: 'Guest userA',
      }),
    );
    await assertSucceeds(getDoc(userDoc));
  });

  test('user cannot read another user document', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(doc(adminDb, 'users/userB'), {
        isAnonymous: true,
        createdAt: Timestamp.now(),
        lastSeen: Timestamp.now(),
        displayName: 'Guest userB',
      });
    });

    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(getDoc(doc(db, 'users/userB')));
  });

  test('owner can write and read own score subdocument', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userA/scores/flag_easy');

    await assertSucceeds(setDoc(scoreDoc, scorePayload()));
    await assertSucceeds(getDoc(scoreDoc));
  });

  test('score updates must strictly improve best score', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(doc(adminDb, 'users/userA/scores/flag_easy'), scorePayload({ bestScore: 12 }));
    });

    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userA/scores/flag_easy');

    await assertFails(setDoc(scoreDoc, scorePayload({ bestScore: 12 })));
    await assertFails(setDoc(scoreDoc, scorePayload({ bestScore: 11 })));
    await assertSucceeds(setDoc(scoreDoc, scorePayload({ bestScore: 13 })));
  });

  test('user cannot write score for another uid', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userB/scores/flag_easy');

    await assertFails(setDoc(scoreDoc, scorePayload()));
  });

  test('invalid score payload is rejected', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userA/scores/flag_easy');

    await assertFails(setDoc(scoreDoc, scorePayload({ bestScore: -1 })));
    await assertFails(setDoc(scoreDoc, scorePayload({ bestScore: 99 })));
    const mismatchedId = doc(db, 'users/userA/scores/capital_easy');
    await assertFails(
      setDoc(
        mismatchedId,
        scorePayload({ categoryKey: 'flag', difficulty: 'easy', bestScore: 10 }),
      ),
    );
  });

  test('score payload with client-provided updatedAt is rejected', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userA/scores/flag_easy');

    await assertFails(
      setDoc(scoreDoc, {
        ...scorePayload(),
        updatedAt: Timestamp.fromDate(new Date('2000-01-01T00:00:00.000Z')),
      }),
    );
  });

  test('owner can write own leaderboard entry and authenticated users can read', async () => {
    const ownerDb = testEnv.authenticatedContext('userA').firestore();
    const entryDoc = doc(ownerDb, 'leaderboard/flag_easy/entries/userA');
    await assertSucceeds(setDoc(entryDoc, leaderboardPayload()));

    const readerDb = testEnv.authenticatedContext('userB').firestore();
    await assertSucceeds(
      getDoc(doc(readerDb, 'leaderboard/flag_easy/entries/userA')),
    );
  });

  test('leaderboard updates must strictly improve score', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(
        doc(adminDb, 'leaderboard/flag_easy/entries/userA'),
        leaderboardPayload({ score: 12 }),
      );
    });

    const db = testEnv.authenticatedContext('userA').firestore();
    const entryDoc = doc(db, 'leaderboard/flag_easy/entries/userA');

    await assertFails(setDoc(entryDoc, leaderboardPayload({ score: 12 })));
    await assertFails(setDoc(entryDoc, leaderboardPayload({ score: 11 })));
    await assertSucceeds(setDoc(entryDoc, leaderboardPayload({ score: 13 })));
  });

  test('user cannot write leaderboard entry for another uid', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const entryDoc = doc(db, 'leaderboard/flag_easy/entries/userB');

    await assertFails(setDoc(entryDoc, leaderboardPayload({ uid: 'userB' })));
  });

  test('leaderboard payload with client-provided updatedAt is rejected', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const entryDoc = doc(db, 'leaderboard/flag_easy/entries/userA');

    await assertFails(
      setDoc(entryDoc, {
        ...leaderboardPayload(),
        updatedAt: Timestamp.fromDate(new Date('2000-01-01T00:00:00.000Z')),
      }),
    );
  });

  test('unauthenticated user cannot read leaderboard entry', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(
        doc(adminDb, 'leaderboard/flag_easy/entries/userA'),
        leaderboardPayload(),
      );
    });

    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'leaderboard/flag_easy/entries/userA')));
  });

  test('owner can create and read attempt records but cannot update', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const attemptDoc = doc(db, 'users/userA/attempts/attempt-1');

    await assertSucceeds(setDoc(attemptDoc, attemptPayload()));
    await assertSucceeds(getDoc(attemptDoc));
    await assertFails(
      setDoc(
        attemptDoc,
        attemptPayload({ correctCount: 15 }),
        { merge: true },
      ),
    );
  });

  test('attempt payload must match difficulty bounds and attempt id', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();

    await assertFails(
      setDoc(
        doc(db, 'users/userA/attempts/attempt-1'),
        attemptPayload({ totalQuestions: 30 }),
      ),
    );

    await assertFails(
      setDoc(
        doc(db, 'users/userA/attempts/attempt-1'),
        attemptPayload({ attemptId: 'different-id' }),
      ),
    );

    await assertFails(
      setDoc(
        doc(db, 'users/userA/attempts/attempt-1'),
        attemptPayload({ correctCount: 20 }),
      ),
    );
  });

  test('user cannot write attempts for another uid', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      setDoc(
        doc(db, 'users/userB/attempts/attempt-1'),
        attemptPayload(),
      ),
    );
  });
});
