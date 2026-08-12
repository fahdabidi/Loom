---
spec: { envelope: 1, experience: 2, grammar: 1 }
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

## 9. When updating an existing, already-shipped community, reuse its real `personaId`/`tabId` values exactly — never re-derive plausible-looking ones from the product doc's own prose

**Requirement shape:** the target is an update to a community that already has a real, committed JSON
package — adding a new archetype, workflow, or field to something that already exists, not authoring a
community from nothing. Every authoring channel of this Skill deliberately never sees the existing shipped
file while drafting (the in-repo `Agent`-tool channel is explicitly forbidden from reading it, and the
zero-tool-access/Codex channels have no mechanism to see it at all) — so the fresh draft has no way to know
what identifiers the shipped file, or any real committed test that hardcodes those identifiers, already
expect.

**Looks plausible but is wrong:** deriving `personaId`/`tabId` values fresh from the product doc's own
vocabulary — reasonable-sounding, internally consistent, and structurally valid, but silently different from
the identifiers the currently-shipped file and its tests actually use. The JSON validates cleanly in
isolation; the defect only surfaces as a broken Dart test, or a broken guard/formula reference, once the new
file replaces the old one — something no JSON-only validator run or self-check can catch.

**Verified-correct shape:** the dispatching session (never the authoring agent itself) reads the currently-
shipped fixture directly and supplies its real `personas[]` and `appShell.tabs[]` values as an explicit
`## Existing identifiers — preserve these exactly` section appended to the target product doc, listing each
`personaId`/`label`/`roleLabel` and `tabId`/`label` pair. The authoring agent reuses every listed value
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

## 10. A `documentLibrary` workflow defaults to `membersOnly` visibility with list-based access tracking — never a required singular `recipientPersonaId` behind a `guarded` default

**Requirement shape:** a community's documents/resources need to be readable by the general membership, with
only a minority genuinely access-restricted (e.g. a leadership-only policy doc). The product doc almost
always names this as an anti-pattern to avoid directly ("hidden document link," "documents should be
findable, not buried").

**Looks plausible but is wrong:** modeling every document as a single-recipient row —
`recipientPersonaId: { "type": "personaId", "required": true }` plus `"visibility": { "default": "guarded",
"readGuard": { "formula": "$viewer == recipientPersonaId || ..." } }`. This looks like careful, privacy-
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
  "acknowledgedPersonaIds": { "type": "personaId[]", "writableBy": "effect" },
  "accessRequestedPersonaIds": { "type": "personaId[]", "writableBy": "effect" }
}
```
Reserve a `guarded`/`readGuard` visibility override only for the genuinely small minority of documents that
need real access restriction (e.g. a board-only financial record), and even then prefer a role-based guard
(`allowedPersonaIds`) over a single required recipient, so the common case — most documents, visible to most
members — is never gated behind an easy-to-drop identity match.

**Found in:** Masjid Nur, 2nd Milestone 1.5 dispatch (Codex GitHub-fetch channel, 2026-08-12) —
`mosque-document-resource` used the required-singular-recipient shape above, confirmed by an independent
Skill Output Judge to make every document invisible to the general membership by construction, contradicting
the product doc's own stated anti-pattern. The currently-shipped fixture for the same community already
proves the correct shape works (`membersOnly` default + `acknowledgedPersonaIds`/`accessRequestedPersonaIds`
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
  "guard": { "allowedPersonaIds": ["<admin-persona>"] },
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
  "guard": { "allowedPersonaIds": ["<organizer-persona>"], "formula": "size(exportScope) > 0" },
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
subsystem with `invitationStatus`/`participantPersonaIds` fields, sourced from the same generic B25 addendum
phrasing already confirmed as cross-community boilerplate. The currently-shipped fixture had already declined
to build this, with an explicit comment stating why. Caught by an independent Skill Output Judge dispatch,
which traced the two `destructive_transition_ignores_availability_field` validator warnings on this
community back to the unrequested subsystem as their root cause, not a missing guard to patch.

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
