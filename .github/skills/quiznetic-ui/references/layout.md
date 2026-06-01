# Spacing, Layout & Cards

## The 8px Grid

All padding, margin, gap, and sizing values must be multiples of 8.

| Value | Use |
| ------- | ----- |
| `4` | Internal chip padding, icon gap (exception) |
| `8` | Tight internal padding, icon-to-label gap |
| `12` | Compact list item padding |
| `16` | Standard screen edge padding, card inner padding |
| `24` | Section gap, large card padding |
| `32` | Between major sections |
| `48` | Hero/splash top padding, generous vertical rhythm |

```dart
// Good
const EdgeInsets.all(16)
const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
const SizedBox(height: 24)

// Bad
const EdgeInsets.all(15)
const SizedBox(height: 7)
```

---

## Screen Layout Template

Every screen that owns a `Scaffold` follows this structure:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // appBar optional — prefer custom headers in quiz screens
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                const _ScreenHeader(),
                const SizedBox(height: 16),
                // ... content
              ]),
            ),
          ),
        ],
      ),
    ),
    // FAB or bottom action if needed
    floatingActionButton: ...,
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );
}
```

Key rules:

- `SafeArea` wraps the full body — not individual sections.
- `CustomScrollView` with `SliverPadding` scales better than wrapping `Column` in `SingleChildScrollView`.
- Add `bottom: false` to `SafeArea` when the `Scaffold` has a `BottomNavigationBar` (it handles its own inset).

---

## Horizontal Screen Padding

Apply `16` on both sides consistently. Never mix `12`, `15`, and `20` on the same screen.

```dart
// Good — applied once at the sliver level
SliverPadding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  sliver: ...,
)

// Bad — mixed padding producing visual jitter
Padding(padding: const EdgeInsets.only(left: 12), child: ...)
Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ...)
```

---

## Card-Based Layouts

Cards are the primary surface unit for quiz questions, answers, leaderboard rows, and score displays.

### Question Card

```dart
Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question 1 of 10',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.text,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    ),
  ),
)
```

### Answer Option Tile

```dart
class AnswerTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrect; // null until answered
  final VoidCallback onTap;

  const AnswerTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? (isCorrect ? cs.primaryContainer : cs.errorContainer)
        : cs.surfaceContainerHighest;
    final textColor = isSelected
        ? (isCorrect ? cs.onPrimaryContainer : cs.onErrorContainer)
        : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor)),
        ),
      ),
    );
  }
}
```

### Leaderboard Row

```dart
Card(
  elevation: 0,
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text('$rank', style: Theme.of(context).textTheme.labelLarge),
    ),
    title: Text(displayName, style: Theme.of(context).textTheme.titleMedium),
    trailing: Text(
      '$score pts',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
)
```

---

## Responsive Layout

QuizNetic targets mobile-first (360–430dp). Use `LayoutBuilder` only when layout genuinely differs across widths.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isWide = constraints.maxWidth > 600;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16),
      child: ...,
    );
  },
)
```

For font scaling respect: wrap the root in `MediaQuery` with `textScaler` clamped if needed:

```dart
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: MediaQuery.of(context).textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
    ),
  ),
  child: child,
)
```

---

## Depth Hierarchy — When to Use Which Surface

| Layer | Surface | Elevation |
| ------- | --------- | ----------- |
| Background | `Scaffold` background | 0 |
| Primary content card | `Card` | 1–2 |
| Raised interactive card | `Card` | 3–4 |
| Modal / bottom sheet | `BottomSheet` | 6+ |
| Snackbar | `SnackBar` (auto) | — |

---

## What NOT to Do

- Do not use `Column` + `.map().toList()` for lists of variable length — always `ListView.builder`.
- Do not nest `Column` inside `Column` more than 2 levels without extracting a widget.
- Do not use `Container` with only a `color` — use `ColoredBox` (faster) or `Card`.
- Do not use `SizedBox(width: double.infinity)` to stretch — use `double.infinity` on `width` in `Container`, or `Expanded`/`CrossAxisAlignment.stretch`.
- Do not mix `mainAxisAlignment: center` and `Spacer()` — pick one layout strategy.
