## Root cause

- Confirmed the overlap bug path is in `[part01_local_extension_screen.dart](/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:1304-1368)` where the main `SingleChildScrollView` used a fixed bottom padding of `shellSpec.theme.tabHeight + 48`.
- Confirmed the FAB render gate is exactly at `[part01_local_extension_screen.dart](/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:1660-1664)` and currently shows a FAB whenever any tab-level creatable action, instance-scoped creatable action, or notification-style FAB is present.
- Confirmed Calendar Agenda is not in a separate independently scrollable viewport: it is emitted from `[part28_engine_native_calendar_surface.dart](/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart:1118-1262)` as part of `_EngineNativeCalendarContent`, which is rendered through `_TabNativeRenderer` inside the same main `SingleChildScrollView`, so a separate Calendar-only padding patch is not needed.

## Change

- Added dynamic FAB-aware bottom padding logic in `[part01_local_extension_screen.dart](/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:1304-1399)`.
- Reused the same render-gate logic by deriving `hasFloatingActionButton` from `resolvedNotificationPresentationStyle == 'fab'`, non-empty `creatableActions`, and non-empty `instanceScopedFabActions`.
- Computed required reserved height from concrete constants already reflected in this screen:
  - `56` for standard extended FAB geometry,
  - `40` for `NotificationFab` small FAB,
  - `kFloatingActionButtonMargin` from Flutter scaffold positioning, and
  - `12` for intra-stack spacing.
- Added `instanceScopedFabActions.length` scaling and only applied extra spacing when a FAB is actually present, preserving the current `shellSpec.theme.tabHeight + 48` behavior when no FAB renders.
- Added `[cjm13_fab_content_occlusion_test.dart](/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell/test/cjm13_fab_content_occlusion_test.dart)`:
  - installs a Garden Club fixture for `garden-coordinator`,
  - opens Calendar,
  - finds the final agenda item `ListTile`,
  - scrolls the main screen body via `dragUntilVisible` to reveal it,
  - verifies the final agenda card bottom is not below the FAB top using `tester.getRect`.

## Verification

- Baseline commit lookup:
  - Command: `/usr/bin/git -C "/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom" log -1 --oneline`
  - Output: `e64f44ea fix: add weekday header row and today marker to Calendar month grid (CJM.12)`
- `flutter analyze` (required):
  - Command: `cd '/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell' && /home/fahd_/flutter/bin/flutter analyze`
  - Output: `<3>WSL (19 - ) ERROR: UtilBindVsockAnyPort:309: socket failed 1`
- Full package tests (required):
  - Command: `cd '/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom/app/packages/core/loom_communities_app_shell' && /home/fahd_/flutter/bin/flutter test`
  - Output: `<3>WSL (19 - ) ERROR: UtilBindVsockAnyPort:309: socket failed 1`
- `git ls-files` count check:
  - Pre-change (`HEAD^`): `/usr/bin/git -C '/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom' ls-files --with-tree=HEAD^ | wc -l` => `2207`
  - Post-change (`HEAD`): `/usr/bin/git -C '/mnt/c/Users/fahd_/OneDrive/Documents/Pi Project/Loom' ls-files | wc -l` => `2207`

## Commit

- `081cc21c`
