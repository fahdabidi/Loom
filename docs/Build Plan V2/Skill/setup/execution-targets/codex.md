# Codex Execution Target

Status: Phase 0 skeleton

Codex is a supported local execution target for the Loom Skill because it can operate over the Loom
source tree, edit files, run repo commands, inspect validator output, and iterate on generated
artifacts.

## Expected Capabilities

- Read Architecture V2, Product Docs V2, Build Plan V2, OpenAPI specs, and Skill guides.
- Create and update extension source files, fixtures, and generated packages.
- Run prereq checks, package validators, manifest gates, phase gates, and Demo App workflow tests.
- Capture diagnostics, transcripts, hashes, and lockfile changes.

## Setup Contract

Codex must run the prereq setup flow before validation:

1. Load `Skill/setup/prereq-manifest.json`.
2. Detect host capabilities.
3. Produce an install/configuration plan.
4. Install or configure approved missing tools.
5. Verify tool commands.
6. Write `Skill/setup/validation-environment.lock.json`.

## Unsupported Without A Hosted Backend

Codex may draft online-only instructions, but a purely online surface cannot be marked validation-ready
unless a hosted Loom build and validation backend performs the equivalent package, emulator, and
workflow checks.
