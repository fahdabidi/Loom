import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B29 complete Calendar tab (Phase 2)', () {
    testWidgets('wf_calendar-agenda-is-date-grouped', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      // Two events share 2026-07-10 → one date-group header
      expect(
        find.byKey(const ValueKey('calendar-agenda-date-group-2026-07-10')),
        findsOneWidget,
      );
      // Both cards exist under the same group
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-game-night-rsvp'),
        ),
        findsOneWidget,
      );
      // Tapping second card switches focus to it
      final secondCard = find.byKey(
        const ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'),
      );
      await scrollFinderIntoViewport(tester, secondCard);
      await tester.tap(secondCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-tournament-rsvp'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('wf_calendar-agenda-has-two-dated-events-and-is-tappable', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      expect(
        find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-game-night-rsvp'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'),
        ),
        findsOneWidget,
      );

      // The first (earliest) event's detail is shown by default.
      expect(
        find.byKey(
          const ValueKey(
            'calendar-event-detail-tabletop-game-night-rsvp',
          ),
        ),
        findsOneWidget,
      );

      // Tapping the second date chip switches the event detail shown.
      final secondDateChip = find.byKey(
        const ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'),
      );
      await scrollFinderIntoViewport(tester, secondDateChip);
      await tester.tap(secondDateChip);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(
            'calendar-event-detail-tabletop-tournament-rsvp',
          ),
        ),
        findsOneWidget,
      );
      // Appears twice by design: the capacity fact pill states it as a
      // compact tag, and the workflow tile's body restates it in the full
      // entryText sentence below.
      expect(find.textContaining('20 of 20 seats filled'), findsNWidgets(2));
    });

    testWidgets('wf_calendar-reminder-toggle-is-real', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      final toggle = find.byKey(
        const ValueKey(
          'calendar-reminder-toggle-tabletop-game-night-rsvp',
        ),
      );
      expect(toggle, findsOneWidget);
      expect(find.text('Reminder set'), findsNothing);

      await scrollFinderIntoViewport(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('Reminder set'), findsOneWidget);

      await scrollFinderIntoViewport(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('Reminder set'), findsNothing);
    });

    testWidgets(
      'wf_full-event-offers-waitlist-and-response-can-be-changed',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await selectPersona(tester, 'tabletop-member');

        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-tournament-rsvp',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final workflowButton = find.byKey(
          ValueKey('workflow-button-${workflow.workflowId}'),
        );
        await scrollFinderIntoViewport(tester, workflowButton);
        await tester.tap(workflowButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('workflow-response-going')),
          findsOneWidget,
        );
        final waitlistButton = find.byKey(
          const ValueKey('workflow-response-waitlist'),
        );
        expect(waitlistButton, findsOneWidget);

        await scrollFinderIntoViewport(tester, waitlistButton);
        await tester.tap(waitlistButton);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('community-tab-home')));
        await tester.pumpAndSettle();
        await scrollToWorkflowCard(tester, workflow);
        expect(find.textContaining('You responded: Join waitlist'), findsOneWidget);

        // Change the response: re-open via the "Change response" button.
        final changeButton = find.byKey(
          const ValueKey('workflow-change-response'),
        );
        await scrollFinderIntoViewport(tester, changeButton);
        await tester.tap(changeButton);
        await tester.pumpAndSettle();

        final goingButton = find.byKey(
          const ValueKey('workflow-response-going'),
        );
        expect(goingButton, findsOneWidget);
        await scrollFinderIntoViewport(tester, goingButton);
        await tester.tap(goingButton);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('community-tab-home')));
        await tester.pumpAndSettle();
        await scrollToWorkflowCard(tester, workflow);
        expect(find.textContaining('You responded: Going'), findsOneWidget);
      },
    );
  });
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openCalendarTab(WidgetTester tester) async {
  final tabFinder = find.byKey(const ValueKey('community-tab-calendar'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

_PackagePairFixture _writeTabletopClubPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b29_tabletop_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline':
            'Board game nights, tournaments, and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'roles': [
          {
            'roleId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description': 'Plans game nights and tournaments.',
          },
          {
            'roleId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights and tournaments.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'tabletop-game-night-rsvp',
            'title': 'RSVP to Friday game night',
            'entryText':
                'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
            'actionText': "Reserve a seat at Friday's game night.",
            'resultText': "You're on the roster for Friday's game night.",
            'calendar': {
              'date': '2026-07-10',
              'time': '19:00',
              'location': 'Community room',
              'capacityLabel': '12 of 20 seats filled',
            },
            'responseChoices': [
              {'responseId': 'going', 'label': 'Going'},
              {'responseId': 'maybe', 'label': 'Maybe'},
              {
                'responseId': 'not-going',
                'label': "Can't go",
                'isDestructive': true,
              },
            ],
          },
          {
            'workflowId': 'tabletop-tournament-rsvp',
            'title': 'Sign up for the Saturday tournament',
            'entryText':
                'Saturday board game tournament at the community hall, 1-5pm. 20 of 20 seats filled.',
            'actionText': 'Sign up for the Saturday tournament.',
            'resultText': "You're signed up for the Saturday tournament.",
            'calendar': {
              'date': '2026-07-11',
              'time': '13:00',
              'location': 'Community hall',
              'capacityLabel': '20 of 20 seats filled',
            },
            'responseChoices': [
              {'responseId': 'going', 'label': 'Going'},
              {'responseId': 'waitlist', 'label': 'Join waitlist'},
            ],
          },
        ],
        'personaPolicies': {
          'tabletop-game-night-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText': "A member RSVP'd to Friday's game night.",
            'receiverActionText': 'Acknowledge RSVP',
            'receiverResultText':
                'RSVP acknowledged and added to the roster.',
          },
          'tabletop-tournament-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText':
                'A member signed up for the Saturday tournament.',
            'receiverActionText': 'Acknowledge signup',
            'receiverResultText': 'Signup acknowledged.',
          },
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
