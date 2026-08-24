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

  test('whole-body watchdog reports the real stalled duration, not 0m 0s',
      () {
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
}
