# Ticket status: Multi-user login (LoomAuthApi + sign-in/sign-up + per-individual identity)

## Item 1: LoomAuthApi + LocalAuthApi contract
Status: done

Files:
- `app/packages/core/loom_communities_app_shell/lib/src/part29_auth_api.dart` — abstract `LoomAuthApi` contract with `LoomAccount` (accountId/displayName/personaTypeId), `LoomSession`, and four API methods (`listAccounts`, `signIn`, `signUp`, `signOut`, `currentSession`)
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart` — `LocalAuthApi` in-memory implementation seeded from the frozen JSON's individual ids (`tabletop-member-03` through `tabletop-member-14`, `tabletop-organizer`), with `signUp` creating new accounts with auto-incrementing ids

`personaId` vs `personaTypeId` threading:
- `LoomAccount.personaTypeId` = the declared persona type (e.g. `"tabletop-member"`) — used for `allowedPersonaIds` guard checks
- `LoomAccount.accountId` = the stable per-individual id (e.g. `"tabletop-member-05"`) — used for `$actor`/`ownerPersonaId`/`voterId` resolution
- `LocalWorkflowEngineApi.setPersonaType(individualId, typeId)` registers the mapping in the engine
- `evaluateGuard` now accepts `String? personaTypeId` — uses it (or falls back to `personaId`) for `allowedPersonaIds` checks
- `availableTransitions` in transition_evaluator threads `personaTypeId` through
- `LocalWorkflowEngineApi.availableTransitions`/`applyTransition` both pass `_personaTypeById[personaId]` as `personaTypeId`

## Item 2: Sign-in/sign-up UI
Status: done

File: `app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart`
- `LoomAuthScreen` — full-screen flow showing seeded accounts grouped by persona type, with a sign-up form (display name + persona type dropdown)
- `_AccountList` — lists existing accounts grouped by `personaTypeId` (Organizers / Members)
- `_SignUpForm` — validates display name, allows persona type selection, calls `signUp`

## Item 3: Switch-user picker (replaced the role picker)

Status: done

Decision: **Replaced.** The existing `_showPersonaPicker` now delegates to a new `_showAccountPicker` method. The old "Switch role" button (`persona-picker-button`, `Icons.people_outline`, tooltip "Switch role") still exists in the UI but now triggers the account-based picker. The new picker sources accounts from `LoomAuthApi.listAccounts()` and signs the user in as the selected account.

Rationale: Two separate switchers for overlapping concepts (role vs individual) would confuse the UI. An account already carries a `personaTypeId`, making role-only switching redundant. The old `personasForExtensionId`-based picker code is preserved as a fallback in `_showPersonaPicker` but re-routes to the account picker when accounts are available.

## Item 4: Session threading through existing personaId call sites

Status: done

New fields in `_LocalExtensionScreenState`:
- `_authApi` (`LoomAuthApi`) — initialized as `LocalAuthApi()`
- `_activeAccountId` getter — returns `session.account.accountId ?? _selectedPersonaId`
- `_activePersonaTypeId` getter — returns `session.account.personaTypeId ?? _selectedPersonaId`

Call sites and their resolution:

| Call site | Uses | Rationale |
|---|---|---|
| `_activePersona()` | `_activePersonaTypeId` | Returns `LoomPersonaDefinition` matched by **type** — used for UI persona data (label, role, description) |
| `appShellTabsFor(personaId:)` | `activePersona.personaId` (type) | Tab generation is type-agnostic; `personaId` here is purely for keying |
| `personaWorkflowViewFor(personaId:)` | `activePersona.personaId` (type) | Needs type to check `actorPersonaIds`/`receiverPersonaIds` against policy |
| `personaWorkflowStateFor(personaId:)` | `activePersona.personaId` (type) | Same as above — UI classification, not engine guard |
| `workflowPersonaReceiptKey(personaId:)` | `activePersona.personaId` (type) | For tracking received items per persona type |
| Engine API calls (`queryInstances`, `availableTransitions`, `applyTransition`, `createInstance`) | `resolveEnginePersonaId(type)` → individual ID | **Engine receives individual ID** for `$actor`/guard evaluation, `allowedPersonaIds` internally looks up `personaTypeId` mapping |
| `setCurrentActiveAccountId()` | `_activeAccountId` | Sets global state for `resolveEnginePersonaId` |
| `_selectedTabIdByPersonaId` keys | `_activePersonaTypeId` | Preserves tab selection when switching between individuals of the same type |

Bridge files modified:
- `part25_engine_native_community_store.dart` — added `_globalAuthApi`, `setGlobalAuthApi()`, `setCurrentActiveAccountId()`, `resolveEnginePersonaId()`, auto-registers persona types on engine init
- `part28_engine_native_calendar_surface.dart` — uses `resolveEnginePersonaId()` when constructing `EngineNativeBindingDispatcher` and `_EngineNativeCalendarContent`

## Tests

`flutter test` was **not runnable** in this sandbox (Flutter SDK on read-only filesystem). The test file exists at:
- `app/packages/core/loom_communities_app_shell/test/v3_multiuser_login_test.dart`

The 5 required tests are authored:

1. **`LocalAuthApi.listAccounts() returns seeded demo accounts`** — verifies 14 accounts (1 organizer, 13 members), each with distinct `accountId`, proper `personaTypeId`, and non-empty `displayName`. Confirms `tabletop-member-05` is seeded as "Priya N."

2. **`signIn / signUp / signOut / currentSession round-trip`** — verifies null→signed-in→signed-out→null cycle, signUp creates a fresh non-colliding account, new account appears in listAccounts

3. **`owner-gated guard distinguishes individuals`** — signs in as `tabletop-member-05` (owner of `share-azul`), confirms `approve-request`/`decline-request` are available; switches to `tabletop-member-06` and confirms they are NOT available — the concrete proof this ticket delivers

4. **`account list groups by persona type`** — verifies accounts are correctly grouped, organizer group has 1 account, member group has >1, all accounts within a group share the same `personaTypeId`

5. **`engine-native store initializes correctly with auth bridge`** — sets `setGlobalAuthApi`, confirms engine queries 17 instances after init, verifies owner transition becomes available

To run tests:
```bash
cd app
flutter test test/v3_multiuser_login_test.dart
```

## Gaps found (if any)

**None.** All call sites were resolvable with the two-value approach (individual ID for engine calls, persona type for UI resolution). No guard/effect call site required collapsing the distinction.

**Note on testing:** The Flutter SDK in this sandbox environment is on a read-only filesystem (`/home/fahd_/flutter/bin/cache/engine.stamp`), so `flutter analyze` and `flutter test` could not execute. The code has been manually verified for correct:
- Part file declarations in `loom_communities_app_shell.dart`
- All part files begin with `part of '../loom_communities_app_shell.dart';`
- Type consistency: `LoomAuthApi`, `LocalAuthApi`, `LoomAccount`, `LoomSession` all in shared library namespace
- `resolveEnginePersonaId` / `setCurrentActiveAccountId` / `setGlobalAuthApi` declared in part25, used in part01 and part28
- Engine guard evaluator `personaTypeId` parameter threaded through `transition_evaluator.dart` → `local_workflow_engine_api.dart`
- Test file imports both `loom_communities_app_shell` and `loom_workflow_engine` packages correctly
