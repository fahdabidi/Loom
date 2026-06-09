# Phase A3 - API Review

Status: Completed in A3

## Scope

Experience service APIs: publishing, messaging/stream, notifications, events, forms, polls, voting.

## Review Checklist

- Pagination and bounded reads.
- Stream item taxonomy.
- Event/RSVP state transitions.
- Protected field routing for forms.
- Notification delivery and dedupe.
- Provider-authored contract tests for search, stream renderer, workflow engine, and App Shell consumers.

## OpenAPI Outputs

Record experience-service spec additions and gaps.

## A3 Contract Additions

- `CommunityPublishingApi`
- `CommunityMessagingApi`
- `CommunityNotificationApi`
- `CommunityEventsApi`
- `CommunityFormsVotingApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_experience_apis.dart` and in-memory fakes
in `app/packages/core/loom_fake_backend/lib/community_experience_fake.dart`.

## OpenAPI Follow-Ups

- Add public specs for post publish/visibility, message stream items, notification dedupe, events/RSVP,
  tickets, form submissions, protected field routing, and poll results.
- Keep stream renderer, search, ad decision, and workflow-engine consumer contracts pending until their
  phases exist.

## Validation Evidence

- `vt_publishing_publish`
- `vt_publishing_visibility`
- `vt_messaging_stream-render`
- `vt_messaging_direct-group`
- `vt_notification_deliver`
- `vt_events_rsvp`
- `vt_events_ticketing`
- `vt_forms-voting_submit`
- `vt_forms-voting_poll-results`
- `ct_forms-voting__protected-vault_sensitive-fields`

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
