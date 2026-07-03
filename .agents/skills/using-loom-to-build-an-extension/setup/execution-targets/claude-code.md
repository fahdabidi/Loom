# Claude Code Execution Target

Status: Phase 0 skeleton

Claude Code is a supported local execution target for the Loom Skill when it has access to the Loom
source tree and can run the same setup and validation commands as Codex.

## Expected Capabilities

- Read Loom planning docs, API specs, component guides, workflow guides, and examples.
- Create extension artifacts and initialization packages in the local workspace.
- Run the prereq setup checks and the Demo App local validation workflow.
- Capture validator diagnostics and rebuild packages after owner-requested changes.

## Setup Contract

Claude Code must follow the same Skill prereq setup flow:

1. Load `Skill/setup/prereq-manifest.json`.
2. Detect host capabilities.
3. Produce an install/configuration plan.
4. Install or configure approved missing tools.
5. Verify tool commands.
6. Write `Skill/setup/validation-environment.lock.json`.

## Interop Requirement

Artifacts created by Claude Code must be portable to Codex and vice versa. The environment lock records
tool versions and validation evidence, not provider-specific transcript details.
