# Loom Communities Product Definition 13: Search and Permission-Aware Discovery

Status: Draft for review
Product area: 13 of 22 (Loom Communities / V2)
Source inputs: [API Reference 1.15](./Extensible%20Loom%20API%20Reference.md#115-search-ai-recommendation--digest-apis)
Predecessor: [Loom V1 Neutral Public Search Utility](../Product%20Docs/13-neutral-public-search-utility.md)

## 1. Product Definition

Search in V2 helps members find communities, spaces, people, posts, messages, documents, events,
forms, facilities, payments, and extension records they are allowed to see. It preserves the V1 neutral
search principle: search is not paid ranking, not hidden promotion, and not a bypass around privacy or
role policy.

Search is permission-aware by default. The same query can return different results depending on
Passport, community, space, role, consent, protected data policy, and member visibility.

## 2. Scope

This area covers public community search, member-visible search, cross-community search, internal
community search, AI-assisted answers, digests, indexing policy, result explanations, search receipts,
source attribution, de-indexing, and protected-context exclusions. Connections/invites are Product 12;
AI authoring is Product 11.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Permission-aware indexing | Index entries carry visibility, policy, data class, source, and deletion state. | Search cannot expose private or protected content. | 04, 14 |
| Neutral public discovery | Public community/profile search has no paid ranking or per-click monetization. | Trustworthy discovery. | 17, 22 |
| Internal search | Community members search messages, documents, events, forms, and extension records within role scope. | Makes custom apps operationally useful. | 10, 15 |
| AI answers with citations | AI summarizes permitted sources and cites records. | Improves usability without hiding source authority. | 11 |
| Search receipts | Audit and utility funding evidence, not ranking economics. | Search can be funded transparently. | 08, 22 |
| De-index and revocation | Policy or deletion changes remove or narrow entries quickly. | Data rights and trust/safety actions propagate. | 14, 17 |

## 4. Product Experience Requirements

Members should know why a result appears, what community/space it belongs to, and whether they need to
join, request access, or obtain a role. Admins should be able to configure public discoverability and
internal searchability. Search should degrade gracefully when access is denied and should never expose
protected record snippets or ad-targeting data.

## 5. User Stories

1. **As a prospective member**, I search for a public book club by name.
   End state: public community card appears with join policy.
2. **As an HOA member**, I search for pool rules.
   End state: member-visible document result appears.
3. **As a care-team member**, I search care requests.
   End state: only authorized protected records appear, with redacted audit.
4. **As a member**, I ask AI "What did I miss this week?"
   End state: answer includes only accessible posts, messages, events, and documents.
5. **As governance**, I confirm search has no paid ranking path.
   End state: search policy and receipts show no paid ordering.

## 6. End-to-End Workflows

### Workflow 1: Public community search

1. User submits public query.
2. Search service reads public index entries and ranking policy.
3. Results merge by neutral relevance and policy, not payment.
4. User opens community card, handle, or QR flow.
5. Search receipt records query metadata for audit/utility funding.

### Workflow 2: Permission-aware internal search

1. Member searches inside a community or across installed communities.
2. Search service resolves Passport, membership, role, space, consent, and data mode.
3. Index filters by visibility, data class, protected policy, deletion state, and extension export state.
4. Results return with reason, source, and action affordance.
5. Denied results are hidden or summarized only where policy permits.

### Workflow 3: AI answer from search

1. Member asks natural-language question.
2. Search retrieves permitted sources and sends citations to AI gateway.
3. AI gateway checks source policy, retention, and protected data constraints.
4. Answer includes citations, limitations, and confidence.
5. Usage/audit receipt records model, source set, and policy context.

## 7. Cross-Area Requirements

- Paid ranking, paid routing, and per-click monetization are prohibited.
- Protected vault records require explicit protected-search scope and redacted audit.
- Revocations, deletes, takedowns, blocks, and role changes must update search eligibility.
- AI answers cannot include sources the member could not open directly.
- Extension-defined records must declare indexability and export behavior.

## 8. Prototype Implications

The MVP should support public community search, installed-community search, document/post/event search,
permission filters, one AI answer flow with citations, search receipts, and de-index behavior for
deleted or private records.

## 9. FAQ

**Can advertisers buy search placement?**
No. Advertising can exist in disclosed ad surfaces, not search ranking.

**Can AI answer from protected records?**
Only if the actor has the protected scope and the answer/audit policy allows it.

## 10. Open Questions

- Which cross-community search surfaces should ship first?
- Should denied-result hints exist for private communities?
- What ranking explanations are sufficient for MVP trust?
