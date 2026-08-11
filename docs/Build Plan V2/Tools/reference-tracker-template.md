# Reference tracker template — sequencing a batch of tickets

A tracker doc is the one artifact that survives across every dispatch round for a multi-ticket effort — it's
what you re-read at the start of a new session to reconstruct state, and what a Regression Impact Judge or
Skill Retrospective dispatch cites for "what's already known." This project's own
`Community JSON Migration Tracker.md` is the real, load-bearing example this template is extracted from.

## Section structure

```markdown
# <Effort name> Tracker

## 0. What this tracker is

One paragraph: the goal, the rough scope (how many tickets/artifacts), and a pointer to the source-of-truth
docs this effort is implementing against (a product spec, a schema doc, a design doc).

### 0.1 Cross-cutting findings

Anything discovered mid-effort that applies to *every* remaining ticket, not just one — a closed enum you
didn't know was closed, a naming convention that traps naive implementations, a structural constraint. Add
to this section as you find things; it's the single highest-leverage place to write down a finding, since
every ticket you dispatch after it can cite it directly instead of re-discovering it.

## 1. Locked spec additions

Any new vocabulary/schema/contract additions this effort has already decided and versioned, with a pointer
to where the authoritative version lives (a `doc_version` bump in a reference doc, a schema file). "Locked"
means dispatched agents may implement against it without re-litigating it — call this out explicitly so a
ticket doesn't waste budget second-guessing an already-decided shape.

## 2. Approved shared-code tickets — dispatch first

Tickets that touch code/infrastructure *reused* across multiple artifacts in this effort, listed and
dispatched before the artifact-specific work that depends on them. For each:

### Ticket <ID> — <one-line title> (status, date)

- What it changes, one paragraph.
- What it unblocks (name the specific downstream artifacts/tickets).
- Link to the actual ticket file once authored: `data/v3_ticket_<slug>.md`.
- Once shipped: a one-paragraph summary of what the independent verification found (not just "done") —
  this is what a later Regression Impact Judge dispatch reads as its starting context.

**Standing rule, restate here every time this section grows:** any ticket in this section that changes code
consumed by more than one artifact requires a **Regression Impact Judge** dispatch
(`regression-impact-judge-tool.md`) against every real consumer before it's marked done — "the ticket's own
tests pass" is not sufficient evidence for shared code.

## 3. Artifact-specific tasks

The per-artifact work list (e.g., per-community, per-page, per-feature) — usually a locked, expand-only list
("never remove, only append/mark-done") so the tracker stays an honest running record rather than getting
retroactively cleaned up to look tidier than the actual process was.

## 4. Per-artifact status

A table or per-item section: artifact name → status (not started / in progress / done, date) → output
location → one-line judge summary. This is the section you scan first to answer "what's left."

## 5. Dispatch mechanics — emulate exactly, do not improvise a shortcut

Paste the exact numbered dispatch recipe from `README.md`'s "core dispatch pipeline" section, adapted with
your own ticket-file naming convention. Restate the WSL concurrency budget (or your own environment's
equivalent constraint) here too — a tracker that's read stand-alone at the start of a new session should not
require also having `README.md` open to know how to actually run a ticket.

## 6. Mandatory completion gate(s)

Any gate that must pass before the *whole effort* (not just one ticket) is considered done — e.g. a live
walkthrough, a full-suite judge pass, a stakeholder sign-off. State it explicitly as a gate, not an
aspiration, so it doesn't quietly get skipped once the ticket list empties out.

## 7. Execution order

The actual sequence you intend to dispatch in, and why (dependency order, risk order, or just the order that
unblocks the most follow-on work fastest). Update this as reality diverges from the plan — a stale execution
order is worse than none, since it actively misleads whoever reads it next.
```

## Why this shape, specifically

- **§0.1 (cross-cutting findings) exists separately from §1 (locked spec)** because the two have different
  lifecycles: locked spec is a deliberate, versioned decision; cross-cutting findings are opportunistic
  discoveries that accumulate as a side effect of doing the work. Conflating them either buries findings
  inside spec-change noise or forces premature "locking" of something you're still learning.
- **§2 is separated from §3** because shared-code tickets are a strict prerequisite for artifact-specific
  work in the common case (an artifact built against not-yet-shipped shared code either can't compile or
  silently targets a soon-to-change API) — sequencing them first, and flagging them for the heavier
  Regression Impact Judge review, reflects that they're categorically higher-risk than one artifact's own
  scoped change.
- **§4 (status) is deliberately a flat scan-first table**, not prose — the tracker's most common read pattern
  is "what's left," and prose buries that answer.
- **§5 (dispatch mechanics) is restated in full, not just linked**, because a tracker read cold at the start
  of a new session (the most common real read pattern in this project's actual history) shouldn't require
  cross-referencing a second doc just to remember how to run the very next command.
