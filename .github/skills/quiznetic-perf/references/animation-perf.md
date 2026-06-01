# Animation Performance & GPU Layers

## How Flutter Renders Animations

Flutter's rendering pipeline has two key phases:

1. **Build** — Dart code runs; widget tree → element tree → render tree.
2. **Paint** — Render tree paints to layers; layers are composited by the GPU (Skia/Impeller).

Most performance problems come from either:

- **Expensive build** — `build()` or `setState` called too frequently or too high in the tree.
- **GPU overdraw** — too many compositing layers or repainting a large area for a small visual change.

---

## `Opacity` Widget — The Most Common Animation Mistake

**Why it's a problem:** `Opacity` applies alpha to its **entire compositing layer**. To do this, it creates a new offscreen GPU layer, renders the child into it, then composites it with the given opacity. This happens on **every frame** of an animation.

For a 60fps fade, that's 60 new GPU compositing operations per second — even if the child is completely static.

```dart
// Bad — creates a new GPU layer every frame
Opacity(
  opacity: _animValue,       // changes every frame
  child: const HeavyWidget(), // static, but repainted every frame anyway
)
```

**Fix: `FadeTransition`**

`FadeTransition` uses the same alpha compositing mechanism but is **optimized by Flutter's animation system** — it skips the build phase during animation and goes directly to the compositing step.

```dart
// Good — bypasses build() entirely during the fade; uses AnimationController
FadeTransition(
  opacity: _fadeAnimation, // CurvedAnimation driven by AnimationController
  child: const HeavyWidget(), // build() is NOT called on each frame
)
```

**For state-driven fades (not animation-controller-driven):**

```dart
// Good for toggling visibility based on state
AnimatedOpacity(
  opacity: _isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOut,
  child: const SomeWidget(),
)
```

---

## `setState` During Animations — What to Avoid

Calling `setState` from an `AnimationController` listener causes `build()` to run on every frame, defeating the purpose of the animation optimization:

```dart
// Bad — build() called 60×/sec
_controller.addListener(() {
  setState(() {}); // forces full rebuild every animation frame
});

// Good — AnimatedBuilder only rebuilds its child subtree
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child, // child is built ONCE and reused
    );
  },
  child: const ExpensiveChildWidget(), // not rebuilt on each frame
)
```

**Key:** Pass static children as the `child` argument to `AnimatedBuilder`. They are built once and passed into the builder as a pre-built widget — not re-evaluated on every frame.

---

## `RepaintBoundary` for Animations

An animation that repaints a widget will, by default, repaint **the entire layer** that widget belongs to. Promote a frequently-repainting widget to its own layer with `RepaintBoundary`:

```dart
// Without boundary: entire screen layer repaints on every timer tick
Column(children: [
  const QuestionCard(),      // repainted unnecessarily
  const AnswerGrid(),        // repainted unnecessarily
  QuizTimerWidget(),         // the only thing that actually changes
])

// With boundary: only QuizTimerWidget's layer is repainted
Column(children: [
  const QuestionCard(),
  const AnswerGrid(),
  RepaintBoundary(
    child: QuizTimerWidget(), // isolated to its own GPU layer
  ),
])
```

**GPU cost of `RepaintBoundary`:** Each boundary allocates an offscreen texture in GPU memory. Don't add them everywhere — use only for widgets that repaint frequently while their siblings are stable.

---

## `Transform` — GPU-Only Operations

`Transform.translate`, `Transform.scale`, and `Transform.rotate` apply a matrix transform at the compositing layer — **no repaint required**. They are the cheapest way to move/scale/rotate a widget during animation.

```dart
// Very efficient — GPU matrix math only, no Dart or paint work
AnimatedBuilder(
  animation: _slideAnimation,
  builder: (context, child) => Transform.translate(
    offset: Offset(0, _slideAnimation.value),
    child: child,
  ),
  child: const CardWidget(),
)
```

Compare to `AnimatedPositioned` in a `Stack` — it triggers a layout pass on every frame, which is significantly more expensive.

---

## Choosing the Right Animation Widget

| Situation | Widget | Why |
| ----------- | -------- | ----- |
| Fade in/out with a controller | `FadeTransition` | Skips build phase; GPU-only alpha |
| Fade based on bool state | `AnimatedOpacity` | Manages controller internally |
| Slide entry/exit | `SlideTransition` | GPU matrix; no layout pass |
| Crossfade between two states | `AnimatedSwitcher` | Clean state-based swapping |
| Scale on tap feedback | `AnimatedScale` | State-driven, no controller needed |
| Color/size/border changes | `AnimatedContainer` | Lerps layout properties smoothly |
| Shared element between screens | `Hero` | Flutter handles compositing automatically |
| Complex multi-stage animation | `AnimationController` + `AnimatedBuilder` | Full control; pass static `child` |

---

## `AnimationController` Lifecycle — Memory Leaks

Every `AnimationController` holds a `Ticker` which runs on the Flutter scheduler. Forgetting to dispose it keeps the ticker alive after the widget is removed, consuming CPU every frame indefinitely.

```dart
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // ties the ticker to this widget's lifecycle
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ← mandatory; stops the ticker
    super.dispose();
  }
}
```

Multiple controllers: use `TickerProviderStateMixin` (not `Single...`).

---

## Page Transition Performance

Custom `PageRouteBuilder` transitions should:

- Use `SlideTransition` or `FadeTransition` (GPU layer operations)
- Keep `transitionDuration` under 400ms (longer feels sluggish on mobile)
- Not trigger Firestore fetches during the transition animation

```dart
// Efficient — slide + fade using transform and opacity (no layout pass)
PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, __, ___) => const ResultScreen(),
  transitionsBuilder: (_, animation, __, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(opacity: animation, child: child),
    );
  },
)
```

---

## Profiling Animations

In **profile mode**, open Flutter DevTools → **Performance** tab:

- Enable **"Track widget builds"** to see which widgets are rebuilt per frame.
- Enable **"Show checkerboard raster cache images"** to identify cached vs. uncached layers.
- Enable **"Show checkerboard offscreen layers"** to visualize every `RepaintBoundary` and composited layer.

```bash
flutter run --profile
# Then open the DevTools URL printed in the terminal
```

Target: **16ms per frame** (60fps). Frames over 16ms will be flagged in the timeline.

---

## Anti-Patterns Summary

| Pattern | GPU/CPU Problem | Fix |
| --------- | ---------------- | ----- |
| `Opacity` widget for animated fades | Offscreen GPU layer every frame | `FadeTransition` or `AnimatedOpacity` |
| `setState` in `AnimationController.addListener` | `build()` called 60×/sec | `AnimatedBuilder` with static `child` |
| `AnimationController` without `dispose()` | Ticker leak; CPU usage after widget removed | Always `dispose()` in `dispose()` |
| `AnimatedPositioned` for sliding | Layout pass every frame | `SlideTransition` (transform only) |
| No `RepaintBoundary` around looping animation | Entire screen layer repaints | Wrap with `RepaintBoundary` |
| Starting Firestore fetch during page transition | Network + animation contend for resources | Fetch after `transitionDuration` completes |
