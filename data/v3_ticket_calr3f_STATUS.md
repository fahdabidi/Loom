# Ticket status: CALR.3f bounded layout fix

## Fix applied

Status: done

`LocalExtensionScreen` now uses a fixed `Column` body. Its existing active-tab
scroll region is an `Expanded` `SingleChildScrollView`, so the community banner,
hero, and selected-tab header remain outside the scrolling content while the
currently selected tab is hosted within the bounded viewport. The existing
scroll controller, bottom-navigation clearance, tab content, and local package
details remain in that scrollable active-content region. The stale tab-shell
comment was updated to describe the new bounded region.

## Regression scope

The change is shared shell infrastructure and applies to every tab and
community, not only Calendar. I inspected the renderer dispatch paths for
Calendar, Messages, Marketplace, Documents, Workflow Status, and all
engine-native community routes; no individual tab surface widget was changed.
Automated full-suite execution was blocked before tests could start.

## Verification

dart analyze: not clean — blocked before analysis by Flutter's launcher:
`/home/fahd_/flutter/bin/internal/update_engine_version.sh: line 64:
/home/fahd_/flutter/bin/cache/engine.stamp: Read-only file system`.

Test suite: blocked: the complete `flutter test` command stopped at the same
read-only `engine.stamp` update before running any tests, so no pass count is
available. Scoped `git diff --check` for the two changed shell files passed.

## Commit

Pending commit.
