// Regression coverage for `positionUnavailableInstanceEvidence`
// (workflow_ui_test_harness.dart), added to fix the B25 defect where a
// `primary_action_unavailable` row's only frame (`start`) is captured at the
// top of the tab scroll, so the instance whose action was unavailable is
// never actually shown.
//
// Two things this file exists to prove, because a positioning fix that
// "passes" without proving either is not a guard:
//
// 1. The MECHANISM: given an instance sitting off-viewport, the helper
//    brings it into view -- and does so via the calendar selected-detail
//    (preferred) or the generic instance card, never by scrolling past an
//    open marketplace dialog, which is the specific regression the ticket
//    that added this helper called out as "most likely to cause a
//    regression".
// 2. The SHAPE: `integration_test/workflow_ui_evidence_test.dart`'s two
//    unavailable branches (`primaryCandidates.isEmpty` and
//    `actionWait.action == null`) both call this one shared helper, not two
//    independently-written inline copies -- read as source text, since the
//    real branches live in an `integration_test` file that needs a device to
//    run.
//
// Every widget test below was run once with the fix under test disabled
// (either short-circuited to a no-op, or with its marketplace-dialog guard
// removed) to confirm it fails for the reason it claims to guard, then
// restored -- per CLAUDE.md, "neutralise the call and show it failing
// before reporting it as working."

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workflow_ui_test_harness.dart';

const _sourceRelativePath =
    'apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart';

File _findEvidenceTestSource() {
  var dir = Directory.current;
  while (true) {
    final candidate = File('${dir.path}/$_sourceRelativePath');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not locate $_sourceRelativePath from '
        '${Directory.current.path}.',
      );
    }
    dir = parent;
  }
}

/// A scrollable page with a spacer tall enough to push [instanceId]'s
/// generic instance card below the fold of the default 800x600 test
/// viewport, and another spacer after it so scrolling has somewhere to go.
Widget _offViewportGenericCardFixture(String instanceId) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 2000),
            SizedBox(
              height: 80,
              child: KeyedSubtree(
                key: ValueKey('generic-instance-card-$instanceId'),
                child: const Text('instance'),
              ),
            ),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('positionUnavailableInstanceEvidence: mechanism', () {
    testWidgets(
      'scrolls the generic instance card into view when it is the only '
      'candidate',
      (tester) async {
        const instanceId = 'pos-generic-1';
        await tester.pumpWidget(_offViewportGenericCardFixture(instanceId));

        final card = find.byKey(
          ValueKey('generic-instance-card-$instanceId'),
        );
        expect(card, findsOneWidget);
        expect(
          card.hitTestable(),
          findsNothing,
          reason: 'Fixture must start with the instance card below the fold '
              '-- otherwise this test cannot prove the helper moved it.',
        );

        await positionUnavailableInstanceEvidence(
          tester: tester,
          instanceId: instanceId,
        );
        await tester.pumpAndSettle();

        expect(
          card.hitTestable(),
          findsOneWidget,
          reason:
              'positionUnavailableInstanceEvidence must scroll the generic '
              'instance card into view when nothing else claims the row.',
        );
      },
    );

    testWidgets(
      'prefers the calendar selected-detail over the generic instance card '
      'when both are present',
      (tester) async {
        const instanceId = 'pos-calendar-1';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Deliberately already visible: if the helper checked
                    // the generic card first (wrong order), it would see
                    // this as "present" and stop, leaving the calendar
                    // detail below unpositioned.
                    SizedBox(
                      height: 80,
                      child: KeyedSubtree(
                        key: ValueKey('generic-instance-card-$instanceId'),
                        child: const Text('generic card'),
                      ),
                    ),
                    const SizedBox(height: 2000),
                    SizedBox(
                      height: 80,
                      child: KeyedSubtree(
                        key: ValueKey(
                          'engine-native-calendar-selected-detail-'
                          '$instanceId-0',
                        ),
                        child: const Text('calendar detail'),
                      ),
                    ),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        );

        final genericCard = find.byKey(
          ValueKey('generic-instance-card-$instanceId'),
        );
        final calendarDetail = find.byKey(
          ValueKey(
            'engine-native-calendar-selected-detail-$instanceId-0',
          ),
        );
        expect(
          genericCard.hitTestable(),
          findsOneWidget,
          reason: 'Fixture must start with the generic card already visible.',
        );
        expect(
          calendarDetail.hitTestable(),
          findsNothing,
          reason:
              'Fixture must start with the calendar detail below the fold.',
        );

        await positionUnavailableInstanceEvidence(
          tester: tester,
          instanceId: instanceId,
        );
        await tester.pumpAndSettle();

        expect(
          calendarDetail.hitTestable(),
          findsOneWidget,
          reason:
              'The calendar selected-detail must be preferred over the '
              'generic instance card when both are present.',
        );
      },
    );

    testWidgets(
      'does not scroll the background list when a marketplace detail '
      'dialog is already open',
      (tester) async {
        const instanceId = 'pos-marketplace-1';
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KeyedSubtree(
                key: const ValueKey('marketplace-detail-test-surface'),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 2000),
                      Builder(
                        builder: (context) => InkWell(
                          key: ValueKey(
                            'marketplace-listing-tap-$instanceId',
                          ),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => Dialog(
                              key: ValueKey(
                                'marketplace-detail-dialog-$instanceId',
                              ),
                              child: const SizedBox(
                                height: 120,
                                width: 200,
                                child: Text('marketplace detail'),
                              ),
                            ),
                          ),
                          child: const SizedBox(
                            height: 80,
                            width: 200,
                            child: Text('listing'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2000),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final surface = find.byKey(
          const ValueKey('marketplace-detail-test-surface'),
        );
        final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
          tester: tester,
          surface: surface,
          tabId: 'marketplace',
          instanceId: instanceId,
        );
        expect(
          preparation.isReadyForActionPolling,
          isTrue,
          reason: 'Fixture setup must open the marketplace detail dialog '
              'before this test can prove the helper leaves it alone.',
        );

        // Preparation's own `tapWhenVisible` already scrolled the listing
        // tile into view to tap it, so it would be a no-op (and this test
        // would prove nothing) to merely assert the offset survives
        // unchanged from here: a buggy helper that fell through to
        // `ensureVisible`-ing the tile again would ALSO leave the offset
        // unchanged, since the tile is already fully visible. Jump the
        // background list back to the top -- the dialog stays open
        // regardless of the underlying scroll position -- so the tile is
        // genuinely off-viewport again. Now a buggy fallback and a correct
        // early-return are distinguishable: only the buggy path would move
        // the offset off zero.
        scrollController.jumpTo(0);
        await tester.pump();
        expect(scrollController.offset, 0.0);

        await positionUnavailableInstanceEvidence(
          tester: tester,
          instanceId: instanceId,
          marketplacePreparation: preparation,
        );
        await tester.pumpAndSettle();

        expect(
          scrollController.offset,
          0.0,
          reason:
              'The open marketplace detail dialog IS the instance view; '
              'positionUnavailableInstanceEvidence must not scroll the list '
              'behind it -- doing so would move the tile behind the modal '
              'barrier for no visible effect on the captured frame.',
        );
        expect(
          find.byKey(ValueKey('marketplace-detail-dialog-$instanceId')),
          findsOneWidget,
          reason: 'The dialog must still be open after positioning.',
        );
      },
    );

    testWidgets(
      'is a no-op and never throws when nothing matches the instance id',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );

        await expectLater(
          positionUnavailableInstanceEvidence(
            tester: tester,
            instanceId: 'nothing-matches-this-id',
          ),
          completes,
        );
      },
    );

    testWidgets(
      'does not throw when the instance id matches more than one widget key',
      (tester) async {
        const instanceId = 'pos-multi-1';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 2000),
                    SizedBox(
                      height: 80,
                      child: KeyedSubtree(
                        key: ValueKey('generic-instance-card-$instanceId'),
                        child: Column(
                          children: [
                            const Text('instance'),
                            // The finder in the harness is a contains-match,
                            // so this second keyed widget also matches --
                            // ensureVisible must be called with `.first`,
                            // never the raw multi-match finder.
                            KeyedSubtree(
                              key: ValueKey(
                                'generic-instance-badge-$instanceId',
                              ),
                              child: const Text('badge'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2000),
                  ],
                ),
              ),
            ),
          ),
        );

        await expectLater(
          positionUnavailableInstanceEvidence(
            tester: tester,
            instanceId: instanceId,
          ),
          completes,
        );
      },
    );
  });

  group('positionUnavailableInstanceEvidence: call-site shape', () {
    test(
      'both unavailable branches in workflow_ui_evidence_test.dart call the '
      'one shared helper, never a duplicated inline copy',
      () {
        final source = _findEvidenceTestSource().readAsStringSync();
        final callSites = RegExp(
          r'positionUnavailableInstanceEvidence\s*\(',
        ).allMatches(source).length;
        expect(
          callSites,
          2,
          reason:
              'Expected exactly two call sites -- the primaryCandidates.'
              'isEmpty branch and the actionWait.action == null branch -- '
              'each calling the one shared harness helper. A duplicated '
              'inline copy in either branch, or the call disappearing from '
              'one of them, both change this count. Found $callSites.',
        );
      },
    );
  });
}
