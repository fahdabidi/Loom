# Using Loom To Build An Extension

Status: Phase 0 skeleton

This walkthrough is the process an LLM or developer follows to build a Loom Communities extension using
the reference Loom source and APIs.

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
- cards and routes
- schemas
- rules
- workflows
- jobs
- fixtures
- validation tests
- owner/member notes

## 6. Validate

Run:

- package validator
- manifest gate
- extension-specific validation tests
- App Shell invariant lint
- permission-negative tests
- export tests for custom records

## 7. Certify, Publish, Install, and Run Latest

Submit signed artifact through the Extension Registry. Certification must approve it before install.
The Main Loom App resolves the latest certified version on open unless the owner pins or rolls back
through an allowed path.

## 8. Learn From Phase Guides

Before using a component or workflow, read the matching guide:

- `components/<component>.md`
- `workflows/<workflow>.md`

These guides contain practical usage notes beyond OpenAPI.
