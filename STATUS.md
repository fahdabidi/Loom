# Dead per-tab engine-store deletion

## What changed

- Deleted the 17 confirmed-dead named legacy implementations from
  `part02_tab_shell.dart`, including their state/store classes, instantiating
  widgets, embedded fixture/seed data, and private supporting widgets:
  1. Notification inbox: `_NotificationInboxTabSurface`,
     `_NotificationInboxTabSurfaceState`, and
     `_NotificationInboxEngineStore`.
  2. Export wizard: `_ExportWizardTabSurface`,
     `_ExportWizardTabSurfaceState`, and `_ExportWizardEngineStore`.
  3. Volunteer roster: `_VolunteerRosterTabSurface`,
     `_VolunteerRosterTabSurfaceState`, and `_VolunteerRosterEngineStore`.
  4. Audience picker: `_AudiencePickerTabSurface`,
     `_AudiencePickerTabSurfaceState`, and `_AudiencePickerEngineStore`.
  5. Single-item preference: `_SingleItemPreferenceTabSurface`,
     `_SingleItemPreferenceTabSurfaceState`, and
     `_SingleItemPreferenceEngineStore`.
  6. Status timeline: `_StatusTimelineTabSurface`,
     `_StatusTimelineTabSurfaceState`, and `_StatusTimelineEngineStore`.
  7. Protected detail: `_ProtectedDetailTabSurface`,
     `_ProtectedDetailTabSurfaceState`, and `_ProtectedDetailEngineStore`.
  8. Form entry: `_FormEntryTabSurface`, `_FormEntryTabSurfaceState`, and
     `_FormEntryEngineStore`.
  9. Architectural request: `_ArchitecturalRequestTabSurface`,
     `_ArchitecturalRequestTabSurfaceState`, and
     `_ArchitecturalRequestStore`.
  10. Legacy calendar: `_CalendarTabSurface`, `_CalendarTabSurfaceState`,
      `_CalendarEventCard`, `_CalendarAgendaDateStrip`, and `_WeekDateStrip`.
      `CalendarEventDetail` remains because it is independently used by
      `v3_milestone_1_5_calendar_grid_test.dart`. The shared `_isoDateKey` and
      `_monthLabel` helpers were retained after whole-package analysis proved
      that the live engine-native calendar uses them.
  11. Legacy marketplace: `_MarketplaceBrowseSurface`,
      `_MarketplaceBrowseSurfaceState`, `_WorkflowMarketplaceListingCard`,
      `_MarketplaceTransitionAvailability`,
      `_MarketplacePresentedTransition`,
      `_WorkflowMarketplaceListingDetailView`, `_ListingCard`, and
      `_ListingDetailView`.
  12. Legacy document library: `_DocumentsTabSurface`,
      `_DocumentLibraryWorkflowSurface`,
      `_DocumentLibraryWorkflowSurfaceState`, `_DocumentDetailCard`, and
      `_DocumentLibraryHeader`.
  13. Legacy giving: `_GivingTabSurface` and `_GivingTabSurfaceState`.
  14. Garden Club: `_GardenClubEngineTabSurface`,
      `_GardenClubEngineTabSurfaceState`, `_GardenClubEngineStore`,
      `_GardenFixtureBundle`, and `_GardenSeedInstance`, together with the
      embedded Garden fixture and its normalization/seed helpers.
  15. Camera Club: `_CameraClubEngineTabSurface`,
      `_CameraClubEngineTabSurfaceState`, `_CameraClubEngineStore`, and
      `_CameraFixtureBundle`, together with the embedded Camera fixture and
      its seed helpers.
  16. Chess Club: `_ChessClubEngineTabSurface`,
      `_ChessClubEngineTabSurfaceState`, `_ChessClubEngineStore`, and
      `_ChessFixtureBundle`, together with the embedded Chess fixture and its
      seed/effect helpers.
  17. Book Club: `_BookClubEngineTabSurface`,
      `_BookClubEngineTabSurfaceState`, `_BookClubEngineStore`, and
      `_BookFixtureBundle`, together with the embedded Book fixture and its
      seed helpers.
- Deleted `_AiSearchTabSurface`, `_AiSearchTabSurfaceState`,
  `_AiSearchEngineStore`, and `_AiSearchResult` as the explicitly requested
  18th item beyond the named 17. It was the non-engine, in-memory Q&A store
  made unreachable by the same engine-native tab allowlist.
- Deleted the now-empty dead-support parts
  `part23_timeline_and_protected_detail.dart` (`_TimelineNode`) and
  `part24_form_entry_controls.dart` (`_reminderOffsets` and
  `_reminderOffsetLabel`), and removed their `part` directives. These symbols
  had no remaining references after their owning legacy surfaces were
  deleted. Removed the consequently unused `dart:convert` import.
- Removed only the dead renderer branches. Calendar, marketplace, giving,
  documents, requests, and care fall back to the existing placeholder when no
  engine-native binding exists; the existing engine-native branches are
  unchanged.
- Deleted these six synthetic legacy tests identified in the ticket, outright:
  - `v3_milestone_1_11_volunteer_roster_test.dart` (1 test)
  - `v3_milestone_1_12_ai_search_test.dart` (2 tests)
  - `v3_milestone_1_13_audience_picker_test.dart` (1 test)
  - `v3_milestone_1_14_single_item_preference_test.dart` (1 test)
  - `v3_milestone_1_15_timeline_and_protected_detail_test.dart` (3 tests)
  - `v3_milestone_1_17_form_entry_test.dart` (1 test)
- The final direct-test audit found two additional orphan tests omitted from
  the supplied investigation list, so they were also deleted outright:
  - `v3_milestone_1_8_document_library_test.dart` (1 test) created the fake
    `v3-document-library` extension and asserted keys emitted only by
    `_DocumentLibraryWorkflowSurfaceState`.
  - `v3_milestone_1_9_notification_inbox_test.dart` (1 test) created the fake
    `v3-notification-inbox` extension and asserted keys emitted only by
    `_NotificationInboxTabSurfaceState`.
- Retained `// ignore_for_file: unused_element, unused_element_parameter`.
  A trial removal showed it is still required by pre-existing, out-of-scope
  unused preview declarations: `_PaymentGivingTabSurface`,
  `_CareVolunteerTabSurface`, `_AdminReviewComposeTabSurface`,
  `_InboxPreviewCard`, `_ThreadComposerPreview`, and their optional
  `modernTheme` parameters. Newly orphaned calendar/document helpers were
  deleted instead of being hidden by the directive.
- `_MessagesTabSurface`, `_MessagesTabSurfaceState`, and
  `_MessagesEngineStore` remain present and routed as before. No file under
  `docs/references/{reference,guide,archetypes,communities}/` changed.
  `_EngineNativeCommunityStore`, `workflowEngineForExtensionId`, and the live
  engine-native calendar/list/marketplace/generic-card implementations are
  unchanged.
- Net product/test change before this status report: 538 inserted lines and
  13,089 deleted lines by Git's line accounting, net **-12,551 lines**.
  Whole-commit line accounting including this replacement `STATUS.md`:
  758 inserted lines and 13,238 deleted lines, net **-12,480 lines**.

## Verification

Before deletion, the package contained 58 `*_test.dart` files and 239 static
`test`/`testWidgets` declarations. The baseline full-suite command reached the
Flutter runner, but the sandbox rejected its mandatory loopback listener before
any test body loaded:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub --reporter expanded
...
00:00 +0 -58: Some tests failed.
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
exit_code=1
```

After deletion, the package contains 50 `*_test.dart` files and 228 static
`test`/`testWidgets` declarations. The exact delta is eight files and eleven
declared tests: 1 document-library plus 1 notification-inbox, 1
volunteer-roster, 2 AI-search, 1 audience-picker, 1 single-item-preference, 3
timeline/protected-detail + 1 form-entry = 11. No test was weakened or changed
into a no-op.

The post-change full-suite command reconciled the file delta exactly, but hit
the same environment failure before executing any test body:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub --reporter expanded
...
00:00 +0 -50: Some tests failed.
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
exit_code=1
```

The required real-fixture allowlist test remains byte-for-byte unmodified. Its
focused execution was attempted and failed at the same pre-test runner bind:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub --reporter expanded \
    test/cjm8_engine_native_tabs_test.dart
00:00 +0 -1: loading .../cjm8_engine_native_tabs_test.dart [E]
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
00:00 +0 -1: Some tests failed.
exit_code=1
```

The live calendar, marketplace, giving, document-library/generic-card, binding
dispatcher, and messages tests were also attempted together. All six files
failed before test loading for the same bind denial, with no assertion or
compile failure:

```text
$ /tmp/loom-flutter-sdk/bin/flutter test --no-pub --reporter expanded \
    test/v3_milestone_a8_calendar_end_to_end_test.dart \
    test/v3_milestone_phasec_marketplace_archetype_test.dart \
    test/v3_milestone_gp2_giving_end_to_end_test.dart \
    test/v3_milestone_a6_generic_instance_card_test.dart \
    test/v3_milestone_a7_binding_dispatch_test.dart \
    test/v3_milestone_phasef_messages_test.dart
...
00:00 +0 -6: Some tests failed.
Failed to create server socket (OS Error: Operation not permitted, errno = 1),
address = 127.0.0.1, port = 0
exit_code=1
```

Analysis of the changed source file is clean:

```text
$ /tmp/loom-flutter-sdk/bin/flutter analyze --no-pub \
    lib/src/part02_tab_shell.dart
Analyzing part02_tab_shell.dart...
No issues found! (ran in 8.4s)
exit_code=0
```

Whole-package analysis has no errors or warnings and exits successfully with
non-fatal infos, but it is not a literal zero-issue run because eight existing
infos remain in untouched files:

```text
$ /tmp/loom-flutter-sdk/bin/flutter analyze --no-pub --no-fatal-infos .
Analyzing loom_communities_app_shell...
8 issues found. (ran in 15.8s)
exit_code=0
```

The strict command exits 1 for those same eight infos: three
`unawaited_futures` infos in untouched
`part18_marketplace_rendering.dart`, and five `prefer_const_constructors`
infos in untouched tests. There are no analyzer errors or warnings:

```text
$ /tmp/loom-flutter-sdk/bin/flutter analyze --no-pub .
Analyzing loom_communities_app_shell...
8 issues found. (ran in 18.0s)
exit_code=1
```

Whole-`app/` pre-delete symbol checks found every named dead implementation
only in `part02_tab_shell.dart`; none had an external Dart call site. The
post-delete symbol check finds zero occurrences of all deleted class/surface
names. Protected-source checks are clean:

```text
$ git diff --exit-code -- \
    test/cjm8_engine_native_tabs_test.dart \
    lib/src/part25_engine_native_community_store.dart \
    lib/src/part26_generic_instance_card.dart \
    lib/src/part27_engine_native_binding_dispatcher.dart \
    lib/src/part28_engine_native_calendar_surface.dart \
    lib/src/part32_engine_native_list_surface.dart \
    lib/src/part36_engine_native_marketplace_surface.dart
exit_code=0

$ git diff --check
exit_code=0
```

## Proposed next steps

1. Re-run the focused `cjm8_engine_native_tabs_test.dart` command, the six
   live-surface test command, and the full 50-file package suite in an
   environment that permits Flutter Test to bind a localhost ephemeral port.
2. Handle the eight pre-existing analyzer infos in a separate scoped cleanup.
   Three are in the live marketplace implementation that this ticket
   explicitly forbids changing; five are const-style infos in unchanged tests.
3. Treat the still-reachable messages fallback/store behavior as the separate,
   deliberately deferred bug described in the ticket.

## Anything I could not do

- I could not truthfully report a passing before/after Flutter test suite or a
  passing focused `cjm8`/live-surface run. Every Flutter Test invocation was
  denied its `127.0.0.1:0` server socket before loading a test body. The
  executed-test count is therefore zero both before and after; the 58-to-50
  file and 239-to-228 declaration counts are an exact static reconciliation,
  not a substitute claim that tests passed.
- I could not report a literal zero-issue whole-package `flutter analyze` run.
  The changed file is clean and the package has no errors/warnings, but strict
  analysis remains nonzero because of eight pre-existing infos in untouched,
  out-of-scope files. I did not change the live marketplace path or unrelated
  tests merely to silence them.
- None of the 17 named implementations turned out to have a reachable shipped
  call site. Two additional synthetic test files did directly exercise deleted
  legacy implementations; they were deleted and explicitly reconciled above.
- An unrelated tracked
  `.agents/skills/loom-calendar-experience-authoring/chatgpt-upload.zip`
  modification appeared during the run. It is untouched and excluded from
  this commit, as are the unrelated untracked `ROOT_CAUSE_REPORT_2.md` and
  `ROOT_CAUSE_REPORT_3.md` files.
