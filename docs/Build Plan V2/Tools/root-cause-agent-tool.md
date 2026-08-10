# Root Cause Agent — dispatch tool for bugs that resist normal investigation

## What it is

A dedicated, read-only Codex CLI role for diagnosing a bug whose mechanism hasn't been pinned down by the
orchestrating session's own reading/hypothesis-and-test budget — distinct from the **Implementation Agent**
(`data/call_implementation_agent.sh`), which writes and commits real fixes, and from the **LLM Vision UX
Judge Agent** (`ux-gate-judge-tools.md`), which reviews rendered UI against a product doc. The Root Cause
Agent does neither: it only reads code and produces a diagnosis or a precise instrumentation request.

**Script**: `data/call_root_cause_agent.sh`. **Model**: `gpt5_6_sol_xhigh` (`gpt-5.6-sol` at
`reasoning_effort: xhigh`) by default, overridable via `CODEX_ROOT_CAUSE_PROFILE`. **Sandbox**:
`workspace-write`, but enforced read-only by the role preamble the script prepends to every brief — it may
write to exactly one file (the report path named in the brief), nothing else.

Added 2026-08-01 after a regression investigation exhausted the verification agent's own
hypothesis-and-test budget without pinning the exact mechanism (five candidate causes each confirmed NOT
responsible, true mechanism still unidentified at that point). First documented here 2026-08-10 after a
second real dispatch, during the Community JSON Migration effort's live UX walkthrough of Cedar Commons
HOA (`Community JSON Migration Tracker.md` §6) — a live emulator run surfaced a real, unexplained
`PathAccessException`/permission-crash mechanism (a freshly-signed-up Board persona's Admin tab throwing
`Bad state: Permission denied for surface admin for <accountId>`) that needed exactly this kind of
multi-file, cross-layer tracing (engine API → app-shell permission resolver → local auth API) before a fix
could be safely scoped.

## Contract — exactly two valid outcomes, never a hedge between them

The role preamble the script injects (verbatim, before your brief) is strict about this:

1. **A confident root-cause diagnosis + a concrete recommended fix**, stated at the mechanism level (which
   function, which line, which interaction, why it produces the observed symptom) with a prose/pseudocode
   description of the fix — not a literal diff (that's the Implementation Agent's job on a follow-up
   dispatch). Only this outcome if genuinely confident, not merely suspicious — a wrong confident diagnosis
   costs a full wasted implementation round.
2. **A precise instrumentation/tracing request**: exact `file:line` locations to add temporary logging,
   exactly what values to print at each, exactly what test/scenario to run to trigger them, and what each
   candidate hypothesis would look like in that output. Vague requests ("add more logging around the
   mutation") are explicitly rejected by the role's own contract.

A report that does neither (e.g. "try X and see if it works") is incomplete — re-dispatch with that fed
back rather than accepting it as final.

**Hard constraints, enforced by the preamble and by the dispatching session's own post-run diff check**:
never edits/creates/deletes any implementation file (`.dart`, `.jsonc`, reference `.md`) — not even a "small
diagnostic tweak," not even something it's highly confident is the fix; never runs `apply_patch` against
anything but the one designated report file; never runs `git add`/`git commit` or any state-mutating
command; never adds print statements or comments-out code to "just check" something — if it wants
instrumentation, it must request it via outcome 2, not add it itself. The dispatching session **must**
`git status`/`git diff` after every run and treat any change outside the one report file as a violation to
investigate, not silently accept or commit.

## Writing the brief

The brief file (passed as `data/root_cause_brief_<name>.md`, referenced by
`bash data/call_root_cause_agent.sh <brief-file> [--fresh]`) must include, so the agent doesn't waste its
budget re-deriving what's already known:

- The exact symptom, reproduced verbatim (error text, stack trace, screenshot description) — not a
  paraphrase.
- The current diff/commit(s) under investigation, if any (this dispatch is not limited to regressions —
  it's equally suited to a pre-existing bug surfaced by new testing, as in the Cedar Commons HOA case,
  where nothing in the diagnosed community's own JSON was the suspected cause).
- The **full ruled-in/ruled-out matrix so far** — every file read, every mechanism traced, cited by exact
  `file:line`, and explicitly marked what's confirmed vs. still-open. Re-deriving already-done reading is
  the single biggest waste of this dispatch's budget.
- Any trace/log output already captured.
- A named "leading hypothesis" section is fine (and was used in the HOA Admin-crash brief) as long as it's
  explicitly marked unconfirmed — giving the agent a starting thread to pull is more efficient than making
  it re-explore the whole call graph from scratch, but the brief must not present the hypothesis as settled.
- The exact report file path to write to, and an explicit reminder of the scope boundary (read-only, no
  edits, which files are out of bounds and why if that's non-obvious).

## Dispatch mechanics

Identical recipe to `data/call_implementation_agent.sh` (see that script's own header comment for the full
annotated walkthrough) — same `wsl_dispatch_tracker.sh baseline`/`capture`/`cleanup`,
`watch_dispatch_log.sh` completion watch, same vsock-alert handling (benign mid-run noise; a genuine
`DISPATCH_HIT_VSOCK=1` block only matters if it's the terminal state), same OneDrive `.git/index.lock`
transient-error handling. The only differences from the Implementation Agent script: the role preamble
(above), the default model profile, and that a clean run never touches `git` at all (nothing to commit) —
so the post-dispatch step is "read the one report file and decide what to do with it," not "confirm a
commit landed."

## What happens to the report

The report is handed back to whoever dispatched it (the orchestrating session, not the agent itself) to
turn into a real implementation ticket via the normal `data/v3_ticket_<name>.md` +
`call_implementation_agent.sh` cycle — the Root Cause Agent never implements its own diagnosis. If the
report is an instrumentation request (outcome 2), the next step is a ticket asking the Implementation Agent
to add exactly that instrumentation, run the specified scenario, and report the captured output back —
which then either directly reveals the mechanism or becomes the input to a second Root Cause Agent
dispatch.
