# Phase Test Manifest Bridge

Use `CommunityTestManifestApi` to record test status and identify stale tests for phase gates. The
machine manifest remains the source of truth; this bridge gives components a typed view over it.

## Extension Use

- Record generated test status after validation.
- Treat stale results as blocking for phase completion.
- Do not bypass `test-manifest.json` when adding or changing tests.

## Validation

- `vt_test-manifest_staleness` proves stale test lookup.
