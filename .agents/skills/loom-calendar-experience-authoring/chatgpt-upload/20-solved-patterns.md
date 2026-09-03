---
spec: 4
doc_version: 1.6.0
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
  "guard": { "actorEqualsField": { "key": "ownerFanId" } } }
```
Only the owner is checked. But `availabilityState` (available/requested/reserved/onLoan) is **orthogonal
data**, not a separate FSM state (per AP-1) — so the item can still be `published` while actively on loan,
and this guard lets the owner delist it out from under an active borrower, stranding the loan with no
return path.

**Verified-correct shape:**
```jsonc
{ "id": "delist", "from": ["published"], "to": "delisted",
  "guard": { "actorEqualsField": { "key": "ownerFanId" },
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
individual identity (a real `fanId`), not a free-text name, so check the community's persona model
first (see pattern 6 below).

**Found in:** Chess Club's `chess-pairing-queue` — the first authoring pass used N separate instances,
silently dropped "waiting players see queue position," and justified the drop with a claim (no admin-tab
access for the waiting persona) that a `grep` of the package's own `audience: "any"` binding directly
contradicted. Redesigned to the shared-container shape above.

---

## 3. Admin-created, member-received objects need `audience: "any"` + `visibility.readGuard`, never `audience: "actor"`/`"receiver"`

**Requirement shape:** an admin/organizer publishes an announcement or sends a notification; a member
receives and reads it.

**Looks plausible, is wrong:**
```jsonc
{ "states": ["sent"], "audience": "receiver", "tabId": "home", ... }
```
On every tab except `admin`, `"receiver"` does not resolve the way its name suggests — it does not mean
"whoever should receive this." Per `render-bindings.md`'s documented trap, non-`admin` tabs can only
reliably resolve `audience: "any"`; `"actor"`/`"receiver"` are creator-only semantics that produce a
permanently dead card for anyone who isn't the literal `createdByFanId`. Since the admin created the
announcement, a member's `home` tab binding using `"receiver"` never shows them anything.

**Verified-correct shape:**
```jsonc
"visibility": { "default": "guarded",
                "readGuard": { "formula": "$viewer == recipientFanId || $viewer == 'community-admin'" } },
"renderBindings": [
  { "states": ["sent"], "audience": "any", "tabId": "home", "cardSurfaceFamily": "notificationInbox", ... }
]
```
`audience: "any"` makes the card visible to everyone the binding's tab reaches; real per-recipient privacy
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
      "fields": { "donorFanId": "{donorFanId}", "fund": "{fund}", "amountLabel": "{amountLabel}" } }
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
                "readGuard": { "allowedRoleIds": ["portability-owner", "portability-member"] } }
```
Before picking `membersOnly` for any workflow with a doc-stated visibility exclusion, check whether a
sibling workflow in the *same package* already uses `guarded` + `readGuard.allowedRoleIds` correctly for
a similar need — if so, that's the mechanism to reuse, not a looser default.

**Found in:** Data Portability Community's `export-package` used `membersOnly` (leaking to the Receiving
Provider persona) while the same package's `export-transfer`/`export-transfer-rollback` already correctly
used `guarded` + a `readGuard` excluding that exact persona — the tighter pattern was available and unused.

---

## 7. Stamp actor-identity fields via an effect on the workflow's own first transition — an equally valid alternative to `$actor` in create-action `prefill`

**Requirement shape:** a self-created instance needs its owner/actor field
(`ownerFanId`/`memberFanId`/`authorFanId`) populated with the real creating persona, for later
`actorEqualsField` guards/`readGuard`s to work.

**Also correct today (CJM.6 fixed, 2026-08-10):**
```jsonc
"actions": [{ "kind": "create", "scope": "tab", "prefill": { "ownerFanId": "$actor" } }]
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
             "editGuard": { "allowedRoleIds": ["ad-off-member"] } }
},
"transitions": [
  { "id": "start-checkout", "from": ["offer"], "to": "reviewing",
    "guard": { "allowedRoleIds": ["ad-off-member"] },
    "effects": [
      { "op": "set", "key": "memberFanId", "value": "$actor" },
      { "op": "set", "key": "priceLabel", "value": "{priceLabel}" }
    ] }
]
```
Two consequences to design around: (1) the un-stamped field must not be `required: true` (it's genuinely
absent for the brief window between creation and the first transition firing), and (2) any guard/`readGuard`
that would check the field on the pre-stamp state must fall back to `allowedRoleIds` only (there's
nothing to check `actorEqualsField` against yet) — a state-level `readGuard` override on that one state
(`workflow-grammar.md`'s per-state `readGuard`, IMPLEMENTED) keeps the creator able to see their own
just-created, not-yet-stamped instance if the workflow-level `visibility` is `guarded`.

**Found in:** Ad-Free Community's `ad-off-member-checkout`/`ad-off-community-checkout` — discovered via a
Skill Retrospective while CJM.6 (above) was still an open engine bug; the same authoring agent worked out
this fix itself when asked what it could have done differently. Kept in this bank as a valid alternative
even after CJM.6 landed — both mechanisms work today, use whichever fits the workflow's shape better.

---

## 8. Every non-`home`/`messages` `tabId` used anywhere in `renderBindings` needs a matching `appShell.tabs[]`/`roleTabs[]` declaration — omitting it entirely is easy when focused on workflow content

**Requirement shape:** a workflow's `renderBindings[].tabId` names a tab (e.g. `"calendar"`, `"organize"`,
`"documents"`) that isn't `home`/`messages`. `tabId` is an open vocabulary — any name is valid — but every
value used anywhere in the package must have a corresponding entry in the top-level `appShell.tabs[]`
array (or `roleTabs[]` for a persona-scoped tab), or the validator rejects it with `unknown_tab_id`.

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
bespoke renderer. See `render-bindings.md`'s `appShell.tabs[]` / `roleTabs[]` — tab declaration shape`
section for the complete field list.

**Self-check step to add, explicitly:** before finishing, grep your own draft for every distinct
`renderBindings[].tabId` value across every workflow, then confirm each one (other than `home`/`messages`)
has a matching `appShell.tabs[]`/`roleTabs[]` entry. Do this as a literal list-comparison step, separate
from validating each `renderBindings` entry in isolation — the two checks catch different failure modes.

**Found in:** Garden Club, re-authored via the Codex GitHub-fetch dispatch channel 2026-08-12 (Milestone
1.5 of `TabId-Archetype Gap Closure.md`) — the fresh output correctly used `calendar`/`marketplace`/
`organize`/`documents`/`care` as tabIds across its workflows, but emitted no `appShell` block at all,
producing 15 `unknown_tab_id` errors on first validation. The currently-shipped fixture for the same
community already gets this right (`appShell.tabs[]` with 3 declared tabs), confirming the gap was in this
one dispatch's output, not a documentation gap in `render-bindings.md` itself (which already documents the
requirement correctly) — the missing piece was reinforcement at the point of final self-check.

---

## 9. When updating an existing, already-shipped community, reuse its real `roleId`/`tabId` values exactly — never re-derive plausible-looking ones from the product doc's own prose

**Requirement shape:** the target is an update to a community that already has a real, committed JSON
package — adding a new archetype, workflow, or field to something that already exists, not authoring a
community from nothing. Every authoring channel of this Skill deliberately never sees the existing shipped
file while drafting (the in-repo `Agent`-tool channel is explicitly forbidden from reading it, and the
zero-tool-access/Codex channels have no mechanism to see it at all) — so the fresh draft has no way to know
what identifiers the shipped file, or any real committed test that hardcodes those identifiers, already
expect.

**Looks plausible but is wrong:** deriving `roleId`/`tabId` values fresh from the product doc's own
vocabulary — reasonable-sounding, internally consistent, and structurally valid, but silently different from
the identifiers the currently-shipped file and its tests actually use. The JSON validates cleanly in
isolation; the defect only surfaces as a broken Dart test, or a broken guard/formula reference, once the new
file replaces the old one — something no JSON-only validator run or self-check can catch.

**Verified-correct shape:** the dispatching session (never the authoring agent itself) reads the currently-
shipped fixture directly and supplies its real `roles[]` and `appShell.tabs[]` values as an explicit
`## Existing identifiers — preserve these exactly` section appended to the target product doc, listing each
`roleId`/`label`/`roleLabel` and `tabId`/`label` pair. The authoring agent reuses every listed value
exactly, and only introduces a genuinely new identifier when the requirements need one beyond what's listed
— stated explicitly as such, not silently substituted for an existing one. This is supplying a fact about
already-shipped state, not letting the agent "cheat" by reading a comparison artifact to copy an answer from
— the distinction the original no-existing-file rule protects is about not reading the *comparison target
for judging purposes*, not about identifiers that are already load-bearing, real, and non-negotiable.

**Found in:** Masjid Nur, re-authored via the Codex GitHub-fetch dispatch channel 2026-08-12 (Milestone 1.5)
— the fresh output invented `mosque-admin`/`mosque-member` (the real, shipped ones are `masjid-admin`/
`community-member`) and added a `care` tab that
`app/packages/core/loom_communities_app_shell/test/cjm8_engine_native_tabs_test.dart` explicitly asserts
must never appear for `ext_mosque`. Caught by an independent Skill Output Judge dispatch, not the validator
(which reported the JSON as structurally clean) — this class of defect is invisible to any check that only
inspects the candidate JSON in isolation.

---

## 10. A `documentLibrary` workflow defaults to `membersOnly` visibility with list-based access tracking — never a required singular `recipientFanId` behind a `guarded` default

**Requirement shape:** a community's documents/resources need to be readable by the general membership, with
only a minority genuinely access-restricted (e.g. a leadership-only policy doc). The product doc almost
always names this as an anti-pattern to avoid directly ("hidden document link," "documents should be
findable, not buried").

**Looks plausible but is wrong:** modeling every document as a single-recipient row —
`recipientFanId: { "type": "fanId", "required": true }` plus `"visibility": { "default": "guarded",
"readGuard": { "formula": "$viewer == recipientFanId || ..." } }`. This looks like careful, privacy-
conscious modeling, but a *required, singular* recipient field makes it structurally impossible to author a
document instance visible to the general membership at all — every document, even a routine weekly notice,
ends up hidden from everyone except one hand-picked persona. This is the exact anti-pattern the product doc
warns against, reintroduced through the back door of "protecting" a field that was never meant to gate
routine content.

**Verified-correct shape:** default the workflow to `"visibility": { "default": "membersOnly" }` (the same
default nearly every other workflow in this grammar uses), and track access/acknowledgement as **list**
fields on one broadcast row, not a per-recipient gate on visibility itself:
```jsonc
"visibility": { "default": "membersOnly" },
"instanceDataSchema": {
  "acknowledgedFanIds": { "type": "fanId[]", "writableBy": "effect" },
  "accessRequestedFanIds": { "type": "fanId[]", "writableBy": "effect" }
}
```
Reserve a `guarded`/`readGuard` visibility override only for the genuinely small minority of documents that
need real access restriction (e.g. a board-only financial record), and even then prefer a role-based guard
(`allowedRoleIds`) over a single required recipient, so the common case — most documents, visible to most
members — is never gated behind an easy-to-drop identity match.

**Found in:** Masjid Nur, 2nd Milestone 1.5 dispatch (Codex GitHub-fetch channel, 2026-08-12) —
`mosque-document-resource` used the required-singular-recipient shape above, confirmed by an independent
Skill Output Judge to make every document invisible to the general membership by construction, contradicting
the product doc's own stated anti-pattern. The currently-shipped fixture for the same community already
proves the correct shape works (`membersOnly` default + `acknowledgedFanIds`/`accessRequestedFanIds`
list fields) — the fresh dispatch regressed away from an already-working pattern it had no visibility into.

---

## 11. A `searchAiAnswer` (or any workflow with a real, unimplemented platform-service field) still needs at least one live, reachable path to its "complete" state — never leave every path to it gated on the missing service alone

**Requirement shape:** a workflow's terminal/complete state (e.g. "answered," "verified," "exported") depends
conceptually on a platform service that is honestly `❌ Not implemented` (an AI-generated answer, a checksum,
a receipt ID) — see `platform-services.md`. The field the missing service would populate must never be
seeded or effect-written (AP-6) — that part is already well understood and consistently done correctly.

**Looks plausible but is wrong:** making the *only* transition into the complete state require that missing
field to already be populated (e.g. a guard like `"formula": "if(answer == null, false, true)"`), with no
other transition anywhere in the workflow that can set it. This correctly avoids fabricating the missing
service's output, but it also makes the state **permanently unreachable by any live action** — not "honestly
blocked pending a platform service" but a structural dead end no future platform-service launch alone would
even fix, since nothing ever calls the transition that would consume it. A demo, a screenshot, or a B25
UX-evidence pass can never show this state working, even in principle, until the JSON itself changes again.

**Verified-correct shape:** give the workflow a second, real, honest path to the same terminal-ish state that
doesn't depend on the missing service — typically an admin/coordinator-curated equivalent, clearly labeled as
such, not disguised as the automated version:
```jsonc
{
  "id": "answer-query", "label": "Provide answer",
  "guard": { "allowedRoleIds": ["<admin-persona>"] },
  "inputs": {
    "answerBody": { "type": "text", "required": true },
    "citationLabel": { "type": "text", "required": true },
    "citationUrl": { "type": "text", "required": true }
  },
  "effects": [
    { "op": "set", "key": "answerBody", "value": "{input.answerBody}" },
    { "op": "set", "key": "citations", "value": [{"label": "{input.citationLabel}", "url": "{input.citationUrl}"}] }
  ]
}
```
This is not a fabrication — the *value itself* is real, human-authored content, just not the AI-generated
answer the field's name might suggest; label it as admin-curated in the UI copy if the grammar allows. Only
the automated/AI computation path stays genuinely absent.

**Found in:** Masjid Nur, 2nd Milestone 1.5 dispatch — `mosque-search-ai-citation`'s only path to "answered"
required the never-written `answer` field to already be non-null, confirmed unreachable by grep (zero
effects write `answer` or `citations` anywhere in the package) and by the candidate's own traceability row
marking the requirement `not_implemented`. The currently-shipped fixture already had a working
admin-curated-answer transition with real inputs/effects; the fresh dispatch regressed away from it without
knowing it existed.

---

## 14. Pattern 11's fix does NOT apply to `checksum`/integrity-hash fields — there is no honest curated substitute for one, so `exportWizard` completion must never be gated on it at all

**Requirement shape:** an `exportWizard` workflow's completion/transfer transitions (e.g. `confirm-export-
ready`, `start-export`, `start-transfer`, `record-platform-verification`) conceptually depend on a checksum
that verifies the export's integrity — `checksum`/`checksumVerified`/`checksumStatus` are honestly declared
and correctly never seeded or effect-written per AP-6, matching pattern 4 and pattern 11's own first half.

**Looks plausible but is wrong — this is a different failure shape from pattern 11's, not the same one:**
applying pattern 11's fix literally, by reasoning "just add a second, admin-curated path to the gated
field." **That fix does not work for a checksum the way it works for a search answer.** A search answer is
legitimately human-authorable content — an admin genuinely can write a real answer by hand, so a
`provide-curated-answer`-style transition produces a real, honest value. A checksum is a deterministic,
verifiable computation over the actual export bytes — nothing in this grammar can compute one, and an admin
typing an arbitrary string into `checksum` is not "curating" anything, it is fabricating exactly the value
AP-6 forbids. There is no honest curated substitute. Confirmed as a real, recurring defect, not a one-off:
**both Garden Club's and Cedar Commons HOA's already-committed Milestone 1.5 fixtures gate their export
completion path on `checksumVerified`/`checksum == null → false`, making `ready`/`transferring`/`transferred`
permanently unreachable** — the exact structural dead end pattern 11 warns about, but pattern 11's own
suggested fix cannot close it here.

**Verified-correct shape:** do not gate completion on the checksum field at all. The export flow should
reach its real completion state (`generated`/`ready`/`transferred`, whatever the workflow calls it) purely
on the conditions genuinely within the actor's control (e.g. `size(exportScope) > 0`, a required redaction-
preview step, an organizer/owner guard) — leaving `checksum`/`checksumVerified` visibly, honestly unset
forever, exactly like `receiptId`/`transferId` already are, rather than treated as a hard precondition:
```jsonc
{
  "id": "generate-export", "from": ["ready"], "to": "generated",
  "guard": { "allowedRoleIds": ["<organizer-persona>"], "formula": "size(exportScope) > 0" },
  "effects": [
    { "op": "set", "key": "generatedAt", "value": "$timestamp" },
    { "op": "set", "key": "statusMessage", "value": "Export generated; checksum pending platform verification" }
  ]
}
```
The status message honestly communicates the gap without blocking the actual capability. If a workflow
*also* has a genuinely separate verification step (e.g. Cedar Commons HOA's `record-platform-verification`),
that specific step may stay checksum-gated and simply remain unreachable — that's an honest, narrower gap on
one optional sub-step, not the whole export capability.

**Found in:** Chess Club's Milestone 1.5 dispatch got this right independently (`generate-export`'s guard has
no checksum dependency) and was judged clean on exactly this point. Garden Club and Cedar Commons HOA (both
Milestone 1.5, already committed before this pattern was identified) got it wrong — found via an independent
Skill Output Judge reviewing Neighborhood Book Club's 2nd dispatch, which reproduced the same shape and
correctly flagged it as a severe, validator-invisible defect (the `destructive_transition_ignores_
availability_field` warning check only looks at destructive transitions skipping a guard a sibling
transition has; it does not detect "this state is now permanently unreachable," a different failure entirely
that no automated check in this pipeline catches). Garden Club and Cedar Commons HOA both need a follow-up
fix.

---

## 12. Don't add a "provider/import reviewer" (or similar) persona from §7 prose alone — that phrase is templated boilerplate shared across multiple, unrelated communities' product docs, not a per-community requirement

**Requirement shape:** a community's export/portability workflow (`exportWizard`) has a §7 requirements row
containing prose like *"provider/import reviewer sees status and a real (non-fabricated) verification
value"* or *"...sees checksum and redaction status."*

**Looks plausible but is wrong:** treating that sentence as evidence this specific community needs a new,
dedicated reviewer/provider persona, and adding one (e.g. `chess-export-reviewer`, `garden-import-reviewer`)
not present in the community's own `## Existing identifiers` list or its §2 persona table. This phrase is
**boilerplate carried over from the Data Portability Community template**, which genuinely does have a
distinct "Receiving Provider" persona (`portability-receiving-provider`) — but it appears **verbatim,
unchanged**, in at least Garden Club's, Neighborhood Book Club's, and Chess Club's product docs too, none of
which have any such persona in their own §2 table or existing shipped fixture. Confirmed twice independently
(Garden Club's 1st Milestone 1.5 dispatch, Chess Club's 2nd) — both added an unrequested reviewer persona
from this exact phrase, in each case contradicted by that community's own §2 persona list and by the
explicit "only add a new persona if the existing set doesn't already cover the need" instruction.

**Verified-correct shape:** check whether §2's own persona table already names a distinct provider/reviewer
role before adding one. If it doesn't, the export/transfer status is meant to be visible to the community's
existing member persona (e.g. `chess-member`, `garden-member`) — a `readGuard`/`visibility` scoped to that
existing persona (plus the owning admin/coordinator) is correct, no new persona needed. Only add a dedicated
reviewer/provider persona for a community whose §2 table genuinely lists one — Data Portability Community is
the one real, confirmed case (`portability-receiving-provider`, a distinct destination-system role its own
workflow, `mosque-donor-visibility`-equivalent for the export domain, is actually built around).

**Found in:** Chess Club, 2nd Milestone 1.5 dispatch (Codex GitHub-fetch channel, 2026-08-12) — added
`chess-export-reviewer`, contradicted by the community's own §2 table (Organizer, Player only) and by its
own currently-shipped fixture, which never acted on the identical §7 phrase. Caught by an independent Skill
Output Judge dispatch, which additionally confirmed the exact same phrase appears unchanged in Garden Club's
and Neighborhood Book Club's product docs — establishing this as boilerplate, not a per-community signal.

---

## 13. Templated §7/§9 language can justify a whole unrequested *feature*, not just an unrequested persona — always cross-check against the workflow's own §5/§6 rows and against the currently-shipped fixture's own prior reasoning

**Requirement shape:** a product doc's B25/§9 addendum row uses generic, evaluation-boilerplate phrasing
for a workflow type — e.g. "member evaluates a concrete message, connection, or invite with sender/recipient
context and accept/decline/block paths." Pattern 12 already covers this phrasing inventing an unrequested
*persona*; this pattern covers the same root cause producing an unrequested *subsystem* on an existing
workflow instead.

**Looks plausible but is wrong:** building the full invite/accept/decline/cancel/block machinery the
boilerplate describes onto a workflow whose own specific requirement rows (§5/§6/§7, in the workflow's own
words) never ask for it — e.g. adding a connection-request system to what the doc's own prose describes as
"a plain club discussion thread." The boilerplate phrasing appears **verbatim, unchanged, across multiple
unrelated communities' product docs** (confirmed: the same B25 addendum sentence appears on four different
workflow rows in Member Social Space's product doc alone), so its presence is not evidence of a
community-specific requirement. Worse, this class of over-build is exactly what triggers
`destructive_transition_ignores_availability_field`-style validator warnings on the new, unrequested
transitions — masking the real defect (unrequested scope) behind what looks like a missing-guard bug.

**Verified-correct shape:** before implementing a §7/§9 row's requirement literally, check two things: (1)
does this workflow's own §5/§6 description (the community's specific, non-templated prose) actually ask for
this capability, and (2) does the currently-shipped fixture already have reasoning — often left as an
explicit code comment — for *not* building it. If the shipped fixture already declined this exact capability
with a stated reason ("the B25 addendum's generic invite/connect/block phrasing does not match this
workflow's own §5/§6/§7 rows"), that reasoning is a real, already-verified finding — reproduce the shipped
fixture's simpler design rather than re-deriving and re-introducing the same over-build a prior authoring
pass already caught and rejected.

**Found in:** Neighborhood Book Club, 1st Milestone 1.5 dispatch (Codex GitHub-fetch channel, 2026-08-12) —
`book-discussion-message` gained a full `send-invite`/`accept-invite`/`decline-invite`/`cancel-invite`
subsystem with `invitationStatus`/`participantFanIds` fields, sourced from the same generic B25 addendum
phrasing already confirmed as cross-community boilerplate. The currently-shipped fixture had already declined
to build this, with an explicit comment stating why. Caught by an independent Skill Output Judge dispatch,
which traced the two `destructive_transition_ignores_availability_field` validator warnings on this
community back to the unrequested subsystem as their root cause, not a missing guard to patch.

---

## 15. A formula-computed reminder **converts** to a `reminder` block — deleting it removes a capability, and nothing in the validator will tell you

**Requirement shape:** an already-shipped package reminds members before an event the old way — a
`reminderAt` field carrying a formula, plus a member- or admin-chosen offset field that formula reads.
The grammar has since replaced that idiom with a declared workflow-level `reminder` block.

**Looks plausible, is wrong:**
```jsonc
// Both fields deleted: the sweep ignores a formula-computed reminder, and once
// the formula is gone nothing reads the offset either. Therefore -- dead code?
"instanceDataSchema": {
  "eventDate": { "type": "date", "required": true, "writableBy": "formEntry" },
  "eventTime": { "type": "time", "required": true, "writableBy": "formEntry" }
  // reminderAt: removed.  reminderOffsetHours: removed.
}
```

The diagnosis is right and the repair is not. The sweep really does ignore `reminderAt`, and the
offset really is unread once the formula goes. But *"this data is dead"* is a fact about the wiring,
never about the product. The doc still promises the capability — Garden Club's B25 row for
`garden-event-rsvp` requires a visible reminder affordance, and its §5 row says
`recurrence/reminder` — so the package now owes something it cannot deliver.

**The validator will not catch this.** Removing both fields makes every finding go away: zero errors,
warnings *down*, every identifier and workflow preserved. A package that quietly lost a feature and
one that correctly gained a wire produce identical reports, because the validator counts what is
declared and only the product doc says what is owed.

**Verified-correct shape** — keep the offset, delete only the formula, declare the block that
consumes it:
```jsonc
"reminder": {
  "anchorDateField": "eventDate",
  "anchorTimeField": "eventTime",
  "leadHoursField": "reminderOffsetHours",  // the field that already exists
  "leadHours": 24                           // its default when unset
},
"instanceDataSchema": {
  "eventDate": { "type": "date", "required": true, "writableBy": "formEntry" },
  "eventTime": { "type": "time", "required": true, "writableBy": "formEntry" },

  // KEPT. Someone's choice of how far ahead they are reminded; consuming it is
  // the block's entire purpose. It also rides along through recurrence, so
  // deleting it silently changes every generated instance in the series.
  "reminderOffsetHours": {
    "type": "number", "required": true, "writableBy": "formEntry",
    "storage": "inline", "displayIcon": "notifications_active",
    "labelTemplate": "Default reminder: {value} hours before",
    "displayContexts": ["detail"]
  }

  // GONE: "reminderAt" -- the platform resolves the instant now, in one place,
  // with a timezone the formula language never had.
}
```

The conversion is a net gain, which is the tell that it is the right move: a display no mechanism
consumed becomes a reminder the sweep actually fires.

**The general rule this is an instance of:** dead data is a missing wire, not an unwanted feature.
Before removing any field nothing writes or reads, check the product doc. If the doc promises the
capability that field served, connect it — name its real writer, or declare the block that consumes
it. Remove it only when nothing in the doc asks for anything it could serve, and say so explicitly in
Gaps/assumptions when you do.

**Found in:** Garden Club (`garden-event-rsvp`), 2026-08-27 — a regeneration that passed the
validator cleanly and had deleted `reminderAt` and `reminderOffsetHours`. Caught by diffing the
returned package against the shipped one field-by-field, not by any check in the pipeline. Cedar
Commons HOA (`hoa-facility-reservation`) is the same conversion done correctly, and is worth reading
next to this.

---

## 16. A field written by a create-action `prefill` is `writableBy: "platform"` — not `effect`, not `formEntry`, not omitted

**Requirement shape:** a workflow stamps the creator's identity or a starting value at creation time,
through the create action's `prefill`:
```jsonc
"prefill": { "ownerFanId": "$actor", "mode": "loan", "conditionState": "good" }
```

**Looks plausible, is wrong** — all three of these appear in the shipped corpus for exactly this shape:
```jsonc
"ownerFanId": { "type": "text", "writableBy": "effect" }     // no effect writes it
"ownerFanId": { "type": "text", "writableBy": "formEntry" }  // no member types it
"ownerFanId": { "type": "text" }                             // something does write it
```
`effect` is the corpus's dominant convention here and it is a false claim — the validator reports it
as `effect_writable_field_has_no_effect`, because prefill is not an effect. Reading that finding as
"so nothing writes it" and dropping `writableBy` altogether trades one false statement for another.
`formEntry` is the worst of the three: it says a member types their own `ownerFanId`, which is an
identity field.

**Verified-correct shape:**
```jsonc
"prefill": { "ownerFanId": "$actor", "mode": "loan" },

"ownerFanId": { "type": "text", "writableBy": "platform" },
"mode":       { "type": "text", "writableBy": "platform" }
```
The platform's create action stamps the value. That is what `platform` means, and it is the only one
of the four that is true.

**Be clear about what this does and does not fix.** With any of the wrong values the package still
behaves correctly today, because a field is editable only when a state lists it in `editableFields`,
and these fields are not listed — the engine checks membership there *before* it looks at
`writableBy`, so neither the form nor the API will accept an edit either way. This is a correctness
and consistency fix, not a live defect: the declaration should state what actually happens, one
authoring pass should not answer it differently from the next, and `formEntry` on an identity field
is a claim that becomes dangerous the moment someone adds that field to `editableFields`.

**Found in:** Garden Club and Neighborhood Book Club, 2026-08-27 — the same shape, in two packages
regenerated hours apart, answered `formEntry` in one and omitted in the other. Two different guesses
for one question is the signal that the grammar had not answered it.

---

## 17. Regenerating a shipped package is a **revision**, not a rewrite — and the validator cannot tell the two apart

**Requirement shape:** an already-shipped community package needs a specific, bounded change — a
writer declaration corrected, a reminder converted, a field renamed.

**Looks plausible, is wrong:** author the package fresh from the product doc, apply the change, and
return the result. It validates, so it must be right.

Here are three runs of one community for one bounded requirement, every one of them
`status: pass`, zero errors:

| Run | Bytes | Lines | Comments | Longest line | What it actually was |
| --- | ---: | ---: | ---: | ---: | --- |
| shipped | 105,220 | 3,007 | 15 | 213 | the baseline |
| r2 | 104,903 | 2,998 | 15 | 213 | a revision — one field removed, on purpose |
| r3 | 70,756 | 418 | 6 | 1,262 | a rewrite wearing a revision's name |

r3 made the requested writer corrections **and** reformatted the file compactly, dropped nine of the
fifteen authored comments, deleted a member's `contactInfo` in favour of an invented `contactMethod`,
and removed two `coordinatorFanId` fields nobody had asked about. Every one of those is invisible in
a validation report, because the validator checks that a package is well-formed and self-consistent —
which a rewrite very much can be.

**Verified-correct shape:** treat the shipped package as the base text and change only what the
requirement implicates.

- Keep the existing formatting exactly — indentation, line breaks, key order. A package that arrives
  reflowed cannot be reviewed, because every line reads as changed.
- Keep every authored comment. They were written by someone explaining a decision, and they are the
  first thing lost in a rewrite and the last thing anyone notices missing.
- Do not touch a field the requirement does not name. Renaming `contactInfo` to `contactMethod` while
  fixing checksum writers is a second, unrequested change riding along inside the first.
- The diff is part of the deliverable. If it cannot be read line by line and every hunk traced to the
  requirement, the change is not finished, however green the validator is.

**Found in:** Garden Club, 2026-08-27, across three consecutive runs of the same requirement. r2 is
the shape to copy; r3 is the shape to avoid. The tell was not the validator — it was `wc -l`.

---

## 18. A tab's audience is **declared**, never inferred from who happens to hold a transition

**Requirement shape:** a community has a tab not everyone should see (an admin or organiser surface),
and a tab everyone should see that only some roles can act on (a public leaderboard, a read-only
document shelf).

**Looks plausible, is wrong:** declare the tabs, guard the transitions, and let visibility fall out.
It appears to work — an `admin` tab whose every transition is `allowedRoleIds: ["organizer"]` really
is hidden from members, because the App Shell derives tab access from transition guards
(`roleHasPermission`).

It works by accident, and it fails in both directions.

*Too hidden.* A workflow that declares `visibility: {"default": "public"}` and whose transitions are
all admin-only is **readable by everyone and visible to no one**. Chess's `chess-rankings-table` is
exactly this: a public ladder its own product doc requires the Player persona to see, hidden from
players because only organisers can publish to it. Nothing in the package looks wrong. The tab is
simply absent.

*Too exposed.* The moment anyone adds a read-only surface to an admin tab, or relaxes one guard, the
tab appears for roles nobody intended. The restriction was never stated, so nothing protects it.

**Verified-correct shape:** say who the tab is for.

```jsonc
"appShell": { "tabs": [
  { "tabId": "admin",    "label": "Admin",    "visibleRoleIds": ["chess-organizer"] },
  { "tabId": "rankings", "label": "Rankings" }   // no restriction: everyone sees it
]}
```

Nine of the ten shipping communities already do this — Ad-Free `admin: ["ad-off-owner"]`, Book Club
`["book-organizer"]`, Cedar and Youth Soccer on five and six tabs each. Chess declares none at all,
which is why it is the community where the defect surfaced.

**Where the audience comes from.** Every product doc has a §3.1 persona table with a *Required tabs*
column. Read it — but read it as a **lower bound, not an exclusive list**. Chess's table names
Rankings under Player and not under Organizer, and organisers plainly need it: §2 lists "publish
rankings" among their duties. A tab absent from one persona's required list is not thereby forbidden
to them. Restrict a tab only where the doc actually says it is restricted, and when the doc does not
settle it, declare no restriction and say so in Gaps rather than inventing one — an over-restricted
tab is as much a defect as an exposed one, and much harder to notice.

**Found in:** Chess Club, 2026-08-28. Surfaced when an implementation agent refused to change a demo
test to match the broken behaviour, calling that manufactured evidence. Worth noting what did *not*
find it: the package validates clean, and every structural diff passes, because a missing
`visibleRoleIds` is an absence and nothing counts absences.

---

## 19. A workflow-level `reminder` block does **not** replace a member-owned reminder on a response row

**Requirement shape:** an event workflow with per-member RSVP rows, where each member can set their
own reminder — their own lead time, or their own due time and notification text.

**Looks plausible, is wrong:** declare a `reminder` block on the parent event and delete the
member-owned reminder transition, on the reasoning that reminders are declared now.

```jsonc
// parent event
"reminder": { "anchorDateField": "eventDate", "anchorTimeField": "eventTime", "leadHours": 24 }
// and the response row's own set-reminder / send-reminder transition: deleted
```

The two are different capabilities and only one of them is per-member. A block on the parent produces
**one** reminder derived from **one** instance's anchor fields — every attendee gets the same 24
hours. The transition on the response row let each member choose. Replacing the second with the first
looks like a modernisation and is a quiet downgrade: nothing fails, the validator is clean, and every
member silently loses a setting they had.

**Verified-correct shape:** they coexist. Keep the member-owned transition; add the block only if the
*event itself* also needs a reminder.

```jsonc
// response row — per member, unchanged
{ "id": "set-reminder", "action": "deliver_reminder", "label": "Add reminder",
  "guard": { "actorEqualsField": { "key": "fanId" } },
  "inputs": { "dueAt": {...}, "notificationTitle": {...}, "notificationBody": {...} },
  "effects": [ { "op": "createInstance", "workflowType": "<community>-notification",
                 "fields": { "recipientFanId": "{fanId}", "dueAt": "{input.dueAt}" } } ] }
```

That is the **materialised notification** path, and `workflow-grammar.md`'s reminder section says in
as many words that it is unaffected by the move away from formulas: a stored `dueAt` an effect writes
outright is data, not calculation, and the sweep honours it. What the formula drop retired was a
`dueAt` computed by a formula — not a member's ability to schedule one.

**Before deleting any reminder transition, ask which instance owns the choice.** If the answer is
"each member, on their own row", a parent block cannot express it and deleting the transition removes
the feature.

**Found in:** Neighborhood Book Club, 2026-08-28 — `book-meeting-rsvp-response.send-reminder`
(`action: "deliver_reminder"`, guarded on `actorEqualsField: fanId`, taking the member's own `dueAt`,
title and body) was removed and a parent block added in its place. It shipped. Caught afterwards by a
verifier that compares transition sets, not by the validator, which was clean throughout. Camera Club
was about to receive the identical change and its product doc §119–129 argues explicitly for the
per-member design — worth reading, because it reasons the case out.

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
  `"prefill": {"ownerFanId": "$actor"}"` is a safe, working pattern again. Independently re-verified via
  a dedicated Regression Impact Judge dispatch against every real consumer (Camera Club, Garden Club,
  Masjid Nur, Riverside Youth Soccer, Data Portability Community, Chess Club) — each traced individually
  against its own guards/readGuards and confirmed genuinely repaired, not just compiling. Pattern 7 (stamp
  via an effect on the first transition) remains a perfectly valid alternative and is what Ad-Free Community
  and Member Social Space already ship with — there's no need to retrofit them now that CJM.6 is fixed,
  since pattern 7 has no functional downside, but new workflows can use either `$actor`-in-`prefill` or
  pattern 7 going forward.

## 20. A platform-written field names **which** platform value it gets — and an id for something that never happened stays empty

`writableBy: "platform"` says a service writes the field. It does not say *which* service or *what
value*. For a **dispatched** value that difference is load-bearing — these two are byte-identical
apart from the field name, and the field name is exactly what must never be read for meaning:

```jsonc
// Indistinguishable. One wants a hash of bytes; the other wants a minted id.
"checksum":   { "type": "text?", "writableBy": "platform" },
"transferId": { "type": "text?", "writableBy": "platform" }
```

`platformSource` is the discriminator.

### Before — declared, and permanently unwritable

Taken from `DataPortabilityCommunity`, where the field carried a `NEEDS IMPLEMENTATION` comment and
no writer at all. It renders, it is never filled, and nothing in the JSON says why.

```jsonc
// NEEDS IMPLEMENTATION (platform service): opaque export transfer-ID generation is not implemented.
"transferId": {
  "type": "text?",
  "displayIcon": "confirmation_number",
  "labelTemplate": "Transfer: {value}",
  "hideWhenEmpty": true
}
```

### After — a named mechanism

```jsonc
"transferId": {
  "type": "text?",
  "writableBy": "platform",
  "platformSource": "opaqueId",
  "displayIcon": "confirmation_number",
  "labelTemplate": "Transfer: {value}",
  "hideWhenEmpty": true
}
```

The comment goes with it. A `NEEDS IMPLEMENTATION` note that outlives its implementation is worse than
no note, because the next reader trusts it and re-reports a closed gap.

### The counter-example that matters more

**Do not do this to a payment receipt.**

```jsonc
// WRONG. Payment processing is deferred, so nothing charges anyone.
"receiptId": { "type": "text?", "writableBy": "platform", "platformSource": "opaqueId" }
```

A minted id here is a confirmation number for a transaction that never happened. It is unique, it is
well-formed, it is displayed to a member as evidence of a payment — and no money moved. That is the
same failure as the old canned `checksum_<communityId>_<count>` string, which hashed nothing while
looking exactly like a checksum, except that this one looks like proof of money changing hands.

`receiptId`, `paymentConfirmationId` and `settlementId` stay **declared and unwritten** until payment
is real. Leave them exactly as they are: no `writableBy`, no `platformSource`, comment intact. An
empty field is a true statement about the world. **Prefer the absent value to the fabricated one** —
the same rule that governs checksums, for the same reason.

### How to tell which case you are in

Ask what would have to have happened for the id to be meaningful, and whether it did.

| Field | Real event behind it | Mint? |
|---|---|---|
| `transferId`, `exportReceiptId` | A bundle was generated and stored | **Yes** |
| `receiptId`, `paymentConfirmationId`, `settlementId` | Money moved | **No — deferred with payment** |

## 21. `platformSource` is declared **only where a dispatcher reads it** — a marker on bookkeeping is noise

Found 2026-08-31 auditing why `checksumVerified` had no source. It did not need one, and neither do
**55 other shipped fields** that the validator was warning about.

`platformSource` has exactly **one** runtime consumer: `workflow_service.dart` walks every field in a
community's schema and mints an id for each one declaring `opaqueId` that is still empty. That is what
the marker buys — a community declares an id field and the platform fills it with **no code change**,
where otherwise the service would hardcode `transferId`, `exportReceiptId` and every future name.

Nothing dispatches on any other value. `platformSource: "checksum"` is descriptive: the export handler
writes `checksum` and `checksumAlgorithm` by literal key name and never reads the marker.

### Wrong — a marker on a field no dispatcher resolves

Plausible, because the field really is written by the platform and the warning really did fire on it.

```jsonc
// WRONG. The archetype handler writes this and already knows the field name.
"readFanIds":       { "type": "fanIdList", "writableBy": "platform", "platformSource": "bookkeeping" },
"checksumVerified": { "type": "bool",      "writableBy": "platform", "platformSource": "checksum" }
```

`bookkeeping` is not in the closed set, so the first is a hard `unknown_platform_source`. The second
validates and is still wrong: it claims the checksum dispatcher owes this field a value, and that
dispatcher does not exist. A marker that describes a mechanism nobody implements is the same class of
defect as a canned checksum string — it reads as a wired mechanism and is not one.

### Correct — verified against Cedar Commons HOA and Garden Club

```jsonc
// Dispatched: the platform must resolve this without knowing the name.
"transferId":       { "type": "text?",     "writableBy": "platform", "platformSource": "opaqueId" },

// Not dispatched: a specific handler writes it, and already knows which field.
"checksumVerified": { "type": "bool",      "writableBy": "platform" },
"readFanIds":       { "type": "fanIdList", "writableBy": "platform" }
```

`checksumVerified` is genuinely computed — the download handler recomputes `sha256` and compares
against **both** the stored checksum and the byte size, because comparing the hash alone would let a
replacement or a truncation verify unconditionally. It simply is not resolved *by declaration*.

### The test to apply

Ask: **could the platform write this field if the field were renamed?**

| | Renamed still works? | Declare `platformSource` |
|---|---|---|
| `transferId` → `shipmentId` | Yes — the dispatcher reads the marker, not the name | **Yes**, `opaqueId` |
| `checksumVerified` → `bundleOk` | No — the handler writes a name it knows | No |
| `readFanIds` → `seenBy` | No — the archetype writes a name it knows | No |

A platform-written field with **no** `platformSource` is therefore usually correct, not incomplete.
`platform_writable_field_missing_platform_source` fires only where a dispatcher is genuinely owed.

## 22. Choose the archetype by interaction shape, not a keyword — a scheduled booking is `calendar`, not `event-rsvp`

**Requirement shape:** a workflow that books a resource for a time — a facility/room reservation, a court
booking, an equipment slot. The words "reserve"/"book"/"sign up" tempt `event-rsvp`.

**Plausible-but-wrong shape:** model it as `event-rsvp` because members "sign up" for a slot. `event-rsvp` is
for members answering **yes/no to an organizer's single event** (going/declined lists), not a bookable
resource schedule.

**Verified-correct shape:** `calendar` — a scheduled booking on a shared calendar (a resource booked for a
date/time; states scheduled → cancelled/completed). Pick the archetype whose **states + interactions** match
the requirement, never a keyword: "book a resource for a time" = `calendar`; "members RSVP yes/no to an
organizer's event" = `event-rsvp`; "a queue of items awaiting a decision" = `approvalQueueItem`. When two look
close, list each candidate's states and check them against the doc's stated states in Step 3, before the
archetype choice locks anything in.

**Found in:** Cedar Commons HOA facility reservation (2026-09-02) — ships and regenerates as `calendar`; a
locked `deriver_test` asserting `event-rsvp` was stale corpus drift, not a skill error.

## 23. A doc-promised affordance whose backing service does not exist is KEPT and marked `not_implemented` — never faked, never silently dropped

**Requirement shape:** the product doc promises a member action whose real mechanism needs a platform service
that is not built yet — e.g. **Mute thread** (needs per-member mute state / a messaging API), a push toggle, a
server-minted receipt.

**Plausible-but-wrong shape (two ways, both wrong):** (a) ship a live-looking button as a **no-op** — a
`to:null` transition with no effect — a dead affordance that lies to the member; or (b) **drop** the affordance
entirely because there is no mechanism, silently removing a doc-promised experience.

**Verified-correct shape:** **KEEP** the affordance (the doc promised it) and mark it honestly — declare the
transition, add a `// NEEDS IMPLEMENTATION (platform service): <what is missing>` comment, and record it
`not_implemented` in the Step 9.5 traceability with `reasoning` citing the missing service. It renders as a
visible placeholder; the gap shows in traceability and (once the rule lands) as a validator **warning** —
never a silent hole. Never resolve a missing-backend affordance by faking a value OR by deleting the
requirement; both hide an unmet promise.

**Found in:** Masjid Nur / Neighborhood Book Club `mute` (2026-09-02) — a regen dropped the button because
per-member mute state has no backing API; correct handling is keep-and-warn, with the messaging API tracked as
a post-production gap (`docs/Build Plan V2/Tickets/GAP-messaging-api.md`).

## 24. RSVP/vote response ROWS are canonical (Phase A.1) — and every reachable response state MUST be render-bound

**Requirement shape:** members RSVP going/maybe/declined to an event, or vote on a ballot. Each member has an independent answer.

**Canonical model (Phase A.1, 2026-08-14):** each member's answer is a **response ROW** — an instance in a `responseTable`, created by the parent event/ballot's **eager fan-out** (never a direct create; the engine refuses `ArchetypeOrigin.inheritedFromResponseTable` on the create endpoint). Rows are canonical because a single `respond` action would otherwise map to three different arrays (going/maybe/declined) and an archetype cannot tell which to fill; the row's state IS the answer, removing that ambiguity. 4 of the 5 RSVP communities in the shipped corpus already use response rows (BookClub, CameraClub, GardenClub, YouthSoccer); Masjid Nur's arrays are the outlier Phase A.1 plans to migrate TO rows.

**Plausible-but-wrong shape (the real masjid/book-club regen bug):** emit the response-row workflow (states pending/going/maybe/declined/waitlisted/withdrawn) but leave those reachable states with **no render binding** — a bare state machine. The unbound states trip `no_render_binding_for_reachable_state` and the extra unrendered workflow diverges from the harness/catalog, failing `product_community_walkthrough_conformance_test`. The fault is the **missing render bindings**, not the response-row model.

**Verified-correct shape:** the response-row workflow with **a render binding for every reachable state** — each answer state (going/maybe/declined/waitlisted) bound to the surface where a member sees their response (the RSVP card / roster), terminal states bound as `summary` where they should still appear, or deliberately unbound only where a state genuinely never renders. Do NOT invent a separate array model alongside the rows.

**Found in:** masjid-nur `mosque-event-rsvp-response` + neighborhood-book-club `book-meeting-rsvp-response`/`book-vote-response` regens (2026-09-02/03) — spawned the correct response-row workflow but left 6-7 states unbound, breaking conformance. Fix is render bindings, not retiring rows. Supersedes the earlier (retracted) "responses are data, never *-response" framing; response ROWS are canonical per Phase A.1.
