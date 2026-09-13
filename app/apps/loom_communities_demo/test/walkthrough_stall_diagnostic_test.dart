import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'walkthrough_wait.dart';
import 'workflow_ui_test_harness.dart';

void main() {
  test('stall message names last step, attempted step, wait, and frame', () {
    final budget = WalkthroughWaitBudget(timeout: const Duration(seconds: 45));
    final message = buildWalkthroughStallMessage(
      lastCompletedStep:
          'phase B16, community Garden Club, '
          'workflow garden-event-rsvp, role member, '
          'screenshot B16_ext_garden_club_garden-event-rsvp_member_start',
      attemptedStep:
          'waiting for a tappable shipped workflow action for '
          'garden-event-rsvp instance event-rsvp-42 on the Calendar tab',
      waitingFor: 'a tappable event tile matching rsvp on the Calendar tab',
      budget: budget,
      diagnosticFrameName:
          'B16_ext_garden_club_garden-event-rsvp_member_STALL_DIAGNOSTIC',
    );

    expect(message, contains('Walkthrough stalled'));
    expect(message, contains('Last completed step:'));
    expect(message, contains('phase B16'));
    expect(message, contains('garden-event-rsvp'));
    expect(message, contains('Attempted step:'));
    expect(message, contains('Calendar tab'));
    expect(message, contains('Waiting for:'));
    expect(message, contains('tappable event tile matching rsvp'));
    expect(message, contains('Diagnostic frame:'));
    expect(
      message,
      contains('B16_ext_garden_club_garden-event-rsvp_member_STALL_DIAGNOSTIC'),
    );
    expect(message, contains('elapsed'));
    expect(message, contains('limit'));
  });

  testWidgets(
    'an unsatisfied engine-native wait fails with the finder it was polling',
    (WidgetTester tester) async {
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await tester.pump();

      final finder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'never appears',
        description: 'a tappable event tile on the Calendar tab',
      );

      // The fake clock advances one second per read so the budget expires
      // without needing a real three-minute wait (device-free regression).
      var observed = DateTime.utc(2026, 1, 1);
      DateTime fakeNow() {
        observed = observed.add(const Duration(seconds: 1));
        return observed;
      }

      await expectLater(
        () => waitForEngineNativeWidget(
          tester,
          finder,
          description: 'the event tile after tapping Calendar',
          timeout: const Duration(seconds: 2),
          lastCompletedStep:
              'phase B16, community Garden Club, '
              'workflow garden-event-rsvp, role member',
          now: fakeNow,
        ),
        throwsA(
          isA<WalkthroughStallFailure>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Walkthrough stalled'),
              contains('the event tile after tapping Calendar'),
              contains('a tappable event tile on the Calendar tab'),
              contains('phase B16'),
              contains('garden-event-rsvp'),
            ),
          ),
        ),
      );
    },
  );

  testWidgets('a walkthrough tap retries through a transient IgnorePointer', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _TemporarilyIgnoredWalkthroughTarget(
          onPressed: () => tapCount += 1,
        ),
      ),
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('temporarily-ignored-walkthrough-action')),
      description: 'temporarily ignored walkthrough action',
    );

    expect(tapCount, 1);
  });

  testWidgets(
    'a permanently missed walkthrough tap fails at the named target with its '
    'hit-test path and wait',
    (WidgetTester tester) async {
      const targetDescription = 'deliberately obscured walkthrough action';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: TextButton(
                    key: ValueKey('deliberately-obscured-walkthrough-action'),
                    onPressed: null,
                    child: Text('Target action'),
                  ),
                ),
                Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final start = DateTime.utc(2026, 1, 1);
      var nowCalls = 0;
      DateTime expireAfterFirstMiss() {
        nowCalls += 1;
        return nowCalls <= 2
            ? start
            : start.add(WalkthroughWaitBudget.defaultInnerWaitTimeout);
      }

      await expectLater(
        tapWhenVisible(
          tester,
          find.byKey(
            const ValueKey('deliberately-obscured-walkthrough-action'),
          ),
          description: targetDescription,
          now: expireAfterFirstMiss,
        ),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'error message',
            allOf(
              contains(targetDescription),
              contains('Walkthrough tap missed'),
              contains(
                'Waited ${formatWaitDuration(WalkthroughWaitBudget.defaultInnerWaitTimeout)}',
              ),
              contains('Hit-test path:'),
              isNot(contains('later widget not found')),
            ),
          ),
        ),
      );
    },
  );

  testWidgets(
    'a B25 row boundary accepts its expected entry gate without requiring a '
    'tappable picker',
    (WidgetTester tester) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final capturedDiagnostics = <String>[];
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installShippedEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);

      final expectedSurface = evidenceTargetRoute(target);
      final entryGate = find.descendant(
        of: expectedSurface,
        matching: find.byKey(const ValueKey('community-entry-gate')),
      );
      final picker = find.descendant(
        of: expectedSurface,
        matching: find.byKey(const ValueKey('actor-identity-picker-button')),
      );
      expect(entryGate, findsOneWidget);
      expect(isFinderReadyForTap(tester, picker), isFalse);

      final start = DateTime.utc(2026, 1, 1);
      var nowCalls = 0;
      DateTime expireAfterFirstReadinessCheck() {
        nowCalls += 1;
        return nowCalls == 1
            ? start
            : start.add(WalkthroughWaitBudget.defaultInnerWaitTimeout);
      }

      var readinessPolls = 0;
      await assertB25CommunityRowSurface(
        tester: tester,
        target: target,
        workflowId: 'garden-event-rsvp',
        role: 'member',
        boundary: 'before',
        captureDiagnostic: (name) async => capturedDiagnostics.add(name),
        now: expireAfterFirstReadinessCheck,
        onReadinessPoll: () => readinessPolls += 1,
      );

      expect(readinessPolls, 0);
      expect(capturedDiagnostics, isEmpty);
    },
  );

  testWidgets(
    'a B25 row boundary waits for its expected picker to become tappable',
    (WidgetTester tester) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final capturedDiagnostics = <String>[];
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installMetadataEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);

      final blocking = ValueNotifier(true);
      final blockingOverlay = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: blocking,
            builder: (context, absorbing, child) =>
                AbsorbPointer(absorbing: absorbing, child: child),
            child: const SizedBox.expand(),
          ),
        ),
      );
      Overlay.of(
        tester.element(evidenceTargetRoute(target)),
      ).insert(blockingOverlay);
      await tester.pump();
      var readinessPolls = 0;
      try {
        await assertB25CommunityRowSurface(
          tester: tester,
          target: target,
          workflowId: 'garden-event-rsvp',
          role: 'member',
          boundary: 'before',
          captureDiagnostic: (name) async => capturedDiagnostics.add(name),
          onReadinessPoll: () {
            readinessPolls += 1;
            if (readinessPolls == 2) blocking.value = false;
          },
        );

        expect(capturedDiagnostics, isEmpty);
        expect(readinessPolls, 2);
      } finally {
        blockingOverlay.remove();
        blocking.dispose();
      }
    },
  );

  testWidgets(
    'a B25 row boundary names its picker and wait when it never becomes '
    'interactable',
    (WidgetTester tester) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final capturedDiagnostics = <String>[];
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installMetadataEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);

      final blockingOverlay = OverlayEntry(
        builder: (context) => const Positioned.fill(
          child: AbsorbPointer(child: SizedBox.expand()),
        ),
      );
      Overlay.of(
        tester.element(evidenceTargetRoute(target)),
      ).insert(blockingOverlay);
      addTearDown(blockingOverlay.remove);

      final start = DateTime.utc(2026, 1, 1);
      var nowCalls = 0;
      DateTime expireAfterFirstReadinessCheck() {
        nowCalls += 1;
        return nowCalls == 1
            ? start
            : start.add(WalkthroughWaitBudget.defaultInnerWaitTimeout);
      }

      await expectLater(
        () => assertB25CommunityRowSurface(
          tester: tester,
          target: target,
          workflowId: 'garden-event-rsvp',
          role: 'member',
          boundary: 'before',
          captureDiagnostic: (name) async => capturedDiagnostics.add(name),
          now: expireAfterFirstReadinessCheck,
        ),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'picker readiness failure',
            allOf(
              contains(
                'B25 actor identity picker never became interactable before '
                'garden-event-rsvp/member',
              ),
              contains('picker actor-identity-picker-button'),
              contains(
                'Waited ${formatWaitDuration(WalkthroughWaitBudget.defaultInnerWaitTimeout)}',
              ),
              contains('Hit-test path:'),
              contains('RenderAbsorbPointer'),
              isNot(contains('B25 surface mismatch')),
            ),
          ),
        ),
      );
      expect(
        capturedDiagnostics,
        contains(
          '${target.phase}_${target.extensionId}_garden-event-rsvp_member_'
          'PICKER_NOT_INTERACTABLE_BEFORE',
        ),
      );
    },
  );

  testWidgets(
    'a B25 row boundary fails loudly when a blocking dialog covers its '
    'community surface',
    (WidgetTester tester) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final capturedDiagnostics = <String>[];
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installMetadataEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);
      await assertB25CommunityRowSurface(
        tester: tester,
        target: target,
        workflowId: 'garden-tool-loan',
        role: 'member',
        boundary: 'before',
        captureDiagnostic: (name) async => capturedDiagnostics.add(name),
      );

      unawaited(
        showDialog<void>(
          context: tester.element(evidenceTargetRoute(target)),
          builder: (context) => const AlertDialog(
            key: ValueKey('marketplace-detail-dialog-steel-wheelbarrow'),
            title: Text('Steel wheelbarrow'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        assertB25CommunityRowSurface(
          tester: tester,
          target: target,
          workflowId: 'garden-tool-loan',
          role: 'member',
          boundary: 'after',
          captureDiagnostic: (name) async => capturedDiagnostics.add(name),
        ),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'surface mismatch',
            allOf(
              contains('B25 surface mismatch after garden-tool-loan/member'),
              contains('expected community ext_garden_club'),
              contains('marketplace-detail-dialog-steel-wheelbarrow'),
            ),
          ),
        ),
      );
      expect(
        capturedDiagnostics,
        contains(
          '${target.phase}_${target.extensionId}_garden-tool-loan_member_'
          'SURFACE_MISMATCH_AFTER',
        ),
      );
      expect(
        find.byKey(
          const ValueKey('marketplace-detail-dialog-steel-wheelbarrow'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a legitimately unavailable action remains unavailable without tapping '
    'its listing instance',
    (WidgetTester tester) async {
      var listingTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: const ValueKey('expected-community-surface'),
              child: InkWell(
                key: const ValueKey(
                  'marketplace-listing-tap-steel-wheelbarrow',
                ),
                onTap: () => listingTapCount += 1,
                child: const Center(
                  child: FilledButton(
                    key: ValueKey(
                      'equipment-loan-action-borrow-steel-wheelbarrow',
                    ),
                    onPressed: null,
                    child: Text('Borrow'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final action = await firstReadyActionOnSurface(
        tester: tester,
        surface: find.byKey(const ValueKey('expected-community-surface')),
        candidates: [
          find.byKey(
            const ValueKey('equipment-loan-action-borrow-steel-wheelbarrow'),
          ),
        ],
      );
      final outcome = action == null
          ? 'primary_action_unavailable'
          : 'primary_action_fired';

      expect(outcome, 'primary_action_unavailable');
      expect(listingTapCount, 0);
    },
  );

  testWidgets('all present but disabled primary candidates become unavailable '
      'immediately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: ValueKey('expected-community-surface'),
            child: Center(
              child: FilledButton(
                key: ValueKey('respond-going-action'),
                onPressed: null,
                child: Text('Going'),
              ),
            ),
          ),
        ),
      ),
    );

    final availability = await waitForPrimaryActionAvailability(
      tester: tester,
      // The production caller uses its normal 2m45s inner budget. This
      // short test-only budget keeps the requested neutralization proof fast.
      timeout: const Duration(milliseconds: 10),
      candidates: [
        PrimaryActionCandidate(
          value: 'respond-going',
          finder: find.descendant(
            of: find.byKey(const ValueKey('expected-community-surface')),
            matching: find.byKey(const ValueKey('respond-going-action')),
          ),
          description: 'respond-going (Going)',
        ),
      ],
    );

    final outcome = availability.allCandidatesPresentAndDisabled
        ? 'primary_action_unavailable'
        : 'primary_action_stalled';
    expect(outcome, 'primary_action_unavailable');
    expect(availability.hasReadyAction, isFalse);
    expect(
      availability.candidateDescriptions,
      'respond-going (Going): present, disabled',
    );
    // This is deliberately far below the 2m45s device wait. A disabled
    // control is a product answer, not a reason to burn the polling budget.
    expect(availability.budget.elapsed, lessThan(const Duration(seconds: 1)));
  });

  testWidgets(
    'an enabled primary candidate covered for the full budget remains a '
    'stall diagnosis with its hit-test path',
    (WidgetTester tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: FilledButton(
                    key: const ValueKey('respond-going-action'),
                    onPressed: () => tapCount += 1,
                    child: const Text('Going'),
                  ),
                ),
                const Positioned.fill(
                  child: AbsorbPointer(child: SizedBox.expand()),
                ),
              ],
            ),
          ),
        ),
      );

      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        timeout: const Duration(milliseconds: 1),
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-going',
            finder: find.byKey(const ValueKey('respond-going-action')),
            description: 'respond-going (Going)',
          ),
        ],
      );

      expect(availability.hasReadyAction, isFalse);
      expect(availability.allCandidatesPresentAndDisabled, isFalse);
      expect(
        availability.candidateReadiness.single.readiness.state,
        FinderTapReadinessState.notHittable,
      );
      expect(
        availability.candidateDescriptions,
        allOf(
          contains('respond-going (Going): present, enabled, not hittable'),
          contains('RenderAbsorbPointer'),
        ),
      );
      final message = buildWalkthroughStallMessage(
        lastCompletedStep: 'start screenshot',
        attemptedStep: 'tapping respond-going',
        waitingFor:
            'a tappable shipped workflow action. Polled action widgets: '
            '[${availability.candidateDescriptions}].',
        budget: availability.budget,
      );
      expect(message, contains('present, enabled, not hittable'));
      expect(message, contains('RenderAbsorbPointer'));
      expect(tapCount, 0);
    },
  );

  testWidgets(
    'an enabled primary candidate covered mid-poll is tapped once it clears',
    (WidgetTester tester) async {
      var tapCount = 0;
      final blocked = ValueNotifier(true);
      addTearDown(blocked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: FilledButton(
                    key: const ValueKey('respond-going-action'),
                    onPressed: () => tapCount += 1,
                    child: const Text('Going'),
                  ),
                ),
                Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: blocked,
                    builder: (context, isBlocked, child) => isBlocked
                        ? const AbsorbPointer(child: SizedBox.expand())
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      var polls = 0;
      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-going',
            finder: find.byKey(const ValueKey('respond-going-action')),
            description: 'respond-going (Going)',
          ),
        ],
        onPoll: (_) {
          polls += 1;
          if (polls == 2) blocked.value = false;
        },
      );

      expect(polls, greaterThanOrEqualTo(2));
      expect(availability.hasReadyAction, isTrue);
      expect(
        availability.candidateReadiness.single.readiness.state,
        FinderTapReadinessState.ready,
      );
      await tester.tap(availability.candidate!.finder, warnIfMissed: false);
      expect(tapCount, 1);
    },
  );

  testWidgets(
    'a Calendar action is discovered only after its agenda entry is selected',
    (WidgetTester tester) async {
      var actionTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _SelectionRequiredCalendar(
              onAction: () => actionTapCount += 1,
            ),
          ),
        ),
      );

      const instanceId = 'spring-workshop';
      final surface = find.byKey(
        const ValueKey('calendar-selection-test-surface'),
      );
      final action = find.descendant(
        of: surface,
        matching: find.byKey(
          const ValueKey('event-rsvp-spring-workshop-action-respond-maybe'),
        ),
      );
      expect(action, findsNothing);

      final preparation = await prepareCalendarActionSurfaceForActionPolling(
        tester: tester,
        surface: surface,
        tabId: 'calendar',
        instanceId: instanceId,
      );
      expect(preparation.agendaEntryPresent, isTrue);
      expect(preparation.selectedDetailPresent, isTrue);
      expect(
        preparation.diagnosticDescription,
        allOf(
          contains('agenda entry present? yes'),
          contains('selected detail present? yes'),
        ),
      );

      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        timeout: const Duration(milliseconds: 10),
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-maybe',
            finder: action,
            description: 'respond-maybe (Maybe)',
          ),
        ],
      );
      expect(availability.hasReadyAction, isTrue);
      expect(
        availability.candidateReadiness.single.readiness.state,
        FinderTapReadinessState.ready,
      );
      await tester.tap(availability.candidate!.finder, warnIfMissed: false);
      expect(actionTapCount, 1);
    },
  );

  testWidgets(
    'a missing Calendar agenda entry is a finding without a blind instance tap',
    (WidgetTester tester) async {
      var blindInstanceTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: const ValueKey('calendar-selection-test-surface'),
              child: InkWell(
                key: const ValueKey('generic-instance-spring-workshop'),
                onTap: () => blindInstanceTapCount += 1,
                child: const Center(child: Text('Spring workshop')),
              ),
            ),
          ),
        ),
      );

      final preparation = await prepareCalendarActionSurfaceForActionPolling(
        tester: tester,
        surface: find.byKey(const ValueKey('calendar-selection-test-surface')),
        tabId: 'calendar',
        instanceId: 'spring-workshop',
      );

      expect(preparation.agendaEntryPresent, isFalse);
      expect(preparation.selectedDetailPresent, isFalse);
      expect(
        preparation.preparationFailureDescription,
        allOf(
          contains('calendar agenda entry is absent or ambiguous'),
          contains('no blind instance tap was attempted'),
          contains('agenda entry present? no'),
          contains('selected detail present? no'),
        ),
      );
      expect(
        classifyPreparedActionPolling(
          surfacePrepared: preparation.isReadyForActionPolling,
          actionLoadSucceeded: false,
          actionLoadFailed: false,
          allPrimaryCandidatesPresentAndDisabled: false,
          allActionCandidatesAbsent: true,
          anyOtherTappable: false,
        ),
        PreparedActionPollingDecision.stall,
      );
      expect(blindInstanceTapCount, 0);
    },
  );

  testWidgets('a prepared, loaded Marketplace detail with a guarded-off primary '
      'becomes unavailable immediately', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _MarketplaceDetailFixture(
            actionBelowFold: false,
            showAction: false,
          ),
        ),
      ),
    );

    const instanceId = 'terracotta-pots-giveaway';
    final surface = find.byKey(
      const ValueKey('marketplace-detail-test-surface'),
    );
    final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
      tester: tester,
      surface: surface,
      tabId: 'marketplace',
      instanceId: instanceId,
    );
    final primary = find.descendant(
      of: preparation.actionSurface,
      matching: marketplaceDetailActionFinder('claim-giveaway'),
    );

    expect(preparation.isReadyForActionPolling, isTrue);
    expect(
      inspectMarketplaceActionLoad(preparation: preparation).state,
      MarketplaceActionLoadState.succeeded,
    );
    expect(actionFindersAreAllAbsent([primary]), isTrue);

    final stopwatch = Stopwatch()..start();
    final availability = await waitForPrimaryActionAvailability(
      tester: tester,
      // The device walkthrough uses its normal 2m45s inner wait. This short
      // test-only bound makes a neutralized early-return branch fail quickly,
      // while the passing branch returns on its first poll.
      timeout: const Duration(milliseconds: 10),
      candidates: [
        PrimaryActionCandidate(
          value: 'claim-giveaway',
          finder: primary,
          description: 'claim-giveaway (Claim giveaway)',
        ),
      ],
      shouldStopWaiting: (availability) {
        final actionLoad = inspectMarketplaceActionLoad(
          preparation: preparation,
        );
        return classifyPreparedActionPolling(
              surfacePrepared: preparation.isReadyForActionPolling,
              actionLoadSucceeded: actionLoad.hasSucceeded,
              actionLoadFailed: actionLoad.hasFailed,
              allPrimaryCandidatesPresentAndDisabled:
                  availability.allCandidatesPresentAndDisabled,
              allActionCandidatesAbsent: actionFindersAreAllAbsent([primary]),
              anyOtherTappable: false,
            ) ==
            PreparedActionPollingDecision.unavailable;
      },
    );
    stopwatch.stop();
    final actionLoad = inspectMarketplaceActionLoad(preparation: preparation);
    final decision = classifyPreparedActionPolling(
      surfacePrepared: preparation.isReadyForActionPolling,
      actionLoadSucceeded: actionLoad.hasSucceeded,
      actionLoadFailed: actionLoad.hasFailed,
      allPrimaryCandidatesPresentAndDisabled:
          availability.allCandidatesPresentAndDisabled,
      allActionCandidatesAbsent: actionFindersAreAllAbsent([primary]),
      anyOtherTappable: false,
    );

    expect(availability.hasReadyAction, isFalse);
    expect(decision, PreparedActionPollingDecision.unavailable);
    expect(
      '${preparation.diagnosticDescription}; per-candidate readiness: '
      '[${availability.candidateDescriptions}]',
      allOf(
        contains('listing tap present? yes'),
        contains('detail dialog present? yes'),
        contains('claim-giveaway (Claim giveaway): absent'),
      ),
    );
    expect(
      describeOwnedGiveawayFormulaDenial(
        transitionId: 'claim-giveaway',
        instanceData: const {'ownerFanId': 'garden-member'},
        actorId: 'garden-member',
        guardFormula: 'if(ownerFanId == \$actor, false, true)',
      ),
      'claim-giveaway unavailable: the actor owns this giveaway '
      '(ownerFanId == \$actor), so the transition\'s guard formula denies it. '
      'Surface prepared, actions loaded.',
    );
    // The checked decision is load-bearing: a guard denial must not consume
    // the device walkthrough's 2m45s polling budget.
    expect(availability.budget.elapsed, lessThan(const Duration(seconds: 1)));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    await closeMarketplaceActionSurfaceAfterActionPolling(
      tester: tester,
      preparation: preparation,
      expectedSurface: surface,
    );
  });

  testWidgets(
    'a Marketplace listing without its detail dialog remains a stall',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MarketplaceDetailFixture(
              actionBelowFold: false,
              showDetailDialog: false,
            ),
          ),
        ),
      );

      final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
        tester: tester,
        surface: find.byKey(const ValueKey('marketplace-detail-test-surface')),
        tabId: 'marketplace',
        instanceId: 'terracotta-pots-giveaway',
      );
      final actionLoad = inspectMarketplaceActionLoad(preparation: preparation);

      expect(preparation.listingTapPresent, isTrue);
      expect(preparation.detailDialogPresent, isFalse);
      expect(
        preparation.preparationFailureDescription,
        allOf(
          contains('detail dialog'),
          contains('listing tap present? yes'),
          contains('detail dialog present? no'),
        ),
      );
      expect(
        classifyPreparedActionPolling(
          surfacePrepared: preparation.isReadyForActionPolling,
          actionLoadSucceeded: actionLoad.hasSucceeded,
          actionLoadFailed: actionLoad.hasFailed,
          allPrimaryCandidatesPresentAndDisabled: false,
          allActionCandidatesAbsent: true,
          anyOtherTappable: false,
        ),
        PreparedActionPollingDecision.stall,
      );
    },
  );

  testWidgets('a Marketplace action-load exception remains a named stall', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _MarketplaceDetailFixture(
            actionBelowFold: false,
            showAction: false,
            actionLoadError:
                'Could not load listing actions: StateError: controlled '
                'action load failure.',
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
      instanceId: 'terracotta-pots-giveaway',
    );
    final actionLoad = inspectMarketplaceActionLoad(preparation: preparation);

    expect(actionLoad.state, MarketplaceActionLoadState.failed);
    expect(
      actionLoad.diagnostic,
      contains('StateError: controlled action load failure'),
    );
    expect(
      classifyPreparedActionPolling(
        surfacePrepared: preparation.isReadyForActionPolling,
        actionLoadSucceeded: actionLoad.hasSucceeded,
        actionLoadFailed: actionLoad.hasFailed,
        allPrimaryCandidatesPresentAndDisabled: false,
        allActionCandidatesAbsent: true,
        anyOtherTappable: false,
      ),
      PreparedActionPollingDecision.stall,
    );
    await closeMarketplaceActionSurfaceAfterActionPolling(
      tester: tester,
      preparation: preparation,
      expectedSurface: surface,
    );
  });

  testWidgets(
    'Marketplace action polling owns its exact detail dialog through cleanup',
    (WidgetTester tester) async {
      var actionTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MarketplaceDetailFixture(
              actionBelowFold: false,
              onAction: () => actionTapCount += 1,
            ),
          ),
        ),
      );

      const instanceId = 'terracotta-pots-giveaway';
      final surface = find.byKey(
        const ValueKey('marketplace-detail-test-surface'),
      );
      final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
        tester: tester,
        surface: surface,
        tabId: 'marketplace',
        instanceId: instanceId,
      );
      expect(preparation.isMarketplaceSurface, isTrue);
      expect(
        preparation.actionSurface,
        findsOneWidget,
        reason: 'The exact opened detail dialog is the polling surface.',
      );

      final action = find.descendant(
        of: preparation.actionSurface,
        matching: marketplaceDetailActionFinder('claim-giveaway'),
      );
      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        timeout: const Duration(milliseconds: 10),
        candidates: [
          PrimaryActionCandidate(
            value: 'claim-giveaway',
            finder: action,
            description: 'claim-giveaway (Claim giveaway)',
          ),
        ],
      );
      expect(availability.hasReadyAction, isTrue);
      expect(actionTapCount, 0, reason: 'Preparation must not fire actions.');

      final closedWithOwnedControl =
          await closeMarketplaceActionSurfaceAfterActionPolling(
            tester: tester,
            preparation: preparation,
            expectedSurface: surface,
          );
      expect(closedWithOwnedControl, isTrue);
      expect(
        marketplaceDetailDialogFinder(instanceId),
        findsNothing,
        reason: 'The dialog opened for this row must not leak to the next one.',
      );
    },
  );

  testWidgets(
    'Marketplace detail polling does not count a matching tile action behind '
    'its modal barrier',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MarketplaceDetailFixture(
              actionBelowFold: false,
              tileAlsoHasAction: true,
            ),
          ),
        ),
      );

      const instanceId = 'terracotta-pots-giveaway';
      final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
        tester: tester,
        surface: find.byKey(const ValueKey('marketplace-detail-test-surface')),
        tabId: 'marketplace',
        instanceId: instanceId,
      );
      expect(
        find.byKey(const ValueKey('marketplace-action-claim-giveaway')),
        findsOneWidget,
        reason: 'The matching control exists only on the covered tile.',
      );

      final detailCandidates = await findReadyActionCandidatesOnSurface(
        tester: tester,
        surface: preparation.actionSurface,
        candidates: [
          PrimaryActionCandidate(
            value: 'claim-giveaway',
            finder: marketplaceDetailActionFinder('claim-giveaway'),
            description: 'claim-giveaway (Claim giveaway)',
          ),
        ],
      );
      expect(detailCandidates, isEmpty);
      await closeMarketplaceActionSurfaceAfterActionPolling(
        tester: tester,
        preparation: preparation,
        expectedSurface: find.byKey(
          const ValueKey('marketplace-detail-test-surface'),
        ),
      );
    },
  );

  testWidgets(
    'Marketplace primary polling prepares an action below the detail fold',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MarketplaceDetailFixture(actionBelowFold: true),
          ),
        ),
      );

      const instanceId = 'terracotta-pots-giveaway';
      final surface = find.byKey(
        const ValueKey('marketplace-detail-test-surface'),
      );
      final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
        tester: tester,
        surface: surface,
        tabId: 'marketplace',
        instanceId: instanceId,
      );
      final action = find.descendant(
        of: preparation.actionSurface,
        matching: marketplaceDetailActionFinder('claim-giveaway'),
      );
      expect(
        inspectFinderTapReadiness(tester, action).state,
        FinderTapReadinessState.notHittable,
      );

      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        timeout: const Duration(milliseconds: 10),
        candidates: [
          PrimaryActionCandidate(
            value: 'claim-giveaway',
            finder: action,
            description: 'claim-giveaway (Claim giveaway)',
          ),
        ],
      );
      expect(availability.hasReadyAction, isTrue);
      await closeMarketplaceActionSurfaceAfterActionPolling(
        tester: tester,
        preparation: preparation,
        expectedSurface: surface,
      );
    },
  );

  testWidgets(
    'Marketplace fallback polling prepares an action below the detail fold',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MarketplaceDetailFixture(actionBelowFold: true),
          ),
        ),
      );

      const instanceId = 'terracotta-pots-giveaway';
      final surface = find.byKey(
        const ValueKey('marketplace-detail-test-surface'),
      );
      final preparation = await prepareMarketplaceActionSurfaceForActionPolling(
        tester: tester,
        surface: surface,
        tabId: 'marketplace',
        instanceId: instanceId,
      );
      final action = find.descendant(
        of: preparation.actionSurface,
        matching: marketplaceDetailActionFinder('claim-giveaway'),
      );
      expect(
        inspectFinderTapReadiness(tester, action).state,
        FinderTapReadinessState.notHittable,
      );

      final fallbackCandidates = await findReadyActionCandidatesOnSurface(
        tester: tester,
        surface: preparation.actionSurface,
        candidates: [
          PrimaryActionCandidate(
            value: 'claim-giveaway',
            finder: marketplaceDetailActionFinder('claim-giveaway'),
            description: 'Claim giveaway',
          ),
        ],
      );
      expect(
        fallbackCandidates.map((candidate) => candidate.value),
        equals(const ['claim-giveaway']),
      );
      await closeMarketplaceActionSurfaceAfterActionPolling(
        tester: tester,
        preparation: preparation,
        expectedSurface: surface,
      );
    },
  );

  testWidgets(
    'an enabled off-viewport candidate becomes ready after every poll scrolls it',
    (WidgetTester tester) async {
      var actionTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 1800),
                  FilledButton(
                    key: const ValueKey('off-viewport-primary-action'),
                    onPressed: () => actionTapCount += 1,
                    child: const Text('Respond maybe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final action = find.byKey(const ValueKey('off-viewport-primary-action'));
      expect(
        inspectFinderTapReadiness(tester, action).state,
        FinderTapReadinessState.notHittable,
      );

      final availability = await waitForPrimaryActionAvailability(
        tester: tester,
        timeout: const Duration(milliseconds: 10),
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-maybe',
            finder: action,
            description: 'respond-maybe (Maybe)',
          ),
        ],
      );

      expect(availability.hasReadyAction, isTrue);
      expect(
        availability.candidateReadiness.single.readiness.state,
        FinderTapReadinessState.ready,
      );
      await tester.tap(availability.candidate!.finder, warnIfMissed: false);
      expect(actionTapCount, 1);
    },
  );

  testWidgets(
    'a primary-absent fallback prepares off-viewport actions and names them '
    'without claiming primary proof',
    (WidgetTester tester) async {
      var actionTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: const ValueKey('expected-community-surface'),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 1800),
                    FilledButton(
                      key: const ValueKey('fallback-join-waitlist-action'),
                      onPressed: () => actionTapCount += 1,
                      child: const Text('Join waitlist'),
                    ),
                    FilledButton(
                      key: const ValueKey('fallback-maybe-action'),
                      onPressed: () => actionTapCount += 1,
                      child: const Text('Maybe'),
                    ),
                    FilledButton(
                      key: const ValueKey('fallback-decline-action'),
                      onPressed: () => actionTapCount += 1,
                      child: const Text('Not attending'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final primary = find.byKey(
        const ValueKey('fallback-going-action-that-is-absent'),
      );
      expect(
        inspectFinderTapReadiness(tester, primary).state,
        FinderTapReadinessState.absent,
      );

      final preparedAlternatives = await findReadyActionCandidatesOnSurface(
        tester: tester,
        surface: find.byKey(const ValueKey('expected-community-surface')),
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-waitlist',
            finder: find.byKey(const ValueKey('fallback-join-waitlist-action')),
            description: 'Join waitlist',
          ),
          PrimaryActionCandidate(
            value: 'respond-maybe',
            finder: find.byKey(const ValueKey('fallback-maybe-action')),
            description: 'Maybe',
          ),
          PrimaryActionCandidate(
            value: 'respond-declined',
            finder: find.byKey(const ValueKey('fallback-decline-action')),
            description: 'Not attending',
          ),
        ],
      );

      expect(
        preparedAlternatives.map((candidate) => candidate.value),
        equals(const ['respond-waitlist', 'respond-maybe', 'respond-declined']),
      );
      final outcome = describePreparedFallbackAvailability(
        primaryUnavailableDescription:
            'Going unavailable: Spring Workshop is full, 2/2.',
        preparedActionDescriptions: preparedAlternatives.map(
          (candidate) => candidate.description,
        ),
        documentedPrimaryRequirementDescription:
            'documented primary attendance action',
      );
      expect(
        outcome,
        'Going unavailable: Spring Workshop is full, 2/2. Other available '
        'actions include Join waitlist, Maybe and Not attending. The '
        'documented primary attendance action was not exercised.',
      );
      expect(actionTapCount, 0, reason: 'Fallback preparation must not tap.');
    },
  );

  testWidgets(
    'a primary-absent fallback with no prepared action retains the stall path',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyedSubtree(
              key: ValueKey('expected-community-surface'),
              child: Center(child: Text('No actions are rendered')),
            ),
          ),
        ),
      );

      final preparedAlternatives = await findReadyActionCandidatesOnSurface(
        tester: tester,
        surface: find.byKey(const ValueKey('expected-community-surface')),
        candidates: [
          PrimaryActionCandidate(
            value: 'respond-waitlist',
            finder: find.byKey(
              const ValueKey('fallback-join-waitlist-action-that-is-absent'),
            ),
            description: 'Join waitlist',
          ),
        ],
      );
      final fallbackOutcome = describePreparedFallbackAvailability(
        primaryUnavailableDescription: 'Going unavailable.',
        preparedActionDescriptions: preparedAlternatives.map(
          (candidate) => candidate.description,
        ),
        documentedPrimaryRequirementDescription:
            'documented primary attendance action',
      );

      expect(preparedAlternatives, isEmpty);
      expect(fallbackOutcome, isNull);
      final outcome = fallbackOutcome == null
          ? 'walkthrough_stalled'
          : 'primary_action_unavailable';
      expect(
        outcome,
        'walkthrough_stalled',
        reason: 'No prepared action must not silently become unavailable.',
      );
    },
  );

  testWidgets(
    'no primary candidates preserves the unavailable outcome without a '
    'speculative listing tap',
    (WidgetTester tester) async {
      var listingTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              onTap: () => listingTapCount += 1,
              child: const Center(child: Text('Steel wheelbarrow')),
            ),
          ),
        ),
      );

      final primaryCandidates = <Finder>[];
      final action = primaryCandidates.isEmpty
          ? null
          : await firstReadyActionOnSurface(
              tester: tester,
              surface: find.byType(Scaffold),
              candidates: primaryCandidates,
            );
      final outcome = action == null
          ? 'primary_action_unavailable'
          : 'primary_action_fired';

      expect(outcome, 'primary_action_unavailable');
      expect(listingTapCount, 0);
    },
  );

  test(
    'an inner wait exhausts its default budget before the watchdog fires',
    () {
      fakeAsync((async) {
        final clock = async.getClock(DateTime.utc(2026, 1, 1));
        final watch = WalkthroughBodyWatch(
          timeout: WalkthroughWaitBudget.defaultTimeout,
          now: clock.now,
          lastCompletedStep: 'start screenshot captured',
          attemptedStep: 'waiting for the primary action to render',
          waitingFor: 'a tappable primary action',
        );
        var polls = 0;
        Duration? exhaustedBudget;

        Future<String> waitForPrimaryActionOutcome() async {
          // The body watchdog starts first, as it does after the start
          // screenshot. This setup gap is what exposed the old equal-deadline
          // race.
          await Future<void>.delayed(const Duration(seconds: 1));
          final budget = WalkthroughWaitBudget(now: clock.now);
          while (!budget.expired) {
            polls += 1;
            await Future<void>.delayed(const Duration(seconds: 1));
          }
          exhaustedBudget = budget.elapsed;
          return 'primary_action_unavailable';
        }

        final result = watchWalkthroughBodyWith<String>(
          waitForPrimaryActionOutcome(),
          watch,
        );
        String? outcome;
        Object? failure;
        result.then<void>(
          (value) => outcome = value,
          onError: (Object error, StackTrace _) => failure = error,
        );

        async.elapse(WalkthroughWaitBudget.defaultTimeout);

        // This also proves the result came after a real exhausted polling wait,
        // rather than a body that returned an unavailable outcome immediately.
        expect(polls, greaterThan(0));
        expect(exhaustedBudget, WalkthroughWaitBudget.defaultInnerWaitTimeout);
        expect(outcome, 'primary_action_unavailable');
        expect(failure, isNull);
      });
    },
  );

  test('whole-body bound fails a never-completing await before the first '
      'screenshot and names the setup phase plus what was awaited', () {
    fakeAsync((async) {
      final neverCompletes = Completer<void>();
      final watch = WalkthroughBodyWatch(
        timeout: const Duration(seconds: 5),
        lastCompletedStep: 'setup phase, no step completed yet',
        attemptedStep:
            'starting workflow garden-event-rsvp (phase B13, '
            'community Garden Club)',
        waitingFor:
            'the first screenshot for workflow garden-event-rsvp to be '
            'captured',
      );

      final result = watchWalkthroughBodyWith<void>(
        neverCompletes.future,
        watch,
      );

      Object? capturedError;
      result.catchError((Object error) {
        capturedError = error;
      });

      // The body never makes progress, so the watchdog must fire within its
      // bound and turn the silent await into a self-describing failure.
      async.elapse(const Duration(seconds: 5));

      expect(capturedError, isA<WalkthroughStallFailure>());
      final message = (capturedError as WalkthroughStallFailure).message;
      expect(message, contains('Walkthrough stalled'));
      expect(message, contains('setup phase, no step completed yet'));
      expect(message, contains('garden-event-rsvp'));
      expect(message, contains('phase B13'));
      expect(message, contains('Garden Club'));
      expect(
        message,
        contains('first screenshot for workflow garden-event-rsvp'),
      );
      expect(message, contains('elapsed'));
      expect(message, contains('limit'));
    });
  });

  test('whole-body watchdog reports the real stalled duration, not 0m 0s', () {
    fakeAsync((async) {
      // The injected clock and the injected timer advance together, so the
      // watchdog fires after a real `timeout` of quiet and the diagnostic must
      // report that same interval rather than a zeroed-out read.
      var current = DateTime.utc(2026, 1, 1);
      final watch = WalkthroughBodyWatch(
        timeout: const Duration(seconds: 5),
        now: () => current,
        lastCompletedStep: 'setup phase, no step completed yet',
        attemptedStep:
            'starting workflow garden-event-rsvp (phase B13, '
            'community Garden Club)',
        waitingFor:
            'the first screenshot for workflow garden-event-rsvp to be '
            'captured',
      );

      final neverCompletes = Completer<void>();
      final result = watchWalkthroughBodyWith<void>(
        neverCompletes.future,
        watch,
      );

      Object? capturedError;
      result.catchError((Object error) {
        capturedError = error;
      });

      // Move both the clock and the fake timer past the full quiet interval.
      current = current.add(const Duration(seconds: 5));
      async.elapse(const Duration(seconds: 5));

      expect(capturedError, isA<WalkthroughStallFailure>());
      final message = (capturedError as WalkthroughStallFailure).message;
      expect(message, contains('0m 5s elapsed'));
      expect(message, contains('limit 0m 5s'));
      expect(message, isNot(contains('0m 0s')));
    });
  });

  group('walkthrough sub-step beats', () {
    // Identifiers fixed across these cases so every assertion is concrete:
    // the watchdog must name the account, role, tab, workflow, phase and
    // community a reader would need to reproduce the stall.
    const workflow = 'garden-event-rsvp';
    const phase = 'B13';
    const community = 'Garden Club';
    const account = 'Shipped member';
    const role = 'member';
    const tabId = 'calendar';

    WalkthroughSubstepProgress progressFor(WalkthroughSubstep substep) {
      return buildWalkthroughSubstepProgress(
        substep,
        account: account,
        role: role,
        tabId: tabId,
        workflow: workflow,
        phase: phase,
        community: community,
      );
    }

    Matcher namesSubstepAndIdentifiers(WalkthroughSubstep substep) {
      final progress = progressFor(substep);
      final identifierMatchers = <Matcher>[
        contains(workflow),
        contains(phase),
        contains(community),
        ...switch (substep) {
          WalkthroughSubstep.seedingEvidenceAccounts => [contains(account)],
          WalkthroughSubstep.signingInEvidenceAccount => [contains(account)],
          WalkthroughSubstep.selectingActorIdentity => [contains(role)],
          WalkthroughSubstep.verifyingExperienceTagline => const <Matcher>[],
          WalkthroughSubstep.selectingCommunityTab => [contains(tabId)],
          WalkthroughSubstep.waitingForEngineNativeWidget => [contains(tabId)],
        },
      ];
      return allOf(<Matcher>[
        // The diagnostic's 'Waiting for:' must name the precise sub-step.
        contains(progress.waitingFor),
        // And its 'Attempted step:' must name the action being taken.
        contains(progress.attemptedStep),
        ...identifierMatchers,
      ]);
    }

    for (final substep in WalkthroughSubstep.values) {
      test(
        'a stall at ${substep.name} names that sub-step and its identifiers',
        () {
          fakeAsync((async) {
            final progress = progressFor(substep);
            final watch = WalkthroughBodyWatch(
              timeout: const Duration(seconds: 5),
              lastCompletedStep: 'setup phase, no step completed yet',
              attemptedStep: progress.attemptedStep,
              waitingFor: progress.waitingFor,
            );

            final neverCompletes = Completer<void>();
            final result = watchWalkthroughBodyWith<void>(
              neverCompletes.future,
              watch,
            );

            Object? capturedError;
            result.catchError((Object error) {
              capturedError = error;
            });

            async.elapse(const Duration(seconds: 5));

            expect(capturedError, isA<WalkthroughStallFailure>());
            final message = (capturedError as WalkthroughStallFailure).message;
            expect(message, contains('Walkthrough stalled'));
            expect(message, namesSubstepAndIdentifiers(substep));
          });
        },
      );
    }
  });
}

class _TemporarilyIgnoredWalkthroughTarget extends StatefulWidget {
  const _TemporarilyIgnoredWalkthroughTarget({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_TemporarilyIgnoredWalkthroughTarget> createState() =>
      _TemporarilyIgnoredWalkthroughTargetState();
}

class _TemporarilyIgnoredWalkthroughTargetState
    extends State<_TemporarilyIgnoredWalkthroughTarget> {
  Timer? _clearIgnorePointer;
  var _ignoring = true;

  @override
  void initState() {
    super.initState();
    _clearIgnorePointer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _ignoring = false);
      }
    });
  }

  @override
  void dispose() {
    _clearIgnorePointer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IgnorePointer(
          ignoring: _ignoring,
          child: TextButton(
            key: const ValueKey('temporarily-ignored-walkthrough-action'),
            onPressed: widget.onPressed,
            child: const Text('Target action'),
          ),
        ),
      ),
    );
  }
}

class _SelectionRequiredCalendar extends StatefulWidget {
  const _SelectionRequiredCalendar({required this.onAction});

  final VoidCallback onAction;

  @override
  State<_SelectionRequiredCalendar> createState() =>
      _SelectionRequiredCalendarState();
}

class _SelectionRequiredCalendarState
    extends State<_SelectionRequiredCalendar> {
  var _selected = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: KeyedSubtree(
        key: const ValueKey('calendar-selection-test-surface'),
        child: Column(
          children: [
            ListTile(
              key: const ValueKey(
                'engine-native-calendar-agenda-spring-workshop-7',
              ),
              title: const Text('Spring workshop'),
              onTap: () => setState(() => _selected = true),
            ),
            if (_selected)
              KeyedSubtree(
                key: const ValueKey(
                  'engine-native-calendar-selected-detail-spring-workshop-7',
                ),
                child: const SizedBox(
                  height: 80,
                  child: Center(child: Text('Spring workshop details')),
                ),
              ),
            if (_selected)
              FilledButton(
                key: const ValueKey(
                  'event-rsvp-spring-workshop-action-respond-maybe',
                ),
                onPressed: widget.onAction,
                child: const Text('Maybe'),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceDetailFixture extends StatefulWidget {
  const _MarketplaceDetailFixture({
    required this.actionBelowFold,
    this.tileAlsoHasAction = false,
    this.showDetailDialog = true,
    this.showAction = true,
    this.actionLoadError,
    this.onAction,
  });

  final bool actionBelowFold;
  final bool tileAlsoHasAction;
  final bool showDetailDialog;
  final bool showAction;
  final String? actionLoadError;
  final VoidCallback? onAction;

  @override
  State<_MarketplaceDetailFixture> createState() =>
      _MarketplaceDetailFixtureState();
}

class _MarketplaceDetailFixtureState extends State<_MarketplaceDetailFixture> {
  static const _instanceId = 'terracotta-pots-giveaway';

  static void _noop() {}

  void _showDetail() {
    if (!widget.showDetailDialog) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const ValueKey('marketplace-detail-dialog-$_instanceId'),
        child: SizedBox(
          height: 280,
          width: 320,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Terracotta pots'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.actionBelowFold) const SizedBox(height: 1800),
                      if (widget.actionLoadError != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(widget.actionLoadError!),
                        ),
                      if (widget.showAction && !widget.tileAlsoHasAction)
                        FilledButton(
                          key: const ValueKey(
                            'marketplace-action-claim-giveaway',
                          ),
                          onPressed: widget.onAction ?? _noop,
                          child: const Text('Claim giveaway'),
                        ),
                    ],
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('marketplace-detail-close-$_instanceId'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('marketplace-detail-test-surface'),
      child: Column(
        children: [
          InkWell(
            key: const ValueKey('marketplace-listing-tap-$_instanceId'),
            onTap: _showDetail,
            child: const SizedBox(
              height: 80,
              child: Center(child: Text('Terracotta pots listing')),
            ),
          ),
          if (widget.tileAlsoHasAction)
            FilledButton(
              key: const ValueKey('marketplace-action-claim-giveaway'),
              onPressed: widget.onAction ?? _noop,
              child: const Text('Claim giveaway on covered tile'),
            ),
        ],
      ),
    );
  }
}
