# Phase B23 - Persona Production UX and Cross-Persona State

## Achieves

Apply the production workflow surfaces per persona so actor, receiver, read-only, disabled, hidden, and
unrelated states each feel like a coherent product experience instead of a test harness state.

## Deliverables

- Persona-specific production surfaces for every example and test app.
- Receiving surfaces that show state created by another persona in the appropriate inbox, feed,
  request list, event page, search result, receipt, export, transfer, or notification surface.
- Disabled/read-only/hidden behavior with user-facing reason copy and backend denial parity.
- Dependency-chain tests for workflows where one persona creates, approves, publishes, pays, or sends
  state before another persona receives, reviews, searches, pays, or continues it.
- Cross-persona screenshot evidence with actor action, persona switch, receiver state, and unauthorized
  persona state where applicable.
- B23 API Review and B23 UX Decisions.

## Completed When

Multi-persona workflows prove the producer persona creates or approves state, the receiving persona
sees that state in a real recipient surface, and unrelated personas cannot act outside their role. The
Masjid Nur announcement flow must prove admin publish and member receive as a representative dependency
chain, with equivalent coverage for the other examples.

## Persona UX Judge Gate

Run `persona_ux_judge.dart` against the B23 persona evidence:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/loom_ux_judges/bin/persona_ux_judge.dart --input ../docs/Build\ Plan\ V2/Evidence/B23/persona-ux-evidence.json --base .. --output ../docs/Build\ Plan\ V2/Evidence/B23/persona-ux-scorecard.json --markdown-output ../docs/Build\ Plan\ V2/Evidence/B23/persona-ux-scorecard.md'
```

The judge must fail if actor, receiver, read-only, disabled, hidden, or unauthorized states are missing
from evidence, or if one all-powerful persona can satisfy a multi-persona workflow.

## Prompt To Use

Use this prompt when executing B23:

```text
You are implementing Phase B23: Persona Production UX and Cross-Persona State.

Use the B17-B20 persona matrices and the B21-B22 production UX contracts. For every community and test
app, verify that the people-icon test persona picker changes the production workflow experience, not
only labels or generic chips.

For each workflow/persona row, implement and test the correct state:
- actor personas can perform the semantic production action
- receiver personas see the resulting record in a real receiving surface
- approver/moderator personas see decision controls only when appropriate
- read-only personas see useful read-only information without mutation controls
- disabled personas see concise reason copy when the workflow remains visible
- hidden workflows are absent for personas that should not know about or use them
- unrelated personas cannot mutate backend state

For dependent workflows, run the chain in UI order: prerequisite actor action, backend persistence,
persona switch, receiver state, continuation action if applicable, and unrelated persona denial or
hiding. Do not use one all-powerful persona to satisfy a multi-persona workflow.

Update screenshot evidence and manifests with persona IDs, role labels, actor/receiver assertions, and
backend parity. Run workflow tests, manifest gate, B23 phase gate, analyze, boundary lint, and diff
check. Record B23 API Review and B23 UX Decisions.
```

## Evidence To Record

Actor screenshots, persona-switch screenshots, receiver screenshots, unauthorized persona screenshots,
backend parity output, per-persona workflow matrix audit, persona UX judge scorecard, manifest rows,
phase gate, analyzer, boundary lint, diff check, and commit SHA.
