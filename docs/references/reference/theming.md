---
spec: { envelope: 1, experience: 2, grammar: 3 }
doc_version: 1.2.0
status: current
last_verified: 2026-07-25
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

## 6. `theme.calendar.dateRail` — configurable agenda date rail (IMPLEMENTED 2026-07-25 — CALR.10b)

✅ See `spec-version.json`'s `resolvedInGrammar.calendarDateRailBinding`.

The Calendar agenda row's date rail (the small box showing which day a row belongs to) defaults to
exactly two pieces — a weekday abbreviation over a circle-highlighted day number — when a community
doesn't opt in. A community may instead declare `theme.calendar.dateRail.entries`, an ordered list of
small visual pieces to render top-to-bottom:

```jsonc
"theme": {
  "calendar": {
    "dateRail": {
      "entries": [
        { "kind": "dateToken", "token": "weekdayAbbrev", "style": "label" },
        { "kind": "dateToken", "token": "dayOfMonth", "style": "circleHighlight", "colorSource": "accent" },
        { "kind": "formula", "formula": "count(dayInstances)", "style": "badge", "colorSource": "styleField" }
      ]
    }
  }
}
```

| Key | Type | Required | Meaning |
|---|---|---|---|
| `kind` | `"dateToken"` \| `"formula"` | **yes** | Where this entry's value comes from |
| `token` | string | required when `kind: "dateToken"` | One of `weekdayAbbrev`, `dayOfMonth`, `monthAbbrev`, `year` — pure calendar arithmetic, not community data, so this is a small fixed vocabulary |
| `formula` | string | required when `kind: "formula"` | Any expression from the existing computation model (see formulas.md), evaluated over the set of instances landing on that day (`dayInstances`) |
| `style` | `"label"` \| `"circleHighlight"` \| `"badge"` | **yes** | Fixed render primitive — how this entry paints |
| `colorSource` | `"accent"` \| `"styleField"` | no (default `"accent"`) | `"accent"` is today's flat behavior; `"styleField"` reuses the CALR.9b style-slot palette (`stylePaletteFrom`) so the rail's color is community-configurable too |

**Closed-primitives/open-composition split**, the same relationship formula *functions* have to formula
*composition*: `kind`/`token`/`style` are small fixed vocabularies (calendar arithmetic and render
primitives genuinely can't be community-authored), but which entries appear, their data source, their
order, and their color are all fully JSON-driven — a community can show anything expressible as a
formula over that day's instances with **zero new App Shell code**.

**Default and back-compat:** omitting `theme.calendar.dateRail` entirely preserves exactly today's
behavior — equivalent to `entries: [{kind: dateToken, token: weekdayAbbrev, style: label}, {kind:
dateToken, token: dayOfMonth, style: circleHighlight, colorSource: accent}]`. Zero behavior change for
every community that doesn't opt in.

IMPLEMENTED: parsing (`LoomExperienceDefinition.calendarDateRailEntries`) and App Shell rendering of all
three `style` primitives, including `colorSource: styleField`'s resolution and the exact default/back-
compat behavior above (confirmed via a dedicated regression test). NOT YET IMPLEMENTED: validator
coverage (proposed rules: `dangling_date_rail_formula`, `unknown_date_rail_token`,
`unknown_date_rail_style`).
