#!/bin/bash
# data/call_root_cause_agent.sh
#
# Direct invocation of the Root Cause Agent. Added 2026-08-01 after
# CAL.Notify2.9's own regression investigation exhausted the verification
# agent's own hypothesis-and-test budget without pinning the exact mechanism
# (systematically ruled out five candidate causes, each confirmed NOT
# responsible, with the true mechanism still unidentified).
#
# Migrated off WSL2 onto a VirtualBox Ubuntu VM 2026-08-12 -- see
# docs/Build Plan V2/Tools/wsl-to-virtualbox-migration.md. Runs INSIDE the
# guest (~/Loom/data/), invoked from the host via
# `ssh loom-vm '. ~/.loom-env.sh && ...'`, not via `wsl.exe`.
#
# Switched Codex CLI -> Muse Code CLI 2026-09-07, then back to Codex CLI the
# same day (both user-directed) -- model `gpt-6-astra` at reasoning
# effort `high`. This required upgrading the VM's Codex CLI itself: the
# installed 0.147.0 rejected `gpt-6-astra` with "requires a newer version of
# Codex"; `npm install -g @openai/codex@0.153.4` fixed it, confirmed live
# (`codex exec -p gpt6_astra_high --sandbox read-only "Reply with exactly:
# PROFILE_OK"` -> correct reply, exit 0). Profile:
# ~/.codex/gpt6_astra_high.config.toml (model = "gpt-6-astra",
# model_reasoning_effort = "high", model_verbosity = "medium",
# model_context_window = 272000, service_tier = "fast").
#
# SESSION SCOPING, user-directed 2026-09-08 (supersedes the 2026-09-07
# "one permanent session" design). A session is scoped to ONE task or ONE
# tracker phase/milestone, not to the whole project:
#
#   * No session key  -> a FRESH session, every time. This is the default,
#     because most dispatches are one-off questions and a stale unrelated
#     context is worse than no context.
#   * Session key given -> resume that key's session if one exists, else seed
#     it and record it under that key. Use the SAME key for a follow-up on
#     something this agent already helped with, and for every dispatch inside
#     one tracker phase/milestone. A NEW phase means a NEW key.
#
# Why this replaced the permanent session: measured 2026-09-08 across the
# first three dispatches, cached input is not free (~10% of uncached), so a
# large accumulated prefix is a RECURRING tax on every resume -- at one
# dispatch the cached prefix cost ~144k uncached-equivalent against only ~82k
# of genuinely new input. A key-scoped session keeps the benefit that matters
# (a follow-up remembers the work it is following up on) without every
# unrelated question paying for the whole project's history. The cache rewards
# a STABLE prefix, not a LARGE one.
#
# Mechanism: the Codex thread id is captured from the `thread.started` event
# in `--json` output and persisted per key at
# `.codex-logs/root_cause_sessions/<key>.id`. There is still no flag to force
# a resume of an arbitrary session -- you either name a key or you get a fresh
# session, so a caller can never silently inherit an unrelated context. To
# abandon a key's accumulated session, delete that key's file by hand.
#
# The pre-2026-09-08 global file `.codex-logs/.root_cause_agent_session_id` is
# NO LONGER read automatically. It is left in place as history; pass
# `--session-key legacy-expert` if you deliberately want that old accumulated
# session back.
#
# READ-ONLY, user-tightened 2026-09-07 -- real sandbox enforcement, not just a
# prompt rule. This agent has ZERO write access and ZERO network access,
# confirmed live, not assumed: `--sandbox read-only` rejects a write with
# `Read-only file system` even to a directory named in `--add-dir` (`--add-dir`
# only has meaning under `workspace-write` -- "additional directories that
# should be WRITABLE alongside the primary workspace" -- and does nothing
# under `read-only`), and a `curl` to a live local service under
# `read-only` fails outright (`exit 7`, no route -- there is no config key
# to re-enable network under this sandbox mode the way
# `sandbox_workspace_write.network_access` does under `workspace-write`).
# **Consequence for briefs**: this agent cannot fetch its own live evidence
# (DB queries, curl checks, `kubectl`) the way earlier dispatches sometimes
# did -- any such evidence must be gathered by the dispatching session BEFORE
# writing the brief and pasted into it. The agent reads code and reasons; it
# does not act. It may propose code edits, tests, or additional
# instrumentation, but only as TEXT in its reply, for a human or the
# implementation agent to actually apply -- never as a file it writes itself.
# `--sandbox` is not accepted by `resume` (confirmed live, see below) so this
# is set once at the seed dispatch and holds for the session's entire life.
#
# Discovered the hard way (confirmed live, not guessed) while wiring this up:
# `codex exec resume <SESSION_ID> [OPTIONS] [PROMPT]` does NOT accept
# `-p/--profile`, `--sandbox`, or `--add-dir` -- only `-c/--config` and
# `-m/--model` (its own `--help` lists the full set; anything else is a hard
# parse error, e.g. "unexpected argument '--sandbox' found"). So the sandbox
# mode is fixed FOREVER at the seed (first-ever) invocation and cannot be
# changed by any later resume -- get it right once. The model/profile
# settings, by contrast, must be RE-SPECIFIED via `-c` on every resume (there
# is no profile layering on `resume`), which is why the resume branch below
# spells out every `gpt6_astra_high.config.toml` value as its own
# `-c key=value` rather than `-p gpt6_astra_high`. Confirmed live that the
# thread id is stable across a resume (resuming a real session and asking the
# agent to quote what it was told in the previous turn got the previous
# turn's exact text back verbatim, with a real cache hit on the resumed
# call's `cached_input_tokens`) -- this is a real continued conversation, not
# a fresh session that happens to share a label.
#
# NO FILE-BASED REPORT ANY MORE, same tightening: this agent has nothing to
# write a report file WITH (no write access at all), so its entire
# deliverable is its conversational reply -- diagnosis, proposed fix,
# proposed test code, or an instrumentation/logging request -- captured in
# this dispatch's own `--json` output log. Read that log directly; there is
# no separate report path to go find.
#
# Two, and only two, valid outcomes for a Root Cause Agent reply:
#   1. A confident root-cause diagnosis + a specific, concrete recommended
#      fix described in prose (file/function/mechanism-level, not a diff) --
#      handed back to the verification agent to turn into a real
#      implementation ticket.
#   2. A precise, minimal specification of what additional instrumentation,
#      tracing, or tests are needed to narrow the mechanism further -- exact
#      file:line locations to instrument, exact values to print, exact
#      scenarios to run -- handed back to the verification agent to turn into
#      an instrumentation ticket for the implementation agent.
# A report that does neither (e.g. "try X and see if it works") is incomplete
# -- re-dispatch with that fed back, don't accept it as final.
#
# Two jobs, not one (recorded 2026-09-07 in the ACWS tracker and TODO.md):
# scoping a non-trivial change BEFORE an implementation ticket is written --
# what it actually touches, the real mechanism, what it would break -- not
# only debugging something that already broke.
#
# MASTER SUPERVISOR / keypatterns.md, user-directed 2026-09-07: the whole
# point of the persistent session above is that this agent becomes the
# project's standing expert, not just a stateless investigator run fresh
# each time. Since it has zero write access, it cannot maintain
# `keypatterns.md` (repo root, append-only -- recurring issues, durable
# patterns, key architectural decisions/pivots) directly the way an earlier
# version of this design intended. Instead: the agent PROPOSES an entry, as
# plain text in its reply, delimited exactly by a `<<<KEYPATTERNS_ENTRY>>>`
# / `<<<END_KEYPATTERNS_ENTRY>>>` pair (the role preamble tells it this
# verbatim). THIS SCRIPT -- running outside the sandbox, as the orchestrator,
# never the sandboxed model -- extracts that block after the dispatch
# finishes and appends it to `keypatterns.md` itself. That is the file's
# only writer; the agent never touches it, matching "zero write access"
# literally rather than as an exception. keypatterns.md is staging memory,
# not the project's real instructions: after any dispatch that adds an
# entry, the orchestrating session (you) reviews it and folds anything
# genuinely durable into CLAUDE.md itself, the file every session actually
# loads.
#
# Usage:
#   bash data/call_root_cause_agent.sh <path-to-brief-file> [--session-key <key>]
#
# Omit --session-key for a one-off question (fresh session). Pass the SAME key
# to continue a task you already consulted this agent about, or to share one
# session across a tracker phase; see SESSION SCOPING above. Keys are
# free-form; use something durable like `gap-permission-catalog` or
# `phase-e-access-authority`.
#
# Same dispatch-and-watch recipe as data/call_implementation_agent.sh
# (dispatch over ssh loom-vm, watch via watch_dispatch_log.sh) -- reuse that
# recipe verbatim, this script only differs in role/model/sandbox scope, not
# in dispatch mechanics. `watch_dispatch_log.sh` recognizes
# "codex exec exited with status" as the real completion line -- unchanged
# from before the Muse detour, no update needed there.
#
# The brief file you pass in should include: the current diff/commit(s) under
# investigation (or, for a scoping dispatch, what change is being considered
# and why), the full ruled-in/ruled-out matrix so far (do not make the agent
# re-derive work already done), and any trace/log/live-query output already
# captured -- gathered by you beforehand; the agent cannot fetch its own
# (see READ-ONLY above).

set -euo pipefail

PROMPT_FILE="${1:?usage: call_root_cause_agent.sh <brief-file> [--session-key <key>]}"
shift || true

SESSION_KEY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session-key)
      SESSION_KEY="${2:?--session-key needs a value}"
      shift 2
      ;;
    --session-key=*)
      SESSION_KEY="${1#--session-key=}"
      shift
      ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      echo "usage: call_root_cause_agent.sh <brief-file> [--session-key <key>]" >&2
      exit 2
      ;;
  esac
done

# Keys become filenames: keep them boring and collision-free.
if [ -n "$SESSION_KEY" ]; then
  SESSION_KEY_SAFE="$(printf '%s' "$SESSION_KEY" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-' | sed 's/^-*//; s/-*$//')"
  if [ -z "$SESSION_KEY_SAFE" ]; then
    echo "ERROR: --session-key '$SESSION_KEY' has no usable characters" >&2
    exit 2
  fi
fi
MODEL="${CODEX_ROOT_CAUSE_MODEL:-gpt-6-astra}"
REASONING_EFFORT="${CODEX_ROOT_CAUSE_REASONING_EFFORT:-high}"
PROFILE="${CODEX_ROOT_CAUSE_PROFILE:-gpt6_astra_high}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: brief file not found: $PROMPT_FILE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Non-interactive shells (via `ssh loom-vm 'cmd'`) skip ~/.bashrc entirely --
# resolve the toolchain PATH explicitly. Never substitute `bash -l`.
. "$HOME/.loom-env.sh"

ROLE_PREAMBLE='# ROLE: Root Cause Agent -- read this before anything else

You are the Root Cause Agent for this repository -- either scoping a non-trivial change before an
implementation ticket is written, or investigating a bug that has resisted the verification agent'"'"'s own
hypothesis-and-test budget. You are NOT an implementation agent. This is a long-lived, persistent session:
you carry context across every dispatch made to you, so treat earlier turns in this conversation as real
prior investigation, not as something to re-derive. Across those dispatches you are meant to become this
project'"'"'s standing expert -- the one place that accumulates recurring issues, durable patterns, and key
architectural decisions/pivots, acting as its master supervisor rather than a one-off investigator with no
memory of the last one.

**You have NO write access and NO network access -- this is enforced by your sandbox, not just a rule.**
Every shell command you run that attempts to write anywhere, or reach the network, will fail outright. This
is deliberate: you read code and reason, you do not act.

**You must NEVER:**
- Attempt to edit, create, or delete any file. You cannot -- do not waste a turn discovering this the hard
  way when reasoning about the code already tells you the same thing.
- Attempt to fetch live evidence (DB queries, `curl`, `kubectl`, anything network-dependent). You have no
  network access. If you need live evidence that was not included in the brief below, say so explicitly and
  name exactly what you need (see outcome 2) -- do not guess in its place.
- Run `git add`/`git commit`, or any command that mutates repository state.

**Your job**, given the brief below (code, diffs, an existing ruled-in/ruled-out matrix, and any captured
trace/log/live-query output already gathered for you): produce EXACTLY ONE of two outcomes, as your reply in
this conversation -- there is no file to write it to, your reply IS the deliverable:

1. **A confident root-cause diagnosis + a concrete recommended fix** (or, for a scoping dispatch, a
   confident account of the real mechanism and what a change would actually touch/break). State the mechanism
   precisely (which function, which line, which interaction, why it produces the observed symptom) and
   describe the fix at the level of "change X to do Y because Z" -- prose/pseudocode is fine. If it would help,
   show the actual test code you would want run to confirm it, or propose the literal edit as a diff-shaped
   quote in your reply -- but show it as text for someone else to apply, never attempt to write or run it
   yourself. Only report this outcome if you are genuinely confident, not merely suspicious -- a wrong
   confident diagnosis costs a full wasted implementation round.
2. **A precise instrumentation/tracing request.** If you cannot reach outcome 1 from what you were given,
   specify EXACTLY what would let you: exact file:line locations to add temporary logging, exactly what
   values to print at each, exactly what test/scenario to run to trigger them, exactly what live data (a DB
   query, a log tail, a curl response) you would need fetched for you, and what you expect each candidate
   mechanism would look like in that output. Vague requests ("add more logging around the mutation") are not
   acceptable -- name the specific function, the specific variable, the specific comparison, the specific
   query.

Do not hedge between the two. If you are not confident enough for outcome 1, you must produce outcome 2, not
a weaker version of outcome 1.

**Propose (never write) an entry for `keypatterns.md` when this dispatch earns one.** You cannot write that
file -- the session dispatching you will, based on what you propose here. Decide whether this dispatch
surfaced any of: a RECURRING issue (a bug class you have now seen more than once, even in a different guise),
a durable PATTERN (a requirement shape with a plausible-wrong version and the verified-correct version, the
way this project'"'"'s own `solved-patterns.md` is written), or a KEY ARCHITECTURAL DECISION OR PIVOT (a
load-bearing choice, or a reversal of one, that a future dispatch -- your own future self, or an
implementation agent -- must not blindly re-litigate). If so, include in your reply, verbatim, a block
delimited EXACTLY like this (nothing before the opening marker or after the closing one on those lines):

<<<KEYPATTERNS_ENTRY>>>
### YYYY-MM-DD -- <short title>

**Kind:** recurring issue | pattern | architectural decision/pivot
**What:** <the thing itself, plainly>
**Why it matters:** <what it costs to not know this>
**Evidence:** <this dispatch, or a file:line/commit if there is one>
<<<END_KEYPATTERNS_ENTRY>>>

Do not force this when nothing of this kind was found -- an unnecessary entry dilutes a memory meant to be
selective. Write it for a human reading it cold, at the level of an experienced engineer briefing a new team
member on this project'"'"'s real institutional memory, not as raw investigation notes.

---

'

PROMPT="$ROLE_PREAMBLE$(cat "$PROMPT_FILE")"

PRE_TRACKED_COUNT="$(git ls-files | wc -l)"
PRE_HEAD="$(git rev-parse HEAD)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/.codex-logs"
SESSION_DIR="$REPO_ROOT/.codex-logs/root_cause_sessions"
SESSION_ID=""
SESSION_ID_FILE=""
if [ -n "$SESSION_KEY" ]; then
  mkdir -p "$SESSION_DIR"
  SESSION_ID_FILE="$SESSION_DIR/$SESSION_KEY_SAFE.id"
  if [ -f "$SESSION_ID_FILE" ]; then
    SESSION_ID="$(tr -d '[:space:]' < "$SESSION_ID_FILE")"
  fi
fi

echo "=== Invoking Root Cause Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Brief file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
if [ -z "$SESSION_KEY" ]; then
  echo "Mode: FRESH session (no --session-key given; nothing will be persisted)"
elif [ -n "$SESSION_ID" ]; then
  echo "Mode: resuming session for key '$SESSION_KEY_SAFE' ($SESSION_ID)"
else
  echo "Mode: seeding a new session for key '$SESSION_KEY_SAFE' (none recorded yet at $SESSION_ID_FILE)"
fi
echo "Model: $MODEL"
echo "Reasoning effort: $REASONING_EFFORT"
echo "Sandbox: read-only, no network (confirmed live -- see script header)"
echo "===================================================="

# --- TODO-tracking hooks (optional; see docs/Build Plan V2/Tools/reference-tracker-
# template.md's §8 "Live TODO / Next Steps Queue" -- see call_implementation_agent.sh's
# own header comment for the full rationale, identical behavior here.
TODO_LOG="$REPO_ROOT/.codex-logs/.dispatch_todo_log.log"
echo "DISPATCH_STARTED $(date -u +%Y-%m-%dT%H:%M:%SZ) script=call_root_cause_agent.sh brief=\"$PROMPT_FILE\" tracker=\"${DISPATCH_TRACKER_FILE:-}\" item=\"${DISPATCH_TODO_ITEM:-}\"" >> "$TODO_LOG"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  if [ -f "$REPO_ROOT/$DISPATCH_TRACKER_FILE" ]; then
    if [ -n "${DISPATCH_TODO_ITEM:-}" ] && ! grep -qF "$DISPATCH_TODO_ITEM" "$REPO_ROOT/$DISPATCH_TRACKER_FILE"; then
      echo "WARNING: DISPATCH_TODO_ITEM text not found in $DISPATCH_TRACKER_FILE -- confirm it's already" >&2
      echo "         queued in that tracker's §8 Live TODO / Next Steps Queue (wording may just differ)." >&2
    fi
  else
    echo "WARNING: DISPATCH_TRACKER_FILE '$DISPATCH_TRACKER_FILE' not found relative to repo root." >&2
  fi
else
  echo "NOTE: no DISPATCH_TRACKER_FILE set for this dispatch -- you decide whether" >&2
  echo "      docs/Build Plan V2/TODO.md needs a new entry once this completes." >&2
fi

echo "$$" > .codex-logs/.last_dispatch.pid

CODEX_OUTPUT_CAPTURE="$(mktemp)"
set +e

if [ -z "$SESSION_ID" ]; then
  # Seed run: this is the ONLY invocation where sandbox/profile can be set,
  # since `resume` accepts neither -- get it right here, it holds forever.
  codex exec \
    -p "$PROFILE" \
    --sandbox read-only \
    --json \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
else
  # Resume: no -p/--sandbox accepted here (confirmed live -- see header).
  # Every profile value re-specified as its own -c override.
  codex exec resume "$SESSION_ID" \
    -c model="$MODEL" \
    -c model_reasoning_effort="$REASONING_EFFORT" \
    -c model_verbosity="medium" \
    -c model_context_window=272000 \
    -c service_tier="fast" \
    --json \
    "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
fi
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

if [ -z "$SESSION_ID" ]; then
  NEW_SESSION_ID="$(grep -o '"thread_id":"[^"]*"' "$CODEX_OUTPUT_CAPTURE" | head -1 | sed 's/.*:"//; s/"$//')"
  if [ -z "$SESSION_KEY" ]; then
    # Fresh mode: nothing to persist, by design. Print the id anyway so a
    # one-off that turns out to matter can be adopted into a key by hand.
    echo "Mode was FRESH: session id ${NEW_SESSION_ID:-<none captured>} deliberately NOT persisted."
    echo "  To adopt it as an ongoing thread:"
    echo "    mkdir -p .codex-logs/root_cause_sessions"
    echo "    echo ${NEW_SESSION_ID:-<id>} > .codex-logs/root_cause_sessions/<key>.id"
  elif [ -n "$NEW_SESSION_ID" ]; then
    printf '%s\n' "$NEW_SESSION_ID" > "$SESSION_ID_FILE"
    echo "Persisted session id for key '$SESSION_KEY_SAFE': $NEW_SESSION_ID ($SESSION_ID_FILE)"
  else
    echo "##################################################################"
    echo "# WARNING: no thread_id found in this seed run's output -- the session was NOT persisted. #"
    echo "# The NEXT dispatch will seed again instead of resuming this one. Check $CODEX_OUTPUT_CAPTURE. #"
    echo "##################################################################"
  fi
fi

# Extract the agent's final conversational reply (there is no report file --
# see the NO FILE-BASED REPORT header note) and, if present, the proposed
# keypatterns.md entry delimited by the markers the role preamble specifies.
# This script -- outside the sandbox -- is the only thing that ever writes
# keypatterns.md; the agent only ever proposes an entry as text.
# NOTE: must be a single jq call using slurp mode (`-s`) to pick the LAST
# matching object, not `jq -r ... | tail -1` -- `-r` decodes embedded `\n`
# into real newlines, so a `tail -1` afterward grabs only the last LINE of
# the last reply, not the last reply itself. Found live during smoke-testing
# 2026-09-07: a multi-line reply silently extracted as just its closing
# "<<<END_KEYPATTERNS_ENTRY>>>" line, and the append step correctly saw that
# as empty and skipped -- no corruption, but nothing was captured either.
#
# SECOND bug, found live on the actual seeding dispatch the same day: `-s`
# (slurp) requires the ENTIRE input to parse as a JSON value sequence, and
# codex prints a plain-text "Reading additional input from stdin..." line
# before its own JSON stream even under `--json` -- that one non-JSON line
# makes the WHOLE slurp parse fail, so `jq -rs` silently produced nothing
# (suppressed by `2>/dev/null`) on a real, large reply that genuinely
# proposed 19 keypatterns.md entries. `grep '^{'` first, keeping only lines
# that look like a JSON object, fixes it -- confirmed live by re-extracting
# from that same dispatch's raw output after the fact.
FINAL_REPLY="$(grep '^{' "$CODEX_OUTPUT_CAPTURE" 2>/dev/null | jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message") | .item.text] | last // ""' 2>/dev/null)"
# `sed '/marker/d'` (not `1d;$d`) strips ONLY the marker lines wherever they
# occur, so this correctly handles a reply proposing MULTIPLE entries (each
# in its own <<<KEYPATTERNS_ENTRY>>>...<<<END_...>>> pair) -- `1d;$d` would
# only strip the very first and very last line of the WHOLE concatenated
# range, corrupting every entry but the first and last. The `awk` pass then
# reinserts a blank line before each entry's own `### ` heading, since the
# blank line originally between separate blocks in the reply sits OUTSIDE
# the extracted ranges and would otherwise be lost, running entries together.
KEYPATTERNS_ENTRY="$(printf '%s\n' "$FINAL_REPLY" | sed -n '/<<<KEYPATTERNS_ENTRY>>>/,/<<<END_KEYPATTERNS_ENTRY>>>/p' | sed '/<<<KEYPATTERNS_ENTRY>>>/d; /<<<END_KEYPATTERNS_ENTRY>>>/d' | awk '/^### / && NR>1 {print ""} {print}')"
if [ -n "$(echo "$KEYPATTERNS_ENTRY" | tr -d '[:space:]')" ]; then
  {
    echo ""
    echo "$KEYPATTERNS_ENTRY"
  } >> "$REPO_ROOT/keypatterns.md"
  echo "Appended a new keypatterns.md entry (proposed by the agent, written by this script -- the"
  echo "agent itself has no write access). Review it and commit keypatterns.md yourself:"
  echo "$KEYPATTERNS_ENTRY" | sed 's/^/  /'
fi

rm -f "$CODEX_OUTPUT_CAPTURE"

POST_TRACKED_COUNT="$(git ls-files | wc -l)"
POST_HEAD="$(git rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "##################################################################"
  echo "# VIOLATION: HEAD moved ($PRE_HEAD -> $POST_HEAD). The Root Cause Agent must never commit. #"
  echo "##################################################################"
fi
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ]; then
  echo "##################################################################"
  echo "# WARNING: tracked file count dropped ($PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT). Investigate before trusting anything. #"
  echo "##################################################################"
fi

DIRTY="$(git status --short)"
UNEXPECTED_DIRTY="$(echo "$DIRTY" | grep -v ' keypatterns\.md$' || true)"
if [ -n "$UNEXPECTED_DIRTY" ]; then
  echo "##################################################################"
  echo "# VIOLATION: the working tree changed somewhere the sandbox should have made impossible. #"
  echo "# Investigate before trusting anything -- the read-only sandbox may not have held:        #"
  echo "##################################################################"
  echo "$DIRTY" | sed 's/^/  /'
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DISPATCH_FINISHED status=$STATUS" >> "$TODO_LOG"
echo "##################################################################"
echo "# NEXT STEP: fold this dispatch's outcome into the TODO record. #"
echo "##################################################################"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  echo "Review this agent's diagnosis/reply against your own read, then update"
  echo "'$DISPATCH_TRACKER_FILE''s §8 Live TODO / Next Steps Queue and docs/Build Plan V2/TODO.md's rollup"
  echo "accordingly (typically: resolve the needs-debug-agent row, add a new-ticket row for the fix)."
else
  echo "No DISPATCH_TRACKER_FILE was set -- decide whether docs/Build Plan V2/TODO.md needs a new entry"
  echo "for this dispatch's outcome."
fi

exit "$STATUS"
