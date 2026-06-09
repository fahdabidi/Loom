# Loom Communities Product Definition 05: Identity, Passport, Wallet, and Protected Vaults

Status: Draft for review
Product area: 05 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.3, 1.13, 1.19](./Extensible%20Loom%20API%20Reference.md#1-core-community-api-families)
Predecessor: [Loom V1 Fan Passport, Wallet, Vaults, and Identity Architecture](../Product%20Docs/05-fan-passport-wallet-vaults-and-identity-architecture.md)

## 1. Product Definition

Identity in Loom Communities is portable and member-owned. A member uses one Passport across every
community, while communities hold only scoped membership and role records. Wallet, entitlement, consent,
and vault systems make paid access, dues, donations, protected data, and data rights work consistently
across custom extensions.

The V2 addition is the protected-visibility vault: sensitive data classes such as care, minors, donor
details, counseling, pastoral notes, or medical disclosures live behind stricter access, redacted audit,
search exclusion, and ad exclusion rules.

## 2. Scope

This area covers Passport identity, personas, recovery, member directory identity, pairwise/community
scoped identifiers, wallet accounts, entitlements, dues/donations payment state, core member vault,
protected-visibility vault, consent grants, and effective-permission data access. Member data rights are
expanded in Product 14; payments and settlement are Product 08.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Passport identity | Portable root identity and recovery state. | Members keep one account across communities and apps. | 03, 12, 15 |
| Community-scoped persona | Display name, avatar, directory visibility, and notification preferences for one community. | Members can present differently by context. | 04, 14 |
| Wallet and entitlements | Dues, donations, invoices, memberships, tickets, premium/ad-off, and receipts. | Payments do not fragment by extension. | 08, 09 |
| Core member vault | Portable preferences, app grants, saves, notification settings, and non-sensitive profile data. | State follows the member across certified apps. | 15, 21 |
| Protected-visibility vault | Sensitive records with special roles, redacted audit, search exclusion, and ad exclusion. | Communities can support real care/minor/donor workflows safely. | 14, 17 |
| Consent grants | Purpose-bound, revocable grants for extensions, apps, AI, search, and workflows. | Custom experiences cannot silently expand data access. | 10, 11, 14 |
| Effective permission | Requested scope intersected with owner approval, role, member consent, safety policy, and platform invariant. | A single rule governs all sensitive access. | 10, 17, 19 |

## 4. Product Experience Requirements

Members should be able to sign in once, join many communities, choose community-specific display and
visibility, review all app and extension grants, revoke consent, pay dues or donations, see receipts,
and export their data. Sensitive information must be visibly distinguished from ordinary profile or
membership data.

Owners and admins should be able to verify membership and role authority without seeing data they do
not need. For example, a treasurer can see payment receipts but not care notes; a coach may see a minor
medical disclosure only if the guardian grant and role policy permit it.

Extensions should receive a narrowed runtime identity context and use wallet/vault APIs instead of
storing payment or sensitive data themselves.

## 5. User Stories

1. **As a member**, I join a book club and an HOA with the same Passport.
   End state: two membership records point to one Passport, with distinct personas.
2. **As a parent**, I submit a child's emergency contact for soccer.
   End state: data is in the protected vault and visible only to authorized roles.
3. **As a treasurer**, I collect dues and issue receipts.
   End state: wallet and receipt ledgers show payment state without exposing unrelated member data.
4. **As a member**, I revoke an extension's access to my profile.
   End state: future runtime calls fail or degrade to public fields.
5. **As an admin**, I recover a member's account without taking over their Passport.
   End state: recovery follows Passport rules and audit records the assistance.

## 6. End-to-End Workflows

### Workflow 1: Passport creation and first community join

1. Member opens the Main Loom App from a handle, QR code, invite, or search result.
2. App creates or resolves Passport and presents community-specific persona defaults.
3. Member reviews membership, visibility, notification, and extension grants.
4. `CommunityMembershipApi` creates the membership.
5. Core member vault stores preferences; audit records the join.

### Workflow 2: Wallet payment and entitlement

1. Member opens dues, donation, ticket, invoice, or ad-off payment surface.
2. Wallet creates payment intent and idempotency key.
3. Payment provider confirms or fails payment.
4. Entitlement ledger writes access or paid status.
5. Receipt ledger records payment, refund/chargeback hooks, and settlement context.

### Workflow 3: Protected data write and read

1. Authorized actor opens a protected form, care request, minor disclosure, or donor note.
2. Policy engine validates role, purpose, consent, safety policy, and data class.
3. Protected vault stores the record under a data class and retention policy.
4. Later read requests are checked again and generate redacted audit.
5. Search, ads, and ordinary analytics receive no identifiable protected record.

### Workflow 4: Consent grant and revoke

1. Extension requests profile, directory, payment, protected, AI, or workflow data.
2. Member sees purpose, fields, duration, destination, and retention.
3. Consent engine records grant, denial, narrowed grant, or revocation.
4. Runtime bridge enforces the latest consent version on every call.

## 7. Cross-Area Requirements

- Communities never own Passport identity; they own only scoped memberships and roles.
- Wallet and vault mutations require idempotency, versioning, audit, and export policy.
- Protected vault data is excluded from ads, general search, and default analytics.
- Every extension data access is bounded by effective permission and certification tier.
- App Shell must expose member controls for grants, payments, receipts, and data export.

## 8. Prototype Implications

The MVP needs Passport resolution, community persona, membership link, wallet/dues simulation,
entitlement state, consent grants, core vault preferences, and one protected vault class for each anchor
vertical that needs it: minor for youth soccer, donor/care for mosque, and confidential request for HOA.

## 9. FAQ

**Does a community admin see member wallet details?**
Only the receipt and payment state needed for their role. Raw payment credentials stay outside the
community and extension boundary.

**Can an extension store protected data itself?**
No. It may define schema and UI, but protected data is written through the protected vault contract.

**Can members use different names in different communities?**
Yes. Passport is stable; personas and directory visibility are community-scoped.

## 10. Open Questions

- Which protected vault classes are mandatory for MVP certification?
- How should guardian/minor relationships be represented across multiple communities?
- What recovery flow balances accessibility with account-takeover risk?
