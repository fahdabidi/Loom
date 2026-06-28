# Phase B20 - Multi-Persona Workflow Evidence Sweep

## Achieves

Prove workflows that require multiple personas by switching persona during Android emulator UI tests.

## Deliverables

- Multi-persona workflow tests for anchor, arbitrary, prompt-generated, and platform examples.
- Full per-persona workflow matrix tests for every declared persona and workflow.
- Prerequisite producer/receiver scenario tests where one persona must create state first.
- Screenshot manifests that include persona IDs and role labels.
- Backend continuity assertions across persona switches.
- Final B17-B20 persona evidence manifest.
- Full B1a-B20 workflow regression sweep.
- B20 API Review and B20 UX Decisions.

## Completed When

Every persona/workflow matrix row is proven through visible UI evidence or explicitly marked not
applicable with rationale. At least one prerequisite-chain workflow per relevant community proves
actor-to-recipient behavior. Masjid Nur must prove admin publishes a public announcement and member
receives/searches it after persona switch.

## Evidence To Record

Multi-persona screenshot bundles, per-persona workflow matrix audit, final persona evidence manifest,
emulator command output, full regression output, manifest rows, phase gate, analyzer, boundary lint,
diff check, and commit SHA.

## Execution Evidence - 2026-06-27

- `wf_multi-persona-workflow-evidence` passed across all example/test communities.
- Android evidence: `docs/Build Plan V2/Evidence/B20/workflow-ui-evidence.json`.
- Final manifest: `docs/Build Plan V2/Evidence/B20/all-workflow-ui-evidence.json` reports
  `status=pass`, 66 workflows, and 198 screenshots across B12-B20.
