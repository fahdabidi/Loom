# B25 row reachability — every row cross-checked against its shipped package

Generated 2026-08-24 by cross-checking each row in
`app/packages/core/loom_communities_app_shell/assets/b25_semantic_interaction_models.json`
against the `workflowType` and `roleId` values its community's shipped `.jsonc` actually declares.

This is the comparison the tracker's 2026-08-22 RESET row called "the next measurement needed"
and recorded as never having been made.

## Result

| | Count |
|---|---|
| B25 rows total | 79 |
| Rows naming a workflow the package does not ship | 7 |
| Rows naming a role the package does not declare | 13 |
| **Distinct rows that cannot be proven as written** | **20 (25%)** |

Excluded as not defects: 5 `wf_*` rows (Masjid Nur's B18-B20 persona-picker, persona-aware-ux and
multi-persona-evidence). Those are demo-app harness rows and are legitimately not package workflows.

## The dominant pattern is one decision, not eleven bugs

**11 of the 13 missing roles are the same role: `owner`**, across five communities.

| Community | Its leadership role | Rows naming `owner` |
|---|---|---|
| Cedar Commons HOA | `hoa-board` | 4 |
| Chess Club | `chess-organizer` | 3 |
| Neighborhood Book Club | `book-organizer` | 2 |
| Garden Club | `garden-coordinator` | 1 |
| Masjid Nur | `masjid-admin` | 1 |

Ad-Free (`ad-off-owner`) and Riverside Youth Soccer (`soccer-owner`) DO declare an owner role, so the
corpus is inconsistent rather than uniformly missing one. The remaining 2 are Masjid Nur's `donor`,
which that package expresses as `community-member`.

The open question is a spec one: is `owner` a distinct role a community declares, or is it the product
docs' generic word for whoever runs the community? Answering it unblocks 11 rows at once. It should not
be settled by editing 11 doc rows to match the packages -- hard rule 14 forbids converging by removal,
and two communities model `owner` as real.

## Method

Validated against three independent ground truths before being trusted:

- the live B15 walkthrough failed with "no actor identity that can represent B25 product-doc role
  `owner`" for `chess-pairing-queue` -- which this check flags independently;
- the B15 manifest's own `productFindings` reported `chess-local-install-open` has no workflow
  definition -- which this check also flags;
- `garden-tool-loan-giveaway`, already recorded as the Garden walkthrough's root cause, appears here too.

## Full findings

```
NO-ROLE CedarCommonsHOA hoa-architectural-request role=owner (has: hoa-board hoa-member )
NO-ROLE CedarCommonsHOA hoa-committee-decision role=owner (has: hoa-board hoa-member )
NO-ROLE CedarCommonsHOA hoa-export-evidence role=owner (has: hoa-board hoa-member )
NO-ROLE CedarCommonsHOA hoa-owner-notification role=owner (has: hoa-board hoa-member )
NO-ROLE ChessClub chess-export-package role=owner (has: chess-member chess-organizer )
NO-ROLE ChessClub chess-pairing-queue role=owner (has: chess-member chess-organizer )
NO-ROLE ChessClub chess-rankings-table role=owner (has: chess-member chess-organizer )
NO-ROLE GardenClub garden-export-custom-schemas role=owner (has: garden-coordinator garden-member )
NO-ROLE MasjidNur mosque-announcement role=owner (has: community-member masjid-admin )
NO-ROLE MasjidNur mosque-donation-payment role=donor (has: community-member masjid-admin )
NO-ROLE MasjidNur mosque-donor-visibility role=donor (has: community-member masjid-admin )
NO-ROLE NeighborhoodBookClub book-export-metadata role=owner (has: book-member book-organizer )
NO-ROLE NeighborhoodBookClub book-selection-publish role=owner (has: book-member book-organizer )
NO-WF ChessClub chess-local-install-open
NO-WF ChessClub chess-route-home
NO-WF GardenClub garden-tool-loan-giveaway
NO-WF MasjidNur wf_community-persona-aware-ux
NO-WF MasjidNur wf_community-persona-aware-ux
NO-WF MasjidNur wf_demo-app-persona-picker
NO-WF MasjidNur wf_multi-persona-workflow-evidence
NO-WF MasjidNur wf_multi-persona-workflow-evidence
NO-WF MemberSocialSpace platform-connection-invite
NO-WF MemberSocialSpace platform-connections-entry
NO-WF MemberSocialSpace platform-message-stream
NO-WF MemberSocialSpace platform-messages-entry
```

---

## CORRECTION, same day — the role half of this measurement was wrong

**The "13 rows naming a missing role" figure above is incorrect, and so is the "20 distinct rows"**
**total that depends on it. The real number blocked on role is 5.**

This check compared each B25 `role` against the `roleId` values in the shipped `.jsonc`. That is
not what the walkthrough does. `_roleIdsForB25Role` in `workflow_ui_evidence_test.dart` matches a
B25 role against `roleId + label + roleLabel` of each entry in the Dart evidence catalog, with
explicit synonym fallbacks:

```dart
'owner' => contains('owner') || contains('admin') || contains('board') || contains('coordinator')
'donor' => contains('member')
'admin' => contains('admin') || contains('owner')
'organizer' => contains('organizer') || contains('coordinator') || contains('admin') || contains('owner')
```

So Cedar (`hoa-board`), Garden (`garden-coordinator`) and Masjid (`mosque-admin`) resolve `owner`
today, and Masjid resolves `donor` via member. None were ever blocked. Only Chess and Book Club
genuinely fail, because Organizer + Member contains none of the four owner synonyms:

| Community | Blocked rows |
|---|---|
| Chess Club | `chess-export-package`, `chess-pairing-queue`, `chess-rankings-table` |
| Neighborhood Book Club | `book-selection-publish`, `book-export-metadata` |

**The workflow half of this measurement stands** — 7 rows name a workflow their package does not
ship. That half was validated against three ground truths. The role half never was: all three
were workflow-missing cases, so the synonym logic was never exercised against a known answer.

**A second finding fell out of the correction.** There are two disagreeing sources of role truth.
The evidence catalog says Ad-Free has `ad-off-admin` and Soccer a bare `owner`; the shipped JSON
says `ad-off-owner` and `soccer-owner`. The walkthrough reads the catalog, the validator reads the
JSON, and nothing keeps them in sync.
