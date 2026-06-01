---
name: quiznetic-perf
description: 'Flutter performance optimization for QuizNetic. Use when: diagnosing slow scrolling, jank, excessive rebuilds, expensive build methods, memory issues, lazy loading problems, Firebase query inefficiency, animation frame drops, or any performance concern. Explains WHY each issue exists, the rendering implication, and the correct fix. Prioritizes maintainable production-ready Flutter code.'
argument-hint: 'Describe the performance symptom or the code to optimize...'
---

# QuizNetic Flutter Performance Skill

## When to Use
- Diagnosing jank, dropped frames, or slow scrolling
- Reviewing code for unnecessary widget rebuilds
- Optimizing a `ListView` or scroll view
- Reducing Firebase read frequency or query cost
- Fixing animation lag or GPU overdraw
- Auditing `build()` methods for expensive operations
- Extracting widgets to isolate rebuild scope

## Quick Reference

| Area | Reference |
|------|-----------|
| Widget rebuilds, `const`, extraction, `RepaintBoundary` | [rebuilds.md](./references/rebuilds.md) |
| `ListView.builder`, lazy loading, keys, slivers | [lists.md](./references/lists.md) |
| Firebase query efficiency & caching | [firebase-queries.md](./references/firebase-queries.md) |
| Animation performance & GPU layers | [animation-perf.md](./references/animation-perf.md) |

---

## Diagnostic Procedure

### 1. Identify the Symptom
Before optimizing, name the problem precisely:

| Symptom | Likely cause |
|---------|-------------|
| Jank on scroll | `Column` + full item build; expensive `itemBuilder` |
| Full screen flicker on data load | `setState` too high in the tree |
| Firebase reads on every rebuild | `FutureBuilder(future: fetch())` with no cache |
| Animation stutter | `Opacity` widget; `setState` inside animation loop |
| High memory on flag screens | Uncached full-res images; no `cacheWidth` |
| Slow `initState` → blank frame | Awaiting Firestore in `initState` without skeleton UI |

### 2. Check Rebuild Scope
The most common Flutter performance mistake is calling `setState` too high in the tree. Ask:
- Which widget owns the state that changes?
- How many widgets are rebuilt as a result?
- Can the state be pushed down to the smallest widget that needs it?

See [rebuilds.md](./references/rebuilds.md).

### 3. Audit the `build()` Method
`build()` must be **pure and cheap**. It can be called many times per second. Anything that is not widget construction does not belong here:
- No `async` / `await`
- No `List.generate` on large collections
- No `jsonDecode`, `RegExp`, or string parsing
- No direct Firestore / HTTP calls

### 4. Optimize Lists
If the screen scrolls, verify `ListView.builder` is used and `itemBuilder` is fast.

See [lists.md](./references/lists.md).

### 5. Verify Firebase Efficiency
- Is `FutureBuilder(future: fetchX())` creating a new Future on every rebuild?
- Is `.snapshots()` subscribed when a one-time `.get()` would suffice?
- Does every query have a `.limit()`?

See [firebase-queries.md](./references/firebase-queries.md).

### 6. Profile in the Right Mode
**Always profile in profile or release mode.** Debug mode is ~5–10× slower due to JIT and assertion overhead.

```bash
flutter run --profile   # connect DevTools for frame timeline
flutter run --release   # closest to production
```

Use Flutter DevTools → **Performance** tab → enable "Track widget builds" to find hot rebuild paths.

---

## Validation Checklist

- [ ] All static widgets use `const` constructors?
- [ ] State-changing `setState` is called at the lowest possible widget in the tree?
- [ ] Dynamic lists use `ListView.builder` (not `Column` + `.map().toList()`)?
- [ ] `itemBuilder` creates no expensive objects (no `RegExp`, no parsing)?
- [ ] Firebase fetches are cached — not created fresh inside `build()` or `FutureBuilder`?
- [ ] Image assets use `cacheWidth` / `cacheHeight`?
- [ ] Animations use `FadeTransition` / `AnimatedOpacity` (not bare `Opacity`)?
- [ ] `AnimationController` and `StreamSubscription` are disposed in `dispose()`?
- [ ] Code profiled in **profile mode** (not debug)?
