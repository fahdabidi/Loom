# Skill Setup Troubleshooting

Status: Phase 0 skeleton

Use this guide when prereq setup fails before package or workflow validation can start.

## Failure Categories

| Category | Typical signal | Required response |
| --- | --- | --- |
| Unsupported execution target | Target is not Codex or Claude Code. | Stop local validation and explain that online-only support requires a hosted backend. |
| Missing tool | A verify command fails. | Add the missing tool to the install plan before retrying validation. |
| Version mismatch | Tool exists but does not meet the prereq manifest. | Upgrade or pin the tool, then regenerate the environment lock. |
| Emulator unavailable | Android emulator or `adb` check fails. | Fix emulator setup before running Demo App workflow tests. |
| Demo App smoke failure | App does not boot or local backend hook is unreachable. | File the failure against the owning Demo App or Local Backend component before changing Skill instructions. |
| Validator unavailable | Extension or initialization validator command fails to start. | Fix tooling package setup before rebuilding generated artifacts. |

## Debug Evidence

Each setup failure should capture:

- Execution target.
- Host OS and shell.
- Failed command.
- Exit code.
- Relevant stderr/stdout.
- Prereq manifest version.
- Existing environment lock, if any.
- Proposed fix or owning component.
