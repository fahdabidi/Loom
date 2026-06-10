# Arbitrary Camera Club Prompt Fixture

This B11 fixture is the owner prompt used to validate the full Skill loop:

1. Capture requested workflows.
2. Generate review docs and package artifacts.
3. Load the generated package pair into the Demo App Local Backend.
4. Validate every requested workflow.
5. Emit a completion report.

The test does not reuse a golden package. It reads `owner-prompt.txt`, generates artifacts into a temp
directory, installs the generated packages, and checks the validation report.
