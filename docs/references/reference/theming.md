---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part17_theme_tokens.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart
---

# Theming (normative) — experience v2

Theme declarations are resolved before a tab surface renders. Renderers consume
the resolved `LoomCardTheme`; they MUST NOT recreate the cascade or derive text
or fills from a raw accent.

## 1. Resolution cascade

The layers are merged in this order:

1. Community `theme` establishes the base `LoomCardTheme`.
2. `theme.tabThemes[tabId]` overrides the active tab's base.
3. A workflow's `themeOverride` overrides the resolved tab theme for that
   workflow's card.

Each later layer wins only for properties it declares. A renderer MUST receive
the theme already resolved for its scope. It MUST NOT bypass a tab override by
reading the community accent directly.

## 2. `LoomCardTheme.merge`

`LoomCardTheme.merge(base, override)` is the only merge operation. If an
override changes `accent`, `merge` first re-derives a coherent base through
`LoomCardTheme.deriveFromAccent`, then applies the override's explicit fields.

- Renderers MUST use `merge`; they MUST NOT hand-merge fields.
- An accent-only override MUST receive re-derived foregrounds and supporting
  tokens rather than stale tokens from the previous accent.
- Authors MAY override individual fill, border, heading, body, shadow, radius,
  elevation, or button tokens after that re-derivation.

## 3. Rendering a resolved theme

The following getters are the sole rendering API:

| Need | Required getter |
|---|---|
| Surface/background fill | `resolvedFill` |
| Dividers, outlines, and cell borders | `resolvedBorder` |
| Titles, labels, and headings | `resolvedHeading` |
| Body copy and secondary event text | `resolvedBody` |
| Shadows | `resolvedShadow` |

- Renderers MUST use these resolved getters, including their opacity.
- Renderers MUST NOT use raw `accent` as foreground or background text color.
- Renderers MUST NOT use ambient Material defaults as a substitute for a
  resolved card border, heading, body, or fill.
- Accent MAY identify a selected state or interactive highlight only after the
  surface has established its resolved fill and foregrounds.

## 4. Nullable `modernTheme`

Some legacy-compatible renderers receive `LoomCardTheme? modernTheme`. They
MUST resolve it before painting:

```dart
final theme = modernTheme ?? LoomCardTheme.deriveFromAccent(accent);
```

This convention applies to Calendar's engine-native and legacy month grids and
matches existing engine surfaces. A null `modernTheme` MUST NOT fall through to
unrelated ambient `ThemeData` colors.

## 5. Calendar requirements

- Engine-native Calendar month cells MUST use `resolvedFill`,
  `resolvedBorder`, `resolvedHeading`, and `resolvedBody`.
- The selected engine-native Calendar date MUST have an accent-driven highlight
  that remains distinct from the resolved unselected fill.
- Legacy `CalendarMonthGrid` MUST use the resolved theme for its label,
  weekday header, cells, day number, event title, and border.
