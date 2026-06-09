# Extensible Loom — Product Definition

Status: Draft for review
Product area: Loom Communities (V2 direction)
Companion: [Extensible Loom — API Reference](./Extensible%20Loom%20API%20Reference.md) (the exhaustive catalog behind this doc)
Predecessor: [Loom V1 Product Docs](../Product%20Docs/01-core-thesis-and-platform-principles.md)

---

## 1. Context & vision

### The pivot

Loom V1 was an open **creator/fan economy protocol** — creators own portable channels, fans own a
portable Passport and Wallet, and platform services compete through certified, swappable APIs (see
[Core Thesis](../Product%20Docs/01-core-thesis-and-platform-principles.md)). That work produced a
working, fully standalone demo: typed contracts in `core/loom_api_contracts`, in-app fakes over a
local SQLite store, ~27 APIs, and a 26-phase plan (see the
[MVP Gap Analysis](../Go-To-Market/MVP%20Gap%20Analysis%20%E2%80%94%20Launch%20Scope.md)).

**We are not extending the V1 creator-economy infra further.** The new direction reuses V1's
trust-and-portability foundation but re-points it at a different, larger surface:

> **Loom Communities: an extensible, AI-buildable operating system for real-world communities.**

Anyone can stand up a community — an HOA, a mosque, a parish, a youth soccer club, a book club, a Buy
Nothing circle — and get a custom app for it, built by an AI Skill (ChatGPT/Gemini/Claude) or a
developer, running on top of stable Loom primitives. Loom owns the trust boundary; the extension owns
the experience.

### The problem

Real-world communities have no portable, AI-buildable home. Today they are scattered across WhatsApp
threads, group emails, spreadsheets, paper sign-up sheets, and a long tail of expensive single-purpose
vertical tools (HOA portals, church-management suites, youth-sports platforms). Each tool is a silo:
separate logins, no shared identity across the communities a person belongs to, and no way to leave
with your data. Most groups can't afford or justify a dedicated tool at all, so they run on
general-purpose chat apps that can't do dues, voting, registration, scheduling, or audit.

### The opportunity

A single platform that supplies the hard, trustworthy parts once — identity, roles, permissions,
payments, audit, portability, safety — and lets the *experience* be generated per community. One
person carries one identity across every community they're in. A community admin describes what they
need and gets a working app. Nobody is locked in.

### Success metrics (proposed)

- Time for a non-technical admin to stand up a working community from a template: **< 15 minutes**.
- A member belongs to **multiple** communities under **one** identity, with one inbox and one wallet.
- A community can **export** all its data and **uninstall** any extension at any time (portability proven).
- The same primitive set powers **several contrasting verticals** with no core changes (see §9).

---

## 2. What carries over from Loom V1 (reuse map)

This is the most important framing for the pivot: most of the trustworthy backend already exists in
V1 form. V2 is largely a **re-pointing and generalization**, not a from-scratch build.

| V1 primitive | V2 use | Status |
| --- | --- | --- |
| **Fan Passport** (portable identity) | **Member identity** — `CommunityMember.passportId`; one person, many communities | Reused (renamed in context) |
| **Fan Wallet / Entitlement Ledger** | **Community payments** — dues, donations, tickets, fees, refunds | Reused |
| **Receipt Ledger / Settlement Engine** | **Community receipts & settlement** — payment, donation, vote, approval, export receipts | Reused |
| **Audit / Receipt classes** (`EconomicReceipt`, `AuditReceipt`, `UtilityFundingReceipt`) | **Community audit trail** | Reused |
| **Extension registry/runtime** (`ExtensionManifest`/`ExtensionInstall`/`ExtensionSession`, keyed by `channelId`/`fanId`) | **Community extension registry/runtime**, keyed by `communityId`/`memberId`/`spaceId`, with typed payloads, routes, launch context | Generalized |
| **`riskTier` / `certificationState`** | **Extension certification tiers 0–5** | Generalized |
| **AI Gateway** (permissioned, receipt-generating) | **`CommunityAiApi`** — summaries, minutes, Q&A, digests | Reused |
| **Migration/export APIs** | **Community import/export & provider transfer** | Reused |
| **Neutral search principles** | **Permission-aware `CommunitySearchApi`** | Reused |
| **Contract-first fake-backend demo harness** (`loom_api_contracts` + `loom_fake_backend` + `loom_local_store` + `loom_seed_data`) | **The V2 MVP delivery method** — new contracts → fakes → seed → UI | Reused as-is |

**Renamed:** `channelId → communityId`, `fanId → memberId`, "follow" → "membership/join", "creator
channel" → "community", "creator experience config" → "community extension install + config".

**Genuinely new:** the Spaces model (sub-communities), the four-level backend-extensibility engine
(rules / workflows / jobs / sandboxed functions), the typed Event Bus, the Extension Data Schema API
(portable custom entities), the App Shell card/route/surface system, and the community-specific
domain modules (sports, religious, facilities, marketplace, governance/cases).

**Explicitly retired for now:** the creator-vs-fan economy framing, creator-led recommendation/
referral revenue, sponsor/ad tooling, and the public neutral-search utility as a headline feature —
none are being built further under the community direction (though the underlying receipt/identity
machinery they share is reused).

---

## 3. Core principle & trust boundary

> **Loom owns the trusted backend contracts, identity, permissions, payments, audit logs,
> portability, and safety. Extensions own the custom community experience: UI, layout, workflows, and
> domain logic.**

A soccer extension can feel like a full club app; an HOA extension like a property-management portal;
a mosque extension like a religious hub — but under the hood they all use the same primitives:
`communityId, spaceId, memberId, role, permission, event, rule, workflow, job, record, receipt,
audit, export`.

### The effective-permission model

Every extension action is gated by the **intersection** of five permission sources — never a generic
`admin`/`write_all` grant:

```text
Extension requested permissions
∩ Community admin-approved permissions
∩ Member role permissions
∩ Member consent grants
∩ Loom platform safety policy
= effective permission
```

This is what prevents a soccer extension from reading donor details, a marketplace extension from
reading youth rosters, or a book-club extension from sending global emergency alerts. Permissions are
scoped capabilities (`community.events.rsvp`, `community.donations.read_aggregate`, …) — the full
catalog is in [API Reference §5](./Extensible%20Loom%20API%20Reference.md#5-capability-permission-catalog).

---

## 4. Personas & product artifacts

### Three personas

| Persona | What they do |
| --- | --- |
| **Community admin** | Creates a community, installs/configures an extension, approves permissions, manages members and roles. |
| **Extension builder / community owner** | Registers with the Skill (gets an App ID), logs in with their Loom Identity, creates the community (CommunityID + friendly handle), and uses the Skill to generate and publish the extension package. |
| **Member** | Opens a community card, uses the custom experience, controls their consent and data. |

(The V1 provider and governance personas carry over for certification, audit, and dispute handling.)

### Three artifacts

| Artifact | Meaning |
| --- | --- |
| **Community** | The portable owner container: members, roles, spaces, data, rules, payments, audit. |
| **Extension** | The custom experience package: UI, cards, routes, schemas, workflows, rules, jobs. |
| **Skill** | The AI authoring tool that generates/updates extensions. **A builder/compiler, not the runtime.** |

The Skill is deliberately *not* the runtime platform. ChatGPT, Gemini, and Claude each have different
skill/app models; depending on any one of them at runtime would re-introduce lock-in. The Skill
generates a portable Loom extension package; Loom validates, certifies, installs, and runs it.

```text
ChatGPT / Gemini / Claude Skill → generates Loom extension package
        → Loom validates, certifies, installs
        → Loom Communities App Shell loads the extension
        → extension calls fixed Loom APIs
        → rules/workflows/jobs execute through Loom's engine
```

---

## 5. Platform architecture

The system, services, and UX are designed as **micro-components** with contract-first interfaces — see
the [System Design Tenets](../Architecture%20V2/00-system-design-tenets.md) and the
[Architecture V2 set](../Architecture%20V2/01-overall-system-architecture.md). Each component is
documented as a two-tier Component Contract Card so a capability change is well-scoped and provable by
that component's own integration tests.

### Five layers

```text
┌────────────────────────────────────────────────┐
│ Loom Communities App Shell                       │  home, cards, auth, nav, permissions, bridge
├────────────────────────────────────────────────┤
│ Community Extension UI                           │  soccer UI, HOA UI, book-club UI, mosque UI
├────────────────────────────────────────────────┤
│ Loom Extension Runtime Bridge                    │  typed API calls, session token, permissions
├────────────────────────────────────────────────┤
│ Loom Community APIs                              │  members, spaces, posts, events, dues, docs…
├────────────────────────────────────────────────┤
│ Rules · Workflows · Event Bus · Jobs · Functions │  safe, sandboxed backend customization
└────────────────────────────────────────────────┘
```

The fixed backend APIs give Loom consistency; the extensions give communities infinite variety.

### What the App Shell owns

Authentication, community cards, permission prompts, the navigation shell, the API bridge (extensions
never get raw credentials), theming boundaries (extensions can't spoof system/security UI), offline/
cache rules, push notifications, audit/receipts, uninstall/export, the **top ads banner**, and the
**navigation-panel contract**. Each card is **defined by the extension but rendered by the shell**:

```text
Livermore Youth Soccer Club        HOA — Sunset Ridge              Friday Book Club
U12 match Sat 10:00 AM             Board meeting tomorrow           Reading: The Hobbit
2 unread coach messages           1 architectural request to review Vote open for next book
Registration due in 3 days        Q2 dues paid                     Next meeting: June 21
[Open]                            [Open]                           [Open]
```

### Required App Shell structure

Every community extension loads into a shell with a fixed structure. Two parts are **structurally
enforced** (Loom renders them; an extension or Skill can't remove them), and the navigation contract
is **Skill-enforced** (baked into how the Skill generates packages, not a hard runtime backend check —
the certifier may lint for it, §6):

1. **Thin ads banner — top of the shell, always present.** Loom-rendered; part of the free-backend
   revenue model (§10). Cannot be removed, hidden, or restyled by the extension.
2. **A navigation panel — always present in the extension.** Placement is flexible
   (top / left / right / bottom / floating), chosen by the extension. It **must always contain a
   "Messages" button and a "Connections" button** (both labels are renamable per community). The Skill
   enforces this pattern when it generates an extension.
   - **Messages** routes to the community's interaction surfaces — chat / messaging / forums / feeds —
     where in-stream ads are delivered (see below).
   - **Connections** shows the people in this community you are connected with, and lets you invite
     your connections to join the community (unless they've blocked you).
3. **Customizable core shells.** Beyond the main extension content, the **Messaging shell** and the
   **Connections shell** can each be customized to fit the community, but both must remain reachable
   from the navigation panel at all times (again, enforced by the Skill's generation pattern).

### How ads are delivered

Loom's revenue model is **free backend + advertising** (§10), delivered two ways:

- **Shell-rendered ad surfaces** — the thin top banner (always) and **video-playback** pre-roll /
  mid-roll. These belong to the shell, not the extension; they can't be removed, hidden, relocated, or
  restyled, and an AI Skill cannot "design them out." Same trust class as Loom-rendered payment
  surfaces (§12).
- **In-stream native ad items (via API)** — for the **interaction streams** behind Messages
  (chat / messaging / forums / feeds), Loom does **not** carve out a separate UI ad slot. Instead it
  **injects the advertisement as a native item in the stream** — a message / post / feed entry —
  through the messaging/feed API. So the extension's stream renderer displays it the same way it
  displays any other message. For this to work, the messaging/stream content model is **rich**: the
  API text stream carries formatting and can attach an image, link, or file, with an ad-disclosure
  marker (see [API Reference §1.7](./Extensible%20Loom%20API%20Reference.md#17-messaging--notification-api)).

A subscription suppresses ads for that end user; a community-owner payment suppresses ads across that
community's surface (§10).

### The Event Bus

Every meaningful action emits a typed event (`community.member.joined`, `payment.succeeded`,
`match.score.finalized`, …). Extensions subscribe to events to drive automation. Event families and
example payloads are in [API Reference §6](./Extensible%20Loom%20API%20Reference.md#6-event-families)
and [§2.4](./Extensible%20Loom%20API%20Reference.md#24-event-bus-api).

### Four levels of backend extensibility

UI extensibility is not enough — a tennis league needs "wait 24h for a dispute, then update
standings"; an HOA needs "route to committee, escalate to board after 14 days." But Loom must never
let an extension run arbitrary code against the database. So backend customization is offered at four
escalating levels, and most needs are met by the first two:

| Level | Mechanism | Use it for | API |
| --- | --- | --- | --- |
| **1 — Configuration** | JSON config values (deadlines, dues amount, roster size, reminder hours) | Per-community tuning | install config |
| **2 — Declarative rules** | Event-condition-action rules (the most important layer) | "On member join, send welcome + add to announcements"; "on payment, mark dues paid" | [`ExtensionRulesApi`](./Extensible%20Loom%20API%20Reference.md#25-extension-rules-api) |
| **3 — Workflows + jobs** | State machines for multi-step processes; time-based jobs | Registration, architectural review, score disputes; reminders, recurring invoices, digests | [`ExtensionWorkflowApi`](./Extensible%20Loom%20API%20Reference.md#26-extension-workflow-api) / [`ExtensionJobsApi`](./Extensible%20Loom%20API%20Reference.md#27-extension-jobs-api) |
| **4 — Sandboxed functions** | Certified bounded code, mutations only via Loom APIs | Standings/rankings, scheduling optimizers, eligibility, trust scoring | [`ExtensionFunctionsApi`](./Extensible%20Loom%20API%20Reference.md#28-sandboxed-functions-api) |

Add sandboxed functions only once rules/workflows prove too limited.

### The policy-aware path

An extension can't say "charge all members $100." It requests "create a dues invoice plan," and Loom
checks: is the extension allowed to create dues? is the actor a treasurer/admin? is the payment
surface approved? is the amount within configured bounds? are notifications within anti-spam limits?
is audit required? is a receipt required? Only then does the mutation happen, emit an audit event, and
publish a bus event that may trigger downstream rules.

---

## 6. Extension package & lifecycle

A Loom community extension is a **package**, not a prompt: a manifest plus UI, cards, routes, schemas,
rules, workflows, jobs, permissions, fixtures, and tests. The full directory layout and the
`loom.extension.json` shape are in
[API Reference §7](./Extensible%20Loom%20API%20Reference.md#7-extension-package-file-format).

### Lifecycle

The end-to-end loop has two halves: **authoring & publishing** (in the Skill) and **discovery,
install & update** (in the Main Loom app).

**A. Authoring & publishing (the Skill / community owner)**

```text
Owner registers with the Skill → creates an App ID (the builder credential in the Skill)
→ Owner logs in with their Loom Identity (Passport) as the community creator/owner — or creates one
→ Owner creates a CommunityID (assigned) + a friendly, unique handle (e.g. @sunset-ridge-hoa) people can search
→ Owner describes the community; the Skill generates the extension package (with its own extensionId)
→ Skill uploads the package to the Loom backend via the publish API
→ Loom validates (schema, permission minimization, portability, UI/rule/payment/minor/secrets/ad-integrity)
→ Loom certifies the package and assigns a tier
→ Publish returns a QR code (+ shareable deep link) that encodes the community handle / CommunityID
```

**B. Discovery, install & update (the Main Loom app / members)**

```text
Member taps "Add a community" in the Main Loom app
→ Finds it by friendly handle / CommunityID, or by scanning the QR code
→ The community's extension package is downloaded to the local app
→ Loom shows requested permissions / surfaces / rules → member/admin approves
→ Community card appears in the member's home
→ On opening the community, the Main Loom app fetches the latest published version of the extension
```

The owner installs into their own community first (the admin path); the QR/handle is how everyone
else finds and installs it. Updates are pulled on open — members always run the latest certified
version without a manual reinstall.

### Certification tiers

Extensions are not all equally trusted. Tier 0 (theme/template, no mutations) → Tier 5 (external
connectors, secrets, sandboxed code). Payments, minors, and sensitive care data are Tier 4+ and
require review. Full table in
[API Reference §2.10](./Extensible%20Loom%20API%20Reference.md#210-extension-certification-tiers).

---

## 7. Decisions (decided)

These forks are now **decided** (2026-06).

### 7.1 Extension UI model → **declarative cards + WebView mini-app + JS bridge** ✅

Of the three options — (A) declarative Loom components, (B) WebView/iframe mini-app with a JS bridge,
(C) native Flutter widgets — we ship **declarative cards** (rendered by the shell) **+ WebView
mini-app routes behind a Loom JS bridge**, and defer native widgets. Cards stay declarative so the
home surface is always safe and consistent; richer per-route experiences run in the sandboxed WebView.
The shell-owned ad slots (§5, §10) live in the declarative layer so they can't be removed by extension
WebView code.

### 7.2 AI builder → **the Skill is in the MVP** ✅

Reversing the earlier "defer" lean: the **AI Skill is a first-class MVP deliverable**. The headline
MVP goal is to **use the Skill to generate a working Loom community extension, with customizations,
and install it** via the validate → certify → install path (§9). Hand-authored packages are still
supported (they seed the example extensions and the Skill's templates), but the proof point is the
Skill round-trip — because a hand-authored and an AI-authored package are the *same* artifact.

This makes the **extension validation + certification APIs required from day one** (you cannot safely
auto-install an AI-authored package without them): schema validation, permission minimization,
portability, and the UI/rule/payment/minor/secrets/**ad-slot-integrity** safety checks (see
[API Reference §2.11](./Extensible%20Loom%20API%20Reference.md#211-extension-certification--validation-api)).

### 7.3 Identity → **reuse the Fan Passport as member identity** ✅

Do not invent a new identity primitive. `CommunityMember.passportId` points at the existing portable
Passport, so one person carries one identity across every community — the core differentiator (§11).

### 7.4 Community as a peer container alongside Channel → **additive, backward-compatible** ✅

"Community" is added as a **new top-level container that sits beside the V1 "Channel,"** not a
replacement. The existing creator/fan channel APIs keep working unchanged; apps already built against
them are unaffected. New community APIs are additive, and the shared layers (Passport identity, Wallet,
receipts, audit, extension runtime) serve both container types.

### 7.5 Spaces → **deeply nestable and user-extensible** ✅

Spaces support **arbitrary nesting** (`parentSpaceId`), so a hierarchy as deep as
club → league → division → team → subgroup is expressible — not a fixed two levels. Beyond the
built-in space types, communities and extensions can **register custom space types**, so the model is
user-extensible rather than a closed enum (see
[API Reference §1.4](./Extensible%20Loom%20API%20Reference.md#14-community-spaces-api)).

### 7.6 Sensitive data → **dedicated protected-visibility vault in the MVP** ✅

Care requests, minor/youth records, and donor-identifiable data are stored in a **dedicated
protected-visibility vault** (reusing V1's vault model), not merely role + visibility policy. Access
is gated by explicit permission, every read is audited, and audit payloads for sensitive cases are
redacted. This is in scope for the MVP because three of the four anchor verticals (soccer minors, HOA,
mosque care/donations) require it.

---

## 8. Community taxonomy

Loom does **not** hardcode "a soccer app" or "an HOA app." It defines durable primitives; extensions
compose them into verticals. The platform targets five broad community families:

| Family | Examples |
| --- | --- |
| **Social / learning / hobby** | Book clubs, hobby clubs, cultural & learning groups, support groups. |
| **Local civic / neighborhood** | Neighborhood groups, Buy Nothing / trading, HOA / condo / co-op, apartment buildings, business associations. |
| **Religious / nonprofit** | Churches/parishes, mosques, temples/synagogues, nonprofits & volunteer orgs. |
| **Sports / facility** | Clubs, teams, leagues, facilities, camps/classes. |
| **Event-centered** | Event collectives, volunteer/event crews, hybrid/remote communities. |

The full category breakdown and the per-vertical user-story tables are in
[API Reference §10](./Extensible%20Loom%20API%20Reference.md#10-community-taxonomy-and-per-vertical-user-stories).
Representative stories:

- **Book club** — start a private club, vote on the next book, run spoiler-safe chapter discussions,
  get an AI meeting summary.
- **HOA** — submit an architectural request with tracked committee review; run a board meeting with
  quorum, board-only votes, and public minutes; collect dues with reminders and a delinquency view.
- **Mosque** — coordinate Ramadan iftar volunteers and reminders; collect donations with private
  receipts; take confidential care requests visible only to the care team.

---

## 9. MVP scope

The MVP proves the **extensibility platform**, not a single vertical, and proves it the hard way:
**the AI Skill builds a real community extension, with customizations, and Loom installs and runs
it.** It is anchored on **all four contrasting verticals** (§9 anchor table) built from the *same*
primitives — the strongest proof that the architecture generalizes — and revenue runs on the
**free-backend-plus-ads** model (§10), so the demo must show shell-owned ad slots that the Skill
cannot remove.

**Headline MVP goal:** an owner registers with the Skill and logs in with their Loom Identity →
creates a community (CommunityID + friendly handle) → the Skill emits a Loom extension package and
**publishes it, getting back a QR code** → another person **adds the community in the Main Loom app by
handle or QR**, downloads the extension, and on open runs the **latest** version → members use the
generated app, complete with un-removable ads → a subscription / owner payment turns ads off.

### Anchor verticals (chosen to span the primitive spectrum)

| Vertical | Exercises | Why it's in the set |
| --- | --- | --- |
| **Book club** | Spaces, posts, polls, events, AI summaries | Lightest case — proves the social/publishing core and AI. |
| **Youth soccer club** | Payments, **minors/guardians**, scheduling, standings, multi-step workflow | Payments + sensitive minor data + a real state machine. |
| **HOA** | Governance, dues, **approval workflows**, cases, audit | Governance/operations + multi-actor approvals + audit. |
| **Mosque / parish** | Recurring services, donations, **sensitive care data**, volunteers | Recurring scheduling + giving + protected-visibility data. |

Together these exercise: light social, payments, minors, recurring schedules, governance/approvals,
sensitive data, and audit — i.e. the full spread of what the primitives must support.

### The end-to-end demo slice (per vertical)

```text
Admin describes the community to the Skill → Skill emits an extension package → Loom validates + certifies
→ Admin approves permissions/surfaces/rules and installs
→ Member opens the community card in the App Shell (ad slots rendered by the shell)
→ Member runs the vertical's headline flow
     book club: nominate + vote on next book
     soccer:    register a child → sign waiver → pay → get assigned to a team
     HOA:       submit an architectural request → committee review → decision letter
     mosque:    donate to a fund → private receipt   /   submit a care request → care-team-only vault
→ A declarative rule or workflow fires (reminder, status change, receipt, standings)
→ An audit event / receipt is recorded
→ Member subscribes (or owner pays) → ads turn off
→ Admin can export community data and uninstall the extension (portability proven)
```

### Delivery method (reuse the V1 harness)

Mirror exactly how V1's launch phases (10–14) were sequenced — contract-first, no backend:

```text
new typed contracts in loom_api_contracts (additive; V1 channel APIs untouched — §7.4)
→ in-app fakes in loom_fake_backend over loom_local_store
→ seed data in loom_seed_data (one fixture per anchor vertical)
→ the App Shell + declarative card/route renderer + JS bridge + shell-owned ad slots
→ the Skill (builder) + the validate/certify path
→ four extension packages (one per vertical) — hand-authored as templates, then reproduced via the Skill
```

### Minimum API subset for the MVP

Platform & core: `CommunityRegistryApi`, `CommunityMembershipApi`, `CommunityRolePolicyApi`,
`CommunitySpacesApi`, `CommunityAppShellApi`, `CommunityExtensionRegistryApi`,
`CommunityExtensionRuntimeApi`, `CommunityExtensionCertificationApi` (validate/certify — required by
§7.2), `ExtensionDataSchemaApi`, `CommunityEventBusApi`, `ExtensionRulesApi`, `ExtensionWorkflowApi`,
`ExtensionJobsApi`, `CommunityAuditApi`, `CommunityVaultApi` (protected-visibility data — §7.6).
Experience & ops: `CommunityPublishingApi`, `CommunityNotificationApi`, `CommunityEventsApi`,
`CommunityFormsApi` (+ `Polls`/`Voting`), `CommunityCaseApi`, `CommunityDocumentApi`,
`CommunityWalletApi`/`CommunityDuesApi`/`CommunityDonationApi`/`CommunityReceiptApi`,
`CommunityImportExportApi`.
Shell & social: `CommunityAdsApi` (banner/playback fill + in-stream ad injection + subscription/owner
ad-off toggles — §10), `CommunityMessagingApi` (rich stream content), `CommunityConnectionsApi`
(connections + invite-to-community).
Plus minimal `CommunityAiApi` (thread/meeting summaries) for the book-club slice, and the **Skill**
itself (extension-builder) as a deliverable, not just an API.

### Explicitly out of the MVP

Sandboxed functions (§5 Level 4), secrets/external connectors, native UI widgets, full marketplace/
sports-stats/league-fixtures depth, external provider transfer, real ad-network integration (ad slots
render house/placeholder creatives in the demo), and the full builder SDK/CLI (`loomx`) — the Skill
ships, the polished CLI tooling is a fast-follow. Standings/rankings in the soccer slice are computed
by a simple rule action or seeded, not by a sandboxed function.

### Success criteria

1. The **Skill generates** a valid, certifiable extension package for a vertical, with at least one
   admin-requested customization, and **publishes it** (validate → certify → publish), getting back a
   **QR code** tied to the community's friendly handle / CommunityID.
2. In the **Main Loom app**, a member **adds the community by handle or QR**, the extension downloads
   locally, and on open the app fetches the **latest published version**.
3. One admin installs four different extensions into four communities; each renders a distinct app.
4. One member identity (one Passport) participates in all four with one inbox and one wallet, while
   the existing V1 channel/fan surfaces still work unchanged (§7.4).
5. Each vertical's headline flow runs end-to-end and produces the right audit event / receipt;
   sensitive data (minor/care/donor) lands in the protected vault.
6. Every generated extension shows the **thin top ad banner** and a **navigation panel with Messages +
   Connections** (renamed per vertical); both core shells are reachable from it.
7. Ads reach members both ways — the **shell banner / playback slot can't be removed**, and an
   **in-stream ad renders as a native message/post** in an interaction stream with rich formatting +
   an attachment; an end-user subscription and an owner payment each turn ads off.
8. From **Connections**, a member invites a connection to join a community (blocked connections can't).
9. A community can be fully exported and an extension uninstalled with jobs/rules immediately disabled.

---

## 10. Monetization / business model

**The backend is free. Revenue comes from advertising, with paid ways to turn ads off.**

### Two ad-delivery modes — neither can be designed out

Ads reach members two ways (see §5 "How ads are delivered"):

- **Shell-rendered ad surfaces** — the **thin top banner** (always present) and **video-playback**
  pre-roll / mid-roll. Rendered by the App Shell, not the extension, so they are **structurally
  un-removable**: an extension — or an AI Skill generating one — can lay content out *around* them but
  cannot remove, hide, relocate, or restyle them.
- **In-stream native ad items** — in the **interaction streams** (chat / messaging / forums / feeds),
  Loom injects the advertisement as a **native stream item** (a message / post / feed entry) through
  the messaging/feed API, rather than as a separate UI slot. The extension's stream renderer shows it
  like any other item; because the item comes *from Loom's API*, the extension can't suppress it
  without dropping platform stream content — which fails certification.

Ad-slot integrity **and** in-stream-ad integrity are validation/certification checks (§6, §7.2), so a
generated package that tries to suppress either fails certification. This is the same trust class as
Loom-rendered payment surfaces (§12).

### Turning ads off (the paid paths)

| Who pays | What they get |
| --- | --- |
| **End-user subscription** | All advertisements are turned off for that user, everywhere they go on Loom. |
| **Community owner** | A monthly payment turns ads off across **that community's** surface for all its members. |

Both flow through the V1 Wallet / Receipt / Settlement machinery (§2).

### Later (post-MVP) revenue options

A **fee on community payments** (dues / donations / tickets, with transparency and charitable-fund
opt-outs) and **paid certified extensions / a marketplace cut** remain available once the ecosystem is
real. Open: whether identity/audit/portability are funded as a shared **utility** (V1's
`UtilityFeePolicy`) to keep the free-backend + portability promise credible.

> **MVP note:** the demo renders **house/placeholder creatives** in the ad slots and exercises both
> ad-off toggles; real ad-network integration is out of MVP scope (§9).

---

## 11. Competitive positioning

Why a community would choose Loom over the alternatives:

| Alternative | Their limitation | Loom's edge |
| --- | --- | --- |
| **WhatsApp / Discord group** | No dues, voting, registration, scheduling, audit; data trapped in chat | Real operations + one portable identity + export |
| **Dedicated vertical tool** (HOA portal, church/mosque suite, youth-sports platform) | Expensive, single-purpose, siloed login, no portability | One identity across all your communities, AI-buildable, no lock-in |
| **Spreadsheets + email + paper** | Manual, error-prone, no automation or audit | Rules/workflows/jobs automate the busywork with an audit trail |

The durable differentiators: a **free, ad-supported backend** (no upfront cost to start a community);
**one portable identity** across every community a person belongs to; **AI-buildable** custom
experience instead of one-size-fits-all; and **no data lock-in** (export + uninstall anytime).

---

## 12. Trust, safety & security model

Loom defines the experience boundary so extensions can be flexible without becoming an unsafe plugin
free-for-all. Enforced rules:

| Rule | Why |
| --- | --- |
| Extensions never receive raw database credentials; all calls go through the runtime bridge. | Prevent lock-in and data leaks; keep authorization centralized. |
| Every mutation is idempotent; every sensitive mutation emits an audit event. | Prevent duplicate charges/posts; preserve governance/payment/safety trails. |
| Extension state must be exportable; extensions can't hide data from community owners. | Preserve portability; prevent hostage-taking by plugin developers. |
| Extensions can't silently install rules or background jobs; time-based jobs are visible. | Admin approval and visibility for all automation. |
| Payments require explicit, Loom-rendered payment surfaces. | Prevent deceptive UI / fraud. |
| Shell ad surfaces (top banner, video pre/mid-roll) are Loom-rendered and un-removable; in-stream ads are injected as native API stream items and can't be suppressed. | Protect the free-backend revenue model (§10); fails certification if violated. |
| The navigation panel must exist and always expose Messages + Connections; the Messaging and Connections shells must stay reachable. | Core member experiences can't be hidden. Enforced by Skill design (lintable at certification), not a hard runtime check. |
| Youth/minor and sensitive-care data require special permission gates and protected visibility. | Sports, religious school, youth groups, pastoral care. |
| Uninstall disables jobs/rules immediately. | No zombie automations. |
| AI prompts are never authoritative policy. | Prompts are not governance. |

---

## 13. Open questions / decisions needed

§7 resolved the major forks (UI model, Skill-in-MVP, identity, community-as-peer-container, nestable/
extensible spaces, protected-visibility vault). Remaining:

- **Governance/certification surface** — the MVP needs validate + certify (§7.2). Open: is that a
  fully automated package validator from day one, or automated validation plus a manual review gate
  for Tier 4+ (payments/minors/sensitive) extensions?
- **Skill customization scope** — what's the minimum set of "customizations" the Skill must support in
  the MVP to be a credible proof (theme + copy? rules/workflows? new schemas/routes?)?
- **In-stream ad cadence & disclosure** — how often an ad item is injected into a stream, how it's
  labeled as an ad, and whether members can report/mute a specific ad item.
- **Connections model & privacy** — is "connections" a Passport-level cross-community social graph or
  per-community only? Who can see your connections, and what are the invite/block defaults?
- **Ad UX & policy** — ad density and placement rules per surface; how ads behave around sensitive
  contexts (care requests, minor data, donation receipts) where ads may be inappropriate; whether
  community owners can choose ad categories.
- **Subscription vs owner ad-off pricing** — price points, and whether owner ad-off is per-community
  flat or scales with member count.
- **Spaces nesting in the demo** — how deep the seed fixtures actually go (e.g. soccer
  club → league → division → team) vs. what the model supports.
- **Protected vault scope** — is one shared protected-visibility vault enough for the MVP, or do
  minor / care / donor data need separate vaults with distinct retention policies?
