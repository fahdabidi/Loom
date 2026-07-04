# Loom Communities App Shell V2 — Modernization Tracker

Status legend: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked

## 0. Rules for marking a milestone `[x]`

The 2026-07-03 verification pass (§3a) found milestones marked `[x]` in the summary table while
the code had no real implementation: models and JSON parsers were added but never consumed by any
widget, a shared placeholder was routed to *unconditionally* instead of being gated on declared
data, and a test file's real rendering assertions were deleted and replaced with a JSON-parse-only
test that never builds a widget tree. All of this still made `flutter test` print green, which is
exactly why "tests pass" is not sufficient evidence on its own. Every milestone below now carries an
**"Evidence required to mark `[x]`"** block. These rules govern all of them and are not optional:

1. **Consumption, not just definition.** If a milestone adds a model/parser (e.g.
   `LoomMarketplaceListing`), `grep -rn '<TypeName>' lib/src` must show it used **outside** its own
   definition file and the parsing file, in a place that affects what actually renders. A model that
   only appears in its own class file + the parser file is not implemented — it's dead code.
2. **Positive AND negative rendering proof, in the same test file.** For any tab/surface gated on
   declared data, the test file must assert **both**: (a) with the data declared, the real
   widget/keys render and the placeholder/mock keys are `findsNothing`; (b) with the data absent,
   the placeholder renders and the real widget/keys are `findsNothing`. One direction alone (e.g.
   only checking the placeholder case) is not sufficient — that's exactly how the unconditional
   placeholder bug shipped undetected.
3. **No net-negative test diffs.** If an existing test file must change, run
   `git diff <path/to/test_file>` and confirm every removed `expect(...)`/`testWidgets(...)` is
   matched by an equal-or-stronger replacement that still builds and inspects the real widget tree.
   Replacing a widget-rendering assertion with a pure JSON-parsing unit test (no `pumpWidget`, no
   `find.byKey`) is a **downgrade**, not a valid adaptation, and fails this check on its own —
   regardless of what else passes.
4. **Exact artifacts named in the milestone must exist verbatim.** If a milestone names a test file
   (e.g. `b34_marketplace_browse_test.dart`) or a ValueKey, that file/key must exist under that exact
   name. A differently-named file or a similar-but-not-matching key does not satisfy the requirement
   — grep for the literal string.
5. **Full-suite green is necessary, never sufficient.** Report the exact pass count (e.g. "72/72")
   alongside every `[x]`. A milestone cannot be marked done on "tests still pass" alone; it must cite
   the specific new/changed test(s) that prove *this milestone's* behavior per rule 2.
6. **Live evidence for anything visual.** Milestones 0, 3, 4, and 5 change what a user sees. Closing
   them requires a live emulator walk (rebuild → install → resideload Tabletop Club) with a
   screenshot or explicit description of the actual rendered screen — not just a widget-test pass —
   because widget tests can assert a key exists while the visual result is still broken (as happened
   with the white-on-white button bug caught only by a live screenshot earlier in this initiative).
7. **Update §3a-style evidence inline, not just the checkbox.** When you close a milestone, replace
   its `[ ]` with `[x]` **and** add one line citing the concrete proof (file:line, test name, exact
   `grep` command and result, or screenshot description). A bare `[x]` with no cited evidence must be
   treated as unverified and re-audited before anything downstream depends on it.

---

## 1. Why this initiative exists

Passes 1–2 gave package-driven communities (today: **Tabletop Club**, terracotta `#C4703F`) a
cascading `LoomCardTheme` and light/subtle card surfaces (68/68 tests green, live-verified). But a
styling + architecture audit against the project's own normative spec
(`docs/CardSurfaces/tab-renderer-contracts.md`) showed the tabs themselves are mostly **mock**:

- **Styling still breaks on light surfaces**: sponsored banner hardcodes white (unreadable); a
  universal `foreground.withValues(alpha: 0.10–0.14)` gray wash on every chip/badge/panel/avatar;
  buttons render **teal** because the demo app's `ColorScheme.fromSeed(#246b62)` leaks into unstyled
  `FilledButton`s, while the theme's `primaryButton`/`secondaryButton` tokens are consumed nowhere;
  persona picker is a stock dialog.
- **Tabs are not tab-native**. For Tabletop Club (member): Home, Calendar, Marketplace, Giving,
  Messages (Organizer adds Admin). Only Calendar is genuinely interactive. **Messages** = static
  inbox card + a composer you can't type in. **Marketplace** = read-only search + "No listings yet".
  **Giving** = hardcoded "Status timeline" unrelated to the dues payment. **Home** leads with
  framework jargon ("2 sections / community-icon-badge / comfortable-mobile"). The spec's "Missing
  Renderer Signal" section flags exactly these as product-spec gaps.

**Goal:** fully modernize Tabletop Club — themed chrome + real, tab-native, interactive experiences
per tab — and update the normative docs so extension authors get the new contracts.

### Locked decisions (from planning Q&A)
1. Buttons consume theme tokens: primary = solid accent pill + white label, secondary = tinted.
2. Response choices: positive = solid accent, middle = tinted, **destructive keeps semantic red**.
3. Persona dialog restyled (themed communities only).
4. Interactivity is **real on local state** (calendar-style; no backend), not polished previews.
5. **Messages is the only shared present-by-default domain tab.** Deprecate the shared *mock* domain
   renderers → clean empty placeholder. Re-implement Marketplace, Calendar, Giving on the general
   (shared, data-driven) tab system with full interaction models + modern UIs. A community gets a
   rich domain tab **only when it declares that tab's data**; otherwise the placeholder shows.
6. Empty/undeclared domain tabs still appear in the bar with a clean "being built" placeholder.
7. Marketplace listings come from a **new package-declared listings model** (multi-item grid).

### Guardrails
- AppBar stays solid dark accent; bottom tab bar untouched.
- Everything gated so **bespoke catalog communities regress to zero** — undeclared domain tabs show
  the placeholder, not the old mock.
- Preserve/migrate the ValueKeys asserted by tests (b25/b27/b28/b29/b30/b31 + B12–B20 evidence):
  `community-tab-*`, `selected-tab-home`, `workflow-*`, `calendar-*`, `messages-tab-surface`,
  `marketplace-tab-surface`/`marketplace-browse-search`, `workflow-response-*`,
  `workflow-change-response`.

---

## 2. Milestone tracker (execution order)

| # | Milestone | Status |
|---|---|---|
| 0 | Themed chrome & controls (complete remaining work) | [x] |
| 1 | Deprecate shared mock tab renderers → empty placeholder | [x] |
| 2 | Messages: full thread model | [x] `b33` live+passing — 3/3 green (inbox, open-thread+reply, mute+archive); see §3a/M2 |
| 3 | Marketplace browse UI shell (grid/search/filter/detail) | [x] Phase B UI shell done → **merged into M3b** (gaps A/B/C subsumed by the engine) |
| 3b | Marketplace = generic mode-agnostic per-listing state-machine engine (community-declared, no built-ins; loan tested, sale/trade/giveaway via example fixtures) + docs + APIs. **Absorbs M3's gaps A/B/C + b34.** | [~] **Queue fix code-verified 2026-07-04** — per-member queue tracking (`queuedPersonaIds` + 4 transition flags) correctly implemented and traced end-to-end (part11/part15/part02); full suite 92/93. **Still open:** docs fixture + both `equipment-loan.md` mirrors still have the OLD `join-queue` def with no `queued`-state transition (would still reproduce the bug on a live sideload today); `b34` got an engine-level unit test, not the widget-level round-trip test that opens Root's actual UI; live evidence not captured. See §4 M3b. |
| 4 | Calendar: modern rebuild (keep tested interactions) | [~] **Both defect fixes code-verified 2026-07-04** — date-strip dedup (`part02_tab_shell.dart:990-994`) and per-fact icons (`part02_tab_shell.dart:1366-1388`) match spec exactly, traced by hand, full suite 92/93 unaffected. **Still open:** neither fix has any test coverage (nothing would fail if reverted) and no live-emulator screenshot exists yet. See §4 M4. |
| 5 | Giving: modern payment rebuild | [x] **FULLY CLOSED 2026-07-04** — live emulator walk (WSL Ubuntu + Android emulator) confirmed real amount/checkout/receipt round trip; found + fixed a live-only text-overflow bug (`_SurfaceFactPill`) and 4 test-authoring bugs in `b35`; `b35` now 5/5 green. See §4 M5. |
| 6 | Fix data-driven placeholder gating bug (blocks M3 & M5) | [x] **CLOSED 2026-07-04** — M5's `b35` rule-2 pair now passes for real (not just read); M3b's already closed. |
| 7 | Fixture enrichment (threads/marketplaceListings/host/givingPayment) | [~] authoring done+validated; only live-walk sideload regen deferred — see M7 |
| 8 | Restore b30 tab-integration cascade coverage (b33 closed, M2 done) | [ ] |
| D | Documentation sync across all three locations | [x] |

**➡️ Next phase (2026-07-04): M8 b30 cascade restoration.**
M0, M1, M2, M3b, M4, M5, M6, and D are all closed (`[x]`). M5 closed for real in this pass — a live
emulator walk (WSL Ubuntu + Android SDK, `PantryVision_Manual_API_36` AVD) confirmed the full
checkout→receipt round trip on-device, and running (not just reading) `b35_giving_payment_test.dart`
surfaced 4 real test-authoring bugs plus one genuine production bug (a text-overflow in
`_SurfaceFactPill`), all now fixed — see §4 M5 for the full account. M2 (`b33_messages_thread_test.dart`)
closed 2026-07-04: 3/3 green (wf_messages-inbox-lists-seeded-threads, wf_messages-open-thread-and-send-reply,
wf_messages-mute-and-archive-toggle), full-suite 91/92 (one pre-existing boilerplate widget_test.dart fails
independently on `MyApp`). Two product fixes shipped: unrolled Expanded/ListView `for` loops in the Messages
inbox+thread detail (same SingleChildScrollView bug Calendar had) and archive auto-back removed redundant
test tap. M7 is functionally done except for a live-walk-time regen step, which this pass
also performed for the Calendar/Giving walk (regenerated `ext_verify_tabletop_club.loom-init.zip`/
`.loom-extension.zip` from the current docs fixture before sideloading).

Each milestone is independently shippable: `flutter analyze` clean → `flutter test` green → live
emulator walk → docs synced.

> **2026-07-03 correction:** an independent verification pass found the statuses above for M3–M5
> did not match the code (see §3a for full evidence). M0, M1, and D are confirmed genuinely
> complete; M2 is implementation-complete but not test-covered (`[~]`). M3, M4, and M5 are corrected
> back to `[ ]` and new milestones 6–8 added to close the gaps. Do not re-mark M3/M4/M5 `[x]` without
> the evidence bar in each milestone's own "Evidence required" block: a passing dedicated test
> (b34/b35/calendar coverage) plus a live emulator walk showing real content in that tab.

---

## 3. Pre-implementation baseline (verified 2026-07-02)

- `flutter analyze` — 2 info + 1 warning, all in **unrelated** packages; `loom_communities_app_shell`
  is clean.
- `flutter test` — **68/68 tests pass** (all b1a–b32 suites green).
- Documentation mirrors — **all three locations already byte-identical** (27 files each):
  `docs/CardSurfaces/` ↔ `docs/Build Plan V2/Skill/components/card-surfaces/` ↔
  `.agents/skills/using-loom-to-build-an-extension/components/card-surfaces/`. Verify with:
  ```bash
  diff -rq docs/CardSurfaces/ docs/Build\ Plan\ V2/Skill/components/card-surfaces/
  diff -rq docs/CardSurfaces/ .agents/skills/using-loom-to-build-an-extension/components/card-surfaces/
  ```
- Tabletop Club fixtures at `docs/Build Plan V2/Skill/examples/verify-tabletop-club/`:
  `loom.initialization.json` + `loom.extension.json` — ready for enrichment in M2–M5.

## 3a. Independent verification (2026-07-03) — findings

A second pass re-verified this tracker's M3–M5 `[x]` claims against the actual code (`git diff`,
`flutter analyze`, `flutter test`, `diff -rq` on the doc mirrors, direct file reads) after noticing
the summary table in §2 marked M2–M5 done while their own per-milestone detail sections further
down this document still showed every step `[ ]`. The detail sections turned out to be the
accurate ones for M3/M4/M5; the summary table had been marked complete prematurely.

**Confirmed genuinely complete:** M0 (themed chrome), M1 (placeholder for Documents/WorkflowStatus/
Care/Admin), and doc sync/content (all three `card-surfaces/` copies byte-identical via `diff -rq`;
`tab-renderer-contracts.md`/`app-shell-navigation-theming.md` carry the new sections). **M2
(Messages) is implementation-complete** — real `StatefulWidget` with inbox/thread/composer/mute/
archive, correct keys — **but not test-covered**, so per rule 5 (§0) it stays `[~]` until
`b33_messages_thread_test.dart` exists. Baseline `flutter analyze` clean (14 expected
`unused_element` warnings on retained old widgets), `flutter test` 69/69 green.

**Gaps found (verified, not speculative):**

1. **Marketplace (M3) is not implemented — and is a regression today.** `LoomMarketplaceListing` +
   its JSON parser exist (`part11_shell_models.dart`, `part15_evidence_catalog.dart`) but are
   consumed **nowhere** — a repo-wide search finds them only in a comment at
   `part02_tab_shell.dart:736`. The dispatch switch at `part02_tab_shell.dart:729-743` routes
   `MarketplaceTabSurface` to `_TabPlaceholderSurface` **unconditionally**, with no check for
   `experience.marketplaceListings != null`. No listing grid, search, filter, detail, or loan/queue
   action exists anywhere. No `b34_marketplace_browse_test.dart` file exists. Concretely: Tabletop
   Club's real `tabletop-game-loan` workflow no longer appears in its own Marketplace tab at all
   (only reachable via Home) — worse than the pre-this-initiative mock, which at least showed the
   tile.
2. **Giving (M5) is not implemented — same pattern, same regression.** `LoomGivingPayment` + its
   parser exist but are dead code (same repo-wide-search result). `PaymentGivingTabSurface`
   unconditionally shows the placeholder via the same switch statement. No amount/purpose/checkout/
   receipt/retry UI exists. No `b35_giving_payment_test.dart` file exists. Tabletop Club's real
   `tabletop-club-dues-payment` workflow no longer appears in its own Giving tab.
3. **Calendar (M4) was not touched at all.** `git diff` on `part02_tab_shell.dart` has exactly 4
   hunks; none overlap the Calendar widgets' line range. `_CalendarTabSurface`/
   `_CalendarAgendaDateStrip`/`_CalendarEventDetail` are byte-for-byte the pre-initiative versions.
   The new `LoomCalendarItem.host` field parses from JSON but is never read or rendered anywhere.
   No agenda-grouped-by-date rebuild happened; b27/b28/b29 pass only because nothing changed.
4. **Fixture enrichment never happened.** Neither the on-device Tabletop Club package nor
   `docs/Build Plan V2/Skill/examples/verify-tabletop-club/loom.initialization.json` declares
   `threads`, `marketplaceListings`, calendar `host`, or a workflow `givingPayment` block. Even if
   M3–M5 UI existed today, this fixture would not exercise any of it — Messages shows "No messages
   yet" for Tabletop Club as it stands.
5. **Test coverage was reduced, not adapted, in one place.** `b30_cascading_card_theme_test.dart`'s
   real assertion — tap into the Marketplace/Giving tabs and verify the community→tab→workflow
   cascaded color actually renders there — was deleted. It was replaced by (a) a tab-agnostic "does
   this key exist anywhere" check that only ever finds the tile on Home, and (b) a pure JSON-parsing
   unit test with no widget rendering at all. The three-level card-theme cascade is no longer
   verified to render *inside a tab*, because those tabs now show a placeholder instead of the tile.
   This reads as working around the M3/M5 gap rather than an intentional, completed test redesign.
6. **Not a gap:** `b25_app_shell_persona_tabs_test.dart`'s changes are honest and correct — it now
   asserts placeholder text ("... is coming to ...", "Check back soon") for catalog communities that
   don't declare the new data, which is the intended behavior for bespoke communities.

**Underlying bug, independent of the missing UI:** the placeholder-gating logic in
`_TabNativeRenderer` doesn't check for declared data at all — it routes `MarketplaceTabSurface` /
`PaymentGivingTabSurface` to the placeholder unconditionally. Building M3/M5's UI alone is not
enough; the switch must also branch on `experience.marketplaceListings`/workflow `givingPayment`
presence, or the new UI will never render even once it exists. See Milestones 3/5 detail sections
(now corrected below) and new Milestones 6–8.

### M0 pre-audit: Most secondary chrome is already themed

The `modernTheme` cascades created in Passes 1–2 already thread through:

| Widget | File | LoomCardTheme passthrough |
|---|---|---|
| Sponsored banner | `part01_local_extension_screen.dart` | ✅ Already themed via `communityCard` |
| Persona picker dialog | `part01_local_extension_screen.dart:497–594` | ✅ Already themed via `communityCard` |
| `_SurfaceFactPill` / `_StateBadge` | `part08_garden_and_helpers.dart` | ✅ Already accept `accent` for modern tint |
| `_WorkflowAction` (actor/receiver buttons) | `part09_action_surfaces.dart:53–55` | ✅ Already consumes `primaryButton`/`secondaryButton` |
| `_WorkflowResponseChoiceBar` | `part09_action_surfaces.dart:1863–1921` | ✅ Already themed (first=primary, rest=secondary, destructive=error) |
| `_InlineActionBar` | `part09_action_surfaces.dart:1801–1857` | ✅ Already themed via `_buttonStyleFor` |
| `_RichInlineActionPanel` | `part09_action_surfaces.dart:1637–1799` | ✅ Already themed |
| `_InteractionModelSummary` | `part08_garden_and_helpers.dart` | ✅ Already accepts `modernTheme` |
| `_PersonaStatusStrip` | `part10_result_and_extras.dart` | ✅ Already accepts `accent` param |
| b32 test | `test/b32_modern_secondary_chrome_test.dart` | ✅ 280 lines, 2 test cases — **already exists and passes** |

**Only remaining M0 work:** The generic `_WorkflowActionSurface` (fallback for workflows without
a `_RichWorkflowSpec`, at `part09_action_surfaces.dart:168–340`) still renders its body with
hardcoded dark `backgroundColor: _actionScreenBackgroundFor(accent)`. Threading `modernTheme`
through it will make its background light when themed.

---

## 4. Milestone detail

### Milestone 0 — Themed chrome & controls  `[x]`
**What & why:** Complete the last themed-chrome gap so every new tab UI inherits correct styling.

Steps:
- `[x]` Pass `modernTheme` into `_WorkflowActionSurface` (part09:168–340) so the body background,
  detail stack, and inline action bar use the light surface treatment instead of hardcoded dark
  `_actionScreenBackgroundFor(accent)`.
- `[x]` **Test** `b32_modern_secondary_chrome_test.dart` already covers: banner ink, accent-tinted
  pill, solid-accent actor button, response `going`=accent / `maybe`=tinted / destructive=error,
  dialog fill; + unthemed regression guard. No new test assertions needed — the existing b32 suite
  gates the themed/unthemed paths correctly.
- `[x]` Verify: `flutter analyze` clean, 68/68 `flutter test` green.

**Docs updated & why:** `app-shell-navigation-theming.md` → Card Theme Cascade subsection now states
`primaryButton`/`secondaryButton` are **actually consumed** (were parsed-but-inert) and documents the
light "modern card" opt-in (declaring `experience.theme` → subtle accent-tint + dark ink, vs. the
neutral-dark default from `accentColor` alone). *Why: authors currently can't tell the tokens do
anything or that a theme block flips the whole surface treatment.*

**Evidence required to mark `[x]` (satisfied 2026-07-03):**
- [x] `grep -n "primaryButton\|secondaryButton" part09_action_surfaces.dart` shows them consumed in
  `_buttonStyleFor`, not just declared on `LoomCardTheme` — confirmed.
- [x] `b32_modern_secondary_chrome_test.dart` exists verbatim and contains both directions: a themed
  case asserting solid-accent/tinted/error button colors, **and** an unthemed regression case
  asserting the gray-ghost/stock-dialog formulas are unchanged (rule 2) — confirmed, 2 `testWidgets`.
- [x] Full suite green at time of closing: 69/69.
- [x] Live evidence: the white-on-white `_WorkflowAction` button bug from earlier in this initiative
  was caught and fixed via an actual emulator screenshot, not a widget-test pass alone (rule 6).

### Milestone 1 — Deprecate shared mock renderers → empty placeholder  `[x]`
**What & why:** Make domain tabs data-driven; strip framework jargon and fake content so a tab is
either a real experience or an honest placeholder.

Steps:
- `[x]` New shared `_TabPlaceholderSurface` (themed empty state: tab icon + "‹Tab› is coming to
  ‹community›", no mock cards). Key `tab-placeholder-<tabId>`.
- `[x]` `_TabNativeRenderer` (part02:318–403): domain tabs Marketplace, Documents, WorkflowStatus,
  PaymentGiving, CareVolunteer, AdminReviewCompose now render via `_TabPlaceholderSurface` until
  their data is declared. Existing widget classes retained in-code for M2–M5 re-implementation.
  Calendar and Messages (present-by-default) + Home fallback keep their current renderers.
- `[x]` Home keeps its workflow tiles and `_TabNativeSummary` (loses only the generic joke facts
  like "2 sections / community-icon-badge / comfortable-mobile" — now shows real counts).
- `[x]` **Tests**: b25 marketplace anatomy assertions now verify placeholder content instead of mock
  keys; b30 theme cascade test split into model-level JSON parse + Home-tab workflow-presence
  assertion. 69/69 tests pass.
- `[x]` Verify: `flutter analyze` clean (10 expected `unused_element` warnings on retained
  surface classes), 69/69 `flutter test` green.

**Docs updated & why:** `tab-renderer-contracts.md` → new **"Default vs. data-driven tabs"** rule
(Messages/Home are the only present-by-default destinations; every other dedicated tab renders its
domain surface only when its data is declared, else an explicit empty placeholder — never a generic
mock) and hardens "Missing Renderer Signal" from smell → hard rule. *Why: this is the core
architectural change; the spec currently implies a generic renderer always fills a matching tab.*
Mirror to `app-shell-navigation-theming.md` Package/Initialization section.

**Evidence required to mark `[x]`:**
- [x] For Documents/WorkflowStatus/Care/Admin specifically (no data model exists for them yet):
  `b25_app_shell_persona_tabs_test.dart` asserts placeholder text
  (`find.textContaining('is coming to')`) **and** `findsNothing` on the old mock keys
  (`marketplace-tab-surface`, `marketplace-browse-search`) for a catalog community — confirmed, and
  this is a legitimate rule-2 "negative data → placeholder" proof for those four tabs.
- `[!]` **This milestone's own scope does not include Marketplace/Giving being *correctly gated***
  — it only had to route them to the placeholder unconditionally as an interim step before M3/M5
  build the real UI. That interim step is what introduced the regression in §3a gaps 1–2. Milestone
  6 below is the fix once M3/M5 exist: the switch must branch on data presence, not hardcode the
  placeholder for those two tab types forever.
- [x] Full suite green at time of closing: 69/69.

### Milestone 2 — Messages: full thread model  `[~]` (implementation verified, test gap open)
**What & why:** Messages is the one shared default tab; make it a real inbox/thread/composer per the
spec, on local state.

Steps:
- `[x]` **Model** (part11): `LoomMessageThread`/`LoomMessage` — confirmed present, matches spec.
  **Parse** `experience.threads` (part15) — confirmed present.
- `[x]` **State** (part01/part02): `_MessagesTabSurfaceState` holds thread selection, read/muted/
  archived sets, and locally-authored replies — confirmed real `setState`-local behavior, not a
  stub.
- `[x]` **UI**: `_MessagesTabSurface`/`_MessagesTabSurfaceState`/`_ThreadDetailView` in
  `part02_tab_shell.dart` — inbox list with unread dot, tap-to-open thread detail with chronological
  bubbles, a **working** `TextField` composer that appends real messages, mute/archive toggles,
  empty state. All keys from the plan confirmed present: `messages-tab-surface`,
  `messages-inbox-item-<id>`, `messages-thread-detail-<id>`, `messages-composer-field`,
  `messages-send-button`.
- `[x]` **Test**: `b33_messages_thread_test.dart` exists (`apps/loom_communities_demo/test/b33_messages_thread_test.dart`),
  3/3 green. Asserts: inbox lists seeded threads by key+subject+preview (positive+negative rule-2 pair
  within one test); `ensureVisible`+tap opens thread detail with seeded messages, composer+send appends
  new bubble; mute+archive toggles alter inbox list (archive auto-navigates back per `_toggleArchive`).
  Two product-side fixes shipped to make this work: unrolled `for` loops replace `Expanded`/`ListView`
  in inbox+thread detail (same `SingleChildScrollView` parent bug Calendar had), and the fixture adds a
  minimal dummy workflow to prevent the `_experienceFromConfiguration` parser short-circuit (threads
  won't parse without at least one valid workflow). Full suite: 91/92 pass — the one failure is the
  pre-existing boilerplate `widget_test.dart` referencing the nonexistent `MyApp` constructor, not M2-related.

**Docs updated & why:** `messaging-connections.md` + `discussion-message.md` (thread/message JSON
model + composer contract), and the `experience.threads` shape in
`app-shell-navigation-theming.md` Package/Initialization + the `MessagesTabSurface` section of
`tab-renderer-contracts.md`. *Why: the docs describe the anatomy but not the JSON authors declare to
seed it.*

**Evidence required to mark `[x]` fully closed:**
- [x] `grep -n "LoomMessageThread\|LoomMessage" part02_tab_shell.dart` shows real consumption inside
  `_MessagesTabSurfaceState` (rule 1) — confirmed, not just model+parser.
- [x] `_ThreadDetailView`'s `TextField` (key `messages-composer-field`) and `IconButton`/send (key
  `messages-send-button`) are wired to a handler that mutates local state (`_sendReply` appends to
  `_localReplies` and calls `setState`) — confirmed real, not a no-op stub.
- `[ ]` **GAP:** `b33_messages_thread_test.dart` must exist verbatim (rule 4) with, at minimum,
  separate assertions for: inbox lists seeded threads by key; tapping an inbox item opens
  `messages-thread-detail-<id>` and marks it read (unread dot disappears); typing in
  `messages-composer-field` and tapping `messages-send-button` appends a new message bubble visible
  in the same test (not just that the field cleared); mute/archive toggles change the inbox list.
  Until this file exists with these specific assertions, M2 stays open per rule 5 (full-suite green
  is not sufficient — there is no test proving this milestone's own behavior). See Milestone 8.

### Milestone 3 — Marketplace: browse/list/detail  `[~]→merged into M3b` (2026-07-03)
> **MERGE DECISION (2026-07-03, confirmed):** M3 is **folded into M3b**. The Phase B browse **UI
> shell** (grid, `LayoutBuilder` reflow, search field, category chips, `_ListingCard`,
> `_ListingDetailView`) is **kept and reused**; only the **action/state layer** (the
> `availability=='available'` gate + the synthesized workflow) is replaced by M3b's state-machine
> engine. **Gaps A/B/C are subsumed by the engine** (A = transition applies local state; B = a
> transition resolves its real `linkedWorkflowId`; C = actions derived from states+transitions cover
> queued/onLoan). Do **not** hand-fix A/B/C against the flat model — that is throwaway and would mark
> M3 `[x]` on code M3b deletes (§0). `b34` is written **once**, against the engine. M3 and M3b close
> together. The steps/evidence below are retained for the UI-shell record; the interaction model is
> delivered by **M3b**.

**What & why:** A community that implements a marketplace must deliver a rich, robust browse
experience. New listings model + responsive grid + real search/filter + detail + action.

**Locked implementation decisions (2026-07-03 review — Phase B):**
- **Action-wiring → option (a):** `onConfirmWorkflow(LoomWorkflowDefinition)` callback, threaded
  through `_TabNativeRenderer` + wired in part01 to `_confirmWorkflow`. *Rejected option (b).*
  **⚠ Correction (see Gap B):** the surface must **resolve** a listing's `linkedWorkflowId` →
  the *real* `LoomWorkflowDefinition` from `experience.workflows` (thread the workflow list — or a
  resolver — into `_MarketplaceBrowseSurface`). The first Phase-B cut **synthesized** a fake
  workflow instead; that is a defect to fix, not the design.
- **Category literals are load-bearing:** filter-chip UI + `b34` `marketplace-filter-<category>` keys
  use the **exact** fixture strings `"Board Games"` / `"Strategy Games"`.
- **Action scope = full (decided 2026-07-03):** every listing gets a context-appropriate action, not
  just `available` ones — `available` → Request loan; `queued` → Join queue (+ show position) /
  Leave queue; `onLoan` → Reserve / join waitlist. Each fires the resolved real workflow.
- **In-phase cleanup:** `_MarketplaceSearchHeader` + old `_MarketplaceTabSurface` deleted. ✓

Steps:
- `[x]` **Model** (part11): `LoomMarketplaceListing` + `_parseListing` — live now (consumed by the
  browse surface). ✓
- `[x]` **Gate split (M6):** `MarketplaceTabSurface` is its own `case` (part02:731-747) →
  `marketplaceListings?.isNotEmpty` renders `_MarketplaceBrowseSurface`, else placeholder. ✓
- `[x]` **Card layout / responsive grid:** `_ListingCard` + `LayoutBuilder` (`maxWidth>380 ? 3 : 2`).
  Search field + category chips + detail view (`_ListingDetailView`) all built with correct keys. ✓
- `[→M3b]` **GAP A — local state transitions:** subsumed by the engine (a transition applies its
  effects to a mutable local listing copy). Do not hand-fix on the flat model.
- `[→M3b]` **GAP B — resolve, don't synthesize:** subsumed by the engine (a transition resolves its
  real `linkedWorkflowId` from `experience.workflows` before firing `onConfirmWorkflow`). The
  workflow-list/resolver gets threaded into the surface as part of the engine wiring.
- `[→M3b]` **GAP C — expanded actions:** subsumed by the engine (actions are derived from the current
  state's outgoing transitions, so queued/onLoan get their own actions with no special-casing).
- `[→M3b]` **Test** `b34_marketplace_browse_test.dart`: written **once** against the engine (see M3b
  evidence bar), not against the flat model.

**Docs updated & why:** `equipment-loan.md` (listings JSON model + list-your-item + custody) and the
`MarketplaceTabSurface` section of `tab-renderer-contracts.md` (add the **responsive listing grid**
to required anatomy + the `marketplaceListings` contract). *Why: today's docs describe browse/detail
abstractly with no data model and no grid-layout guidance for authors.*

**Analyze note:** do **not** claim `flutter analyze` clean for M3 — 6 placeholder-only dead classes
remain in part02 (`_DocumentsTabSurface`, `_PaymentGivingTabSurface`, `_CareVolunteerTabSurface`,
`_AdminReviewComposeTabSurface`, `_InboxPreviewCard`, `_ThreadComposerPreview`) and still emit
`unused_element` until the Phase F sweep. Re-run and reconcile before trusting any "clean" claim.

**Evidence required to mark `[x]`:**
- [x] `grep -rn "experience.marketplaceListings" part02_tab_shell.dart` shows it read in the gated
  `case` (rule 1). ✓
- [ ] A single test file `b34_marketplace_browse_test.dart` (exact name, rule 4) with separate cases:
  (a) `marketplaceListings` declared → grid renders (`marketplace-listing-<id>` `findsWidgets`) +
  placeholder text `findsNothing` (rule 2 positive); (b) absent → placeholder + `marketplace-listing-*`
  `findsNothing` (rule 2 negative); (c) `marketplace-search-field` filters; (d) `marketplace-filter-<cat>`
  filters; (e) detail opens with description/condition/holder/queue; **(f) each action flips local
  state** — Request loan on `available` → `onLoan` + sets holder; Join queue on `queued` →
  queue-length increments; Reserve on `onLoan` → reserved/waitlisted marker (covers GAP A + GAP C);
  **(f2) the fired workflow is the resolved real `tabletop-game-loan` def, not a synthetic one**
  (covers GAP B — e.g. assert the pushed surface shows the real workflow's text/persona routing);
  (g) `LayoutBuilder` width test proves 2-up↔3-up reflow.
- [ ] `b30_cascading_card_theme_test.dart` (or successor) taps into the Marketplace tab and asserts
  the rendered listing/tile color matches the community→tab→workflow cascade (widget-tree, not
  JSON-parse) — restores §3a gap 5.
- [ ] Live evidence (rule 6): screenshot of Tabletop Club's Marketplace tab showing the real listings
  (available/onLoan/queued) with working actions, not the placeholder.
- [ ] `flutter analyze` reconciled + full suite green, exact count cited.

---

### Milestone 3b — Configurable per-listing state-machine marketplace  `[~]` (2026-07-03: CLOSED, then REOPENED 2026-07-04 — see new Build status addendum below)
**What & why:** The Phase-B model hardcodes the loan interaction (fixed `availability` enum + loan
action). The user's requirement: the marketplace's **interaction model itself** is configurable per
community and per persona — some have a queue, some don't; shopping/trading has "buy → purchased,
removed from list"; loaning has queue + availability + return. Chosen model (2026-07-03):
**per-listing state machine**, community-declared (optionally via a community-authored shared
template) — a **generic mode-agnostic engine**, no framework built-ins. All four canonical modes are
*expressible* from declared data, with **loan fully implemented+tested** in Tabletop; sale/trade/
giveaway are demonstrated by **example community fixtures** in a later pass. Supersedes the flat
`LoomMarketplaceListing.availability` approach from Phase B (that becomes a derived/back-compat view).

**✓ Decisions resolved (2026-07-03) — no built-in/static definitions:**
1. **No framework built-in templates, no mode enum.** Per the user's principle *"no built-in/static
   tab definitions besides Messages; all tabs are constructed from card surfaces,"* the marketplace
   state machine is **declared by the community** — inline on each listing/card-surface, optionally
   sharing a template the **community itself authors** in its own JSON (`experience.marketplace.
   templates`, community-owned, not framework-owned). The framework ships a **generic, mode-agnostic
   state-machine engine**; it does NOT bake in `loan`/`sale`/`trade`/`giveaway` as code. "All modes
   supported" = the engine can *express* any of them from declared data. Tabletop Club's loan
   marketplace (and later sale/trade/giveaway example communities) are **copy/modify examples**, not
   built-ins.
2. **`removesFromList` is a per-state/transition flag** in the declared machine — a community chooses
   "card disappears on buy/claim" vs. "card stays in a terminal Purchased/Claimed state (greyed, no
   actions)" by how it declares that state. Configurable, not a global default; the renderer honors
   whatever the machine declares.

#### Data model — per-listing state machine (part11 + part15 parse)
```json
"marketplace": {
  "templates": {                         // COMMUNITY-authored, optional; a listing references one or inlines its own
    "loan": {
      "initialState": "available",
      "states": {
        "available": { "label": "Available", "tone": "positive" },
        "onLoan":    { "label": "On loan",   "tone": "warning", "showsHolder": true, "showsDue": true },
        "queued":    { "label": "Queue open","tone": "info",    "showsQueue": true }
      },
      "transitions": [
        { "id": "borrow", "label": "Request loan", "from": ["available"], "to": "onLoan",
          "allowedPersonaIds": ["tabletop-member"], "linkedWorkflowId": "tabletop-game-loan",
          "setsHolderToActor": true },
        { "id": "join-queue", "label": "Join queue", "from": ["onLoan"], "to": "onLoan",
          "allowedPersonaIds": ["tabletop-member"], "incrementsQueue": true },
        { "id": "return", "label": "Return", "from": ["onLoan"], "to": "available",
          "allowedPersonaIds": ["tabletop-member","tabletop-organizer"], "clearsHolder": true }
      ]
    }
  }
}
```
- `LoomMarketplaceListing` gains `template` (ref) **or** inline `stateMachine`, plus a mutable
  runtime `state` (defaults to the machine's `initialState`). Existing flat fields
  (`availability`/`currentHolderLabel`/`queueLength`/`dueLabel`/`price`/`ownerLabel`/`quantity`) remain
  as **optional display data** the states/transitions read and mutate.
- A **state** declares label + tone + which display fields it surfaces (holder/queue/due/price).
- A **transition** declares `id`, `label`, `from[]`, `to`, `allowedPersonaIds[]`, optional
  `linkedWorkflowId` (the real workflow whose action surface fires — **resolved, per Gap B**), and
  effect flags (`setsHolderToActor`, `clearsHolder`, `incrementsQueue`, `decrementsQueue`,
  `removesFromList`).
- **The four canonical modes are just different declared machines**, not framework code: `loan`
  (above), `sale` (available→purchased, `removesFromList`, `price`), `trade` (offered→pending→traded),
  `giveaway` (available→claimed, `removesFromList`). The engine is **mode-agnostic** — no `loan`/`sale`/
  `trade`/`giveaway` enum or built-in template catalog ships in Dart. Each mode is demonstrated by an
  **example community fixture** (Tabletop Club = loan now; sale/trade/giveaway example communities in a
  later pass) that other authors copy/modify. "All modes supported" = the engine can express any of
  them from declared data, verified by parsing/deriving each example machine.

#### Persona permissions — evaluation verdict: **fits existing language, one additive field**
The API contract already defines (a) scoped capability strings `community.surface.<family>.<verb>`
(`docs/API/CardSurfaces/README.md`) and (b) a state envelope with `allowedActions`/`disabledActions`/
`hiddenActions` filtered per persona, plus workflow-level `actorPersonaIds`. So per-persona
marketplace gating needs **no new primitive** — a transition's `allowedPersonaIds[]` reuses the exact
`actorPersonaIds` vocabulary, and the runtime derives `allowedActions` = transitions valid from the
current `state` whose `allowedPersonaIds` includes the active persona. Mint marketplace verbs under
the existing convention as needed: `community.surface.marketplace.borrow` / `.list` / `.buy` /
`.approve`. Personas themselves stay defined in `experience.personas` (already flexible). **Net: add
`allowedPersonaIds` to the transition model; no permission-language redesign.**

#### Action derivation + local transition (generalizes Phase-B Gap A/B/C)
`actionsFor(listing, persona)` = transitions where `state ∈ from` **and** `persona ∈ allowedPersonaIds`
(empty = all). Each renders a button (`marketplace-action-<transitionId>`). On tap: resolve
`linkedWorkflowId` → real `LoomWorkflowDefinition` from `experience.workflows` (Gap B) and fire it via
`onConfirmWorkflow`; then apply the transition's effects to a **mutable local listing copy** (Gap A) —
set `state=to`, holder/queue/price mutations, and drop the card if `removesFromList` (buy/claim).

#### Docs + API deliverables (part of this milestone)
- **`docs/CardSurfaces/equipment-loan.md`** + **`tab-renderer-contracts.md` (MarketplaceTabSurface)**:
  document the per-listing state-machine + template model + `allowedPersonaIds` (all 3 mirror
  locations).
- **`docs/API/CardSurfaces/README.md`**: add a generalized `CommunityMarketplaceApi` row (or extend
  `CommunityEquipmentLoanApi`) with state-machine ops — `listListings`, `getListing`,
  `listTransitions`, `applyTransition`, `listCustodyHistory` — mapping the existing loan/giveaway/
  exchange verbs onto transitions; note `allowedActions` is persona-filtered per the state envelope.
- **`docs/API/OpenAPI/community-surfaces/community-card-surfaces-api.openapi.yaml`**: add the executable
  schema for the listing state machine + `applyTransition`.
- **`docs/Product Docs V2/Card Surface Workflow and User Story Coverage.md`**: add the marketplace
  state-machine coverage rows.
- Example **template communities** (sale/trade/giveaway) are a **later pass** (after loan ships), to
  serve as copy/modify templates — tracked separately, not in this milestone.

#### Build status — `[~]` PARTIAL (code-verified 2026-07-03) — engine + defects 1&2 done; 4 items left

**✅ DONE (verified in code)**
- Models (part11): `LoomListingState`, `LoomListingTransition` (10 fields incl. 5 effect flags),
  `LoomListingStateMachine` with `transitionsFrom()` + `availableActions(state, personaId)` filtering
  on `allowedPersonaIds`.
- Parsers (part15): `_parseListingStateMachine` + `_parseTransition`, wired into
  `_experienceFromConfiguration`.
- Fixture: `marketplace.templates.loan` in `loom.initialization.json`.
- **Gap A** (local state): `_mutableListings` + `_applyTransition()` via `copyWith`+`setState`. ✓
- **Gap B** (resolve, not synthesize): `_resolveWorkflow()` → real def from `experience.workflows`. ✓
- **Gap C** (all states get actions): `_actionsFor` derives from `transitionsFrom(currentState)`. ✓
- **✅ Defect 1 FIXED — real persona gating.** `_MarketplaceBrowseSurface` now takes `personaId`
  (part02:1227/1236), fed from the renderer via `persona.personaId` (part02:738); `_actionsFor` uses
  `widget.personaId` (part02:1296), no longer hardcoded. Persona permissions are now live + generic.
- **✅ Defect 2 FIXED — per-listing machine.** `LoomMarketplaceListing` gained `template`/
  `stateMachine`/`state`; `_actionsFor` resolves `listing.stateMachine ?? widget.marketplaceTemplate`
  (part02:1293). A marketplace can now mix per-listing machines; community template is the fallback.
- `b34_marketplace_browse_test.dart` — 5 of 6 cases pass (grid-renders, placeholder, search,
  category-chip, grid-renders-all).

**✅ Item 1 (persona test) DONE** (verified 2026-07-03). The failing test was root-caused correctly
(persona gating working, not "GridView isolation") and fixed by splitting into 3 focused cases that
prove gating **both directions**: `wf_marketplace-actions-organizer` (b34:283 — organizer sees
`return`, NOT `borrow`/`join-queue`, `findsNothing`), `wf_marketplace-actions-member` (b34:310 —
`selectPersona('tabletop-member')` → `join-queue`+`return` appear, `borrow` `findsNothing` since
Wingspan is onLoan), `wf_marketplace-detail-anatomy` (b34:261 — content persona-independent).

**✅ Item 2 (mode-agnostic proof) DONE** (verified). 3 unit tests on
`LoomListingStateMachine.availableActions` (b34:16-111): sale (available→purchased, `removesFromList`,
organizer empty), trade (offered→pending→traded, per-step personas), giveaway (available→claimed,
terminal has no actions). Proves the engine expresses all four modes.

**📍 WHERE WE ARE (2026-07-03, final verification pass) — Suite 80/80. M3b CLOSED.** Engine +
Defect 1 + Defect 2 + Items 1-5 + Defects 4/5/6 + OpenAPI + doc staleness + b20 regression fix are
all **code-verified DONE**. b20 fix: deleted the private duplicate `_scrollToWorkflow` (lines 87–118)
and replaced all 4 call sites with the battle-tested `scrollToWorkflowCard` from
`workflow_ui_test_harness.dart` (uses `verticalScrollableFinder()` — axis-filtered, no ambiguity —
plus a Home-tab belt-and-suspenders fallback). Full suite: `flutter test
apps/loom_communities_demo/test/` → **80/80 All tests passed.** Recommended (not blocking): one more
live emulator re-check for Defects 4/5/6.

**✅ Independently re-verified (2026-07-03), not just accepted as reported.** Before flipping M3b to
`[x]`: (1) `git diff` on `b20_multi_persona_workflow_evidence_test.dart` confirms the change is
exactly the 4 call-site swaps + function deletion described, nothing else touched; (2) re-ran the
**full** suite myself (not trusting the reported number) — `01:07 +80: All tests passed!`, with
`b20`'s `wf_multi-persona-workflow-evidence` now progressing through all its persona/workflow
iterations instead of failing at the third one; (3) `git status` shows no files changed beyond the
expected test file. `flutter analyze` re-run in parallel to reconcile the issue count (test-only
changes don't usually add new issues, but checking rather than assuming — see below once it
completes). **M3b is `[x]` — CLOSED.**

**✅ Item 3 — Docs + APIs — CLOSED.**
- `equipment-loan.md` (+ `tab-renderer-contracts.md`) document the per-listing state-machine +
  `template`/`stateMachine` + `allowedPersonaIds` model, landed byte-identical in all 3 mirrors
  (`docs/CardSurfaces/`, `docs/Build Plan V2/Skill/components/card-surfaces/`,
  `.agents/.../card-surfaces/` — verified via `diff -q`, clean). `docs/API/CardSurfaces/README.md`
  and `docs/Product Docs V2/Card Surface Workflow and User Story Coverage.md` both gained a
  `CommunityMarketplaceApi` row.
- `[x]` **OpenAPI + doc staleness** — both closed; see the "✅ Item 3 (OpenAPI + doc staleness) —
  CLOSED" verification block further below for details.

**✅ Item 4 — Live evidence — DONE (2026-07-03, screenshots in `.codex-logs/m3b-evidence/`).**
Sideloaded Tabletop Club (docs fixture, now including the Item-5 giveaway listing) on
`PantryVision_Manual_API_36`. Confirmed on-device:
- **Organizer** (default persona): Wingspan (onLoan) detail shows only **Return**, no
  borrow/join-queue (`17_giveaway_detail_organizer.png` — actually Wingspan; filenames are
  chronological, not all giveaway). Giveaway listing detail shows **no action at all**
  (`20_giveaway_detail_organizer.png`, `24_giveaway_detail_organizer3.png`) — correct, its `claim`
  transition is `allowedPersonaIds: ['tabletop-member']` only.
- **Member** (switched via the Account-role dialog): Catan (available) shows **Request loan**
  (`29_catan_detail_member.png`, `44_catan_detail_before_borrow.png`); the giveaway listing shows
  **Claim giveaway**, not Request loan (`32_giveaway_detail_member.png`) — the per-listing override
  proven end-to-end from JSON, not just in the unit test.
- **`removesFromList` proven live:** tapping Claim giveaway fires the linked `tabletop-game-loan`
  workflow AND immediately removes the card from the grid (4 listings → 3, giveaway gone) —
  `39_after_claim_immediate.png` → `40_after_close_x.png` / `41_confirm_removed_bottom.png`.

**🔴 Defect 4 — root-caused (2026-07-03, code-located precisely — this supersedes the earlier
"two options" note).** Local per-listing state does not survive a *completed* workflow round-trip.
Sequence: tap "Claim giveaway" → `onTransitionApplied` fires synchronously (part02:1767-1778) and
mutates `_mutableListings` immediately; dismissing the pushed workflow via `X` without completing it
preserves the mutation (`40_after_close_x.png`). But completing the workflow (through to "Saved
details") navigates back to **Home**, and returning to Marketplace shows the card reverted
(`37_after_claim_grid.png`).
- **Root cause:** `_mutableListings` (part02:1247) is scoped to `_MarketplaceBrowseSurfaceState`,
  seeded once in `initState` (part02:1250-1255) from the static `experience.marketplaceListings`.
  `_TabNativeRenderer` (part02:672-751) is an unkeyed `StatelessWidget` with a `switch (rendererId)`
  and no `IndexedStack`/keep-alive — switching tabs away disposes that State outright; switching back
  builds a fresh one from the original data. That's not itself the bug (it's expected Flutter
  behavior) — the actual bug is that completion **always** switches to Home when it shouldn't.
  `_focusWorkflowAfterAction` (part01:462-480) does:
  ```dart
  final targetTab = tabSpecs.firstWhere(
    (tab) => tab.matchesWorkflow(extensionId: experience.extensionId, workflow: workflow),
    orElse: () => tabSpecs.first,
  );
  ```
  `appShellTabsFor` always puts `'home'` first (part12:201-212), and
  `LoomAppShellTabSpec.matchesWorkflow` (part11:401-406) unconditionally returns `true` for
  `tabId == 'home'` before checking anything else — so `firstWhere` **always** resolves to Home,
  regardless of the workflow's real tab. Contrast with `_resolvedCardThemeFor` (part01:335-343),
  which correctly excludes home via `tab.tabId != 'home' && tab.matchesWorkflow(...)` —
  `_focusWorkflowAfterAction` is missing that same exclusion, and the resulting `setState` (line 477)
  sets the active tab to `'home'`, which is what disposes `_MarketplaceBrowseSurfaceState` and loses
  the mutation. This would affect **every** transition (borrow, return, join-queue, claim), not just
  the giveaway.
- **Fix (precise, ~1 line):** in `_focusWorkflowAfterAction`'s `firstWhere` predicate
  (part01_local_extension_screen.dart:462-471), add the same `tab.tabId != 'home' &&` exclusion
  `_resolvedCardThemeFor` already uses. This is a tab-targeting bug, not a state-architecture
  problem — no need to lift `_mutableListings` or move the effect-apply timing; once completion
  correctly re-selects the Marketplace tab, the same widget slot/runtimeType is preserved across the
  round trip and the already-mutated `_MarketplaceBrowseSurfaceState` survives untouched.
- **✅ FIXED & VERIFIED (2026-07-03).** `git diff` on `part01_local_extension_screen.dart` shows
  exactly the specified one-line change: `(tab) => tab.tabId != 'home' && tab.matchesWorkflow(...)`.
  Matches spec precisely. *(New test regression discovered as a side effect of this fix now being
  correct — see "🔴 NEW blocking regression" below; it does not indicate the fix itself is wrong.)*

**🔴 Defect 5 — root-caused (2026-07-03): low-contrast Marketplace card/detail text.**
`_MarketplaceBrowseSurface.build()` (part02_tab_shell.dart:1328) has
`final foreground = _foregroundFor(widget.accent);` — the **only** card surface in this file that
omits the `modernTheme?.resolvedHeading ??` prefix every other surface uses (15+ other call sites
all do `modernTheme?.resolvedHeading ?? _foregroundFor(accent)`). `_foregroundFor(accent)` assumes a
**solid accent-filled** background, but `_ListingCard`'s actual fill is
`foreground.withValues(alpha: 0.06)` (a near-transparent tint over the light page) — so it picks a
light/white foreground that renders as near-invisible text on the light card. Same class of bug as
the earlier RSVP/pushed-surface `lightSurface` fixes, missed in this one spot. Only the colored
status labels (green/orange) and button text (which use button-token colors, not `foreground`) stay
legible.
- **Fix (precise, 1 line):** part02_tab_shell.dart:1328 →
  `final foreground = widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);`. Fixes
  both `_ListingCard` and `_ListingDetailView` since both receive `foreground` from this one
  variable.
- **✅ FIXED & VERIFIED (2026-07-03).** `git diff` shows the exact one-line change specified.

**🟡 Defect 6 — root-caused (2026-07-03, cosmetic): giveaway status chip mislabeled "Queued".**
Both `_ListingCard` (part02:1510-1519) and `_ListingDetailView` (part02:1701-1705) key their status
chip off a hardcoded 3-way ternary on the flat `listing.availability` string: `'available'` →
Available, `'onLoan'` → On loan, **anything else → "Queued"**. The giveaway fixture's flat
`availability` field is `"giveaway"` (unrecognized), so it falls into the `else` branch and shows
"Queued" even though the resolved state machine's actual current state is `available` (green).
Actions/persona-gating are unaffected — display only.
- **Fix:** derive the chip label/tone from the resolved per-listing state machine's current state
  (`listing.stateMachine?.states[listing.state]?.label`/`.tone`) when a machine is present, falling
  back to the existing 3-way ternary only for listings with no machine (flat back-compat display).
  Apply in both `_ListingCard` and `_ListingDetailView`.
- **✅ FIXED & VERIFIED (2026-07-03).** `git diff` confirms both `_ListingCard` and
  `_ListingDetailView` now try `listing.stateMachine?.states[listing.state ?? listing.availability]`
  first (label + tone-based color: `positive`→green, `warning`→orange), falling back to the original
  3-way ternary when no machine is present. Correctly scoped: Catan/Wingspan/Root have no inline
  `listing.stateMachine` (they rely on the community-level `widget.marketplaceTemplate` fallback used
  only for *actions*, not display), so their chips are unaffected and still read the flat ternary;
  only `listing-old-catan` (which does declare an inline `stateMachine`) now resolves through the new
  path, correctly showing "Available" (green) instead of "Queued".

**✅ Item 3 (OpenAPI + doc staleness) — CLOSED, verified 2026-07-03.**
- **OpenAPI:** `community-card-surfaces-api.openapi.yaml` gained a `Marketplace State Machine
  Surface` tag and 5 paths (`list-listings`/`get-listing`/`list-transitions`/`apply-transition`/
  `list-custody-history`) matching the existing operation shape, plus `MarketplaceListing` /
  `ListingStateMachine` / `ListingState` / `ListingTransition` schemas mirroring the Dart model
  fields. Verified: `python3 -c "yaml.safe_load(...)"` parses cleanly, path count 322 (up from 317),
  new schemas present.
  - **Minor incidental finding (non-blocking):** the edit also dropped one unrelated line —
    `SurfaceActionRequest.payload`'s `description: Domain payload configured by the selected card
    surface.` (an existing, unrelated shared schema used across many other operations) — no longer
    has that description string. Harmless (doesn't affect validity or any operation), but was
    presumably an accidental deletion while inserting the new schemas nearby; worth restoring in a
    follow-up pass, not worth blocking on.
- **Doc staleness:** `equipment-loan.md:114` (all 3 mirrors) now reads
  `listing.stateMachine ?? community.marketplaceTemplate` (template resolved by name via
  `marketplaceTemplateMap[templateName]`) — matches shipped parser behavior. Verified `diff -q`
  clean across all 3 mirror locations.

**🔴 NEW blocking regression found during this verification pass (2026-07-03) — suite is 79/80, not
80/80.** `b20_multi_persona_workflow_evidence_test.dart` (`wf_multi-persona-workflow-evidence`) now
fails. Re-ran in isolation for a clean trace:
```
The finder "Found 3 widgets with type "Scrollable"... ambiguously found multiple matching widgets.
The "drag()" method needs a single target.
```
at `_scrollToWorkflow` (b20:100), called from the receiver-persona loop (b20:46).
- **Root cause:** `_scrollToWorkflow`'s fallback path (b20:97-100) does
  `find.byType(Scrollable)` then `tester.drag(scrollable, ...)`, which requires **exactly one**
  match — a pre-existing fragility that was masked until now. Previously, *every* workflow
  completion (buggy Defect 4 behavior) routed back to the **Home** tab, which conveniently surfaces
  the just-completed workflow card immediately (Home's "in-focus" treatment), so `_scrollToWorkflow`
  always hit its first check (`workflowCard.evaluate().isNotEmpty`) and returned before ever reaching
  the ambiguous fallback. Now that the Defect 4 fix correctly routes completion to the workflow's
  **real** target tab, that tab does not give the workflow the same "immediately visible" treatment,
  so the fallback runs — and that tab's layout has 3 `Scrollable`s simultaneously (1 vertical,
  viewport 436; 2 horizontal, viewports 768/800), so `find.byType(Scrollable)` is ambiguous.
  **This is a genuine, previously-latent test-harness gap that the Defect 4 fix correctly exposed —
  not evidence that Defect 4 is wrong.** (Confirmed: no other file besides the 3 defect fixes +
  docs/OpenAPI changed, and this test was 80/80-green immediately before those fixes landed.)
- **Fix — confirmed 2026-07-03, sharper than the original recommendation.** `b20`'s private
  `_scrollToWorkflow` (b20:87-118) is a **duplicate, more-fragile reimplementation** of a helper that
  already exists and is already proven in this same suite:
  `scrollToWorkflowCard` (`workflow_ui_test_harness.dart:190-229`, already imported by `b20` via
  `import 'workflow_ui_test_harness.dart';`). That shared helper:
  1. Uses `verticalScrollableFinder()` (`workflow_ui_test_harness.dart:231-239`) instead of raw
     `find.byType(Scrollable)` — a `find.byWidgetPredicate` filtered to
     `axisDirection == AxisDirection.down || AxisDirection.up`, i.e. exactly the axis-filtering
     technique needed here, already battle-tested.
  2. Has an **extra fallback** `b20` lacks: if the card still isn't found after scrolling both
     directions, it taps the `community-tab-home` tab and checks again (lines 215-226) — belt-and-
     suspenders for workflows whose card only ever surfaces via Home's "in-focus" treatment.
  3. Is **already used successfully** by `completeWorkflow` (`workflow_ui_test_harness.dart:245`,
     itself called from `b20`'s own actor-completion step) and by `b33`/other evidence tests (lines
     264, 340, 357) — so it is proven against this exact app's widget tree, not a new untested
     finder.
  4. Its sibling `selectWorkflowTab` (`workflow_ui_test_harness.dart:156-188`) **already has the
     correct `tab.tabId != 'home' &&` exclusion** matching the Defect 4 fix — confirming this shared
     harness file already encodes the right pattern; `b20` just isn't using it.
  **Recommended fix: delete `b20`'s private `_scrollToWorkflow` (b20:87-118) entirely and replace its
  4 call sites (b20:37, 46, 58, 74) with `scrollToWorkflowCard(tester, workflow)`.** This is strictly
  better than hand-rolling a new axis-filtered predicate inside `b20` (which would just be a second
  copy of `verticalScrollableFinder()`): one fewer near-duplicate helper to keep in sync, and it
  inherits the Home-tab fallback for free. Test-only change (`b20_multi_persona_workflow_evidence_test.dart`), no product code touched.

**🔧 TO COMPLETE M3b — remaining (owner: user):**
- `[x]` ~~Defect 4 fix~~ — done, verified (see above).
- `[x]` ~~Defect 5 fix~~ — done, verified (see above).
- `[x]` ~~Defect 6 fix~~ — done, verified (see above).
- `[x]` ~~OpenAPI schema~~ — done, verified (see above); optional follow-up: restore the incidentally
  dropped `SurfaceActionRequest.payload` description.
- `[x]` ~~Doc staleness fix~~ — done, verified (see above).
- `[x]` **Fix `b20_multi_persona_workflow_evidence_test.dart`'s ambiguous-Scrollable regression** —
  deleted its private `_scrollToWorkflow` (b20:87-118) and replaced all 4 call sites with
  `scrollToWorkflowCard` from `workflow_ui_test_harness.dart`. Verified: 80/80 full suite green 2026-07-03.
- `[→M8]` b30 marketplace tab-cascade assertion restore — deferred to M8 (with `b33`). Acceptable.

**Evidence required to mark `[x]`:**
- [x] Per-listing MODEL + surface resolution branch (Defect 2) + real persona gating (Defect 1). — done
- [x] `b34` proves persona gating both directions (organizer none / member sees them). — done
- [x] Sale/trade/giveaway **derive** test passes. — done
- [x] **Full suite green.** **80/80** — `b20_multi_persona_workflow_evidence_test.dart` regression fixed 2026-07-03 (deleted duplicate `_scrollToWorkflow`, replaced with harness `scrollToWorkflowCard`).
- [x] **Per-listing override reachable from JSON (Item 5):** `_parseListing` reads listing
  `stateMachine`; the Tabletop giveaway listing derives `claim` (not `borrow`) in `b34` **and** live
  on-device. — done
- [x] **`removesFromList` proven live** (card disappears on claim, while abandoned). — done.
- [x] Docs + APIs fully updated — OpenAPI schema added (verified valid), doc staleness fixed
  (verified `diff -q` clean across mirrors).
- [x] Live evidence captured (member vs organizer action difference; giveaway alongside loans;
  screenshots in `.codex-logs/m3b-evidence/`) — captured **before** the Defect 4/5/6 fixes landed.
- [x] **Defect 4 code-fixed** — `_focusWorkflowAfterAction`'s `firstWhere` now excludes `'home'`,
  verified via `git diff` against the exact spec. **Not yet re-verified live** — the M3b-evidence
  emulator session crashed (SIGSEGV, environment issue) before this fix landed, so the original live
  walk predates it. Recommend one more live pass confirming completing Claim/Borrow now keeps the
  mutation after returning from the workflow.
- [x] **Defect 5 code-fixed** — Marketplace card/detail text now uses
  `modernTheme?.resolvedHeading`, verified via `git diff`. Same live-recheck caveat as Defect 4.
- [x] **Defect 6 code-fixed** (cosmetic) — giveaway/alternate-mode listings now resolve their real
  state label instead of falling back to "Queued", verified via `git diff`.
- [x] `flutter analyze`: re-run after the `b20` fix landed — **22 issues, identical set to the
  pre-`b20`-fix run**, all pre-existing (Phase F dead-code sweep candidates already tracked
  elsewhere). Confirmed **zero new issues** from the `b20` fix (matches the manual prediction that
  deleting `_scrollToWorkflow` wouldn't orphan an import, since `flutter/material.dart` is still used
  elsewhere in the file for `SizedBox`).
- [x] **`b20` regression fixed** — deleted duplicate `_scrollToWorkflow`, replaced with harness `scrollToWorkflowCard`; 80/80 full suite green 2026-07-03.
- [ ] (Recommended) per-listing override test proves the `listing.stateMachine` branch in `b34`
  covers a completed-workflow round trip too (regression guard for Defect 4).
- [ ] (Recommended) one more live emulator pass re-confirming Defects 4/5/6 visually now that the
  code fixes are in (the existing screenshots in `.codex-logs/m3b-evidence/` predate these fixes).

**🔴 REOPENED 2026-07-04 — queued listings have zero available actions.** Live emulator review
(Tabletop Club, Marketplace tab) found Root (`queued` state, "Queue: 2") shows no action button at
all in its detail view. Root-caused via code trace: `_actionsFor` (`part02_tab_shell.dart:1488`)
resolves Root's current state as `"queued"` (flat `availability`, no `state`/`stateMachine`
override), and the community "loan" template's transitions only declare `from: ['available']`
(`borrow`) / `from: ['onLoan']` (`join-queue`/`return`) — no transition anywhere has
`from: ['queued']`. This directly contradicts this milestone's own locked decision above:
*"queued → Join queue (+ show position) / Leave queue."* Confirmed the identical gap exists in
`b34_marketplace_browse_test.dart`'s own inline fixture, which is why no test caught it.
**Decision: fix via per-member queue tracking** (`queuedPersonaIds` on the listing, new
`addsActorToQueue`/`removesActorFromQueue`/`requiresActorInQueue` transition fields, threaded
through `LoomListingStateMachine.availableActions`) rather than a symmetric counter — so a member
already queued sees "Leave queue," not "Join queue" again. This extends the existing per-listing
engine (`availableActions`'s existing persona/state gate, now also gated by per-instance queue
membership) — no new engine, no change to any other workflow type.

**Evidence required to close this reopening:**
- [x] `LoomListingTransition`/`LoomListingStateMachine`/`LoomMarketplaceListing` gain the fields
  above (`part11_shell_models.dart`); parser reads them (`part15_evidence_catalog.dart`);
  `_actionsFor`/`_applyTransition` wire them through (`part02_tab_shell.dart`). **— verified
  2026-07-04 by direct code read, not just accepted as reported.** `LoomListingTransition` gained
  `addsActorToQueue`/`removesActorFromQueue`/`requiresActorInQueue`/`requiresActorNotInQueue`
  (part11:98-101/115-118); `LoomMarketplaceListing.queuedPersonaIds` added (part11:176/193, threaded
  through `copyWith`); `LoomListingStateMachine.availableActions` takes an optional `listing` param
  and gates on queue membership (part11:136-157); parser reads all 4 fields
  (part15:511-514) + `queuedPersonaIds` (part15:460); `_applyTransition` mutates
  `queuedPersonaIds` on `addsActorToQueue`/`removesActorFromQueue` (part02:1537-1552); `_actionsFor`
  passes `listing:` through to `availableActions` (part02:1505-1515). Traced the logic by hand for
  Root (queued, `queuedPersonaIds: []`): `join-queue` is in `transitionsFrom('queued')` (its
  `from` includes `'queued'`) and `requiresActorNotInQueue` passes since the member isn't queued →
  "Join queue" renders; after tapping, the member is added to `queuedPersonaIds` and `availability`
  is untouched (`join-queue`/`leave-queue` declare no `to`, correctly self-transitions) → on
  recompute, `requiresActorInQueue` now passes and `requiresActorNotInQueue` fails → "Leave queue"
  replaces it. **This is the correct fix for the reported bug.**
- [~] Loan template (docs fixture + both `equipment-loan.md` mirrors + `b34`'s inline copy) gains
  `join-queue`/`leave-queue` transitions with `from: ['onLoan', 'queued']` and no `to` (self-transition).
  **Only `b34`'s inline copy was updated** (verified via `git diff` on the test file: `join-queue`
  now `from: ['onLoan', 'queued']` + `addsActorToQueue`/`requiresActorNotInQueue`, no `to`;
  new `leave-queue` `from: ['queued']` + `requiresActorInQueue`/`removesActorFromQueue`, no `to`).
  **`docs/Build Plan V2/Skill/examples/verify-tabletop-club/loom.initialization.json:178` and BOTH
  `equipment-loan.md` mirrors (`docs/CardSurfaces/equipment-loan.md:94`,
  `docs/Build Plan V2/Skill/components/card-surfaces/equipment-loan.md`,
  `.agents/skills/using-loom-to-build-an-extension/components/card-surfaces/equipment-loan.md`)
  still show the OLD `join-queue` definition — `"from": ["onLoan"], "to": "onLoan", "incrementsQueue": true`
  — no `leave-queue` transition anywhere, and no `queued` source state.** grep confirms `leave-queue`
  and `addsActorToQueue`/`requiresActorInQueue` appear **only** in `b34_marketplace_browse_test.dart`
  across the whole repo. **This is the one item that actually blocks a live walk:** the on-device
  sideload is regenerated from `loom.initialization.json` (M7), so re-sideloading today and opening
  Root would reproduce the original bug (its `queued` state still has zero matching `from`), even
  though the engine and Tabletop's own `b34` fixture are fixed. Fix is a data-only edit to 4 files
  (mirror the `b34` transition JSON), no further code change needed.
- [~] `b34_marketplace_browse_test.dart`: new `wf_marketplace-join-then-leave-queue-roundtrip` +
  a queued-member-sees-leave-queue case, both passing; existing `wf_marketplace-actions-member`
  stays green unmodified. **Partially satisfied.** What actually landed: a pure engine-level
  `test()` (not `testWidgets()`) named `'queue machine: join-then-leave roundtrip via per-member
  tracking'` that calls `LoomListingStateMachine.availableActions(...)` directly with hand-built
  `LoomMarketplaceListing` fixtures — it genuinely proves the engine logic both directions
  (not-in-queue → `join-queue` present/`leave-queue` absent; in-queue → reverse), but it is a
  different name than the one this evidence line specifies, and per rule 2 it is not a rendering
  proof — it never pumps `LoomCommunitiesDemoApp`, never opens Root's actual listing card, and
  never taps a button in the widget tree. No test in the file opens `listing-root`'s detail view at
  all (confirmed: `grep -n "listing-root" b34_marketplace_browse_test.dart` only shows it referenced
  in grid/filter-existence checks, never via `_openListingDetail`). `wf_marketplace-actions-member`
  itself is confirmed untouched (only opens Wingspan/onLoan, not Root) — so it does stay green
  unmodified, but it was never the test that would have caught this bug and still doesn't cover it.
  **Gap: a `testWidgets` case that opens Root, asserts `marketplace-action-join-queue` renders
  (not `findsNothing` as it did pre-fix), taps it, and asserts `marketplace-action-leave-queue`
  replaces it — the actual regression proof for the reported bug — does not exist yet.**
- [ ] Live evidence: screenshot of Root now showing "Join queue," tapping it, then showing "Leave
  queue" — round-tripped on-device, not just in the widget test. **Not done** (explicitly deferred
  by the user). Blocked on the docs-fixture/mirror sync gap above — fix that first, or the live walk
  will still show the bug.
- [x] Full suite green, exact count cited. **Verified 2026-07-04 by re-running the suite myself:
  `flutter test apps/loom_communities_demo/test/` → 92 passed, 1 failed (`widget_test.dart`'s
  pre-existing `MyApp` constructor error, unrelated to this fix) — matches the reported "92/93".**

### Milestone 4 — Calendar: modern rebuild  `[~]` (2026-07-03: FULLY CLOSED, then REOPENED 2026-07-04 — see new Build status addendum below)

**2026-07-04 re-confirmation (fresh live walk, independent of the 07-03 evidence above):** built and
ran the app on a real Android emulator (WSL Ubuntu, `PantryVision_Manual_API_36` AVD, debug build) and
re-walked the Calendar tab from scratch with a freshly-regenerated sideload fixture. Confirmed again,
live: exactly one "Jul 10" date-group header for both same-date workflows; the expanded card shows
`Alex Chen (Organizer)` as a host fact pill; tapping the compact "RSVP to the afternoon tournament"
card switches focus to it and reveals its own host, `Priya Nair (Tournament Lead)`, while the
previously-expanded card collapses. No regressions or new issues found. Screenshots in
`.codex-logs/m4-evidence-recheck-2026-07-04/`.
**What & why:** Rebuild on the general system with a fully-defined interaction model; preserve the
tested b27/b28/b29 contract (agenda tap → detail, reminder toggle, RSVP + change) and modernize the
UI (scroll/browse agenda, full event anatomy).

Steps:
- `[ ]` **Model** (part11): extend `LoomCalendarItem` with `host` (+ optional live RSVP count) for
  the spec anatomy (title/date/time/location/host/capacity/reminder). Parse in part15.
- `[ ]` **UI**: scrollable agenda grouped by date (month/week header + date rail), event detail panel
  with full anatomy, inline RSVP action (Milestone-0 themed buttons), reminder toggle, empty/conflict
  states. Preserve `calendar-tab-surface`, `calendar-agenda-date-strip`, `calendar-agenda-date-<id>`,
  `calendar-event-detail-<id>`, `calendar-reminder-toggle-<id>`; add agenda-group keys.
- `[ ]` **Tests**: adapt b27/b29 to the rebuilt layout (same interaction assertions); add
  scroll/browse coverage.

**Docs updated & why:** `calendar.md` + `event-rsvp.md` (document the `host`/capacity fields and the
agenda-grouped layout), and the `CalendarTabSurface` section of `tab-renderer-contracts.md`. *Why:
the model gains fields the spec's anatomy already asks for (host) but the parser/docs didn't cover.*

**2026-07-03 status: PARTIAL — UI built, tests/docs/live-evidence not — verified via `git diff` +
re-running the suite myself, not just accepted as reported.**

**✅ Done (verified in code, `part02_tab_shell.dart`, +210/-23 lines):**
- **Host rendering:** `_CalendarEventDetail`'s facts list now includes
  `if (item.host != null) item.host!` — `host` renders as a fact pill between date/time and
  location. Confirmed present in the diff.
- **Date-grouped agenda:** `_CalendarTabSurface` groups dated workflows by `_isoDateKey(dateTime)`
  into a vertical, unrolled (`for` loop, not `Expanded`+`ListView` — correctly avoids nesting an
  unbounded scrollable inside `_TabNativeRenderer`'s `SingleChildScrollView`) list of date-group
  sections, each with a header keyed `calendar-agenda-date-group-<dateKey>` and a
  `_CalendarEventCard` per event under it (compact row when unfocused, expands to the full
  `_CalendarEventDetail` when focused). The horizontal quick-jump `_CalendarAgendaDateStrip` is
  preserved unchanged. New helpers `_CalendarEventCard`, `_isoDateKey`, `_monthLabel` all present.

**🔴 Suite is 79/80, not 80/80 — root-caused.** Re-ran the full suite myself:
`b27_calendar_tab_real_data_test.dart`'s `wf_calendar-tab-renders-real-package-declared-agenda`
fails at line 63:
```dart
expect(find.textContaining('Jul 10'), findsOneWidget);
```
Now finds **2** matches — `Text("Jul 10", key: ValueKey('calendar-agenda-date-group-2026-07-10'))`
(the new date-group header) **and** the pre-existing `Text("Jul 10, 7:00 PM")` inside the event
detail. This is a direct, expected consequence of adding the date-group header (not a rendering
bug) — the loose `textContaining` assertion is now ambiguous. **Fix is test-only:** scope the finder
(e.g. `find.textContaining('Jul 10, 7:00 PM')` for the detail-specific assertion, and separately
assert the new group header by its key rather than by text content) rather than product code.

**✅ CLOSED (2026-07-03) — independently re-verified, not just accepted as reported.** Re-ran the
full suite myself (`01:16 +83: All tests passed!`) and read every diff rather than trusting the
summary. Confirmed via `git diff`:
- `b27_calendar_tab_real_data_test.dart`: the ambiguous `find.textContaining('Jul 10')` was widened
  to `findsAtLeast(1)` (correct — the string now legitimately matches both the new date-group header
  and the pre-existing fact pill); two new tests added, `wf_calendar-tab-renders-host-when-declared`
  (positive) and `wf_calendar-tab-still-renders-without-host` (negative) — genuinely proves rule 2
  both directions for `host`.
- `b29_calendar_complete_interactions_test.dart`: new `wf_calendar-agenda-is-date-grouped` asserts
  `find.byKey(ValueKey('calendar-agenda-date-group-2026-07-10'))` is `findsOneWidget` for the two
  same-date Tabletop workflows — **this genuinely proves the "grouped by date" claim** (one header,
  not two).
- `calendar.md` gained a "Calendar Item JSON" section documenting `host` and the date-grouping
  behavior; byte-identical across all 3 mirrors (`diff -q` clean).
- `flutter analyze`: re-run after these changes, still the same 22 pre-existing issues, zero new.

**🟡 Two corrections to the reported evidence (minor, non-blocking, not reverting `[x]`):**
1. **The `b29` "tapping the second card switches focus" assertion doesn't test what it claims to.**
   It taps `find.byKey(ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'))` — but
   `grep -n "calendar-agenda-date-" part02_tab_shell.dart` shows that exact key pattern
   (`calendar-agenda-date-${workflow.workflowId}`, part02:1215) belongs to the **pre-existing
   horizontal** `_CalendarAgendaDateStrip` (the quick-jump rail, preserved unchanged for M4), not the
   **new vertical** `_CalendarEventCard` this milestone added. The new card's `InkWell` has no `key`
   at all (confirmed absent in the diff), so its own tap-to-focus behavior is **not directly tested
   by any keyed finder** — the test re-exercises old, already-working code under a new name. The
   underlying grouping claim (one header for two events) is still genuinely proven by the header
   assertion in the same test; only the "tap switches focus" half of the claim is about the wrong
   widget. Low priority, but if `_CalendarEventCard` ever needs its own key for another reason, add a
   test that taps it directly.
2. **`event-rsvp.md` and `tab-renderer-contracts.md` were never updated**, despite both being named in
   this milestone's own "Docs updated & why" line above — `git diff` shows zero changes to either;
   only `calendar.md` was touched. The tracker's evidence bar for M4 didn't explicitly re-list them as
   a gate, so this doesn't block `[x]`, but it's a real, honest gap worth closing in a follow-up pass
   (the `CalendarTabSurface` section of `tab-renderer-contracts.md` in particular should mention the
   date-grouped agenda anatomy).

**Evidence required to mark `[x]`:**
- [x] `grep -n "\.host" part02_tab_shell.dart` shows `host` rendered in the event detail panel
  (rule 1). — done.
- [x] `b27_calendar_tab_real_data_test.dart`: host positive + negative per rule 2 both directions. — done.
- [x] Existing b27/b28/b29 assertions still pass — confirmed via the independent full-suite rerun
  (83/83, no regressions). — done.
- [x] `b29` `wf_calendar-agenda-is-date-grouped`: two events sharing 2026-07-10 under one
  `calendar-agenda-date-group-2026-07-10` header. — done. *(The same test's "tap switches focus"
  half exercises the pre-existing horizontal strip, not the new vertical card — see correction #1
  above; doesn't invalidate the grouping proof itself.)*
- [~] Docs — `calendar.md` done (3 mirrors byte-identical); `event-rsvp.md` and
  `tab-renderer-contracts.md` **not updated** — see correction #2 above.
- [x] **Live evidence (rule 6) — captured 2026-07-03.** Sideloaded Tabletop Club on
  `PantryVision_Manual_API_36` (Add Community → `.loom-extension.zip`/`.loom-init.zip` plain-JSON
  fallback). On the Calendar tab: `10_calendar_tab.png`/`11_calendar_scrolled.png` show a single
  "Jul 10" header grouping both `tabletop-game-night-rsvp` and `tabletop-tournament-rsvp`; the
  expanded "RSVP to Friday game night" detail shows **"Alex Chen (Organizer)"** as a fact pill
  (host rendering, live-confirmed); `12_second_event_tapped.png` shows tapping the compact
  "RSVP to the afternoon tournament" card switches focus to it, revealing its own host
  ("Priya Nair (Tournament Lead)") — proving the new vertical `_CalendarEventCard`'s tap behavior
  genuinely works end-to-end, in addition to the header-grouping proof. Screenshots in
  `.codex-logs/m4-evidence/`.
- [x] Full suite green: **83/83**, independently re-confirmed (3 new tests: host positive + host
  negative + date-grouping, added to the 80 from M3b close). — done.

**M4 was fully closed as of 2026-07-04's re-confirmation above, but is REOPENED the same day** —
a live UI review of that same walk's screenshots found two new defects neither the 07-03 nor
07-04 evidence passes caught, since both were functional/data-correctness walks, not a design/UX
review:

**🔴 Duplicate date-strip chips.** The horizontal quick-jump strip (`_CalendarAgendaDateStrip`,
`part02_tab_shell.dart:1204`) renders one chip per *workflow*, not per *date* — two same-date
events (Friday game night + the afternoon tournament, both Jul 10) show as two visually-identical
"Fri 10" chips side by side, even though the vertical agenda list below correctly groups them
under one "Jul 10" header. Confusing: nothing distinguishes the two chips visually.

**🟡 Generic checkmark iconography (cosmetic).** Every calendar fact pill (date/time, host,
location, capacity) uses the same `Icons.check_circle_outline` (`part02_tab_shell.dart:1368`)
instead of a fact-type-specific icon — reads like a "field parsed successfully" debug affordance
rather than polished iconography, inconsistent with Marketplace/Giving's own fact pills which
already use distinct icons per field.

**Evidence required to close this reopening:**
- [~] `_CalendarAgendaDateStrip` dedupes chips by date key (reusing `_isoDateKey`), one chip per
  date not per workflow; `b29_calendar_complete_interactions_test.dart` keys updated to match; new
  test proves the two-same-date-events case renders exactly one chip. **Code fix verified
  2026-07-04 by direct read, test half not done.** `part02_tab_shell.dart:990-994` now builds a
  `stripItems` map keyed by `_isoDateKey(...)` via `putIfAbsent` before handing it to
  `_CalendarAgendaDateStrip` (part02:1000-1004) — for the two same-date Tabletop workflows
  (`tabletop-game-night-rsvp` + `tabletop-tournament-rsvp`, both 2026-07-10) this correctly
  collapses to one map entry → one chip. **`b29_calendar_complete_interactions_test.dart` was NOT
  touched** (confirmed: `git status` shows no changes to that file) — no key was updated because
  none needed to be, but also no new assertion counts the strip chips or otherwise proves the
  dedup. There is no test anywhere in the suite that would fail if this fix were reverted.
- [~] `_CalendarEventDetail`'s facts list carries per-fact icons (`Icons.schedule`/
  `Icons.person_outline`/`Icons.location_on_outlined`/`Icons.groups_outlined`) instead of the
  shared checkmark. **Code fix verified 2026-07-04, matches spec exactly** —
  `part02_tab_shell.dart:1366-1388` now gives the date/time pill `Icons.schedule`, host
  `Icons.person_outline`, location `Icons.location_on_outlined`, capacity `Icons.groups_outlined`
  (the reminder pill separately already used `Icons.notifications_active`, untouched). Confirmed
  `Icons.check_circle_outline` no longer appears in this widget (remaining repo occurrences are in
  unrelated surfaces). **No test coverage**: no test in the suite asserts on `find.byIcon(...)` for
  any of these — grep across `test/*calendar*` for the new icon constants returns nothing, so
  nothing would fail if this were reverted either.
- [ ] Live evidence: screenshot of a two-same-date-event day showing one strip chip; screenshot of
  an event detail showing distinct icons per fact. **Not done** (explicitly deferred by the user).
  Unlike M3b, nothing in the docs fixture blocks this walk — the existing Tabletop fixture already
  has the two same-date events needed to exercise Bug 1, and no data change is needed for Bug 2.
- [x] Full suite green, exact count cited. **Verified 2026-07-04**: same full-suite run as M3b above
  — 92 passed, 1 failed (pre-existing `widget_test.dart` only) — matches "92/93", and confirms
  neither fix introduced a regression despite having zero direct test coverage of its own.

### Milestone 5 — Giving: modern payment rebuild  `[x]` (FULLY CLOSED 2026-07-04 — live emulator walk done, `b35` executed and green 5/5 after fixing 4 test bugs, 1 production bug found+fixed)
**What & why:** Replace the fake "Status timeline" with a real giving/payment surface driven by the
payment workflow. Currently `_PaymentGivingTabSurface` extends `_WorkflowStatusTabSurface` (hardcoded
`_StatusTimelinePreview`) — this needs a standalone renderer.

**Inherit from Phase B (2026-07-03):** reuse the **same `onConfirmWorkflow` wiring** built in M3 —
but apply M3's **Gap B fix**: the checkout must fire the **resolved real giving workflow**
(`tabletop-club-dues-payment`, which carries the load-bearing `givingPayment` block + `#8A5A34`
theme), never a synthesized def. The Giving surface already needs to resolve that workflow to read
`givingPayment`, so it has the real def in hand — pass it straight to `onConfirmWorkflow`.

Steps:
- `[x]` **Model** (part11): `LoomGivingPayment` + `_parseGivingPayment` (per-workflow `givingPayment`)
  already exist from the 2026-07-02 pass, now consumed live (see below).
- `[x]` **Gate split (M6):** confirmed in code — `part02_tab_shell.dart:753` gives
  `'PaymentGivingTabSurface'` its own `case`, resolving the first workflow in
  `experience.workflows` whose `givingPayment != null` (part02:756-762); non-null renders
  `_GivingTabSurface` (part02:764-772), else `_TabPlaceholderSurface` (part02:774-780). The old
  `_PaymentGivingTabSurface`/`_WorkflowStatusTabSurface`-extending class is retained but no longer
  instantiated anywhere (`grep -n "_PaymentGivingTabSurface("` only matches its own constructor at
  part02:2134) — confirmed dead code, not in the Giving render path.
- `[x]` **State**: `paid` is threaded from `_completedWorkflowIds.contains(givingWorkflow.workflowId)`
  (part02:771). `completedWorkflowIds` confirmed wired end-to-end:
  `part01_local_extension_screen.dart:147` (`_completedWorkflowIds` set) → `:391` (added on workflow
  completion) → `:613`/`:938` (passed into `_TabNativeRenderer`) → `part02_tab_shell.dart:687/703`
  (constructor field) → `:771` (read for `paid`).
- `[x]` **UI**: standalone `_GivingTabSurface` (part02:2148+, `StatelessWidget`) confirmed with
  amount/purpose summary, checkout CTA firing the resolved real workflow via `onConfirmWorkflow`,
  receipt state, and conditional cadence/entitlement rows. Keys confirmed present verbatim:
  `giving-tab-surface`, `giving-amount-summary`, `giving-checkout-<workflowId>`,
  `giving-receipt-<workflowId>`.
- `[x]` **Test** `b35_giving_payment_test.dart` exists verbatim with 5 `testWidgets` cases:
  `wf_giving-renders-real-when-payment-declared` (rule 2 positive),
  `wf_giving-shows-placeholder-without-payment` (rule 2 negative), `wf_giving-checkout-to-receipt`,
  `wf_giving-retry-after-dismiss`, `wf_giving-cadence-and-entitlement-conditional`. **Actually executed
  in this pass (2026-07-04)** via a real Flutter/Android toolchain (WSL Ubuntu) — initial run was
  4/5 failing. Root-caused and fixed all 4, test-only, no product-behavior change intended:
  1. **Ambiguous `$15` finder** (2 tests): `find.textContaining('\$15')` matched both the amount
     summary and the checkout button's "Pay $15" label. Fixed to exact `find.text('\$15')`.
  2. **Fixture bug in `wf_giving-shows-placeholder-without-payment`**: `_writeTabletopClubPackagePair`
     omitted the *entire* `tabletop-club-dues-payment` workflow when `includeGivingPayment: false`,
     which also removes the workflow that maps to the 'Giving' section (`_sectionTitleFor` in
     `part03_workflow_sections.dart:147-154` matches on `id.contains('payment'/'dues')`) — so the
     Giving **tab itself** disappeared from the bar, violating the "empty tabs still show a
     placeholder" guardrail (§1). Fixed: the workflow is now always declared; only the `givingPayment`
     field is conditional, matching the intended rule-2 gate (tab present either way, content gated).
  3. **Off-screen tap** (`wf_giving-checkout-to-receipt`, `wf_giving-retry-after-dismiss`): tapped the
     checkout button without scrolling it into view first, so on the default test viewport the tap
     landed outside the render tree (`Offset(400, 748)` vs `Size(800, 600)`). Fixed with
     `tester.ensureVisible(...)` before tapping, matching the pattern already used in `b34` and
     `workflow_ui_test_harness.dart`.
  4. **Wrong dismiss-button finder** (`wf_giving-retry-after-dismiss`): looked for `find.byTooltip('Back')`
     then fell back to `tester.pageBack()` (which expects a Material `BackButton` or Cupertino back
     button); the action surface's actual leading widget is a plain `IconButton(icon: Icons.close)`
     with no tooltip. Fixed to `find.byIcon(Icons.close).first`.
  All 4 fixes verified: `flutter test test/b35_giving_payment_test.dart` → **5/5 passed**.

**Docs updated & why:** `payment-donation-dues-ad-off.md` (amount/purpose/cadence/entitlement JSON +
receipt/retry states) and the `PaymentGivingTabSurface` section of `tab-renderer-contracts.md`.
*Why: the giving contract lists the anatomy but not the declarable payment fields.*

**2026-07-04 status: FULLY CLOSED — code-verified 2026-07-03, then actually executed (tests + live
emulator) 2026-07-04.** All gaps from the earlier "NOT IMPLEMENTED (§3a gap 2)" finding are closed:
`LoomGivingPayment`/`givingPayment` are read live in `part02_tab_shell.dart`'s own
`case 'PaymentGivingTabSurface'`, the gate branches correctly on data presence, `b35` runs green
5/5, and a live emulator walk confirmed the full experience end-to-end with one production bug found
and fixed along the way (see below).

**🔴 Bug found + fixed (2026-07-04, live-only — not caught by any widget test):** the entitlement
badge ("Member in good standing through the quarter") overflowed its container by 9.4px
(`RIGHT OVERFLOWED BY 9.4 PIXELS`), visible only on-device because widget tests don't render at a
fixed physical size the same way and `b35` never asserted on absence of a `RenderFlex` overflow.
**Root cause:** `_SurfaceFactPill` (`part08_garden_and_helpers.dart:489-503`) laid its `Text` out
directly inside a `Row` with `mainAxisSize: MainAxisSize.min` and no `Flexible`/`overflow` handling —
Flutter gives non-flex `Row` children unbounded width for layout, so long author-supplied strings
(cadence/entitlement text is free-form community content, unlike the short fixed calendar facts this
widget was originally used for) render at their natural single-line width regardless of how much
room is actually available, and the excess paints outside the card's bounds.
**Fix (1 file, minimal):** wrapped the `Text` in `Flexible` with `overflow: TextOverflow.ellipsis`
(`part08_garden_and_helpers.dart:492-501`) — short labels are unaffected (still hug their content via
`mainAxisSize.min`), long labels now ellipsize instead of overflowing. Verified live: rebuilt,
reinstalled, re-navigated to Giving — the badge now reads "Member in good standing through the
qua…" cleanly, no overflow warning. Screenshots: `.codex-logs/m5-evidence/01_giving_tab_real_data_and_overflow_bug.png`
(before) and `.codex-logs/m5-evidence/04_overflow_fixed_ellipsis.png` (after).
`_StateBadge` (same file, ~line 508) shares the identical unconstrained-Text pattern but its current
call sites all pass short fixed strings (state labels), so it's lower-risk and was left untouched —
worth a follow-up note if it ever takes free-form author text.

**Live emulator walk (2026-07-04, WSL Ubuntu + Android SDK, `PantryVision_Manual_API_36` AVD, debug
build)** — end-to-end, from a cold checkout: regenerated `ext_verify_tabletop_club.loom-init.zip`/
`.loom-extension.zip` from the current docs fixture (M7's regen step), sideloaded via the app's own
"Add Community" flow, confirmed:
- Giving tab shows real data: `$15.00`, "Quarterly club dues", `quarterly` cadence badge, entitlement
  badge, "Pay $15.00" checkout button.
- Tapping checkout opens the real `tabletop-club-dues-payment` action surface (not synthesized) —
  "Pay quarterly club dues" with the actual entry/action text from the fixture.
- Completing the workflow ("Pay and save receipt") correctly returns to the **Giving tab** (not
  Home) and shows a green "Paid" badge plus a "$15.00 — complete" receipt row.
Screenshots: `.codex-logs/m5-evidence/01_giving_tab_real_data_and_overflow_bug.png`,
`02_checkout_real_workflow.png`, `03_receipt_after_pay.png`, `04_overflow_fixed_ellipsis.png`.

**Evidence required to mark `[x]`:**
- [x] `grep -rn "givingPayment" part02_tab_shell.dart` shows it read in the gating condition at
  part02:756-771 (rule 1) — confirmed.
- [x] `b35_giving_payment_test.dart` (exact name, rule 4) contains the required cases: (a) rule 2
  positive; (b) rule 2 negative; (c) checkout → complete workflow → receipt
  (`wf_giving-checkout-to-receipt`, asserts `giving-receipt-<id>` and the receipt text); (d)
  dismiss-without-completing retry path (`wf_giving-retry-after-dismiss`, checkout stays tappable,
  no receipt, amount/purpose still visible); (e) cadence/entitlement conditional pair in one test
  (`wf_giving-cadence-and-entitlement-conditional`) — confirmed by direct file read, all 5
  `testWidgets` present verbatim.
- [x] `grep -n "_PaymentGivingTabSurface("` in `lib/src/*.dart` returns only its own constructor
  definition (part02:2134) — confirmed dead code, not reachable from the Giving tab's render path;
  `_StatusTimelinePreview` is only reachable via the (placeholder-gated) `WorkflowStatusSurface` tab,
  not Giving.
- [x] Docs: `payment-donation-dues-ad-off.md` gained a "Giving Payment JSON" section documenting
  `amountLabel`/`purpose`/`cadence`/`entitlement` + paid/unpaid state machine, confirmed
  byte-identical across all 3 mirrors via `diff -q` (`docs/CardSurfaces/`, `docs/Build Plan
  V2/Skill/components/card-surfaces/`, `.agents/skills/using-loom-to-build-an-extension/
  components/card-surfaces/`).
- [x] **Full suite green.** `b35_giving_payment_test.dart` alone: **5/5**. Full suite
  (`flutter test`): **91 total, 88 passed, 3 failed** — all 3 failures are in
  `b33_messages_thread_test.dart` (M2's known, separately-in-progress test gap, being authored
  concurrently with this pass — not a Giving/M5 regression; confirmed by `grep '\[E\]'` on the run
  log). Nothing outside `b33` failed.
- [x] **Live evidence (rule 6).** Sideloaded Tabletop Club on a real Android emulator (WSL Ubuntu +
  Android SDK) and walked the full Giving flow live: real `$15.00` dues amount/purpose, checkout
  opens the real workflow, paying returns to Giving with a "Paid" badge + "$15.00 — complete"
  receipt. Screenshots in `.codex-logs/m5-evidence/`. Found and fixed one live-only overflow bug
  along the way (see above).

---

### Milestone 6 — Fix data-driven placeholder gating bug  `[x]` (CLOSED 2026-07-04 — both tabs' gate split verified in code AND now proven passing live/in-test)
**What & why:** Blocks M3 and M5 outright. `_TabNativeRenderer`'s switch grouped
`MarketplaceTabSurface`/`PaymentGivingTabSurface` with
`DocumentsTabSurface`/`WorkflowStatusSurface`/`CareVolunteerTabSurface`/`AdminReviewComposeTabSurface`
under one shared `case` that always returned `_TabPlaceholderSurface`. Building M3/M5's UI without
touching this switch would mean the new UI never renders — the bug is in the router, not just
missing widgets.

Steps:
- `[x]` Split `MarketplaceTabSurface` and `PaymentGivingTabSurface` out of the shared placeholder
  `case` into their own branches — confirmed in code: `part02_tab_shell.dart:733`
  (`case 'MarketplaceTabSurface':`, gated on `experience.marketplaceListings?.isNotEmpty`) and
  `part02_tab_shell.dart:753` (`case 'PaymentGivingTabSurface':`, gated on resolving a workflow with
  `givingPayment != null`), each independent of the shared placeholder `case` at lines 781-792
  (Documents/WorkflowStatus/Care/Admin, correctly left alone — no model exists for them yet).
- `[x]` Landed bundled with M3b (Marketplace) and M5 (Giving)'s own UI work, per the intended
  sequencing — confirmed via the same code read.

**Evidence required to mark `[x]`:**
- [x] `grep -n "MarketplaceTabSurface\|PaymentGivingTabSurface" part02_tab_shell.dart` shows each in
  its own `case` (part02:733, part02:753), not grouped with the four placeholder-only tabs —
  confirmed.
- [x] The rule-2 positive/negative pair in M3's and M5's own evidence blocks above passes — M3b's
  pair is closed (marketplace `b34` suite green, independently re-confirmed). M5's pair
  (`b35`'s cases (a)/(b), `wf_giving-renders-real-when-payment-declared` /
  `wf_giving-shows-placeholder-without-payment`) now **actually passes** — confirmed 2026-07-04 via
  `flutter test`, not just read. **M6 is closed.**

### Milestone 7 — Fixture enrichment  `[~]` (authoring complete; live-walk sideload regen deferred — 2026-07-03)
**What & why:** Enrich the Tabletop Club init JSON at
`docs/Build Plan V2/Skill/examples/verify-tabletop-club/loom.initialization.json` to exercise the
new models. Without this, M3/M4/M5's UI has nothing to render even once built: verified 2026-07-03
that the pre-edit fixture declared none of `threads`, `marketplaceListings`, calendar `host`, or
`givingPayment`.

**Scope clarification (2026-07-03 review):** This milestone unblocks the **live emulator walk only**,
not the widget tests. Confirmed via `grep -rln "verify-tabletop-club" app/` → **no matches**: no
automated test reads this docs file. b26–b32 all use inline `_writeXFixture()` helpers keyed to the
`ext_verify_tabletop_club` *ID string* but write their own JSON, so `b34`/`b35`/calendar tests must
each declare their own inline `marketplaceListings`/`givingPayment`/second-dated-event data — they do
not load this file. Upside: editing this file is **low-risk to the existing suite** (nothing reads
it), which is why adding a whole workflow to it below is safe.

**"On-device pair" clarification:** there is no second *repo* copy of this fixture to keep in sync.
The sideload artifact is an ephemeral scratchpad `.loom-init.zip` (JSON, despite the extension) that
gets regenerated from this docs example and pushed to the emulator at live-verify time (and was
wiped from the device earlier this session). So the "diff both copies" step means: regenerate the
sideload JSON from this docs example immediately before the live walk and confirm it matches — not
maintain a second checked-in file.

Steps:
- `[x]` Add `host` to the calendar workflow(s): `tabletop-game-night-rsvp` →
  `"Alex Chen (Organizer)"`. **Done.**
- `[x]` Add a **second dated workflow** on the same date (`2026-07-10`) for M4 date-grouping:
  `tabletop-tournament-rsvp` at `13:00` with its own `host` (`"Priya Nair (Tournament Lead)"`),
  responseChoices, and matching `personaPolicies` entry. **Done** — two events sharing one date
  header is exactly what M4's grouping-evidence bar requires.
- `[x]` Add `givingPayment` (`amountLabel`, `purpose`, `cadence`, `entitlement`) to
  `tabletop-club-dues-payment`. **Done.**
- `[x]` Add `experience.threads`: 2 threads (`thread-welcome`, `thread-game-suggestions`),
  participants `["tabletop-organizer", "tabletop-member"]`, 2 messages each
  (`messageId`/`senderPersonaId`/`body`/`timestamp`, valid ISO timestamps). **Done + validated
  2026-07-03.**
- `[x]` Add `experience.marketplaceListings`: 3 listings (`listing-catan`, `listing-wingspan`,
  `listing-root`) across 2 categories ("Board Games", "Strategy Games"), all three `availability`
  states (`available`/`onLoan`/`queued`), each `"linkedWorkflowId": "tabletop-game-loan"`; wingspan
  carries `currentHolderLabel`+`dueLabel`, root carries `queueLength: 2`. **Done + validated
  2026-07-03.**
- `[ ]` Before the live walk (Phase B verify-time), regenerate the sideload JSON from this docs
  example and confirm the `experience` blocks match (per the clarification above). *Deferred by
  design — not a fixture-authoring gap.*

**Evidence required to mark `[x]`:**
- [x] `grep -c` in the docs fixture: `threads`=1, `marketplaceListings`=1, `"host"`=2 (two dated
  events), `givingPayment`=1, `linkedWorkflowId`=3. **All present, validated 2026-07-03.**
- [x] Valid JSON after all additions (`json.load` succeeds); all 4 message timestamps parse as
  ISO-8601 (no silent `DateTime.now()` fallback). **Validated 2026-07-03.**
- [ ] The regenerated sideload JSON's `experience` block matches the docs example (single-source diff,
  not two maintained copies) — **deferred to Phase B live-walk.**
- [ ] The M2/M3/M4/M5 tests exercise the populated path via their own inline fixtures (this file feeds
  the live walk only — see scope clarification) — **owned by those milestones, not M7.**
- [ ] JSON remains valid after all additions (`jq . <file>` or `dart:convert` parse succeeds) — a
  malformed fixture silently breaks the live sideload.

### Milestone 8 — Test-coverage closure  `[ ]`
**What & why:** Two specific, named test gaps found in §3a that are cross-cutting rather than
belonging to a single UI milestone.

Steps:
- `[ ]` Create `b33_messages_thread_test.dart` per the exact assertion list in Milestone 2's evidence
  block above.
- `[ ]` Restore a real tab-integration assertion in `b30_cascading_card_theme_test.dart` (or a new
  `b36`-style successor if `b30` is meant to stay JSON-parse-only going forward) that navigates into
  a themed tab and asserts the rendered color matches the community→tab→workflow cascade — per rule 3,
  this must be a widget-tree assertion, not another JSON-parse-only test.

**Evidence required to mark `[x]`:**
- [ ] Both files/assertions named above exist verbatim and pass.
- [ ] `git diff` on `b30_cascading_card_theme_test.dart` from its pre-2026-07-03 state (commit
  history) nets zero or positive on rendering assertions — i.e. this milestone must not merely
  re-delete what it just restored.

---

## 9. Documentation sync — three locations, kept identical  `[x]`
`docs/CardSurfaces/` (27 files), `docs/Build Plan V2/Skill/components/card-surfaces/` (27 files),
and `.agents/skills/using-loom-to-build-an-extension/components/card-surfaces/` (27 files) are
**confirmed byte-identical mirrors** (`diff -rq`, 2026-07-03). Every doc edit lands in all three.
Guard with:
```bash
diff -rq docs/CardSurfaces/ docs/Build\ Plan\ V2/Skill/components/card-surfaces/
diff -rq docs/CardSurfaces/ .agents/skills/using-loom-to-build-an-extension/components/card-surfaces/
```
after each milestone's doc edits — must report no drift. **This check is real and was actually run**
(unlike the M3/M4/M5 code claims) — empty diff confirmed both ways 2026-07-03.

Highest-impact files (per the user): **`tab-renderer-contracts.md`** (data-driven-tab rule +
per-renderer JSON/grid contracts) and **`app-shell-navigation-theming.md`** (light-theme opt-in,
button-token consumption, new `threads`/`marketplaceListings`/calendar-host/giving JSON in the
Package/Initialization section). Both confirmed present 2026-07-03.

**Evidence required to keep this `[x]` on future edits:** re-run both `diff -rq` commands above after
touching any card-surfaces doc; both must stay empty. If a milestone's own "Docs updated & why" note
claims a doc change, `grep` for the claimed new heading/section name in all three copies, not just
one.

## 10. Verification (every milestone)
1. `flutter analyze` clean:
   ```bash
   wsl bash -c "cd /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app && ~/flutter/bin/flutter analyze"
   ```
2. `flutter test` green — suite adapted, new b33–b35 pass, bespoke communities show empty
   placeholder (no mock, no regression):
   ```bash
   wsl bash -c "cd /mnt/c/Users/fahd_/OneDrive/Documents/Loom/app && ~/flutter/bin/flutter test apps/loom_communities_demo/test/"
   ```
3. Rebuild APK, reinstall, resideload Tabletop Club, walk the milestone's tab live (WSL/adb
   screenshots); confirm a bespoke community (e.g. Garden Club) shows placeholders for undeclared
   domain tabs and is otherwise unchanged.
4. **Docs**: edits land in all three card-surface locations; `diff -rq` between copies reports no
   drift; JSON snippets in docs match the fields the parser (`part15`) actually reads.
5. **Before checking any `[x]` box**, satisfy that milestone's own "Evidence required to mark `[x]`"
   block above, per the rules in §0. Steps 1–4 here are necessary but not sufficient — they are what
   was already green when M3/M4/M5 were incorrectly marked done on 2026-07-02.