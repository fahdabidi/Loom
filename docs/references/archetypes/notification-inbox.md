---
spec: 4
doc_version: 1.1.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
---

# `notificationInbox`

Messages addressed to one person, which they read, dismiss, or act on.

Used by 5 communities with 25 community-defined transitions.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md).

## 1. Actions

**None named.** Derives structurally.

## 2. Bookkeeping the archetype owns

| Field | Meaning |
|---|---|
| `dismissedByFanIds` | who dismissed it |
| `clickedByFanIds` | who acted on it |
| `impressionedByFanIds` | who saw it |
| `acknowledgedByFanIds` | who confirmed it |

These are genuinely per-person and appear across all 5 communities, hand-declared each time. The
archetype should own them: "has this person seen it" is not a community-specific question.

## 3. Visibility

Model: **`recipient`** -- the addressee, and only the addressee.

This is `permissions.md` section 2's canonical example of a rule that **must never become a role
permission**: *"only the recipient may dismiss their own notification"* is a fact about one row, not
about a role. Pushing it into App Access would let anyone holding the role dismiss anyone's
notifications.

Corpus split: 4 `guarded`, 3 `public`. The `public` ones are broadcast announcements rather than
addressed messages -- the same archetype serving two shapes.

**Which field holds the addressee is declared, not assumed** (decision D9, 2026-08-14 —
[`workflow-grammar.md`](../reference/workflow-grammar.md)'s `visibility.fields`). The corpus already
carries two names, `recipientPersonaId` and `handoffRecipientPersonaId`:

```jsonc
"visibility": {
  "default": "guarded",
  "readGuard": { "allowedRoleIds": ["masjid-admin"] },
  "fields": { "recipient": "recipientFanId" }
}
```

**Omitting `recipient` is legal and means broadcast** — exactly the three `public` workflows above.
Such a workflow falls back to the `default` decision alone, which is the correct reading of a
community-wide announcement and still fails closed under `membersOnly` or `guarded`. So the two shapes
this archetype serves are now distinguishable in the JSON rather than only in prose.

## 4. Community-defined actions

**The norm.** `mark-notification-read`, `keep-notification-unread`, `dismiss-ad`,
`acknowledge-suppression`, `inspect-reason`, and 20 more.

## 5. Open

- **Broadcast versus addressed.** A `public` notification has no recipient, so the `recipient` model
  degenerates to `roles`. Whether that should be a separate model, or an explicit per-workflow choice,
  is undecided.
