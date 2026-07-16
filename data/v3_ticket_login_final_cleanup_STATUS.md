# Ticket status: login final cleanup

## Bug 1 — wrong seeded extensionId
Status: done
Changed `ext_tabletop_club` → `ext_verify_tabletop_club` in part30_local_auth_api.dart:21.
This matches the frozen JSON's actual extensionId. The 14 seed accounts were previously
registered under the wrong key, causing `listAccounts()` to return an empty list for
real Tabletop Club installs.

## Bug 2 — stale instance-count assertions
Status: done
All 4 assertions updated from `hasLength(17)` to `hasLength(20)`:
- a4:122 — `experience.workflowInstances` (parsed directly from JSON) → 20
- a5:81 — `queryInstances(tabId: 'home')` returns all instances → 20
- a5:140 — same query, repeated → 20  
- login:234 — `queryInstances(tabId: 'home')` → 20

Additionally, a5's hardcoded `expectedIds` set was updated to include the 3 new
game-loan share instances: `share-ticket-to-ride`, `share-gloomhaven`, `share-azul`.

## Verification
dart analyze: **clean** ("No issues found!").
flutter test: **blocked** — sandbox denies server-socket creation (same as all prior rounds).

## Commit
Commit hash: 4b77de5
