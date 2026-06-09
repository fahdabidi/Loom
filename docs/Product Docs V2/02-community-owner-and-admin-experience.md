# Loom Communities Product Definition 02: Community Owner and Admin Experience

Status: Draft for review
Product area: 2 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [Extensible Loom Product Definition](./Extensible%20Loom%20Product%20Definition.md)
Predecessor: [Loom V1 Creator Experience](../Product%20Docs/02-creator-experience.md)

## 1. Product Definition

The community owner/admin experience is how a non-technical person creates a community, gets a working
custom app built by the Skill, and runs the community day-to-day — members, roles, spaces, payments,
moderation, and growth — while owning and being able to export everything.

The owner should experience Loom as a single operating system for their community, not a pile of
infrastructure choices. The hard, trustworthy parts (identity, permissions, payments, audit,
portability, safety) are provided; the owner customizes the experience through the Skill.

## 2. Scope

Covers: owner onboarding; building/installing an extension via the Skill; permission approval;
member/role/space management; payments setup (dues/donations); moderation; ad-off purchase for the
community; analytics; export/migration; and multi-admin delegation.

Does not cover: the extension internals (Product 10), the Skill internals (Product 11), payments
mechanics (Product 08), or the App Shell structure (Product 15) — referenced where relevant.

## 3. Owner Roles

| Role | Capability |
| --- | --- |
| Owner | Full control: create/transfer/archive community, approve extensions/permissions, manage admins, pay ad-off, export. |
| Admin | Delegated management: members, roles, spaces, content, moderation, day-to-day ops. |
| Treasurer / Finance | Dues, donations, invoices, refunds, donor-detail access (gated). |
| Moderator | Reports, takedowns, restrictions. |
| Domain roles | Coach, committee, care-team lead, registrar, etc., defined by the extension. |

Roles map to scoped capabilities via `CommunityRolePolicyApi`; donor/minor/care detail requires the
relevant role plus an explicit policy.

## 4. Key Experiences

### 4.1 Create a community

- Register with the Skill → create an App ID → log in with a Loom Identity (or create one).
- Create the community: Loom assigns a `communityId`; the owner picks a friendly, unique handle
  (e.g. `@sunset-ridge-hoa`) members will search by.
- Set type, visibility (public/private/secret), and location scope.

### 4.2 Build with AI or install an extension

- Describe the community to the Skill ("an HOA with dues, architectural review, board votes, and a
  document library"); the Skill generates the extension package.
- Or pick a certified marketplace extension and configure it.
- Loom validates and certifies the package; the owner reviews requested permissions, surfaces, and
  rules in plain language and approves.
- Publish returns a QR code and shareable link for members to join.

### 4.3 Approve permissions

- The owner sees exactly which capabilities the extension requests (e.g. `community.payments.create_intent`,
  `community.minors.read`) and which surfaces it mounts, and approves the minimal set.
- High-risk capabilities (payments, minors, sensitive care, external connectors) are Tier 4+ and
  flagged for extra scrutiny.

### 4.4 Manage members, roles, and spaces

- Approve join requests and invitations; manage households and guardian/minor links.
- Assign roles; create nestable spaces (teams, committees, classes, ministries, leagues).
- Verify members where the community requires it (e.g. hyperlocal or property ownership).

### 4.5 Set up payments

- Configure dues plans, donation funds, tickets, and fees; set bounds the extension can't exceed.
- Collect via Loom-rendered payment surfaces; issue receipts; view open balances and delinquency.

### 4.6 Moderate and keep safe

- Review reports and moderation queues; restrict or suspend members; handle appeals.
- Sensitive cases (care/minor/donor) stay in the protected vault; admins see aggregates unless granted detail.

### 4.7 Turn off ads for the community

- The backend is free and ad-supported. An owner can pay a monthly amount to suppress ads across the
  community's surface for all members (members can also individually subscribe). See Product 09.

### 4.8 See analytics

- Membership growth, engagement, dues collected, donation totals, volunteer coverage, attendance,
  unresolved cases — as compact visuals that fit a phone.

### 4.9 Export and migrate

- Export the full community archive and extension state at any time; transfer to another provider
  without losing identity, members, or history.

## 5. User Stories

1. **As an owner**, I describe my community to the Skill and publish a working app with a QR code, so
   members can join immediately.
2. **As an owner**, I approve only the permissions the extension truly needs, so members' data is protected.
3. **As an admin**, I create spaces for each team/committee and assign roles, so the community is organized.
4. **As a treasurer**, I generate dues and watch a delinquency dashboard, so finances stay current.
5. **As a moderator**, I act on a report and restrict a member, with an audit trail.
6. **As an owner**, I pay monthly to turn off ads on my community's surface.
7. **As an owner**, I export my community and switch providers without losing anything.

## 6. End-to-End Workflows

### Workflow A: Build, certify, publish

Register (App ID) → log in (Passport) → create community (handle) → Skill generates package → Loom
validates + certifies → owner approves permissions/surfaces/rules → publish returns QR. (Architecture
V2 / 01 Workflow 1.)

### Workflow B: Day-two operations

Approve members → assign roles → create spaces → configure dues/funds → publish announcements →
moderate reports → review analytics.

### Workflow C: Ad-off and export

Pay community ad-off (Product 09) → later, request export/provider transfer (Product 21).

## 7. Cross-Area Requirements

- Owner actions are permission-checked and audited; sensitive data stays in the vault.
- The owner can always export and uninstall (rules/jobs disabled immediately).
- The owner cannot disable the top ad banner or in-stream ads except via the paid ad-off path.
- Backward compatibility: an owner who also runs a V1 creator channel keeps that experience.

## 8. Open Questions

- Multi-owner / co-owner model and transfer flow details.
- How much of the Skill authoring happens inside the Main app vs. an external Skill surface.
- Analytics depth for the MVP.
- Community ad-off pricing (flat vs. per-member).
