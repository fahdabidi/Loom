# Loom Communities Product Definition 11: AI Layer and the Skill

Status: Draft for review
Product area: 11 of 22 (Loom Communities / V2)
Source inputs: [Extensible Loom Product Definition 5-7](./Extensible%20Loom%20Product%20Definition.md#5-platform-architecture), [API Reference 1.15 and 7](./Extensible%20Loom%20API%20Reference.md)
Predecessor: [Loom V1 AI Layer](../Product%20Docs/11-ai-layer.md)

## 1. Product Definition

The AI layer has two distinct jobs. First, Loom can use AI inside the product for permission-aware
search, summaries, digests, moderation assistance, owner/admin guidance, and workflow suggestions.
Second, the Loom Skill is the provider-neutral builder process an LLM follows to generate, validate,
and maintain extensions.

The Skill is not the runtime. It is an authoring system that reads Loom docs, APIs, component
contracts, examples, and validation feedback, then outputs a compliant extension package.

## 2. Scope

This area covers runtime AI features, AI gateway policy, prompt/source attribution, permission-aware
retrieval, the Skill knowledge base, extension generation, validation loops, examples, provider-neutral
operation across LLMs, and certification feedback. Extension runtime is Product 10; search/discovery is
Product 13; protected data and consent are Product 14.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| Provider-neutral Skill | `SKILL.md` plus process docs, examples, component guides, workflow guides, and validation commands. | Owners can use ChatGPT, Claude, Gemini, or a developer workflow. | 10, 16, 20 |
| AI extension authoring | Converts owner intent into manifests, cards, routes, schemas, rules, workflows, jobs, fixtures, and tests. | Custom community apps become practical for non-developers. | 02, 10 |
| Permission-aware AI | Retrieval and generation respect role, consent, protected vault, search policy, and export state. | AI does not become a data bypass. | 05, 13, 14 |
| Source attribution | AI outputs keep source pointers and policy context. | Members and admins can verify answers and dispute misuse. | 17 |
| Validation loop | AI output is checked by package validator, certification rules, tests, and App Shell lint. | Generated code is governed by contracts, not trust in the model. | 16, 19 |
| Workflow examples | Book club, youth soccer, HOA, mosque, and other vertical examples grow with the build plan. | The Skill improves phase by phase. | 20, Build Plan V2 |

## 4. Runtime AI Layer

Runtime AI can provide community search answers, digest generation, admin help, moderation triage,
template suggestions, meeting summaries, translation, and workflow drafting. It must operate through
Loom APIs and policy-aware retrieval. It cannot directly read protected vault data, train on member data
outside policy, or emit actions without explicit role/consent checks.

## 5. The Skill

The Skill guides an LLM through this process:

1. Understand the trust boundary: Loom owns identity, roles, payments, vaults, ads, audit, and export;
   the extension owns experience and domain logic.
2. Choose community type, surfaces, and required shell structure.
3. Declare minimal permissions.
4. Compose fixed Loom APIs through config, rules, workflows, jobs, and optional functions.
5. Author cards, routes, schemas, fixtures, and tests.
6. Run validator and certification checks.
7. Publish, QR/install, run latest, and update safely.

The Skill should reference API specs and Architecture V2 cards rather than duplicating them.

## 6. Product Experience Requirements

Owners should be able to describe a community in plain language and receive a previewable extension
with clear permission prompts. Builders should get deterministic artifacts, validation errors, and
component/workflow guides beyond the OpenAPI reference. Members should see AI-generated experiences
only after certification and should understand what data any AI feature uses.

## 7. User Stories

1. **As an owner**, I ask an AI to build a book club app.
   End state: extension package validates and installs with book selection, calendar, discussion, and
   voting surfaces.
2. **As a builder**, I use the Skill to add an HOA architectural request workflow.
   End state: schema, rules, workflow, notifications, and tests are generated.
3. **As a member**, I ask for a community digest.
   End state: AI summarizes only content I can access and cites sources.
4. **As governance**, I reject AI output that requests excessive permissions.
   End state: validation returns actionable remediation.
5. **As the platform**, I enrich the Skill with every built component and workflow.
   End state: the Skill stays current with the architecture.

## 8. End-to-End Workflows

### Workflow 1: Owner builds extension with Skill

1. Owner describes community, workflows, roles, and data sensitivity.
2. Skill selects template and required Loom APIs.
3. Skill emits manifest, routes, cards, schemas, rules, workflows, jobs, fixtures, and tests.
4. Validator checks structure, permissions, shell invariants, export behavior, and test coverage.
5. Owner previews and revises.
6. Package is signed, certified, and installed.

### Workflow 2: Permission-aware AI answer

1. Member asks a question in search, messages, or extension surface.
2. AI gateway receives identity, community, space, role, consent, and query context.
3. Search retrieves only visible sources and excludes protected contexts unless explicitly allowed.
4. AI produces answer with citations and confidence.
5. Audit/usage receipt records source and policy context.

### Workflow 3: Skill enrichment

1. A component or workflow is completed in the build plan.
2. Its contract card, APIs, gotchas, fixtures, and examples are added to the Skill.
3. Master walkthrough links to the new component/workflow guide.
4. Future generated extensions use the updated guide and examples.

## 9. Cross-Area Requirements

- AI must respect effective permissions, protected vault policy, and member consent.
- Generated packages must pass the same validators as hand-written extensions.
- The Skill must preserve App Shell required structure and monetization invariants.
- AI-generated code must be attributable to package versions and build attestations.
- Skill examples must be kept current as a phase definition-of-done.

## 10. Prototype Implications

The MVP needs a rough Skill skeleton, a book club extension generated through the Skill, a validator
loop, a small prompt/source retrieval layer, one permission-aware digest/search demo, and component
guides that point to Architecture V2 contract cards.

## 11. FAQ

**Is the Skill tied to one AI provider?**
No. It is a provider-neutral instruction and artifact set.

**Can AI act without a user?**
Only through declared jobs/workflows and certified permissions; autonomous actions still call Loom APIs
with role, consent, idempotency, and audit.

## 12. Open Questions

- Which LLM/tooling surfaces should be officially tested first?
- How should generated UI be constrained for accessibility and App Shell consistency?
- What source-attribution policy is required for AI summaries in MVP?
