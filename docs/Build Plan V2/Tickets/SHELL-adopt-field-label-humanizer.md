# SHELL — adopt the in-repo field-label humanizer at all four sites

**Status:** written 2026-09-25, **NOT dispatched** (user decided: adopt the humanizer everywhere).
**Route:** `data/call_implementation_agent.sh --fresh`. Supersedes the open question in row-256.

## The defect

Field-label fallback behaviour disagrees with itself across four sites, and **`part18` disagrees with
itself** — which is what makes this a conformance bug rather than an open product question:

| Site | Fallback today |
|---|---|
| `part18_marketplace_rendering.dart:514` (`schema.labelTemplate ?? field`) | **raw key** |
| `part18_marketplace_rendering.dart:629` (`?? member.key`) | **raw key** |
| `part18_marketplace_rendering.dart:923` | **humanized**, via `_humanizeFactField` |
| `part26_generic_instance_card.dart:403` | **humanized**, via `_humanizeFieldName` |
| `part28_engine_native_calendar_surface.dart:2475` (`schema.labelTemplate ?? ''`) | **empty string** |

Two of the sites already humanize, and the helpers are written and shipped. So the decision was only
whether to adopt the existing behaviour everywhere — **user decided yes, 2026-09-25.**

**Live reproduction, on a third surface:** a Cedar walkthrough found a chip rendering the literal raw
key `requestInstanceId` on the spawned `hoa-committee-decision` card, which binds
`cardSurfaceFamily: "approvalQueueItem"` — i.e. a `part18`-served surface, consistent with the split
above.

## What to build

**CORRECTED 2026-09-26 BEFORE DISPATCH — the population was undercounted. There are THREE
implementations, not two, and a whole file was missing from the site list.** Swept
`app/packages/core/loom_communities_app_shell/lib/` myself rather than trusting the enumeration below,
and `part32_engine_native_list_surface.dart` never appeared in it:

| Implementation | Kind | camelCase → Title | Handles `_` |
|---|---|---|---|
| `part18:1002` `_humanizeFactField` | top-level | yes | **yes** (`replaceAll('_', ' ')`) |
| `part26:824` `_humanizeFieldName` | **class method** | yes | no |
| `part32:590` `_humanizeFieldName` | top-level | yes | no |

`part26`'s and `part32`'s bodies are **character-identical** — the same regex, the same capitalisation,
duplicated across two files. `part18`'s differs **behaviourally**: a field named `foo_bar` renders
"Foo bar" through `part18` and stays `foo_bar` through the other two. So this is not "two
implementations of one idea" but three, one of which silently disagrees.

**`part32` matters more than its omission suggests: it is the `table` renderer**, intercepting that
family at `:132` before the dispatcher is reached. Leaving it out would make table column labels
humanize differently from every other surface — a fix landing on some instances of the class and not
the rest, which is exactly the shape this repo keeps recording.

**Adopt ONE shared helper in `part08` and have every site below call it.** Delete all three local
implementations; do not leave a single duplicate behind. **Decide the underscore question explicitly
and state it in the report** — `part18`'s behaviour (underscores become spaces) is the superset and is
almost certainly right, but it is a real behaviour change for the other two sites and must be a
decision, not a side effect of whichever body you copied.

Call sites, all of which must end up on the shared helper:

- `part18:514` and `:629` — replace the raw-key fallback.
- `part28:2475` — replace the empty-string fallback. **Note this is a real behaviour change**, not just
  a label swap: a field with no `labelTemplate` currently renders *nothing* on the calendar surface and
  will now render a humanized label. That is the intent of the decision, but call it out in the report.
- `part18:923` and `part26:403` — repoint to the shared helper; behaviour unchanged.
- **`part32:390` and `:396`** — repoint to the shared helper. These are the two sites the original
  ticket missed, and both are genuine `template.isEmpty` / `label.isEmpty` fallbacks.
- `part26:387`, `:805` and `:993` — repoint whatever still resolves to a local helper. `:993` calls
  `_humanizeFactField`, which resolves to `part18`'s top-level function because these are `part` files
  of one library; check each call resolves to the shared helper after the change rather than assuming.

**A `part` file caveat that will bite otherwise:** these files share one library scope, so two
top-level helpers with the same name in different `part` files would not compile — which is why
`part26`'s is a method and `part32`'s is top-level. When you add the shared helper to `part08`, the
existing top-level names must be removed in the same change or the library will not build.

## The trap this ticket must NOT fall into

**Humanizing is the wrong fix for internal fields, and doing it blindly makes them worse.** Cedar's
`requestInstanceId` is `writableBy: "effect"` holding an opaque instance id. Humanized it renders
*"Request Instance Id: community_cedar_commons_hoa_…"* — which dresses an internal identifier up as a
user-facing fact, worse than the raw key it replaces.

**The correct fix for that field is package-side** — `displayContexts: []` — and the opt-out mechanism
already exists and is deliberate. Its semantics are documented in the renderer's own source at
`part26_generic_instance_card.dart:420-422`: *"An empty list means 'never render this field anywhere'
(used for internal/formula-only fields); only an omitted/null list means 'no restriction, show in every
context' — the two must not be conflated."* `part18:181` agrees (`if (displayContexts == null) return
true;`).

**So this ticket humanizes the fallback and does not touch that distinction.** Preserve
empty-list-means-never exactly as it is at every site you edit. Cedar's own `displayContexts: []` fix is
Skill-authored and tracked separately — do not hand-edit the `.jsonc`.

## The consequence worth stating in the report

The platform's default is *show*, and the label fallback is the *raw key*, so the two defaults compound:
**the least-annotated fields are the most exposed.** A field with no display metadata at all — the
clearest signal its author never meant it to be seen — is currently rendered everywhere with a
developer-facing name. This ticket fixes the label half. The exposure half is a candidate validator rule
(a field that is `writableBy: effect` or `platform` with no `labelTemplate` and no `displayContexts` is
almost certainly internal and should have to say so) — **note it, do not build it here.**

## Regression tests

- A field with **no `labelTemplate`** renders a humanized label at each of the four sites — four cases,
  since the point is that they now agree.
- A field with **`displayContexts: []`** renders **nowhere**, at every site. This is the guard against
  the trap above and matters more than the humanizing tests.
- A field with an explicit `labelTemplate` is **unchanged** — the humanizer is a fallback only.
- `part28` specifically: a field with no `labelTemplate` previously rendered an empty string and now
  renders a label; assert the new behaviour and note the old in the test name.

Prove at least the first can fail by neutralising the shared helper.

## Verification

- **All five suites.** Baselines **re-measured 2026-09-25**: judges **525**, app shell **421 (+2)**,
  engine **346 cases** (`345 +1 skipped` with PostgreSQL credentials; `341 +5` without), service
  **169 cases** (`168 +1`) with both credential sets, demo app **262, exit 0, ZERO failures**.
- **The demo app suite is GREEN now — any failure in it is yours.** Earlier copies of this ticket told
  you to expect one known failure matching `Found 0 widgets with key 'generic-instance-card-nom-draft-1'`.
  **That is obsolete**: `d87f9875` fixed the defect and `4192dbb8` inverted the test that asserted it.
  Do not read past a failure here on the strength of the old instruction.
- **Three service PostgreSQL tests time out under concurrency** — transaction-rollback, guard-refusal
  and idempotency-race. Re-run any of them alone with `--concurrency=1` before filing a regression;
  all three pass isolated in under 15s.
- **Expect text-finder churn.** Any test asserting a raw key appears — `find.text('requestInstanceId')`
  — was asserting the defect and should assert the humanized form instead. Diff every changed assertion
  and justify each; do not weaken a count to get green.
- `flutter analyze` clean on the app shell.

## Out of scope

Community JSON, `docs/references/**`, the engine, the workflow service, the validator rule noted above,
and the `displayContexts: []` fix for Cedar's `requestInstanceId`.
