# Loom Communities Product Definition 17: Trust, Safety, Moderation, and Compliance

Status: Draft for review
Product area: 17 of 22 (Loom Communities / V2)
Source inputs: [API Reference 1.16](./Extensible%20Loom%20API%20Reference.md#116-trust-safety-moderation--audit-apis)
Predecessor: [Loom V1 Trust, Safety, Fraud, and Compliance](../Product%20Docs/17-trust-safety-fraud-and-compliance.md)

## 1. Product Definition

Trust, safety, moderation, and compliance protect members, communities, providers, advertisers,
builders, and Loom itself from abuse. V2 needs safety for real-world communities: harassment, spam,
minor safety, donor/care privacy, payment fraud, moderation disputes, extension abuse, ad misuse,
provider incidents, unsafe AI output, and export/data-rights violations.

Trust should be operational inside the platform through contracts, receipts, audit, policy versions,
moderation cases, and certification, not left to each extension.

## 2. Scope

This area covers abuse reports, moderation labels, takedowns, member blocks, spam/invite abuse, payment
fraud, ad fraud, protected data incidents, extension suspension, provider incidents, AI safety, dispute
resolution, audit records, compliance exports, policy versions, and appeal paths.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Abuse report API | Reports against members, content, messages, ads, extensions, providers, or AI outputs. | One intake path across custom communities. | 15, 18 |
| Moderation case/task | Versioned case workflow with evidence, decisions, appeal, and audit. | Communities can handle local moderation with governance backup. | 04, 10 |
| Protected-data incident controls | Sensitive data exposure has special audit, notification, and remediation. | Care/minor/donor workflows remain trustworthy. | 14 |
| Fraud controls | Payment, ad, invite, receipt, and settlement abuse detection. | Prevents financial and platform manipulation. | 08, 09 |
| Extension/provider suspension | Capability-scoped limits and runtime fail-closed behavior. | Unsafe actors can be contained precisely. | 16, 19 |
| Compliance policy versions | Decisions reference the policy version in force. | Disputes and audits are explainable. | 19 |

## 4. Product Experience Requirements

Members should be able to report, block, mute, appeal where allowed, and see safety status without
exposing private evidence. Owners/admins need queues, labels, role-scoped moderation, and escalation
paths. Governance needs cross-community incident tools, evidence, certification actions, and public or
private reporting rules.

## 5. User Stories

1. **As a member**, I report harassment in a community message.
   End state: moderation case is created and block/mute applies immediately.
2. **As an admin**, I remove spam invite links.
   End state: invite is revoked and abuse signals update.
3. **As governance**, I suspend an extension that mishandles protected data.
   End state: runtime blocks version and owners are notified.
4. **As a treasurer**, I dispute a chargeback or fraud adjustment.
   End state: evidence-backed case is reviewed.
5. **As a parent**, I report unsafe youth-sports data visibility.
   End state: protected data incident path is triggered.

## 6. End-to-End Workflows

### Workflow 1: Abuse report and moderation

1. Reporter submits report with context, target, evidence, and policy category.
2. Trust/safety service creates case/task and applies immediate block/mute where requested.
3. Moderator reviews evidence under role policy.
4. Outcome applies label, restriction, takedown, warning, suspension, or dismissal.
5. Parties receive notifications and appeal options.

### Workflow 2: Extension or provider incident

1. Audit, report, or automated probe detects unsafe behavior.
2. Incident record links actor, version, key, data class, community, and evidence.
3. Governance limits, suspends, revokes, or requests remediation by capability.
4. App Shell/runtime fail closed for revoked scopes.
5. Owners and members receive migration, update, or export options.

### Workflow 3: Fraud and settlement adjustment

1. Fraud service flags payment, ad, receipt, invite, or settlement anomaly.
2. Receipt ledger preserves original events and appends fraud signal.
3. Settlement engine holds or adjusts payout.
4. Affected actor can dispute with evidence.
5. Final adjustment record is appended.

## 7. Cross-Area Requirements

- Safety actions must be policy-versioned, auditable, and appealable where appropriate.
- Protected data incidents have stricter redaction and notification rules.
- Extension/provider/app revocation must propagate to App Shell and runtime immediately.
- Fraud adjustments append records; they do not delete original receipts.
- External embedded content must preserve source attribution and platform rules where used.

## 8. Prototype Implications

The MVP should include abuse report, block/mute, moderation case, extension suspension, provider
incident stub, fraud signal stub, protected-data incident flag, and dispute record. Deep automated
detection can be simulated.

## 9. FAQ

**Who moderates a community?**
Local admins handle ordinary community policy; governance handles platform, provider, certification,
protected-data, and cross-community incidents.

**Can an extension implement moderation alone?**
It can add UI/workflows, but official records and enforcement go through Loom trust/safety contracts.

## 10. Open Questions

- Which moderation categories are global versus community-configurable?
- What incident notifications are public, owner-only, or member-specific?
- How should minors and guardian escalation be handled in MVP?
