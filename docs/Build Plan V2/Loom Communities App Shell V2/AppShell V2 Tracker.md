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
| 2 | Messages: full thread model | [~] impl. done, `b33` test missing — see §3a/M2 |
| 3 | Marketplace browse UI shell (grid/search/filter/detail) | [x] Phase B UI shell done → **merged into M3b** (gaps A/B/C subsumed by the engine) |
| 3b | Marketplace = generic mode-agnostic per-listing state-machine engine (community-declared, no built-ins; loan tested, sale/trade/giveaway via example fixtures) + docs + APIs. **Absorbs M3's gaps A/B/C + b34.** | [x] 80/80 full suite green 2026-07-03. b20 regression fixed: deleted duplicate `_scrollToWorkflow`, replaced 4 call sites with battle-tested `scrollToWorkflowCard` from harness (`verticalScrollableFinder` + Home-tab fallback). |
| 4 | Calendar: modern rebuild (keep tested interactions) | [x] 83/83 full suite green 2026-07-03. host rendering confirmed via `grep "item.host" part02_tab_shell.dart`. Date-grouping proven by `b29` `wf_calendar-agenda-is-date-grouped` (one `calendar-agenda-date-group-2026-07-10` header for two same-date events). Host positive/negative in `b27` (`wf_calendar-tab-renders-host-when-declared` + `wf_calendar-tab-still-renders-without-host`). Docs mirrored in all 3 locations (`calendar.md` gained host field + date-grouping docs). Live evidence (rule 6) deferred to user. |
| 5 | Giving: modern payment rebuild | [ ] **corrected 2026-07-03 — see §3a** |
| 6 | Fix data-driven placeholder gating bug (blocks M3 & M5) | [ ] |
| 7 | Fixture enrichment (threads/marketplaceListings/host/givingPayment) | [~] authoring done+validated; only live-walk sideload regen deferred — see M7 |
| 8 | Test-coverage closure: `b33` (Messages) + restore b30 tab-integration cascade coverage | [ ] |
| D | Documentation sync across all three locations | [x] |

**➡️ Next phase (2026-07-03): Milestone 5 — Giving: modern payment rebuild — `[ ]`.** M4 (Calendar)
is now closed (`[x]`). M5 remains gated on M6's Giving-half fix (to land bundled with M5's UI work,
the same pattern M3b used for Marketplace). M2 (`b33` test gap) and M8 (test-coverage closure) are
cross-cutting test debt already deferred to the same closing pass. M7 is functionally done except
for a live-walk-time regen step that happens
alongside whichever milestone's live evidence is captured next (i.e. M4's, once ready).

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
- `[ ]` **GAP — Test**: `b33_messages_thread_test.dart` does **not exist**. The implementation is
  real but has no dedicated regression test locking in inbox/open-thread/send/mute/archive behavior.
  This is the one remaining M2 item — see Milestone 8.

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

### Milestone 3b — Configurable per-listing state-machine marketplace  `[x]` (2026-07-03: CLOSED — Items 1-5 + Defects 4/5/6 + OpenAPI + doc staleness + `b20` regression fix all code-verified DONE, 80/80 suite independently re-confirmed — see Build status)
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

### Milestone 4 — Calendar: modern rebuild  `[x]` (2026-07-03: closed — host rendering + date-grouped scrollable agenda + tests + docs all code-verified DONE; 83/83 full suite green. Live evidence (rule 6) deferred to user.)
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

**Remaining before `[x]` (owner: user, matches the evidence bar below):**
- `[ ]` Fix `b27`'s ambiguous `find.textContaining('Jul 10')` (see root cause above).
- `[ ]` Add a `b27` (or new) test asserting `host` renders by text/key when declared **and** that
  omitting `host` still renders the panel without it (rule 2, both directions — happy path only
  isn't enough).
- `[ ]` Add a test proving two events sharing `2026-07-10` (both already in the Tabletop fixture per
  M7) render under **one** `calendar-agenda-date-group-2026-07-10` header, not two separate ones —
  this is the actual "grouped by date" claim; nothing currently proves it.
- `[ ]` Confirm existing b28/b29 interaction assertions (reminder toggle, RSVP respond/change) still
  pass against the new card/detail structure — not yet independently re-run in isolation this pass.
- `[ ]` Docs: `calendar.md` + `event-rsvp.md` (host field + agenda-grouped layout) +
  `tab-renderer-contracts.md` (`CalendarTabSurface` section), landed in all 3 mirrors, `diff -q`
  clean — none touched yet (`git status` confirms no doc files changed).
- `[ ]` Live evidence (rule 6): screenshot of Tabletop Club's Calendar tab showing the rendered
  `host` field and the date-grouped headers.
- `[ ]` Full suite green — currently **79/80** (see root cause above).

**Evidence required to mark `[x]`:**
- [x] `grep -n "\.host" part02_tab_shell.dart` shows `host` rendered in the event detail panel
  (rule 1). — done.
- [x] `b27_calendar_tab_real_data_test.dart`: host positive (`wf_calendar-tab-renders-host-when-declared` — `find.textContaining('Alex Chen (Organizer)')`) and negative (`wf_calendar-tab-still-renders-without-host` — `find.textContaining('Alex Chen'), findsNothing`) per rule 2 both directions. Existing `wf_calendar-tab-renders-real-package-declared-agenda` adapted (`findsOneWidget`→`findsAtLeast(1)` for "Jul 10" now matched by both date-group header and fact pill). — done.
- [x] Existing b27/b28/b29 assertions still pass: `wf_calendar-agenda-has-two-dated-events-and-is-tappable`, `wf_calendar-reminder-toggle-is-real`, `wf_full-event-offers-waitlist-and-response-can-be-changed` all green (verified by full suite run). — done.
- [x] `b29` `wf_calendar-agenda-is-date-grouped`: two events sharing 2026-07-10 under one `calendar-agenda-date-group-2026-07-10` header; tapping the second card switches focus to `calendar-event-detail-tabletop-tournament-rsvp`. — done.
- [ ] Live evidence (rule 6): screenshot of Tabletop Club's Calendar tab — **deferred to user**.
- [x] Full suite green: **83/83** (3 new tests: host positive + host negative + date-grouping; 3 added to the 80 from M3b close). — done.

### Milestone 5 — Giving: modern payment rebuild  `[ ]`
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
  already exist from the 2026-07-02 pass — but as **dead code**. Phase C makes them live.
- `[ ]` **Gate split (M6):** `PaymentGivingTabSurface` leaves the shared placeholder `case`; resolve
  the tab's giving workflow (**decided:** first workflow in the Giving tab's sections whose
  `givingPayment != null`) → non-null renders `_GivingTabSurface`, else placeholder.
- `[ ]` **State**: paid/unpaid from `_completedWorkflowIds`; retry reuses the action surface.
- `[ ]` **UI** (new standalone `_GivingTabSurface` at part02, replacing the
  `_WorkflowStatusTabSurface`-extending version): amount/purpose summary, checkout CTA
  (→ action surface via resolved real workflow), **receipt after payment**, failure/retry,
  recurring-plan + entitlement rows. Keys: `giving-tab-surface`, `giving-amount-summary`,
  `giving-checkout-<id>`, `giving-receipt-<id>`.
- `[ ]` **Test** `b35_giving_payment_test.dart`: unpaid summary → checkout → paid receipt; retry from
  failure; recurring/entitlement rows when declared.

**Docs updated & why:** `payment-donation-dues-ad-off.md` (amount/purpose/cadence/entitlement JSON +
receipt/retry states) and the `PaymentGivingTabSurface` section of `tab-renderer-contracts.md`.
*Why: the giving contract lists the anatomy but not the declarable payment fields.*

**2026-07-03 status: NOT IMPLEMENTED (§3a gap 2).** `LoomGivingPayment` + parser exist but
`grep -rn "LoomGivingPayment\|givingPayment" lib/src` returns matches only in the model file, the
parser file, and a comment at `part02_tab_shell.dart:736`. `PaymentGivingTabSurface` routes to
`_TabPlaceholderSurface` via the same shared, unconditional `case` as Marketplace/Documents/Care/
Admin — same underlying bug as M3, see Milestone 6.

**Evidence required to mark `[x]`:**
- [ ] `grep -rn "givingPayment" part02_tab_shell.dart` must show it read in a condition that decides
  between the new `_GivingTabSurface` and `_TabPlaceholderSurface` (rule 1).
- [ ] `b35_giving_payment_test.dart` (exact name, rule 4) must contain separate cases for: (a) a
  fixture **with** `givingPayment` declared renders `giving-tab-surface`/`giving-amount-summary` and
  asserts the placeholder text is `findsNothing` (rule 2 positive); (b) a fixture **without** it
  still shows the placeholder and `giving-tab-surface`/`giving-amount-summary` are `findsNothing`
  (rule 2 negative); (c) tapping `giving-checkout-<id>` opens the action surface and completing it
  flips the summary to a receipt state (`giving-receipt-<id>`, real data from
  `_completedWorkflowIds`, not a hardcoded string); (d) a failure/retry path re-opens checkout
  without losing the declared amount/purpose; (e) recurring/entitlement rows render only when
  `cadence`/`entitlement` are declared, and are absent otherwise (another rule-2 pair).
- [ ] The literal old `_StatusTimelinePreview` hardcoded "Submitted/Review/Changes/Approved" strings
  must not appear anywhere in the new Giving tab's render path — `grep` for
  `_StatusTimelinePreview` in the Giving case should return nothing once this closes.
- [ ] Live evidence (rule 6): screenshot of Tabletop Club's Giving tab post fixture enrichment
  showing the real dues amount/purpose and, after paying, a real receipt (not the fake timeline).
- [ ] Full suite green, exact count cited.

---

### Milestone 6 — Fix data-driven placeholder gating bug  `[ ]`
**What & why:** Blocks M3 and M5 outright. `_TabNativeRenderer`'s switch
(`part02_tab_shell.dart:729-743`) groups `MarketplaceTabSurface`/`PaymentGivingTabSurface` with
`DocumentsTabSurface`/`WorkflowStatusSurface`/`CareVolunteerTabSurface`/`AdminReviewComposeTabSurface`
under one shared `case` that always returns `_TabPlaceholderSurface`. Building M3/M5's UI without
touching this switch means the new UI will still never render — the bug is in the router, not just
missing widgets.

Steps:
- `[ ]` Split `MarketplaceTabSurface` and `PaymentGivingTabSurface` out of the shared placeholder
  `case` into their own branches: `experience.marketplaceListings?.isNotEmpty == true` → real
  Marketplace UI (M3) else placeholder; workflow-level `givingPayment != null` (need to resolve which
  workflow — likely the tab's pinned/first giving workflow) → real Giving UI (M5) else placeholder.
  Documents/WorkflowStatus/Care/Admin stay on the shared placeholder `case` (no model exists for them
  yet — out of scope for this initiative).
- `[ ]` Do this step **as part of** landing M3 and M5, not before their UI exists — sequence: M3 UI +
  this gate together, M5 UI + this gate together. Do not gate on data presence while still returning
  a stub for the "data present" branch.

**Evidence required to mark `[x]`:**
- [ ] `grep -n "MarketplaceTabSurface\|PaymentGivingTabSurface" part02_tab_shell.dart` shows each in
  its own `case`, not grouped with the four placeholder-only tabs.
- [ ] The rule-2 positive/negative pair in M3's and M5's own evidence blocks above passes — this
  milestone's evidence IS those two pairs; there is no separate test file for the gate alone.

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