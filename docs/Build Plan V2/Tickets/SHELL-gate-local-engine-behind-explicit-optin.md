# SHELL — gate the in-memory engine behind an explicit opt-in (ticket A)

**Status:** written 2026-10-01, **DISPATCHED AND SHIPPED as `ee8e9483`** ("feat(shell): the in-memory engine is now behind an exp"). Kept for its reasoning; do NOT re-dispatch.
**Route:** `data/call_implementation_agent.sh --fresh`.
**Parallel with** [HARNESS-production-wiring-and-direct-grant-auth.md](HARNESS-production-wiring-and-direct-grant-auth.md) — different files, no shared edits.

## Why

**User decision 2026-10-01, non-negotiable:** the UX judge and the live walkthrough must execute
against the **live backend services**, never the in-memory engine. The capture harness currently runs
local *silently* — it calls `pumpWidget(LoomCommunitiesDemoApp())` and never `main()`, so the
production factory is never installed and the shell falls back to memory with no signal at all.

**This ticket alone delivers the guarantee.** After it, a capture can no longer quietly run local: it
**throws loudly at the first store install**. It does not make the harness work remotely — that is
ticket B — it makes the silent failure impossible, which is the half that matters for trusting
evidence.

## The seam — already has a predicate, do not invent one

Gate the initializer of `_productionEngineNativeCommunityEngineFactory` at
`part25_engine_native_community_store.dart:171`. Resolution order at `:256-258` is per-extension
registration → test override → this production factory, so **every** engine-native store passes
through it regardless of entrypoint. That is exactly why gating `main()` cannot work.

"This process is explicitly local" already has one predicate:
`resolveLoomServiceEnvironment() == null` (`part40_service_environments.dart:125`), which is null only
for compile-time `LOOM_ENV=local` or the runtime test flag `debugForceLoomLocalBackend` (`part40:116`).

Replace the default with a sentinel that falls back to local **only** when that predicate says the
process is explicitly local, and otherwise throws a `StateError` naming: the extension id, that no
production factory was configured, that `main()` installs one when
`configureLoomRemoteServicesFromEnvironment()` returns non-null, and the two legitimate opt-ins
(`debugForceLoomLocalBackend` in a package's `flutter_test_config.dart`, or
`--dart-define=LOOM_ENV=local`). **The message is the deliverable as much as the gate** — whoever hits
it must not have to read this ticket to understand it.

**DO NOT gate `database.dart:71` (`WorkflowDatabase.memory()` itself).** 45 of the 72 test files that
reference the memory engine live in `loom_workflow_engine` (34) and `loom_workflow_service` (11) and
construct it as the unit under test. They are legitimately local forever and gating the constructor
punishes them for nothing.

## Two companion edits, or the gate leaks straight back

1. **`resetProductionEngineNativeCommunityEngineFactoryForTesting()` (`:205-208`) must reset to the
   SENTINEL**, not to `_createLocalEngineNativeCommunityEngine`. Otherwise any test calling the reset
   reintroduces the silent fallback for the remainder of the process. Two app-shell test files call
   it.
2. **Add `packages/core/loom_communities_app_shell/test/flutter_test_config.dart`**, the same shape as
   the demo app's existing one, setting `debugForceLoomLocalBackend = true`. It does **not** exist
   today. `flutter_test_config.dart` runs before every test under that package's `test/` root, so this
   is one shared seam for all 447 tests — **not 72 edits, and not any edit to an existing test.**

`_database = WorkflowDatabase.memory()` at `:246` stays as-is: it is `late final`, is passed to the
factory, and the remote factory (`part37:443`) ignores it. An inert allocation, not a leak.
`part02_tab_shell.dart:754` (`_MessagesEngineStore`) is out of scope by standing instruction and does
not route through this factory.

## One file needs a deliberate decision, not a discovery

`integration_test/load_all_communities_test.dart` pumps `LoomCommunitiesDemoApp()` without `main()`,
and `integration_test/` deliberately has **no** `flutter_test_config.dart` — that absence is correct,
because `integration_test/` is exactly where the gate must bite. So this test will throw. **Choose and
state which:** build it with `LOOM_ENV=local`, or convert it to the production wiring. Do not let it
meet the gate by surprise and do not add a `flutter_test_config.dart` under `integration_test/` —
that would disable the gate for the capture harness, defeating the entire ticket.

## Verification

- **All five suites**, which is the whole point: demo 262 exit 0, app shell 447 (+2), judges 525,
  engine 345 (+1), service 168 (+1) with both credential sets. A broken opt-in shows up here as mass
  failure, so green suites are the proof the seam is right.
- **Prove the gate FIRES**: a test (or a documented manual run) that installs an engine-native store
  with no production factory and no local opt-in must get the `StateError`, not a local engine. A gate
  only ever seen passing is indistinguishable from one that cannot fail — and this repo has shipped
  exactly that twice.
- `flutter analyze` clean on the app shell (it is clean today, so any finding is yours).
