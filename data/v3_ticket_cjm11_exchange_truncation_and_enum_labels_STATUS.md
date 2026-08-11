## Root cause
- Exchange tile pills are rendered through `WorkflowFactPillRow` → `_factWidget` → shared `_SurfaceFactPill` in `part18_marketplace_rendering.dart`; the shared text inside `_SurfaceFactPill` had no `maxLines` override, so every pill was effectively single-line and clipped.
- In engine-native marketplace cards (`EquipmentLoanArchetypeCard`), those pills are generated from machine-provided field schemas in `part36_engine_native_marketplace_surface.dart::_factSchema`, so title/owner fields were not given any dedicated wrapping allowance while the grid constrained tile height (`gridChildAspectRatio: 0.58`).
- `_valueText` in `part18_marketplace_rendering.dart` returned `rawValue` text directly, so identifier-style state values like `onLoan` were rendered verbatim instead of sentence-style text.
- `_humanizeFieldName` logic in `part26_generic_instance_card.dart` already provided the camel/snake split behavior for field keys and is the right basis for value humanization.

## Change
- Added two-line support only where needed in the shared pill widget pipeline:
  - Added `maxLines` to `_SurfaceFactPill` (`part08_garden_and_helpers.dart`) with default `1`.
  - Threaded `maxLines` through `WorkflowFactPillRow` rendering paths and persona pills:
    - `_factWidget` now passes `schema.maxLines` into `_SurfaceFactPill` and `_WorkflowPersonaFact`.
    - `_WorkflowPersonaFact` now supports `maxLines` and applies it on its label `Text`.
  - Added `maxLines` field to `WorkflowFactPillFieldSchema` (default `1`).
- Scoped marketplace-specific wrapping to Exchange/marketplace identity/name fields:
  - `part36_engine_native_marketplace_surface.dart::_factSchema` sets `maxLines: 2` for `title`, `holderPersonaId`, and `claimedByPersonaId` when building card schemas.
  - Set `maxLines: 2` defaults for `title`/owner fields in `equipmentLoanDefaultInstanceDataSchema` and `equipmentGiveawayDefaultInstanceDataSchema` so marketplace-like templates get the same budget.
- Increased tile height budget for marketplace cards:
  - `part36_engine_native_marketplace_surface.dart` changed `gridChildAspectRatio` from `0.58` to `0.62`.
- Added a generic identifier-to-display value humanizer:
  - `part18_marketplace_rendering.dart` now applies identifier humanization in `_valueText` only when `_looksLikeIdentifierValue` detects values without spaces in a field-value-like form.
  - Added public `humanizeIdentifierValue(String rawValue)` using adapted `_humanizeFieldName` logic (camelCase + underscores) + title-casing words.
  - Example conversions now supported: `onLoan` → `On Loan`, `available` → `Available`.
- Tests added/extended in `app/packages/core/loom_communities_app_shell/test/milestone_1_4_test.dart`:
  - New widget test verifies item/owner pills show full long strings and that `maxLines == 2` for both.
  - New direct unit test verifies `humanizeIdentifierValue('onLoan')`, `humanizeIdentifierValue('available')`, and unchanged prose value behavior for `Neighborhood Association Archive`.

## Verification
- Baseline reference commit (per `git log -1` before changes):
  - `/usr/bin/git log -1 --oneline` 
  - Output: `7cd86d33 fix: resolve CJM.10's own retry-tap test regression (CJM.10b)`
- Flutter validation attempts were blocked by the workspace runtime socket error:
  - `/home/fahd_/flutter/bin/flutter analyze` 
    - Output: `WSL (169 - ) ERROR: UtilBindVsockAnyPort:309: socket failed 1` and `WSL (174 - ) ERROR: UtilBindVsockAnyPort:309: socket failed 1`
  - `/home/fahd_/flutter/bin/flutter test` 
    - Same `UtilBindVsockAnyPort:309` errors.
- File status before commit:
  - `/usr/bin/git status --short` 
  - Output:
    - `M app/packages/core/loom_communities_app_shell/lib/src/part08_garden_and_helpers.dart`
    - `M app/packages/core/loom_communities_app_shell/lib/src/part18_marketplace_rendering.dart`
    - `M app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart`
    - `M app/packages/core/loom_communities_app_shell/test/milestone_1_4_test.dart`
- Repository tracked-file sanity check:
  - `/usr/bin/git ls-files | wc -l`
  - Output: `2205`

## Commit
- Committed as `632de44e` with message: `fix: stop truncating Exchange item/owner names, humanize raw enum state values (CJM.11)`
