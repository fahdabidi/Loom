# GAP TICKET — member-social-space needs `socialGraph` + `adSlot` archetypes

**Status:** POST-PRODUCTION (deferred by user decision 2026-09-02)
**Severity:** gap — one community (member-social-space) cannot be authored correctly with the current grammar
**Surfaced by:** the Thread-1 provenance regeneration (2026-09-02). The skill authoring agent REFUSED to
produce a package and reported the gap rather than force-fit — the correct behaviour.

## The gap

member-social-space's product doc requires two `cardSurfaceFamily` surface families that do **not** exist
in Loom's 13-family archetype registry:

1. **`socialGraph`** — a relationship surface for: connection suggestions + relationship status; invite /
   accept / decline / cancel / **block / unblock / appeal / keep-blocked**; per-relationship parties with a
   privacy-safe projection of the blocked target; enforcement that a block **disables messaging and further
   invitations** across related instances; and a connection-list / relationship-detail presentation (not a
   generic approval card).
2. **`adSlot`** — an advertising-placement surface for: in-stream sponsored placement + disclosure; banner
   reservation / **no-fill** handling; sensitive-context suppression; and non-collapsing layout.

## Current state (the force-fit, kept as a documented exception until this lands)

The **shipped** member-social-space package fakes these with the nearest existing archetypes —
connections use `approvalQueueItem`/`statusTimeline`, sponsored/no-fill objects use `notificationInbox`.
This is a force-fit and violates the mandatory archetype-fit rule; it is retained deliberately as a
documented provenance exception, NOT re-authored, until real archetypes exist.

## What "done" looks like

- Design + register `socialGraph` and `adSlot` archetypes (grammar + validator + app-shell renderers +
  reference docs), following the existing archetype pattern.
- Re-author member-social-space through the skill onto the real archetypes; regen should then be
  provenance-clean like the others.

## Why post-production

New archetypes are platform/grammar work (renderers, validator rules, reference docs) — larger than a
package change and not on the critical path to the production bar. Tackle after production per user
direction 2026-09-02.
