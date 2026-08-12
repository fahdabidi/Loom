---
spec: { envelope: 1, experience: 2, grammar: 1 }
doc_version: 1.1.0
status: current
last_verified: 2026-08-12
audience: llm-agent
---

# Solved patterns — recurring requirement shapes, with the verified-correct JSON shape

Every pattern below was extracted from a **real, independently-judged defect** found in a skill-authored
community package during the Community JSON Migration effort (`docs/Build Plan V2/Community JSON Migration
Tracker.md`). Two of them (delist-guard, ordered-queue-position) were independently reinvented as bugs by
**two different authoring passes** before either was named here — that repetition is exactly why this doc
exists: naming a shape once, with its verified-correct fix, should stop it from being rediscovered as a bug
a third time.

**How to use this doc:** read it in full before authoring, the same way you read `04-antipatterns.md`. Each
entry names the requirement shape in the words a product doc might use for it, shows the shape that looks
plausible but is wrong, shows the verified-correct shape, and cites the real community where this was found
and fixed. If a requirement in front of you matches one of these shapes, use the correct shape directly —
don't re-derive it from scratch.

---

## 1. Destructive/terminal transition on a possessable item must gate on availability, not just ownership

**Requirement shape:** an item (tool, gear, listing) can be loaned/claimed and later delisted/removed by its
owner.

**Looks plausible, is wrong:**
```jsonc
{ "id": "delist", "from": ["published"], "to": "delisted",
  "guard": { "actorEqualsField": { "key": "ownerPersonaId" } } }
```
Only the owner is checked. But `availabilityState` (available/requested/reserved/onLoan) is **orthogonal
data**, not a separate FSM state (per AP-1) — so the item can still be `published` while actively on loan,
and this guard lets the owner delist it out from under an active borrower, stranding the loan with no
return path.

**Verified-correct shape:**
```jsonc
{ "id": "delist", "from": ["published"], "to": "delisted",
  "guard": { "actorEqualsField": { "key": "ownerPersonaId" },
             "instanceDataEquals": { "key": "availabilityState", "value": "available" } } }
```
Delist only fires when nothing is actively borrowed/claimed — mirrors the pattern every sibling
`cancel-request`/`decline-loan` transition on the same workflow already uses.

**Found in:** Camera Club's `gear-loan-request.delist` and (independently, same bug) Garden Club's
`garden-tool-loan.delist`/`garden-tool-giveaway.delist` — both merged with this fix.

---

## 2. Ordered queue with visible position needs one shared container instance, not N separate per-item instances

**Requirement shape:** a doc requires "waiting members see their queue position."

**Looks plausible, is wrong:** modeling each waiting entrant as its own separate workflow instance (one
`chess-pairing-queue` instance per waiting player). This feels natural (each waiting player "is a thing"),
but `indexOf(list, value)` — the only real position-computing function (`formulas.md`) — needs a **list on
one shared instance** to search. With N separate instances there is no shared list to index into, so
position becomes uncomputable, and the requirement quietly gets dropped (often with an unrelated excuse for
why it can't be done).

**Verified-correct shape:** one shared container instance holding an **ordered list**; each waiting
member's position is their index in that list.
```jsonc
"instanceDataSchema": {
  "waitingPlayerNames": { "type": "list", "writableBy": "effect",
    "labelTemplate": "Waiting in order: {value}" }
}
```
`appendUnique` on join, `removeValue` on assign/withdraw — list order is preserved as join order, so the
position is genuinely visible (as an ordered list any viewer can read), without needing a per-viewer
`indexOf` formula at all. If a numeric per-viewer position is specifically required (not just visible
order), only then reach for `indexOf(waitingPlayerNames, playerId)` — but note this needs a resolvable
individual identity (a real `personaId`), not a free-text name, so check the community's persona model
first (see pattern 6 below).

**Found in:** Chess Club's `chess-pairing-queue` — the first authoring pass used N separate instances,
silently dropped "waiting players see queue position," and justified the drop with a claim (no admin-tab
access for the waiting persona) that a `grep` of the package's own `role: "any"` binding directly
contradicted. Redesigned to the shared-container shape above.

---

## 3. Admin-created, member-received objects need `role: "any"` + `visibility.readGuard`, never `role: "actor"`/`"receiver"`

**Requirement shape:** an admin/organizer publishes an announcement or sends a notification; a member
receives and reads it.

**Looks plausible, is wrong:**
```jsonc
{ "states": ["sent"], "role": "receiver", "tabId": "home", ... }
```
On every tab except `admin`, `"receiver"` does not resolve the way its name suggests — it does not mean
"whoever should receive this." Per `render-bindings.md`'s documented trap, non-`admin` tabs can only
reliably resolve `role: "any"`; `"actor"`/`"receiver"` are creator-only semantics that produce a
permanently dead card for anyone who isn't the literal `createdByPersonaId`. Since the admin created the
announcement, a member's `home` tab binding using `"receiver"` never shows them anything.

**Verified-correct shape:**
```jsonc
"visibility": { "default": "guarded",
                "readGuard": { "formula": "$viewer == recipientPersonaId || $viewer == 'community-admin'" } },
"renderBindings": [
  { "states": ["sent"], "role": "any", "tabId": "home", "cardSurfaceFamily": "notificationInbox", ... }
]
```
`role: "any"` makes the card visible to everyone the binding's tab reaches; real per-recipient privacy
comes from `visibility.readGuard`, which is genuinely engine-enforced at the query layer — not the render
binding's role, which only ever controls *card visibility given the row is already readable*, never
row-level privacy.

**Found in:** correctly applied from the start in Cedar Commons HOA, Masjid Nur's `mosque-announcement`/
`mosque-neutral-notification`, Ad-Free Community's checkout/entitlement types — cite these as the working
reference when a new community needs the same shape. Formalized here because `render-bindings.md` already
documents the trap in prose; this entry exists to give the pattern a name and a copy-pasteable shape.

---

## 4. Never fabricate a backend-computed value — checksum, receipt ID, ranking delta

**Requirement shape:** an export/payment/ranking workflow needs a checksum, receipt ID, transaction ID, or
computed ranking change.

**Looks plausible, is wrong:**
```jsonc
{ "op": "set", "key": "checksum", "value": "sha256-chess-2026" }
```
A hardcoded or seemingly-computed-looking literal. `platform-services.md` lists checksum/hash generation,
payment-receipt-ID generation, and real Elo/rating math (`pow`/`exp` aren't in `formulas.md`'s function
list) as `❌ Not implemented` platform services — no real backend exists to produce these values honestly.

**Verified-correct shape:** declare the field, never write it from any effect, mark the gap inline:
```jsonc
// NEEDS IMPLEMENTATION (platform service): checksum/hash generation is a Not-implemented
// platform service (platform-services.md). Declared, never written by any effect.
"checksum": { "type": "text?", "writableBy": "effect", "hideWhenEmpty": true }
```
If a real, honestly-derivable value exists (e.g. a status label like `"complete"`, or a count via
`size(...)`), use that instead of leaving the surface empty — the anti-pattern is fabricating an *opaque
identifier or hash*, not every computed field. `receiptStatus: "complete"` is fine; `receiptId:
"RCT-88221"` is not.

**Found in:** Cedar Commons HOA's `hoa-export-evidence` (original bug), Chess Club's `chess-export-package`
(hardcoded checksum) and `chess-match-result` (fake ranking-delta string, disconnected from the real
submitted score) — both named explicitly in that community's product-doc correction note as bugs never to
repeat, and both avoided cleanly in the actual authored package.

---

## 5. A workflow with no creation path anywhere can never come into existence beyond its seed data

**Requirement shape:** a doc requires a "change path"/"update preference"/similar ongoing-editable surface
for a workflow whose fields are all `writableBy: "effect"` (not user-editable via a form).

**Looks plausible, is wrong:** seeding 1-2 example instances and assuming that's sufficient, with no
`renderBindings[].actions[].kind: "create"` anywhere and no `createInstance` effect anywhere else in the
package targeting this type. The existing validator rule `no_creation_path_for_editable_type` only fires
for types declaring `formEntry`-writable fields — an all-`effect`-writable type (common for
"preference"/"status" objects spawned by another workflow's action) can slip past that check entirely while
still being permanently uncreatable once the seeded rows are gone.

**Verified-correct shape:** if the type conceptually belongs to a real user action elsewhere (a donation
creating a donor-visibility preference; a signup creating a membership record), wire a `createInstance`
effect on that real action:
```jsonc
{ "id": "pay", ...,
  "effects": [
    ...,
    { "op": "createInstance", "workflowType": "donor-visibility-preference",
      "fields": { "donorPersonaId": "{donorPersonaId}", "fund": "{fund}", "amountLabel": "{amountLabel}" } }
  ] }
```
If it's genuinely a standalone, directly-creatable object instead, give it its own `kind: "create"` action
the normal way. Either is fine — the requirement is that *some* real path exists, not which one.

**Found in:** Masjid Nur's `mosque-donor-visibility` had zero creation path (two seeded rows standing in
for a missing affordance); fixed by wiring `mosque-donation-payment`'s `pay` transition to create a real
per-donation preference row.

---

## 6. Choose the tightest correct `visibility`/`readGuard` scope available — don't default to a looser one when a sibling type in the same package already shows the tighter pattern working

**Requirement shape:** a doc explicitly excludes one persona from seeing a workflow's data ("only sees the
transfer's own scope, never the source community's unrelated internal data").

**Looks plausible, is wrong:**
```jsonc
"visibility": { "default": "membersOnly" }
```
`membersOnly` means "any signed-in, active-status account for this community" (`workflow-grammar.md`) — it
does **not** distinguish between personas. If a persona the doc explicitly wants excluded (e.g. a Receiving
Provider who should only see their own transfer, never the exporting owner's other export packages) counts
as a community "member" for this purpose, `membersOnly` silently leaks every instance to them.

**Verified-correct shape:** use `guarded` + an explicit persona allowlist that deliberately omits the
excluded persona:
```jsonc
"visibility": { "default": "guarded",
                "readGuard": { "allowedPersonaIds": ["portability-owner", "portability-member"] } }
```
Before picking `membersOnly` for any workflow with a doc-stated visibility exclusion, check whether a
sibling workflow in the *same package* already uses `guarded` + `readGuard.allowedPersonaIds` correctly for
a similar need — if so, that's the mechanism to reuse, not a looser default.

**Found in:** Data Portability Community's `export-package` used `membersOnly` (leaking to the Receiving
Provider persona) while the same package's `export-transfer`/`export-transfer-rollback` already correctly
used `guarded` + a `readGuard` excluding that exact persona — the tighter pattern was available and unused.

---

## 7. Stamp actor-identity fields via an effect on the workflow's own first transition — an equally valid alternative to `$actor` in create-action `prefill`

**Requirement shape:** a self-created instance needs its owner/actor field
(`ownerPersonaId`/`memberPersonaId`/`authorPersonaId`) populated with the real creating persona, for later
`actorEqualsField` guards/`readGuard`s to work.

**Also correct today (CJM.6 fixed, 2026-08-10):**
```jsonc
"actions": [{ "kind": "create", "scope": "tab", "prefill": { "ownerPersonaId": "$actor" } }]
```
`$actor` now correctly resolves in `prefill` for both creation scopes — this pattern was broken between
when it was first tried and 2026-08-10, but is a safe default again. The pattern below remains an equally
valid alternative with no functional downside, not a required workaround.

**Also correct, works via a different mechanism:** stamp the field via a normal transition effect
instead — `$actor` inside `effects` is the single most common, worked-example-confirmed construct in this
entire grammar, used in nearly every community's transitions already.
```jsonc
"states": {
  "offer": { "label": "Offer", "editableFields": ["priceLabel"],
             "editGuard": { "allowedPersonaIds": ["ad-off-member"] } }
},
"transitions": [
  { "id": "start-checkout", "from": ["offer"], "to": "reviewing",
    "guard": { "allowedPersonaIds": ["ad-off-member"] },
    "effects": [
      { "op": "set", "key": "memberPersonaId", "value": "$actor" },
      { "op": "set", "key": "priceLabel", "value": "{priceLabel}" }
    ] }
]
```
Two consequences to design around: (1) the un-stamped field must not be `required: true` (it's genuinely
absent for the brief window between creation and the first transition firing), and (2) any guard/`readGuard`
that would check the field on the pre-stamp state must fall back to `allowedPersonaIds` only (there's
nothing to check `actorEqualsField` against yet) — a state-level `readGuard` override on that one state
(`workflow-grammar.md`'s per-state `readGuard`, IMPLEMENTED) keeps the creator able to see their own
just-created, not-yet-stamped instance if the workflow-level `visibility` is `guarded`.

**Found in:** Ad-Free Community's `ad-off-member-checkout`/`ad-off-community-checkout` — discovered via a
Skill Retrospective while CJM.6 (above) was still an open engine bug; the same authoring agent worked out
this fix itself when asked what it could have done differently. Kept in this bank as a valid alternative
even after CJM.6 landed — both mechanisms work today, use whichever fits the workflow's shape better.

---

## 8. Every non-`home`/`messages` `tabId` used anywhere in `renderBindings` needs a matching `appShell.tabs[]`/`personaTabs[]` declaration — omitting it entirely is easy when focused on workflow content

**Requirement shape:** a workflow's `renderBindings[].tabId` names a tab (e.g. `"calendar"`, `"organize"`,
`"documents"`) that isn't `home`/`messages`. `tabId` is an open vocabulary — any name is valid — but every
value used anywhere in the package must have a corresponding entry in the top-level `appShell.tabs[]`
array (or `personaTabs[]` for a persona-scoped tab), or the validator rejects it with `unknown_tab_id`.

**Looks plausible but is wrong:** authoring every workflow's `renderBindings` correctly, including
well-chosen custom `tabId` values that match the product doc's own vocabulary, and then simply never
emitting a top-level `appShell` block at all. Nothing about drafting the workflows themselves prompts you to
come back and declare the tabs they reference — this is a whole-package omission, not a per-field mistake,
so a field-by-field self-check of each `renderBindings` entry will not catch it. Confirmed in practice: a
full self-check pass (all antipattern rules, all `05-validation.md` rows, every `role`/guard check) still
missed this, because none of those checks are phrased as "does a top-level key exist."

**Verified-correct shape:** after drafting every workflow, collect the full set of distinct non-`home`/
`messages` `tabId` values used anywhere in the package, then emit exactly one `appShell.tabs[]` entry per
value:
```jsonc
"appShell": {
  "tabs": [
    { "tabId": "calendar", "label": "Calendar", "iconKey": "calendar_today",
      "description": "Events, schedules, capacity, and reminders." },
    { "tabId": "documents", "label": "Documents", "iconKey": "folder",
      "description": "Shared files and export records." }
  ]
}
```
`rendererContractId` may be omitted (defaults to the generic list surface) unless the tab genuinely needs a
bespoke renderer. See `render-bindings.md`'s `appShell.tabs[]` / `personaTabs[]` — tab declaration shape`
section for the complete field list.

**Self-check step to add, explicitly:** before finishing, grep your own draft for every distinct
`renderBindings[].tabId` value across every workflow, then confirm each one (other than `home`/`messages`)
has a matching `appShell.tabs[]`/`personaTabs[]` entry. Do this as a literal list-comparison step, separate
from validating each `renderBindings` entry in isolation — the two checks catch different failure modes.

**Found in:** Garden Club, re-authored via the Codex GitHub-fetch dispatch channel 2026-08-12 (Milestone
1.5 of `TabId-Archetype Gap Closure.md`) — the fresh output correctly used `calendar`/`marketplace`/
`organize`/`documents`/`care` as tabIds across its workflows, but emitted no `appShell` block at all,
producing 15 `unknown_tab_id` errors on first validation. The currently-shipped fixture for the same
community already gets this right (`appShell.tabs[]` with 3 declared tabs), confirming the gap was in this
one dispatch's output, not a documentation gap in `render-bindings.md` itself (which already documents the
requirement correctly) — the missing piece was reinforcement at the point of final self-check.

---

## Known current engine limitations to design around (not "solved" — update this section once each lands)

These are real, confirmed gaps in the App Shell's implementation of documented grammar, not JSON-authoring
mistakes — no JSON-level fix exists for either until the underlying engine ticket lands. Check
`docs/Build Plan V2/Community JSON Migration Tracker.md` §2 for current status before relying on either.

- **CJM.5 — the `event-rsvp` detail card hardcodes the literal workflow-type strings `'event-rsvp'`/
  `'event-rsvp-response'`** instead of reading each community's own `responseTable` binding
  (`part28_engine_native_calendar_surface.dart`). Since no real community names its event workflow type
  literally `event-rsvp`, per-member RSVP action buttons may not populate correctly for any community using
  a custom-named event/response pair — which is every real community. Status: under investigation.
- **CJM.6 — FIXED, 2026-08-10 (commits `8ec0af17`, `6df2024f`).** A `create` action's `prefill` now
  correctly resolves `$actor` (and `$timestamp`) for both `scope: "tab"` and `scope: "instance"` creates —
  `"prefill": {"ownerPersonaId": "$actor"}"` is a safe, working pattern again. Independently re-verified via
  a dedicated Regression Impact Judge dispatch against every real consumer (Camera Club, Garden Club,
  Masjid Nur, Riverside Youth Soccer, Data Portability Community, Chess Club) — each traced individually
  against its own guards/readGuards and confirmed genuinely repaired, not just compiling. Pattern 7 (stamp
  via an effect on the first transition) remains a perfectly valid alternative and is what Ad-Free Community
  and Member Social Space already ship with — there's no need to retrofit them now that CJM.6 is fixed,
  since pattern 7 has no functional downside, but new workflows can use either `$actor`-in-`prefill` or
  pattern 7 going forward.
