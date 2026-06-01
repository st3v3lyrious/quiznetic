# Animations & Transitions

## Philosophy

- One micro-interaction per user action. Do not layer multiple simultaneous animations.
- Animations communicate state, not decorate boredom.
- Default to Flutter's built-in animation widgets before writing custom `AnimationController`.
- All durations are `const`. Standard values: `150ms` (instant feedback), `250ms` (state change), `400ms` (enter/exit), `600ms` (hero/dramatic).

---

## Preferred Animation Widgets (No Controller Needed)

### `AnimatedContainer` — State-driven style changes

Use for answer selection feedback, highlighting, color shifts.

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    color: isSelected
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(16),
  ),
  padding: const EdgeInsets.all(16),
  child: ...,
)
```

### `AnimatedOpacity` — Fade in/out

```dart
AnimatedOpacity(
  opacity: _isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: ...,
)
```

### `TweenAnimationBuilder` — One-shot value animations

Use for score counters, progress bars, reveal effects.

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: progress),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOut,
  builder: (context, value, _) => LinearProgressIndicator(value: value),
)
```

### `AnimatedSwitcher` — Crossfade between widget states

Use when swapping content (question text, result vs. loading).

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  child: _isLoading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : ResultCard(key: ValueKey('result'), score: _score),
)
```

### `AnimatedScale` — Bounce feedback on tap

```dart
AnimatedScale(
  scale: _isPressed ? 0.95 : 1.0,
  duration: const Duration(milliseconds: 100),
  curve: Curves.easeInOut,
  child: ...,
)
```

---

## `AnimationController` — When to Use

Use `AnimationController` only when:

- The animation loops (countdown pulse, loading spinner)
- The animation has multiple stages that depend on each other
- You need fine-grained playback control (forward, reverse, repeat)

```dart
class _QuizTimerState extends State<QuizTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // always dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LinearProgressIndicator(
        value: 1 - _controller.value,
        color: Theme.of(context).colorScheme.error,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }
}
```

---

## Page Transitions

Use `PageRouteBuilder` for custom screen transitions. Keep them fast and directional.

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const ResultScreen(),
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  ),
);
```

---

## Hero Transitions

Use `Hero` for shared elements between screens (flag image, score badge).

```dart
// On source screen
Hero(
  tag: 'flag-${question.countryCode}',
  child: Image.asset('assets/flags/${question.countryCode}.png', width: 80),
)

// On destination screen (same tag)
Hero(
  tag: 'flag-${question.countryCode}',
  child: Image.asset('assets/flags/${question.countryCode}.png', width: 160),
)
```

Rules:

- The `tag` must be globally unique at any moment — include an ID.
- The widget type and shape should match between source and destination for a smooth morph.

---

## Splash Screen Polish

The native splash screen (configured via `flutter_native_splash`) shows before Flutter renders. The Flutter-side `SplashScreen` widget should animate in gracefully:

```dart
class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo / wordmark
              Image.asset('assets/images/logo.png', width: 120),
              const SizedBox(height: 24),
              Text(
                'QuizNetic',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Score Counter — Animated Number Roll

```dart
TweenAnimationBuilder<int>(
  tween: IntTween(begin: 0, end: finalScore),
  duration: const Duration(milliseconds: 800),
  curve: Curves.easeOut,
  builder: (context, value, _) {
    return Text(
      '$value',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  },
)
```

---

## What NOT to Do

- Do not use `Opacity` widget for animated fades — use `AnimatedOpacity` or `FadeTransition`.
- Do not run multiple `AnimationController`s simultaneously on the same widget unless orchestrated.
- Do not use `Future.delayed` to trigger UI state — use `addStatusListener` on the animation.
- Do not animate `MediaQuery`-dependent values — they can cause infinite rebuild loops.
- Do not forget `dispose()` on every `AnimationController` — it leaks resources.
- Do not use `flutter_animate` or other animation packages unless the user explicitly requests it.
