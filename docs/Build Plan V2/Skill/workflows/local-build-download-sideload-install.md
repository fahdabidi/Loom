# Local Build Download Sideload Install

Use this workflow for `local-demo` mode when no hosted Loom backend exists.

## Process

1. Verify the validation environment lock is current for Codex or Claude Code.
2. Generate `<extension-id>.loom-extension.zip`.
3. Generate `<extension-id>.loom-init.zip`.
4. Validate extension package shape, asset manifest, and asset policy.
5. Validate initialization schema, idempotency, and community branding.
6. In the Demo App, use Add Community to open the local package loader.
7. Point the loader at the `.loom-extension.zip` and `.loom-init.zip` files in the local/emulator file system.
8. Validate the package pair before import; fix suffix/schema errors before continuing.
9. Import the initialization package into the fake backend/local store.
10. Render the community card from imported branding props.
11. Open `local:<extension-id>@latest` inside App Shell.

## Debug Loop

- Save the prompt, generated package manifests, validator output, and final artifact hashes.
- Save the local extension/init package paths used by the Demo App loader.
- If install fails, update the failing component validation test first.
- If the Skill output is wrong, add the failing prompt and package diff to the example before changing
  Skill instructions.

## Covering Tests

- `wf_local-demo-prereq-to-validation-ready`
- `wf_local-build-download-sideload-install`
