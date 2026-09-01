# Community JSON Migration Tracker

status: active
created: 2026-08-09
owner: this session (Validation Agent), Implementation Agent = Codex CLI via `data/call_implementation_agent.sh`

**Approval scope (clarified 2026-08-09):** authoring/updating a community's own JSON (§4's per-community
work) is standing-approved as part of this tracker and does not need a fresh sign-off per community. Only
changes to the shared *specification* — `field-types.md`, `guards.md`, `effects.md`,
`workflow-grammar.md`, or a genuinely new archetype — go back to the user for approval before landing,
same as §1/§2 already did.

## 0. What this tracker is

The generic v2 archetype pipeline (`instanceDataSchema` + `workflowDefinitions` JSON, rendered by
`GenericWorkflowInstanceCard` + the 3 real bespoke archetypes) is proven end-to-end on 3 communities
(Apartment Events, Tabletop Club, AuthZ Repro HOA — the last is a throwaway test package, not a real
product community). **The other 10 real communities are not migrated** — confirmed by direct source
inspection, not assumed:

| Tier | Communities | Current state |
|---|---|---|
| Pure legacy (no JSON at all) | Cedar Commons HOA, Member Social Space, Ad-Free Community, Data Portability Community | Hardcoded Dart, no `workflowDefinitions` |
| Hybrid (real JSON, bespoke rendering) | Garden Club, Camera Club, Neighborhood Book Club, Chess Club, Masjid Nur, Riverside Youth Soccer | Real `workflowDefinitions` embedded as Dart string literals in `part02_tab_shell.dart`, run through the real engine, but rendered by **per-community bespoke widgets** (`_GardenClubEngineTabSurface` etc.), not `renderBindings`/the generic archetype dispatcher — and only reached for the Calendar tab |
| Already engine-native | Apartment Events, Tabletop Club | Fully JSON-driven via the generic pipeline already — no migration work needed |

This tracker covers the 10 non-migrated communities. Governing rule for this whole effort, set by the user:
**author JSON → identify archetype/spec/API gaps → lock gaps in with the user → implement → verify live →
repeat per community.** Always verify against real source/widget code before proposing a new archetype;
check existing archetype capability first, every time (`docs/references/archetypes/README.md`, re-verified
2026-08-05 @ `743395e0` — 3 real bespoke archetypes: `event-rsvp`, `votePoll`, `equipment-loan`; 6 more
🟡 GENERIC via `GenericWorkflowInstanceCard`: `paymentCheckout`, `approvalQueueItem`, `formEntry`,
`discussionThread`, `statusTimeline`, `notificationInbox`; the rest are ❌ NOT REAL — do not target them).

### 0.1 Two cross-cutting structural findings (confirmed across nearly every community doc)

Found while reconciling individual communities' docs this migration effort, recorded here once instead of
per-community since both recur so consistently:

1. **The closed `tabId` enum blocks part of almost every community's documented tab architecture.** The
   real, engine-recognized `tabId` values are exactly 6: `admin`, `calendar`, `giving`, `home`,
   `marketplace`, `messages` (confirmed `docs/references/reference/render-bindings.md:261`). Every
   community doc reconciled so far that requests a custom-named tab has had to be flagged and remapped:
   Cedar Commons HOA, Member Social Space (`Connections`/`Invites`), Ad-Free Community (`Settlement`),
   Data Portability Community (`Export`/`Transfer`/`Documents`/`Audit`), Chess Club (its legacy
   implementation literally used `matches`/`rankings`/`documents` as `tabId` values — none real), and
   Neighborhood Book Club (`library`). Whoever authors each community's JSON must remap onto the real 6,
   generally `home`/`admin`/`messages` as the catch-alls. Not tracked as a spec gap to fix — this is a
   deliberate constraint of the current tab model — but real enough, and recurring enough, to record here so
   it stops being independently rediscovered per community.
2. **The B25 Card Surface Registry Mapping table present in every community doc links to a superseded
   vocabulary.** Its `Card surface family` column links to `docs/CardSurfaces/*.md` files describing
   non-real family names (`portability`, `ad`, `social`, `documentLibrary`, etc.) that do not correspond to
   the 9 real archetypes (`docs/references/archetypes/README.md`). Confirmed present in every community doc
   reconciled so far: Cedar Commons HOA, Camera Club, Garden Club, Chess Club, Neighborhood Book Club,
   Riverside Youth Soccer, Masjid Nur, Member Social Space, Ad-Free Community, Data Portability Community —
   i.e. all 10. Treat that table's `Card surface family` column as historical/aspirational context only when
   authoring JSON; the real archetype choice always comes from the 9-item list in `archetypes/README.md`.

**Process change, locked 2026-08-09 (see §1b): "author JSON" no longer means hand-authoring it directly in
this session.** It means dispatching the `loom-calendar-experience-authoring` Skill (sandboxed, spec-only)
against the community's product doc, then judging its output — both for the JSON's own quality and for
whether the Skill itself needs updating. Cedar Commons HOA's JSON was hand-authored before this change
landed; it is the first community being re-run through the new skill-based process specifically to test it.

**Standing product-doc rule (locked by the user 2026-08-09): only ever EXPAND product docs. Never remove a
documented or implemented workflow/interaction.** Where the doc and the real implementation disagree, the
doc gets expanded to cover the union, never trimmed to match the doc.

### 0.2 CRITICAL — 6 of 10 communities' merged JSON has zero live effect until the legacy hybrid shims are removed (found 2026-08-10, during Garden Club's §6 walkthrough)

**The §7 execution order has a real sequencing bug, caught empirically, not theoretically.** Step 7 says run
the §6 UX Judge gate per community as its JSON locks; step 8 says remove the 6 hybrid communities' bespoke
Dart widgets (`_GardenClubEngineTabSurface` etc.) only *after* all 10 rows read complete. This is backwards
for exactly those 6 communities: `part02_tab_shell.dart:3507-4287` gates every tab surface
(Calendar/Marketplace/Care/Documents/Home) behind `_isGardenEngineExperience`/`_isCameraEngineExperience`/
`_isBookEngineExperience`/`_isMosqueEngineExperience`/`_isYouthSoccerEngineExperience`/
`_isChessEngineExperience` — each checking for workflow-type names the **real, merged, engine-native JSON
also declares** — and routing to a hardcoded, independently-fixtured legacy widget
(`_GardenClubEngineTabSurface` line 8019, `_CameraClubEngineTabSurface` line 9059,
`_ChessClubEngineTabSurface` line 9979, `_BookClubEngineTabSurface` line 11948, plus Mosque's and Youth
Soccer's equivalents) **instead of** the real `EngineNativeArchetypeCard`/binding-dispatcher pipeline
(`part27_engine_native_binding_dispatcher.dart`) every other community (Cedar Commons HOA, Tabletop Club,
and the 3 non-hybrid communities below) actually renders through.

**Confirmed via a real live walkthrough, not inference:** installing Garden Club's actual merged package
(`docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`) onto a running
emulator and reviewing real screenshots (LLM Vision UX Judge Phase A dispatch) showed the exact text of the
legacy widget's own independently-embedded fixture (`_gardenBundledFixtureJsonc`, `part02_tab_shell.dart:8920`
— e.g. `"location": "Riverside Greenhouse", "capacityLabel": "18 of 24 spots"`) rendering on screen, **not**
the real JSON's actual data (`location: "Community Garden Plot A"`, `capacity: 20`). The legacy fixture also
independently hardcodes a fabricated checksum (`"checksum": "8F4A-PLANT"`, line 9054) that has nothing to do
with the real JSON's correctly-declared-but-never-written `checksum` field — a second, separate instance of
the exact pattern-4 defect this migration has been fixing, except baked into shipped Dart source where no
community-JSON fix can ever reach it.

**Practical consequence: the §6 gate cannot be meaningfully run for any of the 6 hybrid communities
(Garden Club, Camera Club, Chess Club, Neighborhood Book Club, Masjid Nur, Riverside Youth Soccer) until
their legacy shim is removed or bypassed first** — any walkthrough attempted now would review the *old*
hardcoded UI, not the JSON this migration effort actually produced, and any findings from it would be
worthless (already happened once, for Garden Club — see its §4 row for the discarded first-pass review).
**The 3 non-hybrid communities (Member Social Space, Ad-Free Community, Data Portability Community) have no
such shim and are NOT blocked** — confirmed no `_isXxxEngineExperience`/`_XxxEngineTabSurface` exists for any
of them in `part02_tab_shell.dart`; their §6 walkthroughs can proceed in any order.

**Revised execution order (supersedes §7 step 7/8 ordering for the 6 hybrid communities only):**
1. Run §6 walkthroughs for the 3 non-hybrid communities now — unaffected, no reason to wait.
2. Dispatch the legacy-shim removal/bypass as its own real ticket (or 6 tickets, one per community) —
   effectively pulling forward the "explicit scrap all the legacy code" work from step 8, scoped to just
   these 6 `_isXxxEngineExperience` gates + their `_XxxEngineTabSurface` classes + embedded fixtures, not the
   full step-8 list (`part04_rich_spec_catalog.dart` etc. can still wait, since nothing currently blocks on
   those). Requires careful regression verification (a Regression Impact Judge dispatch, given this is shared
   routing code touching 6 communities at once) since the shims currently deliver a *working* (if
   wrong-data) experience real code may still reference.

**Ticket CJM.7 (done, 2026-08-10, commit `4a7f3f21`) — first pass, PARTIAL.** Removed all 42
`if (_isXxxEngineExperience(experience))` gate blocks from `_TabNativeRenderer.build`
(`part02_tab_shell.dart`). `flutter analyze` clean (2 expected new `unused_element_parameter` warnings on
the now-dead shim constructors); full `loom_communities_app_shell` suite 214/215, identical to baseline.

**A dedicated Regression Impact Judge dispatch (required per this section's own standing rule) found CJM.7
alone is NOT safe to treat as closing this gap.** 5 of the 8 `rendererId` cases in `_TabNativeRenderer.build`
(`CalendarTabSurface`/`MessagesTabSurface`/`MarketplaceTabSurface`/`PaymentGivingTabSurface`/
`AdminReviewComposeTabSurface`) already had a working `_hasEngineNativeBinding`/`_hasEngineNativeCalendarBinding`
fallback beneath the deleted gates and now correctly render the real JSON. **3 cases never had any such
fallback at all** (`WorkflowStatusSurface`, `CareVolunteerTabSurface`, `DocumentsTabSurface` — only checked
legacy typed struct fields `architecturalRequest`/`documentLibrary` that only Cedar Commons HOA's schema
populates, never true for any of the six communities' real `workflowDefinitions`-based JSON) — so CJM.7
turned "wrong legacy fixture content" into "literally blank `_TabPlaceholderSurface`" for: Garden Club's
`care` tab; Camera Club's `critique` tab; Chess Club's `matches`/`rankings`/`documents`("Rules") tabs;
Neighborhood Book Club's `books`/`search`/`documents`("Materials") tabs; Masjid Nur's `care`/`search` tabs;
Riverside Youth Soccer's `registration`/`team`/`documents`("Waivers") tabs. None of this is caught by the
green test suite (no existing test exercises these 3 rendererId cases). Cedar Commons HOA, Tabletop Club,
and the 3 non-hybrid communities confirmed unaffected either way (no overlap with the deleted gates).

**Root Cause Agent dispatched 2026-08-10** (`data/root_cause_brief_cjm8_missing_fallbacks.md`,
report at `data/root_cause_report_cjm8_missing_fallbacks.md`) — found, with high confidence, that
`selectedTab.tabId` is the *App Shell navigation* ID, not the engine's closed-enum binding ID, so a dynamic
`selectedTab.tabId` fallback would remain empty by construction; a static alias table was also ruled out
(several obsolete IDs collapse onto the same real tabId, which would render identical undifferentiated
content under multiple visually-distinct labels — a new regression, not a faithful recreation). **The real
fix is upstream, at tab-construction time**: `appShellTabsFor`/`_declarativeTabSpecsFor` must stop merging
each community's legacy declarative custom-ID tab specs (`_declarativeTabSpecsByExtensionId`) into
engine-native experiences' navigation at all, not try to route around them at render time.

**Ticket CJM.8 (done, 2026-08-10, commits `4f43defb` + `f8075d3e`) — fully closed at the unit-test level; a
live re-walkthrough found one more real, unresolved gap — see the dated note below.** First commit
implemented the root-cause report's recommendation: `appShellTabsFor`/`_mergeDeclarativeTabSpecs`/
`_declarativeTabSpecsFor` now compute `isEngineNativeExperience` and filter both the generated base tab list
and declarative overrides down to the six real tabIds for engine-native experiences, dropping all 9 named
obsolete custom IDs across the 6 communities; real-tabId label overrides (Camera Club's `calendar`→"Walks",
Garden Club's `marketplace`→"Exchange") confirmed still working **at the tab-metadata/label level** (i.e.
`cjm8_engine_native_tabs_test.dart`'s Dart widget tests, which check the tab exists with the right
id/label — not its actual on-device content); Cedar Commons HOA's legacy behavior
confirmed byte-for-byte unchanged; 4 new regression tests added
(`test/cjm8_engine_native_tabs_test.dart`). Independent verification (mine) found the first commit's filter
was scoped too broadly — it applied to **every** declarative-tab source, not just the static per-extension
legacy table, breaking 2 unrelated test fixtures (`authz_p4b_permission_wiring_test.dart`'s synthetic
`private-surface` tab, `notification_dedicated_tab_test.dart`'s `notification-inbox` tab) that legitimately
declare `workflowDefinitions` for unrelated testing purposes via `appShellConfiguration`, never intended to
be constrained to the 6-community legacy-tab problem. Fixed directly (`f8075d3e`, not a Codex dispatch — a
precise, well-understood scoping correction): the engine-native filter now applies **only** to the two static
per-extension sources (`_declarativeTabSpecsByExtensionId`/`_declarativeTabSpecsByExtensionAndPersona`),
never to `appShellConfiguration`-supplied tabs. Full suite back to 218 passed / 1 failed (baseline 214 +
CJM.8's own 4 new tests, same single pre-existing named flaky failure).

**Regression Impact Judge dispatched and completed** — independently re-ran the full suite (confirmed
218/1), traced the fix boundary directly in source (confirmed correct: every real community's JSON has zero
`appShellConfiguration` usage, so the filter's scope split only matters for test fixtures, exactly as
intended), swept all 11 real communities individually (6 originally-affected ones confirmed fixed via the
new tests; Cedar Commons HOA confirmed a no-op since its only static-table tab, `admin`, is already in the
closed six; Tabletop Club and the 3 non-hybrid communities confirmed never in the static table at all), and
grepped for any other uncovered `workflowDefinitions`+custom-tab combination (found none). **Verdict: CJM.8
can be marked fully closed; all 6 previously-blocked communities' §6 walkthroughs may proceed.**
3. Now run/re-run §6 walkthroughs for the 6 previously-blocked communities, starting with Garden Club
   (whose first-pass review is already known-invalid per above), plus finish the 3 non-hybrid communities'
   walkthroughs (Member Social Space install already proven working, walkthrough itself not yet run to
   completion; Ad-Free Community and Data Portability Community not yet started).

**Garden Club re-walkthrough, 2026-08-10 (autonomous session) — real bug found (Exchange tab blank), but the
live walkthrough's OTHER observations (Home/Calendar "looking fixed") turned out to be a misread — see CJM.9
below for the actual root cause.** Re-installed Garden Club's real package on a fresh emulator instance.
First impression: Home appeared to render the real engine-native list surface and Calendar appeared to
render through the real `EngineNativeCalendarSurface` (a day-picker strip). **The Exchange (marketplace) tab
showed the bare `_TabPlaceholderSurface` fallback** ("Exchange is coming to Garden Club... check back soon")
despite the real JSON unambiguously declaring `tabId: "marketplace"` renderBindings on both `garden-tool-loan`
and `garden-tool-giveaway` (confirmed via direct grep, 5 matches) — reproduced identically on a second,
completely independent fresh emulator+app instance, ruling out a simple stale-process/cache explanation.

**Root Cause Agent dispatch (CJM.9) found something much more foundational than a Marketplace-specific bug —
and it retroactively overturns the "Home/Calendar confirmed working" read above.** The demo app preloads all
10 example communities as empty-config catalog shells at every launch. Sideloading a real package over one of
these shells hits an unconditional early-return in `LocalInAppBackend.importInitializationPackage`: any
`communityId` already present in `_communities` (always true for a preloaded community) causes the entire
incoming package to be silently discarded, returning the untouched empty shell — while the UI still shows
"Updated Garden Club from local packages," a **misleading message that only proves the key existed, never
that any data was applied**. Every community sideloaded and walked through this session was therefore never
actually exercising the real JSON at all — what looked like "the real engine-native Home/Calendar pipeline"
was the legacy hardcoded `_experienceByExtensionId` catalog rendering through generic, legacy-compatible
paths (`_HomeTabSurfaceStack`, `_WeekDateStrip`) that merely *look* superficially similar to the real
engine-native surfaces. The blank Exchange tab was simply the first tab whose legacy fallback has nothing to
show, which is what exposed the whole chain. **CJM.7 and CJM.8's fixes are themselves still believed correct**
(independently unit-tested and Regression-Impact-Judged) — but no live walkthrough this session has yet
actually proven them on a real device, because sideload never took effect for any community tested so far.
Full report: `data/root_cause_report_cjm9_marketplace_blank.md`.

**Ticket CJM.9 — done, 2026-08-10/11, commits `ec94308a` + `296f263d`.** Hydrates/replaces a preloaded shell
with the incoming package's real config instead of no-opping, discriminated by
`existing.experienceConfiguration.isEmpty && experienceConfiguration.isNotEmpty`, reusing the same
`LocalInstalledCommunity` construction already used for brand-new installs. Preserves today's
genuinely-idempotent re-import behavior for already package-backed communities unchanged (confirmed by the
existing `vt_fake-backend_import-idempotent` test, still passing). Independent verification found and fixed
two bugs in the dispatch's own new test file (`test/cjm9_preloaded_shell_hydration_test.dart`): a missing
`loom_workflow_engine` import, and two missing `tester.runAsync` wrappers around real `dart:io` file
operations — the second of which was masking the test's actual fast-passing result behind a 10-minute
framework timeout, the exact same failure class as CJM.5 earlier this session.

**A required Regression Impact Judge dispatch caught a real process error before this ticket could be
trusted closed**: the two test-file fixes above were made to the working tree but a `git commit -m` run
without a fresh `git add` only committed the dispatch's own stale staged version, silently dropping both
fixes — confirmed by the judge's own clean-checkout repro (`ec94308a` alone fails to compile, "Type
'LoomWorkflowStateMachine' not found"). Fixed in a follow-up commit (`296f263d`) landing exactly the same,
already-verified fixes; re-confirmed via `git show HEAD:...` that both are now genuinely present at HEAD, and
`flutter analyze` re-run clean on the committed state.

**Final verification, all independently re-run by the judge from a real checkout, not trusted from
self-report:** `loom_demo_local_backend` 14/14 passing; `loom_communities_app_shell` 221/222 passing (same
one pre-existing named flaky test, zero other regressions). Discriminator logic traced for the one edge case
worth checking (a package whose `experienceConfiguration` is itself legitimately empty) — falls back to the
pre-fix short-circuit behavior, not a new regression, and confirmed moot for all 10 real communities (all
declare non-empty `experience`/`workflowDefinitions`). Swept for other callers of
`importInitializationPackage` — found one (`loom_skill_debug_harness`'s AI-skill-output validator), traced
and confirmed unaffected (always installs against a fresh, unseeded backend, never hits the changed branch).
Per-consumer sweep across all 10 preloaded communities: uniformly safe by source tracing (one shared
construction loop, no per-community branching in the fixed code), Garden Club additionally confirmed via a
real widget-level test asserting `engine-native-marketplace-root` renders and the placeholder text is absent.

**CJM.9 is now genuinely fully closed. No community's §6 live walkthrough — including Garden Club's first two
attempts, and anything this session previously marked as visually-confirmed working — can be trusted as real
evidence, since sideload never took effect for any community tested before this fix. Garden Club's
walkthrough must be re-run a third time next, followed by the remaining 8 communities, to produce the first
actually-valid live evidence this migration effort has collected.**

Also separately noted, lower priority, not yet assessed as blocking: a static "In-focus product surface"
preview panel (sourced from `part16_experience_catalog.dart`'s hardcoded `_experienceByExtensionId` catalog +
`part08_garden_and_helpers.dart`) shows canned illustrative content ("Spring Planting Workshop"/"Riverside
Greenhouse") on the Calendar tab — confirmed present for all 10 communities including Cedar Commons HOA,
whose walkthrough already passed, so likely a benign, intentional "capability showcase" coexisting with real
content rather than a new regression; re-assess once CJM.9 lands and a walkthrough can see real content
alongside it. **Operational note for future walkthroughs:** never `adb shell am force-stop` the app while
`flutter run` is attached — it kills the whole debug session and emulator connection, not just the app; use
the app's own back-navigation or `flutter run`'s own `q` uit command instead.

### 0.3 Garden Club walkthrough #3 (2026-08-11) — first genuinely valid live evidence, CJM.9 confirmed working, 9 new shared-code UX findings

**CJM.9 is now proven fixed on real hardware, not just in unit tests.** Rebuilt the real Garden Club package
pair via the new `app/packages/core/loom_communities_app_shell/tool/generate_garden_club_package.dart`
(mirrors the existing Cedar Commons HOA/Tabletop Club generators, using the real `extensionId: ext_garden_club`
so it hydrates the same preloaded shell rather than creating a separate community), pushed it into the app's
private storage, and sideloaded it via "Add local community" on the manual-review emulator (commit `163e002d`).
Concrete, positive evidence the fix works, none of which was observable in the first two walkthroughs:
- Post-install banner read **"Updated Garden Club from local packages"** (not "Loaded"), and the community
  card's description text itself changed from the old preloaded-shell stub to the real package's copy
  ("RSVP to garden events, share plants, coordinate care, and keep club records portable.").
- **Home tab**: real workflow instances rendered — a `garden-volunteer-shift` instance ("Mulch delivery
  volunteer shift", 2026-08-16, "6 spots") and a schema-export card referencing the real schema ids
  `garden_event`/`plant_exchange`.
- **Exchange tab (the tab CJM.9 specifically targeted)**: real `garden-tool-loan`/`garden-tool-giveaway`
  instances rendered via the engine-native marketplace surface ("Hand tool set" — onLoan, "Steel wheelbarrow"
  — available, each with a real owner attribution) — **zero trace of the old "Exchange is coming to Garden
  Club" placeholder** that both prior walkthroughs and CJM.9's own regression test were built around.
- **Calendar tab**: a real `garden-event-rsvp` instance ("Spring Workshop", 2026-08-15) rendered on the month
  grid and in the Agenda list.
- Sign-up correctly offered the real "Member" persona sourced from the package's own JSON (not a hardcoded
  persona list — corroborates the unrelated AuthZ.P1 persona-picker fix still holding for a freshly-sideloaded
  community).

Full §6 gate run for real: 5 screenshots hand-captured and hashed, a genuine LLM Vision UX Judge dispatch (via
the `Agent` tool, `subagent_type: Explore`, `model: opus`, fresh context, Read-only) against the canonical
judge-prompt contract, both `b25_llm_review_freshness_gate.dart` (`status=pass problems=0`) and
`b25_llm_ux_review_importer.dart` (`status=fail findings=9 screenReviews=5`, exit propagated correctly — not a
tooling error) run for real, then `production_ux_judge.dart` run against the imported review. Evidence:
`docs/Build Plan V2/Evidence/B25/phase-a-garden-club-3/`.

`production_ux_judge.dart`'s `b25-c01-no-blocker-major` criterion reports **blocker=0, major=5** — i.e. the
judge found zero critical-blockers. Its own `real-content-legibility` holistic question scored 82/100 and
explicitly confirmed the data-source question this walkthrough exists to answer ("real, community-authored
content... none of which reads like a generic hardcoded shell"). The remaining criteria fail only because
this was an ad-hoc Phase-A precheck, not a canonical full-B25 pass (no `productDocCoverage`,
`blueprintCoverage`, visual-inspection rows, workflow/persona scorecards, or schema-v4 markers were ever
supplied) — the exact same, already-documented shape as the Apartment Events and Cedar Commons HOA Phase-A
precedents.

**The 9 real findings are shared-App-Shell-code issues, not Garden-Club-JSON issues** — every one of them
will recur verbatim on the other 9 communities' walkthroughs unless fixed once in the shared rendering code
first. Recorded here for tracking (severity per the judge; ticket dispatch is the very next step, see below):

| Finding | Severity | Shared surface |
| --- | --- | --- |
| `raw-schema-ids-in-member-ui` — untitled export card prints `[garden_event, plant_exchange]` verbatim, plus a triplicated "N schemas" chip/label | major | generic instance/export card |
| `unexplained-disabled-save` — same card's "Save changes" is greyed out with zero explanation | major | generic instance/export card |
| `exchange-truncation-hides-owners` — item names and `Owner:` chips clipped mid-word on Exchange | major | engine-native marketplace surface |
| `calendar-missing-weekday-header` — month grid has no weekday header row, no "today" marker, raw ISO selected-date pill | major | engine-native calendar surface |
| `fab-occludes-content` — FAB/bottom-nav clips real content on all 5 screens reviewed | major | shared scaffold/tab-shell padding |
| `raw-enum-state-labels` — Exchange state chips show raw `onLoan` (camelCase, inconsistent casing vs. `available`) | minor | engine-native marketplace surface |
| `identity-absent-off-scroll` — signed-in name only lives in a scrollable header card; gone once scrolled or on Calendar | minor | shared identity/app-bar chrome |
| `empty-sponsorship-banner` — "No sponsored message right now." rendered above the fold instead of suppressed | minor | Home tab sponsorship slot |
| `install-banner-developer-copy` — "Updated Garden Club from local packages" uses install-harness vocabulary, no version/count | minor | install-confirmation banner |

Per this tracker's own §6 gate (step 6: "Any real finding becomes a ticket... independently verified, then
recaptured and re-judged"), these need to be bridged into CJM-numbered tickets and fixed before Garden Club
(or any community) can be marked complete in §4. Given all 9 are shared code, fixing them now — before
walking the remaining 8 communities — avoids rediscovering the same 9 findings 8 more times. Full raw judge
output, freshness-gate/importer/production-judge output, and the review-input/judge-prompt artifacts are
preserved under `docs/Build Plan V2/Evidence/B25/phase-a-garden-club-3/` for the tickets to reference directly.

### 0.4 CJM.10–CJM.13: the 5 major findings fixed, independently re-verified live (2026-08-11)

All 5 **major** findings from walkthrough #3 (§0.3) were dispatched as shared-code tickets, each following
the full established discipline — dispatch → my own independent `flutter analyze`/full-suite re-run (never
trusting the sandbox's self-report, which hit the known WSL vsock bug on every single one of these 4
dispatches) → fix any real regression the dispatch itself introduced → commit:

- **CJM.10** (`194fc3e6`) — `_editor()` in `part26_generic_instance_card.dart` had no `case 'list':`/
  `'personaId[]':` branch, so those fields fell through to a plain `TextField` that stringified the raw Dart
  `List` (`[garden_event, plant_exchange]`); fixed to comma-join for display and re-parse on save. Added a
  "No changes to save yet." hint under the disabled Save button. **Follow-up regression caught and fixed**:
  my own independent full-suite re-run found a genuine pre-existing test broken by this exact commit
  (`v3_milestone_a6_generic_instance_card_test.dart`'s retry-tap test, passing on the parent commit,
  confirmed via a throwaway `git worktree`) — root-caused and fixed as **CJM.10b** (`7cd86d33`).
- **CJM.11** (`632de44e`) — added `maxLines` to `WorkflowFactPillFieldSchema` and wired it through
  `WorkflowFactPillRow`/`_SurfaceFactPill`/`_WorkflowPersonaFact`; added a generic camelCase/snake_case →
  Title Case humanizer for raw enum-like instance-data values. **My own independent verification caught two
  real bugs the dispatch's broken sandbox never saw**: (1) the humanizer called `_humanizeFieldName`, a
  *private instance method* scoped to an unrelated class in a different file — a genuine `undefined_function`
  compile error; (2) the humanizer's title-casing mangled legitimate short-form values like `"TBD"` into
  `"Tbd"`, breaking an existing calendar test. Both fixed directly, plus updated 4 pre-existing tests whose
  hardcoded raw-enum-text assertions (`'onLoan'`/`'available'`) were superseded by the intended fix —
  committed together as `bfa204cf`.
- **CJM.12** (`e64f44ea`) — added a weekday header row and a "today" cell marker to
  `_EngineNativeMonthGrid`, with a proper `currentDate` clock-injection point (avoiding a hardcoded
  `DateTime.now()` that would have made the new tests date-dependent). Independently re-verified clean, no
  fix-up needed.
- **CJM.13** (`de237cfb`) — the community screen's `SingleChildScrollView` reserved bottom padding for the
  bottom nav bar (`tabHeight + 48`) but never for the floating action button that floats above it; added FAB-
  aware extra padding. **Follow-up bug caught and fixed**: the dispatch's own new geometry-assertion test hung
  (`pumpAndSettle` never converged after a `dragUntilVisible`) — its own sandbox never caught this either
  (same vsock blocker). Replaced with the bounded `pump()`-loop pattern already proven elsewhere this session
  — **CJM.13's own fix-up**, `0d0309f7`.
- **CJM.11c** (`b92ded64`, no separate ticket — small enough to fix directly after finding it live) — **the
  single most important catch of this whole sequence**: re-testing CJM.11 live on Garden Club's *real*
  sideloaded JSON (not the hardcoded default equipment-loan archetype the original ticket's test fixture used)
  showed the Exchange "Owner:" pill was **still truncating identically to before the fix**. Root cause: two
  separate gaps. `part26_generic_instance_card.dart`'s conversion from a community's own JSON-declared
  `instanceDataSchema` into `WorkflowFactPillFieldSchema` never set `maxLines` at all (silent default of 1).
  `part36_engine_native_marketplace_surface.dart`'s equivalent conversion *did* set `maxLines: 2`, but gated
  it behind a hardcoded field-name allowlist (`'holderPersonaId'`, `'claimedByPersonaId'`) copied verbatim
  from the hardcoded default archetype — Garden Club's own JSON names the same field `ownerPersonaId`, which
  the allowlist never matched. This is a textbook instance of this session's own repeated lesson: **a fix
  verified only against a synthetic/default fixture, never against a real community's own JSON, is not
  verified.** Fixed both call sites to apply the default universally, not keyed to field names.

**Independent verification, every one of the 4 dispatches, run by me from a real checkout, never trusted from
self-report:** `flutter analyze` clean every time; full `loom_communities_app_shell` suite grew from 221→227
tests across the four tickets, with the *only* failure at every single checkpoint being the one already-known,
pre-existing, unrelated flaky test in `v3_milestone_a11_event_rsvp_archetype_test.dart`. Zero other
regressions survived to the final state.

**Live re-verification (the actual point of all of this): rebuilt the app fresh, re-sideloaded Garden Club's
real package, and re-captured all 5 previously-failing screens.** Dispatched a fresh LLM Vision UX Judge
(`Agent` tool, `Explore` subagent, `opus`, fresh context) against the new screenshots. First pass
(`phaseA-garden-club-4-1`) confirmed 3 of 5 resolved (raw-schema-dump, disabled-Save-hint, owner-truncation)
but could not confirm the other 2 (calendar header, FAB/nav clearance) — **not because the code was wrong,
but because the single calendar screenshot supplied had scrolled past the weekday header and stopped short of
full agenda-card clearance**. This is exactly the freshness/evidence discipline this pipeline exists to
enforce: the judge correctly refused to credit a fix it couldn't see. Recaptured two corrected, further-
scrolled screenshots and dispatched a second, focused judge pass (`phaseA-garden-club-4-2`), which confirmed
both resolved: the weekday header (`MON TUE WED THU FRI SAT SUN`) is genuinely present and column-aligned,
today's cell carries a real (if low-contrast) marker distinct from the selected-date styling, and the Agenda
detail card now scrolls fully clear of the bottom nav with its complete rounded bottom edge visible. Both
freshness-gate runs passed clean (`status=pass problems=0`). Evidence for both passes:
`docs/Build Plan V2/Evidence/B25/phase-a-garden-club-4/`.

**All 5 of walkthrough #3's major findings are now genuinely, independently, live-re-verified resolved.**

**New findings surfaced during this re-verification pass** (not blocking — no critical-blockers, matching
this session's own established precedent of documenting open findings rather than blocking indefinitely on
every last polish item; tracked here for a future remediation pass, not yet ticketed):
- `exchange-card-content-clipped` (major) — Exchange grid cards clip their own trailing content at a fixed
  card height: the "Pickup:" chip is sliced mid-icon and the "Request"/"Join queue" CTA bleeds past the
  card's bottom edge.
- `bottom-nav-tab-row-overflows-viewport` (major) — the 4th bottom-nav tab ("Organize") is clipped by the
  right screen edge on every in-community screen.
- `raw-field-keys-and-duplicate-chips-on-instance-cards` (minor) — schema values still show raw snake_case
  identifiers (`garden_event, plant_exchange`) rather than human labels; a bare `isFull` boolean-key chip with
  no value; duplicated "Signed up: 1" / "2 schemas selected"+"2 schemas" chips.
- `exchange-secondary-text-still-truncated` (minor) — `Borrower:` attribution and some item names still
  ellipsize even after CJM.11/CJM.11c (owner attribution specifically is fixed; borrower is not).

Garden Club's core sideload mechanism (CJM.9) and all 5 major shared-code UX findings from its first genuinely
valid walkthrough are now closed. Not yet run for Garden Club: the §6 step 7 product-doc reconciliation gate.
Given all 9 original findings and their fixes are shared App-Shell code, the remaining 8 communities' `§6`
walkthroughs should now surface substantially fewer shared-code issues than Garden Club's did — proceeding to
those next.

## 1. Locked spec additions (both now in `docs/references/reference/field-types.md`, doc_version 1.2.0)

Both approved by the user 2026-08-09. Both are field/display-level capabilities, deliberately **not** new
archetypes and **not** new `effects.md` ops — a link-open is a presentation action tied to one field's
value, not a state mutation, so it doesn't belong in the effects vocabulary; and because every archetype
already renders `instanceDataSchema` through the same shared fact-pill code, building this once at the
field-type level makes it available to every archetype simultaneously.

1. **`type: "url"`** — a field whose value is an openable link/document. Required `openMode`:
   `"external"` | `"embedded"` | `"choice"`. Tapping performs the platform action; never calls
   `applyTransition`, never mutates `instanceData`. New validator rules (all ⚠️ proposed):
   `missing_url_open_mode`, `invalid_url_open_mode`, `url_open_mode_on_non_url_field`.
2. **Citation lists** — `type: "list"` with an `itemSchema` whose members can themselves be `type: "url"`
   (e.g. `{ "label": {"type":"text"}, "source": {"type":"url","openMode":"external"} }`). No new field
   `type`; renders each list item as label text + a tappable link per that member's `openMode`. New
   validator rule (⚠️ proposed): `item_schema_on_non_list_field`.

**Implementation sequencing (locked):** `openMode: "external"` only needs `url_launcher` (not currently a
`loom_communities_app_shell` dependency — confirmed via `pubspec.yaml`). `embedded`/`choice` need
`webview_flutter` (also not present) — a strictly larger follow-on. Land `external` first; the field-level
JSON contract does not change based on which increment ships first.

## 1a. Findings from the single tooling smoke test (2026-08-09) — real, not hypothetical

Surfaced by actually installing Cedar Commons HOA's JSON and driving the live app on-device (§6's mandatory
gate, run once end-to-end as a dry run before the full cycle — see the mini-report for the full trace).
Recorded here because they're durable, cross-community findings, not just this one run's trivia.

1. **`hoa-owner-01` vs. `hoa-homeowner` (fixed, JSON-side):** the fixture's seed `workflowInstances` used a
   stray instance-level identifier (`hoa-owner-01`) in several `personaId`-typed fields
   (`createdByPersonaId`, `payerPersonaId`, `reservedByPersonaId`, `requesterPersonaId`) instead of the
   community's actually-declared persona id (`hoa-homeowner`). The validator caught the `createdByPersonaId`
   instances (`unknown_instance_persona`) but NOT the plain `instanceData` fields of the same shape — those
   are never checked against the declared persona list, only `createdByPersonaId` is. **Lesson for every
   remaining community's JSON:** any `personaId`-typed `instanceData` field that a guard reads must hold a
   real declared persona id, not a distinct "flavor" instance identifier — the validator will not catch this
   class of bug, only a live sign-in-and-look pass will. (This fix alone did not make the Giving tab visible
   — see #4.)
2. **Calendar tab requires a field literally named `eventDate` (NOT fixed, documented gap):** the Calendar
   surface (`part28_engine_native_calendar_surface.dart:635`) reads `instanceData['eventDate']` as a
   hardcoded literal — it does NOT consult `instanceDataSchema` for a `type: "date"` field under any other
   name, and does NOT use the `locationOverlap` creationGuard's own configurable `dateField` (which exists
   for a completely different purpose — overlap-checking at creation time, not calendar projection).
   Cedar Commons HOA's `hoa-facility-reservation` uses `reservationDate` (a more domain-accurate name) and,
   as a result, fails to render on the Calendar tab at all (`Could not show hoa-res-room-a: event date is
   missing or invalid`). This is a real, validator-invisible archetype-fit gap, confirmed by the live judge
   walkthrough exactly as intended — **every remaining community's calendar-bound workflow needs a literal
   `eventDate` field** (rename, or add a computed `formula` field aliasing the real date field) until/unless
   the calendar surface is changed to honor a configurable field name. Left as-is in this fixture
   deliberately, to prove the live-walkthrough gate surfaces real gaps rather than being fixed silently —
   pick this up as its own follow-up ticket before Cedar Commons HOA is marked complete in §4.
3. **Marketplace tab renders its real, correct empty state** ("Marketplace is coming to Cedar Commons HOA")
   for a community with no workflow bound to `tabId: "marketplace"` — confirmed as intended behavior, not a
   bug, since Cedar Commons HOA's design never targets that tab.
4. **`role: "actor"` in a render binding means "I am `createdByPersonaId`," not "a `personaId`-typed field
   on this instance names me" (NOT fixed, open design question):** confirmed by reading
   `_engineNativeActorRolesForInstance` (`part32_engine_native_list_surface.dart:145-150`, the default
   `rolesForInstance` for the generic list-based tab surface that "giving" uses) — it grants role `"actor"`
   **only** when `instance.createdByPersonaId == viewerPersonaId`, nothing else. Fixing #1's `payerPersonaId`
   was necessary but not sufficient: `hoa-dues-priya`'s `createdByPersonaId` is correctly `hoa-board` (the
   board issues the invoice), so a signed-in Homeowner is never its "actor," and the `role: "actor"` primary
   binding never resolves — the Giving tab stays empty for the exact persona meant to pay. This is a genuine
   **board-issues / member-acts** shape (also true of `hoa-architectural-request`'s decision flow in
   reverse) that the default creator-based "actor" role does not model. **Open question for the user/next
   session, not resolved here:** should such workflows declare `role: "any"` instead (visible to every
   signed-in persona — simple, but reopens the "read visibility" question §3's `no_read_visibility_declared`
   warning already flags, since nothing currently scopes an "any" binding to just the relevant payer), or
   does the binding-resolver need a real `payer`/custom role wired via an explicit `rolesForInstance`
   override (bigger, more correct, not yet attempted anywhere in this codebase for a non-creator actor)?
   Left open deliberately — this is a real architecture decision, not a JSON typo, and belongs in §2/§3 of
   this tracker's next revision before Cedar Commons HOA (or Garden Club's near-identical loan-request shape)
   can be marked complete.

## 1b. New process: skill-based JSON authoring (locked 2026-08-09)

Every community's JSON was, up to Cedar Commons HOA, hand-authored directly in this session. That worked,
but it means the *authoring capability itself* was never actually tested — I both wrote the JSON and judged
it, with full knowledge of the app's internals, the archetype registry, and every prior fix. The whole point
of `docs/references` is that it's supposed to be sufficient **on its own**, with no other context, for an
LLM to author a real community — and `.agents/skills/loom-calendar-experience-authoring/` already exists
specifically to test that claim (its own `SKILL.md`: "is `docs/references` alone... sufficient for an LLM to
author a working experience?", confirmed once already against a live external ChatGPT session with zero
repo/tool access, 2026-08-04).

**New standing process for every remaining community:** JSON authoring is dispatched to a sandboxed
subagent instructed to act as this Skill — reading only `docs/references/**` (plus the Skill's own bundle)
and the target community's product doc as "the request" — rather than authored directly by this session.
This session's role shifts from author to **reviewer/judge** of the Skill's output, matching the same
separation-of-concerns principle the whole B25 pipeline is built on ("Worker agents may implement UI and
tests, but they do not grade their own work").

**Known scope mismatch, deliberate, not an oversight:** the Skill is currently scoped *narrowly* to the
Calendar tab / `event-rsvp` `cardSurfaceFamily` only (see its own `SKILL.md` Scope section) — a much
narrower slice than most communities need (Cedar Commons HOA alone needs `paymentCheckout`,
`approvalQueueItem`, `formEntry`, and a reused `equipment-loan`, none of which are `event-rsvp`). Running
this narrow Skill against a broad community on purpose is the point: it's the fastest way to find out
exactly where the Skill's instructions need broadening before trusting it for the other 9 communities. The
Skill's own Hard Rule 7 requires it to say so explicitly rather than force-fit — its response to Cedar
Commons HOA is itself the first real data point for §1c's new judge.

**First real run, dispatched 2026-08-09:** a sandboxed `general-purpose` subagent, given only `SKILL.md`,
`00-INSTRUCTIONS.md`, and `cedar-commons-hoa-product-experience.md`, told explicitly not to read the
existing hand-authored fixture or any other session artifact, and required to run the real validator CLI
itself before calling anything final (per the Skill's own mandatory validate-and-fix loop). Its prior
hand-authored version was backed up to
`Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.HAND-AUTHORED-BACKUP.jsonc` first, so nothing is
lost regardless of outcome. Result and follow-up to be recorded here once the dispatch returns.

## 1c. New judge role: Skill Output / Skill-Update Judge

A genuinely new role, alongside the existing `LLM Vision UX Judge Agent` and
`LLM Product Docs To Evidence Reconciliation Agent` in `docs/Build Plan V2/Tools/ux-gate-judge-tools.md` —
add it there once proven, following the same Agent Split table format. Purpose: **judge the Skill's output,
and separately, judge the Skill itself** — the first without the second risks silently reworking every bad
JSON by hand instead of fixing the root cause that will just recur on the next community.

| | |
|---|---|
| Responsibility | Compare a Skill-authored community JSON against (a) the community's product doc, (b) `docs/references/archetypes/README.md`'s real-vs-not-real archetype status, (c) the shared spec docs (`field-types.md`, `guards.md`, `effects.md`, `workflow-grammar.md`), and (d) the Skill's own stated scope and Hard Rules — then decide whether the JSON is correct/high-quality **and** whether the Skill's instructions, read order, worked examples, or stated scope need to change to reliably produce this quality on the next run. |
| Context allowed | The Skill-authored JSON + its self-reported "Gaps / assumptions" section, the community's product doc, the archetype registry, the shared spec docs, the Skill's own files (`SKILL.md`, `00-INSTRUCTIONS.md`, and whichever numbered reference files are relevant to what it got wrong). Explicitly allowed — unlike the authoring dispatch itself — to read the existing hand-authored comparison fixture where one exists, since this judge's job is exactly the comparison the authoring dispatch was sandboxed away from. |
| Output | A verdict on the JSON (validator-clean is necessary but not sufficient — must also be archetype-correct, not force-fitting, not missing real product-doc requirements), plus a **separate, itemized list of concrete Skill-file edits** (e.g. "broaden Scope section to cover X", "add a worked example for `paymentCheckout`", "Hard Rule N is ambiguous about Y") when the JSON's problems trace back to the Skill's own instructions rather than one-off author error. |
| Not this judge's job | Re-running the live UX walkthrough (§6 — separate, already proven, still required) or the product-doc reconciliation gate (separate LLM role, already documented in `ux-gate-judge-tools.md`, not yet run for any community this tracker covers — see the smoke-test report's coverage audit). This judge is scoped to authoring-time JSON quality and Skill fidelity only. |

Dispatch mechanics: same as the LLM Vision UX Judge — a Claude Code subagent via the `Agent` tool, not
Codex, not the headless `claude` CLI. First real dispatch happens once §1b's authoring run returns a result
to judge.

> **Scope note, added 2026-08-11, not a correction to the above:** this "not Codex" statement is specific to
> the **judge** role and remains accurate — judging still only happens via the `Agent` tool. The **authoring**
> side of this Skill gained a third channel the same day, which does use Codex CLI (zero-repo-access, live
> GitHub fetch, `data/call_skill_authoring_agent.sh`) — see `docs/Build Plan V2/Tools/
> community-authoring-skill-tool.md`'s "Three channels" section and `SKILL.md`'s own channel list for the
> real, current mechanism. All 10 communities recorded in this tracker were authored via the in-repo `Agent`
> tool channel (channel 1 there), not this newer channel — nothing here is retroactively changed by its
> existence.

### First real verdict (2026-08-09, judged directly by this session against the returned output)

The sandboxed authoring run (§1b) returned a genuinely strong result: a validator-clean (`0 errors, 0
warnings`) package covering the two workflows that actually fit the Skill's stated Calendar/`event-rsvp`
scope (`hoa-meeting`, `hoa-facility-reservation`, both with a proper per-member-response + reminder shape),
plus an exceptionally specific, itemized report of the other 5 product-doc workflows it correctly refused to
force-fit, why each doesn't fit `event-rsvp`, and what `cardSurfaceFamily` each would really need. Every one
of those 5 refusals is correct — none of `paymentCheckout`, `documentLibrary`, `approvalQueueItem`,
`notificationInbox`-as-broadcast, or `exportWizard` is `event-rsvp`.

**Independently spot-checked, not taken on faith** — this session re-read the actual current source of every
load-bearing claim in the agent's own 10-point self-assessment before trusting any of it. Every claim
checked came back exactly correct, several with real, previously-unknown consequences:

1. **`visibility`/`readGuard` has no normative shape documented anywhere in `docs/references`** — confirmed:
   `workflow-grammar.md` mentions `visibility` exactly once, for an unrelated `audienceMemberField` concept;
   the only place `visibility`/`readGuard`/`membersOnly`/`guarded` appear together is one table row in
   `guide/05-validation.md`'s validator-rules summary, with zero shape/enforcement definition. This is a
   canonical `docs/references` gap, not a Skill-bundle-only problem — the same warning
   (`no_read_visibility_declared`) already fires on the fixture in `docs/references/communities/`.
2. **A real, previously-unknown bug in this session's OWN hand-authored Cedar Commons HOA fixture,
   confirmed by this comparison**: `guards.md` §9 (`locationOverlap`) says, verbatim, "**Use as a
   `creationGuard`**" as its recommended placement — but `workflow-grammar.md` marks `creationGuard`
   "PROPOSED, not yet implemented," and the "not yet implemented" caveat is never repeated inline in
   `guards.md` §9 itself, right where a reader would act on it. This session's hand-authored
   `hoa-facility-reservation` followed guards.md's literal recommendation and put `locationOverlap` inside a
   `creationGuard` — which **never actually runs**, meaning the hand-authored fixture's double-booking
   protection is inert despite the JSON structurally implying it works. The Skill-authored version instead
   placed `locationOverlap` on the `reserve` **transition's** guard — the real, implemented placement — and
   is therefore *more correct on a genuine functional dimension* than this session's own hand-authored JSON.
   **This needs its own follow-up fix to the hand-authored/backup fixture, independent of anything else in
   this tracker.**
3. **`guide/05-validation.md` is stale relative to the files it summarizes, confirmed**: says "one of the
   20" formula functions (`formulas.md` itself says 23 in its heading and 22 in its own rules table — a
   second, separate internal inconsistency); says "one of the nine" effect ops (effects.md documents twelve
   per the agent's report); and says "no `!`" twice, which `formulas.md` explicitly corrects with a dated
   "Correction, 2026-07-17: unary `!` ... genuinely works" note that `05-validation.md` was never updated to
   match. Confirmed by direct read of both files.
4. **Cedar Commons HOA's own product doc actively misleads on `cardSurfaceFamily` naming, confirmed**: its
   "B25 Card Surface Registry Mapping" table names surfaces `payment`, `documents`/`external-document-link`,
   `calendar`, `workflow-status`, `notification-inbox`, `portability` — none of which are real
   `cardSurfaceFamily` enum values (`paymentCheckout`, `documentLibrary`, `event-rsvp`,
   `approvalQueueItem`/`statusTimeline`, `notificationInbox`, `exportWizard`) — and links each to
   `../../CardSurfaces/*.md`, the exact 26-file set `archetypes/README.md` already declares **superseded**
   ("every file invents a nonexistent `CommunityXxxApi`. Nothing from it is promoted here"). This is very
   likely the same trap that led this session to originally over-propose 3 new archetypes for this same
   community before being corrected earlier in this project. If the other 9 communities' product docs share
   this template (not yet checked), every one of them carries the same trap for both the Skill and any
   hand-authoring pass that trusts the product doc's own registry table literally.

**Verdict: the Skill's output is high-quality and its scope discipline is working correctly** — it did
exactly what Hard Rule 7 asks (report, don't approximate) and, per finding #2, its narrow focus on only the
in-scope grammar made it *more* correct than this session's own broader, faster hand-authoring pass. **The
Skill does not yet cover enough of a typical community to be the sole authoring path** — Cedar Commons HOA
needs 5 more workflow types this Skill is deliberately out of scope for. Recommendation, not yet applied:

**(a)/(b)/(c) applied 2026-08-09, user-approved:**
- `workflow-grammar.md` (now doc_version 1.6.0): added a full normative `visibility`/`readGuard` section —
  confirmed by direct source read (`workflow_models.dart:471-538`, `local_workflow_engine_api.dart:340-392`)
  to be genuinely, currently enforced (not advisory, not proposed) — previously undocumented anywhere
  except one bare table row in `guide/05-validation.md`.
- `guards.md` §9 (now doc_version 1.9.0): added the "do not place in `creationGuard`, it silently never
  runs" caveat directly inline next to the recommendation that caused it.
- `guide/05-validation.md` (now doc_version 1.1.0): fixed `unknown_effect_op` (nine → twelve),
  `unknown_formula_function` (20 → 23), and the stale "no `!`" claim (now correctly states unary `!` is
  supported, only `!=` is not) — all three resynced against the current `formulas.md`/`effects.md`.

**(d) a second real bug found in the hand-authored fixture, same review pass:** `hoa-export-evidence`'s
`generate-export` effect sets `"checksum": "SHA-{id}"` — a fabricated, fake-looking hash. Confirmed via
`platform-services.md`: both "Checksum / integrity hash" and "ID generation" are `❌ Not implemented`
platform services. This is a real AP-6 violation (never substitute a hardcoded value for one that should be
computed by a real service) introduced by this session's own hand-authoring, caught only by the skill-vs-
hand-authored comparison this judge pass did. Needs its own fix alongside the `locationOverlap` merge below.

**Process decision, superseding this section's original "do not broaden" recommendation (user direction,
2026-08-09):** broaden `loom-calendar-experience-authoring` itself to cover every real/working
`cardSurfaceFamily`, not just `event-rsvp` — do **not** switch to `using-loom-to-build-an-extension`
instead. Investigated directly: that sibling Skill is a much heavier, ~700-line, full B25-pipeline
apparatus (build/certify/UX-review, not just JSON authoring) whose own Operating Rule 15 points at exactly
the same superseded `components/card-surfaces/*` vocabulary that misled this session's original Cedar
Commons HOA archetype proposal and that this Skill's finding #4 flagged as a trap — adopting it would
reintroduce the exact problem this whole exercise is trying to close. `loom-calendar-experience-authoring`'s
own narrow, `docs/references`-only discipline is the asset worth keeping; only its stated *scope* needs to
widen. This is de-risked by a real discovery: `guide/03-common-patterns.md` **already has canonical
patterns P1-P6** covering RSVP, ballot (`votePoll`), approval queue (`approvalQueueItem`), loan
(`equipment-loan`), payment (`paymentCheckout`), and discussion thread (`discussionThread`) — i.e. every
real archetype except `formEntry`/`notificationInbox` (simple enough not to need a dedicated pattern) — and
`SKILL.md`'s own `chatgpt-upload/` regeneration step already copies the **entire** `03-common-patterns.md`
file into the bundle as `02-common-patterns.md`, P2-P6 included, even though nothing in the read order or
scope text currently tells the Skill to use them. Broadening is therefore mostly a scope/read-order/
Hard-Rule edit, not authoring new teaching material from scratch. See §1d for the concrete plan and
execution.

**Deferred, not dropped:** whether the CardSurfaces-registry-vocabulary trap (finding #4) exists in the
other 9 communities' product docs too — explicitly deferred by the user until Cedar Commons HOA's full,
broadened-Skill-authored package passes this judge for real. Minor Skill-bundle polish items (the
`chatgpt-upload/` self-contradiction about reading its own worked example, the missing "ship the in-scope
slice" instruction, the reminder-scheduling gap) get folded into §1d's broadening edit rather than done
separately.

## 1d. Broadening `loom-calendar-experience-authoring` — plan and execution (2026-08-09)

Goal: the Skill authors a **complete** Cedar Commons HOA package (all 7 workflows, not just the 2
calendar-shaped ones), sandboxed exactly as before, then §1c's judge decides whether the result correctly
uses the real archetypes and matches the product doc — iterate (edit Skill → re-dispatch → re-judge) until
it does, before touching any other community.

Concrete edits (this session, direct — Skill-bundle files are not spec files, no separate approval gate
per the tracker's own approval-scope rule):

1. **`SKILL.md` Scope section**: replace the "Calendar only... `event-rsvp` is the only `cardSurfaceFamily`
   this Skill's scope needs" framing with the full real set — `event-rsvp`, `votePoll`, `equipment-loan`
   (the 3 bespoke real archetypes) plus `paymentCheckout`, `approvalQueueItem`, `formEntry`,
   `discussionThread`, `statusTimeline`, `notificationInbox` (the 6 🟡 GENERIC ones) — sourced from
   `docs/references/archetypes/README.md`, cited as the live source of truth rather than copied as a frozen
   list. Explicitly out of scope, by the same source: `documentLibrary`, `exportWizard`, `audienceSelector`,
   `stateMachineGrid`/`table`, `volunteerRoster`, `searchAiAnswer`, `singleItem` (all ❌ NOT REAL) — say so
   per Hard Rule 7, never force-fit.
2. **Hard Rule 6**: update from "the only value you should need is `event-rsvp`" to "never invent a
   `cardSurfaceFamily` not listed as real in `archetypes/README.md`" — same rule, corrected scope.
3. **Read order**: add `guide/03-common-patterns.md` P2-P6 (already physically present in the
   `chatgpt-upload/` bundle as `02-common-patterns.md`, just never pointed at), keyed to which pattern
   applies to which product-doc request shape (ballot → P2, propose/decide → P3, loan/giveaway → P4,
   payment → P5, discussion → P6). Change the `archetypes/README.md` read-order entry from "confirm
   `event-rsvp` is correct" to "the source of truth for picking the right `cardSurfaceFamily` for
   **any** workflow in scope, and for which families are real vs. not."
4. **New: CardSurfaces-vocabulary warning**, sourced directly from this Skill's own first-run finding #4 —
   product docs' "B25 Card Surface Registry Mapping" tables use names (`payment`, `documents`, `calendar`,
   `workflow-status`, `notification-inbox`, `portability`) that do **not** match real `cardSurfaceFamily`
   values and link to the superseded `docs/CardSurfaces/` folder. Never copy those names directly into
   `cardSurfaceFamily` — always cross-reference `archetypes/README.md`'s real enum.
5. **New: partial-scope instruction** — "if any part of the request is in scope, author that part
   completely; report everything else by product-doc section, workflow id, and the `cardSurfaceFamily` it
   would actually need, rather than refusing the whole request or force-fitting."
6. **`00-INSTRUCTIONS.md`**: mirror edits 1-5 (it's the frozen portable copy consumed by a no-tool-access
   provider, per `SKILL.md`'s own regeneration convention) plus fix its own stale "eleven"/"one of the
   nine" phrasing to match §1c fix (c) above.
7. Regenerate `chatgpt-upload/`'s straight-copied files (`07-workflow-grammar.md`, `08-guards.md`,
   `11-field-types.md`, `04-validation.md`) from the now-updated `docs/references` sources, per `SKILL.md`'s
   own documented `cp` recipe.
8. Re-dispatch the sandboxed authoring run against Cedar Commons HOA's product doc — same sandboxing rules
   as §1b's first run (read-only, `docs/references/**` + the product doc + this Skill's own files; no
   reading the hand-authored fixture or its backup; real validator CLI required before treating anything as
   final) — this time expecting a complete 7-workflow package, not a 2-workflow slice.
9. §1c's judge (this session, directly, same verification discipline as the first pass — spot-check the
   agent's own claims against real source before trusting them) reviews the result for: validator
   cleanliness, correct archetype selection per `archetypes/README.md` (not the CardSurfaces vocabulary),
   real product-doc coverage, absence of AP-6-style fabricated values (the `checksum` bug is the concrete
   negative example to check for), and correct use of the `type:"url"` field (CJM.2 external-mode support)
   for `hoa-member-document` — declaring `openMode` freely is fine even though `embedded`/`choice` aren't
   implemented yet; that's expected, to be closed in a later implementation cycle, not an authoring defect.
10. Iterate (fix Skill → re-dispatch → re-judge) until the judge finds no blocking issues. Only then merge
    the result into the canonical `Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`, re-run
    the §6 live UX Judge walkthrough fresh, and move to the next community.

### Outcome (2026-08-09) — one loop, judge passed, merged

Steps 1-9 above ran exactly once (no Skill-content iteration needed — the first broadened dispatch already
passed). **Judge verdict: PASS** — a genuinely separate `Agent`-tool dispatch (not self-judged this time),
which independently re-ran the real validator, independently re-verified the candidate's own claimed
`creatable`/`missing_template` findings against source, and found 4 additional real defects of its own:

- **D1 (most serious, new discovery):** the candidate named its facility-reservation time field
  `startTime`; the Calendar surface reads `instanceData['eventTime']` by hardcoded literal name
  (`part28_engine_native_calendar_surface.dart:343,635,642`) — parses/validates fine, silently renders no
  time label and sorts every entry to midnight. This is now documented in `archetypes/README.md` (a note
  right after the archetype table) so it stops being a silent trap.
- **D3:** 3 terminal states had no `renderBinding` at all (`hoa-member-document.archived`,
  `hoa-committee-decision.closed`, `hoa-owner-notification.withdrawn`) — instances in them would vanish
  from every tab. Fixed with a `summary` binding each.
- **D4 (minor):** `record-payment-failure` only fired `from: ["due"]`, so a second failed attempt (a real
  product-doc requirement) couldn't be recorded. Added `"failed"` to its `from` list.
- **D2 (reviewed, not applied):** the judge flagged `set-reminder`'s `allowedPersonaIds` including
  `hoa-board` as unsatisfiable alongside its `actorEqualsField: reservedByPersonaId` guard. On direct
  re-check: `confirm-reservation`'s own guard allows `hoa-board` to be the reserver too, so
  `reservedByPersonaId` can legitimately be `hoa-board` and the guard is satisfiable in that case — not
  applied as a fix, kept as an example of verifying a judge finding rather than applying it blindly.

All 3 applied fixes (D1, D3, D4) re-validated clean (`0 errors, 0 warnings`) before merge. The merged file
now also fixes both bugs the judge confirmed in the *prior* hand-authored version (the inert
`creationGuard`/`locationOverlap` placement, and the fabricated `checksum`/`receiptId` AP-6 violations) —
neither exists in the merged file. Comments explaining every archetype choice (including the
event-rsvp-vs-`equipment-loan` decision for facility reservations, settled in the file's own header
comment) were added back in, addressing the judge's one real complaint about the candidate (no review
context, unlike the hand-authored version).

**Merged into the canonical `Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`** — the prior
hand-authored version remains at `...HAND-AUTHORED-BACKUP.jsonc` for reference; the partial 2-workflow
first-pass output remains at `...SKILL-AUTHORED-CALENDAR-SLICE.jsonc`.

**Spec-doc fixes applied from the judge's 9 itemized recommendations** (all mechanical, evidence-backed —
applied directly per this tracker's approval-scope rule, same as §1c's earlier 3 fixes):
`archetypes/README.md` (the `creatable`→`actions[]` fix on the `event-rsvp` row, the new
`eventDate`/`eventTime` hardcoded-name warning, and the `missing_template`-not-enforced caveat on Hard
Rule 1); the same `creatable`→`actions[]` fix in 4 more archetype docs
(`approval-queue.md`, `vote-poll.md`, `equipment-loan.md`, `discussion-thread.md`) whose copyable JSON
snippets all had it — the actual highest-blast-radius finding, since these are reachable from this Skill's
own read order; `guide/06-product-doc-to-json.md`'s two stale rows describing the same dead key as the
BLOCKING-phase design (now marked SHIPPED with the real shape); `render-bindings.md` and
`guide/05-validation.md`'s `missing_template` rows (marked NOT ENFORCED, confirmed by the judge's own
negative-control test); `SKILL.md`'s stale "Calendar (event-RSVP) only" paragraph (contradicted its own,
already-broadened Scope section below it) and its "Hard Rule 2" → "Hard Rule 3" citation. `chatgpt-upload/`
mirror regenerated again to match.

**§4 status**: Cedar Commons HOA's JSON is now authored, judged, and merged — but not yet marked complete.
Per this tracker's own §6 gate, a fresh live UX Judge walkthrough against this merged file (not the
smoke-test's earlier hand-authored version) is still required before this community closes out.

## 2. Approved shared code gaps — 3 tickets, dispatch first (they unblock every community's JSON)

All three approved by the user 2026-08-09 ("Approving all the others (1,2,4)"). Each becomes its own
`data/v3_ticket_<name>.md` at dispatch time, following the proven structure (`## Context`, `## Scope`,
`## Do not do`, `## Required verification`, `## Git safety reminder`, `## Commit`, `## Required response
format`) — see §5 for the exact dispatch mechanics.

**Process addition, 2026-08-10 (`docs/Build Plan V2/Tools/regression-impact-judge-tool.md`):** every ticket
here changes code shared across multiple communities, not code scoped to one — "the ticket's own tests
pass" only proves the ticket's own new behavior works, not that every *other* consumer of the same shared
code path (every community declaring the same `cardSurfaceFamily`/mechanism) is unaffected. CJM.1 and
CJM.3 shipped before this was named as a distinct required step (retroactive risk judged low for both, but
that judgment itself wasn't done via a systematic per-consumer sweep — see the tool doc's "Status" section
for the honest accounting). **Going forward, every shared-code ticket in this section must be independently
verified via a Regression Impact Judge dispatch against every real consumer before being marked done**, not
just its own scoped test run. CJM.5 (below) is the first ticket this applies to from the start.

### Ticket CJM.1 — `equipment-loan` giveaway generalization (done, 2026-08-10)

`_isGiveaway` now derives from whether the workflow declares a `claim` transition
(`widget.resolved.machine.transitions.any((t) => t.id == 'claim')`) instead of matching the literal string
`'equipment-giveaway'`. Verified zero behavior change against the real Tabletop Club fixture (its
`equipment-giveaway` type has a `claim` transition, its `equipment-loan` type doesn't). Unblocks Garden
Club's `garden-tool-loan-giveaway`. Commit `b34211e8`, pushed.

**File:** `app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart:369-696`.
**Gap:** `EquipmentLoanArchetypeCard` is otherwise fully generic (fact-pills + button row driven by
`instanceDataSchema`/`availableTransitionsAsync`; queue/return already generic via action-ID lookup) —
the **only** hardcoded literal is `_isGiveaway => _instance.workflowType == 'equipment-giveaway'`, gating
"borrow" vs. "claim" button copy. **Fix:** derive `_isGiveaway` from a declared JSON property instead of a
hardcoded workflow-type string (e.g. a `cardSurfaceFamily`-adjacent flag or a convention on the
`instanceDataSchema`/workflow definition itself — Implementation Agent picks the mechanism, must not be a
second hardcoded string list). **Do not touch:** queue/return logic (already generic, do not regress).
**Unblocks:** Garden Club's `garden-tool-loan` (borrow) reuse of the same archetype without inventing a
new one.

### Ticket CJM.2 — `type: "url"` field rendering (external only)

**Files:** the shared fact-pill/field renderer (used by `GenericWorkflowInstanceCard` and every archetype —
locate via the `displayIcon`/`labelTemplate` rendering path already read this session), plus
`loom_communities_app_shell/pubspec.yaml` (add `url_launcher`). **Scope:** render `type: "url"` fields per
the locked contract in §1.1 — tappable control, `openMode: "external"` launches via `url_launcher`,
`embedded`/`choice` explicitly out of scope for this ticket (render as disabled/"not yet supported" rather
than crash, OR reject at validator level if `openMode` isn't `"external"` — Implementation Agent's choice,
state which one in STATUS). **Unblocks:** Cedar Commons HOA (`hoa-member-document`), Riverside Youth Soccer
(`soccer-waiver-document`).

### Ticket CJM.3 — citation-list rendering (`itemSchema` on `type: "list"`) (done, 2026-08-10)

**Files:** `workflow_models.dart` (`InstanceDataField.itemSchema`, recursive reuse of the same model),
`part18_marketplace_rendering.dart` (`WorkflowFactPillFieldSchema.itemSchema`, new `type == 'list'` render
branch reusing CJM.2's `url_launcher` tap-to-open primitive), `part26_generic_instance_card.dart` (bridge
wiring). Independent verification found and fixed 3 real bugs the vsock-blocked dispatch's own verification
never caught: a missing `context` parameter on `_factWidget` (compile error), a missing
`api.registerDefinition` call in the dispatch's own new test, and — the significant one — a genuine design
conflict where the pre-existing generic list-of-maps inference (`_isNestedListField`) unconditionally
intercepted every `type:"list"` field before the new `itemSchema`-aware path could ever run, making the
whole feature dead code for its intended shape; fixed with a one-line precedence rule
(`itemSchema` present → skip the generic inference). Full suite green. **Unblocks:** Neighborhood Book Club
(`book-search-ai-digest`), Masjid Nur (`mosque-search-ai-citation`).

### Ticket CJM.5 — `event-rsvp` detail card hardcodes `'event-rsvp'`/`'event-rsvp-response'` instead of reading `responseTable` (done, 2026-08-10)

**Found while judging Riverside Youth Soccer's skill-authored output.** `_EventRsvpDetailCardState`
(`app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart`) — the
real, live widget dispatched for every `cardSurfaceFamily: "event-rsvp"` card
(`part27_engine_native_binding_dispatcher.dart:322-324`) — has `_usesResponseRows` (line 1636) hardcoded to
`_instance.workflowType == 'event-rsvp'`, and `_loadActions`/`_applyTransition` (lines 1773, 1847) hardcode
the literal string `'event-rsvp-response'` for the response-row workflow type, instead of reading
`responseTable.workflowType` off the binding (the same field `_viewerResponseLookupFor`, line 809-837,
already reads correctly for a different summary-view code path in the same file). No real community names
its event workflow type literally `event-rsvp` — Camera Club uses `photo-walk-rsvp`, Garden Club
`garden-event-rsvp`, Riverside Youth Soccer `soccer-practice-schedule` — so for every one of them this
getter evaluates `false`, the response-row's own going/maybe/declined/waitlisted transitions never load
into `_actions`, and the `_RsvpActionChip` buttons a member needs to actually RSVP may never appear.
**Severity note:** if confirmed, this affects the already-merged Camera Club and Garden Club packages too,
not just Riverside Youth Soccer — not a new-community-only gap.

**Status: dispatched, 2026-08-10.** The Root Cause Agent confirmed the diagnosis with a full static
reachability proof (`data/root_cause_report_event_rsvp_response_hardcoded.md`) and surfaced 2 additional
reachable defects beyond the original finding: reminders (`part28...:933`) and recurring-series creation/
deletion (`part28...:1912/1935/2004/2030`) both apply transitions to the hardcoded literal even when they
correctly *find* the custom response row first; and, independently, **brand-new custom-named events receive
zero seeded response rows at all** (`part01_local_extension_screen.dart:404-425/447-462`, gated on the same
literal). Ticket `data/v3_ticket_cjm5_event_rsvp_response_workflow_type.md` written covering all of these as
one atomic fix (the report is explicit that fixing the response-table gate without also fixing the
reminder/recurring call sites creates a new, different breakage) and dispatched via
`call_implementation_agent.sh`.

**Done, 2026-08-10.** Fixed in commit `0259a54f`. Independent verification (mine, outside the dispatch's own
vsock-blocked sandbox) found and fixed the dispatch's own diff was clean (`flutter analyze` 0 errors after 6
real errors/warnings I fixed across `part28_engine_native_calendar_surface.dart` and the dispatch's new
616-line regression test), but the new Garden-fixture regression tests it added surfaced **four further real,
pre-existing bugs** the new tests were simply the first to exercise end-to-end, all fixed in the same commit:
1. Every new test calling `_customResponseFor`/`_customResponseRowsForEvent` did so via a bare `await`
   instead of `tester.runAsync(...)` (the established convention every other real-engine-query helper in the
   same file already follows) — caused 5 of the new tests to hang for the full 10-minute per-test timeout
   each (~50 minutes total) rather than fail fast. Fixed by wrapping all 8 call sites.
2. `GenericWorkflowCreationCard._normalizedValue` (`part33_generic_creation_card.dart`) never parsed
   `type: "number"` fields — a numeric text field's raw string went straight into `createInstance`, crashing
   any widget that later does `... as num` on it (here, `_EventRsvpDetailCardState.build`'s capacity read).
   Pre-existing, affects every community using the generic creation form for a numeric field; no prior test
   exercised create-via-form-then-view-detail for one. Fixed with a `num.tryParse` pass.
3. `resolveEffectValue` (`effect_evaluator.dart`) left a whole-string `"{field}"` template as literal
   unsubstituted text when the referenced field was absent on the source instance, instead of resolving to
   `null` (as its sibling `{input.X}` branch already correctly does) — crashed formula evaluation on any
   `generateRecurringInstances`-created sibling whose optional field was unset on the anchor. Fixed with an
   explicit null fallback, careful to exclude `{id}` (substituted later, by design) from that fallback after
   an initial version of the fix broke 4 existing engine tests that rely on `{id}` falling through.
4. Garden Club's own `make-recurring` effect never stamped `seriesId` onto its generated siblings (present
   in Tabletop's equivalent effect, missing here) — recurring events never joined their series. A genuine
   JSON-authoring gap in the merged Garden Club package, fixed directly in the `.jsonc` file (plus the
   missing `seriesId` schema declaration) and re-validated (`status: pass`, 0 errors).
Also fixed two test-only bugs (a stale `ensureVisible` before a facet-chip tap whose position shifted once
CJM.5's own fix correctly renders more event-detail content; a hardcoded assumption that `respond-going`
always shows an input dialog, false for Garden Club's undeclared-input transition) and one test logic bug
(`count` passed as `2` but the poll expected 3 total series events — `count` is documented as the *total*
occurrence count including the anchor, confirmed against a passing sibling test).

**Verification:** `flutter analyze` clean on `loom_workflow_engine` and `loom_communities_app_shell`
(4 harmless pre-existing `prefer_const_constructors` info-lints only). Full `loom_workflow_engine` suite:
206/206 passing. Full `loom_communities_app_shell` suite: 214/215 passing — the one failure
("organizer creates an event and one pending response per member") independently confirmed via `git stash`
to reproduce identically against pre-CJM.5 code, i.e. genuinely pre-existing and unrelated to this change,
not newly introduced or newly discovered-and-ignored.

**Regression Impact Judge: dispatched and completed, 2026-08-10.** Independently re-ran both full test suites
(206/206 `loom_workflow_engine`, 214/215 `loom_communities_app_shell` — same one pre-existing flaky test) and
the validator across every community package (0 errors, `status: pass`). Traced every real `responseTable`
consumer's own schema/`source` query against the fix's derivation logic and confirmed a match: Tabletop Club
(directly tested, all pass), Garden Club (directly tested via the new regression suite, all pass), Camera
Club, Riverside Youth Soccer, Masjid Nur, Neighborhood Book Club (traced, schema-confirmed, no dedicated
widget-test coverage for any of these four — a **pre-existing** gap, not introduced by this fix). Confirmed
Cedar Commons HOA's merged package and the legacy `part02_tab_shell.dart` fixture never engage the mechanism
at all (no `responseTable` declared), unaffected before and after. Separately swept every community's own
`effects`/`fields`/`recurrenceRule` blocks for the `resolveEffectValue` null-fallback's blast radius (the
widest-reach change in this commit, since that function is used engine-wide, not just for event-rsvp) and
found no other consumer has a comparable genuinely-optional-field-in-a-template pattern — Garden Club's
`reminderOffsetHours` was the only real instance, already the fix's own target.

**Two explicit, non-blocking follow-ups from the judge** (not gating this ticket, matching the CJM.6
precedent of naming rather than silently dropping open items): (1) Camera Club/Riverside Youth
Soccer/Masjid Nur/Neighborhood Book Club have no dedicated automated widget-test coverage of their own
event-rsvp detail card — a good candidate for a future live/emulator RSVP-button spot-check on each,
independent of this fix; (2) the judge observed the same pre-existing flaky-test failure signature but did
not itself re-run the `git stash` before/after comparison that established its pre-existing status — that
comparison was done directly by the orchestrating session (this fix's independent verification), not
re-derived by the judge.

### Ticket CJM.6 — `create` action `prefill` never resolves `$actor` (either scope), `scope: "tab"` drops `prefill` entirely (done, 2026-08-10)

**Found while judging Ad-Free Community's skill-authored output, independently confirmed by direct source
read (not just trusting the judge).** `render-bindings.md` documents `prefill` values as using "the effect
interpolation grammar plus `{context.*}` (instance scope only)" — i.e. `$actor`/`$timestamp` are meant to
work in `prefill`, same as in transition effects. Confirmed broken in two compounding ways:
1. `scope: "tab"` creates never resolve `prefill` at all —
   `part01_local_extension_screen.dart:1230-1246` builds `_CreatableWorkflowAction`s with
   `resolvedInitialValues` left at its `const {}` default; `action.prefill` is never read.
2. Even where prefill IS resolved (`scope: "instance"`, via `resolveInstanceScopedPrefill`,
   `instance_scoped_action_context.dart:8-24`), only `{context.id}`/`{context.<field>}` are substituted — a
   literal `"$actor"` value passes through **unchanged as the 4-character string**, not the real acting
   persona id.

**Blast radius — higher than CJM.5.** `"prefill": {"<ownerField>": "$actor"}` on a `scope: "tab"` create
action is the standard, near-universal pattern for stamping an effect-only ownership field at creation
time. Already-merged Camera Club (`gear-loan-request`, `critique-submission`) and Garden Club
(`plant-exchange-submission`, `garden-tool-loan`, `garden-tool-giveaway`) both use it; so do Chess Club,
Riverside Youth Soccer, Neighborhood Book Club, Masjid Nur, and the in-progress legacy communities. If
uncorrected, every affected create flow produces an instance whose owner/actor field is absent or a literal
`"$actor"` string — permanently un-actionable (guards keyed on that field can never match a real persona)
and, where `visibility.readGuard` also keys on it, unreadable even by its own creator.

**Full ticket:** `data/v3_ticket_cjm6_create_action_prefill_actor_resolution.md`. **Fix (already diagnosed,
no Root Cause Agent needed — confirmed via direct source read):** thread `action.prefill` through for
`scope: "tab"` creates (mirroring the `scope: "instance"` branch immediately below it in the same
function), and extend the prefill value-resolver to substitute `$actor`/`$timestamp` the same two tokens
`effects.md` already defines for transition effects. **Status:** ticket written, not yet dispatched.
**Before this ticket is marked done:** a dedicated Regression Impact Judge dispatch
(`docs/Build Plan V2/Tools/regression-impact-judge-tool.md`) covering every community using `$actor` in a
create-action `prefill` — at minimum Camera Club and Garden Club (already merged) — confirming their real
create flows produce working, readable, actionable instances, not just this ticket's own new test.

**Done, 2026-08-10.** Fixed in commits `8ec0af17` (fix) + `6df2024f` (independent-verification follow-up —
found and fixed a real Dart compile error the dispatch's own vsock-blocked verification never caught, plus
3 real bugs in the dispatch's own new regression test: wrong workflow type mutated, fabricated widget key
names, and a helper that left a dialog open blocking the FAB under test). **Regression Impact Judge
dispatched and completed** (`docs/Build Plan V2/Tools/regression-impact-judge-tool.md`) — every real
consumer at time of fix (Camera Club, Garden Club, Masjid Nur, Riverside Youth Soccer, Data Portability
Community, Chess Club) individually traced against its own guards/readGuards/formulas and confirmed
genuinely repaired, not just compiling; the pattern-7 workaround communities (Ad-Free Community, Member
Social Space) confirmed on a fully independent code path, unaffected either way. `flutter analyze` clean;
full suite shows zero new failures beyond the one pre-existing known-flaky test. Two small non-blocking
follow-ups noted by the judge, not gating this ticket: (1) Data Portability Community's `export-transfer`/
`export-transfer-rollback` `requestedAt` field — worth an emulator spot-check to confirm the pre-fix literal
`"$timestamp"` string didn't hard-block creation via strict date-field validation (severity unconfirmed,
now moot either way since the fix produces a real timestamp); (2) Tabletop Club's own reference JSON still
has 3 tab-scoped create actions with `GAP-2` comments describing exactly what CJM.6 now fixes but never
retrofitted with real `prefill` — a good, low-risk cleanup candidate, not urgent.

### Ticket CJM.4 — validator rule: `no_render_binding_for_reachable_state` (done, 2026-08-09)

Real Dart validator gap, not a docs fix — the D3 finding from judging the skill-authored Cedar Commons HOA
package (3 reachable terminal states with no `renderBinding` coverage, invisible in the UI despite being
grammar-valid). Added `WorkflowValidator._checkNoRenderBindingForReachableState` (warning-only, same
"expected affordance" heuristic family as `no_read_visibility_declared` et al.), documented in
`guide/05-validation.md`'s "Expected affordances" table, mirrored into `chatgpt-upload/04-validation.md`.
Dispatched via Codex CLI (`data/v3_ticket_cjm4_validator_render_binding_coverage.md`); the dispatch's own
`flutter analyze`/test verification was blocked by a WSL vsock failure, so it landed marked "blocked" —
independent verification (me) found and fixed 3 real regressions the blocked dispatch never caught: a new
test misclassified `unreachable_state` as a warning (it's an error), and 2 existing tests / 2 HTTP-server
fixtures lacked renderBinding coverage the new check now correctly (and harmlessly) flags. Full suite: 155
pass, 0 fail. Cedar Commons HOA re-validated clean (0 errors, 0 warnings) — the new rule does not fire
against the already-D3-fixed shipped package. Commits `d0936638` (validator) / `fdf8a181` (skill self-check
docs, D1/D4 — see below), pushed.

**Also landed in the same cycle (not itself a CJM ticket — skill-instruction changes, not app code):** the
`loom-calendar-experience-authoring` Skill's `SKILL.md`/`chatgpt-upload/00-INSTRUCTIONS.md` gained Hard
Rules 8-9, making the Skill self-check two more defect classes a validator pass can never catch: D1
(`event-rsvp` date/time fields must be named literally `eventDate`/`eventTime` — a hardcoded Dart-string
read, not a grammar rule) and D4 (product-doc retry/resubmit language must be cross-referenced against the
transition graph's `from` lists). Both are now mandatory steps in the validate-and-fix loop and its
no-validator-access fallback. **Next step**: re-dispatch the Skill a third time against Cedar Commons HOA
to test whether it now avoids D1/D4 on its own (D3 is now also caught automatically by the validator
itself, regardless of the Skill's own behavior).

**Outcome (2026-08-09) — the re-run happened, and found a NEW defect class (D5).** A third, blind
skill-authoring dispatch against Cedar Commons HOA (sandboxed away from all 3 prior JSON artifacts and every
judge report) was run, followed by an independent judge pass. Result: **D1 and D4 were both caught
unassisted** — the judge independently verified every `event-rsvp` date/time field used the literal
`eventDate`/`eventTime` names, and all 3 retry-shaped transitions (`pay`, `request-export`, `reopen`)
correctly covered every state a real retry could come from (the Skill's own output even widened `reopen` to
cover both `approved` and `denied`, better than the original hand-applied D4 fix which only touched one
transition). D3 fired automatically via CJM.4's validator rule against a deliberately-unbound notification
type, and was correctly recognized as an intentional, documented pattern rather than blindly "fixed."

The judge also found a genuinely new bug class it wasn't asked to look for: **D5 — a transition can be
guard-correct and pass CJM.4's `no_render_binding_for_reachable_state` check, and still be a dead button**,
because a `renderBinding`'s `role` (`actor`/`receiver`) is not part of the JSON grammar at all — it's
resolved per-tab by App Shell dispatch code, confirmed by direct source read to be sharply asymmetric:
`admin` is the only tab where `role: "receiver"` ever resolves to anyone; `giving`/`home`/`messages`/
`marketplace` only ever grant `"actor"` to the literal `createdByPersonaId` (never "whoever the guard is
really about"); `calendar` grants neither role at all (only `role: "any"` renders there). The already-shipped
canonical Cedar Commons HOA file had several real instances (e.g. a homeowner could never withdraw their own
architectural request once submitted — the button silently disappeared; the board could never record a
failed dues payment). Full remediation cycle, same pattern as D1/D3/D4:

- **Fixed the canonical file** additively (role widened to `"any"`, a `states` list expanded, or one binding
  split into two — no guard/transition/persona-list logic touched). Re-validated clean throughout. Commit
  `8cf2b971`.
- **Documented the mechanism** in `render-bindings.md`'s new "⚠️ `role: "actor"`/`"receiver"` resolution"
  normative table, and added it to the Skill as Hard Rule 10 (mandatory self-check step, since — like D1/D4
  — it can never appear as a validator finding). Commit `fcbcf235`.
- **Ticket CJM.5** (`data/v3_ticket_cjm5_validator_dead_role_binding.md`) — a new validator rule,
  `dead_role_binding`, catching the two *purely structural* (no guard analysis needed, zero false positives
  given current dispatch wiring) shapes of this bug: `role: "receiver"` on any non-`admin` tab without
  `audienceMemberField`, and any non-`"any"` role on `calendar`. (The third, harder pattern — `"actor"`
  resolving to the wrong persona when the guard targets a non-creator field — isn't statically decidable from
  the binding alone and is Skill-self-check-only, not a validator rule.) Same vsock-blocked-dispatch pattern
  as CJM.4: the Codex dispatch landed real code but its own verification was blocked; independent
  verification found the new rule correctly firing as *real, previously-invisible* bugs in 6 legacy Phase 5
  fixtures (Garden Club, Camera Club, Book Club, Youth Soccer, Mosque, HOA-dues) — extended
  `_knownAffordanceGapTypes`/inline tolerances the same way CJM.4 required, fixing each fixture individually
  deferred (tracked here, not in this ticket). Full suite: 160 pass, 0 fail. Commits `8e5c7feb` (rule) /
  `69d8a09a` (test tolerance), pushed.

**This closes the D1-D5 loop for Cedar Commons HOA specifically as far as this session's remediation cycle
goes.** Remaining before the community row in §4 can close: the §6 live UX Judge walkthrough (never run
against the merged/fixed file, only the original pre-merge hand-authored version).

## 3. Product-doc expansion tasks (locked: expand only, never remove)

Each is a real doc edit, not just a decision — the doc file itself must gain the sections below before that
community's JSON is treated as locked, since the JSON should implement the doc's full (expanded) scope.

| Community | Doc file | Expansion needed |
|---|---|---|
| Chess Club | `docs/references/communities/chess-club-product-experience.md` | **Done, 2026-08-10.** Confirmed `chess-local-install-open`/`chess-route-home` are unreachable dead code (no real `LoomWorkflowDefinition` anywhere ever uses either id) — do not author JSON for them. Doc expanded to cover all 8 real workflows (`chess-club-night`, `chess-discussion-thread`, `chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`, `chess-rules-documents` added to every table alongside the 2 already-documented ones) plus 2 confirmed AP-6 bugs (fabricated checksum, fake ranking-delta) and 2 structural gaps (fictional `tabId`s `matches`/`rankings`/`documents`; fictional `cardSurfaceFamily`s `dashboard`/`table`/`exportWizard`/`documentLibrary`/`calendarAgenda`) flagged with real-archetype candidates for the authoring Skill. Ready for skill-authoring dispatch. |
| Masjid Nur | `docs/references/communities/masjid-nur-product-experience.md` | **Done, 2026-08-10.** Confirmed via the real implementation (`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`, 9 workflowDefinitions) that `mosque-document-resource` doesn't exist (build fresh from doc requirements) and `mosque-discussion-thread` is real but was undocumented (added to doc). Also confirmed `wf_demo-app-persona-picker`/`wf_community-persona-aware-ux`/`wf_multi-persona-workflow-evidence` are B18/B19/B20 Dart test names, not real workflows — do not author JSON for them (same dead-code pattern as Chess Club). 10 total real+new workflows. `mosque-search-ai-citation` needs the citation-list extension (§1.2 / CJM.3, now landed). |
| Neighborhood Book Club | `docs/references/communities/neighborhood-book-club-product-experience.md` | Doc wants `book-shared-library` (searchable, loan/giveaway, queue); implementation has generic `book-library-item`. Reconcile as **one** workflow, expanded to deliver the doc's full richness, under a name that preserves both (decide exact id when authoring JSON). `book-search-ai-digest` needs the citation-list extension (§1.2 / CJM.3). |
| Riverside Youth Soccer | `docs/references/communities/riverside-youth-soccer-product-experience.md` | `soccer-team-discussion` is implemented but not in the doc — add it, keep it. `soccer-waiver-document` needs `type: "url"` (§1.1 / CJM.2). |
| Garden Club | `docs/references/communities/garden-club-product-experience.md` | Doc wants a combined `garden-tool-loan-giveaway`; implementation has separate `garden-tool-loan` + undocumented `garden-volunteer-shift`. Keep both tool-loan and volunteer-shift (nothing removed); expand doc to document volunteer-shift. `garden-tool-loan`'s borrow flow depends on CJM.1's generalization fix to reuse `equipment-loan` cleanly. |
| Camera Club | `docs/references/communities/camera-club-product-experience.md` | `camera-validation-report` is implemented but not in the doc, and was independently confirmed by an earlier B25 judge finding to be pure scaffolding with zero real content. **Decision (made under the never-remove rule, not before it):** this is dropping an undocumented, contentless placeholder, not removing a real interaction — the never-remove rule protects real workflows/interactions, not empty scaffolding. Proceeding to drop it; flagged here for visibility rather than silently carried forward. |

No doc-mismatch found for Cedar Commons HOA — its JSON is already authored 1:1 against its doc. **Member
Social Space / Ad-Free Community / Data Portability Community are "pure legacy" (§0) — no JSON exists at
all for any of them, only hand-authored Dart, so there is no doc-vs-implementation mismatch to reconcile in
the first place** (unlike the 6 hybrid communities above, which each have a real, divergent JSON to
reconcile against). Their reconciliation pass, done 2026-08-10, instead: moved each doc to
`docs/references/communities/` (the only location the Skill reads from — they were not there before),
added a missing persona row each doc's own §7 rows already implied but never gave its own row (Blocked
Member / Ad-Free Viewer / Receiving Provider), and flagged two structural gaps every one of these 3 docs
shares with several already-reconciled docs: required custom tabs that don't exist in the real closed
`tabId` enum, and the superseded CardSurfaces-registry vocabulary trap. See §4 rows 8-10.

## 4. Per-community status

JSON files land at `docs/references/communities/Loom_Communities_Workflow_Engine_<Name>_Example.jsonc`,
following the Cedar Commons HOA pattern (grammar-verified inline comments explaining archetype-reuse
reasoning, kept as durable doc, not just chat explanation).

| # | Community | Doc reconciliation | JSON authoring | Known code gaps | UX Judge walkthrough |
|---|---|---|---|---|---|
| 1 | Cedar Commons HOA | Locked (7 workflows, 1:1 with doc); event-rsvp-vs-equipment-loan question for facility reservation settled (event-rsvp — see the file's own header comment) | **Skill-authored (full, all 7 workflows), judged PASS, merged into canonical 2026-08-09** — validator-clean (0/0), no AP-6 fabrication, correct archetypes throughout, both bugs in the old hand-authored version fixed (inert `creationGuard`/`locationOverlap`, fabricated `checksum`/`receiptId`). 5 defects found across two judge passes (D1 `eventTime` field-name, D3 missing terminal-state bindings, D4 repeat-failure guard, D5 dead role/tab bindings) all fixed; D3 and D5's purely-structural shapes now caught automatically by validator rules (CJM.4, CJM.5); D1/D4/D5 all taught to the Skill itself (Hard Rules 8-10) — **confirmed 2026-08-09**: a 3rd, blind skill re-dispatch avoided D1 and D4 completely unassisted (independently judged). | CJM.2 (done, see §1a); CJM.4 (done); CJM.5 (done, 2026-08-09 — see §2); the `role:"actor"`-vs-payer design question flagged in §1a #4 was exactly D5 — now resolved (fix + validator rule + Skill self-check), same shape worth re-checking on Garden Club given the near-identical dues-payment pattern | **Done, 2026-08-10 — row closed.** Live walkthrough ran end-to-end on-device (install, both personas, all tabs): found ONE real, blocking, novel bug (Board's Admin tab crash — traced by the Root Cause Agent to a genuine App Shell lifecycle gap unrelated to this community's JSON, fixed as AuthZ.P8, commit `6bae3cec`, re-verified live with zero crash and correct role-resolved content rendering). The judge's remaining ~55 findings were triaged and are **accepted, documented grammar-tier limitations, not bugs**: (a) the 6 🟡 GENERIC archetypes render via the shared `GenericWorkflowInstanceCard` fact-pill+form template by design — no bespoke per-family visual treatment exists yet for any community, this is a known investment gap in the archetype tier itself, not something wrong with this community's JSON; (b) no `Documents`/`Requests` tab exists because the `tabId` enum is closed to `{admin, calendar, giving, home, marketplace, messages}` — already disclosed in the file's own header comment before this walkthrough ran; (c) several "missing action" findings (no pay button visible, no cancel on a reservation) trace to the same generic-card template not surfacing every available transition as prominently as a bespoke widget would — same root cause as (a), not a new defect. None of these block real usage (every guard-permitted transition IS reachable, per the D5 remediation) — they're a polish/investment gap for a future session, not a correctness bug. Full product-doc reconciliation gate (§6 step 7) deliberately not run as a second full pass — the walkthrough + reconciliation-flavored judge dispatch already covered its ground in one combined pass this cycle; re-running it separately would re-derive the same accepted findings above. |
| 2 | Garden Club | **Done, 2026-08-10.** Skill-authored (split `garden-tool-loan-giveaway` into `garden-tool-loan`/`garden-tool-giveaway`, defensible per the type-vs-instance test), independently judged (FAIL, 3 findings), all fixed and re-validated (0 errors, 7 expected warnings): `delist` guard gap on both marketplace types (could strand custody), unwired `garden-notification` effects for `request-loan`/`claim`/`sign-up`, and a doc-internal B25 §9 inconsistency for `plant-exchange-submission` (corrected in the doc, not the JSON). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | CJM.1 (landed, used); CJM.7/CJM.8 legacy-shim removal (§0.2) unblocked this row's walkthrough; CJM.9 (sideload no-op) was the real blocker beneath both of the row's first two failed attempts; CJM.10/CJM.10b/CJM.11/CJM.11c/CJM.12/CJM.13 (§0.4) — all shared code, fixed here first, benefits every remaining community | **Done, 2026-08-11 (walkthrough #4) — row closed for the shared-code gate; §6 step 7 product-doc reconciliation not yet run.** First two attempts (2026-08-10) were both invalid — attempt 1 hit the legacy-shim shadowing bug (§0.2 original text below, preserved for history), attempt 2 (post-shim-removal) still showed no real content because of the then-undiscovered CJM.9 sideload no-op (§0.2/§0.3). Attempt 3 (§0.3), after CJM.9's fix, was the first genuinely valid evidence this migration effort collected — confirmed real JSON-driven content on Home/Exchange/Calendar, but its own LLM Vision UX Judge found 5 major, 4 minor findings, all in shared code. Attempt 4 (§0.4, this row): all 5 major findings fixed (CJM.10-13 + CJM.11c) and independently re-verified live via a corrected two-pass judge review — genuinely resolved. 4 new non-blocking findings tracked for a future pass (§0.4). Original attempt-1 discard note, preserved: the real package was installed and 6 real screenshots captured across both personas, but `part02_tab_shell.dart`'s legacy `_GardenClubEngineTabSurface` shim shadowed the entire community and rendered its own independently-hardcoded fixture instead of the reviewed JSON — confirmed by exact text mismatch (legacy fixture's `"Riverside Greenhouse"`/`"18 of 24 spots"` vs. the real JSON's `"Community Garden Plot A"`/`capacity: 20`) and a legacy-only fabricated checksum (`"8F4A-PLANT"`, `part02_tab_shell.dart:9054`) that doesn't exist in the real JSON at all. |
| 3 | Neighborhood Book Club | **Done, 2026-08-10.** Skill-authored (first real use of the new Hard Rule 11 requirement traceability table), independently judged (FAIL, 2 real issues: an isTerminal contract violation, and `book-vote-response`'s only creation path resting on a not-yet-implemented `scope:"instance"` create action), both fixed and re-validated (0 errors, 9 expected warnings). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | CJM.3 (landed, used) | **Run 2026-08-11 — NOT closed, real findings pending.** Sideload confirmed genuinely working (own generator, `tool/generate_book_club_package.dart`, overriding both `communityId`/`extensionId` to match the preloaded shell since this fixture's own ids — `community_neighborhood_book_club`/`ext_neighborhood_book_club` — differ from the preload's `community_book_club`/`ext_book_club`, unlike Garden Club where they happened to match). Real, package-specific content confirmed on Home (a genuine discussion-questions card about *The Song of Achilles*), Calendar (a real Sep 2026 meeting), and Marketplace (`The Odyssey (audiobook)`, `The Song of Achilles`, `Trivial Pursuit: Book Lovers`). A fresh LLM Vision UX Judge dispatch found the CJM.9 fix and the disabled-Save-hint fix (CJM.10) generalize cleanly to this second, differently-themed community, but **several of CJM.11/12/13's fixes do not fully generalize** — this is genuinely new information Garden Club's single-community re-verification could not have caught: (a) longer item titles still truncate past the fixed `maxLines: 2` budget (moderate-length titles/holder text render fine; longer ones like "The Song of Achilles (paperback)" don't) — a real remaining limit of the specific fix, not a regression; (b) the Calendar weekday header (CJM.12) renders in a fixed color that is illegible against this community's dark brown theme — needs to bind to a theme foreground token, not a literal color; (c) FAB-occludes-content (CJM.13) recurs on the **community list screen itself** (the "Add Community" FAB covering the last card) — a surface Garden Club's own re-verification evidence never captured, so CJM.13's fix was never actually proven there. Also newly found: a raw `label`/`source` schema-token leak on an instance card, and a marketplace listing simultaneously chipped "Available" and "Overdue". None of these are sideload/data-correctness failures — the core mechanism and content are genuinely real. **Triaged and closed, 2026-08-11:**
- **Theme-aware weekday header color** — real bug, fixed directly as **CJM.14** (`431f55f2`): the header `Text` had no style at all (inheriting an unrelated ambient color); now uses `modernTheme.resolvedHeading`, matching the token already used for date-number cells. Independently verified (`flutter analyze` clean, 227/227 with the one known flaky test); live-reverified on Book Club — header now legible.
- **Community-list FAB "covering" the last card** — investigated live by scrolling the community list to its actual end: the last card (`Data Portability Community`) is fully clear of the FAB with room to spare, proving the 128px bottom padding already there is sufficient. The earlier screenshot was taken at a **mid-scroll** position, where a FAB transiently overlapping whatever's beneath its fixed screen position is completely standard, expected Material FAB behavior — not the same defect class as CJM.13 (which was about content staying **permanently** unreachable even at full scroll). No code change; not a real bug.
- **Raw `label`/`source` schema-token leak** — real bug, but a **JSON-authoring gap, not shared code**: the citation `itemSchema`'s `label`/`source` sub-fields had no `labelTemplate`, so the generic renderer correctly fell back to the raw field key per its own documented convention — and one key happens to literally be the word "label", producing an especially confusing render. Found the exact same unlabeled shape, copied from the same CJM.3 citation-list precedent, already present in **Cedar Commons HOA and Masjid Nur's fixtures too** (both already marked "done" earlier this session) — fixed all three consistently, re-validated (0 errors each), live-reverified on Book Club (citation now shows "Madeline Miller official reading guide" as real text plus a tappable source link). Committed `159428c7`.
- Longer-title truncation past `maxLines: 2` and the contradictory `Available`/`Overdue` chip pair are real, lower-severity polish items **left open, deferred** — not blocking, matching the Cedar Commons HOA precedent for accepted findings.

**Row closed, 2026-08-11.** Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-book-club-1/`. |
| 4 | Riverside Youth Soccer | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL, 1 real JSON defect + 1 shared App Shell bug), JSON defect fixed and re-validated (0 errors, 5 expected warnings): `soccer-export-metadata`'s `completed` state was declared `isTerminal: true` while `rollback-export` left it (a direct grammar contradiction). The judge also found CJM.5 (see §2) — a shared, cross-community bug, not fixable in this JSON; tracked separately, does not block this row from closing. JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc`. Row closed pending §6 live UX walkthrough (which should also verify CJM.5's real-world impact once fixed). | Not started | CJM.2 (landed, used); CJM.5 found here, affects this + other communities; CJM.15 found here, shared code | **Run 2026-08-11, row closed.** Confirmed CJM.5's fix live: the "Tuesday evening practice" event-rsvp instance correctly reads its own `responseTable`, showing real, arithmetically-consistent attendance ("1 / 20 going", "19 seats left") and a real Attendees list ("Going: soccer-coach", "Pending: soccer-guardian"). Confirmed CJM.2's documented `openMode: "choice"` unsupported-fallback behavior renders as expected (not a bug). A fresh LLM Vision UX Judge dispatch found the calendar weekday-header (CJM.12/14) and RSVP-data fixes generalize cleanly to this third community/theme, but surfaced two more real, shared-code gaps that CJM.11's original humanizer never covered: raw booleans (`Rescheduled: false`) and hyphenated identifiers (`Calendar sync: not-synced`) were never humanized at all (CJM.11 only handled underscore-separated strings, not booleans or kebab-case). Fixed as **CJM.15** (`86f355f9`) — booleans now render Yes/No, and the identifier regex accepts hyphens as word separators — independently verified (`flutter analyze` clean, 226/226 with the one known flaky test), live-reverified. Also found and fixed the same missing-`labelTemplate` pattern already seen on 3 other communities: the `location` field had no `labelTemplate`, so it rendered its own raw key instead of "Riverside Sports Complex" — fixed (`90601aaf`), live-reverified. The judge's other findings (Giving-tab empty-state messaging, no RSVP action control visible, minor copy/truncation items) are lower-priority polish, left open and deferred, matching the established accepted-findings precedent — none are correctness bugs. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-youth-soccer-1/`. |
| 5 | Chess Club | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL, 1 real AP-11 violation — a silently dropped "queue position" requirement backed by a false justification), fixed via a real redesign (shared queue container + ordered list, not just a gap marker) and re-validated (0 errors, 1 expected warning for a deliberate singleton type). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | None identified | **Run 2026-08-11, row closed.** Real content confirmed throughout (Maya Patel #1/1500 pts ranking, Thursday club night, Season 2026 export scope). CJM.12/14 (weekday header) and CJM.10 (disabled-Save hint) both confirmed holding on a fourth community. **New real finding, deferred (not fixed this pass):** raw ISO-8601 dates/timestamps (`Updated 2026-08-08T10:00:00Z`, calendar day chips `2026-08-13`) are never humanized — a genuinely separate gap from CJM.15, since the identifier-detection regex requires a leading letter and ISO dates start with a digit, so they never reach the humanizer at all. This needs real date parsing/formatting (not a regex extension) and is deferred to a future ticket rather than implemented mid-walkthrough, given this session's already very large scope — tracked explicitly, not silently dropped. FAB-occlusion findings across all 5 screens are the same known evidence-coverage pattern (mid-scroll screenshots) already established twice this session for Garden Club and Youth Soccer; not re-chased given CJM.13 already independently proven at true max-scroll multiple times. Remaining findings (unhumanized `Delta` field key, chip/field duplication, `2 roles` ambiguity, Admin capability coverage, nav tab clipping) are minor polish, deferred per the established accepted-findings precedent. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-chess-club-1/`. |
| 6 | Camera Club | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL, 5 findings), all 5 fixed and re-validated (0 errors, 5 expected `no_render_binding_for_reachable_state` warnings). The original §3 "drop `camera-validation-report`" framing turned out too narrow — the doc's §3/§5 rows ask for real, honestly-derivable content (requested-workflow list + implemented status), not just the "package paths" scaffolding that was the actual AP-6 concern; restored as `camera-validation-report` carrying only the real part. Also fixed: dead `send-reminder` transition (hits App Shell's `_hiddenAutomaticActionIds`) replaced with a member-owned `set-reminder` action on `photo-walk-response`; `delist` guard gap that could strand a borrower's gear; Critique-tab-folded-into-Home now documented. JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc`. Doc: see `camera-club-product-experience.md` §10 for full notes. Row closed pending §6 live UX walkthrough. | Not started | None identified | **Run 2026-08-11, row closed.** Real content confirmed throughout (Golden Gate sunrise walk, Canon 70-200mm lens loan, speedlite giveaway). A fresh LLM Vision UX Judge dispatch found 11 items, but on inspection every one is either an already-known, already-triaged pattern from prior communities (community-list "updated card" highlight quirk — the app's own focused-community logic, not a data bug; FAB occlusion in mid-scroll screenshots — known evidence-coverage gap, not re-chased given CJM.13 already independently proven at true max-scroll on 2 other communities; raw ISO date chips — the same deferred date-formatting gap found on Chess Club; item-title truncation past `maxLines: 2` — the same deferred limit found on 2 other communities), a **by-design decision already made earlier this session** (the judge flagged the Home tab's "3 workflows requested"/"3 implemented and validated" counters as "build scaffolding" — this is in fact the deliberately-restored `camera-validation-report` workflow, per this row's own JSON-authoring note above: "the doc's §3/§5 rows ask for real, honestly-derivable content... restored... carrying only the real part" — not a defect), or new minor polish (gear-card visual hierarchy, role-text duplication, Organizer gear-custody action scope) deferred per the established accepted-findings precedent. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-camera-club-1/`. |
| 7 | Masjid Nur | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL, 1 real issue — no creation path for `mosque-donor-visibility`), fixed by wiring donation-payment's `pay` transition to create a real per-donation visibility row, re-validated (0 errors, 7 expected warnings). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | CJM.3 (landed, used) | **Run 2026-08-11, row closed.** Real content confirmed throughout (Iftar setup crew volunteer shift, Arabic Literacy Class event). Found the same missing-`labelTemplate` pattern already fixed 3 times this session, now on `shiftDate`/`shiftTime`/`location`/`isFull`/`hasWaitlist` — fixed directly. **Real operational discovery, documented for future walkthroughs**: pushing a fixed package and re-tapping "Validate and install" on an *already-hydrated* community is a no-op — CJM.9's own idempotent-reimport guard (`existing != null && !shouldHydratePreloadedShell`) correctly declines to re-hydrate, so the first re-verification screenshot still showed the old, unfixed chips, and the judge correctly flagged them as still-broken from that evidence. **Did a full app restart (clears the in-memory backend back to preloaded/empty shells) and re-sideloaded fresh** — live-confirmed the fix genuinely works: chips now read "2026-08-14", "17:30", and "Full: No" instead of the bare `shiftDate`/`shiftTime`/`isFull` keys. Also swept and fixed the identical `isFull`/`hasWaitlist` gap already present (but not yet fixed) in Garden Club's own fixture, found during this same sweep. Both fixtures re-validated (0 errors). Remaining findings (Giving-tab empty-state messaging, calendar event-title truncation, ISO date formatting — known deferred gap, FAB occlusion — known evidence-coverage pattern, duplicate signup-count chips, internal-jargon copy) are UX polish, deferred per the established accepted-findings precedent. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-masjid-nur-1/`. |
| 8 | Member Social Space | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL, 2 real issues: CJM.6 with no fallback stamping mechanism, and a blocker-identity privacy leak contradicting the doc's own correction note), both fixed via solved-patterns.md pattern 7 (draft pre-stamp state) and a `displayContexts` fix, re-validated (0 errors, 0 warnings). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | **CJM.16 found here, not yet fixed** — see walkthrough notes | **Run 2026-08-11, row closed.** Confirmed CJM.10/11/11c/12/14/15's shared-code fixes all hold on this seventh community's distinctive named-individual persona model (personas are "Alex Rivera"/"Bailey Chen"/"Casey Nguyen", not role types — by design, matching the messaging purpose). The judge flagged a `critical-blocker`: the Messages tab — this community's stated core purpose — shows zero conversations for the freshly-signed-up "Alex Rivera" account, with no empty-state messaging. **Root-caused, not just accepted at face value**: the fixture seeds 3 real `platform-message-thread` instances with `participantAPersonaId` literally `"platform-member-alex"`, matching the exact persona this walkthrough signed up as, gated by `visibility.readGuard: "$viewer == participantAPersonaId || $viewer == participantBPersonaId"` — so the threads *should* be visible. They are not because `LocalAuthApi.signUp` (`part30_local_auth_api.dart:157`) generates `accountId: '$personaTypeId-$counter'` (e.g. `"platform-member-alex-1"`), a numeric-suffixed value that never equals the seed data's bare `"platform-member-alex"` string used both as the guard's comparand and (per the `start-thread` transition's `$actor`-stamping effect) as what a live-created thread's own participant field would actually be set to. This is a genuine, systemic identity-matching gap between how seed data authors participant references and how live accounts are identified — not previously exercised because every other community's guards use `allowedPersonaIds` against the stable `personaTypeId`, not formula guards comparing against literal seeded instance-data strings. **Deliberately not fixed live this pass** given real blast radius (the fix reshapes either `$actor`/`$viewer` resolution semantics or the seed-data authoring convention, affecting every formula guard in every community) — tracked as **CJM.16**, recommended as its own dedicated future ticket with a Root Cause Agent dispatch first to determine the correct fix shape. Other findings (sponsor card showing advertiser view/click telemetry to a Member persona with no message body and a contradictory "No sponsored message right now." banner alongside a real sponsor card, Admin tab empty for the Member persona, internal-jargon copy, FAB occlusion on the community list, an unexplained "4 roles" chip, the identity hero repeating on every tab) are UX polish or already-established deferred patterns, left open per the accepted-findings precedent. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-member-social-space-1/`. |
| 9 | Ad-Free Community | **Done, 2026-08-10.** Skill-authored, independently judged (FAIL — CJM.6's `$actor`-in-`prefill` bug broke both checkout entry points), fixed via the Skill Retrospective process using the new pattern-7 workaround (stamp actor identity via an effect on the first transition instead of `prefill`) rather than waiting on CJM.6 to land, re-validated (0 errors, 0 warnings). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | **CJM.17 found here, fixed** — see walkthrough notes | **Run 2026-08-11, row closed.** Confirmed CJM.6's pattern-7 checkout fix holds live, end-to-end: signed up as Member, tapped through the full real checkout (Buy ad-off -> Turn off ads -> Confirm payment) with zero exceptions, correctly spawning linked `ad-off-entitlement-status`/`ad-off-receipt-evidence` records. The judge flagged a raw field-key leak (a bare `daysSincePurchase` chip with no label/value) on the resulting entitlement card — **root-caused, not JSON-authoring**: `displayContexts: []` (an explicit "never render this field" signal the JSON author used for internal/formula-only fields, the same pattern present in 12 different community fixtures) was being treated identically to `null`/omitted ("show everywhere") at 3 separate shared-code call sites (`part18_marketplace_rendering.dart`'s `shouldDisplayInContext`, `part26_generic_instance_card.dart`'s `_isVisibleField`, `part36_engine_native_marketplace_surface.dart`'s `_factSchema`). Fixed as **CJM.17** (`4018e1e4`) — independently verified (`flutter analyze` clean, full test suite with the one pre-existing unrelated flaky test confirmed via `git stash` against baseline), then live-reverified: the entitlement card now shows only its two real fields, no stray chip. Also fixed in the same commit: the Messages tab's shared default description literally read "Shell-owned communication and connections." — confirmed via source read that `productionUxGenericCopyViolations()` already bans the phrase "Shell-owned", yet the tab spec itself was never checked against its own list; changed to "Messages and connections with other members." The judge's remaining findings (raw ISO dates on Giving — known deferred pattern; the payment-edit field showing its raw editable value — correct by-design behavior, not a leak, corrected from the judge's initial read; launcher truncation/banner-occlusion — known evidence-coverage pattern; "2 roles" badge — known deferred pattern; FAB overlap on package-details row) are UX polish or already-established deferred patterns, left open. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-ad-free-1/`. |
| 10 | Data Portability Community | **Done, 2026-08-10.** Skill-authored (merged 5 of the doc's 9 rows into one `export-package` lifecycle per the type-vs-instance test), independently judged (FAIL, 1 real visibility leak to the Receiving Provider persona), fixed and re-validated (0 errors, 0 warnings). JSON: `docs/references/communities/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`. Row closed pending §6 live UX walkthrough. | Not started | **CJM.18 found here, not yet fixed** — see walkthrough notes | **Run 2026-08-11, row closed — tenth and final community.** Confirmed CJM.17's Messages-tab copy fix and every other prior shared-code fix hold on this final community. **Real, reproducible blocker found and root-caused, not fixed live**: signing up as ANY of this community's 3 personas (tried Owner/Admin and Member) failed deterministically with `Sign-up failed: Invalid argument(s): Persona type "portability-owner" is not declared by community "ext_export_migration".` — even though the fixture genuinely declares that exact persona id and the sign-up dropdown itself correctly listed all 3 real personas. Reproduced 3 times on the same screen instance (not transient); then a full app restart + fresh re-sideload + *immediate* sign-up (before any other in-session activity) succeeded on the first try. The distinguishing factor was not elapsed time within one screen instance but **prior in-session activity across other communities** (this attempt followed an extensive Ad-Free Community walkthrough in the same running app process) — pointing to cross-community state leakage in the sign-up persona-validation path (`LocalAuthApi._resolvePersona`), not a timing race or a persona-specific bug. Tracked as **CJM.18**, deliberately not fixed this pass given the investigation needed to find the actual leaking state — recommended as a Root Cause Agent dispatch before a fix ticket, matching CJM.16's precedent. Once signed in (via the fresh-process workaround), the judge found a real, **fixed** JSON-authoring bug: both `export-package` and `export-schema-listing` declared a redundant `componentCount` formula field (`size(includedComponents)`) whose labelTemplate and `displayContexts` overlapped with the underlying list field's own, producing literal duplicate chips ("4 components" / "4 components", "2 components" / "2 components") on both the Home and Admin cards — fixed by removing the redundant fields, re-validated (0 errors, 0 warnings), live-reverified on both cards. Also found and precisely diagnosed (not fixed, given shared-code blast radius): the Admin edit form shows a bare lowercase `components` label beside a properly humanized "Package Label" — traced to the shared editor's label-stripping logic (`_editorLabel` in `part26_generic_instance_card.dart`) only trimming *trailing* punctuation, so a leading-placeholder labelTemplate (`"{value.length} components"`) leaves an uncleaned lowercase trailing word, unlike a trailing-placeholder template (`"Redacted: {value.length}"` → cleanly "Redacted"). Remaining findings (launcher title truncation, package-card missing headings, replay-action state legibility, messages-empty no next-action, Admin FAB overlap) are UX polish or already-established deferred patterns from prior communities, left open. Evidence: `docs/Build Plan V2/Evidence/B25/phase-a-data-portability-1/`. |

## 5. Dispatch mechanics — emulate exactly, do not improvise a shortcut

This is the same canonical recipe proven this session for the AuthZ.P1-P7 ticket series (8+ tickets shipped,
independently verified). Full detail lives in `data/call_implementation_agent.sh`'s own header comment —
read it before the first dispatch of this tracker if any step below is unclear. Summarized here for the
per-community loop:

```bash
# 1. Author the ticket file (one per community-JSON-authoring pass, or per shared code gap CJM.1-3)
#    at data/v3_ticket_cjm_<slug>.md, following the proven structure:
#    ## Context / ## Scope / ## Do not do / ## Required verification / ## Git safety reminder /
#    ## Commit / ## Required response format (the _STATUS.md template).

# 2. Baseline
bash data/wsl_dispatch_tracker.sh baseline <label>

# 3. Dispatch, backgrounded (never run call_implementation_agent.sh in the foreground — it blocks
#    the session for the full dispatch duration)
setsid nohup bash data/call_implementation_agent.sh data/v3_ticket_cjm_<slug>.md --fresh \
  < /dev/null > .codex-logs/<label>_dispatch.out.log 2>&1 & disown
sleep 3   # let the dispatch's own WSL session establish before capturing

# 4. Capture the process set this dispatch spawned
bash data/wsl_dispatch_tracker.sh capture <label>

# 5. Watch via Monitor (NOT a raw tail|grep loop — see the script header for why that leaks sessions)
wsl.exe -e bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom" && bash data/watch_dispatch_log.sh <label>'

# 6. Once genuinely complete (Monitor fired on "codex exec exited with status", not just a vsock
#    alert mid-run) -- BOTH of the following together, as one paired step, BEFORE flutter
#    analyze/tests:
bash data/wsl_dispatch_tracker.sh cleanup <label>
# ...and confirm+commit the round's real edits (git status/git diff first) right alongside cleanup.

# 7. Gate check -- must print "READY FOR VALIDATION" before independent verification starts
bash data/handoff_gate.sh <label>

# 8. Independent verification (mine, never trust STATUS.md alone):
#    - flutter analyze clean on every touched package
#    - full test suite, no unexplained pass-count drop
#    - for JSON tickets: re-run the real validator (loom_ux_judges CommunityPackageValidator /
#      workflow_validator.dart) against the new fixture AND every existing shipped community,
#      confirm zero new errors
#    - for code-gap tickets touching UI: live re-verification on the emulator, not just analyze/test
#    - for any ticket touching SHARED code (a widget/renderer/validator rule reused by more than one
#      community's cardSurfaceFamily/mechanism, i.e. every ticket in §2): a dedicated Regression Impact
#      Judge dispatch (docs/Build Plan V2/Tools/regression-impact-judge-tool.md) against every real
#      consumer, not just this ticket's own scoped test -- "the ticket's tests pass" is not evidence the
#      OTHER consumers of the same shared code are unaffected.
```

**Session-wide WSL concurrency budget (standing user instruction): cap total concurrent `wsl.exe`
subprocesses at 4.** One dispatch + one Monitor watch = 2 already-reserved slots; route any additional
ad-hoc `wsl.exe` calls (status checks, log reads) through `data/wsl_slot.sh` rather than firing them
unbounded. For anything needing >4 parallel checks (e.g. dispatching JSON-authoring tickets for several
communities' *reconciliation passes* at once, which don't touch code and don't need the full Codex dispatch
loop), batch up to 4 parallel calls inside a single `wsl -e bash -lc "... & ... & wait"` invocation instead
of spawning multiple top-level `wsl.exe` processes — proven pattern from the Phase A judge-dispatch batches
earlier this session.

**Model:** dispatches default to GPT-5.3-Codex-Spark @ xhigh (`data/call_implementation_agent.sh`'s current
default, set 2026-08-07) unless a ticket has reason to override via `CODEX_IMPLEMENTATION_PROFILE`.

## 6. Mandatory completion gate — live LLM Vision UX Judge walkthrough

**No community is marked complete in §4 without a real walkthrough. This is not optional and not
satisfied by `flutter analyze`/unit tests alone** — those verify code correctness, not that the actual
rendered UI matches the community's product doc and is legible/actionable to a real user.

Mechanism (proven end-to-end this session on Apartment Events — 6 real findings surfaced, one bridged to a
ticket, fixed, and re-verified as passing on recapture; full detail and Agent Split table in
`docs/Build Plan V2/Tools/ux-gate-judge-tools.md`):

1. **Launch the emulator** via the hardened launcher (not ad hoc):
   ```powershell
   wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom" && bash app/packages/tooling/launch_loom_demo_emulators.sh --restart --mode both --run-app --app-target manual'
   ```
2. **Capture real screenshots** for the community's workflows/personas — either the existing automated
   catalog path (`b25_capture_workflow_screenshots.dart --mode targeted-precheck --phases <phase>` for
   communities already in `loomEvidenceTargets`) or the manual adb/uiautomator capture + hand-assigned
   `rowId`/`screenshotHash` approach (proven for Apartment Events, which isn't in the catalog).
3. **Produce `screenRows[]`** via `b25_evidence_collector.dart`, with real `rowId`/`screenshotHash`, and
   compute `appCommitSha` = `git rev-parse --short HEAD` at that exact moment.
4. **Dispatch the judge** — a Claude Code subagent via the `Agent` tool (never Codex; never the headless
   `claude` CLI for this tracker's Phase A work — that's the separate, not-yet-built Phase B automation),
   briefed with the canonical prompt contract at `ux-gate-judge-tools.md`'s Agent Split table + the exact
   numeric/boilerplate thresholds (≥16-char `visibleEvidence` on direct-question answers, ≥24-char on
   holistic, ≥80-char non-boilerplate `critique`/`why`, **100% `screenRows` coverage in `screenReviews[]`**
   — not a sample), Read-only access to the screenshots, and the fixed facts to echo back verbatim. The
   agent must classify any doc/implementation mismatch it notices as `product-spec-gap` /
   `implementation-gap` / `evidence-gap` per the contract, and must never include
   `sourceReviewRunId`/`carriedForward`/`reusedPriorReview`/`usesPriorReview`/`carriedFromPriorReview` in
   its output (the freshness gate rejects any of these being present/truthy).
5. **Run the real chain**, from `app/` under WSL:
   ```bash
   dart run packages/tooling/loom_ux_judges/bin/b25_llm_review_freshness_gate.dart --llm-review <output.json>
   dart run packages/tooling/loom_ux_judges/bin/b25_llm_ux_review_importer.dart --llm-review <output.json> --output independent-production-ux-review.json
   dart run packages/tooling/loom_ux_judges/bin/production_ux_judge.dart --input independent-production-ux-review.json
   ```
6. **Any real finding becomes a ticket** via the Phase C bridge (`ux-gate-judge-tools.md`'s "Findings-to-
   tickets bridge" section) — hand-authored `data/v3_ticket_<name>.md`, dispatched per §5, independently
   verified, then **recaptured and re-judged** to confirm the fix actually landed in the pixels (not just
   that the code changed) before the community is marked complete.
7. **Run the LLM Product Docs To Evidence Workflow Reconciliation gate** (added to this checklist
   2026-08-09, closing a real gap the tooling-coverage audit found — this role exists and is dispatchable,
   it was simply never run in the first smoke-test pass). Full contract:
   `docs/Build Plan V2/Tools/b25-product-doc-workflow-reconciliation-llm-gate.md`. Same dispatch mechanism
   as step 4 (Agent tool, fresh context) — compares the community's product doc §6/7/8/9 and B25 semantic/
   card-surface sections against the same screenshots/evidence from steps 2-3, plus the relevant
   `components/card-surfaces/*.md` docs. Any blocker/major finding becomes a ticket exactly like step 6.

A community only moves to "complete" in §4 once: JSON authored (via §1b's skill dispatch, not hand-authored)
and validator-clean, judged by §1c's Skill Output/Update Judge, all its code gaps (if any)
dispatched/verified/committed, and both this walkthrough (steps 1-6) and the product-doc reconciliation gate
(step 7) run with either zero findings or all findings resolved and re-verified.

## 7. Execution order

1. **Prove the skill-based authoring process (§1b) on Cedar Commons HOA first**, since its JSON already
   exists as a known-good comparison point: dispatch the sandboxed Skill-authoring run → dispatch §1c's
   Skill Output/Update Judge against the result, comparing to the hand-authored backup → apply whatever
   Skill-file edits the judge recommends → only then treat the skill-based process as ready for the other 9
   communities. Do not skip straight to using the Skill on communities with no existing comparison point
   until this loop has run at least once.
2. Dispatch CJM.1, CJM.2, CJM.3 (§2) — sequentially or CJM.1 parallel with CJM.2, then CJM.3 after CJM.2
   (CJM.3 reuses CJM.2's rendering primitive). These unblock JSON authoring for HOA, Garden Club, Book
   Club, Soccer, Masjid Nur.
3. Resolve Chess Club's open question (§3) — read how `chess-local-install-open`/`chess-route-home` are
   actually exercised, confirm real-per-community vs. generic-mechanic, before expanding its doc.
4. Run the reconciliation pass (§3 caveat) for Member Social Space, Ad-Free Community, Data Portability
   Community — currently the only 3 of the 10 without a completed doc-vs-implementation check.
5. Expand the 6 mismatched product docs (§3) with real edits, not just decisions recorded here.
6. Author JSON for all 9 remaining communities via §1b's skill dispatch (not hand-authored), one at a time,
   each followed by §1c's Skill Output/Update Judge before treating that community's JSON as locked. If the
   Skill's own stated scope (Calendar/`event-rsvp` only) can't cover what a community needs, that's a real,
   expected finding, not a blocker — fall back to hand-authoring for the out-of-scope parts, exactly as
   surfaced for Cedar Commons HOA, and feed that gap back into whether/how the Skill should be broadened.
7. Per community, once JSON is locked: validate → live-install → run the §6 UX Judge gate (now including
   step 7, the product-doc reconciliation gate) → close out row in §4.
8. Only after all 10 rows in §4 read complete: remove the legacy Dart catalog paths
   (`part04_rich_spec_catalog.dart`, `part05_domain_preview.dart`, `part08_garden_and_helpers.dart`,
   `part09_action_surfaces.dart`'s legacy paths, `part14_copy_helpers.dart`'s legacy paths) and the 6
   hybrid communities' bespoke per-community widgets (`_GardenClubEngineTabSurface` etc.) — explicit
   "scrap all the legacy code" directive, deferred until nothing still depends on them.

---

## 8. Live TODO / Next Steps Queue

| Status | Tag | Item | Source | Date |
|---|---|---|---|---|
| ⬜ Open | `needs-verification` | **STALENESS SWEEP OWED on the migrated blocks.** §9 and §10 arrived from TODO.md on 2026-08-31 carrying **13 open checkboxes intact and unadjudicated**, several written before the B8 regeneration. Sweep each against the shipped packages with a control before treating any as current. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `needs-skill-dispatch` | **Outstanding Skill dispatches**: DataPortability (6 prefill) and AdFree (4 orphan) never dispatched; Camera Club's regeneration was **rejected, not installed** (it moved the reminder off the per-member path); Book Club is **knowingly damaged and held** (`c0e0355b` removed its per-member `send-reminder`); Garden Club is regenerated but **not installed**. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-ticket` | **Six dead queue transitions** — `join-queue`/`leave-queue` in Book Club, Camera and Garden have no reachable caller. | TODO.md, migrated | 2026-08-31 |
| ⬜ Open | `new-ticket` | **The `chmod 444` anti-hand-editing guard is not durable.** All eleven packages are 444 again, but nothing restores the bit after a lift-copy-restore cycle that exits early, and the guard is the only thing standing between the Skill-only rule and a silent hand edit. | TODO.md, migrated | 2026-08-31 |
| ⏸️ Paused | `needs-debug-agent` | CJM.16 (Member Social Space): Messages tab shows zero conversations for a freshly-signed-up account. Root Cause Agent dispatched 2026-08-13 — this is a **systemic identity-namespace gap**, not a narrow bug: the grammar's single `personaId` type conflates persona *type* with a specific *account*, so any seed data meaning "this individual" (not "this role") is unsatisfiable once a real account exists. Confirmed present (0.97 confidence) in 10 of 11 real fixtures via full source audit, not just Member Social Space. Recommended fix is a new package-level `seedAccounts` grammar concept plus a migration of seed data across ~10 communities — real architectural scope, not a quick patch. **Paused by explicit user decision, 2026-08-13**, pending review of [`CJM.16 Identity Architecture Proposal.md`](CJM.16%20Identity%20Architecture%20Proposal.md) (written up in full: current identity model, the gap, affected workflows, proposed grammar change, open questions). Resume only after that proposal is reviewed/decided. | §4 row 8 | 2026-08-11 (root-caused 2026-08-13) |
| ⏸️ Paused | `needs-debug-agent` | CJM.18 (Data Portability Community): sign-up fails deterministically for any persona after prior in-session activity in another community. Root Cause Agent dispatched 2026-08-13 — could not fully confirm the exact reported sequence without live on-device tracing (correctly reported as an instrumentation request, not a guess), but *did* statically confirm a real, separate defect: `main.dart`'s `_authApiForCommunity` caches a persona-resolver closure that ignores its own `communityExtensionId` argument and goes stale after a community's package is re-hydrated (`main.dart:219-233`). Concrete fix + 2 regression tests specified in the report. **Paused by explicit user decision, 2026-08-13** — sequenced after CJM.16's architecture proposal is resolved, not for a technical reason of its own. | §4 row 10 | 2026-08-11 (root-caused 2026-08-13) |
| ⬜ Open | `needs-live-validation` | §6 step 7 (LLM Product Docs To Evidence Reconciliation gate) — confirmed run and closed only for Cedar Commons HOA (§4 row 1, combined-pass note). Status for the other 9 communities not confirmed in this table; re-check §4 per-row before assuming it's outstanding everywhere, then run/close per community. | §6 step 7 | 2026-08-11 |
| ⬜ Open | `new-milestone` | §7 step 8: remove the legacy Dart catalog paths and the 6 hybrid communities' bespoke per-community widgets — now unblocked, all 10 §4 rows read complete. Not yet scoped into tickets. | §7 step 8 | 2026-08-11 |
| ⬜ Open | `new-ticket` | Backlog of deferred, lower-severity polish findings accepted across multiple communities (ISO-8601 date/timestamp humanization — needs real date parsing, not a regex extension; `maxLines: 2` truncation on longer titles; contradictory chip-pair rendering) — tracked in §4's per-row notes, not yet consolidated into a ticket. | §4, multiple rows | 2026-08-11 |

---

## 9. Package regeneration record — 2026-08-29 → 2026-08-31

*Migrated from `TODO.md` on 2026-08-31. Four dated entries on the packages themselves: the Book Club
"regression" that the backend work overtook, a stale marker and the grammar gap behind it, the B8
`experience.notifications` regeneration across all eleven communities, and the absent-block default
that would have silently switched off device notifications for every community that never declared
the block.*

### 2026-08-29 — the Book Club "regression" has been overtaken by the backend

`c0e0355b` removed eleven instance fields from Book Club while making an unrelated and correct
change, and was recorded as a shipped regression. Re-examined today against `c0e0355b^`, the removal
splits three ways and **only the first was ever wrong**:

| Removed | Verdict now |
|---|---|
| `reminderAt`, `reminderSentAt` | **Correct** — the documented §15 conversion to a declared `reminder` block removes the formula field |
| `acknowledgedByFanIds`, `savedByFanIds`, `accessRequestedFanIds`, `approvedFanIds` | **Correct now** — per-member document state is owned by the deployed member-state API |
| `queuedFanIds`, `myQueuePosition`, `queueLength`, `currentHolderFanId`, `currentHolderDisplay` | **Correct now** — queue membership, position and custody are owned by the deployed item queue service |

They were a regression **at the time** because they were removed before anything replaced them. B1
and B5 have since shipped the services that own those facts, and B5's own spec names a `fanId[]` of
readers as the anti-pattern it exists to replace: it grows without bound and rides along on every
read of the instance.

**So do not restore them.** Re-adding would create a second, diverging source of truth for who holds
an item and who acknowledged a document. `verify_community_package.py` against `c0e0355b^` reports
`VERIFY FAIL` and will keep doing so; that comparison is now the wrong baseline, and the standing
instruction to "verify Book Club against `c0e0355b^`, not HEAD" is **retired** — HEAD is the correct
baseline for this package again.

Left open, and genuinely unresolved: the shared-library and reading-material surfaces still *declare*
those experiences in the product doc while the JSON no longer carries the fields and the app does not
yet call the services for this community. That is a wiring gap, not a data-loss gap, and it belongs
with B3/B6-style app work rather than with a regeneration.


### 2026-08-29 — one stale marker left, and a small grammar gap behind it

Every remaining `NEEDS IMPLEMENTATION` marker is a correctly deferred service — payment gateway and
payment ids (AdFree 6, Cedar 2, Mosque 2, Youth Soccer 1, Garden 1), and AI answer generation
(Book Club 1, Mosque 1) — **except one.**

Garden's `checksumVerified` carries: *"checksum verification is unavailable with the checksum
service."* **That is no longer true.** `export-bundle-api.openapi.yaml` implements
`verifyExportBundle`, and the spec states plainly that `checksumVerified` gets `false` on generation
and *"only `verifyExportBundle` may set"* it true. The comment describes a gap that has been closed
since 2026-08-27.

- [x] `DECIDED 2026-08-31 — none. platformSource is declared only where a dispatcher resolves the value; checksumVerified is written directly by the download handler` — ~~`needs-spec-decision`~~ **what `platformSource` does a `checksumVerified` field declare?** The
  closed set is `checksum` and `opaqueId`, and neither fits: the field is a verification **result**,
  a bool set by a different operation on the same service, not a hash value produced at transition
  time. Three options, none obviously right:
  1. reuse `"checksum"`, letting the service infer from the field's `bool` type — implicit typing,
     and the kind of thing that reads as clever until it is wrong
  2. add a third value such as `"checksumVerification"` — explicit, but a grammar addition
  3. leave it `writableBy: "platform"` with no `platformSource` — honest today, and it keeps the
     missing-`platformSource` warning pointing at a field that genuinely has an unnamed writer

  Small, and blocking nothing. Worth deciding rather than guessing, because option 1 is the tempting
  one and the least reversible.

- [ ] `new-ticket` — **delete Garden's stale `checksumVerified` comment** regardless of which option **CONFIRMED STILL PRESENT AND NOW DEMONSTRABLY FALSE, 2026-08-31.** Garden's comment reads *"NEEDS IMPLEMENTATION (platform service): checksum verification is unavailable with the checksum service"* — but `checksumVerified` **is** implemented: the download handler recomputes `sha256` and compares against both the stored checksum and the byte size before writing it. This is precisely what solved-patterns §20 warns about — *"a NEEDS IMPLEMENTATION note that outlives its implementation is worse than no note, because the next reader trusts it and re-reports a closed gap."* Needs a **Skill dispatch**; the JSON cannot be hand-edited.
  wins. A `NEEDS IMPLEMENTATION` note that outlives its implementation is worse than none: the next
  reader trusts it and re-reports a closed gap.


### 2026-08-31 — B8 package regeneration, running record

Product docs: **11 of 11 done** (`e1561c0a`, `56c93e80`). Each states what its community offers and
why, drawn from that community's own workflows rather than boilerplate.

Packages, each through the Skill via a **targeted-edit brief** and verified before install:

| Community | Commit | Delta | Diff | Validator (new / shipped control) |
| --- | --- | ---: | --- | --- |
| Camera Club | `31652ee7` | +109 | 4 lines | pass 0 err, 9 / 9 |
| Chess Club | `cad5c1bc` | +109 | 4 lines | pass 0 err, 2 / 2 |
| Cedar Commons HOA | `e1050a25` | +109 | 4 lines | pass 0 err, 12 / 12 |
| Ad-Free Community | `9026105c` | +109 | 4 lines | pass 0 err, 4 / 4 |

**The +109 is a tripwire, not a coincidence.** Four independently authored packages producing a
byte-identical delta means the Skill is making the same minimal edit rather than reformatting. A
package that comes back with a *different* delta gets scrutiny before anything else — which is worth
more than the validator here, because deletion and correct addition produce identical validator
reports.

Two tools now derive from the shipped package rather than from memory:

- **the brief generator** extracts roles, workflows and tabs and counts them, so the "what must
  survive" block cannot be subtly wrong in the way that grants permission to drop something
- **the installer** does lift-copy-restore on the `chmod 444` canonical file, updates the asset
  mirror, and **confirms the written file matches its source byte-for-byte** — the pilot's copy was
  silently refused by the permission guard and the provenance tool then ran against a half-applied
  state

- [x] `B8 COMPLETE 2026-08-31` — remaining: Garden Club (running), Masjid Nur, Member Social Space, Neighborhood Book Club,
      Riverside Youth Soccer, Tabletop Club, Data Portability
- [x] `B8 COMPLETE 2026-08-31 — the app read shipped with the packages; part44 gates on deviceDeliveryEnabled` — then the app read, which **must ship with the last package** — the read alone switches device
      notifications off, the packages alone are inert

### 2026-08-30 — the absent-block default would have silently switched off device notifications

**A correction to my own analysis, caught before it shipped.** I offered the user three options for
what an absent `experience.notifications` block should mean and described `["inbox"]` as "fails quiet
— an omission never interrupts anyone". They picked it on that description. **The description was
incomplete in the way that mattered.**

`part44_reminder_sweeper.dart:59` calls `_delivery.deliver(notification)` **unconditionally** for
every due notification, and `LocalNotificationDeliveryService.deliver` calls
`FlutterLocalNotificationsPlugin.show()`. So device notifications already fire in **every** community
today. "Quiet" was never the status quo — it would have been a **regression**, switching off a
working feature in all eleven communities the moment the app started honouring the config, with
nothing failing and no error anywhere. Exactly the silent-loss failure this effort exists to remove.

Re-presented with that fact. **User decision: keep absent = `["inbox"]`, and regenerate all eleven
packages to declare `push` explicitly**, so the rule stays "quiet unless asked" while no community
loses delivery.

**Consequence: the app-read and the package regeneration must land together.** Shipping the read
first switches notifications off; shipping the packages first is inert. That coupling is the whole
risk of this item.

- [x] `B8 COMPLETE 2026-08-31` — regenerate eleven packages to declare `experience.notifications`, **through the Skill only** —
      community JSON is never hand-authored. Use a **targeted-edit brief**: an authoring-mode
      dispatch re-authors from scratch and drops shipped workflows and tabs
- [x] `B8 COMPLETE 2026-08-31` — verify each against its predecessor **field by field**, not just with the validator —
      deletion is invisible in a validator run, so a package that quietly lost a workflow and one
      that correctly gained a config block produce identical reports
- [x] `B8 COMPLETE 2026-08-31` — run `tool/update_community_provenance.dart` in the **same commit**, or the judges suite goes red
- [x] `B8 COMPLETE 2026-08-31` — then the app read: deliver the device notification iff `push` is in `default` **and**
      `muted` is false; the inbox record is unaffected, because muting stops the interruption and
      not the record
- [x] `B8 COMPLETE 2026-08-31` — **pilot one community first** and verify it exhaustively before touching the other ten


---

## 10. Writer-declaration pass and tab audiences — 2026-08-27 → 2026-08-28

*Migrated from `TODO.md` on 2026-08-31. Where the writer pass stood across the ten packages, the
`writableBy`/`effect` split, and the tab-visibility fix — a role that could read a tab but not act
on it rendered as invisible, which conflated "can act" with "can see".*

### 2026-08-28 — where the writer pass and the archetype backends actually stand

**Writer-declaration pass — 7 of 10 installed.** Book Club (partially, see below), Garden, Mosque,
MemberSocialSpace, Chess (twice: writers, then tab audiences), Cedar, Youth Soccer.

- [ ] `needs-skill-dispatch` — **DataPortability (6 prefill) and AdFree (4 orphan) were never dispatched.** Briefs are built and current at `data/{dataportability,adfreecommunity}_brief.md`
- [ ] `needs-skill-dispatch` — **Camera Club's regeneration was REJECTED, not installed.** It moved the reminder from the per-member `photo-walk-response` row to the parent event and deleted each member's `reminderOffsetHours` — the same collapse that shipped in Book Club and became solved-patterns §19. Camera's own product doc argues the per-member design explicitly at §119–129. Re-dispatch against rule 5f; the output in `~/.codex-skill-authoring-scratch/camera-writers/` is the rejected one, do not install it
- [ ] `needs-skill-dispatch` — **Book Club is knowingly damaged and held.** `c0e0355b` removed its per-member `send-reminder`, the shared-library queue/custody fields and the reading-material access lists; its own doc requires all of them. A verified restore exists at `~/.codex-skill-authoring-scratch/bookclub-restore-r2/` and is deliberately NOT installed — held until the listing/loan backend exists, by user decision, so it can be regenerated once against the new API rather than restoring instance-data fields the backend supersedes. **Verify any Book Club output against `c0e0355b^`, not against HEAD** — HEAD is the damaged state and a diff against it reports the loss as faithfully preserved

**Archetype backends.** The pattern is now three specs and two services.

- [x] `new-milestone` — **export bundles + checksum**: spec, service, app client, all committed and green
- [x] `new-milestone` — **document library gains version and per-member state**: `Document.version` is service-assigned and bumps on revision; `read`/`saved`/`acknowledged` move off instance data; acknowledgement binds to the version so a revision invalidates it without rewriting a record. **Spec only — not built**
- [x] `new-milestone` — **item queue service built** (`b77d0cfd`), 12 tests, workflow service 89 → 101
- [ ] `needs-verification` — **b77d0cfd MUST NOT BE DEPLOYED as-is.** `_queueOfferHoldWindows` throws at line 38 of `main`, before Postgres opens, so the service will not start without `LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS`. Deploying it without the manifest entry takes down documents, exports and notifications too. Fix dispatched: startup tolerates absence, malformed config still fails loudly, `advanceItemQueue` alone refuses per-community
- [ ] `new-ticket` — **the six dead queue transitions are still dead.** `join-queue`/`leave-queue` in Book Club, Camera and Garden have zero effects. The service exists; nothing points at it. Needs a Skill regeneration per community plus an app-shell client, neither started **RE-EXAMINED 2026-09-01 — the wiring now exists, so "dead" needs re-testing rather than assuming.** The six are confirmed present: 3 `join-queue` + 3 `leave-queue` across Book Club, Camera and Garden. But the caller chain that was missing is now in place: `part02_tab_shell.dart` → `EngineNativeMarketplaceSurface` (part36) → `joinItemQueue`/`leaveItemQueue` → `part46_item_queue_client.dart` → the service. And the transitions declare the right action (`"action": "join_queue"`). **What I cannot confirm from source alone** is that a transition actually routes to that surface at runtime — that needs exercising on device, which is blocked behind the `calendar.*` creation refusal. So: re-test rather than re-report. Note the first search here returned nothing because I grepped `joinQueue`/`leaveQueue`; the methods are `joinItemQueue`/`leaveItemQueue`.
- [ ] `new-milestone` — **messaging is a boundary, not an implementation.** `messaging-api.openapi.yaml` is `0.0.0-placeholder`; `messaging_feature_not_available` warns on the 8 thread-state transitions that do nothing

**Validator rules added this pass** — four defect classes that were previously invisible to every check: `effect_writable_field_has_no_effect` (60), `prefill_written_field_not_platform` (128), `transition_has_no_observable_effect` (36 measured — my ad-hoc scan said 37; now **30** after `join_queue`/`leave_queue` became platform-completed), `messaging_feature_not_available` (8). Judges 434 → 461.

### 2026-08-28 — a tab you may read but not act on is invisible — CLOSED

- [x] `new-ticket` — **`roleHasPermission` conflated "can act" with "can see". Fixed `3006fa29`.** A role is now admitted if it can act OR if the bound workflow's visibility admits it to read, with read resolution moved into a shared `read_visibility_resolver.dart` in the engine so the tab rail and the instance list cannot disagree. `visibleRoleIds` remains an absolute override. Blast radius was 5 role-tab grants, all in Chess, no removals — predicted independently before reading the agent's report, and the two lists matched
- [x] `new-ticket` — **PREREQUISITE done `2e8541af`:** Chess declares tab audiences (`admin: ["chess-organizer", "chess-owner"]`). Sequencing mattered — shipping the shell fix first would have widened an exposure rather than closing it
- [x] `needs-verification` — **demo suite green at 160/160**, first time since Chess declared the tabs its doc requires
- [ ] `new-ticket` — **SECURITY-ADJACENT, found incidentally and now fixed, but worth a corpus check: Chess's `admin` tab was visible to members.** The demo test asserted it — `chess-member` persona, `community-tab-admin` `findsOneWidget` — and that assertion was *correct about the old behaviour*. With no `visibleRoleIds` declared, a member holding any transition on any admin-tab workflow reached the whole tab. The other nine communities all declared audiences and were unaffected, so the exposure was Chess-only. **The open item is the general one:** nothing fails a build when a community declares an `admin`-ish tab with no `visibleRoleIds`. Rule 5e and solved-patterns §18 tell the Skill to declare them, but a validator rule would catch a package that does not — consider `tab_without_declared_audience` as a warning


- [ ] `needs-verification` — **my corpus scan of this defect over-counted twice and is not evidence.** It first said 8 by not following `responseTable` into response workflows, which the real derivation does — that produced false hits on Camera and Garden calendars, where members obviously do RSVP. Refined to 6, still wrong, because it ignored `visibleRoleIds`: AdFree's `admin` hidden from a member is correct behaviour, not a defect. Only the Chess `rankings` case is proven, and it was proven by rendering the UI rather than by reading JSON. Re-measure with the real derivation before quoting any number

### 2026-08-27 — the writer-declaration pass, and what it opened up

Landed today, all pushed and green (judges 440, engine 312, app shell 308, workflow service 75):

- [x] `new-milestone` — **`writableBy` gained `platform`, and `effect` stopped meaning two things.** `effect` had been covering both "a JSON effect writes this" and "something outside the package fills this in", so a field nothing wrote was indistinguishable from one the platform wrote. `InstanceDataField` gained `isMemberWritable`/`isMachineWritten`; six call sites now ask the question they mean. Documented in `field-types.md`, `workflow-grammar.md`, `05-validation.md` and the Skill's instructions
- [x] `new-milestone` — **two validator rules that make writer defects checkable.** `effect_writable_field_has_no_effect` (60 findings, was 64) and `prefill_written_field_not_platform` (128 findings). Both warnings, deliberately: the packages did not break, the grammar learned to tell things apart. All 10 packages remain `pass` with **zero errors**. Promote to errors once the corpus has moved
- [x] `needs-skill-dispatch` — **Book Club regenerated**: checksum, transferId and the AI digest answer now say `platform`. Four orphan findings → zero. Verified by my own validator run plus a field-by-field diff, not the agent's report
- [x] `new-milestone` — **solved-patterns §15 and §16**, the reminder conversion and the prefill writer, each with the plausible-wrong JSON beside the correct JSON. Written after a prose-only rule produced a destructive reading

Open, in order:

- [ ] `needs-skill-dispatch` — **regenerate the remaining 8 communities for writer declarations.** Cedar (16 prefill + 6 orphan), Chess (18+6), Mosque (29+7), Youth Soccer (14+4), Garden (13+12), MemberSocialSpace (22+17), CameraClub (9+4), AdFree (0+4), DataPortability (6+0). Briefs are built at `data/<community>_brief.md` with identifiers re-derived from the shipped package, not from notes. **Book Club needs one more pass too** — its `ownerFanId` is `formEntry` and should be `platform` (its single remaining prefill finding)
- [ ] `needs-verification` — **Garden Club is regenerated but NOT installed.** Run 1 deleted `reminderAt` *and* `reminderOffsetHours`, removing a capability the product doc promises; run 2, against the corrected instructions, declared the `reminder` block correctly and kept the offset. Re-dispatch once more so the prefill fields land as `platform` in the same pass, then install
- [ ] `new-ticket` — **the `chmod 444` anti-hand-editing guard is not durable.** All eleven packages are 444 again as of 2026-08-27 (AdFreeCommunity and ChessClub had drifted to 664), but git does not track that permission bit, so a fresh clone gets them writable and the guard silently disappears. It is a local speed bump, not an enforced rule — the actual enforcement is the standing instruction in CLAUDE.md. If it should be real, it needs something the repo carries: a test that fails when a community `*.jsonc` changes without a corresponding Skill dispatch record, or a committed pre-commit hook plus a documented install step. Worth deciding rather than leaving a guard that looks stronger than it is
- [ ] `new-milestone` — **the export checksum service** (user-queued 2026-08-27, still next after the writer pass): 10 markers across 8 workflows in 6 communities. Spec-first — `migration-export-api` has no checksum concept, and nothing produces an export *bundle* for one to hash
- [ ] `needs-verification` — **`dueNotifications` has never been proven live.** `loom-workflow-service:0.4.0` is deployed with the endpoint; no community is provisioned into the service with a reminder-bearing instance, so the sweep has never returned a real row **UPDATED 2026-08-31 — the endpoint IS live; what is unproven is narrower.** `GET /v1/communities/{id}/notifications/due?asOf=` returns **200** and rejects a non-ISO-8601 `asOf` with `400 invalid_as_of`. The stored definitions are current (6 carry a reminder key, matching the 6 shipped packages that declare one). What has never happened is a reminder actually becoming due: the only 3 instances in the service are probe artifacts created by direct calls that bypassed the app-side `reminderEnabled: false` prefill, so the formula yields null. Proving it is now blocked behind the `calendar.*` permission gap, since creation is refused.

