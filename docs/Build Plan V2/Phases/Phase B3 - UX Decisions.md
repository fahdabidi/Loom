# Phase B3 - UX Decisions

Status: Complete - R20 second-pass UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for youth soccer guardian join, minor protected data, team roster, registration payment, schedule event, practice notification, and local card/open flow. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [TeamSnap](https://www.teamsnap.com/) and [TeamSnap ONE](https://www.teamsnap.com/one) | Youth sports registration, payments, schedules, communication, parent app. | B3 is a youth team membership, registration, schedule, and communication workflow. | Youth sports products bundle registration/payment, roster, schedule, reminders, and parent communication. | Loom must split these into reusable community services and protected data contracts. | 2026-06-09 |
| [SportsEngine HQ](https://www.sportsengine.com/hq/) | Online registration, payments, auto scheduling, mobile team app. | B3 needs parent registration payment, schedule, and roster visibility. | Registration, payment, and team mobile access are tied together for parents. | Loom keeps payment and roster permissions separated by component. | 2026-06-09 |
| [PlayMetrics](https://home.playmetrics.com/) and [PlayMetrics club system overview](https://help.playmetrics.com/hc/en-us/articles/360021201253-An-Introduction-to-the-PlayMetrics-Club-System) | Registration/payments, roles, roster/team formation, communication, notifications. | B3 needs role-aware access for administrators, coaches, and player contacts. | Account roles have different access; communications and notifications are shared member tools. | Loom's role/policy engine must explicitly gate protected records and roster details. | 2026-06-09 |
| [PlayMetrics registration and payments](https://home.playmetrics.com/clubs/registration) | Program dashboard, registrations, money collected, player statuses, waitlists. | Registration payment and player status need clear admin/member states. | Payment state, discounts, refunds, overdue accounts, and player status belong together in admin context. | B3 validates one registration payment; payment plans/refunds are later. | 2026-06-09 |
| [FTC COPPA Rule](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa) and [COPPA FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions) | Child privacy, notice, parental consent before collecting child personal information. | B3 collects minor birthdate and protected player data. | Parent notice/consent and data minimization are required patterns for child data. | Loom docs are not legal advice; protected-vault and consent flows must be reviewed before release. | 2026-06-09 |
| [eCFR 16 CFR Part 312](https://www.ecfr.gov/current/title-16/chapter-I/subchapter-C/part-312) | Separate consent options for collection/use versus disclosure. | Some youth sports data should be usable for team operations without broad disclosure. | Consent should distinguish operation-critical use from third-party disclosure. | B3 stores protected data behind permissions; separate disclosure consent is a future compliance task. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Guardian-first membership | TeamSnap, SportsEngine, PlayMetrics | Parents act for minors and need clear join/approval status. | Membership request/approval is tied to guardian passport, not child-owned account. | Need stronger legal/consent review before release. |
| Minor data minimization and redaction | FTC COPPA, eCFR | Sensitive child data should not leak into public roster or card surfaces. | Protected Vault stores minor birthdate and returns redacted reads. | Coaches may need operational access; permissions must be explicit. |
| Role-limited roster visibility | PlayMetrics roles | Coaches/admins need roster data, parents need only appropriate team context. | Role/Policy gates protected read and roster visibility. | B3 validates permission, not full visual roster variants. |
| Registration payment tied to team enrollment | SportsEngine, PlayMetrics registration | Parents need payment confirmation and admins need paid status. | Wallet records registration dues with receipt-ledger coverage. | Payment plans/refunds are not in B3. |
| Schedule plus notification loop | TeamSnap, SportsEngine mobile app | Families rely on practice/game reminders. | Events creates practice; Notification delivers reminder. | Notification preferences and quiet hours are later. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Parent/guardian joins and is approved before child data is collected. | Child data should not be collected until community membership is established. | Membership, Invitation, Role/Policy. | `vt_membership_join-approval`, `wf_youth-soccer-headline` |
| Minor birthdate is protected-vault data and never card/public roster data. | Sensitive minor information must stay permission-gated and redacted by default. | Protected Visibility Vault, Roster surfaces. | `vt_protected-vault_read-gated`, `wf_youth-soccer-headline` |
| Coach/admin access is permission-based, not implied by space membership alone. | Role-limited roster access reduces accidental disclosure. | Role/Policy/Consent Engine. | `vt_role-policy_effective-permission`, `wf_youth-soccer-headline` |
| Registration payment is recorded before team schedule/notifications are treated as active. | Payment status is part of enrollment readiness. | Wallet/Dues/Donations, Receipt Ledger. | `vt_wallet_payment`, `ct_receipt-ledger__wallet_append-payment`, `wf_youth-soccer-headline` |
| Schedule and notification are separate assertions. | A practice can exist even if reminder delivery fails; failures need separate ownership. | Events Service, Notification Service. | `vt_events_rsvp`, `vt_notification_deliver`, `wf_youth-soccer-headline` |
| Local card/open remains shell-owned and does not expose minor data. | The community card should advertise the team, not child information. | Community Card, App Shell Runtime. | `wf_youth-soccer-headline` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Keep B3 as a workflow over protected services, not a visual roster screen. | Prevents premature display of minor data before UX/privacy review. | Workflow Validation Harness. | `wf_youth-soccer-headline` |
| Use `minor_birthdate` as the protected-data sentinel field. | Tests can prove redaction without exposing broader player profiles. | Protected Visibility Vault. | `wf_youth-soccer-headline` |
| Grant `protected.read` explicitly in the harness. | Permission requirements are visible in the test setup. | Role/Policy/Consent Engine. | `wf_youth-soccer-headline` |
| Model registration as `CommunityPaymentKind.dues`. | Keeps registration payment inside the community payment/audit model. | Wallet/Dues/Donations. | `wf_youth-soccer-headline` |
| Notify by dedupe key. | Practice reminders are idempotent and avoid duplicate sends. | Notification Service. | `vt_notification_deliver`, `wf_youth-soccer-headline` |

## Workflow Walkthrough

Workflow under review: `wf_youth-soccer-headline`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Request/approve guardian membership. | Guardian membership moves to active after owner approval. | Membership Service. | Guardian-first membership. | `wf_youth-soccer-headline` |
| 2 | Create team space. | Team space `U10 Falcons` is created. | Spaces Service. | Role-limited roster context. | `wf_youth-soccer-headline` |
| 3 | Collect protected minor field. | Minor birthdate is written to protected vault and read redacted. | Protected Visibility Vault. | Minor data minimization and redaction. | `wf_youth-soccer-headline` |
| 4 | Record registration payment. | Registration dues payment is recorded. | Wallet/Dues/Donations. | Payment tied to enrollment. | `wf_youth-soccer-headline` |
| 5 | Create schedule event. | Saturday practice event is created with capacity. | Events Service. | Schedule loop. | `wf_youth-soccer-headline` |
| 6 | Send notification. | Practice reminder is delivered once by dedupe key. | Notification Service. | Notification loop. | `wf_youth-soccer-headline` |
| 7 | Open local team extension. | App Shell opens `local:ext_youth_soccer@latest`. | App Shell Runtime. | Shell-owned local open. | `wf_youth-soccer-headline` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| What minor data can appear on coach roster screens? | Birthdate, age band only, no sensitive fields. | Use age band/eligibility status in future UI; keep birthdate protected. | Protected Vault / Role Policy. | Before visual roster UI |
| Is COPPA consent sufficient for all youth sports workflows? | Generic consent, separate consent per disclosure/use. | Treat B3 as a technical privacy baseline and require legal/privacy review before production. | Trust/Safety / Legal. | Production release |
| Should registration payments support installments now? | One payment now, installments now. | One payment for headline flow; installments/refunds in later payment UX. | Wallet/Dues/Donations. | Payment polish |
| Should notifications include location and player info? | Full details, minimal reminder. | Minimal reminder in B3; richer details require notification preferences and protected-data rules. | Notification Service. | Notification preference phase |

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
