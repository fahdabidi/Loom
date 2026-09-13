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

      final action = firstReadyActionOnSurface(
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
