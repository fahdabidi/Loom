# Phase B5 - Mosque Headline Flow

Workflow bundle: announcements, event RSVP, volunteer signup, donation with donor visibility, care
request through protected vault.
Components involved: Publishing, Events, Forms/Voting, Protected Vault, Wallet, Notification, Search/AI,
Role/Policy, App Shell.
UX gate: high
Gate: `wf_mosque-headline` plus affected component regressions pass.

## 0. Prerequisite Gate

- B4 complete and committed.
- Donation, protected-vault, event, form, and notification tests are current.
- Mosque example package exists.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_mosque-headline` | Member sees announcements, RSVPs or volunteers, donates with selected donor visibility, submits protected care request, and receives notifications. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Publish announcement | publishing-service | `vt_publishing_publish` |
| RSVP to event | events-service | `vt_events_rsvp` |
| Volunteer form | forms-voting-service | `vt_forms-voting_submit` |
| Donate with visibility | wallet-dues-donations, protected-visibility-vault | `vt_wallet_payment`, `vt_protected-vault_read-gated` |
| Submit care request | protected-visibility-vault, role-policy-consent-engine | `vt_protected-vault_read-gated`, `vt_role-policy_effective-permission` |
| Notify members/admins | notification-service | `vt_notification_deliver` |

## 3. UX Research and Decisions

Create `Phase B5 - UX Decisions.md`. Review religious/community event, donation, volunteer, and care
request UX. Record donor privacy, care-team routing, and respectful disclosure patterns.

## 4. Execution and Issue-Triage Loop

Run `wf_mosque-headline`. Protected donor/care failures must first strengthen Protected Vault,
Role/Policy, or Wallet validation tests.

## 5. Per-Component Regression Gate

Run all tests for altered components plus workflows involving Protected Vault, Wallet, Events, Forms,
Publishing, Notification, or Search/AI.

## 6. Skill Contribution

Add:

- `Skill/workflows/mosque-headline.md`
- Mosque example extension under `Skill/examples/mosque/`

Update component guides for donations, protected vault, events, volunteer forms, and notifications.

## 7. Manifest Update

Stamp `wf_mosque-headline` and affected tests.

## 8. API Review

Create `Phase B5 - API Review.md`. Record donation, donor visibility, care request, event, volunteer,
and notification API gaps.

## 9. Definition of Done

Mosque workflow passes, regressions pass, Skill/example updated, manifest current, UX/API docs filed,
tracker and commit SHA recorded.

## 10. Next Phase

Proceed to [Phase B6 - Messaging In-Stream Ads and Connections.md](./Phase%20B6%20-%20Messaging%20In-Stream%20Ads%20and%20Connections.md).
