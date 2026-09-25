# SKILL — add primary bindings for 5 states whose only binding is `summary` (PREREQUISITE)

**Status:** written 2026-09-25, **NOT dispatched**.
**Route:** the Skill only, via `data/call_skill_authoring_agent.sh`. Three packages, so three dispatches.
**Ordering: THIS SHIPS FIRST.** The shell ticket
[SHELL-implement-bindingkind-summary.md](SHELL-implement-bindingkind-summary.md) must not land until
this has, or five states lose reachable actions in the interval.

## Why this exists

User decided 2026-09-25: **implement `bindingKind`** — make `summary` mean what
`render-bindings.md:553-560` says it means, *"Compact/read-only card"*, rather than the current state
where the renderer ignores the key entirely and a `summary` binding renders a fully interactive card.

Implementing that faithfully has a prerequisite nobody had measured. I swept all ten packages:

- **115** `summary` bindings in total.
- **59** of them include at least one **non-terminal** state — which sounds alarming and mostly is not:
  for **115 state-coverages** a `primary` binding elsewhere (usually the workflow's own tab) also
  covers that state, so the primary keeps the actions and the summary becomes a status view. That is
  exactly `render-bindings.md`'s own documented intent ("The author watches its status on Home").
- **5 states have NO primary binding at all**, and all five have live outgoing transitions. For these,
  read-only removes user-reachable actions with nothing to fall back on.

## The five, each with what would be lost

| Package | Workflow | State | Transitions that would become unreachable |
|---|---|---|---|
| Ad-Free | `ad-off-community-checkout` | `funded` | `request-community-refund` |
| Book Club | `book-search-ai-digest` | `saved` | `edit-digest`, `add-citation`, `report-stale-citation`, `withdraw-query` |
| Cedar HOA | `hoa-architectural-request` | `approved` | `reopen-case` |
| Cedar HOA | `hoa-architectural-request` | `denied` | `reopen-case` |
| Cedar HOA | `hoa-committee-decision` | `changes-needed` | `owner-resubmitted`, `owner-withdraw` |

Verified by sweep with controls: the summary/primary split control returned **115** covered
state-coverages (so the primary side of the query matched), and each state above was checked for
outgoing transitions by reading every transition's `from` list rather than inferring from the state's
`isTerminal` flag.

**Note what these are.** A refund request, a resubmit-after-changes path, a reopen-a-decided-case path,
and four edit/curate actions on a saved digest. These are not incidental — `request-community-refund`
and `owner-resubmitted` are the kind of action whose silent disappearance is a user-facing regression
rather than a cosmetic one.

## What to build

For each of the five, **add a `primary` render binding covering that state** on the tab where its
persona already works, so the actions keep a home once `summary` becomes read-only. Do **not** change
the existing `summary` bindings — they are correct and become status views.

**Derive the tab and audience from each community's own product doc**, not by copying a sibling: the
doc's persona table says who acts on that state and where. Say per state which doc line you used.

**Per-package notes:**

- **Book Club `book-search-ai-digest` / `saved`** — this workflow is also touched by
  [SKILL-bookclub-regeneration-release-hold.md](SKILL-bookclub-regeneration-release-hold.md), which
  adds `submitterFanId` create-time identity. **Sequence those two or fold them into one Book Club
  dispatch**; two independent regenerations of one community is exactly what row-247's "regenerate
  ONCE" instinct was protecting against. Folding is preferred.
- **Cedar `hoa-architectural-request`** — it already carries **four** render bindings, three of them
  `summary`. Read them before adding a fifth; the `approved`/`denied` pair may belong on one binding.
- **Ad-Free `ad-off-community-checkout` / `funded`** — `funded` is the success state and
  `request-community-refund` is its only exit, so a member who has funded currently has a visible
  refund path that must survive.

## Out of scope

Do not implement the shell change here. Do not touch the `summary` bindings. Do not alter any
transition, guard or state — this ticket adds render bindings only.

## Verification

- `POST /validate` from my own shell per package: `pass`, 0 errors.
- Field-by-field diff per package confirming workflows, roles and tabs survive as identical sets, and
  that **no existing binding was modified** — only additions. Deletion is invisible in a validator run.
- Re-run the orphan sweep and confirm it reports **0** orphaned summary states. That is the gate this
  ticket exists to pass, and it is the check that says the shell change is now safe to land.
- Three-step regeneration per package (regenerate → publish definitions → install), then
  `check_permission_parity.sh`.
- Sync all three copies per package: app-shell asset, the `docs/references/communities` twin (**note
  the differing filenames**), and the provenance manifest via `tool/update_community_provenance.dart`.
- All five suites.
