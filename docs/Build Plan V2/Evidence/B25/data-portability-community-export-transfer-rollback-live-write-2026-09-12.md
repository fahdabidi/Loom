**Workflow:** `export-transfer-rollback` in Data Portability Community
**Outcome:** BLOCKED — not proven. The workflow is uncreatable through the UI: its only create action is declared `scope: "instance"` + `presentation: "button"` on an `exportWizard` binding, and the app shell's `exportWizard` card is the one surface that never receives instance-scoped create actions. No instance was created and no row exists.

**Package identity:** `skillVersion: "3.6.0"`, sha256 `f30994c9776871da2a4d48480f1ec83b2e7becaf16f860017dde5733ae0def43`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc`)

**Date:** 2026-09-12
**Device:** `emulator-5554` (Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`)
**Identity:** `loom-portability-owner-1` / `fan-portability-owner-1`, role `portability-owner`

## Where the run stopped

The ticket's prescribed order was followed exactly, and step 3 is where it stopped:

1. ✅ Created the `export-transfer-verification` transfer (proven — see the companion manifest).
2. ✅ Fired `start-provider-transfer` → `transferring`, the state in which the rollback button is declared.
3. ⛔ **"Request rollback" never rendered.** With the transfer sitting in `transferring`, the Admin-tab card
   was located and read in full. It rendered its three transitions — "Send for provider verification",
   "Record transfer error", "Cancel transfer" — and the card ended there, followed by the list footer
   ("Local package details"). There was no "Request rollback" button.
4. ⛔ Steps 4–5 (drive the rollback to `complete`) were therefore unreachable.

Because the button is the *only* way to create this workflow, the transfer was afterwards taken to its own
terminal state so that at least that row could be proven. That ordering no longer mattered: the button does
not render in any state, so cancelling the transfer destroyed nothing that was otherwise reachable.

## This is not "the workflow has no create action"

The ticket pre-empted that misreading, and it is not what is being reported. The package **does** declare a
create action, twice, and it is well-formed:

    "kind": "create", "workflowType": "export-transfer-rollback",
    "label": "Request rollback", "byRoleIds": ["portability-owner"],
    "scope": "instance", "presentation": "button",
    "prefill": { "sourceTransferInstanceId": "{context.id}", ..., "rollbackAvailable": true }

on bindings for `["transferring","awaiting-provider","failed"]` and `["verified"]`, both
`tabId: "admin"`, both `cardSurfaceFamily: "exportWizard"`.

The defect is that this declaration cannot reach the screen.

## Root cause, read from the app shell source

`lib/src/part27_engine_native_binding_dispatcher.dart` switches on `cardSurfaceFamily`. Three cases pass the
binding's instance-scoped create actions down to the card — `event-rsvp`, `votePoll`, and the `default`
`GenericWorkflowInstanceCard` — each via the same filter:

    action.kind == 'create' && action.scope == 'instance' &&
    action.presentation == 'button' && action.byRoleIds?.contains(roleId) == true

The `exportWizard` case (line 461) constructs `ExportWizardArchetypeCard` and **does not pass them**:

    case 'exportWizard':
      return ExportWizardArchetypeCard(
        key: contentKey, resolved: resolved, engine: engine, fanId: fanId,
        accent: accent, onInstanceChanged: onInstanceChanged,
        modernTheme: modernTheme, displayContext: displayContext,
        visibleFieldKeys: visibleFieldKeys,
      );                                    // no instanceScopedCreateActions / onInstanceScopedCreate

`ExportWizardArchetypeCard` (`part36_engine_native_marketplace_surface.dart:1963`) contains **zero**
occurrences of `instanceScopedCreateActions` — it has no such parameter to pass.

The one other code path that handles instance-scoped creates,
`part01_local_extension_screen.dart:1511-1521`, is surface-independent but requires
`action.presentation == 'fab'`. This package declares `presentation: "button"`.

So `scope:"instance"` + `presentation:"button"` + `cardSurfaceFamily:"exportWizard"` is precisely the
combination that renders nowhere. Both of this package's create actions are that combination.

## Why no validator or test caught it

`scope: "instance"` appears in **exactly one** of the ten shipped packages — this one — and only on these two
actions:

    0  AdFree   0  BookClub   0  CameraClub   0  CedarCommonsHOA   0  ChessClub
    2  DataPortabilityCommunity
    0  GardenClub   0  MemberSocialSpace   0  Mosque   0  YouthSoccer

There is no working instance-scoped button anywhere in the corpus, so there is no control to compare against
and nothing that would have failed. Every individual declaration here is valid; the defect lives in the
binding-to-renderer mapping, which no per-declaration check can see.

## Evidence that the affordance is genuinely absent

Per the standing rule against reporting a missing affordance on weak evidence, absence was established three
independent ways, and **not** from a `uiautomator dump`:

- **Screenshot, full card.** The `transferring` card was scrolled until its entire extent plus the following
  list footer were on one screen. Three transition buttons, no create button.
- **Source read.** The two code paths above — conclusive, and it explains *why*, not just *that*.
- **Tap test.** Tapping the card body produced no detail view or navigation, and the instance stayed in
  `transferring`. There is no expanded surface holding the button.

A `uiautomator dump` was attempted first and was **useless, not negative**: it returned 8,641 bytes containing
**zero** text nodes. A control (`grep` for any text node at all) showed the query was broken rather than the
screen empty, so it was discarded rather than reported.

Role was ruled out as a cause: the create action requires `portability-owner`, and I demonstrably hold it —
`start-provider-transfer` is guarded on the same role and I fired it successfully.

## Database confirmation — a real negative result

    select count(*) from workflow_instances where workflow_type='export-transfer-rollback';
    -- 0

Zero before the run and zero after, consistent with the UI: no instance was created, so nothing was written.
The workflow-type total for the table went 45 → 46, that one row being the companion
`export-transfer-verification` instance.

## The `{context.id}` measurement could not be taken

The ticket asked, as its own deliverable, for the stored `sourceTransferInstanceId` verbatim, to settle
whether `{context.id}` resolves in a `scope: "instance"` create prefill.

**That measurement is unavailable from this run, and honestly so:** the prefill is only evaluated when the
create action fires, and it never fired. Reporting any value — including "empty" — would be inventing an
observation. The question is untouched, not answered negatively.

Worth recording for whoever takes it next: the resolver does exist and is surface-independent
(`resolveInstanceScopedPrefill(action.prefill, focusedInstance, actorId: ...)` in
`part01_local_extension_screen.dart`, alongside `instance_scoped_action_context.dart`). So `{context.id}`
resolution is testable today via an instance-scoped action declared with `presentation: "fab"`, which does
reach that code path — it is only the `"button"` presentation on `exportWizard` that is stranded.

## Scope of the defect

This is not cosmetic. `export-transfer-rollback` declares six states including three terminal ones, five
transitions, and a full `instanceDataSchema`, and **none of it is reachable by any user** — the workflow has
no tab-scoped FAB and no other create path. Its B25 row cannot be proven by anyone until either the
`exportWizard` case forwards instance-scoped create actions, or the package declares the action as
`presentation: "fab"`.

Per the ticket I changed no application code, no community JSON, and no tracker.
