# Ticket status: CommunityPackageValidator (Ticket B)

## Item 1 of 1: community package validator + CLI + tests

Status: done

Commit hash: pending (implementation staged for commit).

loom_ux_judges test result: `00:01 +56: All tests passed!`

`dart analyze` was previously clean for this package; direct compilation and the real CLI invocation succeeded.

Full verbatim CLI output for the Tabletop Club package:

```json
{
  "status": "pass",
  "errorCount": 0,
  "warningCount": 4,
  "findings": [
    {"type":"unknown_instance_persona","message":"createdByPersonaId \"tabletop-member-03\" is not a known persona.","location":"experience/workflowInstances[3]/createdByPersonaId","isWarning":true},
    {"type":"unknown_instance_persona","message":"createdByPersonaId \"tabletop-member-04\" is not a known persona.","location":"experience/workflowInstances[4]/createdByPersonaId","isWarning":true},
    {"type":"unknown_instance_persona","message":"createdByPersonaId \"tabletop-member-05\" is not a known persona.","location":"experience/workflowInstances[5]/createdByPersonaId","isWarning":true},
    {"type":"unknown_instance_persona","message":"createdByPersonaId \"tabletop-member-06\" is not a known persona.","location":"experience/workflowInstances[6]/createdByPersonaId","isWarning":true}
  ]
}
```

(a) The single-quoted literal formula parses; no `invalid_formula_syntax` finding was emitted.
(b) Yes. The ballot `eventId` resolved to its event and its `selectedGame` cross-instance write produced no cross-instance finding.
