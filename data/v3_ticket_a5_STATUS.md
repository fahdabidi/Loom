# Ticket status: Shared engine per engine-native community (A.5)

## Item 1 of 1: engine-native installation and seed import

Status: done

Implementation commit: `a646f76822f6eb6f6d3d5278ca158989c5114757`.

Changed files: concrete local engine seed import and formula-query resilience; app-shell library part declaration, A.4 resolution install hook, focused shared community store; direct engine seed tests; shared-engine acceptance test.

`LocalWorkflowEngineApi.seedInstances` validates the complete batch before a single SQLite transaction, preserves supplied ID/type/state/data/creator, accepts exact repeat rows as no-ops, rejects conflicting existing rows, and rolls back invalid batches. Nullable app-shell seed creators fail clearly.

Verification completed: engine `dart analyze` reported `No issues found!`; its A.5 seed suite reported `00:00 +7: All tests passed!`; app-shell `flutter analyze` was clean before the final shared-engine test; and the shared-engine real Tabletop test passed. It proved 11 definitions, 17 rows, Friday's 12 `goingPersonaIds` and computed `goingCount == 12`, proposal states approved/pending, and repeated accessor identity with 17 retained rows.

Frozen fixture SHA-256 remained `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`; its diff from `c5eb7aa` was empty.
