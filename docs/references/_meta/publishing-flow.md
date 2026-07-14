---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
---

# Publishing flow — releasing a specification change

Normative. **A spec change is not "done" when the code merges. It is done when this flow completes.**

## The failure this prevents

The engine gains a capability. Nobody updates the docs. The Skill — which reads only the docs — keeps
generating JSON against the old contract. Either it generates something invalid, or (far worse) it never
learns the new capability exists and keeps writing bespoke workarounds. The docs silently rot into
fiction, and the Skill's output quality decays with them.

This is not hypothetical: it is exactly what happened to `docs/CardSurfaces/*.md`, which still tells
readers to call a `CommunityVoteApi` that **has never existed**.

**Rule: code, docs, and the reference community move together, or the change is not shipped.**

## Trigger

Run this flow whenever **any** of these change:

- `workflow_models.dart` — the models / `fromJson` parser
- `formula_evaluator.dart` — the formula vocabulary
- `local_workflow_engine_api.dart` — effect-op or guard semantics
- `binding_resolver.dart` — how bindings resolve
- The install/parse path for `experience` (`part15_evidence_catalog.dart`)

The tracked list lives in [`../spec-version.json`](../spec-version.json) → `groundedIn`.

## The flow

### 1. Classify the change

Additive or breaking? Apply the test in
[versioning-policy.md](./versioning-policy.md#breaking-vs-additive--the-bump-rule): *would every
existing community JSON still load and behave identically?*

### 2. Decide the version

- **Additive** → version numbers **stay**. Record as an addition under the current version.
- **Breaking** → **bump** the affected layer in [`../spec-version.json`](../spec-version.json).
  Add the old version to that layer's `supported` list **only if** the loader really still supports it;
  otherwise dropping it is itself a breaking change to advertise.

### 3. Update the normative reference — *before* the guide

The `reference/` docs are the contract. Update them first, from the **code**, not from memory or from
the guide.

- [ ] Amend the relevant `reference/*.md` (grammar, guards, effects, formulas, field-types,
      render-bindings, theming, platform-services).
- [ ] Update its frontmatter: `spec`, bump `doc_version`, set `last_verified` to today.
- [ ] Every reference doc cites the source file it derives from — confirm the citation still resolves.

### 4. Update the guide and archetypes

- [ ] `guide/*.md` — if the change affects how you'd *teach* it.
- [ ] `guide/03-common-patterns.md` — if a recipe is now written the wrong way.
- [ ] `guide/04-antipatterns.md` — if the change makes a former workaround unnecessary (**the most-missed
      step**: capabilities get added and the old workaround stays enshrined as "the way").
- [ ] `archetypes/*.md` — any archetype whose JSON shape changed.

### 5. Update the reference communities

- [ ] `Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` — the reference community
      must be **re-authored against the new spec**, not left behind. It is the Skill's grounding example;
      a stale one teaches the Skill the wrong thing.
- [ ] Re-stamp its version fields.
- [ ] `communities/*.md` — update its notes.

### 6. Re-validate everything

- [ ] Run the community-package validator over **every** community JSON in the repo
      (`guide/05-validation.md`). Not just the one you touched — a grammar change can invalidate files
      you didn't think about.
- [ ] Run the docs-sync checker ([`docs-sync-checker.md`](./docs-sync-checker.md)) — no doc may be left
      `stale`.
- [ ] Run the engine + app-shell + validator test suites.

### 7. Record it

- [ ] [`../CHANGELOG.md`](../CHANGELOG.md): what changed, why, breaking or additive, what an author must
      do about it (a **migration note** for breaking changes — "here is how to update your JSON").
- [ ] [`doc-manifest.json`](./doc-manifest.json): bump `syncedTo` for every doc touched.
- [ ] [`../spec-version.json`](../spec-version.json): `lastReviewed`, and `released` if the version moved.

### 8. Close a known gap, if you closed one

[`../spec-version.json`](../spec-version.json) → `knownGaps` lists capabilities the docs say are needed
but the grammar lacks. If this change closed one, **remove it from `knownGaps`** and delete the
`NEEDS IMPLEMENTATION` markers it justified in the reference JSON. A stale "known gap" sends the Skill
building workarounds for a problem that no longer exists.

## Definition of done

A spec change ships only when **all** are true:

- [ ] `spec-version.json` reflects reality (version, `lastReviewed`, `knownGaps`).
- [ ] Every affected `reference/`, `guide/`, and `archetypes/` doc is updated and re-stamped.
- [ ] The reference community JSON is re-authored and re-validated against the new spec.
- [ ] The validator passes on **every** community JSON in the repo.
- [ ] The docs-sync checker reports **zero** stale docs.
- [ ] `CHANGELOG.md` has an entry, with a migration note if breaking.

## Roles

- **Whoever changes the engine** owns steps 1-3. The spec is part of the change, not a follow-up. A PR
  that alters the grammar without touching `reference/` is incomplete.
- **Whoever maintains the Skill** owns steps 4-5 — they are the docs' primary consumer.
- **The verification agent** enforces steps 6-8 before the change is considered closed, applying the
  same discipline as any milestone: independently re-run the validator and the suites; never accept a
  self-report.
