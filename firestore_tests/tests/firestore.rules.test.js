import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';

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
    updatedAt: Timestamp.now(),
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
    updatedAt: Timestamp.now(),
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

  test('user cannot write score for another uid', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userB/scores/flag_easy');

    await assertFails(setDoc(scoreDoc, scorePayload()));
  });

  test('invalid score payload is rejected', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const scoreDoc = doc(db, 'users/userA/scores/flag_easy');

    await assertFails(setDoc(scoreDoc, scorePayload({ bestScore: -1 })));
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

  test('user cannot write leaderboard entry for another uid', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const entryDoc = doc(db, 'leaderboard/flag_easy/entries/userB');

    await assertFails(setDoc(entryDoc, leaderboardPayload({ uid: 'userB' })));
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
});
