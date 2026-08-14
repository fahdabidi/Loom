---
spec: 4
doc_version: 1.0.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
---

# `approvalQueueItem`

Something one person asks for and another decides on.

**The most customised archetype in the corpus** — 9 communities and **74 community-defined
transitions**, more than any other. It is the clearest evidence that a closed vocabulary would have
been the wrong design.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

> Not to be confused with [`approval-queue.md`](./approval-queue.md), which describes the *authoring
> pattern*. This file defines the archetype's contract.

## 1. Actions

**None named.** Generic archetype: every transition derives structurally.

| Structure | Derived action | Permission |
|---|---|---|
| a `create` action on a binding | `create` | `approval_queue_item.create` |
| `tone: "destructive"`, or target `isTerminal` | `terminate` | `approval_queue_item.terminate` |
| any other state change | `advance` | `approval_queue_item.advance` |
| read-only binding | `view` | `approval_queue_item.view` |

The corpus vocabulary is entirely community-owned: `approve`, `reject`, `assign-pairing`,
`approve-and-assign-care-request`, `approve-handoff`, `begin-review`, `request-changes`,
`accept-invite`, and 66 more.

## 2. The accepted limit

**Structural derivation cannot separate `approve` from `reject` — both are `advance`.** So this
archetype can express *may decide* but not *may approve but not reject*.

This is accepted deliberately (`permissions.md` §5). A reviewer who may approve can realistically
reject, and the alternative is forcing an `action` field onto all 74 transitions, which would end the
genericity that makes the archetype useful.

**If a community genuinely needs asymmetric decision rights, that is the signal to promote it to a
bespoke archetype** with a closed vocabulary — not a reason to complicate the generic path.

## 3. Bookkeeping

**None.** A request has a requester and a reviewer, not a per-person interaction log.

## 4. Visibility

Model: **`parties`** — the requester and the reviewer, plus the roles a state admits.

This archetype is behind most of the 18 identity-dependent read guards in the corpus. Typical shape
today:

```jsonc
"readGuard": { "formula": "$viewer == requesterFanId || $viewer == reviewerFanId" }
```

Under the `parties` model the community names which fields hold the two sides and writes no formula.

> **This is where the seven broken guards live.** Three of Cedar Commons HOA's — `hoa-dues-payment`,
> `hoa-architectural-request`, `hoa-committee-decision` — compare `$viewer` against the literal
> `'hoa-board'`, a declared role. That comparison can never be true, so the intended "…or a board
> member may read it" clause silently does nothing. Nobody had flagged them before the corpus was
> scanned.

Corpus split: 6 `guarded`, 4 `membersOnly`, 1 `public`.

## 5. Worked example — Camera Club

```jsonc
"critique-submission": {
  "states": {
    "submitted": { "label": "Submitted" },
    "reviewed":  { "label": "Reviewed" },
    "withdrawn": { "label": "Withdrawn", "isTerminal": true }
  },
  "visibility": { "default": "guarded" },

  "transitions": [
    // No `action` on any of these: they are this community's own vocabulary.
    { "id": "review",   "from": ["submitted"], "to": "reviewed",
      "guard": { "allowedRoleIds": ["camera-mentor"] } },
    { "id": "withdraw", "from": ["submitted"], "to": "withdrawn", "tone": "destructive",
      "guard": { "actorEqualsField": { "key": "submitterFanId" } } }
  ]
}
```

| Role | Permission | From |
|---|---|---|
| `camera-mentor` | `approval_queue_item.advance` | `review` changes state |
| *(none)* | `approval_queue_item.terminate` | `withdraw` is destructive — but guarded per-instance, not by role, so it grants nothing at install time |

That second row is the two-layer model working as intended: `withdraw` is gated by
`actorEqualsField`, which the workflow engine resolves per instance. It derives no role grant, and
that is correct — "only the submitter may withdraw their own submission" is a fact about one row.

## 6. Community-defined actions

**The norm.** All 74 of them.

## 7. Open

- **Whether `parties` needs configurable field names.** Communities name the two sides differently
  (`requesterFanId`/`reviewerFanId`, `submitterFanId`/`mentorFanId`, `guardianFanId`/`coachFanId`).
  The model must let a community say which fields play which part.
