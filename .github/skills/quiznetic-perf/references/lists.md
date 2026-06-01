# Lists, `ListView.builder` & Lazy Loading

## Why `Column` + `.map().toList()` Is a Performance Problem

**Rendering implication:** `Column` is a single render object that lays out **all** its children at once, regardless of whether they are visible on screen. With 50 answer history tiles or a leaderboard of 100 entries:

1. Flutter calls `build()` on every item immediately.
2. Flutter lays out every item — even items 200px below the viewport.
3. All item render objects live in memory for the lifetime of the `Column`.
4. Scrolling requires all items to have been measured first → slower first frame.

```dart
// Bad — 50 items all built immediately, full layout cost upfront
SingleChildScrollView(
  child: Column(
    children: leaderboard.map((e) => LeaderboardRow(entry: e)).toList(),
  ),
)
```

---

## `ListView.builder` — The Correct Pattern

**Why it's fast:** `ListView.builder` maintains a "realization window" — only the visible items plus a small configurable buffer (`cacheExtent`) are built and laid out. Items outside the window are discarded and rebuilt on demand.

```dart
// Good — only visible items are built; O(visible) not O(total)
ListView.builder(
  itemCount: leaderboard.length,
  itemBuilder: (context, index) {
    final entry = leaderboard[index];
    return LeaderboardRow(key: ValueKey(entry.uid), entry: entry);
  },
)
```

### Required Properties

- `itemCount`: Always provide it. Without it, Flutter cannot determine scroll extent, causing layout issues and unnecessary renders.
- `key` on items: Allows Flutter to preserve item state across scrolls (see [rebuilds.md](./rebuilds.md)).

### `itemBuilder` Must Be Cheap

`itemBuilder` is called every time an item enters the viewport — including during fast flings. It must return instantly.

```dart
// Bad — parses JSON inside itemBuilder (called on every scroll frame)
itemBuilder: (context, i) {
  final data = jsonDecode(rawItems[i]); // DO NOT DO THIS
  return ItemTile(title: data['title']);
}

// Good — items are pre-parsed; builder is instant
itemBuilder: (context, i) => ItemTile(
  key: ValueKey(items[i].id),
  title: items[i].title,
)
```

---

## `cacheExtent` — Tuning the Realization Window

`cacheExtent` controls how many logical pixels **beyond** the viewport are pre-built. Default is `250.0`.

```dart
ListView.builder(
  cacheExtent: 500, // pre-build items 500px above and below the viewport
  itemCount: items.length,
  itemBuilder: (_, i) => ItemTile(item: items[i]),
)
```

- **Increase** `cacheExtent` for slower-scrolling content where pre-building reduces jank.
- **Decrease** if memory is constrained and items are expensive to build.

---

## Slivers — Mixing List Types

Use `CustomScrollView` + Slivers when a screen combines a list with headers, banners, grids, or pinned elements.

```dart
CustomScrollView(
  slivers: [
    // Pinned header — stays visible while list scrolls
    SliverAppBar(
      pinned: true,
      title: const Text('Leaderboard'),
    ),

    // Static content above the list
    const SliverToBoxAdapter(
      child: CategoryBanner(),
    ),

    // The lazy list
    SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) => LeaderboardRow(
        key: ValueKey(entries[i].uid),
        entry: entries[i],
      ),
    ),
  ],
)
```

**Why not `Column` + `ListView` inside `SingleChildScrollView`?**
Nesting a `ListView` inside `SingleChildScrollView` forces `ListView` to lay out all items to calculate its own height — destroying lazy loading. Use Slivers instead.

---

## Lazy Loading — Pagination from Firestore

For leaderboards with many entries, load in pages rather than fetching all at once.

```dart
class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final List<LeaderboardEntry> _entries = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    var query = FirebaseFirestore.instance
        .collection('leaderboard')
        .doc(widget.categoryKey)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();
    final newEntries = snap.docs.map(LeaderboardEntry.fromFirestore).toList();

    setState(() {
      _entries.addAll(newEntries);
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _entries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Trigger next page load when near the end
        if (index == _entries.length - 5) {
          _loadNextPage();
        }

        // Show a loading indicator at the bottom
        if (index == _entries.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return LeaderboardRow(
          key: ValueKey(_entries[index].uid),
          entry: _entries[index],
          rank: index + 1,
        );
      },
    );
  }
}
```

---

## Image Assets in Lists — Memory Optimization

Flag images decoded at full resolution cost GPU memory proportional to their pixel dimensions, regardless of display size.

```dart
// Bad — decodes the full PNG (e.g. 1024×512) into GPU memory
Image.asset('assets/flags/$code.png')

// Good — Flutter decodes at the display size, reducing GPU texture memory
Image.asset(
  'assets/flags/$code.png',
  cacheWidth: 96,   // display width in logical pixels × device pixel ratio
  cacheHeight: 64,
  fit: BoxFit.contain,
)
```

For list items that appear many times, this alone can reduce GPU memory by 10–50×.

---

## `separatorBuilder` — Avoid Wrapping Every Item in Padding

```dart
// Inefficient — Padding widget added to every item
ListView.builder(
  itemBuilder: (_, i) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ItemTile(item: items[i]),
  ),
)

// Better — separator is a separate, const, cheap widget
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (_, __) => const SizedBox(height: 12),
  itemBuilder: (_, i) => ItemTile(item: items[i]),
)
```

---

## Anti-Patterns Summary

| Pattern | Problem | Fix |
| --------- | --------- | ----- |
| `Column` + `items.map().toList()` | Builds all items upfront | `ListView.builder` |
| `ListView` inside `SingleChildScrollView` | Forces full layout | `CustomScrollView` + `SliverList` |
| `itemBuilder` with JSON parsing | Heavy per-frame CPU | Pre-parse data in `initState` |
| No `itemCount` on `ListView.builder` | Infinite scroll, layout errors | Always provide `itemCount` |
| `Image.asset` with no cache params in lists | High GPU memory | Add `cacheWidth`/`cacheHeight` |
| Missing `key` on list items | State lost on scroll | `ValueKey(item.id)` |
| Fetching all pages at once | Memory spike, slow query | Paginate with `startAfterDocument` |
