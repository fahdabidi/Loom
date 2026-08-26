# Step 2 proven: the app reads the deployed backend from a real device

**Date:** 2026-08-26
**Device:** `emulator-5554`, Android 16 (API 36), on Windows
**Verified from my own shell and cross-checked against Postgres**, not from an agent report.

## The result

`integration_test/on_device_remote_backend_proof_test.dart`, run with the three
`--dart-define`s, passed:

    ON_DEVICE_REMOTE_PROOF
      instanceCount = 3
      instanceId    = community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh
      workflowType  = hoa-facility-reservation
      state         = open
      instanceData  = {title: Clubhouse - live chain probe, facility: Clubhouse,
                       eventDate: 2026-09-15, eventTime: 18:00, durationMinutes: 120,
                       reservationWindow: Evening, locationDetails: Main hall,
                       requesterFanId: fan-test-alice, dueAt: null, reminderState: off}

Asserted on device: the engine resolved through the **production** factory is a
`RemoteWorkflowEngineApi` (not the `@visibleForTesting` override), its `communityId` and
its scheme/host/port match the configured service, and a real `queryInstances` returns
data.

## Why this is proof and not a client-side claim

A test passing against a local engine looks identical to one passing against the real
service. That confusion is the entire reason the work was resequenced, so the client
output alone was not accepted. Cross-checked directly against the live database:

    select instance_id, current_state, created_by_fan_id from workflow_instances
      where instance_id = 'community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh';
    -> community_cedar_commons_hoa_hoa-facility-reservation_3pbmhxf5srqh | open | fan-test-alice

    select count(*) from workflow_instances;
    -> 3

That instance id was created earlier in this effort by a direct `POST /instances` against
the deployed service. It exists only in the cluster's Postgres. **An in-memory local
engine cannot fabricate it**, and the client's `instanceCount=3` matches the row count
exactly.

Two honest caveats:

- **Keycloak logged no token activity** in the run window. The workflow service requires a
  valid JWT to serve the request at all, so a token was certainly used — most likely
  cached in secure storage, or Keycloak is simply quiet at its default log level (an
  earlier check found it silent for known-good activity too). Not over-read either way.
- The workflow service has no request-level logging, only the unexpected-500 logging added
  as item 1o. So the database cross-check, not a log line, is what carries this.

## An incidental confirmation

`dueAt: null` and `reminderState: off` in the returned data are the **repaired Cedar
formulas** evaluating correctly with `reminderEnabled` absent. Before that fix
(`485a092c`) these threw `FormulaEvaluationException: Expected bool, got null`, which
killed row hydration before visibility ran and made the instance unreadable. Seeing them
resolve on the device closes that loop end to end: package fix -> republished definitions
-> service -> device.

## What it took, and the failure that nearly hid it

The path from "step 2 is wired" to "step 2 is proven" ran through five distinct blockers,
none of which were visible from the code:

1. The app defaulted to local, and the defines are **compile-time** — so remote required a
   rebuild, not a config change.
2. Android 16 blocks cleartext HTTP; the manifest permitted none, and every service is
   plain `http://`. Fixed with a config scoped to the dev hosts, debug builds only.
3. The config had to reach the **merged** manifest, not merely exist as a source file.
4. The decision function `configureLoomRemoteServicesFromEnvironment` had **zero tests** —
   the single highest-consequence untested function in the migration.
5. The first on-device run failed on a trailing slash: the test encoded one exact URI
   spelling while the client normalises. A test bug, not a product one.

A verification of mine also failed and nearly produced a false finding: scanning the APK
for `192.168.56.10` returned 0, which read as "the defines never took". Running a control
for strings that **must** be present — `cedar`, `loom_communities` — returned 0 as well.
The method was broken; Dart's `kernel_blob.bin` does not yield to `strings` that way. The
original 0 meant nothing. **Validate a sweep against a known answer before trusting what
it did not find** — the same discipline whose absence produced the retracted item 1g.

## Consequences

- **2d and 2b are closed.** The app demonstrably uses the deployed backend on device.
- **Step 3 is unblocked**: retiring the app's local backends can proceed, with the standing
  caveat that `LocalWorkflowEngineApi` itself stays — the deployed workflow service uses it
  as its own in-process engine.
- **Captures are unblocked**, with one hard requirement: every capture build must pass the
  same three `--dart-define`s. A capture without them silently exercises the local engine
  while appearing to prove the real stack, which would reproduce exactly the problem the
  resequencing exists to prevent.
