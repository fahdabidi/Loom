# Loom Communities Product Definition 14: Member Data Rights, Consent, and Sensitive-Data Vaults

Status: Draft for review
Product area: 14 of 22 (Loom Communities / V2)
Source inputs: [Core Thesis V2](./01-core-thesis-and-platform-principles.md), [API Reference 1.3 and 1.19](./Extensible%20Loom%20API%20Reference.md)
Predecessor: [Loom V1 Audience Data Firewall and Data Rights](../Product%20Docs/14-audience-data-firewall-and-data-rights.md)

## 1. Product Definition

Member data rights define how members understand, consent to, revoke, export, and delete data access
inside communities. The product must let communities operate while preventing owners, admins,
extensions, advertisers, providers, and AI tools from turning membership into unrestricted data access.

The protected-visibility vault is the core V2 addition: some data is too sensitive for ordinary role
visibility and must live in a dedicated policy, audit, search, and ad-exclusion path.

## 2. Scope

This area covers consent, effective permission, app and extension grants, data-use purposes, access
history, protected vault classes, export, deletion, tombstones, directory visibility, blocked members,
minor/guardian handling, donor privacy, care/pastoral notes, sensitive search, and ad exclusion.
Passport and wallet mechanics are Product 05.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Effective permission | Requested scope intersected with owner approval, role, member consent, safety policy, and platform invariant. | One consistent rule for every data access. | 05, 10, 17 |
| Purpose-bound consent | Grants include fields, purpose, duration, destination, retention, revocation, and audit. | Members know why data is used. | 11, 18 |
| Protected vault classes | Care, minor, donor, hardship, safety, and other sensitive records. | Sensitive community work can exist without broad admin exposure. | 05, 08 |
| Access history | Members and authorized admins see data access events appropriate to their role. | Builds trust and supports disputes. | 17, 19 |
| Export and deletion | Members can export and request deletion/tombstone, subject to legal/audit exceptions. | Data rights are operational. | 21 |
| Sensitive ad/search exclusion | Protected contexts are excluded from ads and ordinary indexing. | Monetization and discovery do not exploit sensitive data. | 09, 13 |

## 4. Product Experience Requirements

Members should see a data dashboard: app/extension grants, community visibility, directory settings,
protected records they can access, access history, export, deletion, and dispute/report controls.
Admins should see only the data necessary for their role. Extensions should prompt clearly and degrade
when consent is denied or revoked.

## 5. Protected Vault Classes

| Class | Examples | Default behavior |
| --- | --- | --- |
| `care` | Pastoral care, counseling, medical concern, support request. | Care-team only; redacted audit; no ads/search. |
| `minor` | Guardian consent, emergency contact, medical disclosure, youth eligibility. | Guardian/registrar/authorized coach only. |
| `donor` | Donor-identifiable giving detail, restricted fund notes. | Treasurer/donor steward only; aggregates for admins. |
| `hardship` | Waivers, scholarships, payment plans. | Finance/care roles only. |
| `safety` | Reports, moderation evidence, disputes. | Trust/safety roles only; strict retention. |

## 6. User Stories

1. **As a member**, I revoke a book club extension's access to my profile.
   End state: future calls are denied or narrowed.
2. **As a parent**, I control who sees my child's emergency data.
   End state: protected minor class limits access and audit is redacted.
3. **As a donor**, I give anonymously.
   End state: public views hide identity; finance roles can reconcile.
4. **As a member**, I export my data across communities.
   End state: export includes portable data and explains retained exceptions.
5. **As governance**, I investigate data misuse.
   End state: access receipts, grants, policies, and audit records are available.

## 7. End-to-End Workflows

### Workflow 1: Consent grant and revoke

1. Extension or app requests fields, purpose, duration, and destination.
2. Member approves, narrows, denies, or applies a default.
3. Consent engine records grant version and audit.
4. Runtime permits access only within effective permission.
5. Member revokes; future calls fail and access history updates.

### Workflow 2: Protected write/read

1. Authorized actor opens protected form or workflow.
2. Policy engine checks role, consent/guardian state, purpose, and data class.
3. Protected vault writes record with retention and audit.
4. Later read checks current policy again.
5. Redacted audit is visible to appropriate actors; ads and ordinary search receive no record.

### Workflow 3: Export/delete/tombstone

1. Member requests export, deletion, or tombstone.
2. System identifies community records, extension schemas, receipts, protected records, and legal/audit
   retention exceptions.
3. Export package is generated or delete/tombstone is applied.
4. Community and extension access is narrowed.
5. Member sees completion and retained-record explanation.

## 8. Cross-Area Requirements

- Consent is revocable, purpose-bound, versioned, and auditable.
- Protected data never enters ad targeting, general search, public analytics, or extension storage.
- Extensions must handle denied/narrowed consent paths.
- Export must include extension-defined data and explain retained audit/settlement/safety exceptions.
- Certification must test data-rights controls.

## 9. Prototype Implications

The MVP should include data dashboard basics, consent grant/revoke, protected vault class enforcement,
access receipts, redacted audit, export request, and no-fill/no-index behavior for sensitive contexts.

## 10. FAQ

**Can an owner override a member's consent?**
No for member-owned data. Some community records may have retention/legal obligations, but those must
be explicit and auditable.

**Can protected data be summarized by AI?**
Only under a protected AI policy, for authorized actors, with source limits and redacted audit.

## 11. Open Questions

- Which deletion exceptions are required for receipts, moderation, and legal retention?
- How should guardian consent transfer when a minor becomes an adult?
- What member dashboard detail is necessary without exposing sensitive audit payloads?
