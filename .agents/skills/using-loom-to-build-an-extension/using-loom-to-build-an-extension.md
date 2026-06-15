# Using Loom To Build An Extension

Status: Phase 0 skeleton

This walkthrough is the process an LLM or developer follows to design, build, validate, and iterate a
Loom Communities extension using the Skill references, the Loom source, and the Loom APIs.

The first supported execution targets are Codex and Claude Code running locally. Online-only support is
deferred until Loom provides a hosted build and validation backend.

## 0. Bootstrap Knowledge and Validation Environment

Before planning or generating packages:

1. Read [references/source-dependency-model.md](./references/source-dependency-model.md).
2. Discover the local Loom repo checkout or fetch the configured Loom repo at the pinned source
   version.
3. Read [setup/system-prereqs.md](./setup/system-prereqs.md).
4. Load [setup/prereq-manifest.json](./setup/prereq-manifest.json).
5. Detect whether the execution target is Codex or Claude Code.
6. Detect host OS, shell, repo root, package managers, Android/emulator availability, and command paths.
7. Produce an install/configuration plan before changing the environment.
8. Install or configure approved missing tools.
9. Verify required tool commands and versions.
10. Run the Demo App local validation smoke check.
11. Write [setup/validation-environment.lock.json](./setup/validation-environment.lock.json).

Do not claim a package or workflow is validated until the validation environment lock is current and
the setup smoke checks pass.

## 1. Learn From Loom Reference Implementations

Read [references/loom-reference-implementation-methodology.md](./references/loom-reference-implementation-methodology.md).
For relevant Loom workflows, explain:

- what the existing workflow does
- which personas it serves
- how APIs, rules, events, jobs, UI surfaces, seed data, and tests implement it
- why Loom chose that UX and architecture shape
- which patterns transfer to the new extension
- which platform-owned constraints must not be copied into extension-owned code

## 2. Research the Target Community

Research comparable communities, apps, policies, and UX patterns. If network access is unavailable,
ask the user for examples. Produce `community-research.md` with:

- personas
- high-level workflows
- policies and moderation needs
- privacy and sensitive-data needs
- payments, donations, dues, or ad-off needs
- communication and notification patterns
- UX patterns and tradeoffs

Optionally stop for user confirmation before detailed product docs.

## 3. Create Product Workflow Docs

Use [references/extension-creation-process.md](./references/extension-creation-process.md). Create
multiple detailed product workflow docs organized by functionality area, such as onboarding,
membership, events, content, payments, messaging, admin/moderation, search, and export.

Each workflow doc must include actors, trigger, end state, happy path, edge cases, permissions,
sensitive data, audit/export behavior, UX notes, and validation criteria.

## 4. Map Workflows To Loom APIs, Rules, Events, And Tests

Use [references/workflow-api-mapping-template.md](./references/workflow-api-mapping-template.md).
For each workflow step, map:

- Loom API contract
- extension schema
- declarative rule, workflow, job, or function
- event emitted or consumed
- App Shell surface
- fake-backend initialization data
- validation test

## 5. Create UX Guidelines And UX Decisions

Use [references/ux-methodology-template.md](./references/ux-methodology-template.md). Produce UX
research and guidelines before implementation. For each phase with UX impact, create a `UX
Decisions.md` file with reference sources reviewed, UX patterns extracted, key UX decisions, key
implementation decisions, workflow walkthrough, and open questions/tradeoffs.

## 6. Create Extension Build Tracker And Phase Docs

Create an extension-scoped build tracker and right-sized implementation phases. Each phase doc must
state workflows implemented, APIs/rules/events used, UI surfaces changed, generated files, tests,
validation commands, commit requirement, and definition of done.

Stop for owner approval after the research, product workflow docs, API/rules/events maps, UX docs,
tracker, and phase docs are complete. Do not generate code or packages until the user approves.

## 7. Understand the Trust Boundary

Loom owns:

- Passport identity and sessions.
- Community membership, spaces, roles, consent, and policy.
- Core and protected vaults.
- Wallet, dues, donations, receipts, settlement, and ad-off.
- Ads, App Shell required structure, Messages, Connections, and payment surface.
- Audit, trust/safety, certification, export, and migration.

The extension owns:

- Domain experience and routes.
- Cards and UI fragments mounted into the App Shell.
- Custom schemas.
- Rules, workflows, jobs, and optional sandboxed functions.
- Fixtures, examples, tests, and owner/member documentation.

## 8. Choose the Community Type and Surfaces

Choose the delivery mode:

- `local-demo`: produce downloadable local files for the Demo Loom Communities App with the Local
  Backend.
- `real-backend-publish`: produce a publish-ready package and backend initialization payload for a real
  Loom Communities backend.

Use the Demo App with the Local Backend for validation in both modes.

Pick the community category, required roles, spaces, and surfaces:

- `community.home`
- `space.<type>`
- `messages`
- `connections`
- `events`
- `forms`
- `payments`
- `documents`
- `admin`

Keep App Shell invariants intact.

Collect personalization inputs:

- Community display name.
- Tagline.
- Category.
- Logo.
- Card image.
- Hero image.
- Accent color.
- Alt text or decorative marking for non-text images.

If the owner does not provide assets, generate safe placeholders and keep them editable before build.
For local-demo, all images must be bundled locally; do not depend on remote image URLs.

## 9. Declare Minimal Permissions

For every feature, state:

- Actor.
- Surface.
- Loom API used.
- Fields requested.
- Purpose.
- Data class.
- Retention/export behavior.
- Whether consent is required.

## 10. Compose Loom APIs

Use this escalation order:

1. Configuration.
2. Declarative rules.
3. Workflows and jobs.
4. Sandboxed functions only when declarative logic is insufficient.

## 11. Author Extension Artifacts

Create:

- `loom.extension.json`
- `loom.initialization.json`
- extension asset bundle under `assets/`
- community seed assets under `seed/assets/`
- cards and routes
- schemas
- rules
- workflows
- jobs
- fixtures
- validation tests
- owner/member notes

The extension package is the runtime artifact. The initialization package is the local/fake-backend
artifact: it seeds community metadata, spaces, initial roles, rules, workflows, jobs, custom schema
records, and sample data through Loom APIs rather than direct table writes.

Use the locked package format:

```text
<extension-id>.loom-extension.zip
  loom.extension.json
  ui/
  assets/
    brand/
      extension-icon.png
      default-community-logo.png
      default-card-image.png
      default-hero-image.png
    images/
    icons/
    thumbnails/
  schemas/
  rules/
  workflows/
  jobs/
  functions/
  fixtures/
  tests/
  docs/
  signatures/

<extension-id>.loom-init.zip
  loom.initialization.json
  seed/
    assets/
  fixtures/
  import-plan.json
```

The extension package provides default assets. The initialization package provides the installed
community's personalized branding. The App Shell renders the actual community card and resolves card
images in this order:

1. Community-specific `branding.cardImage`.
2. Community-specific `branding.logo`.
3. Extension `defaultCardImage`.
4. Generated initials/category/accent-color fallback.

## 12. Validate

Run:

- Skill prereq setup check
- package validator
- extension asset validator
- initialization package validator
- manifest gate
- extension-specific validation tests
- App Shell invariant lint
- community-card branding priority test
- permission-negative tests
- export tests for custom records

## 13. Local Download, Sideload, and Run

When there is no hosted backend, use local mode:

1. Generate the extension package as a downloadable file.
2. Generate the initialization package as a downloadable file.
3. Verify bundled assets and initialization branding paths.
4. Load the extension package through the Loom Communities Demo App `Add Community` action.
5. Import the initialization package through the local in-app fake backend.
6. Verify that the app started with no communities, then shows one branded community card after import.
7. Open the card and run the latest local extension inside App Shell.

The Skill should output clear package paths, validator diagnostics, and any fake-backend import report.
It should also include the validation environment lock hash so the owner can tell which local toolchain
proved the package.

## 14. Debug the Skill

Treat Skill runs as reproducible tests:

- Keep prompt fixtures for each workflow and community type.
- Keep golden extension and initialization packages.
- Capture the model transcript, inputs, validator output, package diff, and final artifact hash.
- Capture prereq setup failures separately from package-generation failures.
- On failure, add the failing prompt or validator diagnostic before changing the Skill instructions.
- Re-run the Demo App sideload workflow after changing package shape or initialization behavior.

## 15. Certify, Publish, Install, and Run Latest

Submit signed artifact through the Extension Registry. Certification must approve it before install.
The Main Loom App resolves the latest certified version on open unless the owner pins or rolls back
through an allowed path.

## 16. Use Phase-Enriched Guides As References

Before using a component or workflow, read the matching guide:

- `components/<component>.md`
- `workflows/<workflow>.md`

These guides contain practical usage notes beyond OpenAPI. Treat them as reference implementation
knowledge, not instructions to modify Loom platform APIs.

Phase A1 adds the foundation guides for passport identity, role/policy decisions, member vaults,
protected data, connections, receipts, audit, events, keys, and builder App IDs. Use these first when
planning permissions, sensitive-data reads, package signing, or event-driven workflows.

Phase A2 adds registry/control-plane guides for communities, spaces, membership, invitations,
certification, extension versions, public discovery projections, workflow inventory, and manifest
staleness. Use these before designing installation, discovery, or certification flows.

Phase A3 adds experience-service guides for publishing, messaging, notifications, events, and
forms/voting. Use these when implementing announcements, threads, RSVP flows, polls, or protected
forms.

Phase A4a adds ops/community guides for cases, documents, facilities, import/export, provider transfer,
abuse reports, moderation, incidents, and disputes. Use these when implementing approval queues,
document libraries, reservations, migration packages, safety escalation, and portability behavior.

Phase A4b adds economic/search/ad guides for wallet payments, ad campaigns, ad decisions, indexing,
search, AI answers, digests, settlement, utility funding, and fraud signals. Use these when
implementing monetization, ad-off, permission-aware search, cited AI, and auditable economic flows.

Phase A5 adds extension-engine guides for runtime sessions, rules, workflows, jobs, functions, schemas,
secrets/connectors, extension packages, and initialization packages. Use these to build downloadable
local-demo artifacts and to keep backend logic declarative before reaching for sandboxed functions.

Phase A6 adds UX/local-demo guides for App Shell, community cards, navigation, stream rendering,
connections, ad slots, payment, data dashboard, the local in-app backend, and the Demo App. Use these
to validate that generated packages install locally and preserve shell-owned structure.

Phase B1a proves the local-demo workflow. Use
`workflows/local-build-download-sideload-install.md` and the book-club `phase-b1a-local` example to
generate package pairs, validate them, import fake-backend seed data, render the branded card, and open
`local:<extension-id>@latest`.

Phase B1b proves the `real-backend-publish` workflow shape while still validating locally. Use
`workflows/build-publish-discover-install.md` and the book-club `phase-b1b-publish` example to add
builder App ID metadata, signing scope, package ID, certification evidence, community handle, QR
payload, and latest-open routing. The validation loop uses local registry, certification, discovery,
and App Shell fakes until a hosted Loom backend is available.

Phase B2 adds the first vertical workflow guide: `workflows/book-club-headline.md`. Use it to compose
forms, polls, events, publishing, discussion, search, AI, and digest features into a complete book club
extension, then validate the flow in the Demo App with Local Backend.

Phase B3 adds `workflows/youth-soccer-headline.md`. Use it for guardian membership, team spaces,
protected minor data, registration payments, schedule events, notifications, and local Demo App
validation of a youth sports extension.

Phase B4 adds `workflows/hoa-headline.md`. Use it for dues, member-visible documents, facility
reservations, architectural request cases, committee workflow decisions, owner notifications, export
coverage, and local Demo App validation of an HOA extension.

Phase B5 adds `workflows/mosque-headline.md`. Use it for mosque announcements, iftar/event RSVPs,
volunteer signup with protected contact fields, anonymous donor visibility, donations, private care
requests, neutral notifications, public announcement search/AI citations, and local Demo App
validation of a mosque extension.

Phase B6 adds `workflows/messaging-ads-connections.md`. Use it to preserve shell-owned Messages,
Connections, top banner ads, in-stream sponsored disclosure, blocked-connection affordances,
sensitive-context no-fill behavior, and local Demo App validation of platform invariants.

Phase B7 adds `workflows/ad-off.md`. Use it for shell-owned ad-off checkout, member and community
entitlements, eligible ad suppression, sensitive-context no-fill, receipts, settlement, utility
funding, and local Demo App validation of ad-off economics.

Phase B8 adds `workflows/export-migration.md`. Use it for export scope, protected redaction, import
replay, extension custom-data export, checksums, provider transfer verification, rollback, API inventory
validation, and final full-suite Demo App regression.

Phase B9 adds `workflows/arbitrary-local-package-ingestion.md`. Use it whenever the Skill generates a
new local-demo extension that is not one of the worked examples. The Demo App loader must consume the
selected package contents, import the parsed community and branding, render the parsed card, and open
`local:<extension-id>@latest`; seeing Book Club values in this flow is a validation failure.

Phase B10 adds `workflows/skill-arbitrary-extension-test-run.md` and the
`examples/arbitrary-garden-club/` replay fixture. Use it as the approval gate for arbitrary Skill
output: save the generated manifests, replay them through the Demo App Local Backend, confirm the
generated card and branding render, and open `local:<extension-id>@latest` before approving the
extension or starting owner-requested iteration.

Phase B11 adds `workflows/prompt-build-validate-complete.md` and the
`examples/arbitrary-camera-club/owner-prompt.txt` prompt fixture. Use it for the full local Skill
loop: start from an owner prompt, capture requested workflows, generate review docs and packages, load
the package pair into the Demo App Local Backend, open the generated extension, validate every target
workflow, and emit a completion report. Do not claim the extension is complete unless that report has
`complete=true`.

Phase B12 adds the Skill reference methodology files under `references/`. Use them before execution to
research the target community, explain Loom reference implementations, write product workflow docs,
map workflows to APIs/rules/events/tests, create UX docs, create the extension build tracker, and stop
for owner approval before generating code or packages.
