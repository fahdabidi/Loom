#!/bin/bash
# data/call_patterns_agent.sh -- mine the project's own history for durable patterns.
#
# ROLE. This agent reads git history and the trackers and proposes entries for
# keypatterns.md. It is a LIBRARIAN, not an investigator: it does not debug,
# does not scope changes, and does not answer questions about current state.
# Run it manually, occasionally -- after a milestone, or when a stretch of work
# has produced lessons nobody has folded in yet. It is deliberately not wired
# into any loop.
#
# WHY IT EXISTS. keypatterns.md was previously fed only as a side effect of
# Root Cause Agent dispatches -- one entry at a time, only about whatever was
# broken that day, and only when someone happened to dispatch it. Patterns that
# live in the SHAPE of the history (the same mistake in three commits six weeks
# apart, a decision reversed twice, a guard that keeps lapsing) are invisible
# to that. This agent looks at the record instead of at the bug.
#
# SESSION. Always a FRESH session, deliberately. Each sweep should re-read the
# record with no memory of what it concluded last time -- a resumed session
# would anchor on its own prior entries and stop noticing anything new. That is
# the opposite of the Root Cause Agent's task-scoped sessions, and for a
# reason: that agent benefits from continuity within one investigation, this
# one benefits from a cold read of the whole corpus.
#
# WRITE MODEL, identical to the Root Cause Agent and for the same reason. The
# agent runs --sandbox read-only with no network and CANNOT write anything.
# It proposes entries as delimited text; THIS SCRIPT appends them to
# keypatterns.md after the dispatch exits. So a prompt-injection or a confused
# agent cannot edit the repo, and every append is auditable in one place. The
# script fails loudly if the tree changed anywhere except keypatterns.md.
#
# DEDUPLICATION is the hard part and is handled in the prompt, not the code:
# the agent must read keypatterns.md FIRST and justify, per entry, why it is
# not already covered. A sweep that proposes nothing is a correct outcome --
# do not treat an empty run as a failure.
#
# Usage:
#   bash data/call_patterns_agent.sh [--since <rev-or-date>] [extra-file ...]
#
#   --since  how far back to read history; anything git log accepts
#            (a date like 2026-08-01, or a range like v0.3.0..HEAD).
#            Default: 3 months ago.
#   extra    additional repo-relative files to put in front of the agent.
#
# Sources note: there is no file named change-implement-tracker.md in this repo
# (checked 2026-09-08). The defaults below are the four real trackers plus the
# reference material a proposed pattern has to be checked against. Pass extra
# paths if that set is ever wrong.
set -euo pipefail

SINCE="3 months ago"
EXTRA_FILES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:?--since needs a value}"; shift 2 ;;
    --since=*) SINCE="${1#--since=}"; shift ;;
    -h|--help) sed -n '1,48p' "$0"; exit 0 ;;
    -*) echo "ERROR: unknown flag '$1'" >&2; exit 2 ;;
    *) EXTRA_FILES+=("$1"); shift ;;
  esac
done

MODEL="${CODEX_PATTERNS_MODEL:-gpt-6-astra}"
REASONING_EFFORT="${CODEX_PATTERNS_REASONING_EFFORT:-high}"
PROFILE="${CODEX_PATTERNS_PROFILE:-gpt6_astra_high}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$HOME/.loom-env.sh" ]; then
  . "$HOME/.loom-env.sh"
elif [ -f "$SCRIPT_DIR/loom-env.sh" ]; then
  . "$SCRIPT_DIR/loom-env.sh"
fi

cd "$REPO_ROOT"
command -v codex >/dev/null || { echo "ERROR: codex not on PATH" >&2; exit 2; }
[ -f "$REPO_ROOT/keypatterns.md" ] || { echo "ERROR: keypatterns.md not found at repo root" >&2; exit 2; }

PRE_TRACKED_COUNT="$(git ls-files | wc -l)"
PRE_HEAD="$(git rev-parse HEAD)"
# Capture the tree's dirt BEFORE the run. The audit below compares against this,
# not against a clean tree: .last_dispatch.pid and similar are routinely dirty
# from earlier dispatches, and flagging them as a sandbox VIOLATION trains the
# reader to ignore the banner -- which is worse than not having it. Found on the
# first real run, 2026-09-08.
PRE_DIRTY="$(git status --short | sort)"

# --- Gather the history the agent cannot gather for itself -------------------
# The sandbox is read-only with no network. Pre-gathering makes the input
# deterministic and reviewable, and means a change in git output format cannot
# silently change what the agent saw.
INPUT_DIR="$REPO_ROOT/.codex-logs/patterns_input"
mkdir -p "$INPUT_DIR"
HISTORY_FILE="$INPUT_DIR/git-history.txt"
STAT_FILE="$INPUT_DIR/git-churn.txt"

git log --since="$SINCE" --date=short --pretty=format:'%h %ad %an%n%s%n%b%n---' > "$HISTORY_FILE"
# Churn: which files change most, and therefore which co-change. Repeated
# co-change is one of the few pattern signals visible in structure, not prose.
git log --since="$SINCE" --name-only --pretty=format: | sed '/^$/d' | sort | uniq -c | sort -rn | head -60 > "$STAT_FILE"

HISTORY_COMMITS="$(grep -c '^---$' "$HISTORY_FILE" || true)"

DEFAULT_SOURCES=(
  "keypatterns.md"
  "CLAUDE.md"
  "docs/Build Plan V2/TODO.md"
  "docs/Build Plan V2/Access Control and Workflow Service Tracker.md"
  "docs/Build Plan V2/Community JSON Migration Tracker.md"
  "docs/Build Plan V2/Build Tracker.md"
  "docs/Build Plan V2/TabId-Archetype Gap Closure.md"
  "docs/references/reference/solved-patterns.md"
)

SOURCE_LIST=""
for f in "${DEFAULT_SOURCES[@]}" ${EXTRA_FILES[@]+"${EXTRA_FILES[@]}"}; do
  if [ -f "$REPO_ROOT/$f" ]; then
    SOURCE_LIST="$SOURCE_LIST
- $f"
  else
    echo "NOTE: source not found, skipping: $f" >&2
  fi
done

read -r -d '' PROMPT_BODY <<'PROMPTEOF' || true
You are the Patterns Agent for the Loom project. You are a librarian of this
project's own history, not a debugger. You have READ-ONLY access and no network.
You cannot WRITE any file and you have no network. You CAN and MUST run
read-only shell commands to read files -- `cat`, `sed -n`, `grep`, `head`,
`wc` and the like are all available and expected. The sandbox blocks writes and
network, not command execution. Nothing in these instructions forbids reading;
if you find yourself concluding that you cannot read the inputs, that conclusion
is wrong -- read them with `cat`.

You propose entry text and a script appends it for you; that is the only reason
you do not write the file yourself.

# Your job

Find DURABLE patterns in this project's record and propose them as keypatterns.md
entries. A pattern is worth proposing only if it will still be true and still be
useful months from now, and if someone who had not lived through the history
would act differently for knowing it.

Look especially for what is visible in the SHAPE of the record rather than in any
single document:
- the same mistake recurring in commits weeks or months apart
- a decision made, reversed, and remade -- and what finally settled it
- a guard, check or convention that keeps lapsing (why does it not hold?)
- two areas that always change together, and what that implies about coupling
- a class of defect that only ever gets caught by one kind of check
- language in trackers that repeatedly turns out to be wrong in the same way

# What is NOT a pattern

- a one-off bug and its fix
- a restatement of something already in keypatterns.md or CLAUDE.md
- a summary of what happened (the git log already says that)
- advice generically true of software rather than specific to this codebase

# Deduplication is mandatory

Read keypatterns.md FIRST, in full. For EVERY entry you propose, state which
existing entries you checked it against and why it is not already covered. If a
pattern IS already covered but the existing entry is now wrong or incomplete,
propose the correction and quote the text you are correcting -- do not add a
near-duplicate.

Proposing nothing is a correct outcome. If the record contains no durable new
pattern, say so plainly. Do not manufacture entries to look productive: a thin
keypatterns.md that is all true beats a padded one.

# Evidence standard

Every entry must cite specific evidence -- commit hashes, file:line references,
tracker row text. An entry that cannot cite where it came from is speculation and
must not be proposed. Where you are inferring rather than observing, say which.

# Output format

First, a short prose report: what you read, what you looked for, what you found,
and what you considered and REJECTED as not-a-pattern. That last part matters --
it tells the reader what was already weighed.

Then one block per proposed entry, delimited exactly:

<<<KEYPATTERNS_ENTRY>>>
### YYYY-MM-DD -- short imperative title

**Kind:** pattern | recurring issue | architectural decision

**What:** the pattern itself, stated so it can be acted on

**Why it matters:** the cost of not knowing it, with the real instance

**Evidence:** commits, file:line, tracker rows; mark inferred vs observed

**Not already covered because:** which existing entries you checked
<<<END_KEYPATTERNS_ENTRY>>>

The script appends every block it finds, so do NOT include a worked example
block anywhere in your prose.

# Mandatory completion marker

After your prose report and any entry blocks, emit this line EXACTLY, on its own
line, listing every file you actually read:

<<<SWEEP_READ: file1, file2, ...>>>

Emit it whether or not you propose entries. If you could not read the inputs, do
NOT emit it -- say what blocked you instead. The script treats a missing marker
as a FAILED sweep rather than an empty one, because "found nothing" and "read
nothing" must never look the same to whoever reads the output.
PROMPTEOF

PROMPT="$PROMPT_BODY

# Input you have been given

Git history since '$SINCE' ($HISTORY_COMMITS commits), pre-gathered because you
cannot run commands:
- .codex-logs/patterns_input/git-history.txt
- .codex-logs/patterns_input/git-churn.txt   (files by change frequency)

Documents to read (keypatterns.md FIRST):$SOURCE_LIST"

echo "=== Invoking Patterns Agent (codex exec) ==="
echo "Repo: $REPO_ROOT"
echo "Mode: FRESH session, always (a cold read each sweep -- see header)"
echo "History window: $SINCE ($HISTORY_COMMITS commits)"
echo "Sources:$SOURCE_LIST"
echo "Model: $MODEL / effort $REASONING_EFFORT"
echo "Sandbox: read-only, no network. The agent cannot write; this script appends."
echo "===================================================="

CODEX_OUTPUT_CAPTURE="$(mktemp)"
set +e
# Model and effort are pinned BOTH ways on purpose: -p loads the profile, and
# the -c overrides restate model/effort so this agent still runs on GPT-6 Astra
# at high reasoning even if the profile file is missing or edited. A patterns
# sweep silently downgraded to a weaker model would produce plausible, shallow
# entries that are expensive to detect later -- the failure mode this whole
# script exists to avoid.
codex exec \
  -p "$PROFILE" \
  -c model="$MODEL" \
  -c model_reasoning_effort="$REASONING_EFFORT" \
  -c model_verbosity="medium" \
  -c model_context_window=272000 \
  -c service_tier="fast" \
  --sandbox read-only \
  --json \
  "$PROMPT" 2>&1 | tee "$CODEX_OUTPUT_CAPTURE"
STATUS="${PIPESTATUS[0]}"
set -e

echo "===================================================="
echo "codex exec exited with status $STATUS"

# Extraction: identical to call_root_cause_agent.sh, including both bugs already
# found and fixed there -- grep '^{' first (codex prints non-JSON lines even
# under --json, and one of them makes jq -s fail silently), and sed on the
# marker lines rather than 1d;$d so MULTIPLE entries survive intact.
FINAL_REPLY="$(grep '^{' "$CODEX_OUTPUT_CAPTURE" 2>/dev/null | jq -rs '[.[] | select(.type=="item.completed" and .item.type=="agent_message") | .item.text] | last // ""' 2>/dev/null)"
SWEEP_READ="$(printf '%s\n' "$FINAL_REPLY" | sed -n 's/.*<<<SWEEP_READ:\(.*\)>>>.*/\1/p' | head -1)"
ENTRY_COUNT="$(printf '%s\n' "$FINAL_REPLY" | grep -c '<<<KEYPATTERNS_ENTRY>>>' || true)"
ENTRIES="$(printf '%s\n' "$FINAL_REPLY" | sed -n '/<<<KEYPATTERNS_ENTRY>>>/,/<<<END_KEYPATTERNS_ENTRY>>>/p' | sed '/<<<KEYPATTERNS_ENTRY>>>/d; /<<<END_KEYPATTERNS_ENTRY>>>/d' | awk '/^### / && NR>1 {print ""} {print}')"

if [ -n "$(echo "$ENTRIES" | tr -d '[:space:]')" ]; then
  {
    echo ""
    echo "$ENTRIES"
  } >> "$REPO_ROOT/keypatterns.md"
  echo "Appended $ENTRY_COUNT proposed entry/entries to keypatterns.md."
  echo "REVIEW BEFORE COMMITTING -- these are proposals, not verified facts:"
  echo "$ENTRIES" | sed 's/^/  /'
else
  # "Found nothing" and "read nothing" must not look the same. The agent emits
  # <<<SWEEP_READ: ...>>> only after actually reading the inputs; without it,
  # an empty result is a FAILED sweep, not a clean one. This exists because the
  # first real run (2026-09-08) read nothing at all -- it concluded the prompt
  # forbade running commands -- and the script reported that as a legitimate
  # empty outcome. A reassuring message over a silent failure is worse than no
  # message at all.
  if [ -n "$SWEEP_READ" ]; then
    echo "No entries proposed, and the sweep DID read its inputs:"
    echo "  $SWEEP_READ"
    echo "That is a legitimate outcome, not a failure -- it means this sweep found"
    echo "nothing durable that keypatterns.md does not already cover."
  else
    echo "##################################################################"
    echo "# FAILED SWEEP: no entries AND no <<<SWEEP_READ:...>>> marker.    #"
    echo "# The agent did not confirm it read the inputs, so this is NOT an #"
    echo "# empty result -- treat it as a failed run and read the log.      #"
    echo "##################################################################"
    echo "Agent's final reply (first 40 lines):"
    printf '%s\n' "$FINAL_REPLY" | head -40 | sed 's/^/  /'
  fi
fi

rm -f "$CODEX_OUTPUT_CAPTURE"

POST_TRACKED_COUNT="$(git ls-files | wc -l)"
POST_HEAD="$(git rev-parse HEAD)"
if [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "##################################################################"
  echo "# VIOLATION: HEAD moved ($PRE_HEAD -> $POST_HEAD). This agent must never commit. #"
  echo "##################################################################"
fi
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ]; then
  echo "##################################################################"
  echo "# WARNING: tracked file count dropped ($PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT). Investigate. #"
  echo "##################################################################"
fi
DIRTY="$(git status --short)"
UNEXPECTED_DIRTY="$(comm -13 <(printf '%s\n' "$PRE_DIRTY") <(printf '%s\n' "$DIRTY" | sort) | grep -v ' keypatterns\.md$' || true)"
if [ -n "$UNEXPECTED_DIRTY" ]; then
  echo "##################################################################"
  echo "# VIOLATION: the tree changed where a read-only sandbox should have made it impossible. #"
  echo "##################################################################"
  echo "$DIRTY" | sed 's/^/  /'
fi

echo "##################################################################"
echo "# NEXT: review each appended entry, delete any that do not earn   #"
echo "# their place, then commit keypatterns.md yourself.               #"
echo "##################################################################"
