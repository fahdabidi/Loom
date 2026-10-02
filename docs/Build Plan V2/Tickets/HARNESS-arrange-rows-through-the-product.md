# HARNESS — stop addressing seeded instance ids; arrange each row through the product

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by:** Root Cause Agent, session key `harness-remote-data-strategy`. **Two of its claims were
re-derived by me and one of them is wrong — see "Corrections" before trusting any count here.**

## The defect

The capture harness addresses rows **by seeded instance id**. `_shippedWorkflowSelector`
(`integration_test/workflow_ui_evidence_test.dart:3744`) iterates `package.experience.workflowInstances`
and every downstream wait addresses `selector.instance.instanceId`, blocking at
`waitForEngineNativeWidget(... 'shipped <type> instance <seedId> ...')`.

**Package `workflowInstances` seed the local engine only** — the 2026-09-07 decision, deliberate. So on
the remote path those ids cannot exist, and after the auth fix (`ea169ea7`) every Garden stall moved
from `seeded account Garden Member 1` to `shipped <type> instance <seedId> on <tab>`. The harness now
authenticates correctly and then asks for rows that were never there.

## Corrections to the scoping, both load-bearing

- **The bar is 73 real rows, not 74.** The scoping said the asset carries 4 `wf_` rows. It carries
  **5** — `wf_community-persona-aware-ux` x2, `wf_multi-persona-workflow-evidence` x2,
  `wf_demo-app-persona-picker` x1 — so 78 - 5 = 73, which is what `check_b25_status.sh` computes.
  **Take the figure from the gate, never from prose.**
- **Do not arrange state by calling `RemoteWorkflowEngineApi` directly.** The scoping recommended it as
  a shortcut. It is not needed: `authenticateEvidenceFanForRemote` (`test/workflow_ui_test_harness.dart:2071`)
  already performs `session.logout()` then `loginWithTestCredentials(...)` per call and takes `roleId`
  and `target`, so it is **re-entrant by construction** — a row can create as one fan and act as
  another entirely through the product. Arranging through the UI is strictly better evidence, and it is
  what the live-verification walkthroughs already do.

## What is already built, and must be reused rather than rewritten

`_createAndPublishShippedAnnouncement` (`:4920`, invoked `:898` and `:950` for Masjid rows) is a
**worked create-then-act path**, verified by reading it:

    selectActorIdentity -> _selectPackageTab -> prepareCreatableFabForTap -> tap the create FAB
      -> fill the form from the package schema -> submit
      -> waitForCreatedEngineNativeInstanceId (identifies the new row by diffing list keys)
      -> fire the transition -> _expectShippedInstanceIdState

Its helpers are already row-agnostic. **This ticket is a generalization, not a new mechanism.**

## The change

Introduce one arrangement seam that returns a **real** instance id for a selector, and have the row
address that instead of `selector.instance.instanceId`:

    Future<String> arrangeRemoteInstanceFor(WidgetTester tester, <selector>, {required LoomEvidenceTarget target})

- Use the seed's `instanceData` as the **input** to the create form — the seed stays authoritative for
  *what the row is about*, and stops being an address.
- Keep the proof action in the UI. Arrangement is setup; it is not the evidence.
- On the local path, return the seed id unchanged, so nothing about local capture moves.

**Scope this dispatch to initial-state, single-identity rows, and to Garden first.** Those are the
majority and they need no sequencing at all. Report how many Garden rows traverse afterwards.

## Do not

- **Do not delete or rewrite the seeds.** They are the local engine's fixtures and the form input here.
- **Do not widen the selector to "any instance of this type".** A row must be proven against an
  instance whose data matches what the row is about, or the screenshot depicts a different claim.
- **Do not fail the run when a row cannot be arranged.** Record *that row's* outcome with the reason
  and **continue to the next row** — give it its own outcome name, distinct from
  `primary_action_unavailable`, which is a designed result meaning something else entirely. Assert the
  continuation in a test; "it kept going" is exactly the property a single-row fixture cannot show.
- **Do not touch `docs/references/**`** — hard-locked. No package edits: none are needed.

## Deliberately NOT in this dispatch

Named so nobody infers them from silence, with the one genuinely open piece called out:

- **two-identity rows** (creator role != acting role) — mechanism exists, needs wiring per row;
- **effect-born rows** — no create action at all; they are born from a sibling's `createInstance` or
  cascade effect, so arranging one means creating the **sibling**. Which sibling births which target is
  **not yet mapped**, and that mapping is the real work, not the plumbing;
- **later-state rows** — need intermediate transitions fired first;
- rows whose ceiling is a missing platform service (payment, id generation, external search, checksum).
  Those cannot complete; their reachable boundary is the honest success criterion.

## Verification

- All five suites, **skip counts before pass counts**: app shell **448 (+2)**, demo **266**, judges
  **525**, engine **345 (+1)**, service **168 (+1)** with both credential sets. All measured green, so
  any movement is yours. **If you lack Postgres access, say so** — more skips means your run proved
  less, and I will re-run them.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line. A fourth is yours.
- Report **traversal separately from b25Proven**. A row that reaches its surface and renders no action
  is a different fact from a row that was proven, and the two must never share a total.
