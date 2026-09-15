#!/usr/bin/env bash
# data/call_root_cause_agent.sh
#
# Root Cause Agent dispatcher -- Claude Code CLI, model `fable`, effort `medium`.
#
# Switched 2026-09-14 (user-directed) from `codex exec -p gpt6_astra_high` after the
# OpenAI/Codex account hit its usage limit ("try again at Sep 19th"). The Codex-era
# version, with its long history of sandbox/resume findings, is in git history at
# docs/Build Plan V2/Tools/code/call_root_cause_agent.sh before this change.
#
# USAGE
#   bash data/call_root_cause_agent.sh <brief-file>                        # fresh session
#   bash data/call_root_cause_agent.sh <brief-file> --session-key <key>    # scoped session
#
# The first argument is a FILE PATH, not the brief text. Passing "$(cat brief)" fails
# with "brief file not found" (it happened 2026-09-14).
#
# SESSION SCOPING (unchanged semantics): no key -> fresh session, nothing persisted;
# a key -> resume that key's session if one exists, else seed and persist it.
# Claude session ids live in .codex-logs/root_cause_sessions/<key>.claude.id. The old
# <key>.id files hold CODEX thread ids, which `claude --resume` cannot open, so they
# are deliberately ignored rather than migrated.
#
# READ-ONLY -- HOW IT IS ENFORCED, AND HOW STRONGLY. Be precise about this, because the
# Codex version had an OS sandbox and this one does not:
#   * Tools are an explicit allowlist (READ_ONLY_TOOLS below): Read, Grep, Glob, and a
#     short list of non-mutating Bash command prefixes. `claude -p` never prompts, so
#     any tool call outside the allowlist is DENIED, not asked about.
#   * Edit/Write/NotebookEdit/WebFetch/WebSearch are additionally disallowed.
#   * Deliberately NOT allowed because they can write: `sed` without -n (sed -i),
#     `find` (-delete/-exec), `awk` (print > file), `tee`, `curl`, and `git`
#     subcommands other than the read-only ones listed.
#   * Verified live 2026-09-14, by checking the files did not exist afterwards (not by the
#     agent's own report): `echo > file`, `tee`, `touch` to /tmp; `cat README.md > /tmp/x`
#     and `curl` through the script itself; and redirects INTO the repo via allowed
#     commands (`cat README.md > ~/Loom/x`, `git grep ... > ~/Loom/y`). All denied. The
#     denial text mentions "allowed working directories: /home/fahd/Loom", which reads as
#     if in-repo writes were permitted -- they were not, but that is why it was tested.
#   * This is a permission layer, not a kernel sandbox. The post-run audit below (HEAD
#     unchanged, tree clean apart from keypatterns.md) is the backstop -- read it.
#
# OUTPUT
#   Streams `--output-format stream-json` so the log GROWS during the run (unlike the
#   buffered UX-judge / live-verification dispatchers, where 0 bytes is normal). A log
#   that stops growing early is still a death signal here.
#   Completion line: "claude exited with status N". The reply is printed between
#   "=== AGENT REPLY ===" and "=== END AGENT REPLY ===".
#
# KEYPATTERNS.MD: the agent proposes entries between <<<KEYPATTERNS_ENTRY>>> markers in
# its reply; THIS SCRIPT appends them. Review and commit keypatterns.md yourself.
#
# Overrides: CLAUDE_ROOT_CAUSE_MODEL (default fable), CLAUDE_ROOT_CAUSE_EFFORT (default medium).

set -euo pipefail

PROMPT_FILE="${1:?usage: call_root_cause_agent.sh <brief-file> [--session-key <key>]}"
shift || true

SESSION_KEY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --session-key) SESSION_KEY="${2:?--session-key needs a value}"; shift 2 ;;
    --session-key=*) SESSION_KEY="${1#--session-key=}"; shift ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      echo "usage: call_root_cause_agent.sh <brief-file> [--session-key <key>]" >&2
      exit 2 ;;
  esac
done

if [ -n "$SESSION_KEY" ]; then
  SESSION_KEY_SAFE="$(printf '%s' "$SESSION_KEY" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-' | sed 's/^-*//; s/-*$//')"
  if [ -z "$SESSION_KEY_SAFE" ]; then
    echo "ERROR: --session-key '$SESSION_KEY' has no usable characters" >&2
    exit 2
  fi
fi

MODEL="${CLAUDE_ROOT_CAUSE_MODEL:-fable}"
EFFORT="${CLAUDE_ROOT_CAUSE_EFFORT:-medium}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: brief file not found: $PROMPT_FILE" >&2
  echo "       (the argument is a path to the brief, not the brief's text)" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Non-interactive shells (ssh loom-vm 'cmd') skip ~/.bashrc; never substitute bash -l.
. "$HOME/.loom-env.sh"

command -v claude >/dev/null 2>&1 || { echo "ERROR: claude CLI not on PATH" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq not on PATH (needed to extract the reply)" >&2; exit 1; }

READ_ONLY_TOOLS=(
  "Read" "Grep" "Glob"
  "Bash(cat:*)" "Bash(ls:*)" "Bash(head:*)" "Bash(tail:*)" "Bash(wc:*)"
  "Bash(grep:*)" "Bash(rg:*)" "Bash(sed -n:*)" "Bash(jq:*)"
  "Bash(git log:*)" "Bash(git show:*)" "Bash(git diff:*)" "Bash(git blame:*)"
  "Bash(git status:*)" "Bash(git rev-parse:*)" "Bash(git ls-files:*)" "Bash(git grep:*)"
)
DENIED_TOOLS=("Edit" "Write" "NotebookEdit" "WebFetch" "WebSearch")

read -r -d '' ROLE_PREAMBLE <<'PREAMBLE' || true
# ROLE: Root Cause Agent -- read this before anything else

You are the Root Cause Agent for this repository -- either scoping a non-trivial change before an
implementation ticket is written, or investigating a bug that has resisted the verification agent's own
hypothesis-and-test budget. You are NOT an implementation agent. When this dispatch resumes an earlier
session, treat earlier turns as real prior investigation, not something to re-derive.

**You have READ-ONLY access, enforced by tool permissions.** Reads are safe by construction: use Read, Grep,
Glob, and these shell commands freely -- cat, ls, head, tail, wc, grep, rg, sed -n, jq, git log, git show,
git diff, git blame, git status, git rev-parse, git ls-files, git grep. Anything else (writing, editing,
network, other commands) will be denied without a prompt, so do not spend turns on it.

**You must NEVER:**
- Attempt to edit, create, or delete any file.
- Attempt to fetch live evidence (DB queries, curl, kubectl, anything network-dependent). If you need live
  evidence that was not included in the brief below, say so explicitly and name exactly what you need
  (outcome 2) -- do not guess in its place.
- Run any command that mutates repository state.

**Your job**, given the brief below, is to produce EXACTLY ONE of two outcomes, as your reply -- there is no
file to write it to, your reply IS the deliverable:

1. **A confident root-cause diagnosis + a concrete recommended fix** (or, for a scoping dispatch, a
   confident account of the real mechanism and what a change would actually touch/break). State the
   mechanism precisely (which function, which line, which interaction, why it produces the observed
   symptom) and describe the fix as "change X to do Y because Z". Show test code or a diff-shaped edit as
   text for someone else to apply, never attempt it yourself. Only report this outcome if you are genuinely
   confident -- a wrong confident diagnosis costs a full wasted implementation round.
2. **A precise instrumentation/tracing request.** If you cannot reach outcome 1, specify EXACTLY what would
   let you: file:line locations for temporary logging, the values to print, the scenario to run, the live
   data to fetch for you, and what each candidate mechanism would look like in that output. Vague requests
   are not acceptable.

Do not hedge between the two. If you are not confident enough for outcome 1, produce outcome 2.

If the brief states a premise, attack it FIRST. A premise correction is worth more than a fix for the wrong
problem.

**Propose (never write) an entry for `keypatterns.md` when this dispatch earns one** -- a RECURRING issue, a
durable PATTERN, or a KEY ARCHITECTURAL DECISION OR PIVOT. If so, include in your reply, verbatim:

<<<KEYPATTERNS_ENTRY>>>
### YYYY-MM-DD -- <short title>

**Kind:** recurring issue | pattern | architectural decision/pivot
**What:** <the thing itself, plainly>
**Why it matters:** <what it costs to not know this>
**Evidence:** <this dispatch, or a file:line/commit if there is one>
<<<END_KEYPATTERNS_ENTRY>>>

Do not force this when nothing of this kind was found.

---

PREAMBLE

PROMPT="$ROLE_PREAMBLE
$(cat "$PROMPT_FILE")"

cd "$REPO_ROOT"
PRE_TRACKED_COUNT="$(git ls-files | wc -l)"
PRE_HEAD="$(git rev-parse HEAD)"

mkdir -p "$REPO_ROOT/.codex-logs"
SESSION_DIR="$REPO_ROOT/.codex-logs/root_cause_sessions"
SESSION_ID=""
SESSION_ID_FILE=""
if [ -n "$SESSION_KEY" ]; then
  mkdir -p "$SESSION_DIR"
  SESSION_ID_FILE="$SESSION_DIR/$SESSION_KEY_SAFE.claude.id"
  if [ -f "$SESSION_ID_FILE" ]; then
    SESSION_ID="$(tr -d '[:space:]' < "$SESSION_ID_FILE")"
  fi
fi

echo "=== Invoking Root Cause Agent (claude -p) ==="
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
echo "Effort: $EFFORT"
echo "Access: read-only tool allowlist (permission layer, not a kernel sandbox -- see header)"
echo "===================================================="

TODO_LOG="$REPO_ROOT/.codex-logs/.dispatch_todo_log.log"
echo "DISPATCH_STARTED $(date -u +%Y-%m-%dT%H:%M:%SZ) script=call_root_cause_agent.sh brief=\"$PROMPT_FILE\" tracker=\"${DISPATCH_TRACKER_FILE:-}\" item=\"${DISPATCH_TODO_ITEM:-}\"" >> "$TODO_LOG"
if [ -n "${DISPATCH_TRACKER_FILE:-}" ]; then
  if [ -f "$REPO_ROOT/$DISPATCH_TRACKER_FILE" ]; then
    if [ -n "${DISPATCH_TODO_ITEM:-}" ] && ! grep -qF "$DISPATCH_TODO_ITEM" "$REPO_ROOT/$DISPATCH_TRACKER_FILE"; then
      echo "WARNING: DISPATCH_TODO_ITEM text not found in $DISPATCH_TRACKER_FILE." >&2
    fi
  else
    echo "WARNING: DISPATCH_TRACKER_FILE '$DISPATCH_TRACKER_FILE' not found relative to repo root." >&2
  fi
else
  echo "NOTE: no DISPATCH_TRACKER_FILE set for this dispatch -- you decide whether" >&2
  echo "      docs/Build Plan V2/TODO.md needs a new entry once this completes." >&2
fi

echo "$$" > .codex-logs/.last_dispatch.pid

CAPTURE="$(mktemp)"
CLAUDE_ARGS=(
  -p "$PROMPT"
  --model "$MODEL"
  --effort "$EFFORT"
  --output-format stream-json
  --verbose
  --allowedTools "${READ_ONLY_TOOLS[@]}"
  --disallowedTools "${DENIED_TOOLS[@]}"
)
if [ -n "$SESSION_ID" ]; then
  CLAUDE_ARGS+=(--resume "$SESSION_ID")
elif [ -z "$SESSION_KEY" ]; then
  CLAUDE_ARGS+=(--no-session-persistence)
fi

set +e
claude "${CLAUDE_ARGS[@]}" < /dev/null 2>&1 | tee "$CAPTURE"
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "claude exited with status $STATUS"

# Only lines that look like JSON objects -- anything else would break jq's slurp.
JSON_LINES="$(grep '^{' "$CAPTURE" 2>/dev/null || true)"
FINAL_REPLY="$(printf '%s\n' "$JSON_LINES" | jq -rs '[.[] | select(.type=="result") | .result // ""] | last // ""' 2>/dev/null || true)"
# `tostring` matters: `false // "unknown"` yields "unknown", because jq's `//` treats false as empty.
IS_ERROR="$(printf '%s\n' "$JSON_LINES" | jq -rs '[.[] | select(.type=="result") | .is_error | tostring] | last // "unknown"' 2>/dev/null || echo unknown)"
DENIALS="$(printf '%s\n' "$JSON_LINES" | jq -rs '[.[] | select(.type=="result") | (.permission_denials // []) | length] | last // 0' 2>/dev/null || echo 0)"
echo "result.is_error=$IS_ERROR  permission_denials=$DENIALS"
if [ -z "$(printf '%s' "$FINAL_REPLY" | tr -d '[:space:]')" ]; then
  echo "##################################################################"
  echo "# WARNING: no final reply extracted. Treat this dispatch as FAILED, not as an empty answer. #"
  echo "##################################################################"
fi

if [ -n "$SESSION_KEY" ] && [ -z "$SESSION_ID" ]; then
  NEW_SESSION_ID="$(printf '%s\n' "$JSON_LINES" | jq -rs '[.[] | .session_id // empty] | first // ""' 2>/dev/null || true)"
  if [ -n "$NEW_SESSION_ID" ]; then
    printf '%s\n' "$NEW_SESSION_ID" > "$SESSION_ID_FILE"
    echo "Persisted session id for key '$SESSION_KEY_SAFE': $NEW_SESSION_ID ($SESSION_ID_FILE)"
  else
    echo "WARNING: no session_id captured -- the next dispatch on this key will seed again."
  fi
fi

KEYPATTERNS_ENTRY="$(printf '%s\n' "$FINAL_REPLY" | sed -n '/<<<KEYPATTERNS_ENTRY>>>/,/<<<END_KEYPATTERNS_ENTRY>>>/p' | sed '/<<<KEYPATTERNS_ENTRY>>>/d; /<<<END_KEYPATTERNS_ENTRY>>>/d' | awk '/^### / && NR>1 {print ""} {print}')"
if [ -n "$(echo "$KEYPATTERNS_ENTRY" | tr -d '[:space:]')" ]; then
  { echo ""; echo "$KEYPATTERNS_ENTRY"; } >> "$REPO_ROOT/keypatterns.md"
  echo "Appended a keypatterns.md entry (proposed by the agent, written by this script). Review and commit:"
  echo "$KEYPATTERNS_ENTRY" | sed 's/^/  /'
fi

echo "=== AGENT REPLY ==="
printf '%s\n' "$FINAL_REPLY"
echo "=== END AGENT REPLY ==="

rm -f "$CAPTURE"

POST_TRACKED_COUNT="$(git ls-files | wc -l)"
POST_HEAD="$(git rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "# VIOLATION: HEAD moved ($PRE_HEAD -> $POST_HEAD). The Root Cause Agent must never commit."
fi
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ]; then
  echo "# WARNING: tracked file count dropped ($PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT)."
fi
DIRTY="$(git status --short)"
UNEXPECTED_DIRTY="$(echo "$DIRTY" | grep -v ' keypatterns\.md$' | grep -v '\.codex-logs/' || true)"
if [ -n "$(echo "$UNEXPECTED_DIRTY" | tr -d '[:space:]')" ]; then
  echo "# VIOLATION: the working tree changed; the read-only allowlist may not have held:"
  echo "$UNEXPECTED_DIRTY" | sed 's/^/  /'
fi

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DISPATCH_FINISHED status=$STATUS" >> "$TODO_LOG"
echo "# NEXT STEP: fold this dispatch's outcome into the TODO record."
exit "$STATUS"
