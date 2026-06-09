# Phase B3 - Youth Soccer Headline Flow

Workflow bundle: parent joins team, guardian/minor protected data, registration payment, roster,
schedule, notifications.
Components involved: Spaces, Membership, Invitation, Protected Vault, Wallet, Events, Notification,
Role/Policy, App Shell, Extension Runtime.
UX gate: high
Gate: `wf_youth-soccer-headline` plus affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- B2 complete and committed.
- Minor/protected vault and payment tests are current.
- Youth soccer fixture package exists.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_youth-soccer-headline` | Parent joins team space, submits protected minor data, pays registration, roster and schedule are visible to authorized roles, notifications deliver. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Invite parent to team space | invitation-service, membership-service | `vt_invitation_create-revoke`, `vt_membership_join-approval` |
| Create team/roster space | spaces-service | `vt_spaces_nesting` |
| Submit guardian/minor protected data | protected-visibility-vault, forms-voting-service | `vt_protected-vault_read-gated`, `ct_forms-voting__protected-vault_sensitive-fields` |
| Pay registration | wallet-dues-donations, receipt-ledger | `vt_wallet_payment`, `ct_receipt-ledger__wallet_append-payment` |
| Create schedule and notify | events-service, notification-service | `vt_events_rsvp`, `vt_notification_deliver` |
| Coach views roster | role-policy-consent-engine | `vt_role-policy_effective-permission` |

## 3. UX Research and Decisions

Complete `Phase B3 - UX Decisions.md` before implementation work that affects UI, interaction, user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow this required format:

1. **Reference Sources Reviewed** - find several reference implementations of youth soccer guardian join, minor protected data, team roster, registration payment, schedule event, practice notification, and local card/open flow; record each source, surface/flow reviewed, why it applies, patterns observed, applicability/gaps, and review date.
2. **UX Patterns Extracted** - learn from the reference implementations and extract concrete patterns for task flow, entry points, state handling, trust/privacy/payment cues, layout density, accessibility, and error recovery.
3. **Key UX Decisions** - list the UX decisions made for Loom, with rationale, affected surfaces, and the acceptance signal or covering test.
4. **Key Implementation Decisions** - record implementation choices that materially alter UX, including component ownership, state model, layout behavior, validation behavior, copy source, and test coverage.
5. **Workflow Walkthrough** - walk through the workflow step by step, mapping each user goal/action to the screen or state, owning component, UX decision applied, and covering test.
6. **Open Questions / Tradeoffs** - capture unresolved questions, options considered, recommendation, owner, and when resolution is required.

The phase cannot be marked done if the UX Decisions file only contains generic notes or unreviewed placeholders. If no external references are available, record the internal reference surfaces reviewed and the reason external reference research was not possible.

## 4. Execution and Issue-Triage Loop

Run `wf_youth-soccer-headline`. Any issue touching protected data must first add a failing validation
or contract test in Protected Vault, Policy, Forms, or Wallet as appropriate.

## 5. Per-Component Regression Gate

Run all tests for altered components plus all workflows involving Protected Vault, Wallet, Events,
Membership, or App Shell.

## 6. Skill Contribution

Add:

- `Skill/workflows/youth-soccer-headline.md`
- Worked soccer package under `Skill/examples/youth-soccer/`

Update component guides for protected vault, wallet, events, and role policy with youth-sports gotchas.

## 7. Manifest Update

Stamp workflow and affected component tests.

## 8. API Review

Create `Phase B3 - API Review.md`. Record guardian/minor, payment, roster, schedule, and notification
contract gaps.

## 9. Definition of Done

Youth soccer workflow passes, protected data assertions pass, regressions pass, Skill/example updated,
manifest current, UX/API docs filed, tracker and commit SHA recorded.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B4 - HOA Headline Flow.md](./Phase%20B4%20-%20HOA%20Headline%20Flow.md).
