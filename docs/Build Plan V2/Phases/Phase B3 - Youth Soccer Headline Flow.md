# Phase B3 - Youth Soccer Headline Flow

Workflow bundle: parent joins team, guardian/minor protected data, registration payment, roster,
schedule, notifications.
Components involved: Spaces, Membership, Invitation, Protected Vault, Wallet, Events, Notification,
Role/Policy, App Shell, Extension Runtime.
UX gate: high
Gate: `wf_youth-soccer-headline` plus affected component regressions pass.

## 0. Prerequisite Gate

- B2 complete and committed.
- Minor/protected vault and payment tests are current.
- Youth soccer fixture package exists.

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

Create `Phase B3 - UX Decisions.md`. Review youth sports registration, guardian consent, team roster,
schedule, and protected-form UX. Record minor-data disclosure and role-limited display decisions.

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

## 10. Next Phase

Proceed to [Phase B4 - HOA Headline Flow.md](./Phase%20B4%20-%20HOA%20Headline%20Flow.md).
