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
| platform-messages-entry | member | Message thread entry | sender, recipient, preview/body, read/unread, reply/mute/archive path | Messaging/events | B16/B25 |
| platform-connections-entry | member | Connections entry | suggested member, relationship status, invite/accept/decline/block path | Connections/policy | B16/B25 |
| platform-connection-invite | member | Connection invite | inviter, invite reason, accept/decline/cancel, receiver state | Connections/events | B16/B25 |
| platform-blocked-target | member | Blocked connection state | blocked member, reason/status, unblock path, safety state | Connections/safety | B16/B25 |
| platform-message-stream | member | Message stream | participants, message preview, timestamp, reply/mark-read/mute state | Messaging/events | B16/B25 |
| platform-in-stream-ad | member | In-stream sponsored item | sponsor, disclosure, content context, impression/click state | Ads/ad decision | B16/B25 |
| platform-top-banner-no-fill | member | Top banner no-fill | reserved space, no-fill reason, shell layout preserved | Ads/ad decision/App Shell | B16/B25 |
| platform-sensitive-no-fill | member | Sensitive no-fill | protected context, ad suppressed state, no content overlap | Ads/protected-data policy | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| platform-messages-entry | member opens/replies | recipient sees sent/read state | archived thread remains readable | reply disabled when blocked | non-member cannot view thread |
| platform-connections-entry | member invites/accepts/declines | recipient sees invitation state | existing connection state is readable | duplicate invite disabled | blocked users hidden from invite |
| platform-connection-invite | member accepts or declines | inviter sees accepted/declined state | invite history readable | accept disabled after expiration | blocked inviter cannot re-invite |
| platform-blocked-target | member blocks/unblocks | target cannot message while blocked | block reason/state readable | message action disabled while blocked | extensions cannot override block |
| platform-message-stream | member reads/replies/mutes | sender sees delivery/read state | muted thread remains readable | reply disabled when blocked | non-member cannot view stream |
| platform-in-stream-ad | member views sponsored item | advertiser receives impression/click event | disclosure remains visible | dismiss disabled when required | extensions cannot hide required ad slot |
| platform-top-banner-no-fill | member sees reserved shell slot | shell keeps layout stable | no-fill state visible | click disabled because no ad filled | extension cannot collapse slot |
| platform-sensitive-no-fill | member sees protected content without ad | ad decision records suppression | suppression state readable | ad click hidden | extension cannot show ad in sensitive context |

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


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `platform-messages-entry` | [thread](../../CardSurfaces/discussion-message.md) | `CommunityThreadApi` | reply/edit/delete, read/unread, moderate/mute/archive, attachments/mentions | Demo renderer must show sender, recipient, body, timestamp/read state, reply, mute/archive, and block-aware disabled states. |
| `platform-connections-entry` | [social](../../CardSurfaces/messaging-connections.md) | `CommunitySocialSurfaceApi` | invite/accept/decline/cancel, block/unblock, connection status, thread state | Demo renderer must show suggested member, relationship state, invite/accept/decline/block, and receiver state. |
| `platform-connection-invite` | [social](../../CardSurfaces/messaging-connections.md) | `CommunitySocialSurfaceApi` | invite/accept/decline/cancel, block/unblock, connection status, thread state | Demo renderer must show inviter, invite reason, accept/decline/cancel, and resulting connection status. |
| `platform-blocked-target` | [social](../../CardSurfaces/messaging-connections.md) | `CommunitySocialSurfaceApi` | block/unblock, blocked message state, safety audit | Demo renderer must show blocked target, reason/status, unblock path, and disabled message affordance. |
| `platform-message-stream` | [thread](../../CardSurfaces/discussion-message.md) | `CommunityThreadApi` | thread read/reply/mute/archive and delivery state | Demo renderer must show message stream, timestamp, sender/recipient, read state, reply, mute, and archive. |
| `platform-in-stream-ad` | [ad](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | ad decision, impression/click/no-fill, disclosure/ad-off, restore/receipt evidence | Demo renderer must show sponsored disclosure, sponsor/body, impression/click state, and content context. |
| `platform-top-banner-no-fill` | [ad](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | top banner reserved space, no-fill reason, layout preservation | Demo renderer must show reserved banner area, no-fill reason, and stable layout. |
| `platform-sensitive-no-fill` | [ad](../../CardSurfaces/ads-no-fill-ad-off.md) | `CommunityAdSurfaceApi` | sensitive-context suppression, disclosure/no-fill state | Demo renderer must show protected context, ad suppression reason, and no-overlap content state. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
