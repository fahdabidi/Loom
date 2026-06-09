# Phase B4 - API Review

Status: Completed

## Scope

HOA dues, documents, facility reservation, architectural request, committee review workflow,
notification, export, and local latest-open behavior.

## Review Checklist

- Dues payment: covered by `CommunityWalletApi.recordPayment`.
- Document upload and visibility: covered by `CommunityDocumentsApi.uploadDocument` and
  `visibleDocuments`.
- Facility reservation: covered by `CommunityFacilitiesApi.reserveFacility` and
  `listReservations`.
- Architectural request: represented as `CommunityCaseTaskApi.openCase` and `transitionCase`.
- Committee review: represented by `CommunityWorkflowApi.startWorkflow` and `transition`.
- Decision notification: covered by `CommunityNotificationApi.deliver`.
- Export assembly: covered by `CommunityExportApi.assemble`.

## OpenAPI Outputs

- Existing contracts cover the local workflow.
- Hosted OpenAPI should add a first-class architectural request resource with attachment references,
  committee comments, due dates, and decision reasons.
- Export OpenAPI should add record-level inclusion lists for cases, payments, reservations,
  notifications, and workflow runs instead of only component coverage.
- Facility OpenAPI should eventually include availability/conflict checks and cancellation policy.

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
