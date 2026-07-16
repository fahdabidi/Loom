# Ticket status: login final cleanup round 2

## Bug 1 — a5 empty-payload smoke test
Status: done
Updated `createInstance` call to pass required fields: `title`, `category`, `ownerPersonaId`.
Confirmed against `tabletop-game-loan`'s `instanceDataSchema` in the frozen JSON — these three
are `required: true`, non-computed fields.

## Bug 2 — multiuser test states-vs-data mixup
Status: done
Replaced hardcoded `currentState: 'available'` (a data value, not a state) and incomplete
`instanceData` with a live query of the seeded `share-azul` instance via
`page.items.firstWhere((i) => i.instanceId == 'share-azul')`, matching Test 3's established
pattern. Now correctly passes `currentState: 'published'` and the full seeded instance data.

Also strengthened the assertion from `isNotEmpty` to explicitly check for `approve-request`
and `decline-request` — the transitions the owner-gated guard is meant to unlock.

## Verification
dart analyze: **clean** ("No issues found!").
flutter test: **blocked** — sandbox denies server-socket creation (same as all prior rounds).

## Commit
Commit hash: 778c8ac
