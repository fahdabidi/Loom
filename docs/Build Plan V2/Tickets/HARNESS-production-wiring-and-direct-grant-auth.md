# HARNESS — run the capture against live backend services (ticket B)

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`.
**Independent of** [SHELL-gate-local-engine-behind-explicit-optin.md](SHELL-gate-local-engine-behind-explicit-optin.md) (ticket A) — different files. A makes silent-local impossible; **B is what makes remote actually work.** Neither blocks the other.

## Why

User decision 2026-10-01: the UX judge and live walkthrough must run against **live backend
services**. The harness currently never installs the production wiring, so every captured frame
depicts the in-memory engine — which is why 21 judged rows all carry a `LOCAL ENGINE` badge.

## There is a working template — read it before writing anything

`integration_test/on_device_remote_backend_proof_test.dart` already does this end to end:
`demo.main()` (line 59) → `session.loginWithTestCredentials(username: …, password: …)` (line 103) →
live reads **and a live write** through the engine from the production factory. **Nothing new needs
inventing; this ticket is mostly "apply that pattern to the capture harness".**

## What to build

### 1. Install the production wiring before pumping

`workflow_ui_evidence_test.dart:263` calls `pumpWidget(const LoomCommunitiesDemoApp())` and skips
`main()`'s pre-`runApp` block (`main.dart:22-39`), which is where
`configureLoomRemoteServicesFromEnvironment()` and
`configureEngineNativeCommunityEngineFactoryForProduction(...)` live.

**Preferred:** extract that block into a public `configureLoomProductionWiring()` in the demo app, and
have **both** `main()` and the harness call it. One seam, so the two can never drift — this repo has
three recorded instances of the same logic diverging across call sites. Calling `demo.main()` directly
(the proof test's pattern) also works under `IntegrationTestWidgetsFlutterBinding` and is acceptable if
extraction proves awkward; say which you did and why.

**No new `--dart-define` is required.** `LOOM_ENV` defaults to `dev`, whose endpoints *and*
`authClientId: 'loom-test-client'` are baked into `part40_service_environments.dart:80`, and `part37`
falls back to those when the defines are empty. (An earlier draft of this ticket claimed
`LOOM_AUTH_CLIENT_ID` was newly required. That was wrong — verified at `part40:80` and `part37:247`.)

### 2. Authenticate per seeded FAN, in-process

Before driving the identity picker for a role: `session.logout()`, then
`loginWithTestCredentials` as the matching fan. Seeded accounts follow the recorded convention —
Keycloak `loom-<slug>`, fan id `fan-<slug>`, shared test password in the Access Control tracker.
**Look the credentials up; never create or reset one.**

**Order matters:** `RemoteLoomAuthApi.signIn` compares the selected account id against the token's
`fanId` and rejects a mismatch, so login must come **before** picker selection and must match it.
That guard is the reason this project's evidence is attributed to the right fan; do not route around it.

**The Chrome-SSO-cookie ritual does NOT apply here.** The direct grant never touches a browser, so the
documented "clear both Chrome and app data" dance is a device-walkthrough problem, not a harness one.
Do not import it.

**A credential that fails is not a blocker:** accounts are seeded several per role, so pick another
holder of that role (precedent: `loom-book-member-1`'s replaced password). Do not stop and ask.

### 3. Report the engine honestly in the evidence

The captured evidence must record which engine produced each frame, so a future reader can tell
local frames from live ones without inspecting pixels for a badge. Whatever field you add, it must be
**derived from the configured factory at runtime**, never from a flag the caller passes — a
caller-supplied label would be exactly the kind of assertion that outlives its truth.

## Out of scope — and this is the big one

**Do NOT attempt to make the harness's row selection work remotely.** Package `workflowInstances`
seed **only** the local engine, and remote communities start empty by design (2026-09-07 decision), so
the selector's seeded rows do not exist against the live backend. Making rows creation-driven is
ticket C and is the largest unknown in this programme.

**So the success criterion for B is deliberately narrow: ONE authenticated remote frame.** Prove the
wiring and the auth work. A run that authenticates and then finds no rows is a **success** for this
ticket and the expected outcome — say so plainly in the report rather than treating it as failure.

## Verification

- A capture invocation reaches the live backend: evidence or logs show
  `mode=remote endpoint=http://192.168.56.10:30083/` rather than `mode=local`, for a real request.
- At least one frame captured with an authenticated session, and the recorded engine field says remote.
- `logout()` → `loginWithTestCredentials` as a *second* seeded fan works in the same run, since every
  multi-fan row depends on switching identity cleanly.
- All five suites still green (demo 262, app shell 447 (+2), judges 525, engine 345 (+1), service 168 (+1)).
- **Do not weaken, skip or delete any existing capture test** to make this pass. If a test blocks the
  change, report it and stop.
