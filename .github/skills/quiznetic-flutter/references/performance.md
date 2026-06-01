# Flutter Performance Rules

## Widget Design

### Always Use `const` Constructors

```dart
// Good — widget is never rebuilt unnecessarily
const Text('Score', style: TextStyle(fontSize: 18));
const SizedBox(height: 16);
const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.star));
```

Enable lints in `analysis_options.yaml`:

```yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_const_declarations
```

### Extract Sub-widgets Instead of Helper Methods

Helper methods (`_buildScoreRow()`) are called inside `build()` and cause the parent to rebuild the entire subtree. Dedicated widget classes are independently diffed by Flutter.

```dart
// Bad — _buildRow() forces full parent rebuild on any setState
Widget _buildRow() => Row(children: [...]);

// Good — ScoreRow is independently const-able and never rebuilds without prop changes
class ScoreRow extends StatelessWidget {
  final int score;
  const ScoreRow({super.key, required this.score});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$score', style: Theme.of(context).textTheme.headlineMedium),
  ]);
}
```

---

## Lists

### Always Use `ListView.builder` for Dynamic Content

`Column` with `.map().toList()` builds **all** children immediately, regardless of visibility.

```dart
// Bad — builds all items at once
Column(
  children: questions.map((q) => QuestionTile(question: q)).toList(),
)

// Good — only builds visible items
ListView.builder(
  itemCount: questions.length,
  itemBuilder: (context, index) => QuestionTile(question: questions[index]),
)
```

### Add `key` to List Items

Helps Flutter track identity across rebuilds and reorders.

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, i) => ItemTile(
    key: ValueKey(items[i].id),
    item: items[i],
  ),
)
```

### Mixed Content — Use Slivers

When mixing a list with headers, banners, or grids:

```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: const HeaderBanner()),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => LeaderboardEntry(entry: entries[i]),
        childCount: entries.length,
      ),
    ),
  ],
)
```

---

## State Management

### Never Call `setState` Inside `build()`

```dart
// Bad — triggers an infinite rebuild loop
@override
Widget build(BuildContext context) {
  setState(() { _loaded = true; }); // DO NOT DO THIS
  return ...;
}

// Good — mutate state in initState, callbacks, or post-frame hooks
@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  final data = await fetchData();
  setState(() => _data = data);
}
```

### Cache Async Results — Don't Re-fetch on Rebuild

```dart
// Bad — creates a new Future on every rebuild
FutureBuilder(future: fetchLeaderboard(), ...)

// Good — fetch once, store result in state
class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    final entries = await LeaderboardService.fetchTop10(categoryKey);
    setState(() => _entries = entries);
  }
}
```

### `FutureBuilder` vs `StreamBuilder`

| Use case | Tool |
| ---------- | ------ |
| One-shot data (leaderboard fetch, profile load) | `FutureBuilder` |
| Real-time reactive data (auth state, live counters) | `StreamBuilder` |
| Auth gating | **Always** `StreamBuilder` |

Never wrap `authStateChanges` in `FutureBuilder`.

---

## Images & Assets

- Use `Image.asset` with `cacheWidth` / `cacheHeight` for flag images to reduce GPU texture memory.
- Prefer `AssetImage` inside `const` constructors where possible.
- For network images, use `cached_network_image` rather than `Image.network` to avoid re-downloading.

```dart
Image.asset(
  'assets/flags/$countryCode.png',
  cacheWidth: 128, // decoded at 128px wide — reduces GPU memory
)
```

---

## Animations

- Do not use `Opacity` widget for animated fades — it composites a new layer every frame.
- Use `AnimatedOpacity` or `FadeTransition` (uses a dedicated render object, no extra layer).
- Do not use `AnimationController` without disposing it.

```dart
// Bad
Opacity(opacity: _fadeValue, child: ...)

// Good
FadeTransition(opacity: _animation, child: ...)
```

---

## Build Modes

Test performance **only** in profile or release mode — debug mode disables most Flutter optimizations (JIT, assertion overhead, extra painting).

```bash
flutter run --profile         # accurate frame timing, DevTools accessible
flutter run --release         # closest to production
flutter build apk --release   # for final APK performance check
```

---

## Do Not

- Do not use `GlobalKey` on frequently rebuilt widgets — it forces subtree re-mounting.
- Do not create `StreamController` or `AnimationController` without disposing in `dispose()`.
- Do not use `MediaQuery.of(context)` deep in a widget tree if only a leaf needs it — pass the value down.
- Do not nest `Expanded` inside widgets that are not direct children of `Row`, `Column`, or `Flex`.
