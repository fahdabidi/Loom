# B25 Product Docs To Evidence Reconciliation - b25-v4-pass-36-app-shell-capability-precheck

Decision: fail

## App Shell Capability Review

Status: fail

Missing capabilities:

- screenshot-proven minimized/medium/expanded state transitions
- screenshot-proven pinned surfaces
- main community-list card presentation states
- explicit renderer-selection proof

## Findings

| Finding | Severity | Community | Workflow | Required fix |
| --- | --- | --- | --- | --- |
| $(System.Collections.Specialized.OrderedDictionary.findingId) | $(System.Collections.Specialized.OrderedDictionary.severity) | Garden Club | $(System.Collections.Specialized.OrderedDictionary.workflowId) | Recapture and, if needed, implement the App Shell so Garden Club workflow surfaces visibly demonstrate minimized off-focus cards, a medium in-focus card, and a tap-expanded product surface for the same workflow/persona. The after screenshots must show the transition and the action surface, not just a static card list. |
| $(System.Collections.Specialized.OrderedDictionary.findingId) | $(System.Collections.Specialized.OrderedDictionary.severity) | Cedar Commons HOA | $(System.Collections.Specialized.OrderedDictionary.workflowId) | Update the community product doc or UI to identify pinned surfaces per persona/tab, then recapture screenshots proving pinned surfaces stay visible in the correct tab while non-pinned surfaces use minimized/medium/expanded behavior. |
| $(System.Collections.Specialized.OrderedDictionary.findingId) | $(System.Collections.Specialized.OrderedDictionary.severity) | Loom Communities | $(System.Collections.Specialized.OrderedDictionary.workflowId) | Add main community selection coverage to B25 evidence. Capture the list with a medium in-focus community card and minimized off-focus cards, including community-specific theme/typography/customization tokens and tap-to-open behavior. |
| $(System.Collections.Specialized.OrderedDictionary.findingId) | $(System.Collections.Specialized.OrderedDictionary.severity) | Riverside Youth Soccer | $(System.Collections.Specialized.OrderedDictionary.workflowId) | Add screenshot/review evidence that the soccer roster workflow is rendered by the roster/profile card-surface family with the documented App Shell presentation state and not by a generic fallback renderer. If the UI cannot prove this visually, update the product doc and renderer evidence rows. |

These findings must be converted into B25 remediation tickets before the next remediation pass.
