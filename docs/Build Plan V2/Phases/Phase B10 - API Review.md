# Phase B10 - API Review

## Scope

B10 validates the first arbitrary Skill-output replay path. The review focuses on whether the local
parser accepts the documented Skill example shape and whether the replay harness proves generated
artifacts can be installed without fixture substitution.

## APIs Reviewed

| API or contract | Owner | B10 decision |
| --- | --- | --- |
| Skill arbitrary example manifests | ai-skill-extension-builder | `Skill/examples/arbitrary-garden-club/` is the replayable fixture for arbitrary generated output. |
| `LocalInAppBackend.parseLocalPackagePair` | local-in-app-backend | Accepts `displayName` as initialization community name alias and `branding.logo`, `branding.cardImage`, `branding.heroImage` as asset-reference aliases. |
| `LocalInAppBackend.installLocalPackagePairFromFiles` | local-in-app-backend | Replays Skill artifacts after copying JSON manifests to locked local-demo package suffixes. |
| `CommunityCardBranding` | community-card | Uses parsed Skill branding references directly as local asset identifiers until real archive extraction is added. |
| App Shell local open route | app-shell-runtime | Opens `local:<extension-id>@latest` from the parsed extension ID. |

## Payload Compatibility

The B10 parser supports both backend-native and Skill example names:

| Concept | Backend-native field | Skill example alias |
| --- | --- | --- |
| Community display name | `communityName` | `displayName` |
| Card image | `cardAssetId` or `branding.cardAssetId` | `branding.cardImage` |
| Logo | `logoAssetId` or `branding.logoAssetId` | `branding.logo` |
| Hero image | `heroImageAssetId` or `branding.heroImageAssetId` | `branding.heroImage` |
| Accent color | `accentColor` | `branding.accentColor` |

## Validation Decisions

| Decision | Rationale | Covering test |
| --- | --- | --- |
| Skill examples remain plain JSON in docs. | Keeps artifacts reviewable and diffable while the package-builder archive step is deferred. | `wf_skill-arbitrary-extension-test-run` |
| Replay writes JSON into locked package suffixes. | Exercises the same Demo App loader path used by local-demo installs. | `wf_skill-arbitrary-extension-test-run` |
| Parsed branding paths are accepted as local asset IDs. | The fake backend does not yet extract asset bytes; path references are sufficient for card identity. | `wf_skill-arbitrary-extension-test-run` |
| Book Club values are treated as a failure for this phase. | B10 exists specifically to prove arbitrary Skill output. | `wf_skill-arbitrary-extension-test-run` |

## Open API Gaps

- Add true package-builder output with zip archive assembly and extraction.
- Validate asset file existence and hashes inside the local package.
- Add full schema diagnostics for Skill-generated artifacts before local replay.
- Add a CLI command that packages a Skill example into `.loom-extension.zip` and `.loom-init.zip`
  rather than using the test harness copy step.
