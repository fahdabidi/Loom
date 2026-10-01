#!/bin/bash
# data/call_ux_judge_agent.sh
#
# Dispatches the UX Review judge to a Claude Code CLI agent: model `fable`, effort
# `medium` (user-directed 2026-09-14). See MODEL / EFFORT below -- those lines are the
# authority, not this comment.
#
# DRIFT NOTE, 2026-09-14: the three copies disagreed in opposite directions. The VM's
# data/ copy ran `fable` under a header saying Sonnet; this repo copy and its Tools/code
# mirror had a header saying fable over code defaulting to `sonnet`. None passed an
# effort level. All three were replaced with this file -- after editing, cmp the VM copy.
#
# WHY CLAUDE AND NOT CODEX/DEEPSEEK: judging UX means LOOKING at the captured
# screenshots. The DeepSeek gateway is text-only and refuses image content
# outright ("unsupported content type: input_image"), which killed a capture
# run on 2026-08-23 the moment the agent tried to inspect a frame. Claude reads
# images, so the judge can do the one thing a UX judge exists to do.
#
# Not Opus by deliberate choice: this is high-volume, well-specified perceptual
# work over many screenshots, not open-ended design. Opus is reserved for the
# live verification agent, which has to drive a device and reason about failure.
# The judge model itself has moved (Sonnet -> fable); what matters and has not
# changed is that it READS IMAGES and is not the device-driving agent.
#
# Usage:
#   bash data/call_ux_judge_agent.sh <prompt-file> [label]
#
# The judge is REVIEW-ONLY. It reads screenshots and evidence and writes its
# verdict; it must not edit application code to make a verdict pass. That is
# enforced by prompt and checked by the git guard below, not by sandboxing --
# so read its diff before trusting it, exactly as with any other dispatch.
set -euo pipefail

PROMPT_FILE="${1:?usage: call_ux_judge_agent.sh <prompt-file> [label]}"
LABEL="${2:-uxjudge-$(date +%Y%m%d-%H%M%S)}"
MODEL="${CLAUDE_UX_JUDGE_MODEL:-fable}"
EFFORT="${CLAUDE_UX_JUDGE_EFFORT:-medium}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Toolchain env: the Linux VM has ~/.loom-env.sh; Windows (Git Bash) does not,
# so fall back to the repo-local data/loom-env.sh. One script body, either host.
if [ -f "$HOME/.loom-env.sh" ]; then
  . "$HOME/.loom-env.sh"
elif [ -f "$SCRIPT_DIR/loom-env.sh" ]; then
  . "$SCRIPT_DIR/loom-env.sh"
else
  echo "ERROR: no toolchain env found (~/.loom-env.sh or $SCRIPT_DIR/loom-env.sh)" >&2
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# Same stable-prefix assembly as the Codex dispatches: invariant rules first,
# ticket last. Anthropic caches on prefix too, so this is not DeepSeek-specific.
DISPATCH_PREAMBLE_FILE="${CODEX_DISPATCH_PREAMBLE:-$REPO_ROOT/data/dispatch_preamble.md}"
if [ -f "$DISPATCH_PREAMBLE_FILE" ]; then
  PROMPT="$(cat "$DISPATCH_PREAMBLE_FILE")
$(cat "$PROMPT_FILE")"
else
  PROMPT="$(cat "$PROMPT_FILE")"
fi

# A verdict the bar cannot see is a verdict that did not happen.
# `check_b25_status.sh` extracts judged rows with
#   grep -oE '\*\*Workflow:\*\* `[a-z0-9-]+`'
# over `*ux-judge*.md`, so a verdict that names its rows only in a prose heading
# (`## Chess Club -- chess-export-package, owner`) counts as ZERO judged rows.
# That happened on 2026-09-19: nine judged rows were invisible for hours, and the
# tell -- a judge count that did not move after a verdict was committed -- was
# misread as "those rows were already covered".
#
# This requirement is appended to EVERY judge dispatch rather than left to each
# hand-written brief, because a convention that is mandatory but undocumented
# will be missed again. Appended last so it cannot be overridden by the brief,
# and so the cached stable prefix above is unaffected.
PROMPT="$PROMPT

---

# MANDATORY VERDICT FORMAT -- this is how the bar counts your work

Your verdict is parsed, not read. For **every row you judge**, the verdict file must contain a line
of exactly this form, on its own line:

    **Workflow:** \`<workflow-id>\`

Use the workflow id verbatim (for example \`garden-tool-giveaway\`), lowercase, in backticks. One such
line per judged row, in addition to any prose heading you write -- headings are for humans and are
**not** counted.

A row you judged without that line is counted as **not judged at all**, and the pass or fail you
recorded for it is silently discarded. If you judge nine rows and omit the line, the bar moves by
zero and nothing tells you.

Write the verdict to a file whose name contains \`ux-judge\` and ends in \`.md\`, or it will not be
found.

**Immediately after each \`**Workflow:**\` line, on its own line, record that row's outcome in exactly
this shape:**

    **Outcome:** PASS

Use exactly one of **PASS**, **FAIL** or **UNPROVEN**, uppercase, nothing else on the line:

- **PASS** — the frames show this row working. You may still record findings; a pass with findings is
  a PASS.
- **FAIL** — the frames show it not working, or contradicting its product doc.
- **UNPROVEN** — you could not tell from the frames. A cropped, ambiguous or missing frame is
  UNPROVEN, **never** PASS and never FAIL. This is a real outcome, not a cop-out, and choosing it
  honestly is worth more than a confident guess.

**Why this line exists, so you do not treat it as bookkeeping.** Until 2026-09-28 the bar counted a
row as judged if a verdict merely *named* it — so a row judged FAIL counted exactly like a row judged
PASS, and five known failures sat inside the reported figure. Your prose verdict is for humans; this
line is the only part a counter can read. A row without it is not counted as passing.

**And on its own line in the same block, record which ENGINE produced the frames:**

    **Engine:** remote

Read this from the capture run's own manifest -- the harness records the engine it resolved at
runtime -- and copy it verbatim. Do **not** infer it from how the frames look, and do **not** guess.
If the manifest does not say, write:

    **Engine:** unrecorded

**Why, and it decides whether your verdict counts at all.** On 2026-10-01 the user ruled that the UX
judge and the live walkthrough must both execute against the LIVE BACKEND SERVICES, never the
in-memory engine. A screen can render correctly on the in-memory engine and be broken on the real
one -- that has happened here, with a Publish button that is hidden only on the remote path. So a PASS
over in-memory frames is not evidence about the shipped product, and the bar now counts a row as
proven only when its verdict records a live engine. \`unrecorded\` is an honest third answer and is
treated as not-live; it is counted and printed, not discarded. Guessing \`remote\` to make a row count
would put a false row in the only figure that means proven."

LOG_DIR="$REPO_ROOT/.codex-logs/ux-judge/$LABEL"
mkdir -p "$LOG_DIR"
OUTPUT_CAPTURE="$LOG_DIR/output.log"

# Git integrity guard -- identical intent to call_implementation_agent.sh: a
# collapsed tracked-file count or a moved HEAD is a loud failure, because a
# review agent should never do either.
PRE_TRACKED_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l)"
PRE_HEAD="$(cd "$REPO_ROOT" && git rev-parse HEAD)"

echo "=== Invoking UX Review Judge (Claude Code CLI) ==="
echo "Repo:        $REPO_ROOT"
echo "Prompt file: $PROMPT_FILE ($(wc -l < "$PROMPT_FILE") lines)"
echo "Model:       $MODEL"
echo "Effort:      $EFFORT"
echo "Label:       $LABEL"
echo "Log:         $OUTPUT_CAPTURE"
echo "Role:        REVIEW ONLY -- reads screenshots and evidence, writes a verdict"
echo "================================================================"

# Per-label, because concurrent judge runs would otherwise clobber each other's pid
# file and leave whichever finished last claiming to be "the" dispatch.
echo $$ > "$REPO_ROOT/.last_dispatch.pid"
echo $$ > "$REPO_ROOT/.last_dispatch.$LABEL.pid"

set +e
claude -p "$PROMPT" \
  --model "$MODEL" \
  --effort "$EFFORT" \
  --add-dir "$REPO_ROOT" \
  --dangerously-skip-permissions \
  2>&1 | tee "$OUTPUT_CAPTURE"
STATUS="${PIPESTATUS[0]}"
set -e

echo "================================================================"
echo "claude exited with status $STATUS"

POST_TRACKED_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l)"
POST_HEAD="$(cd "$REPO_ROOT" && git rev-parse HEAD)"
if [ "$POST_TRACKED_COUNT" -lt "$PRE_TRACKED_COUNT" ] || [ "$POST_HEAD" != "$PRE_HEAD" ]; then
  echo "!!! GIT INTEGRITY ALERT !!!" >&2
  echo "  tracked files: $PRE_TRACKED_COUNT -> $POST_TRACKED_COUNT" >&2
  echo "  HEAD:          $PRE_HEAD -> $POST_HEAD" >&2
  echo "  A review agent must not delete tracked files or move HEAD." >&2
  exit 1
fi

# Verdict-countability gate. The prompt above REQUIRES a `**Workflow:** `<id>``
# line per judged row; this checks the agent actually wrote one, because the
# failure it guards against is invisible by construction -- the verdict file
# exists, reads correctly to a human, and contributes zero to the bar.
#
# Deliberately three distinct outcomes, not two, so neither direction is a guard
# whose output never changes:
#   - verdict file(s) found, all carry the line   -> silent, nothing to say
#   - verdict file(s) found, one or more lack it  -> LOUD, non-zero exit
#   - no verdict file found at all               -> stated plainly, not failed;
#     a diagnostic or re-judging run may legitimately write nothing, and this
#     script cannot tell that from a verdict written to an unmatched filename.
# NOTE the quote stripping, which this gate silently needed and did not have on
# the first attempt: `git status --porcelain` QUOTES any path containing a space,
# and this repo's evidence lives under `docs/Build Plan V2/...`. So every verdict
# path arrives as `"docs/Build Plan V2/.../x-ux-judge.md"` and a pattern anchored
# on `\.md$` matches nothing -- the gate reported "no verdict file" for a file
# sitting right in front of it, in all three test cases. Caught only by
# deliberately feeding it a bad verdict and watching it stay quiet.
# (Only surrounding quotes are stripped; git also backslash-escapes non-ASCII
# inside those quotes, which would need `-z` to handle properly. No such path
# exists here, and a mangled name fails loudly at the `grep -q` below rather
# than passing, so the residual risk is a false alarm, not a false pass.)
# CONCURRENCY, added 2026-10-01. Several judge runs now run at once to get through
# the corpus faster, and `git status` is REPO-WIDE: without scoping, run A's gate
# inspects run B's verdict -- possibly half-written -- and fails A for B's state.
# That is a false failure caused purely by a sibling, and it would be maddening to
# diagnose because it depends on timing.
#
# So when EXPECTED_VERDICT names this run's own verdict path, the gate checks
# exactly that file and ignores every other. Unset, it falls back to the repo-wide
# scan, which stays correct for a single run.
if [ -n "${EXPECTED_VERDICT:-}" ]; then
  if [ -f "$REPO_ROOT/$EXPECTED_VERDICT" ]; then
    VERDICT_FILES="$EXPECTED_VERDICT"
  else
    VERDICT_FILES=""
    echo "NOTE: EXPECTED_VERDICT was set to '$EXPECTED_VERDICT' and that file does not exist."
    echo "      The agent either wrote it elsewhere or wrote nothing. Treat as NOT countable."
  fi
else
  VERDICT_FILES="$(cd "$REPO_ROOT" && git status --porcelain \
    | sed 's/^...//; s/^"//; s/"$//' | grep -E '(^|/)[^/]*ux-judge[^/]*\.md$' || true)"
fi
if [ -z "$VERDICT_FILES" ]; then
  echo "NOTE: no new or modified *ux-judge*.md file in the working tree."
  echo "      If this run was meant to produce a verdict, it is not where the bar looks."
else
  VERDICT_UNCOUNTABLE=""
  while IFS= read -r vf; do
    [ -n "$vf" ] || continue
    if ! grep -qE '^\*\*Workflow:\*\* `[a-z0-9-]+`' "$REPO_ROOT/$vf" 2>/dev/null; then
      VERDICT_UNCOUNTABLE="$VERDICT_UNCOUNTABLE $vf"
    fi
  done <<< "$VERDICT_FILES"
  if [ -n "$VERDICT_UNCOUNTABLE" ]; then
    echo "!!! VERDICT NOT COUNTABLE !!!" >&2
    echo "  These verdict files carry no '**Workflow:** \`<id>\`' line, so" >&2
    echo "  check_b25_status.sh will count ZERO judged rows from them:" >&2
    for vf in $VERDICT_UNCOUNTABLE; do echo "    $vf" >&2; done
    echo "  Add one such line per judged row before committing. The verdict is" >&2
    echo "  not wrong -- it is invisible, which is worse, because nothing else" >&2
    echo "  will report it." >&2
    exit 1
  fi
  echo "Verdict countability: OK -- every *ux-judge*.md carries a **Workflow:** line."
fi

DIRTY="$(cd "$REPO_ROOT" && git status --porcelain)"
if [ -n "$DIRTY" ]; then
  echo "WARNING: working tree left dirty after this run (visibility only):"
  echo "$DIRTY"
else
  echo "Working tree clean."
fi
exit "$STATUS"
