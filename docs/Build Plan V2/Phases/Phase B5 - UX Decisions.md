# Phase B5 - UX Decisions

Status: Completed

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and open tradeoffs for mosque announcements, events, volunteer signup, donations, donor
privacy, protected care requests, notifications, and local card/open flow.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [The Masjid App](https://themasjidapp.org/en-us/) | Mosque donations, events, mobile app, volunteer management | Direct mosque/community app reference | Donations, receipts, events, community updates, and volunteer management are grouped as mosque operations rather than separate apps. | Good fit for mosque-specific IA; public marketing page does not expose detailed in-app privacy states. | 2026-06-09 |
| [Masjidbox mosque management guide](https://masjidbox.com/blog/mosque-management-software-the-complete-guide) | Announcements, events, donations, volunteer operations | Current mosque management reference | Centralized admin flow for prayer/community updates, donations, events, and volunteer coordination. | Useful for capability grouping; not enough detail for protected care-request UI. | 2026-06-09 |
| [Masjid Solutions](https://masjidsolutions.net/) | Mosque/nonprofit donations, events, donor management, engagement | Mosque-specific all-in-one platform | Donations, donor management, events/programs, and community engagement are presented as first-class modules. | Strong module map; detailed member UX remains product-specific. | 2026-06-09 |
| [Tithely Church App](https://get.tithe.ly/product/church-app) | Church app events, volunteer opportunities, in-app giving, prayer requests | Adjacent faith-community UX reference | Giving, events, volunteer opportunities, and request/support features are placed in one branded community app. | Church-specific content terms need mosque-specific copy. | 2026-06-09 |
| [Tithely Prayer Wall help](https://help.tithe.ly/hc/en-us/articles/7406856265751-Using-the-Prayer-Wall-on-Your-Church-App) | Prayer/request submission and moderation | Sensitive support-request reference | Requests can be created by members and moderated/approved by admins before wider visibility. | Loom B5 keeps care requests private rather than public wall posts. | 2026-06-09 |
| [Planning Center prayer requests](https://help.planningcenter.com/en/139165-prayer-requests.html) | Form-based private prayer request intake | Useful proxy for protected care request intake | Request forms create private records/notes routed to collaborators/admins. | Planning Center profile model differs; Loom maps this to protected vault records. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Put announcements, events, giving, and volunteering in one mosque home | The Masjid App, Masjidbox, Masjid Solutions | Members should not hunt across disconnected tools for mosque operations. | The Skill example produces a single mosque extension card and local open flow covering announcement, iftar event, volunteer signup, and donation. | B5 validates workflow state, not final visual screen composition. |
| Keep giving quick but explicit about receipt and visibility | The Masjid App, Masjid Solutions, Tithely | Donors need confidence that a contribution is recorded and privacy preference is honored. | Donation uses `CommunityWalletApi.recordPayment`; donor visibility is represented as a core vault preference with anonymous selected. | Hosted backend needs richer tax receipt/export fields beyond local fake coverage. |
| Treat care requests as protected intake, not public content | Tithely Prayer Wall, Planning Center | Members may disclose sensitive needs and expect limited access. | Care request details are submitted as sensitive form fields and stored in the protected vault; only a permitted owner/admin reads the redacted record. | Later UX must clarify response SLA and emergency disclaimers. |
| Capacity and volunteer commitments should be confirmed immediately | The Masjid App, Masjidbox, Tithely | Members need clear confirmation when joining an event or volunteering. | RSVP returns a ticket code; volunteer form stores non-sensitive answers and protects phone/contact info. | B5 does not implement volunteer capacity conflicts yet. |
| Notifications close the support loop without exposing content | Push/community-app references, Planning Center | Members need confirmation that private requests were received. | Notification subject confirms receipt while excluding care-request details. | Notification templates require hosted localization/copy governance later. |

## Key UX Decisions

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| The mosque card opens a single local extension that contains announcement, event, volunteer, donation, and care request entry points. | Reference mosque apps consolidate operations into one branded community app. | Demo App card/open flow and Skill example package. | `wf_mosque-headline` opens `local:ext_mosque@latest`. |
| Donation visibility is a deliberate member choice, represented as anonymous in B5. | Faith-community giving can be socially sensitive; the UX should not imply public donor exposure. | Donation flow, member data, receipt copy. | `wf_mosque-headline` stores `donor_visibility=anonymous` before recording the donation. |
| Care request details are protected by default and never appear in normal form answers. | Sensitive support requests should route to trusted admins/care teams. | Care request form and protected vault. | `wf_mosque-headline` removes `details` from visible answers and stores a protected record. |
| Volunteer phone/contact details are protected while shift preference remains visible operational data. | Volunteer coordinators need the shift, but contact data should be permission-gated. | Volunteer signup form. | `wf_mosque-headline` keeps `shift` visible and protects `phone`. |
| Member notifications use neutral confirmation copy. | Confirmation should reassure without leaking care/request contents to notification previews. | Notification service and future push copy. | `wf_mosque-headline` sends "Your care request was received". |

## Key Implementation Decisions

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Model donor visibility as a `CommunityCoreVaultApi` preference in B5. | Lets the workflow prove privacy preference without adding payment API shape prematurely. | core-member-vault, wallet-dues-donations | `wf_mosque-headline`, A1/A4b regressions. |
| Use `CommunityFormsVotingApi.submitForm` with `sensitiveFields` for volunteer contact and care request details. | Separates operational answers from permission-gated sensitive data. | forms-voting-service, protected-visibility-vault | `wf_mosque-headline`, `vt_forms-voting_submit`, `vt_protected-vault_read-gated`. |
| Index only public announcement content for AI/search. | Keeps care requests and donor details out of search/AI citations. | publishing-service, indexing-service, ai-gateway | `wf_mosque-headline`, A4b search/AI regressions. |
| Reuse the Demo App local backend installation pattern. | Keeps B5 validation aligned with the required preliminary local flow. | loom-communities-demo-app, local-in-app-backend, app-shell-runtime | `wf_mosque-headline`, B1a regressions. |

## Workflow Walkthrough

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Publish announcement | Mosque home shows Ramadan community night announcement. | publishing-service | Consolidated mosque home. | `wf_mosque-headline` |
| 2 | Create event | Community iftar event accepts RSVPs. | events-service | Immediate commitment confirmation. | `wf_mosque-headline` |
| 3 | RSVP/sign up | Member receives a ticket code for the event. | events-service | Immediate commitment confirmation. | `wf_mosque-headline` |
| 4 | Volunteer | Shift preference remains visible; phone is protected. | forms-voting-service, protected-visibility-vault | Protect volunteer contact details. | `wf_mosque-headline` |
| 5 | Donate | Member records a donation after selecting anonymous donor visibility. | core-member-vault, wallet-dues-donations | Explicit donor privacy choice. | `wf_mosque-headline` |
| 6 | Submit protected care request | Summary is visible; details route through protected vault. | forms-voting-service, protected-visibility-vault | Care request protected by default. | `wf_mosque-headline` |
| 7 | Send notification | Member receives neutral confirmation. | notification-service | No sensitive content in notification preview. | `wf_mosque-headline` |
| 8 | Open local mosque extension | Demo App opens the installed local mosque extension. | app-shell-runtime, loom-communities-demo-app | Local Demo App is the validation target. | `wf_mosque-headline` |

## Open Questions / Tradeoffs

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should donor visibility be wallet-owned instead of a core vault preference? | Add a `donorVisibility` field to payments now; keep B5 preference and add hosted spec later. | Keep preference for B5; add wallet/OpenAPI field when hosted donations are implemented. | Wallet/API owner | Hosted backend donation API |
| Should care requests support public prayer wall posting? | Public wall, moderated wall, private care-team request. | Private care-team request is the B5 default; public prayer wall is a later optional extension pattern. | Trust/Safety + Product | Public community support features |
| Should volunteer signup include capacity/conflict checks now? | Add capacity model now; validate a single signup now. | Validate single signup now; capacity belongs in later volunteer-management UI. | Forms/Events owner | Volunteer scheduling feature |

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
