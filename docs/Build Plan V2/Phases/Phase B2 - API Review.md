# Phase B2 - API Review

Status: Completed

## Scope

Book club workflow: nomination, voting, event, discussion, search/digest.

## Review Checklist

- Custom schema fields: nomination form uses a `book` field and no sensitive fields.
- Poll/vote state: `CommunityFormsVotingApi.submitVote` records the winning option count.
- Event creation and RSVP: `CommunityEventsApi.createEvent` and `rsvp` provide meeting/ticket state.
- Discussion visibility: `CommunityMessagingApi.sendMessage` and stream rendering cover the discussion
  thread.
- Search/AI citation coverage: `CommunityIndexingApi`, `CommunityAiGatewayApi`, and
  `CommunityDigestApi` provide cited digest output.

## OpenAPI Outputs

- No new OpenAPI gap blocks B2. Future hosted APIs should expose a vertical package schema for
  nomination/poll/event/digest defaults so the Skill can generate them without relying on examples.

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
