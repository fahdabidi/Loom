# Loom Communities Product Definition 20: MVP / Prototype Roadmap

Status: Draft for review
Product area: 20 of 22 (Loom Communities / V2)
Source inputs: [Extensible Loom Product Definition 9](./Extensible%20Loom%20Product%20Definition.md#9-mvp-scope)
Predecessor: [Loom V1 MVP / Prototype Roadmap](../Product%20Docs/20-mvp-prototype-roadmap.md)

## 1. Product Definition

The MVP proves the V2 thesis: an owner can create a community, use the Skill to generate a custom
extension, publish/install it into the Main Loom App, onboard members by handle/QR/invite, run real
community workflows, accept payments or donations where needed, enforce data rights, show required ad
surfaces or ad-off, and export/migrate state.

The MVP is not a full marketplace or production-scale backend. It is a coherent end-to-end prototype
across several verticals that exercises the platform primitives.

## 2. Scope

This area covers MVP anchor verticals, required system set, prototype workflows, sequencing, success
criteria, simulated versus real integrations, and explicit deferrals. The detailed phased build plan is
separate under Build Plan V2.

## 3. Key Features to Prove First

| Feature | Prototype proof |
| --- | --- |
| Community creation | Owner creates community, handle, QR, profile, roles, and spaces. |
| Main Loom App | Member sees community card, nav panel, Messages, Connections, ads, and extension UI. |
| Skill-built extension | Skill generates package, fixtures, tests, and installable artifact. |
| Extension runtime | Rules/workflows/jobs call fixed Loom APIs through runtime bridge. |
| Payments | Dues/donations/tickets/ad-off use wallet and receipts, even if payment is simulated. |
| Protected vault | Minor/donor/care/confidential records use protected policy. |
| Discovery | Handle, QR, invite, and basic search work. |
| Ads/ad-off | Required ad slots show; ad-off suppresses eligible ads. |
| Certification | Package validator and risk tier catch violations. |
| Export/migration | Community and extension data export works. |

## 4. Anchor Verticals

| Vertical | Why it matters | MVP workflows |
| --- | --- | --- |
| Book club | Low-risk social/hobby baseline. | Choose book, schedule meeting, discuss, vote. |
| Youth soccer | Minors, teams, schedules, registration, guardian data. | Register player, pay fee, roster, event reminders. |
| HOA | Payments, facilities, documents, approvals, notices. | Dues, architectural request, pool reservation, documents. |
| Mosque | Donations, events, volunteers, classes, care/donor privacy. | Donate, RSVP, volunteer, care request, announcements. |

## 5. MVP System Set

Required components:

- Community Registry, Spaces, Membership, Role/Policy/Consent.
- Passport, Core Vault, Protected Vault, Connections Graph.
- App Shell, community cards, nav panel, stream renderer, Messages, Connections, ad slots, payment surface.
- Extension Registry, Runtime Bridge, Event Bus, Rules, Workflows, Jobs, Data Schema Store.
- Publishing, Messaging, Notifications, Events, Forms/Voting, Case/Task, Documents, Facilities.
- Wallet/Dues/Donations, Receipt Ledger, Settlement Simulator, Ads Service.
- Search/AI digest, Import/Export, Trust/Safety, Certification.
- Skill skeleton with component/workflow guides and examples.

## 6. User Stories

1. **As an owner**, I generate and install a book club extension with the Skill.
2. **As a parent**, I register a child for soccer and submit protected data.
3. **As an HOA member**, I pay dues and submit an architectural request.
4. **As a mosque donor**, I donate and choose donor visibility.
5. **As a member**, I export my data and see extension records included.

## 7. End-to-End Prototype Workflows

### Workflow 1: Build, publish, discover, install

1. Owner describes community to Skill.
2. Skill outputs package, tests, fixtures, and docs.
3. Validator/certification pass.
4. Community gets handle/QR.
5. Member scans, joins, and opens latest certified extension.

### Workflow 2: Book club headline flow

1. Owner creates club and meeting cadence.
2. Members nominate books and vote.
3. Winning book creates event and discussion thread.
4. Digest/search can summarize permitted discussion.

### Workflow 3: Youth soccer headline flow

1. Parent joins team space.
2. Registration collects guardian/minor data in protected vault.
3. Fee payment records entitlement/receipt.
4. Coach sees roster and schedule within role policy.

### Workflow 4: HOA headline flow

1. Member pays dues.
2. Member submits architectural request with attachments.
3. Committee workflow reviews and decides.
4. Decision, documents, and audit are exportable.

### Workflow 5: Mosque headline flow

1. Member joins mosque and relevant spaces.
2. Member donates with donor visibility.
3. Member RSVPs or volunteers for event.
4. Care request uses protected vault.

## 8. Sequencing

1. Foundation primitives: identity, policy, vaults, receipts, event bus, fakes.
2. Registry/control plane: communities, spaces, extensions, certification.
3. Experience services: publishing, messaging, events, forms, payments, ads, search.
4. Extension engines: runtime, rules, workflows, jobs, schemas.
5. UX micro-components: app shell, cards, nav, stream, connections, payments, ad slots.
6. Workflows: build/publish/install and vertical demos.

## 9. Explicit Deferrals

- Production payment provider and payouts can be simulated.
- Full advertiser marketplace can be faked behind ad decision API.
- External provider marketplace can start with fake providers and scorecards.
- Third-party apps can wait until Main Loom App proves the shell.
- Sandboxed functions can be limited to one or two examples.

## 10. Success Criteria

- Each anchor vertical runs end-to-end in the Main Loom App.
- Required App Shell structure and ads/ad-off are visible.
- Protected data, consent, and search exclusions are demonstrable.
- Extension package validates and can update to latest.
- Export includes community, membership, payments, receipts, and extension data.

## 11. FAQ

**Why multiple verticals in MVP?**
Because V2 is a platform. One vertical can hide missing primitives; four anchor verticals expose the
common API surface.

**Is the phased build plan executed here?**
No. This doc defines product scope. Build Plan V2 will sequence implementation.

## 12. Open Questions

- Which vertical should be the first live demo?
- What minimum UI polish is required for owner review?
- Which workflows need real payment integration before external demos?
