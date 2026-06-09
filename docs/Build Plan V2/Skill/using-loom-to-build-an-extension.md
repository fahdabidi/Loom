# Using Loom To Build An Extension

Status: Phase 0 skeleton

This walkthrough is the process an LLM or developer follows to build a Loom Communities extension using
the reference Loom source and APIs.

The first supported execution targets are Codex and Claude Code running locally. Online-only support is
deferred until Loom provides a hosted build and validation backend.

## 0. Prepare the Validation Environment

Before planning or generating packages:

1. Read [setup/system-prereqs.md](./setup/system-prereqs.md).
2. Load [setup/prereq-manifest.json](./setup/prereq-manifest.json).
3. Detect whether the execution target is Codex or Claude Code.
4. Detect host OS, shell, repo root, package managers, Android/emulator availability, and command paths.
5. Produce an install/configuration plan before changing the environment.
6. Install or configure approved missing tools.
7. Verify required tool commands and versions.
8. Run the Demo App local validation smoke check.
9. Write [setup/validation-environment.lock.json](./setup/validation-environment.lock.json).

Do not claim a package or workflow is validated until the validation environment lock is current and
the setup smoke checks pass.

## 1. Understand the Trust Boundary

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

## 2. Choose the Community Type and Surfaces

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

## 3. Declare Minimal Permissions

For every feature, state:

- Actor.
- Surface.
- Loom API used.
- Fields requested.
- Purpose.
- Data class.
- Retention/export behavior.
- Whether consent is required.

## 4. Compose Loom APIs

Use this escalation order:

1. Configuration.
2. Declarative rules.
3. Workflows and jobs.
4. Sandboxed functions only when declarative logic is insufficient.

## 5. Author Extension Artifacts

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

## 6. Validate

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

## 7. Local Download, Sideload, and Run

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

## 8. Debug the Skill

Treat Skill runs as reproducible tests:

- Keep prompt fixtures for each workflow and community type.
- Keep golden extension and initialization packages.
- Capture the model transcript, inputs, validator output, package diff, and final artifact hash.
- Capture prereq setup failures separately from package-generation failures.
- On failure, add the failing prompt or validator diagnostic before changing the Skill instructions.
- Re-run the Demo App sideload workflow after changing package shape or initialization behavior.

## 9. Certify, Publish, Install, and Run Latest

Submit signed artifact through the Extension Registry. Certification must approve it before install.
The Main Loom App resolves the latest certified version on open unless the owner pins or rolls back
through an allowed path.

## 10. Learn From Phase Guides

Before using a component or workflow, read the matching guide:

- `components/<component>.md`
- `workflows/<workflow>.md`

These guides contain practical usage notes beyond OpenAPI.

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
