# Arbitrary Local Package Ingestion

Use this workflow after the Skill generates any local-demo extension/init pair that is not one of the
worked vertical fixtures.

## Process

1. Create `<extension-id>.loom-extension.zip` and `<extension-id>.loom-init.zip`.
2. Ensure the extension package either contains `loom.extension.json` inside the zip or is a direct
   JSON payload with the locked package suffix. It must declare `extensionId`, `displayName`,
   `version`, permissions, and asset IDs.
3. Ensure the initialization package either contains `loom.initialization.json` inside the zip or is a
   direct JSON payload with the locked package suffix. It must declare `communityId`, `communityName`
   or `displayName`, the matching `extensionId`, seed data files, and branding asset IDs.
4. Save both files to a path the Demo Loom Communities App can read.
5. In the Demo App, choose Add Community and enter both local file paths.
6. Validate and install the pair.
7. Confirm the installed card uses the generated community name, extension ID, accent color, card image,
   logo, and hero image references.
8. Open `local:<extension-id>@latest`.

## Debug Loop

- If the card shows Book Club or another fixture, treat it as a loader regression.
- If the package fails before install, capture the two generated JSON payloads, path suffixes, and error
  text.
- If the extension and initialization `extensionId` values differ, rebuild the package pair before
  testing UI behavior.
- Keep the arbitrary package in the Skill debug transcript so later iterations can replay the same
  local-demo install.

## Covering Tests

- `vt_fake-backend_parse-arbitrary-local-package-pair`
- `vt_fake-backend_parse-arbitrary-zip-package-pair`
- `vt_fake-backend_import-arbitrary-package-pair`
- `vt_demo-app_arbitrary-local-extension-loads-card`
- `wf_arbitrary-local-package-ingestion`
