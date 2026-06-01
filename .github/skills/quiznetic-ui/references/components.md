# Reusable Component Patterns

## Buttons

### Primary CTA — `FilledButton`

```dart
FilledButton(
  onPressed: _onStart,
  style: FilledButton.styleFrom(
    minimumSize: const Size(double.infinity, 56), // full-width, tall touch target
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  child: Text(
    'Start Quiz',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onPrimary,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### Secondary Action — `OutlinedButton`

```dart
OutlinedButton(
  onPressed: _onViewLeaderboard,
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    side: BorderSide(color: Theme.of(context).colorScheme.outline),
  ),
  child: const Text('View Leaderboard'),
)
```

### Icon Action — `IconButton` (M3 filled variant)

```dart
IconButton.filled(
  onPressed: _onSettings,
  icon: const Icon(Icons.settings_outlined),
  tooltip: 'Settings',
)
```

### Rules

- Minimum touch target: **48×48dp** (M3 requirement; `minimumSize: Size(48, 48)`)
- Full-width buttons: `minimumSize: Size(double.infinity, 56)`
- Never use `ElevatedButton` (M2), `RaisedButton` (deprecated), or `FlatButton` (deprecated)

---

## App Bar

Prefer a custom header over `AppBar` on immersive screens (quiz, splash, result).

```dart
// Custom header for quiz screen
class _QuizHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback onClose;

  const _QuizHeader({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: currentQuestion / totalQuestions),
            duration: const Duration(milliseconds: 400),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$currentQuestion/$totalQuestions',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
```

For screens with an `AppBar`:

```dart
AppBar(
  title: Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
  centerTitle: false, // M3 default: left-aligned
  scrolledUnderElevation: 2, // shows elevation when content scrolls under
  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
)
```

---

## Score / Stat Badge

```dart
class StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const StatBadge({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                )),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                )),
          ],
        ),
      ),
    );
  }
}
```

Usage (3-stat row):

```dart
Row(
  children: [
    Expanded(child: StatBadge(value: '$score', label: 'Score', icon: Icons.star_rounded)),
    const SizedBox(width: 8),
    Expanded(child: StatBadge(value: '$correct', label: 'Correct', icon: Icons.check_circle_rounded)),
    const SizedBox(width: 8),
    Expanded(child: StatBadge(value: '$streak', label: 'Streak', icon: Icons.bolt_rounded)),
  ],
)
```

---

## Category / Mode Selection Card

```dart
class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias, // required for InkWell ripple to respect card radius
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? cs.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? cs.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Empty State

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Loading States

Prefer skeleton shimmer (manual) or `CircularProgressIndicator` centered in the content area — never block the full screen with a loading overlay.

```dart
// Centered inline loader
if (_isLoading)
  const Center(
    child: Padding(
      padding: EdgeInsets.all(48),
      child: CircularProgressIndicator(),
    ),
  )
else
  // actual content
```

For `LinearProgressIndicator` on quiz timer, see [animation.md](./animation.md).

---

## Snackbars & Feedback

```dart
// Success
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Score saved!'),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: Theme.of(context).colorScheme.inverseSurface,
  ),
);

// Error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Theme.of(context).colorScheme.error,
  ),
);
```

---

## What NOT to Do

- Do not use `RaisedButton`, `FlatButton`, `ElevatedButton` (M2) — use M3 variants only.
- Do not use `Colors.blue` or any named color — use `colorScheme.*`.
- Do not use raw `Container(decoration: BoxDecoration(color: ...))` as a card — use `Card`.
- Do not place `InkWell` inside a `Card` without `clipBehavior: Clip.antiAlias` — the ripple escapes the border radius.
- Do not use `withOpacity()` — it is deprecated; use `withValues(alpha: 0.5)`.
- Do not use `showDialog` for destructive actions without a `title` and explicit confirm/cancel buttons.
