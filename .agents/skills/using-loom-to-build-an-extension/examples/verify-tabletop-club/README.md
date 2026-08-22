# Verify Tabletop Club Example

This example is the App Shell Phase 1 "package-driven experience" fixture. Its `extensionId`
(`ext_verify_tabletop_club`) is deliberately absent from the App Shell's hardcoded demo catalog
(`_experienceByExtensionId`), so any workflows, roles, or role guards that render for it
must come from this package's `experience` block — proving the App Shell renders arbitrary
sideloaded communities instead of only the ~11 built-in examples.

Unlike the earlier `arbitrary-garden-club` fixture (which reuses the built-in `ext_garden_club`
id and would render from the catalog even if package-driven parsing were broken), this fixture is
a true negative-control: if `loom.initialization.json`'s `experience` block were ignored, the App
Shell would fall back to the single generic "Open local home" workflow instead of the six
Tabletop Club workflows below.

## Files

- `loom.extension.json`: local-demo extension manifest.
- `loom.initialization.json`: initialization package with an inline `experience` block declaring
  2 roles, 6 workflows across 5 card-surface categories, per-workflow role guards, a real
  calendar item, and real multi-choice response surfaces.

## `experience` block contract

- `displayName`, `tagline`, `accentColor` (`#RRGGBB`): experience branding.
- `theme` (optional): a `LoomCardTheme` override for every card surface in the community —
  `{ accent?, fillColor?, fillOpacity?, borderColor?, borderOpacity?, borderWidth?, headingColor?,
  headingOpacity?, headingWeight?, bodyColor?, bodyOpacity?, cornerRadius?, elevation?,
  shadowOpacity?, primaryButton?, secondaryButton?, tabThemes? }`. Every field is optional;
  omitted fields are derived from `accent` (defaulting to the top-level `accentColor` if `theme`
  itself is omitted) via a neutral-dark-card-plus-accent-highlights default — the accent tints
  borders, headings, badges, and buttons instead of filling the whole card. `primaryButton`/
  `secondaryButton` accept the same shape as a button theme: `{ fillColor?, fillOpacity?,
  borderColor?, borderOpacity?, borderWidth?, foregroundColor?, foregroundOpacity?, shape?
  ("pill"|"rounded"|"square"), labelWeight? ("w400".."w800") }`.
  - `tabThemes` (optional): `{ "<tabId>": { ...same LoomCardTheme shape... } }`. Declaring an
    entry re-themes every card surface in that tab, merged on top of the community-level `theme`
    — this fixture gives the Giving tab a deeper terracotta (`#8A5A34`) than the rest of the
    community (`#C4703F`) to show the cascade actually applying per-tab.
  - A workflow's own `theme` block (see below) is the most specific override, merged on top of
    its owning tab's theme in turn — so the cascade is community -> tab -> workflow, each level
    optional and each only needing to declare the fields it wants to change (typically just
    `accent`, which re-derives the rest of that level's look automatically).
- `roles`: list of `{ roleId, label, roleLabel, description }`.
- `workflows`: list of `{ workflowId, title, entryText, actionText, resultText, calendar?,
  responseChoices?, theme? }`. Category, card-surface family, and section/tab placement are derived
  automatically from `workflowId`/`title` keyword patterns by the same generic helpers the
  hardcoded catalog uses (`_workflowCategoryFor`, `_sectionTitleFor`,
  `_cardSurfaceRegistryEntryForWorkflowId`) — no extension-specific code is required for a new
  package to get correctly-categorized rendering.
  - `calendar` (optional): `{ date, time?, location?, capacityLabel? }`. Declaring this replaces
    the Calendar tab's placeholder week strip with a real date strip and event detail for that
    workflow; workflows without it keep the placeholder.
  - `responseChoices` (optional): `[{ responseId, label, isDestructive? }]`. Declaring 2+ choices
    replaces the plain confirm/cancel action surface with a real branching response bar (e.g.
    Going/Maybe/Can't go); the chosen response is recorded and named in the result text ("You
    responded: Maybe"). **This is opt-in only** — there is deliberately no automatic per-category
    default (see caution below).
  - `theme` (optional): a per-workflow `LoomCardTheme` override, same shape as the community-level
    `theme` above (minus `tabThemes`, which only makes sense at the community level). This fixture
    uses it on `tabletop-club-dues-payment` (`{ "accent": "#8A5A34" }`) to show the deepest cascade
    level overriding both the community and Giving-tab defaults.
- `personaPolicies`: map of `workflowId` to
  `{ actorPersonaIds, receiverPersonaIds, readOnlyPersonaIds?, prerequisiteWorkflowId?,
  receiverEntryText?, receiverActionText?, receiverResultText?, readOnlyText?, disabledReason? }`.

This fixture's workflows are deliberately named/shaped to exercise 4 different tabs beyond
Home/Messages, plus both real-interaction mechanisms (calendar display, response choices):

| workflowId | keyword match | category | tab | real mechanism |
| --- | --- | --- | --- | --- |
| `tabletop-game-night-rsvp` | `rsvp` | Event | Calendar | `calendar` + `responseChoices` (Going/Maybe/Can't go) |
| `tabletop-committee-decision` | `decision` | Approval | Admin (organizer) | `responseChoices` (Approve/Request changes/Reject) |
| `tabletop-game-loan` | `loan` | (equipment-loan) | Marketplace | — |
| `tabletop-club-dues-payment` | `payment`/`dues` | Payment | Giving | — |
| `tabletop-meetup-announcement` | `announcement` | Publishing | Admin (organizer only) | — |

Two cautions found while building this fixture:

1. `request` is an overloaded keyword — both `_sectionTitleFor` and the Admin-tab-eligibility
   check (`_personaCanAdministerAnyWorkflow`) treat any workflow whose `workflowId` contains
   `request` as "Requests and approvals", which makes its actor persona admin-eligible. An
   earlier draft named the loan workflow `tabletop-game-loan-request`, which unintentionally gave
   the Member persona an Admin tab. Avoid `request`/`approval`/`decision`/`review` in a
   `workflowId` unless the workflow is genuinely an approval-style request (note
   `tabletop-committee-decision` above intentionally uses `decision` since it *is* one).
2. `responseChoices` must be declared explicitly per workflow — an earlier implementation
   defaulted Event/Approval *categories* to a 3-way choice automatically, which broke an existing
   catalog demo workflow that happened to share the same generic rendering path with no bespoke
   widget of its own. There is no way to safely enumerate every catalog workflow that would be
   swept into a category default, so the shipped mechanism requires opt-in.

## Validation

- `test/b26_package_driven_experience_test.dart` writes this same content to temp
  `.loom-extension.zip` / `.loom-init.zip` files (matching the B9/B10 fixture convention),
  installs it through `LocalInAppBackend`, and asserts that `experienceForExtensionId` returns
  the package-declared workflows/personas/policies rather than the generic single-workflow
  fallback — including that switching to the "Organizer" persona reveals the receiver/admin view
  of workflows the "Member" persona only sees as an actor.
- `test/b27_calendar_tab_real_data_test.dart` proves the `calendar` block renders a real
  date/location/capacity agenda instead of the placeholder week strip, with a regression guard
  that catalog communities keep the placeholder.
- `test/b28_response_choice_interactions_test.dart` proves `responseChoices` renders a real
  branching surface for the RSVP and committee-decision workflows, records the chosen response,
  and that a workflow with no declared choices keeps the plain confirm/cancel bar unchanged.
