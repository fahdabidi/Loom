# Skill Arbitrary Extension Test Run

Use this workflow to validate a freshly generated arbitrary local-demo extension before treating the
Skill output as usable.

## Process

1. Capture the owner-approved requirements docs for workflows, major UI screens, features, permissions,
   schemas, rules, jobs, assets, and UI guidelines.
2. Generate the local-demo extension package and initialization package.
3. Save the generated package manifests and debug transcript with the Skill example.
4. Copy the generated manifests into files with the locked suffixes:
   - `<extension-id>.loom-extension.zip`
   - `<extension-id>.loom-init.zip`
5. Load the pair through the Demo App Add Community flow or the Local In-App Backend replay harness.
6. Assert the installed community uses the generated name, extension ID, branding, seed file list, and
   local latest route.
7. Iterate from validation failures by updating the Skill artifact docs or generator instructions first,
   then rebuilding the package pair.

## B10 Reference Fixture

The B10 test fixture is `Skill/examples/arbitrary-garden-club/`. It proves the Skill can emit an
extension/init pair that is not one of the anchor verticals and still load into the Demo App with the
Local Backend.

## Covering Tests

- `wf_skill-arbitrary-extension-test-run`
