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

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Platform Social product experience. | Judge current social/ad screenshots against shell-native surfaces. | open |
