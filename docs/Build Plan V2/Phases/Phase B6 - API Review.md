# Phase B6 - API Review

Status: Completed

## Scope

Required shell navigation, Messages, Connections, invite/block behavior, stream rendering, in-stream ad
disclosure, top banner fill/no-fill behavior, and sensitive-context no-fill.

## Review Checklist

- Required nav and shell contracts: covered by `CommunityAppShellRuntime`, `NavigationPanelProps`, and
  `AdSlotProps`.
- Message stream: covered by `CommunityMessagingApi.sendMessage` and `renderStream`.
- Connection invite/block behavior: covered by `CommunityConnectionsApi.invite`, `block`, and
  `canInvite`.
- Connections shell affordance: covered by `ConnectionsShellProps.canInvite`.
- In-stream ad disclosure: covered by `renderAdStreamItem` and the `Sponsored` disclosure token.
- In-stream/top-banner fill: covered by `CommunityAdCampaignApi.createCampaign` and
  `CommunityAdDecisionApi.decide`.
- Sensitive context no-fill: covered by `CommunityAdDecisionApi.decide(sensitiveContext: true)`.

## OpenAPI Outputs

- Hosted App Shell OpenAPI should expose a formal shell invariant/certification endpoint for required
  navigation and ad surfaces.
- Messaging OpenAPI should add thread participants, unread count, and request/inbox state when the
  visual inbox is built.
- Connections OpenAPI should add invite request states, expiration, report/escalation hooks, and block
  reason/audit metadata.
- Ad Decision OpenAPI should formalize slot taxonomy, disclosure text, no-fill reason codes, and
  sensitive-context classification.
- Stream Renderer contract should define a stable ad stream item schema with disclosure, campaign ID,
  click/impression events, and accessibility labels.

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
