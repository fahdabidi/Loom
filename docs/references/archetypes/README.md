---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.0.0
status: current
last_verified: 2026-07-14
audience: llm-agent
---

# Archetypes — index and status

`cardSurfaceFamily` in a render binding names an **archetype** — the widget family that renders the
instance.

## AGENT: hard rules

1. **MUST NOT invent a `cardSurfaceFamily`.** Only the values below exist. An unknown one produces
   `missing_template` and renders as a generic fallback card.
2. **Check the Status column.** Most archetypes are **being rebuilt right now** (tracker 3). A `NOT REAL`
   archetype currently renders as a generic card regardless of what you declare — you may still declare
   it (the JSON is forward-looking), but do not expect the interaction to work yet.
3. **Read the honesty note below** before assuming any archetype "works".

## Status legend

| Status | Meaning |
|---|---|
| ✅ REAL | A genuinely distinct widget with the interactions its name implies |
| 🔨 REBUILDING | Being made real now; the phase is named |
| ❌ NOT REAL | Currently renders as the generic card (icon + title + fact pills + buttons) |

## The archetypes

| `cardSurfaceFamily` | Purpose | Status |
|---|---|---|
| `event-rsvp` | Event with RSVP + capacity + waitlist | 🔨 REBUILDING — tracker-3 Phase A |
| `votePoll` | Ballot: candidates, tally, tie/runoff | 🔨 REBUILDING — Phase B |
| `equipment-loan` | Browse/borrow/queue/return items | 🔨 REBUILDING — Phase C |
| `paymentCheckout` | Dues/donations + receipt | 🔨 REBUILDING — Phase D |
| `approvalQueueItem` | A live queue of items awaiting decision | 🔨 REBUILDING — Phase E |
| `formEntry` | Author/edit a record (typed controls) | 🔨 REBUILDING — Phase E |
| `discussionThread` | Threads + messages + compose | 🔨 REBUILDING — Phase F |
| `statusTimeline` | Timestamped progression of an item | ❌ NOT REAL |
| `notificationInbox` | List of notices, unread state | ❌ NOT REAL |
| `documentLibrary` | Categorised documents | ❌ NOT REAL (widget exists; no data ever populated it) |
| `stateMachineGrid` / `table` | Browse many items, search/filter/sort | ❌ NOT REAL (except Marketplace) |
| `volunteerRoster` | Shifts + capacity meter | ❌ NOT REAL |
| `exportWizard` | Stepped export flow | ❌ NOT REAL |
| `searchAiAnswer` | Query + cited answer | ❌ NOT REAL |
| `audienceSelector` | Multi-select member picker | ❌ NOT REAL |
| `protectedDetail` | Field-level masking by viewer | ⚠️ Permission logic REAL; visual treatment NOT |
| `singleItem` | Exclusive choice (radio/segmented) | ❌ NOT REAL |
| `guidedProcess` | Multi-step wizard with step indicator | ✅ REAL |
| `dashboard` | The Home feed | ⚠️ Real, but section order is hardcoded, not data-driven |

## ⚠️ Honesty note — read this

An audit of all 17 archetypes found that **15 of 17 were the same generic card, reskinned** — an icon, a
title, a subtitle, a row of fact pills, and a row of buttons. The names promised distinct interaction
models; the code delivered one.

Tracker 3 is the effort to make them real, one phase at a time, driven from JSON.

**Consequence for the agent:** declaring `cardSurfaceFamily: "volunteerRoster"` today does **not** get you
a capacity meter. It gets you the generic card. The JSON you write is correct and forward-looking — but
do not tell the user an interaction works when it does not.

## Per-archetype JSON references

Written and verified **as each phase makes the archetype real** — not before. Documenting a JSON shape
for a widget that doesn't exist is how the previous doc set came to describe a `CommunityVoteApi` that
never existed.

| Archetype | Doc | When |
|---|---|---|
| `event-rsvp` | [calendar-agenda.md](./calendar-agenda.md) | **Draft now** (Phase A verifies it) |
| `votePoll` | *planned* | Phase B |
| `equipment-loan` | *planned* | Phase C |
| `paymentCheckout` | *planned* | Phase D |
| `approvalQueueItem`, `formEntry` | *planned* | Phase E |
| `discussionThread` | *planned* | Phase F |

Until a per-archetype doc exists, use:
- [`guide/03-common-patterns.md`](../guide/03-common-patterns.md) — canonical templates
- [`communities/tabletop-club.md`](../communities/tabletop-club.md) — a full worked community
