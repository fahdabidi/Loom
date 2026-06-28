# Phase B12 - API Review

No new Loom service API is introduced in B12.

The phase adds a test/evidence contract:

- `workflow-ui-evidence.json` records workflow ID, app ID, screenshot paths, assertions, command
  output path, emulator/device metadata, and pass/fail status.
- The Android emulator screenshot driver writes PNG artifacts for each screenshot requested by the
  integration test.
- Missing screenshot files fail evidence generation.

Existing package, App Shell, Local Backend, and workflow APIs remain unchanged.
