Ticket AuthZ.P3 — JSON grammar: persona accessMode, workflow visibility/readGuard, account status

## Context

Third ticket in a larger data-safety hardening effort. AuthZ.P1 (sign-up persona picker fix, commit
`6113d194`) and AuthZ.P2 (global-state -> explicit `ActiveIdentityScope` refactor, commits `74715e6e`/
`eeb95b48`) are both merged and independently verified. This ticket adds JSON vocabulary and data-model
fields that later tickets (read-path enforcement, membership/invitation flows) will consume -- it is
**purely additive**: new optional fields, new parsing, one new validator warning. No enforcement logic, no
UI changes, no behavior change for any community that doesn't use the new fields. Every existing community
package and test fixture must continue to work identically.

The guiding principle for this whole effort, unchanged: authorization concepts must be *derived from* a
community's own declared JSON -- never a hardcoded Dart list keyed to one specific community.

## Scope

**1. Persona-level `accessMode`** (a hint for a later ticket's sign-up/invitation flows -- this ticket only
adds the field and its parsing, not any enforcement of it):
```jsonc
{ "personaId": "apartment-event-manager", "label": "...", "roleLabel": "...", "accessMode": "requiresApproval" }
```
Valid values: `"open"` (default when omitted -- today's behavior), `"requiresApproval"`, `"requiresInvite"`.
Add an `accessMode` field (parsed as an enum or plain string, your call, but validate the value is one of
the three at parse time) to `LoomPersonaDefinition` wherever it is currently parsed from JSON -- find the
existing parser for `personaId`/`label`/`roleLabel`/`description` and add this alongside them, following the
exact same optional-field pattern already used there.

**2. Workflow-level `visibility`** (also just the shape for now -- no read filtering yet, that is a later
ticket):
```jsonc
"workflowDefinitions": {
  "apartment-event": {
    "visibility": { "default": "guarded", "readGuard": { "allowedPersonaIds": ["apartment-event-manager"] } },
    "states": { ... }
  }
}
```
Valid `default` values: `"public"` (default when the whole `visibility` block is omitted -- today's
behavior), `"membersOnly"`, `"guarded"` (requires a sibling `readGuard` using the exact same `WorkflowGuard`
JSON shape already used by `editGuard`/`creationGuard`). Add `visibility` to
`app/packages/core/loom_workflow_engine/lib/src/models/workflow_models.dart`'s
`LoomWorkflowStateMachine` class (the workflow-type-level model, alongside `workflowType`/`initialState`/
`states`). Also add an optional, **per-state** `readGuard` field to `LoomWorkflowState` (same file), parsed
identically to how `editGuard` is already parsed there (find `editGuard`'s exact parsing code -- `final
editGuard = json['editGuard'] != null ? WorkflowGuard.fromJson(...) : null;` -- and mirror it precisely for
`readGuard`). This per-state override lets a later ticket express "most states are `guarded` by the
workflow-level default, but this one draft state has its own stricter guard."

**3. `LoomAccount.status`**
(`app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart`): add a `status` field, type
`MembershipStatus` (new enum: `active`, `pendingApproval`, `invited`), defaulting to `MembershipStatus.active`
in every existing constructor call site -- grep for every place a `LoomAccount(...)` is constructed
(including seeded/demo accounts) and confirm each one either explicitly passes `status: MembershipStatus.active`
or gets it for free via a default parameter value. Zero existing account should end up any other status.

**4. New `LoomCommunityInvite` record type** (data shape only -- no issuing/redeeming logic yet, that is a
later ticket):
```dart
class LoomCommunityInvite {
  final String inviteId;
  final String communityExtensionId;
  final String personaTypeId;
  final String issuedByAccountId;
  final String code;
  final InviteStatus status; // pending | claimed | revoked
  final DateTime createdAt;
}
```
Add this class in the same file as `LoomAccount` (`part29_auth_api.dart`) or a natural neighboring location
you judge appropriate -- just don't wire it into `LocalAuthApi`'s actual signUp/signIn logic yet, that's
scope creep for a later ticket. It's fine (expected) for this ticket to leave it unused/unconstructed
anywhere in production code.

**5. Validator support**
(`app/packages/tooling/loom_ux_judges/lib/src/validator/workflow_validator.dart`): add a new **warning**
(not error) finding, code `no_read_visibility_declared`, raised once per workflow type that omits the
`visibility` field entirely. Follow the exact pattern already used for the three existing warning checks in
this file (`editable_fields_without_edit_guard`, `no_creation_path_for_editable_type`,
`no_destructive_exit_for_managed_type`) -- same registration mechanism in the `validate()` method, same
`ValidationFinding`/message shape, same `isWarning: true`. Add this to
`docs/references/guide/05-validation.md`'s error-to-fix table too (the source doc for the ChatGPT-facing
skill built earlier), following the existing table row format for the three checks already documented there.

## Do not do

- Do not add any enforcement logic anywhere -- not in `queryInstances`, not in sign-up/sign-in, not in tab
  visibility. This ticket is data model + parsing + one validator warning only. A later ticket in this same
  effort adds enforcement.
- Do not touch AuthZ.P1 (persona-picker) or AuthZ.P2 (`ActiveIdentityScope`) code -- both done, verified,
  must keep passing unchanged.
- Do not make `no_read_visibility_declared` an error. Warning only, in this ticket.
- Do not wire `LoomCommunityInvite` into `LocalAuthApi` or any UI -- data shape only.

## Required verification

1. `flutter analyze` on `packages/core/loom_workflow_engine`, `packages/core/loom_communities_app_shell`,
   and `packages/tooling/loom_ux_judges` -- clean, zero new issues, all three.
2. Full test suites for all three packages -- identical baseline outcome (`loom_communities_app_shell`:
   182 passing / 1 known a11 flake failing) plus new tests you add for the new parsing and the new validator
   warning.
3. Add parsing tests: a workflow JSON with `visibility` declared parses correctly into the new model fields
   (all three `default` values); a persona JSON with each of the three `accessMode` values parses correctly;
   omitting either field entirely still parses with the documented defaults (`public`/`open`); a malformed
   `accessMode`/`visibility.default` value (not one of the enumerated strings) should fail parsing with a
   clear error, not silently default -- confirm this is genuinely the case, or explicitly note if you chose
   silent-default-on-invalid instead and why.
4. Add validator tests: a fixture workflow type with no `visibility` field triggers exactly the new
   `no_read_visibility_declared` warning and nothing else changes; a fixture with `visibility` declared
   produces no such warning.
5. If your sandbox cannot run `flutter analyze`/`flutter test`/`dart test`, say so plainly in your STATUS
   response -- independent verification will be re-run outside the sandbox regardless (this has been
   necessary for both prior tickets in this effort due to sandbox network/filesystem restrictions).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `feat: add persona accessMode, workflow visibility/readGuard, and account status
JSON grammar (AuthZ.P3)`.

## Required response format (write to `data/v3_ticket_authz_p3_json_grammar_STATUS.md`)

```
# Ticket status: AuthZ.P3

## Change applied
Status: done | blocked
Exact file:line for every new field/class added, and confirmation of the invalid-value parsing behavior
(reject vs silent-default, and why).

## Verification
flutter analyze (all three packages): clean/not clean.
Test suites (all three packages): pass counts (X/Y each). Explicitly confirm loom_communities_app_shell is
182/183 with only the known a11 flake, and name the new parsing/validator tests added.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
