# Firebase — Firestore Patterns

## Setup

Use `lib/firebase_env_options.dart` for platform-specific `FirebaseOptions`. Never hardcode `google-services.json` values in Dart.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_env_options.dart';

await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
```

For auth patterns (Google, Apple, anonymous, profile sync), see the [quiznetic-firebase-auth skill](../../quiznetic-firebase-auth/SKILL.md).

---

## Firestore Schema

```text
users/{uid}/scores/{categoryKey}          → { bestScore: int, updatedAt: Timestamp }
leaderboard/{categoryKey}/entries/{uid}   → { score: int, updatedAt: Timestamp, displayName: String }
```

---

## Patterns

### Best Score — Compare-and-Swap via Transaction

Use a transaction to avoid race conditions when multiple devices could write simultaneously.

```dart
final db = FirebaseFirestore.instance;
final scoreRef = db
    .collection('users')
    .doc(uid)
    .collection('scores')
    .doc(categoryKey);

await db.runTransaction((tx) async {
  final snap = await tx.get(scoreRef);
  final current = snap.exists ? (snap.data()!['bestScore'] as int? ?? 0) : 0;
  if (newScore > current) {
    tx.set(scoreRef, {
      'bestScore': newScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
});
```

### Leaderboard — Upsert Entry

```dart
final entryRef = db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .doc(uid);

await entryRef.set({
  'score': score,
  'updatedAt': FieldValue.serverTimestamp(),
  'displayName': displayName,
}, SetOptions(merge: true));
```

### Top N Leaderboard Read

```dart
final snap = await db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .orderBy('score', descending: true)
    .limit(10)
    .get();

final entries = snap.docs.map((d) => LeaderboardEntry.fromFirestore(d)).toList();
```

### Read a User's Best Score

```dart
final doc = await db
    .collection('users')
    .doc(uid)
    .collection('scores')
    .doc(categoryKey)
    .get();

final best = doc.exists ? (doc.data()!['bestScore'] as int? ?? 0) : 0;
```

---

## Best Practices

- Use `FieldValue.serverTimestamp()` for all `updatedAt` fields — never `DateTime.now()`.
- Use transactions for any read-then-write to avoid races (especially scores).
- Use `WriteBatch` when deleting or updating multiple docs atomically.
- Cache Firestore results in screen state — do not re-fetch on every `build()`.
- Always handle `FirebaseException` by code: `permission-denied`, `unavailable`, `not-found`.

---

## Error Handling Pattern

```dart
try {
  await db.runTransaction((_) async { ... });
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      debugPrint('Firestore permission denied — check security rules');
    case 'unavailable':
      debugPrint('Firestore offline — will retry when online');
    default:
      debugPrint('Firestore error: ${e.code} ${e.message}');
  }
}
```

---

## Firestore Security Rules

Enforce in `firestore.rules`:

- Users write only to `users/{uid}/**` where `request.auth.uid == uid`.
- Leaderboard entries written only by the matching authenticated user.
- Leaderboard reads are public (unauthenticated reads allowed).

---

## What NOT to Do

- Do not call `db.collection(...)` inside `build()` — use `initState` + `setState`, or `FutureBuilder`.
- Do not use `get()` on large collections without `.limit()`.
- Do not subscribe with `snapshots()` unless real-time updates are genuinely needed — prefer `get()` for leaderboards.
- Do not store raw `DocumentReference` objects across widget rebuilds.
- Do not use deprecated packages (`cloud_functions`) unless Cloud Functions are explicitly required.
