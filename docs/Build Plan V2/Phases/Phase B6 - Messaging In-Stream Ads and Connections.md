# Phase B6 - Messaging, In-Stream Ads, and Connections

Workflow bundle: required navigation, Messages, Connections, invite/block behavior, stream rendering,
in-stream ads, top banner behavior.
Components involved: App Shell, Navigation Panel, Messaging/Stream, Connections Graph, Connections
Shell, Stream Renderer, Ad Decision, Ad Slots, Protected Vault policy.
UX gate: high
Gate: `wf_messaging-ads-connections` plus affected component regressions pass.

## 0. Prerequisite Gate

- B5 complete and committed.
- App Shell, messaging, connections, ad decision, and protected no-fill tests are current.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_messaging-ads-connections` | Member can reach Messages and Connections from nav, send/receive stream items, invite a connection subject to block policy, and see required ad items or valid no-fill. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Nav exposes Messages/Connections | navigation-panel, app-shell-runtime | `vt_navigation-panel_messages-connections`, `vt_app-shell_required-nav` |
| Message stream renders | messaging-stream-service, stream-renderer | `vt_messaging_stream-render`, `vt_stream-renderer_ad-item-disclosure` |
| Connection invite/block path | connections-graph, connections-shell, invitation-service | `vt_connections_invite-permission`, `vt_connections-shell_invite-blocked` |
| In-stream ad inserted | ad-decision-service, stream-renderer | `ct_ad-decision__stream-renderer_in-stream-ad` |
| Top banner rendered | ad-slots, app-shell-runtime | `vt_app-shell_ad-slots` |
| Sensitive context no-fill | ad-decision-service, protected-visibility-vault | `vt_ad-decision_sensitive-no-fill` |

## 3. UX Research and Decisions

Create `Phase B6 - UX Decisions.md`. Review messaging, contacts/connections, invite/block, stream ad,
and banner ad UX. Record how the required nav remains present inside custom extensions.

## 4. Execution and Issue-Triage Loop

Run `wf_messaging-ads-connections`. Any issue that hides Messages, Connections, banner ads, or in-stream
ads first strengthens App Shell/UX validation tests.

## 5. Per-Component Regression Gate

Run all tests for altered components plus workflows involving App Shell, Messaging, Connections, Ads,
or Protected Vault.

## 6. Skill Contribution

Add:

- `Skill/workflows/messaging-ads-connections.md`

Update App Shell, navigation, stream renderer, connections shell, ad slot, and messaging component
guides with concrete extension constraints.

## 7. Manifest Update

Stamp `wf_messaging-ads-connections` and affected tests.

## 8. API Review

Create `Phase B6 - API Review.md`. Record messaging, connections, ad decision, stream item, and App
Shell contract gaps.

## 9. Definition of Done

Workflow passes, required platform invariants are proven, regressions pass, Skill updated, manifest
current, UX/API docs filed, tracker and commit SHA recorded.

## 10. Next Phase

Proceed to [Phase B7 - Ad-Off.md](./Phase%20B7%20-%20Ad-Off.md).
