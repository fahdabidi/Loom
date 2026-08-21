import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_calendar_engine';

File _repositoryFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$relativePath');
    if (file.existsSync()) return file;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Fixture not found: $relativePath');
}

void main() {
  group('M2.3 Calendar engine RSVP path', () {
    testWidgets('date strip dedupes same-date events and navigates agenda', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      expect(find.byKey(const ValueKey('calendar-agenda-date-strip')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey('calendar-agenda-date-group-2026-07-10')),
        findsOneWidget,
      );
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
        findsNothing,
        reason: 'date strip is deduped to one chip for 2026-07-10',
      );

      await _openEventDetail(tester, 'Saturday tournament');
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-tournament-rsvp'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('agenda list renders both events and detail opens in place', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(sameDateEvents: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      expect(find.text('Friday game night'), findsWidgets);
      expect(find.text('Saturday tournament'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-game-night-rsvp'),
        ),
        findsOneWidget,
      );

      await _openEventDetail(tester, 'Saturday tournament');
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-tournament-rsvp'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('RSVP going is handled by calendar engine action row', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(sameDateEvents: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _openCalendarTab(tester);

      await _tapCalendarAction(tester, 'going');
      expect(find.text('Your RSVP: Going'), findsOneWidget);

      await _openEventDetail(tester, 'Saturday tournament');
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-tournament-rsvp'),
        ),
        findsOneWidget,
      );

      await _openEventDetail(tester, 'Friday game night');
      expect(
        find.byKey(
          const ValueKey('calendar-event-detail-tabletop-game-night-rsvp'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Your RSVP: Going'),
        findsOneWidget,
        reason: 'RSVP state must persist in the engine-backed instance, not only local detail state.',
      );
    });

    testWidgets('RSVP maybe is handled by calendar engine action row', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _openCalendarTab(tester);

      await _tapCalendarAction(tester, 'maybe');
      expect(find.text('Your RSVP: Maybe'), findsOneWidget);
    });

    testWidgets('RSVP not-going is handled by calendar engine action row', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _openCalendarTab(tester);

      await _tapCalendarAction(tester, 'not-going');
      expect(find.text("Your RSVP: Can't go"), findsOneWidget);
    });

    testWidgets('capacity and waitlist display update from response model', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(onlyTournament: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _openCalendarTab(tester);
      await _openEventDetail(tester, 'Saturday tournament');

      expect(find.text('20 of 20 seats filled'), findsOneWidget);
      await _tapCalendarAction(tester, 'waitlist');
      expect(find.text('Waitlist: 1'), findsOneWidget);
      expect(find.text('Your RSVP: Join waitlist'), findsOneWidget);
    });

    testWidgets('event detail uses distinct schema-driven fact icons', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await _openCalendarTab(tester);

      expect(find.byIcon(Icons.schedule), findsWidgets);
      expect(find.byIcon(Icons.person_outline), findsWidgets);
      expect(find.byIcon(Icons.location_on_outlined), findsWidgets);
      expect(find.byIcon(Icons.groups_outlined), findsWidgets);
      expect(
        find.byIcon(Icons.check_circle_outline),
        findsNothing,
        reason: 'Calendar fact pills must not use a shared generic checkmark',
      );
    });

    testWidgets('calendar fixture declares RSVP response model fields', (
      tester,
    ) async {
      final fixture = _repositoryFile(
        'docs/Build Plan V2/Loom Communities Workflow Engine V2/'
        'Loom_Communities_Workflow_Engine_Calendar_RSVP_Example.jsonc',
      );
      expect(fixture.existsSync(), isTrue);
      final text = fixture.readAsStringSync();
      expect(text, contains('"responseModel"'));
      expect(text, contains('"kind": "simpleRsvp"'));
      expect(text, contains('"responseMapField": "rsvpByPersona"'));
      expect(text, contains('"goingListField": "goingPersonaIds"'));
      expect(text, contains('"waitlistField": "waitlistedPersonaIds"'));
    });
  });
}

Future<void> _tapCalendarAction(WidgetTester tester, String transitionId) async {
  var button = find.byKey(ValueKey('calendar-action-$transitionId'));
  if (button.evaluate().isEmpty && transitionId == 'waitlist') {
    button = find.text('Join waitlist');
  }
  await scrollFinderIntoViewport(tester, button);
  expect(button, findsOneWidget);
  await tester.tap(button, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _openEventDetail(WidgetTester tester, String title) async {
  final dateChip = title.contains('Saturday')
      ? find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'),
        )
      : find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-game-night-rsvp'),
        );
  if (dateChip.evaluate().isNotEmpty) {
    await scrollFinderIntoViewport(tester, dateChip);
    await tester.tap(dateChip, warnIfMissed: false);
    await tester.pumpAndSettle();
    return;
  }
  final keyedCard = title.contains('Saturday')
      ? find.byKey(
          const ValueKey('calendar-event-card-tabletop-tournament-rsvp'),
        )
      : find.byKey(
          const ValueKey('calendar-event-card-tabletop-game-night-rsvp'),
        );
  if (keyedCard.evaluate().isNotEmpty) {
    await scrollFinderIntoViewport(tester, keyedCard);
    await tester.tap(keyedCard, warnIfMissed: false);
    await tester.pumpAndSettle();
    return;
  }
  final titleFinder = find.text(title).last;
  await scrollFinderIntoViewport(tester, titleFinder);
  await tester.tap(titleFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
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
      const ValueKey('community-card-community_verify_tabletop_calendar_engine'),
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
  expect(tabFinder, findsOneWidget);
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeTabletopCalendarFixture({
  bool sameDateEvents = true,
  bool onlyTournament = false,
}) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b36_calendar_');
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
      'communityId': 'community_verify_tabletop_calendar_engine',
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
          if (!onlyTournament)
            {
              'workflowId': 'tabletop-game-night-rsvp',
              'title': 'Friday game night',
              'entryText':
                  'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
              'actionText': "Reserve a seat at Friday's game night.",
              'resultText': "You're on the roster for Friday's game night.",
              'calendar': {
                'date': '2026-07-10',
                'time': '19:00',
                'location': 'Community room',
                'host': 'Mara, organizer',
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
            'title': 'Saturday tournament',
            'entryText':
                'Saturday tournament at the community room, 8-11pm. 20 of 20 seats filled.',
            'actionText': 'Join the tournament waitlist.',
            'resultText': "You're on the tournament waitlist.",
            'calendar': {
              'date': sameDateEvents ? '2026-07-10' : '2026-07-11',
              'time': '20:00',
              'location': 'Community room',
              'host': 'Mara, organizer',
              'capacityLabel': '20 of 20 seats filled',
            },
            'responseChoices': [
              {'responseId': 'going', 'label': 'Going'},
              {'responseId': 'waitlist', 'label': 'Join waitlist'},
            ],
          },
        ],
        'personaPolicies': {
          if (!onlyTournament)
            'tabletop-game-night-rsvp': {
              'actorPersonaIds': ['tabletop-member'],
              'receiverPersonaIds': ['tabletop-organizer'],
              'receiverEntryText': "A member RSVP'd to Friday's game night.",
              'receiverActionText': 'Acknowledge RSVP',
              'receiverResultText': 'RSVP acknowledged.',
            },
          'tabletop-tournament-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText':
                'A member joined the Saturday tournament waitlist.',
            'receiverActionText': 'Acknowledge waitlist',
            'receiverResultText': 'Waitlist acknowledged.',
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

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}
