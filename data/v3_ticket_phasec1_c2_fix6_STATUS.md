# Ticket status: Phase C.1-2 fix6

## Root cause found

This was a test-side category-chip hit/settling proof gap, not a broken production filter predicate. The live path is wired correctly: `ChoiceChip.onSelected` calls `onCategorySelected`, the Marketplace state stores the selected category in `_selectedCategory`, passes it into `_EngineNativeMarketplaceContent`, and `_filteredBindings` retains only instances whose `instanceData['category']` exactly matches it. After clearing the Wingspan search, the test tapped `marketplace-filter-Strategy Games` without first ensuring that chip was visible, so the gesture was not guaranteed to reach the chip after the preceding text/layout interaction. Its subsequent `_pumpUntil(Root)` was also vacuous because Root was already present before the tap; it could return without proving that the category callback had run. The test now ensures the chip is visible, waits for both non-matching Catan and Wingspan cards to disappear, and asserts the chip's `selected` state, then repeats the visibility/state checks when clearing the filter. No production Marketplace code required changing.

## Change applied
Status: done

## Verification
flutter analyze: not runnable in this sandbox — the Flutter wrapper failed before analysis with `UtilBindVsockAnyPort:309: socket failed 1`; direct Dart analysis of `packages/core/loom_communities_app_shell` completed cleanly with `No issues found!`.
Test suite: pass count unavailable (0/48 package test files reached test execution). The focused Phase C Marketplace test, focused calr4g test, and full package suite all failed before test bodies because Flutter could not create its loopback tester server (`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`). The full invocation ended `00:00 +0 -48: Some tests failed` while loading. Therefore this sandbox cannot confirm the a11-only failure or confirm all 3 Phase C Marketplace archetype tests and both calr4g tests pass; independent outside-sandbox verification is required.

## Commit
f55f111a (the implementation agent's dispatch was interrupted before its own commit step completed;
independently verified — flutter analyze clean, 169/170 app-shell suite green with only the known a11 flake
failing — and committed by the verification agent).
