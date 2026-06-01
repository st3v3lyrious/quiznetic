# Widget Rebuilds, `const`, & Widget Extraction

## Why Rebuilds Happen

Flutter calls `build()` on a widget every time `setState` is called on it **or any ancestor**. The framework then walks the element tree downward, diffing the new widget tree against the old one. Widgets that survive the diff (same type, same key) are reused — but their `build()` was still called.

**Consequence:** One `setState` at the `Scaffold` level can trigger `build()` on every widget on screen, even ones whose data hasn't changed.

---

## `const` Widgets — The Cheapest Optimization

Marking a widget `const` tells Flutter it will never change. The framework **skips diffing it entirely** and reuses the exact same element. No `build()` call. No render object update.

```dart
// Flutter calls build() on this every parent rebuild:
Text('Score', style: TextStyle(fontSize: 18))

// Flutter skips this completely — zero cost on parent rebuild:
const Text('Score', style: TextStyle(fontSize: 18))
```

### Rules

- Every widget whose constructor arguments are compile-time constants must be `const`.
- Enable the lint: `prefer_const_constructors` in `analysis_options.yaml`.
- `const` propagates — if a child is `const`, the parent can be `const` too.

```dart
// Good — entire subtree is frozen
const Padding(
  padding: EdgeInsets.all(16),
  child: Icon(Icons.star, color: Colors.amber),
)

// Bad — missing const; Icon is rebuilt on every parent setState
Padding(
  padding: const EdgeInsets.all(16),
  child: Icon(Icons.star, color: Colors.amber), // not const — rebuilt needlessly
)
```

---

## Push State Down — Smallest Possible Scope

**Why it matters:** Every `setState` rebuilds the widget that called it and all its descendants. The smaller that widget, the less Flutter has to rebuild.

```dart
// Bad — CounterState owns the entire screen; every tick rebuilds everything
class _QuizScreenState extends State<QuizScreen> {
  int _secondsLeft = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // This entire Column rebuilds every second:
        const QuestionCard(...),
        const AnswerGrid(...),
        Text('$_secondsLeft s'),   // only this needs to change
      ]),
    );
  }
}
```

```dart
// Good — TimerWidget owns its own state; QuizScreen never rebuilds for ticks
class QuizScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const QuestionCard(...),   // never rebuilt
        const AnswerGrid(...),     // never rebuilt
        const TimerWidget(),       // rebuilds only itself
      ]),
    );
  }
}

class _TimerWidgetState extends State<TimerWidget> with SingleTickerProviderStateMixin {
  // ... owns the countdown, calls setState only here
}
```

---

## Extract Widgets — Don't Use Helper Methods

Helper methods like `_buildRow()` are inlined into the parent's `build()` and cause the parent to rebuild the entire result. Named widget classes are independently diffed.

```dart
// Bad — _buildScoreRow() is called inside the parent build(),
// so the parent rebuilds fully whenever any state changes.
Widget _buildScoreRow() {
  return Row(children: [Text('$_score pts')]);
}
```

```dart
// Good — ScoreRow is an independent element in the tree.
// Flutter only rebuilds it if its props change.
class ScoreRow extends StatelessWidget {
  final int score;
  const ScoreRow({super.key, required this.score});

  @override
  Widget build(BuildContext context) => Row(children: [Text('$score pts')]);
}
```

### Extraction Heuristic

Extract into a named widget class whenever:

- The subtree has more than ~5 widgets
- The subtree contains data that doesn't change when the parent's state changes
- The same pattern appears in more than one place

---

## `RepaintBoundary` — Isolate GPU Repaint Regions

**Why it matters:** When a widget repaints (e.g., an animated timer), Flutter repaints the entire layer it belongs to. `RepaintBoundary` promotes a subtree to its own compositing layer, so only that layer is repainted on GPU — not the rest of the screen.

```dart
// The animated timer repaints 60×/sec. Without a boundary,
// the entire quiz screen layer repaints with it.
RepaintBoundary(
  child: QuizTimerWidget(),
)
```

**When to use:**

- Looping animations (countdown timers, spinners)
- Frequently updating widgets (live score counters)
- Large, expensive subtrees that are stable while a child animates

**When NOT to use:**

- On every widget — each boundary adds a compositing layer with GPU memory cost
- On small, cheap, non-animating widgets

---

## `ValueKey` and `GlobalKey` — Rebuild Identity

Flutter uses keys to match old and new widgets during reconciliation.

- **`ValueKey`**: Use on list items to preserve state across reorders. Low cost.
- **`ObjectKey`**: Use when the item object itself is the identity.
- **`GlobalKey`**: Preserves widget state across tree positions. **High cost** — forces a subtree remount. Avoid on frequently rebuilt widgets.

```dart
// Good — Flutter preserves QuestionTile state across scroll
ListView.builder(
  itemBuilder: (context, i) => QuestionTile(
    key: ValueKey(questions[i].id),
    question: questions[i],
  ),
)

// Bad — GlobalKey on a list item; remounts the widget every rebuild
ListView.builder(
  itemBuilder: (context, i) => QuestionTile(key: GlobalKey(), ...)
)
```

---

## Avoid Expensive Operations in `build()`

`build()` is called multiple times per second during animations or rapid state changes. It must return instantly.

| Operation | Problem | Fix |
| ----------- | --------- | ----- |
| `jsonDecode(data)` | CPU-heavy | Parse in `initState`, cache result |
| `RegExp(pattern)` | Allocates object | Make it a `static final` field |
| `List.generate(1000, ...)` | Allocates large list | Use `ListView.builder` |
| `DateTime.now()` | Fine once; bad in hot paths | Cache if used for display only |
| `Image.asset(...)` with no cache params | Decodes full image each build | Add `cacheWidth`/`cacheHeight` |
| `fetchFromFirestore()` | Starts a network request | Cache in state; never call in `build()` |

```dart
// Bad
@override
Widget build(BuildContext context) {
  final data = jsonDecode(widget.rawJson); // heavy, every build
  return Text(data['title']);
}

// Good
late final Map<String, dynamic> _data;

@override
void initState() {
  super.initState();
  _data = jsonDecode(widget.rawJson); // once
}

@override
Widget build(BuildContext context) => Text(_data['title']); // instant
```

---

## `shouldRebuild` — Inherited Widgets

If you introduce an `InheritedWidget`, implement `updateShouldNotify` precisely:

```dart
@override
bool updateShouldNotify(MyInherited oldWidget) =>
    oldWidget.score != score; // only notify if score actually changed
```

Returning `true` unconditionally causes every dependent widget to rebuild on every ancestor `setState`.
