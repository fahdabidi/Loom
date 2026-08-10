# Solved patterns — recurring requirement shapes, with the verified-correct JSON shape

Every pattern below was extracted from a **real, independently-judged defect** found in a skill-authored
community package. Two of them (delist-guard, ordered-queue-position) were independently reinvented as bugs
by **two different authoring passes** before either was named here — that repetition is exactly why this
file exists: naming a shape once, with its verified-correct fix, should stop it from being rediscovered as
a bug a third time.

**How to use this file:** read it in full before authoring, the same way you read `03-antipatterns.md`.
Each entry names the requirement shape in the words a product doc might use for it, shows the shape that
looks plausible but is wrong, shows the verified-correct shape, and cites the real community where this was
found and fixed. If a requirement in front of you matches one of these shapes, use the correct shape
directly — don't re-derive it from scratch.

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
data**, not a separate FSM state, so the item can still be `published` while actively on loan, and this
guard lets the owner delist it out from under an active borrower, stranding the loan with no return path.

**Verified-correct shape:**
```jsonc
{ "id": "delist", "from": ["published"], "to": "delisted",
  "guard": { "actorEqualsField": { "key": "ownerPersonaId" },
             "instanceDataEquals": { "key": "availabilityState", "value": "available" } } }
```
Delist only fires when nothing is actively borrowed/claimed — mirrors the pattern every sibling
`cancel-request`/`decline-loan` transition on the same workflow already uses.

**Found in:** two different real communities' equipment-loan workflows, independently — both fixed with
this exact guard shape.

---

## 2. Ordered queue with visible position needs one shared container instance, not N separate per-item instances

**Requirement shape:** a doc requires "waiting members see their queue position."

**Looks plausible, is wrong:** modeling each waiting entrant as its own separate workflow instance (one
instance per waiting member). This feels natural (each waiting member "is a thing"), but `indexOf(list,
value)` — the only real position-computing function (`10-formulas.md`) — needs a **list on one shared
instance** to search. With N separate instances there is no shared list to index into, so position becomes
uncomputable, and the requirement quietly gets dropped (often with an unrelated excuse for why it can't be
done).

**Verified-correct shape:** one shared container instance holding an **ordered list**; each waiting
member's position is their index in that list.
```jsonc
"instanceDataSchema": {
  "waitingMemberNames": { "type": "list", "writableBy": "effect",
    "labelTemplate": "Waiting in order: {value}" }
}
```
`appendUnique` on join, `removeValue` on assign/withdraw — list order is preserved as join order, so the
position is genuinely visible (as an ordered list any viewer can read), without needing a per-viewer
`indexOf` formula at all. If a numeric per-viewer position is specifically required (not just visible
order), only then reach for `indexOf(waitingMemberNames, memberId)` — but note this needs a resolvable
individual identity (a real `personaId`), not a free-text name, so check the community's persona model
first (see pattern 6 below).

**Found in:** a real community's waiting-list workflow — the first authoring pass used N separate
instances, silently dropped the "waiting members see queue position" requirement, and justified the drop
with a claim (no tab access for the waiting persona) that a re-read of the grammar directly contradicted.
Redesigned to the shared-container shape above.

---

## 3. Admin-created, member-received objects need `role: "any"` + `visibility.readGuard`, never `role: "actor"`/`"receiver"`

**Requirement shape:** an admin/organizer publishes an announcement or sends a notification; a member
receives and reads it.

**Looks plausible, is wrong:**
```jsonc
{ "states": ["sent"], "role": "receiver", "tabId": "home", ... }
```
On every tab except `admin`, `"receiver"` does not resolve the way its name suggests — it does not mean
"whoever should receive this." Per `12-render-bindings.md`'s documented trap, non-`admin` tabs can only
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

**Found in:** correctly applied from the start in several real communities' announcement/notification
types — cite this shape as the working reference when a new community needs the same pattern.

---

## 4. Never fabricate a backend-computed value — checksum, receipt ID, ranking delta

**Requirement shape:** an export/payment/ranking workflow needs a checksum, receipt ID, transaction ID, or
computed ranking change.

**Looks plausible, is wrong:**
```jsonc
{ "op": "set", "key": "checksum", "value": "sha256-example-2026" }
```
A hardcoded or seemingly-computed-looking literal. `14-platform-services.md` lists checksum/hash
generation, payment-receipt-ID generation, and real Elo/rating math (`pow`/`exp` aren't in `10-formulas.md`'s
function list) as `❌ Not implemented` platform services — no real backend exists to produce these values
honestly.

**Verified-correct shape:** declare the field, never write it from any effect, mark the gap inline:
```jsonc
// NEEDS IMPLEMENTATION (platform service): checksum/hash generation is a Not-implemented
// platform service (14-platform-services.md). Declared, never written by any effect.
"checksum": { "type": "text?", "writableBy": "effect", "hideWhenEmpty": true }
```
If a real, honestly-derivable value exists (e.g. a status label like `"complete"`, or a count via
`size(...)`), use that instead of leaving the surface empty — the anti-pattern is fabricating an *opaque
identifier or hash*, not every computed field. `receiptStatus: "complete"` is fine; `receiptId:
"RCT-88221"` is not.

**Found in:** multiple real communities' export/payment/ranking workflows — named explicitly in each
community's own product-doc correction note as a bug never to repeat.

---

## 5. A workflow with no creation path anywhere can never come into existence beyond its seed data

**Requirement shape:** a doc requires a "change path"/"update preference"/similar ongoing-editable surface
for a workflow whose fields are all `writableBy: "effect"` (not user-editable via a form).

**Looks plausible, is wrong:** seeding 1-2 example instances and assuming that's sufficient, with no
`renderBindings[].actions[].kind: "create"` anywhere and no `createInstance` effect anywhere else in the
package targeting this type. The real validator's `no_creation_path_for_editable_type` rule only fires for
types declaring `formEntry`-writable fields — an all-`effect`-writable type (common for
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

**Found in:** a real community's donor-visibility-preference workflow had zero creation path (two seeded
rows standing in for a missing affordance); fixed by wiring its donation-payment workflow's `pay` transition
to create a real per-donation preference row.

---

## 6. Choose the tightest correct `visibility`/`readGuard` scope available — don't default to a looser one when a sibling type in the same package already shows the tighter pattern working

**Requirement shape:** a doc explicitly excludes one persona from seeing a workflow's data ("only sees the
transfer's own scope, never the source community's unrelated internal data").

**Looks plausible, is wrong:**
```jsonc
"visibility": { "default": "membersOnly" }
```
`membersOnly` means "any signed-in, active-status account for this community" (`07-workflow-grammar.md`) —
it does **not** distinguish between personas. If a persona the doc explicitly wants excluded (e.g. a
receiving-provider persona who should only see their own transfer, never the exporting owner's other
records) counts as a community "member" for this purpose, `membersOnly` silently leaks every instance to
them.

**Verified-correct shape:** use `guarded` + an explicit persona allowlist that deliberately omits the
excluded persona:
```jsonc
"visibility": { "default": "guarded",
                "readGuard": { "allowedPersonaIds": ["community-owner", "community-member"] } }
```
Before picking `membersOnly` for any workflow with a doc-stated visibility exclusion, check whether a
sibling workflow in the *same package* already uses `guarded` + `readGuard.allowedPersonaIds` correctly for
a similar need — if so, that's the mechanism to reuse, not a looser default.

**Found in:** a real data-portability-themed community's export-package workflow used `membersOnly`
(leaking to an excluded receiving-provider persona) while a sibling transfer workflow in the same package
already correctly used `guarded` + a `readGuard` excluding that exact persona — the tighter pattern was
available and unused.

---

## Known current engine limitations to design around (not "solved" — check current status before relying on either)

These are real, confirmed gaps in the App Shell's implementation of documented grammar, not JSON-authoring
mistakes — no JSON-level fix exists for either until the underlying engine fix lands. If you have no way to
check current status (no repo access), treat both as still-open risks and name them in your Gaps section
whenever a requirement depends on either.

- **A shared calendar-detail widget may hardcode a literal `event-rsvp`/`event-rsvp-response` workflow-type
  string** instead of reading each community's own response-table binding. Since no real community names
  its event workflow type literally `event-rsvp`, per-member RSVP action buttons may not populate correctly
  for a custom-named event/response pair — which is every real community. If this is still unfixed, name it
  explicitly in your Gaps section for any `event-rsvp`-shaped workflow rather than assuming it works.
- **A `create` action's `prefill` may never resolve `$actor`, and `scope: "tab"` creates may drop `prefill`
  entirely.** The grammar documents `prefill` as using "the effect interpolation grammar plus `{context.*}`"
  (i.e. `$actor`/`$timestamp` should work), but this has been found not implemented for either creation
  scope in at least one real build. `"prefill": {"ownerPersonaId": "$actor"}"` on a `scope: "tab"` create
  action — the standard pattern for stamping an effect-only ownership field at creation — may produce an
  instance with that field absent or the literal string `"$actor"`, either of which breaks every
  `actorEqualsField` guard/readGuard keyed on it. This is the highest-blast-radius gap found so far, since
  the pattern is used by nearly every "member creates their own X" workflow. If you cannot confirm this is
  fixed, name it explicitly in your Gaps section for any workflow using `$actor` in a create action's
  `prefill`.
