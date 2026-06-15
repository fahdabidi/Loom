# Book Club Phase B1b Publish Example

This example extends the B1a local package with publish metadata used by `real-backend-publish` mode.
It is still validated locally through fakes so the Skill can iterate before a hosted backend exists.

Artifacts:

- `loom.extension.json`: package metadata, permissions, assets, and publish metadata.
- `loom.initialization.json`: local fake-backend seed package.

Validation:

- `wf_build-publish-discover-install`
- `vt_ai-skill_generate-package`
