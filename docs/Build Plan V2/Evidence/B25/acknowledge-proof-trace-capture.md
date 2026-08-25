# B25_ACK trace capture — Windows emulator, Ad-Free B16

Run: `--mode targeted-precheck --communities ext_ad_free_community --phases B12,B16`
Instrumented build from the trace ticket. 26 trace lines emitted, of two kinds only.

## What fired

```
B25_ACK_CARD_AVAILABILITY {"instanceId":"ad-off-suppression-proof","currentState":"unreviewed","fanId":"ad-off-member","memberFanId":"ad-off-member","generation":0,"request":1,"transitionIds":["acknowledge-proof"]}
B25_ACK_CARD_AVAILABILITY {"instanceId":"ad-off-suppression-proof","currentState":"unreviewed","fanId":"ad-off-member","memberFanId":"ad-off-member","generation":1,"request":3,"transitionIds":["acknowledge-proof"]}
B25_ACK_CARD_AVAILABILITY {"instanceId":"ad-off-suppression-proof","currentState":"unreviewed","fanId":"ad-off-member","memberFanId":"ad-off-member","generation":2,"request":5,"transitionIds":["acknowledge-proof","request-restoration"]}
B25_ACK_CARD_AVAILABILITY {"instanceId":"ad-off-suppression-proof","currentState":"unreviewed","fanId":"ad-off-member","memberFanId":"ad-off-member","generation":2,"request":5,"transitionIds":["acknowledge-proof"]}
B25_ACK_CARD_AVAILABILITY {"instanceId":"ad-off-suppression-proof","currentState":"unreviewed","fanId":"ad-off-owner","memberFanId":"ad-off-member","generation":0,"request":1,"transitionIds":[]}
B25_ACK_ENGINE_AVAILABLE {"fanId":"ad-off-member","roleId":"ad-off-member","currentState":"unreviewed","memberFanId":"ad-off-member","allowedRoleIds":["ad-off-member"],"actorEqualsFieldKey":"memberFanId","actorEqualsFieldValue":"ad-off-member","roleClausePass":true,"actorEqualsClausePass":true,"evaluatorCandidateIds":["acknowledge-proof","request-restoration"],"finalResultIds":["acknowledge-proof","request-restoration"]}
B25_ACK_ENGINE_AVAILABLE {"fanId":"ad-off-member","roleId":"ad-off-member","currentState":"unreviewed","memberFanId":"ad-off-member","allowedRoleIds":["ad-off-member"],"actorEqualsFieldKey":"memberFanId","actorEqualsFieldValue":"ad-off-member","roleClausePass":true,"actorEqualsClausePass":true,"evaluatorCandidateIds":["acknowledge-proof"],"finalResultIds":["acknowledge-proof"]}
B25_ACK_ENGINE_AVAILABLE {"fanId":"ad-off-owner","roleId":"ad-off-owner","currentState":"unreviewed","memberFanId":"ad-off-member","allowedRoleIds":["ad-off-member"],"actorEqualsFieldKey":"memberFanId","actorEqualsFieldValue":"ad-off-member","roleClausePass":false,"actorEqualsClausePass":false,"evaluatorCandidateIds":[],"finalResultIds":[]}
```

## What did NOT fire, and was specified

| Trace | Lines |
|---|---|
| `B25_ACK_SELECTOR` | 0 |
| `B25_ACK_SIGNED_IN` | 0 |
| `B25_ACK_CARD_ERROR` | 0 |

The walkthrough definitely ran — it failed at the source-state assertion — so
`_shippedWorkflowSelector` was reached. Those traces not emitting is itself a datum:
either they were placed on a branch not taken, or not implemented as specified.

## What this establishes

- The guard PASSES. `roleClausePass: true`, `actorEqualsClausePass: true`,
  `finalResultIds: ["acknowledge-proof"]`. The action is legitimately available.
- The actor matches: `fanId` == `memberFanId` == `ad-off-member` in every trace. The
  actor-mismatch hypothesis is dead, as the previous report predicted.
- Availability is not blanket-permissive: a trace with `fanId: "ad-off-owner"` correctly
  yields `transitionIds: []`.
- `currentState` is `unreviewed` in ALL 26 traces, across card generations 0, 1 and 2.
  The state never changes.
- NO error was caught by the card (`B25_ACK_CARD_ERROR` never fired).

## What remains unresolved

Whether the button callback fired at all, and whether `applyTransition` was entered.
No trace covers those, so a missed tap and a silently non-persisting apply remain
indistinguishable. That is the gap the next instrumentation must close.
