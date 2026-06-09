# Loom Communities Product Definition 08: Payments, Dues, Donations, Receipts, and Settlement

Status: Draft for review
Product area: 08 of 22 (Loom Communities / V2)
Source inputs: [API Reference 1.13](./Extensible%20Loom%20API%20Reference.md#113-payments-dues-donations-invoices--receipts-apis)
Predecessor: [Loom V1 Revenue, Receipts, Ledgers, and Settlement](../Product%20Docs/08-revenue-receipts-ledgers-and-settlement.md)

## 1. Product Definition

Payments in Loom Communities support practical community money flows: dues, donations, invoices,
tickets, facility reservations, event fees, classes, campaigns, ad-off, premium features, refunds,
chargebacks, receipts, and settlement. The member-facing product should feel simple, but every economic
mutation must be auditable, idempotent, versioned, and exportable.

V2 reuses the V1 receipt/settlement discipline but re-centers it on community operations rather than
creator media revenue.

## 2. Scope

This area covers payment purposes, payment intents, wallets, invoices, dues plans, donations, event
fees, receipts, refunds, chargebacks, payout instructions, settlement statements, tax/reserve policy,
and reconciliation. Advertising and ad-off economics are Product 09 and Product 18; business model and
incentive design are Product 22.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Dues and invoices | Recurring or one-time obligations with status, reminders, waivers, and receipts. | Communities can run basic operations without custom finance software. | 04, 10, 15 |
| Donations | Funds, campaigns, donor visibility, receipts, and protected donor detail. | Religious and nonprofit communities can accept support safely. | 14, 17 |
| Tickets and reservations | Event registration, facility booking, inventory deposit, and payment state. | Real-world activities become first-class workflows. | 10, 20 |
| Receipt ledger | Signed, typed records for payments, refunds, ad-off, donations, dues, rewards, and settlement. | Statements and disputes have evidence. | 17, 19 |
| Settlement engine | Allocates funds to community, providers, developers, advertisers, apps, and utilities. | Economics follow manifests and receipts. | 09, 22 |
| Payment surface | Standard App Shell UI for checkout, history, refund, receipts, and ad-off. | Extensions do not collect raw payment credentials. | 15 |
| Financial role policy | Treasurer, finance admin, donor steward, coach, event admin, and owner scopes. | Money access matches community role boundaries. | 05, 14 |

## 4. Product Experience Requirements

Members should see clear payment purpose, amount, recurrence, refund policy, receipt, and data use.
Owners and finance admins should see ledger status, outstanding balances, settlement statements,
refund/chargeback state, and export. Sensitive donor or hardship data should route through protected
vaults. Extensions can define a payment use case but must invoke standard wallet/payment surfaces.

## 5. User Stories

1. **As a treasurer**, I create annual HOA dues.
   End state: invoices exist and members see due status.
2. **As a parent**, I pay a soccer registration fee.
   End state: payment receipt and registration entitlement are recorded.
3. **As a donor**, I give anonymously to a mosque fund.
   End state: treasurer can reconcile donation while public/directory views hide identity.
4. **As an owner**, I view settlement for ad-off, dues, donations, and provider fees.
   End state: settlement statement explains allocation.
5. **As a member**, I request a refund.
   End state: refund/chargeback workflow records evidence without deleting original receipts.

## 6. End-to-End Workflows

### Workflow 1: Create dues plan and collect payment

1. Treasurer creates dues plan with amount, schedule, due date, waivers, reminders, and eligible roles.
2. Wallet service generates invoices for matching members.
3. Member opens payment surface in the App Shell.
4. Payment provider confirms payment.
5. Entitlement or dues status updates.
6. Receipt ledger stores `PaymentReceipt`, `DuesReceipt`, and settlement context.

### Workflow 2: Donation with protected donor visibility

1. Donor selects fund, amount, recurrence, and visibility.
2. Wallet collects payment through standard surface.
3. Protected vault stores donor-identifiable detail where policy requires.
4. Treasurer sees finance view; general admins see aggregate fund status.
5. Receipt and settlement records are created.

### Workflow 3: Refund, chargeback, or adjustment

1. Member, provider, or finance admin opens dispute/refund request.
2. System gathers payment receipt, policy version, role, and event context.
3. Refund/chargeback record is appended; original receipt remains.
4. Settlement engine applies adjustment to future statements.
5. Parties see status and evidence appropriate to their role.

### Workflow 4: Settlement run

1. Settlement engine reads payment, ad, ad-off, provider, extension, and utility receipts.
2. Manifests define allocation rules and reserves.
3. Statements are generated for community, provider, developer, app, and utility participants.
4. Payout instructions are applied.
5. Audit and export packages include statements and receipt references.

## 7. Cross-Area Requirements

- Payment credentials never enter extension storage.
- Every economic mutation is idempotent and has a receipt.
- Protected donor, hardship, minor, or care-related data must use protected vault policy.
- Settlement must account for ad-off and mandatory ad economics.
- Export must include finance records with privacy-aware redaction.

## 8. Prototype Implications

The MVP should simulate payments but implement the durable models: dues plan, invoice, payment receipt,
entitlement, donation fund, refund/adjustment record, and settlement statement. External money movement
can be stubbed; receipt and state transitions cannot be skipped.

## 9. FAQ

**Can an extension implement its own checkout?**
No. It can start a payment intent and define context, but checkout and receipts use the standard Loom
payment surface.

**Do all donations expose donor identity to admins?**
No. Donor visibility is role-scoped and can route identifiable detail through the protected vault.

## 10. Open Questions

- Which payment provider should be the first real integration?
- Which tax and donation receipt rules must be modeled for launch verticals?
- How much accounting export is required for HOA and nonprofit MVP credibility?
