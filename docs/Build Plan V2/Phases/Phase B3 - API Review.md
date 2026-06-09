# Phase B3 - API Review

Status: Completed

## Scope

Youth soccer workflow: team join, guardian/minor protected data, registration payment, roster,
schedule, notifications.

## Review Checklist

- Guardian/minor data classes: represented as extension schema fields with protected-vault storage.
- Protected-vault read/write shape: `CommunityProtectedVaultApi.writeProtectedRecord` and
  `readProtectedRecord` cover permission-gated redaction.
- Registration payment and entitlement: `CommunityWalletApi.recordPayment` covers dues-style
  registration payment.
- Roster role policy: membership approval plus team space creation define the preliminary roster.
- Schedule notification payloads: `CommunityEventsApi.createEvent` and `CommunityNotificationApi`
  cover schedule/reminder behavior.

## OpenAPI Outputs

- Future OpenAPI should formalize guardian/minor profile schemas and roster-safe display rules. B3 is
  otherwise covered by existing local component contracts.

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
