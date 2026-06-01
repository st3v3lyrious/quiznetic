---
name: quiznetic-ui
description: 'UI/UX patterns for QuizNetic Flutter app. Use when: building or reviewing screens, widgets, cards, layouts, animations, splash screen, dark theme, typography, spacing, or any visual/interaction design. Enforces Material 3, 8px grid spacing, theme-driven colors, card-based layouts, dark mode, polished animations, mobile-first responsive layout. Avoids plain white layouts, hardcoded colors, excessive widget nesting, and default Flutter demo appearance.'
argument-hint: 'Describe the screen, component, or UI pattern to build or polish...'
---

# QuizNetic UI/UX Skill

## When to Use
- Building or reviewing any screen, card, button, or layout
- Setting up or extending the Material 3 theme (colors, typography, dark mode)
- Adding animations, transitions, or splash screen polish
- Fixing spacing inconsistencies or excessive widget nesting
- Making a screen feel premium, modern, and mobile-first

## Quick Reference

| Area | Reference |
|------|-----------|
| Theme, ColorScheme, dark mode | [theme.md](./references/theme.md) |
| Spacing, layout, cards, responsive | [layout.md](./references/layout.md) |
| Animations & transitions | [animation.md](./references/animation.md) |
| Reusable component patterns | [components.md](./references/components.md) |

---

## Design Principles

1. **Theme-driven** — every color, text style, and shape comes from `Theme.of(context)`. Zero hardcoded hex values.
2. **8px grid** — all padding, margin, and spacing is a multiple of 8 (8, 16, 24, 32, 48).
3. **Depth through cards** — surfaces use `Card` with `elevation` and `surfaceTint` for hierarchy, not flat color blocks.
4. **Dark mode first** — build with dark theme in mind; test both themes before shipping.
5. **Playful but not noisy** — one accent animation per interaction; avoid simultaneous competing motions.
6. **Mobile-first constraints** — design within 360–430dp wide; use `SafeArea`, bottom padding for gesture bar.

---

## Procedure

### 1. Check the Theme First
Before writing any color or text style, read [theme.md](./references/theme.md). Confirm the `ColorScheme` seed and typography are already set in `main.dart`. Never introduce a raw `Color(0xFF...)`.

### 2. Plan the Layout Skeleton
- What is the primary scroll axis? Use `ListView.builder` or `CustomScrollView` with Slivers.
- Are there sticky headers, banners, or FABs? Plan the `Scaffold` structure first.
- Apply the 8px grid and add `SafeArea` for edge-to-edge screens.

See [layout.md](./references/layout.md).

### 3. Build with M3 Components
Use Material 3 components — `FilledButton`, `Card`, `NavigationBar`, `Chip`, `SegmentedButton`. Never reach for M2 equivalents (`RaisedButton`, `BottomNavigationBar`, `FlatButton`).

See [components.md](./references/components.md) for card, button, and tile patterns.

### 4. Add Motion Last
Add animation after the layout is correct, not before. One micro-interaction per widget. Use `AnimatedContainer`, `Hero`, `PageRouteBuilder`, or `TweenAnimationBuilder` — not third-party animation libraries unless explicitly requested.

See [animation.md](./references/animation.md).

### 5. Validate Dark Mode
Wrap the widget in a `Theme(data: ThemeData.dark(...))` in tests or use the device system setting. Every surface, text, and icon must be legible in both themes.

---

## Validation Checklist

- [ ] All colors from `Theme.of(context).colorScheme.*` — no hardcoded hex?
- [ ] All text from `Theme.of(context).textTheme.*` — no hardcoded `TextStyle(fontSize: ...)`?
- [ ] Spacing is a multiple of 8 (`8, 16, 24, 32, 48`)?
- [ ] Lists use `ListView.builder`, not `Column` with `.map().toList()`?
- [ ] No widget nesting deeper than ~4 levels without extracting a named widget class?
- [ ] `SafeArea` applied on screens that own the `Scaffold`?
- [ ] Dark mode visually correct (tested manually or via `ThemeData.dark`)?
- [ ] Animations use `const` durations and don't conflict with other motion on screen?
- [ ] Only M3 component APIs used (`FilledButton`, `Card`, `NavigationBar`, etc.)?
