# Phase A6 - API Review

Status: Template

## Scope

UX micro-component contracts: App Shell, community card, nav panel, stream renderer, connections shell,
ad slots, payment surface, data dashboard/consent, Loom Communities Demo App, and local in-app backend
adapter.

## Review Checklist

- Required nav entries.
- App Shell latest-version route behavior.
- Community-card branding props: display name, tagline, logo, card image, hero image, category, accent
  color, alt/decorative metadata, and fallback state.
- Stream item rendering contracts.
- Ad slot fill/no-fill contracts.
- Payment surface and consent prompt ownership.
- Accessibility and visual test hooks.
- Demo App empty-state and `Add Community` command.
- Local file loader contract for extension packages and initialization packages.
- Local asset cache and card-image loading behavior.
- Local fake-backend import/reset/reload APIs.
- Stubbed API behavior when no hosted backend is present.

## OpenAPI Outputs

Record App Shell, UI, local-loader, and local fake-backend contract gaps.

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
