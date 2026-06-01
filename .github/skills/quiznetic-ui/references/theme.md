# Theme, ColorScheme & Dark Mode

## Theme Setup in `main.dart`

The entire visual identity is driven by a single `ColorScheme.fromSeed`. Define it once — never create local `ThemeData` in screens.

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // replace with brand color
      brightness: Brightness.light,
    ),
    // Custom text theme (see Typography section below)
    textTheme: _buildTextTheme(),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(),
  ),
  themeMode: ThemeMode.system, // respects device setting
  ...
)
```

---

## ColorScheme Roles — Use These, Never Hex

| Token | Use for |
| ------- | --------- |
| `colorScheme.primary` | Primary actions, active icons, key CTAs |
| `colorScheme.onPrimary` | Text/icons on primary-colored surfaces |
| `colorScheme.secondary` | Accent chips, secondary buttons |
| `colorScheme.surface` | Card backgrounds, bottom sheets |
| `colorScheme.onSurface` | Body text on cards |
| `colorScheme.surfaceContainerHighest` | Elevated card background (M3 tonal) |
| `colorScheme.error` / `onError` | Error states, destructive actions |
| `colorScheme.outline` | Dividers, borders, inactive strokes |
| `colorScheme.inverseSurface` | Snackbar, tooltip backgrounds |
| `colorScheme.primaryContainer` | Tonal highlight backgrounds |
| `colorScheme.onPrimaryContainer` | Text on tonal highlight |

```dart
// Good
color: Theme.of(context).colorScheme.primary,

// Bad — breaks dark mode, breaks theme changes
color: const Color(0xFF6750A4),
```

---

## Typography

Define text styles through `TextTheme`. Scale: `displayLarge` → `bodySmall`.

```dart
TextTheme _buildTextTheme() {
  return const TextTheme(
    // Quiz question text
    headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    // Score numbers, counters
    displaySmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0),
    // Card titles, screen headers
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
    // Body copy, answer options
    bodyLarge: TextStyle(fontWeight: FontWeight.w400, height: 1.5),
    // Labels, badges, chips
    labelMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}
```

Usage in widgets:

```dart
// Good
Text('Score', style: Theme.of(context).textTheme.headlineMedium)

// Bad — hardcoded, breaks dark mode, not scalable
Text('Score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))
```

---

## Dark Mode

### Rules

- Never use `Colors.white` or `Colors.black` directly — use `colorScheme.surface` and `colorScheme.onSurface`.
- Never use `Colors.grey` — use `colorScheme.outline` or `colorScheme.onSurfaceVariant`.
- Elevation in dark mode is expressed with `surfaceTint` (automatic in M3 `Card`), not a lighter grey.

### Testing Dark Mode

```dart
// In a widget test or during development, wrap with:
Theme(
  data: Theme.of(context).copyWith(
    brightness: Brightness.dark,
  ),
  child: const YourWidget(),
)
```

Or toggle system setting on the simulator: **Settings → Display & Brightness → Dark**.

---

## Surface Elevation & Tonal Layers (M3)

M3 uses tonal surface overlays instead of shadow-only elevation. `Card` handles this automatically.

```dart
// Elevated card — M3 applies surfaceTint automatically
Card(
  elevation: 2,
  child: ...,
)

// Filled card (no shadow, tonal fill)
Card(
  elevation: 0,
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  child: ...,
)

// Outlined card
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Theme.of(context).colorScheme.outline),
  ),
  child: ...,
)
```

---

## Shape

Use consistent border radii via the theme's `ShapeBorder`. Prefer:

- **Cards / containers**: `BorderRadius.circular(16)` (M3 medium)
- **Chips / badges**: `BorderRadius.circular(8)` (M3 small)
- **Bottom sheets / modals**: `BorderRadius.vertical(top: Radius.circular(28))` (M3 large)
- **Buttons**: handled automatically by M3 `FilledButton` / `OutlinedButton`

```dart
// Set globally in theme to avoid per-widget overrides
cardTheme: const CardTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
),
```
