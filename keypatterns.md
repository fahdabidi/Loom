# Key Patterns — Loom's institutional memory

**What this file is.** Fed by the Root Cause Agent (`data/call_root_cause_agent.sh`), a single
persistent Codex session that carries context across every dispatch made to it and is meant to act
as this project's standing expert — the one place that accumulates recurring issues, durable
patterns, and key architectural decisions/pivots across every investigation, rather than each
dispatch rediscovering them independently. **The agent itself never writes this file** — it runs
`--sandbox read-only` with zero write access, enforced, not just asked for. It only *proposes* an
entry, as text in its reply, delimited by `<<<KEYPATTERNS_ENTRY>>>`/`<<<END_KEYPATTERNS_ENTRY>>>`;
`call_root_cause_agent.sh` itself extracts and appends that block after the dispatch completes —
that script is this file's only writer.

**Append-only.** Never delete or rewrite an existing entry from this file — that includes the
agent that maintains it. A superseded entry is corrected by adding a new entry that says so and
pointing back at the old one, the same convention this project's trackers already use
(`ORIGINAL: ...` kept alongside a correction, never replaced). If an entry turns out wrong, mark it
`[SUPERSEDED — see <entry>]` in place rather than removing it.

**How this feeds `CLAUDE.md`.** This file is the working/staging memory; `CLAUDE.md` is the
project's actual loaded-every-session instructions. After each Root Cause Agent dispatch, the
orchestrating session reviews what's new here and folds genuinely durable, generally-applicable
entries into `CLAUDE.md` itself (in its own words, at `CLAUDE.md`'s own level of generality) —
this file is not read automatically by every session the way `CLAUDE.md` is, so an entry that
matters going forward needs to actually make that trip, not just sit here.

**Entry shape** (one per finding, dated, most recent last):

```
### YYYY-MM-DD — <short title>

**Kind:** recurring issue | pattern | architectural decision/pivot
**What:** <the thing itself, plainly>
**Why it matters:** <what it costs to not know this>
**Evidence:** <dispatch/investigation it came from, or a file:line/commit if there is one>
```

---

## Entries

_None yet — seeded 2026-09-07 via the Root Cause Agent's first real dispatch (context-loading
across every tracker, architecture doc, OpenAPI spec, Skill file, and the git history). Entries
follow below as the agent finds them, starting with that dispatch's own findings._
