# Phase B3 - UX Decisions

Status: Completed

## Reference Sources Reviewed

Youth sports registration, guardian consent, roster, schedule, and payment patterns.

## UX Patterns Extracted

- Protected minor data is never displayed directly in roster cards.
- Guardian registration and payment are separate states so failed payment does not expose protected data.
- Team spaces are the roster boundary.
- Schedule notifications should dedupe by event/reminder key.

## Key UX Decisions

- Roster views show approved member/team state, not sensitive minor fields.
- Protected-vault reads must show redacted values unless the actor has the required permission.
- Practice reminders are local notification events in the preliminary app.

## Workflow Walkthrough

`wf_youth-soccer-headline` installs a local youth soccer community, approves membership, creates the
team space, stores protected minor data, records registration payment, creates a practice event,
delivers a reminder, and opens `local:ext_youth_soccer@latest`.

## Open Questions

- How much roster data guardians can export.
- Whether team chat belongs in the headline workflow or the later messaging phase.

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
