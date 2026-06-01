# Firebase Query Efficiency & Caching

## Why Firebase Calls Inside `build()` Are Dangerous

`build()` can be called dozens of times per second — on every `setState`, every parent rebuild, every animation frame that touches the subtree. A Firebase call inside `build()` means:

1. A new `Future` (or `Stream` subscription) is created on every call.
2. Each `Future` triggers a network request to Firestore.
3. When the response arrives, it calls `setState` → triggers another `build()` → another Firebase call.
4. This creates an **infinite request loop**.

```dart
// DANGEROUS — new Firestore request on every rebuild
@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: FirebaseFirestore.instance         // ← new Future every build()
        .collection('leaderboard')
        .doc(categoryKey)
        .collection('entries')
        .get(),
    builder: (context, snap) { ... },
  );
}
```

---

## The Correct Pattern: Cache the Future

Store the `Future` in a field. `FutureBuilder` re-uses the same `Future` across rebuilds — only the initial creation triggers a request.

```dart
class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final Future<List<LeaderboardEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _fetchEntries(); // created ONCE
  }

  Future<List<LeaderboardEntry>> _fetchEntries() async {
    final snap = await FirebaseFirestore.instance
        .collection('leaderboard')
        .doc(widget.categoryKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(20)
        .get();
    return snap.docs.map(LeaderboardEntry.fromFirestore).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _entriesFuture, // reused — no extra requests
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final entries = snap.data ?? [];
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (_, i) => LeaderboardRow(entry: entries[i]),
        );
      },
    );
  }
}
```

---

## `get()` vs `snapshots()` — Choose the Right Tool

| Method | Use when | Cost |
| -------- | ---------- | ------ |
| `.get()` | Data doesn't need real-time updates (leaderboard view, profile load, best score display) | One read per call |
| `.snapshots()` | Data changes while the user is looking at it and they must see updates (live multiplayer, active session) | Sustained connection + read on every change |

**QuizNetic guideline:** Use `.get()` for leaderboard reads and score lookups. Use `.snapshots()` only if a live-updating feed is explicitly needed.

```dart
// Correct for leaderboard — one-time read
final snap = await db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .orderBy('score', descending: true)
    .limit(10)
    .get();

// Only use snapshots() if the UI must update while open
final stream = db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .orderBy('score', descending: true)
    .limit(10)
    .snapshots();
```

---

## Always Use `.limit()` on Reads

Without `.limit()`, a query returns every matching document. A leaderboard with 10,000 users returns 10,000 documents — each billed as a read and loaded into memory.

```dart
// Bad — unbounded read; expensive and slow
final snap = await db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .orderBy('score', descending: true)
    .get();

// Good — bounded; predictable cost
final snap = await db
    .collection('leaderboard')
    .doc(categoryKey)
    .collection('entries')
    .orderBy('score', descending: true)
    .limit(20)
    .get();
```

---

## Offline Cache & Persistence

Firestore's local cache is enabled by default on mobile. When offline, `.get()` returns cached data. Use `GetOptions` to control behavior explicitly:

```dart
// Use cache first, then network (fast, stale-ok)
final snap = await ref.get(const GetOptions(source: Source.cache));

// Force network (always fresh, fails offline)
final snap = await ref.get(const GetOptions(source: Source.server));

// Default: cache if available, else network
final snap = await ref.get();
```

For leaderboard reads where slightly stale data is acceptable, prefer `Source.cache` for instant display, then refresh in the background:

```dart
Future<void> _loadLeaderboard() async {
  // 1. Show cached data instantly
  try {
    final cached = await _ref.get(const GetOptions(source: Source.cache));
    if (cached.docs.isNotEmpty) {
      setState(() => _entries = _parse(cached));
    }
  } catch (_) { /* no cache yet */ }

  // 2. Refresh from network silently
  final fresh = await _ref.get(const GetOptions(source: Source.server));
  setState(() => _entries = _parse(fresh));
}
```

---

## Transaction Efficiency

Transactions are the correct tool for compare-and-swap (best score update). Each transaction is **one round-trip per read inside it** — minimize reads.

```dart
// Good — one read, one conditional write
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

Avoid reading multiple documents inside a single transaction unless strictly necessary — each read is a separate Firestore I/O operation.

---

## Stream Subscription Lifecycle

If you subscribe to a Firestore `snapshots()` stream manually (outside `StreamBuilder`), you must cancel the subscription in `dispose()` to avoid memory leaks and ghost writes.

```dart
class _ScoreScreenState extends State<ScoreScreen> {
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = scoreRef.snapshots().listen((snap) {
      setState(() => _score = snap.data()?['bestScore'] as int? ?? 0);
    });
  }

  @override
  void dispose() {
    _sub?.cancel(); // ← mandatory
    super.dispose();
  }
}
```

**Prefer `StreamBuilder` over manual subscriptions** — it handles lifecycle automatically.

---

## Error Handling by Code

Always handle `FirebaseException` by code to give the user actionable feedback:

```dart
try {
  await db.runTransaction((_) async { ... });
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      // Log — likely a security rules misconfiguration
      debugPrint('Firestore permission denied: ${e.message}');
    case 'unavailable':
      // Show offline message — expected when device has no network
      _showOfflineSnackbar(context);
    case 'deadline-exceeded':
      // Retry or inform user
      _showRetryDialog(context);
    default:
      debugPrint('Firestore error [${e.code}]: ${e.message}');
  }
}
```

---

## Anti-Patterns Summary

| Pattern | Why It's Wrong | Fix |
| --------- | --------------- | ----- |
| `FutureBuilder(future: db.collection(...).get())` in `build()` | New request on every rebuild | Cache `Future` in `initState` |
| `.snapshots()` for leaderboard display | Sustained connection for data that doesn't need to be live | `.get()` with cache strategy |
| Query without `.limit()` | Unbounded reads; cost and memory spike | Always add `.limit(n)` |
| Manual stream subscription without `dispose` | Memory leak, ghost `setState` after unmount | Use `StreamBuilder` or cancel in `dispose()` |
| Multiple document reads in a transaction | Slow round-trips | Minimize reads per transaction |
| Fetching the same data multiple times across screens | Wasted reads, inconsistent state | Pass data via route args or cache at app level |
