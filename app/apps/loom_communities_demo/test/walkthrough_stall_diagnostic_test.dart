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
}
