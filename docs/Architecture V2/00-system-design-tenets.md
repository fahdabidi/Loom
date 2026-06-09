# Loom Communities Architecture 00: System Design Tenets (Micro-Components)

Status: Draft for review
Source product docs: [Core Thesis V2](../Product%20Docs%20V2/01-core-thesis-and-platform-principles.md), [Extensible Loom Product Definition](../Product%20Docs%20V2/Extensible%20Loom%20Product%20Definition.md)
Applies to: every Loom Communities (V2) architecture document and component design.

## 1. Purpose & scope

This document defines the **system design tenets** that every Loom Communities system, service, and UX
surface must follow, and the standard **Component Contract Card** used to document each component
against those tenets.

The driving goal is **agent-workability**: the system is decomposed into small components with
well-defined interfaces so that implementing a capability is a **well-scoped change to one component**
(plus, at most, additive changes to declared dependents), and that change is **provable by the
component's own integration tests**. A less-powerful agent can then be handed a single component,
implement it against its contract and its dependencies' fakes, and prove correctness by passing that
component's tests — **without needing global context**.

Every architecture doc in this set (01–12) links back here, documents its components as Component
Contract Cards, and includes a "How these components adhere to the tenets" section.

## 2. The ten tenets

### T1 — Single responsibility + owned data boundary

Each component owns exactly **one capability domain** and is the **sole writer** of its data. No other
component writes that data directly; others read or mutate it only through this component's contract.
Example: only the Spaces Service writes `CommunitySpace`; the Soccer extension creates a team space by
calling `CommunitySpacesApi`, never by touching space storage.

### T2 — Contract-first interfaces

A component's **only** entry point is a **versioned, typed contract** — a `Community*Api` in
`loom_api_contracts`. Consumers depend on the contract, never on the implementation. The contract is
the unit of agreement between components and between agents.

### T3 — Dependency inversion & fakeability

Every dependency is consumed **through a contract that has a fake** (the existing `loom_fake_backend`
over `loom_local_store`). A component must build and pass its tests against dependency **fakes**, so it
can be developed in isolation before its real dependencies exist.

### T4 — Acyclic, layered dependency graph

Components are assigned to layers (§4). **Synchronous** dependencies flow in **one direction** across
layers; there are **no cycles**. The only "upward" path is **asynchronous**, via the Event Bus (T8).
Sibling services in the same layer do **not** call each other synchronously.

### T5 — Scoped change / blast-radius containment

Implementing or changing a capability touches the **one owning component**, plus at most **additive,
backward-compatible** changes to the contracts of **declared** dependents. It never requires edits to
unrelated components. Every card states its blast radius explicitly so the change surface is known
before work starts.

### T6 — Per-component integration tests = definition of done

Each component ships a **contract-conformance suite** (it implements its contract correctly) plus
**integration tests against the fakes of its declared dependencies**. A component is **done when its
own tests are green**, independent of sibling components. This is the agent's acceptance gate.

### T7 — Idempotency, versioning & audit by construction

Every mutation is **idempotent** (carries an `idempotencyKey`) and **versioned**. Sensitive mutations
emit a **redacted audit event**. These are built into the contract, not added later. (Already in the
[packet model](./01-overall-system-architecture.md#4-transaction-packet-model).)

### T8 — Event-driven decoupling

Components publish **typed events** for state changes; downstream components react via **rules,
workflows, or subscriptions**, not via synchronous back-calls. The Event Bus is what keeps the
synchronous graph acyclic (T4) while still allowing "downstream" effects.

### T9 — Agent-workability ("one component = one workpackage")

A component's card is a **self-contained work package**: an agent given only the card has the
responsibility, the contract to implement, the dependency fakes to build against, the list of
capability sub-units, and the acceptance tests. No global context is required to implement it or to
verify it is done.

### T10 — UX micro-components

UI surfaces are **contract-bearing components** too. The App Shell and extension UI are composed of
small components (community card, navigation panel, Messages/stream renderer, Connections shell, ad
slots, payment surface) each with a **typed props/data contract**, the **required-structure
invariants** (top ad banner; nav panel always exposing Messages + Connections), and **visual /
interaction tests**. Extension-generated UI consumes these via the App Shell, not raw APIs.

## 3. The Component Contract Card (two-tier)

Every component is documented with this card. It is **two-tier**: the component is the unit; its
**capabilities** are separately testable sub-units.

```text
Component: <name>                 Layer: <foundation | registry | service | engine | ux>
Single responsibility: <one sentence — the one capability domain it owns> (T1)
Interface contract: <Community*Api> (vN), in loom_api_contracts (T2)
Capabilities (testable sub-units):                                        (tier 2)
  - <capability A> → <contract operations> → <sub-unit integration test>
  - <capability B> → <contract operations> → <sub-unit integration test>
Owned data: <entities this component is the sole writer of>               (T1)
Dependencies (by contract + fake): <ContractX (fake), ContractY (fake)>   (T3)
Events emitted: <type list>   Events consumed: <type list>                (T8)
Blast radius / scoped change: <what a change here touches; what is guaranteed untouched> (T5)
Integration tests (definition of done):                                    (T6)
  - component-level: <conformance + cross-capability suite>
  - per-capability: <one suite per capability sub-unit above>
Agent workpackage: <why the card is sufficient to implement in isolation; acceptance = tests green> (T9)
```

Rules for filling a card:
- **Owned data** must be disjoint from every other card (T1). If two cards claim the same entity, split
  the entity or merge the components.
- **Dependencies** list only contracts in **lower or cross-cutting** layers (T4) and each must name its
  fake (T3).
- **Blast radius** must name the dependents whose contracts may need additive change, and assert the
  rest of the system is untouched (T5).
- **Per-capability tests** map 1:1 to the capability sub-units, so an agent can implement and verify one
  capability at a time.

## 4. Dependency-graph & layering rules

Components are assigned to five layers. Synchronous calls go **downward only**; "upward" effects happen
**only** through the Event Bus.

```mermaid
flowchart TB
  subgraph UX[UX layer]
    AppShell[App Shell + UI micro-components]
  end
  subgraph Engine[Extension-engine layer]
    Runtime[Extension Runtime Bridge]
    Rules[Rule Engine]
    Workflows[Workflow Engine]
    Jobs[Job Scheduler]
    Functions[Function Runtime]
    DataSchema[Data Schema Store]
  end
  subgraph Service[Service layer (experience + economic)]
    Publishing[Publishing]
    Messaging[Messaging]
    Events[Events]
    Forms[Forms/Voting]
    CaseTask[Case/Task]
    Docs[Documents]
    Facilities[Facilities]
    SearchAI[Search/AI]
    Wallet[Wallet/Dues/Donations]
    Ads[Ads]
    Settlement[Settlement]
  end
  subgraph Registry[Registry / control-plane layer]
    CommReg[Community Registry]
    Spaces[Spaces]
    ExtReg[Extension Registry]
    Cert[Certification]
  end
  subgraph Foundation[Foundation / cross-cutting layer]
    Identity[Passport Identity]
    Policy[Role/Permission/Policy/Consent]
    Vault[Protected + Core Vaults]
    Connections[Connections Graph]
    Receipts[Receipt Ledger]
    Audit[Audit Ledger]
    EventBus[Event Bus]
    Keys[Key Management]
  end

  AppShell --> Runtime
  AppShell --> Registry
  Runtime --> Service
  Runtime --> Registry
  Runtime --> Foundation
  Rules --> Service
  Workflows --> Service
  Jobs --> Rules
  Functions --> Service
  Service --> Registry
  Service --> Foundation
  Registry --> Foundation

  Service -. emits events .-> EventBus
  EventBus -. triggers .-> Rules
  EventBus -. triggers .-> Workflows
```

Layer rules:

| Layer | May call (synchronously) | Must not |
| --- | --- | --- |
| **Foundation** | Other foundation contracts only (acyclically). | Anything in Registry/Service/Engine/UX. |
| **Registry** | Foundation. | Sibling registries' storage; Services/Engines/UX. |
| **Service** | Registry + Foundation. | **Sibling services** (coordinate via Event Bus); Engines; UX. |
| **Engine** | Service + Registry + Foundation. | UX. Reacts to Services only via the Event Bus, never a synchronous back-call. |
| **UX** | Engine (Runtime Bridge) + Registry. | Service/Foundation storage directly; it goes through the Runtime Bridge. |

The Event Bus, Audit Ledger, and Identity/Policy are **cross-cutting**: any layer may depend on them,
and they depend on nothing above Foundation, so they never create a cycle.

## 5. Integration-test discipline

Each component's tests are the contract between the agent that builds it and the rest of the system.

- **Contract-conformance suite** — proves the component implements every operation of its `Community*Api`
  with the documented request/response shapes, idempotency (T7), and error behavior.
- **Per-capability integration suites** — one per capability sub-unit on the card; each drives the
  component through the Runtime/contract and asserts owned-data writes, emitted events (T8), and audit
  records (T7).
- **Dependency fakes** — all dependencies are exercised through their **fakes** (`loom_fake_backend`
  over `loom_local_store`, seeded by `loom_seed_data`), so the suite runs without real siblings (T3).
- **Definition of done** — the component is complete when its conformance suite + all per-capability
  suites are green against the fakes. No sibling needs to exist or pass.
- **Cross-component flows** are covered separately by the **workflow packet overlays** in each
  architecture doc, each annotated with the owning component(s) and the integration test that covers
  the step — but a single component is never blocked on a cross-component flow to be "done."

This reuses the V1 harness exactly: typed clients in `loom_api_contracts`, fakes in `loom_fake_backend`,
the local store, and seed data — the same substrate that already makes the demo standalone.

## 6. Agent-workability model

> **One component = one work package.** An agent is assigned a single Component Contract Card.

The card is sufficient because it carries: the single responsibility (what to build), the contract (the
exact interface), the capability sub-units (an ordered task list), the dependency fakes (what to build
against), the owned-data boundary (what it may write), the events to emit/consume, the blast radius
(what it may and may not touch elsewhere), and the integration tests (the acceptance gate).

Workflow:

1. Agent reads one card. It does **not** read the rest of the system.
2. Agent implements the contract operations capability-by-capability, against dependency fakes.
3. Agent writes/extends the per-capability integration suites and the conformance suite.
4. **Acceptance gate:** all of the component's suites green against the fakes → the component is done.
5. If the agent finds it must change a sibling beyond an **additive** dependent-contract change, that is
   a **tenet violation (T5)** and a signal to re-scope the card, not to make a cross-component edit.

This is why the tenets matter: they bound each agent's change surface to one card and make "done"
objective and local.

## 7. UX micro-component rules (T10)

The App Shell and extension UI are decomposed into contract-bearing UI components, each with a typed
props/data contract and tests:

| UX component | Data/props contract | Required invariants | Tests |
| --- | --- | --- | --- |
| Community Card | `CommunityCard` + resolved `dataSources` | Rendered by shell; extension supplies content only. | Visual snapshot + data-binding test. |
| Navigation Panel | `NavigationPanel` (placement + buttons) | Always present; always exposes Messages + Connections (renamable). | Interaction test asserting both buttons + reachability. |
| Messages / Stream Renderer | `StreamItem` (rich content + attachments + `kind`) | Renders messages, posts, feed items, and `kind:ad` items faithfully; ads not suppressible. | Renders each `kind`; asserts injected ad item shown with disclosure. |
| Connections Shell | connection list + invite affordance | Reachable from nav; invite respects block. | Interaction test for list + invite-blocked path. |
| Ad Slots | `fillAdSlot` result | Top banner always present unless ad-off; not removable by extension. | Asserts banner renders; asserts ad-off suppression. |
| Payment Surface | payment intent | Loom-rendered; extension cannot spoof. | Asserts Loom-owned rendering; no extension override. |

Extension-generated UI mounts into the shell and consumes these components/surfaces; it cannot replace
the structurally-enforced ones (ad banner, payment surface) or remove the nav panel (Skill-enforced,
lintable at certification).

## 8. Current-architecture scorecard

How well the current V2 design (Architecture 01 + the two V2 product/API docs) already satisfies the
tenets, and what this doc + the card retrofit add.

| Tenet | Current state | Gap → remediation |
| --- | --- | --- |
| T1 Single responsibility + owned data | **Strong** — ~30 single-responsibility services. | Owned-data boundary not stated per component → cards add it. |
| T2 Contract-first interfaces | **Strong** — `Community*Api` + `loom_api_contracts`. | None. |
| T3 Dependency inversion & fakeability | **Strong substrate** — `loom_fake_backend`. | Per-dependency fakes not named per component → cards' Dependencies field. |
| T4 Acyclic, layered graph | **Partial** — Arch 01 groups subsystems but no formal layering/acyclicity. | §4 layer model + rules; no-sibling-sync rule. |
| T5 Scoped change / blast radius | **Missing** — not documented. | Cards' Blast-radius field; T5 as a hard rule. |
| T6 Per-component integration tests | **Missing** — biggest gap. | §5 discipline + cards' Integration-tests field = definition of done. |
| T7 Idempotency / versioning / audit | **Strong** — packet model. | None. |
| T8 Event-driven decoupling | **Strong** — Event Bus exists. | "No synchronous sibling calls" not stated → §4 rule. |
| T9 Agent-workability | **Missing** — not addressed. | §6 model; the card is the work package. |
| T10 UX micro-components | **Partial** — App Shell owns surfaces; required structure defined. | §7 makes surfaces contract-bearing with tests. |

**Verdict:** the V2 architecture is already well-decomposed and contract-first (T1, T2, T7, T8 strong),
which is most of the way to micro-components. The missing half is the **discipline that makes it
agent-workable**: explicit owned-data boundaries, a formal acyclic layering, per-component blast-radius
and integration-test definitions, and UX-as-components. This doc and the Component Contract Cards close
exactly those gaps; Architecture 01 is retrofitted as the worked example and 02–12 are authored to the
same pattern.
