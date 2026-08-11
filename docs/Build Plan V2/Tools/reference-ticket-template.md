# Reference ticket template — the lightweight dispatch format

This is the ticket format every real dispatch round in this project's history used —
`data/v3_ticket_<slug>.md`, handed to `data/call_implementation_agent.sh`. It is deliberately lightweight:
seven fixed sections, no schema validation, readable top to bottom by a human before it's ever dispatched.

**Not the same thing as** the heavier, schema-v4 B25 Remediation Ticket format
(`b25-remediation-ticket-template.md`) — that one targets a separate Worker Agent/Remediation Planner
process built around structured findings from the UX judge pipeline. Use *this* template for ordinary
implementation/fix/investigation work; reach for the B25 format only if you've adopted that specific pipeline
too.

## The seven sections

```markdown
Ticket <id> — <one-line description>

## Context

Why this ticket exists, and everything already known/ruled-out so the agent doesn't waste its budget
re-deriving it. Include:
- What problem this solves and why it matters (link a parent tracker/tracking doc if one exists).
- Exact file:line citations for anything already confirmed by reading the source — never make the
  dispatched agent re-discover what you already know.
- Dependencies: what this ticket assumes already landed, and how you confirmed that (a file:line citation,
  not just "should be done by now").
- What this ticket unblocks, if relevant.

## Scope

The concrete, numbered list of changes. One item per file/mechanism touched, specific enough that two
different agents given this ticket would produce materially the same diff. Name exact functions/classes to
change, the exact new field/parameter shape, and the exact fallback behavior for anything that must stay
backward-compatible.

## Do not do

Explicit boundaries — files, features, or related-but-out-of-scope work this ticket must NOT touch. Always
include, verbatim or adapted:
- Any adjacent ticket/feature this one must not encroach on.
- "The working tree may have other unrelated uncommitted changes when you start. Stage and commit ONLY the
  files you actually touch for this ticket, by exact path. Do NOT use `git add -A`, `git add .`, or
  `git commit -am`."
- Any invariant that must survive unchanged (e.g. "do not change any existing `ValueKey`s — grep before and
  after, confirm the old key set is a subset of the new one").

## Required verification

Exact commands, exact expected outcomes — not "make sure it works." Always include:
1. The exact `analyze`/lint command(s) for every package touched, and "clean" as the bar.
2. The exact test command(s), and "identical pass count to baseline" (name the baseline count if you know
   it) plus any specific new test(s) required, described precisely enough that its assertions are
   unambiguous.
3. Any project-specific invariant check relevant to this ticket (e.g. a key-set diff, a schema validator
   run, a visual re-check).
4. "If your sandbox cannot run <command>, say so plainly — independent verification will be re-run outside
   the sandbox regardless." (Always include this — never let a missing command silently become "assumed
   fine.")

## Git safety reminder

Paste verbatim if your repo lives on a cloud-synced path (OneDrive, Dropbox, Google Drive) accessed from
WSL/a container — the exact failure mode this guards against is documented in
`dispatch-pipeline-tools.md`'s `call_implementation_agent.sh` section:

> This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's
> own atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
> `.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and
> requires no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the
> same command once. If it fails again, STOP — do not run `git reset --hard`, any broad `--cached` unstage,
> or recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working
> tree as-is.

(`call_implementation_agent.sh` already prepends an equivalent preamble automatically — this section in the
ticket is a second, ticket-local reminder, cheap insurance against a resumed session having lost that
context.)

## Commit

The exact commit message to use, once verified. One commit per ticket unless the ticket explicitly scopes
multiple. Naming it in advance keeps commit history consistent across many independently-dispatched rounds.

## Required response format

Tells the agent exactly what machine-checkable status file to write, and its exact shape — always
`data/v3_ticket_<slug>_STATUS.md` (or your own naming convention), always covering: what was actually
changed (file:line, and any judgment calls made — "state which shape you used and why"), the verification
results (not just "passed" — the actual counts/output), and the commit outcome (hash, or "staged, not
committed" + the exact blocker). This is what you read first when the dispatch completes — but never treat
it as sufficient evidence on its own; see README's core discipline.
```

## Worked example (real, shipped)

The following is a real ticket from this project's history, lightly trimmed, showing the format filled in
for a genuinely non-trivial change (a new JSON field threaded through a data model, a Flutter widget, and a
generic-card bridge, with an explicit backward-compatibility requirement):

```markdown
Ticket CJM.3 — citation-list rendering (`itemSchema` on `type: "list"`)

## Context

Part of the Community JSON Migration effort (`docs/Build Plan V2/Community JSON Migration Tracker.md` §2).
Locked spec addition (§1, already approved, `field-types.md` doc_version 1.2.0): a `type: "list"` field may
declare an `itemSchema` whose members can themselves be `type: "url"` — each list item renders as label text
plus a tappable link per that member's own `openMode`. No new field `type` — this extends the existing
`type: "list"` field, and reuses CJM.2's already-shipped tap-to-open primitive (do not reinvent it).
**Depends on CJM.2, which has already landed** — confirmed by direct read, `type: "url"` rendering exists at
`.../part18_marketplace_rendering.dart:568-594`.

**Confirmed from source, read this session (cite exactly):**
1. `InstanceDataField` (`.../workflow_models.dart:713-785`) — has `type`, `openMode` — no `itemSchema` field
   at all. `fromJson` silently drops any `itemSchema` key present in the JSON today.
2. `WorkflowFactPillFieldSchema` (`.../part18_marketplace_rendering.dart:153-176`) — same gap on the
   Flutter-rendering side.
3. `WorkflowFactPillRow._factWidget` (same file, 542-601) — the actual per-field render switch; this is
   where a `type == 'list'` branch belongs, following the exact structural pattern CJM.2 used for `url`.
4. The same generic-card bridge gap CJM.2 had to fix will very likely recur here — confirm whether the
   `WorkflowFactPillFieldSchema(...)` constructor call in `part26_generic_instance_card.dart` was updated by
   CJM.2 to also pass `openMode` — read the actual current state yourself rather than assuming.

## Scope

1. `workflow_models.dart` (`InstanceDataField`): add `Map<String, InstanceDataField>? itemSchema`, parsed
   from `json['itemSchema']`. No validation logic here — just carry the value through.
2. `part18_marketplace_rendering.dart` (`WorkflowFactPillFieldSchema`): add the equivalent field + ctor
   param, same optional pattern as `openMode`.
3. `part18_marketplace_rendering.dart` (`_factWidget`): add a `type == 'list'` branch (before the fallback)
   rendering non-url members as text, url members as tappable links per their own `openMode`. If
   `itemSchema` is absent, fall through to today's existing behavior unchanged — purely additive, never a
   regression for a `type: "list"` field without `itemSchema`.
4. `part26_generic_instance_card.dart`: confirm/fix the `itemSchema:` wiring at the constructor call site per
   Context point 4 — state in STATUS which case you found.

## Do not do

- No editing, no per-item actions, no new effects/guards vocabulary — pure read-time rendering only.
- Do not add the proposed `item_schema_on_non_list_field` validator rule — separate, not-yet-approved ticket.
- Do not touch unrelated already-landed code (name the specific file/feature).
- Do not modify the locked spec doc — this ticket only implements it.
- Do not change any existing `ValueKey`s — grep before and after, confirm the old key set is a subset of the
  new one.
- The working tree may have other unrelated uncommitted changes when you start. Stage and commit ONLY the
  files you actually touch, by exact path. Do NOT use `git add -A`, `git add .`, or `git commit -am`.

## Required verification

1. `flutter analyze` on both touched packages — clean.
2. Full test suites for both — identical pass count to baseline, plus one new test asserting a `type: "list"`
   field with an `itemSchema` url member renders a tappable per-item link (mock/skip the platform
   `url_launcher` channel call, per CJM.2's own test precedent).
3. Confirm the `ValueKey`/`Key` grep check was actually run, before and after; report the result in STATUS.
4. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly — independent verification
   will be re-run outside the sandbox regardless.

## Git safety reminder

[verbatim OneDrive/git-index-lock note, as above]

## Commit

One commit, once verified: `feat: render citation-list items (itemSchema on type:"list") with per-item url
links (CJM.3)`.

## Required response format (write to `data/v3_ticket_cjm3_citation_list_rendering_STATUS.md`)

    # Ticket status: CJM.3

    ## Change applied
    Status: done | blocked
    Exact file:line for each of the 4 scope items. State which shape you used for itemSchema's Dart type and
    why. State whether CJM.2's openMode wiring at the part26 generic-card bridge was already correct or
    needed fixing alongside itemSchema.

    ## Verification
    flutter analyze (both packages): clean/not clean.
    Test suite (both packages): pass count, before/after, naming the new test.
    ValueKey/Key grep check: confirm run, before/after key sets compared.

    ## Commit
    Commit hash, or "staged, not committed" + exact blocker.
```

This ticket shipped cleanly on the first dispatch, independently re-verified, no follow-up round needed —
worth studying as the target quality bar: every claim in Context is a citation, not an assumption; every
Scope item names the exact file and exact fallback behavior; Do not do closes every scope-creep path an
agent might otherwise rationalize its way into.
