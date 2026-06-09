# Loom Communities Product Definition 16: Builder Ecosystem, App IDs, and Extension Supply Chain

Status: Draft for review
Product area: 16 of 22 (Loom Communities / V2)
Source inputs: [API Reference 2 and 7](./Extensible%20Loom%20API%20Reference.md)
Predecessor: [Loom V1 Developer Ecosystem and DevOps Supply Chain](../Product%20Docs/16-developer-ecosystem-and-devops-supply-chain.md)

## 1. Product Definition

The builder ecosystem lets AI tools, developers, agencies, community owners, and internal teams create
safe Loom extensions. Builders get App IDs, SDKs, templates, fakes, validators, conformance tests,
artifact signing, versioning, certification feedback, and marketplace/listing paths.

The supply chain must make AI-generated and hand-written packages equally auditable.

## 2. Scope

This area covers builder identity, App IDs, package signing, extension registry submission, build
attestations, SBOMs, validators, local emulators, SDKs, fakes, examples, CI templates, certification
evidence, version release channels, rollback, revocation, and developer economics.

## 3. Key Features and Differentiators

| Feature | Definition | Product value | Interacting areas |
| --- | --- | --- | --- |
| App ID | Builder credential tied to Loom identity and signing keys. | Packages are attributable. | 05, 19 |
| Local harness | Contracts, fakes, local store, seed data, validators, and integration tests. | Builders can work before real providers exist. | Build Plan V2 |
| Signed artifacts | Immutable package versions with signatures and attestations. | Runtime can fail closed on tampering. | 10, 17 |
| Certification feedback | Actionable errors for permissions, UI invariants, data rights, ads, exports, and tests. | Safe iteration. | 19 |
| Version channels | Draft, preview, certified, revoked, rollback, and latest. | Owners can preview and update safely. | 15 |
| Examples and Skill docs | Component/workflow examples beyond OpenAPI. | AI and human builders learn correct patterns. | 11, 20 |

## 4. Product Experience Requirements

Builders should be able to create an App ID, scaffold a project, run fake backend tests, validate
package structure, sign artifacts, submit for certification, read failure output, publish updates, and
monitor installs/incidents. Owners should know who built an extension and what version is installed.

## 5. User Stories

1. **As a builder**, I create an App ID and publish a book club extension.
   End state: artifact is signed and attributable.
2. **As the Skill**, I use fakes and validators to catch missing permissions before submission.
   End state: generated package passes local checks.
3. **As governance**, I revoke a compromised package version.
   End state: App Shell fails closed and owners are notified.
4. **As an owner**, I preview an extension before installing it.
   End state: preview uses seed data and declared permissions.
5. **As a developer**, I release a patch without changing permissions.
   End state: latest certified version rolls forward automatically.

## 6. End-to-End Workflows

### Workflow 1: App ID and scaffold

1. Builder signs in with Passport/identity.
2. Builder console creates App ID and signing keys.
3. Builder chooses template or Skill output.
4. Local project includes manifest, schemas, tests, fakes, fixtures, and CI config.
5. Builder runs validator locally.

### Workflow 2: Sign, submit, certify, publish

1. Builder signs artifact and attaches build attestation/SBOM.
2. Extension registry stores immutable version.
3. Certification validates manifest, permissions, data rights, UI invariants, tests, and supply chain.
4. Approved version is marked certified and optionally listed.
5. Rejected version receives remediation output.

### Workflow 3: Incident and rollback

1. Vulnerability, policy breach, or compromised key is detected.
2. Governance limits or revokes package version/App ID.
3. App Shell stops loading revoked version.
4. Owners receive rollback or update path.
5. Builder submits fixed version and certification reruns.

## 7. Cross-Area Requirements

- Every package version must be attributable to App ID and builder identity.
- Validators must include ad/nav/payment/data-rights/export/certification checks.
- Runtime must fail closed on invalid signature, revoked App ID, or uncertified version.
- The Skill and examples must be versioned with the platform contracts.

## 8. Prototype Implications

The MVP needs App ID records, local scaffold, validator, fake backend, artifact signing stub, extension
registry version states, certification output, and one update/rollback path.

## 9. FAQ

**Can an owner use the Skill without becoming a developer?**
Yes. The Skill can create or use a builder identity/App ID behind a guided owner flow.

**Can unsigned packages run locally?**
Only in local/dev preview. Installable packages require signing and certification state.

## 10. Open Questions

- How should App IDs be delegated to agencies or teams?
- What marketplace model applies to paid extensions after MVP?
- Which SBOM/build attestation standards are required at launch?
