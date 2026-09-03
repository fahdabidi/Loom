# GAP TICKET — messaging / discussion-thread API (incl. per-member mute)

**Status:** POST-PRODUCTION (user decision 2026-09-02)
**Severity:** gap — doc-promised affordances render but have no backing API

## The gap
The "messages" / discussion-thread experience is not built server-side. Doc-promised member affordances
render as buttons but have no persistence:
- **Per-member mute** ("Mute thread" — stops interruption, keeps the record in the inbox): requires storing
  which member muted which thread. No API or store exists, so the button is a **dead affordance** today.
- The broader discussion-thread messaging (send/reply history, read/unread per member) needs a real backend.

## What "done" looks like
- A messaging/discussion API (fan-passport or a dedicated service) that persists per-member mute state and
  thread message/read state.
- Skill can then author the mute/messaging affordances against a real mechanism (no force-fit, no dead button).

## Interim (until this lands)
- The skill drops the mute affordance on regeneration (no mechanism) — correct.
- **Validator should emit a WARNING** when a package declares an affordance whose backing API experience is
  not implemented (e.g. mute/messaging), so the gap is visible rather than silent. (See the skill/validator
  enhancement work, 2026-09-02.)

## Why post-production
Messaging is a new backend surface; not on the critical path to the production bar. Tackle after production.
