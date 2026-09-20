**Workflow:** `book-search-ai-digest` in Neighborhood Book Club
**Outcome:** BLOCKED at `draft` — the instance was created live through the real UI by the intended
identity and is confirmed in Postgres, but it could not be advanced to `open`/`saved` because the
`draft` card renders for nobody. This is the live confirmation of a defect row-247 had so far only
predicted by static inspection. **Not a proof. This row remains unproven.**

**Package identity:** `Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`
`skillVersion`: `3.6.0`
`sha256`: `71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`

**Date:** 2026-09-20 · **Device:** `emulator-5554` (Windows host, via the VM's adb tunnel)

---

## Identity

| | |
|---|---|
| Keycloak account | `loom-book-member-2` |
| Fan id | `fan-book-member-2` |
| Community role | `book-member` ("Signed in as Test book-member-2 — Member") |

Both Chrome and the app were cleared first (`pm clear` on each), because the app held a **different**
identity — it opened signed in as **Book Organizer 1**, which would have failed the member-guarded
create. After clearing, the app showed `LoomAuthNotLoggedInException: No Loom authentication session
is stored; login is required.` and the **real Keycloak form** rendered at `192.168.56.10:30082` — no
stale-SSO auto-sign-in. The password field was revealed before submitting and read exactly
`LoomTest123!` (no shell-escaping artefact). The launch screen showed **"Loaded 10 example
communities"**, confirming the preload flag is compiled into this build.

Identity is settled independently of the screen: `created_by_fan_id` on the resulting row is
`fan-book-member-2`, the fan I authenticated as.

## What was driven (real UI only)

Books tab → create FAB → **"Ask the club"** → `query` = `B25-Sep20-member2-digest` → **Create**.

The IME collapsed the dialog's `Query` field to zero height, exactly as the brief warned; the
keyboard was hidden and the field re-read as the full `B25-Sep20-member2-digest` before Create was
tapped. No transition was fired through the API.

**Final UI state:** the Books tab renders the community header, the tab description, one `Closed`
ballot card and `Local package details` — and **no digest card at all**. The Home tab was also
checked and shows no digest (the package declares no home binding for this type). So there is no UI
route to the instance, and `submit-query` cannot be reached.

## Database (queried this session)

Baseline before the run, measured rather than assumed: **99 rows total**, **0 of
`book-search-ai-digest`**. The zero is a real absence, not a broken query — seven sibling `book-*`
types returned rows as a control. Afterwards: **100 rows total**, one of them mine.

```
instance_id       community_neighborhood_book_club_book-search-ai-digest_oxvn8zmukhol
community_id      community_neighborhood_book_club
workflow_type     book-search-ai-digest
created_by_fan_id fan-book-member-2
current_state     draft
created_at        1789894970382   (2026-09-20 09:02:50 UTC)
instance_data     {"query":"B25-Sep20-member2-digest"}
```

**Do the two halves agree?** On the write, yes: the UI create action produced exactly this row, by
the identity driven, with the typed value stored in full (no `input text` truncation). On the
outcome, there is nothing to agree about — the workflow never left its initial state.

`book-search-ai-digest` is published at **version 4**, so this is not an unpublished-type no-op.

## Why it is blocked — measured, not inferred

`instance_data` holds **only `query`**. There is no `submitterFanId`, because nothing writes it until
`submit-query` fires.

`role_resolver.dart:20-31` (`deriveInstanceRoles`) walks the machine's transitions, takes the
**first** one declaring `actorEqualsField`, `break`s, and resolves the actor from that field —
falling back to `createdByFanId` **only when no transition declares one at all**. For this workflow
the first such transition is `edit-digest`, keyed on `submitterFanId`. In `draft` that field is
unset, so the actor resolves to null, nobody matches, and the `draft` binding — which is
`audience: "actor"` — renders for no one, including its own author.

The circle: the card is the only route to `submit-query`; `submit-query` is the only writer of
`submitterFanId`; `submitterFanId` is what the card's audience needs to render. The `"Ask the club"`
create action declares no `prefill`, so nothing breaks the circle at creation time.

Three independent lines agree, which is why this is stated as a mechanism rather than a guess:

1. **Source** — the resolver above, read directly.
2. **Live control, different surface family** — a pre-existing `book-nomination` row sits in `draft`,
   also created by `fan-book-member-2`, also with its identity field (`nominatorFanId`) absent, and
   it is **equally invisible** on that same Books tab (no "Dune" card in any screenshot). That
   excludes a `searchAiAnswer`-specific renderer fault: the surface family is dispatched normally at
   `part27_engine_native_binding_dispatcher.dart:446` (`SearchAiAnswerArchetypeCard`), and the
   sibling failure uses `formEntry`.
3. **Telemetry** — every engine call logged `LOOM_BINDING … outcome=ok status=200`. No 403, no fetch
   failure. The instance is read successfully and then not rendered; this is a binding decision, not
   an authorization or transport problem.

**This is not a new defect.** `TODO-open-detail.md` row-247 already scopes the fix — create-time
identity **in the package** (a `prefill` on the create action), explicitly *not* a `createdByFanId`
fallback in the engine, because the docs deliberately give the business party precedence over the
creator. That row names three siblings "confirmed by static inspection (**not live**)", and
`book-search-ai-digest` (`submitterFanId` on `submit-query`) is one of them. **The contribution of
this run is converting that static prediction into an observed, on-device fact with a database row
behind it.** Book Club's regeneration is HELD by user decision until the listing/loan backend exists,
so no package change was proposed here.

## Consequence for the bar

This row cannot be proven on the UI path until row-247's create-time identity lands. It should sit
with the other Book Club rows blocked behind that held regeneration, not in the walkthrough queue.

A note on what would close the loop and was deliberately not run: the `open` and `saved` bindings are
`audience: "any"`, so an instance in `open` must render for everyone. Advancing it would take an API
transition, which this ticket forbids precisely because it proves the service boundary rather than
the UI path. The block stands as observed.

## Left undone

- The workflow was not advanced to `open` or `saved`; `save-digest` was never reached.
- `withdraw-query` was deliberately not taken — it is the destructive exit and ends the row short.
- The empty `answer` field was not investigated: the package annotates it as a platform service that
  does not exist, and no guard reads it, so it is the designed state and not this row's blocker.
- No application code, community JSON or tracker was modified.
