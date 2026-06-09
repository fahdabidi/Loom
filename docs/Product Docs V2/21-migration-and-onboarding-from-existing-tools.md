# Loom Communities Product Definition 21: Migration and Onboarding from Existing Tools

Status: Draft for review
Product area: 21 of 22 (Loom Communities / V2)
Source inputs: [API Reference 1.17](./Extensible%20Loom%20API%20Reference.md#117-import-export-migration--provider-portability-apis)
Predecessor: [Loom V1 Migration Strategy from Existing Platforms](../Product%20Docs/21-migration-strategy-from-existing-platforms.md)

## 1. Product Definition

V2 migration helps real communities move from WhatsApp, Facebook Groups, Discord, Slack, Google Drive,
spreadsheets, HOA portals, church/mosque software, sports team apps, Eventbrite, email lists, and local
payment systems. Loom should not require a clean break on day one; it should import what is allowed,
link what cannot be imported, capture members through QR/invite, and give owners a path to export or
switch later.

## 2. Scope

This area covers owner onboarding, tool inventory, import templates, CSV/spreadsheet import, contacts
and member invite capture, document import, event/calendar import, payment/dues migration, public
metadata references, external link preservation, migration receipts, export packages, provider
transfer, and community launch communications.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Guided onboarding | Owner selects existing tools and community type. | Reduces setup friction. | 02, 20 |
| Import templates | CSV/spreadsheet/file mappings for members, spaces, dues, events, documents, facilities. | Works with messy real-world data. | 04, 08 |
| Manual re-acquisition | QR/invite/link campaign captures members when external graphs cannot be imported. | Honest onboarding without scraping. | 12 |
| Data-class mapping | Imported fields map to ordinary, protected, payment, audit, or extension data. | Sensitive records get correct policy. | 14 |
| Migration receipts | Imports, skipped rows, errors, and provenance are recorded. | Owners can review and dispute migration quality. | 17, 19 |
| Export and provider transfer | Communities can leave Loom or switch providers with custom data included. | Portability remains credible. | 06 |

## 4. Migration Stages

1. **Inventory**: identify current tools, data types, owners, legal rights, and risks.
2. **Map**: map data to communities, spaces, roles, members, payments, documents, events, and extension
   schemas.
3. **Import/link**: import allowed files/data and link unsupported sources.
4. **Invite/reacquire**: QR, email, SMS, printed flyer, and connection invites bring members in.
5. **Validate**: owner reviews counts, errors, protected classifications, and sample records.
6. **Launch**: announce community, freeze old workflows, and start using Loom.
7. **Export/transfer**: later export or provider migration remains available.

## 5. User Stories

1. **As an HOA manager**, I import member list, dues status, documents, and facilities from spreadsheets.
2. **As a mosque admin**, I import events, donation funds, volunteer lists, and public announcements.
3. **As a soccer organizer**, I import teams, parents, schedules, and registration fields.
4. **As a book club owner**, I migrate from WhatsApp and Google Calendar using invites and event import.
5. **As an owner**, I export everything if I choose to leave.

## 6. End-to-End Workflows

### Workflow 1: Tool inventory and import plan

1. Owner selects community type and current tools.
2. Import assistant proposes data mappings and risk classifications.
3. Owner uploads CSV/files or connects approved import source.
4. System runs dry-run with errors, duplicates, protected-field warnings, and counts.
5. Owner approves import plan.

### Workflow 2: Import and member reacquisition

1. Import service writes community, spaces, documents, events, dues, and extension records.
2. Protected fields route to protected vault.
3. Migration receipts record source, rows, errors, and provenance.
4. Owner sends QR/invite/link announcement to existing members.
5. Members join with Passport and confirm visibility/consent.

### Workflow 3: Export and provider transfer

1. Owner requests export or transfer.
2. System assembles community, spaces, memberships, roles, documents, payments, receipts, extension
   schemas, and custom records.
3. Protected/member data is redacted or separated by policy.
4. Destination provider receives package or owner downloads export.
5. Export receipt and checksum are recorded.

## 7. Cross-Area Requirements

- Imports must classify sensitive data before writing.
- External member graphs should not be scraped or silently imported.
- Imported data must retain provenance and deletion/export policy.
- Extension custom records must be included in export.
- Migration failures should be disputeable and auditable.

## 8. Prototype Implications

The MVP should support CSV import, document import/link, event import, dues/membership import, invite
campaign generation, migration receipt, and export package for at least HOA, mosque, soccer, and book
club examples.

## 9. FAQ

**Can Loom import WhatsApp group membership automatically?**
Generally no. It should support announcement/invite capture rather than unauthorized graph scraping.

**Can imported spreadsheets include protected data?**
Yes, if mapped to protected vault classes before import and reviewed by an authorized owner/admin.

## 10. Open Questions

- Which existing tools should get first-class import templates?
- What migration errors block launch versus remain warnings?
- How should community owners prove rights to import certain data?
