# Skill Retrospective — closing the loop from "judge caught it" to "the Skill wouldn't have missed it"

## Why this exists, and what it is NOT

The independent Skill Output Judge (`Community JSON Migration Tracker.md` §1c) is not the production
architecture — it's training wheels. **The actual production goal is a Skill that authors correct,
complete engine-native JSON on its own, with no second independent pass required.** Every time a judge
finds a real defect, that's a signal the Skill's own instructions/context/prompting were insufficient to
prevent it — and treating "the judge caught it, ship the fix" as the end of the story wastes that signal.
This process closes the loop: after a judge-found defect is fixed, interrogate *why the authoring pass
missed it* and *what would have prevented it*, then turn the answer into a real, durable improvement to
`SKILL.md`/`docs/references` — so the next community authored is measurably less likely to repeat the same
mistake, and the judge's real job shrinks over time.

This is **not** the Root Cause Agent (`root-cause-agent-tool.md`, which diagnoses *engine/App-Shell* bugs
by reading source code) and **not** the Regression Impact Judge (`regression-impact-judge-tool.md`, which
checks a shared-code fix's blast radius across other consumers). Both of those are about code correctness.
This is about **prompting/documentation correctness** — why an LLM authoring pass, given the Skill's
current instructions, produced a wrong or incomplete artifact.

## The mechanism: ask the agent that actually made the mistake, not a fresh one

**Every Skill Output authoring dispatch this session has been a background `Agent` tool call with a real,
addressable agent id.** That agent's own conversation still holds its full reasoning: which doc rows it
read, what it considered, what it decided and why. A fresh agent asked "why would someone miss this" can
only speculate: it never had the original context. The original agent can actually answer.

**Procedure**, once a judge-found defect has been fixed and independently re-verified:

1. **Resume the original authoring dispatch** via `SendMessage` (`to: <original agentId>`), not a new
   `Agent` call. Ask it, concretely, referencing the exact defect:
   - *"The independent judge reviewing your package found `<exact finding, verbatim>`. Why did your
     authoring pass not implement/catch this? Walk through your actual reasoning at the time, if you
     recall it, rather than a generic explanation after the fact."*
   - *"What, specifically, would have made you get this right on the first pass — a different instruction
     in SKILL.md, an example of the correct shape in your read set, a check you were told to run but
     didn't, a doc you weren't told to read at all? Be concrete: name the exact file and the exact
     sentence/section that should exist or change."*
2. **Treat the answer as a hypothesis to verify, not a fact to ship.** An agent's retrospective account of
   its own reasoning can be post-hoc rationalized, same as a human's — cross-check the claimed cause
   against what SKILL.md/the referenced docs actually say today. If the agent claims "I wasn't told to
   check X" and X is already in the read order, that's a real finding too (the instruction exists but isn't
   salient/clear enough — a different fix than "the instruction is missing").
3. **Turn a verified cause into a real, durable doc change** — not a note to remember for next time. Options
   in rough order of strength: add the shape to `solved-patterns.md` (if it's a reusable requirement
   shape); tighten a Hard Rule's wording (if an existing rule was ambiguous or the agent read it but
   under-applied it); add a new self-check to `01-authoring-procedure.md` (if no check existed for this
   class of mistake at all); reorder/emphasize the read order (if the right doc existed but wasn't weighted
   heavily enough against competing instructions).
4. **Mirror the change into `chatgpt-upload/`** the same as every other Skill edit, per the standing
   convention in `SKILL.md`'s own maintenance notes.

## What this looked like for the two retrospectives run so far

### Chess Club — `chess-pairing-queue` silently dropped "queue position"

**Verified cause, in the agent's own words:** the agent *had already read* the fix (`formulas.md`'s
canonical Queue Position pattern, `indexOf(list, $viewer)`) and the fact that would have falsified its
reasoning (its own binding already used `role: "any"` on the `admin` tab it claimed Player couldn't reach)
— it had the correct information in context and still produced the wrong output. Two distinct causes, not
one: (1) a genuine read-order gap — `guide/06-product-doc-to-json.md` (which states outright that
per-persona tab sets aren't real grammar) is only read when the input doc literally matches the named
Template file; Chess Club's doc was the same shape but not that literal file, so it was never read; (2) a
cross-checking failure independent of missing information — the agent picked a row-per-waiting-player
archetype shape driven by the *primary* action alone, never went back to check that shape against the
doc's *other* stated requirements (queue position) before locking it in, then rationalized the resulting
gap with a false constraint instead of reconsidering the shape.

**Applied fixes** (commit series starting `0ae76df7`+):
- `01-authoring-procedure.md`'s product-doc-conversion callout now triggers on **doc shape** ("has a
  Persona Tabs table"), not literal Template-file identity — mirrored to `chatgpt-upload/`, inlining the
  key fact directly there since that bundle doesn't carry `06-product-doc-to-json.md` at all (a pre-existing
  gap, noted but not otherwise addressed by this fix).
- Step 3 (states-vs-data) gained an explicit cross-check: any doc using "position"/"queue"/"waiting
  list"/"ranking" must be checked against `formulas.md`'s Queue Position pattern and
  `solved-patterns.md` pattern 2 **before** the archetype/structural shape locks in, not after.
- (Step 9.5's traceability table, added the same session as this retrospective, independently also covers
  this class of gap for future authoring passes — the two fixes reinforce each other at different points
  in the process: Step 3 prevents the structural mistake, Step 9.5 catches it if Step 3 still misses it.)

### Ad-Free Community — unresolved `$actor` in `prefill` shipped despite the agent flagging its own uncertainty

(Retrospective dispatched; findings pending.)

## When NOT to run this

- The defect was an **engine/App-Shell bug** (CJM.5, CJM.6) — the Skill was sandboxed away from the source
  that would have let it know the documented grammar doesn't match real behavior. No prompting change fixes
  a spec that's asserting something false; the fix is fixing the spec's accuracy (or the engine), not the
  Skill's instructions. Route these to the Root Cause Agent / implementation ticket pipeline instead.
- The defect is a one-off, community-specific misjudgment with no generalizable shape (rare — most defects
  found so far *do* generalize, which is itself informative about where the Skill's current instructions
  are thin).

## Relationship to the production goal

Track this as a real metric over time, not just a per-defect exercise: **the rate of real judge-found
defects per community authored should trend down** as `solved-patterns.md` grows and Hard Rules get
sharpened from real retrospective findings. If it doesn't trend down after several retrospectives have fed
back into the Skill, that's a signal the retrospective's proposed fixes aren't actually landing as durable
doc changes, or aren't the real cause — revisit the process, don't just keep running it hoping for a
different outcome.
