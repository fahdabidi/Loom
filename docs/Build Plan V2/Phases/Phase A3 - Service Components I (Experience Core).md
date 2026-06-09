# Phase A3 - Service Components I (Experience Core)

Layer: service
Components: Publishing Service, Messaging/Stream Service, Notification Service, Events Service,
Forms/Voting Service.
Depends on: A2
Parallelism: one agent per component
Gate: experience-service validation and contract tests pass

## 0. Prerequisite Gate

- A2 complete and committed.
- Foundation and registry tests are current.
- No stale tests for built providers.
- Service components have contract fakes for all A1/A2 dependencies.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| publishing-service | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityPublishingApi` |
| messaging-stream-service | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityMessagingApi` |
| notification-service | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityNotificationApi` |
| events-service | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityEventsApi` |
| forms-voting-service | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityFormsVotingApi` |

## 2. Agent Assignment and Parallelism

Run five component agents in parallel. Merge order:

1. Notification.
2. Publishing.
3. Messaging/Stream.
4. Events.
5. Forms/Voting.

The order allows notifications to be consumed by events/forms while preserving independent test gates.

## 3. Per-Component Build Spec

Each service owns its data and emits typed events. Services may call foundation and registry contracts.
Sibling services must not call each other synchronously. If a workflow needs sibling effects, use
Event Bus or a later workflow/engine phase.

## 4. Basic Validation Tests

Required:

- `vt_publishing_publish`
- `vt_publishing_visibility`
- `vt_messaging_stream-render`
- `vt_messaging_direct-group`
- `vt_notification_deliver`
- `vt_events_rsvp`
- `vt_events_ticketing`
- `vt_forms-voting_submit`
- `vt_forms-voting_poll-results`

## 5. Consumer-Contract Tests Authored for Dependents

Author and register:

- `ct_publishing__search_index-visible-content`
- `ct_publishing__stream-renderer_render-post`
- `ct_messaging__stream-renderer_render-message-and-ad-item`
- `ct_messaging__ad-decision_in-stream-insertion`
- `ct_events__workflow-engine_event-registration`
- `ct_forms-voting__protected-vault_sensitive-fields`
- `ct_notification__workflow-engine_delivery`

Tests for A4b/A5/A6 consumers remain pending until those phases.

## 6. Cross-Component Test Gate

Run A3 validation tests, all consumed A1/A2 provider tests, all provider tests whose consumers exist,
and affected A1/A2 regressions. Manifest gate must show no stale required tests.

## 7. Tenet-Adherence Checks

Verify service-layer no-sibling-sync rule, owned data boundaries, event emission, idempotent mutations,
and redacted audit where forms touch protected data.

## 8. Skill Contribution

Add component guides for publishing, messaging/stream, notifications, events, and forms/voting.
Guides must include common extension recipes such as announcement, thread, RSVP, poll, and protected
form.

## 9. Manifest Update

Stamp all A3 tests and resolve newly unblocked A1/A2 contract tests.

## 10. API Review

Create `Phase A3 - API Review.md`. Feed specs to `docs/API/OpenAPI/**` for publishing, messaging,
notifications, events, and forms/voting.

## 11. Definition of Done

A3 tests, regressions, manifest, Skill guides, API Review, tracker, and commit SHA complete.

## 12. Next Phase

Proceed to [Phase A4a - Service Components II (Ops and Community).md](./Phase%20A4a%20-%20Service%20Components%20II%20%28Ops%20and%20Community%29.md).
