# Platform Social Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Platform Social |
| Evidence community name | Member Social Space |
| Community type | Required shell social/ad invariant test app |
| Product promise | Prove Messages, Connections, invites/blocks, sponsored disclosures, and stream surfaces feel like real platform features. |
| Brand cues | Loom shell-native social surfaces, restrained ads, clear connection/message states. |
| What this must not feel like | Validation-only social workflow tiles. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Member | Message, connect, invite/block | Manage community relationships and messages. | Block/invite states must be clear and privacy-safe. | Message/connection state is visible and reversible where appropriate. |
| Moderator | Observe safety/social invariant behavior | Ensure required surfaces cannot be suppressed. | Sponsored/ad labels must be clear. | Social and ad surfaces remain accessible. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Messages | Communicate with members. | Member | thread participants, preview, unread/sent state. | Open/send |
| Connections | Manage graph. | Member | invites, connection status, block state. | Invite/block |
| Stream/ad | Show required sponsored content. | Member | disclosure, no-fill/sponsored state. | View / dismiss if allowed |

## 4. Home Screen Requirements

The app must keep Messages and Connections available from the shell and make social state readable as
product UI, not as test assertions.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Message thread | participants, latest message, unread/sent | empty/unread/sent | open, reply | generic messaging workflow |
| Connections | invitee, status, block state | invited/connected/blocked | invite, accept, block | abstract graph card |
| Sponsored item | sponsor/disclosure/body | fill/no-fill/ad-off | view | hidden required ad surface |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| messaging-thread | member | Message thread | participant/message/read state | Messaging/events | B16/B25 |
| connections-invite-block | member | Connections | invite/block state | Connections/policy | B16/B25 |
| in-stream-ad | member | Stream/ad | disclosure/no-fill state | Ads/ad decision | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| connections | member invites/blocks | recipient sees invite/blocked state | moderator observes invariant | blocked users disabled | extensions cannot hide shell surfaces |

## 8. Content And Seed Data Requirements

Use realistic message previews, member names, invite states, block reason/status, ad disclosure, and
no-fill copy.

## 9. Visual And Interaction Standard

Use shell-native social components with clear affordances, not generic validation cards. Ads must be
legible and not dominate core community tasks.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| platform-messages-entry | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | send message, reply, send invite, accept invite, connect | decline, block, mute, archive, cancel invite | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| platform-connections-entry | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | send message, reply, send invite, accept invite, connect | decline, block, mute, archive, cancel invite | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| platform-connection-invite | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | send message, reply, send invite, accept invite, connect | decline, block, mute, archive, cancel invite | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| platform-blocked-target | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| platform-message-stream | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | send message, reply, send invite, accept invite, connect | decline, block, mute, archive, cancel invite | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| platform-sensitive-no-fill | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
