# Phase B2 - UX Decisions

Status: Completed

## Reference Sources Reviewed

Book club, poll, event, discussion, and digest examples.

## UX Patterns Extracted

- The first screen should show current book selection, vote status, and the next meeting.
- Nomination and voting are separate cards to avoid accidental duplicate submissions.
- Digest output must show citations back to indexed community content.
- Discussion is a thread entry point, not a replacement for the main stream.

## Key UX Decisions

- Empty state prompts members to nominate the first book.
- Winning-selection publish creates a stream item and a searchable record.
- Meeting RSVP shows ticket state when capacity is enforced.
- Digest failures should identify whether search, AI, or citation generation owns the failure.

## Workflow Walkthrough

`wf_book-club-headline` installs a local book club community, submits a nomination, records a vote,
creates a meeting, RSVPs, publishes the winning selection, starts a discussion, indexes the published
selection, creates a cited digest, and opens `local:ext_book_club@latest`.

## Open Questions

- Whether nominations should be anonymous by default.
- Whether digest cards should appear in the main stream or a separate recap surface.

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
