# Community-authoring Skill — dispatch tool for producing a new engine-native JSON package from a spec doc

## What it is

Not a script — a **prompt bundle** (`.agents/skills/loom-calendar-experience-authoring/SKILL.md` + a
`docs/references/**` reference tree) that, when read in full by any sufficiently capable LLM, is sufficient
on its own to author a real, validator-clean workflow-engine JSON package from a plain-language product
spec. It is the **producer** half of the same discipline every other tool in this directory enforces on the
**consumer/verification** side — the thing whose output the Skill Output Judge, the Regression Impact Judge,
and the Skill Retrospective process all exist to check and improve.

**Confirmed working end-to-end against a zero-tool-access external LLM** (a ChatGPT Custom GPT with no repo
access, no filesystem, no code execution — see the Skill's own `SKILL.md` header for the exact verification:
byte-for-byte match against an independent local re-run of the same source material). That's the design
constraint worth internalizing: everything the Skill needs must be reachable by *reading docs alone*, never
by running a tool, because the whole point is testing whether documentation-as-interface is sufficient.

## Two channels, one source of truth

- **In-repo dispatch**: the `Agent` tool, `subagent_type: general-purpose`, given a prompt instructing it to
  act as this Skill — reading only `docs/references/**` (plus the Skill's own bundle) and the target spec
  doc, explicitly forbidden from reading any existing hand-authored comparison artifact or other session
  context that would let it "cheat" by pattern-matching a known-good answer instead of actually deriving one.
- **Zero-tool-access external channel** (e.g. a custom GPT): the portable export at
  `.agents/skills/loom-calendar-experience-authoring/chatgpt-upload/` (20 files, uploaded as-is), with a live
  HTTP validator wired in as a Custom GPT Action so the external agent can self-validate before returning an
  answer. Every edit to the in-repo docs that changes authoring behavior must be **mirrored** into this
  bundle — the two are kept in lockstep deliberately, not left to drift, since the whole point of the
  external channel is proving the *same* material works with zero tool access.

Both channels read the identical procedure — see `SKILL.md`'s own "Read order" table for the current,
authoritative list of source docs (currently: the archetype confirmation list, workflow grammar, field
types, common patterns, the requirement-traceability-table procedure, and the growing
`solved-patterns.md` bank).

## The procedure, at a glance

1. **Scope check**: confirm every required `cardSurfaceFamily` in the spec doc is confirmed real in
   `docs/references/archetypes/README.md` — refuse plainly (which section, why it doesn't fit any real
   archetype) rather than force-fitting a request into an unsupported shape.
2. **Author** following `docs/references/guide/01-authoring-procedure.md`'s numbered steps, cross-checking
   requirement shapes against `docs/references/reference/solved-patterns.md` (a catalog of recurring
   requirement shapes with a "looks-plausible-is-wrong" vs. "verified-correct" pairing for each — see below).
3. **Self-validate** using the in-repo/HTTP validator (`validator-tool.md`) before returning an answer.
4. **Build the requirement traceability table** (mandatory output, not an internal check) — one row per
   product-doc requirement, mapped to exactly what in the JSON satisfies it, with a real, citable reason for
   any requirement marked `not_implemented`/`partial` (a validator rule, a closed enum, a missing formula
   function — never a guessed constraint). This is the artifact a judge reads first when checking whether the
   authoring pass actually covered the spec, not just produced *a* valid package.

## The Solved Patterns bank — why it exists, and how to grow it

`docs/references/reference/solved-patterns.md` (mirrored to `chatgpt-upload/20-solved-patterns.md`) catalogs
requirement shapes that have already tripped up a real authoring pass at least once, each with four parts:
the requirement shape (in plain language, as it tends to appear in a spec doc), the plausible-but-wrong JSON
shape an under-informed pass tends to produce, the verified-correct shape, and where it was found. This is
**not** a general design-pattern library — every entry exists because a real judge dispatch caught a real
defect, and the pattern was added *after* the fact as a durable fix, never speculatively.

Grow this bank via the **Skill Retrospective** process (`skill-retrospective-tool.md`): when a judge finds a
defect, resume the *original* authoring agent and ask why it missed the requirement and what would have
prevented it — the answer becomes a new pattern entry (or a tightened Hard Rule, or a reordered read
priority) once verified against what the docs actually say today, not accepted as fact on its own.

## Validation, in-repo

```bash
dart run loom_ux_judges:community_package_validator --package <your-file>.jsonc
```
See `validator-tool.md` for the full validator reference (structural rules, warning-vs-error, the HTTP
server variant used by the external channel).

## Relationship to the other roles in this pipeline

- **Skill Output Judge** (documented as a worked pattern, not a standalone doc, in this project's own
  `Community JSON Migration Tracker.md` §1c) — a *separate*, independently-dispatched `Agent`-tool review
  comparing the Skill's output against the source product doc and the Skill's own Hard Rules. Never
  self-judged — the authoring agent never reviews its own output.
- **Skill Retrospective** (`skill-retrospective-tool.md`) — the loop-closing step once a judge finds a real
  defect: interrogate the agent that made the mistake, verify its account, land a durable fix in the Skill's
  own instructions.
- **Regression Impact Judge** (`regression-impact-judge-tool.md`) — relevant when a defect turns out to be a
  bug in **shared rendering/engine code** the Skill's output merely exposed (not a prompting gap) — that
  routes to a code fix + blast-radius check, not a Skill Retrospective (see that doc's own "when NOT to run
  this" section for the exact split).

## Production goal — this Skill is training wheels for itself

The independent judge pass is not the end-state architecture. The goal is a Skill that authors correct,
complete output on its own, with no second independent pass required — every judge-found defect is a signal
the Skill's own instructions were insufficient, and the Skill Retrospective process exists to shrink that gap
over time. Track the real judge-found-defect rate per artifact authored as a metric: it should trend down as
`solved-patterns.md` grows and Hard Rules get sharpened from verified retrospective findings. If it doesn't,
that's a signal to revisit the retrospective process itself, not to keep running it hoping for a different
outcome.
