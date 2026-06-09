# Phase B5 - API Review

Status: Completed

## Scope

Mosque workflow: announcement, event RSVP, volunteer signup, donation with donor visibility, protected
care request, notification, public search/AI citation, and local latest-open behavior.

## Review Checklist

- Announcement publishing: covered by `CommunityPublishingApi.publishPost`.
- Event and RSVP: covered by `CommunityEventsApi.createEvent` and `rsvp`.
- Volunteer signup: covered by `CommunityFormsVotingApi.submitForm`; contact data uses
  `sensitiveFields`.
- Donation: covered by `CommunityWalletApi.recordPayment` with `CommunityPaymentKind.donation`.
- Donor visibility: represented locally as `CommunityCoreVaultApi.setPreference` for
  `donor_visibility`.
- Care request privacy: represented by `CommunityFormsVotingApi.submitForm` plus
  `CommunityProtectedVaultApi.writeProtectedRecord`/`readProtectedRecord`.
- Notification: covered by `CommunityNotificationApi.deliver`.
- Public search/AI: announcement content is indexed through `CommunityIndexingApi.indexRecord` and
  cited through `CommunityAiGatewayApi.answerQuestion`.

## OpenAPI Outputs

- Hosted donation APIs should add first-class `donorVisibility` and receipt/tax-statement fields
  rather than relying on a generic member preference.
- Volunteer forms should eventually expose capacity, scheduling window, and coordinator assignment.
- Protected care requests need an explicit hosted resource with care-team routing, response status,
  escalation disclaimers, and audit metadata.
- Notification templates should support localized neutral/private copy for sensitive request
  confirmations.
- Search/AI OpenAPI should document that protected care details and donor visibility data are
  non-indexable.

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
