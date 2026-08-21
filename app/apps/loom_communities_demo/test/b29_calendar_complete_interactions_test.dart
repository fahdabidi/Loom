import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';
const _communityId = 'community_verify_tabletop_club';
const _gameNightId = 'tabletop-game-night-rsvp';
const _tournamentId = 'tabletop-tournament-rsvp';

void main() {
  group('B29 complete Calendar tab (Phase 2)', () {
    testWidgets('wf_calendar-agenda-is-date-grouped', (tester) async {
      final fixture = _writeTabletopClubPackagePair(
        'same-date',
        sameDateEvents: true,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _tournamentId);

      final dateGroup = find.byKey(
        const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
      );
      expect(dateGroup, findsOneWidget);
      expect(
        find.descendant(of: dateGroup, matching: _agendaEntry(_gameNightId)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dateGroup, matching: _agendaEntry(_tournamentId)),
        findsOneWidget,
      );

      await _openEvent(tester, _tournamentId);
      expect(_eventCard(_tournamentId), findsOneWidget);
    });

    testWidgets('wf_calendar-agenda-has-two-dated-events-and-is-tappable', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair('two-dates');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      expect(_agendaEntry(_gameNightId), findsOneWidget);
      expect(_agendaEntry(_tournamentId), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-11'),
        ),
        findsOneWidget,
      );
      expect(_eventCard(_gameNightId), findsOneWidget);

      await _openEvent(tester, _tournamentId);
      expect(_eventCard(_tournamentId), findsOneWidget);
      expect(find.text('20 / 20 going'), findsOneWidget);
    });

    testWidgets('wf_calendar-reminder-action-is-engine-backed', (tester) async {
      final fixture = _writeTabletopClubPackagePair('reminder');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final reminder = _eventAction(_gameNightId, 'set-reminder');
      expect(reminder, findsOneWidget);
      await scrollFinderIntoViewport(tester, reminder);
      await tester.tap(reminder);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('generic-transition-input-dialog')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-offsetHours')),
        '24',
      );
      await tester.tap(
        find.byKey(const ValueKey('generic-transition-input-confirm')),
      );
      await tester.pumpAndSettle();

      // Re-selecting the event proves the effect was persisted on this
      // member's response instance instead of held in detail-widget state.
      await _openEvent(tester, _tournamentId);
      await _openEvent(tester, _gameNightId);
      expect(_eventCard(_gameNightId), findsOneWidget);
      expect(reminder, findsNothing);
    });

    testWidgets('wf_full-event-offers-waitlist-and-response-can-be-changed', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair('waitlist');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);
      await _openEvent(tester, _tournamentId);

      final eventCard = _eventCard(_tournamentId);
      final going = _eventAction(_tournamentId, 'respond-going');
      final waitlist = _eventAction(_tournamentId, 'respond-waitlist');
      expect(eventCard, findsOneWidget);
      expect(find.text('20 / 20 going'), findsOneWidget);
      expect(waitlist, findsOneWidget);
      expect(
        going,
        findsNothing,
        reason: 'a full event must not expose the capacity-gated Going action',
      );

      await scrollFinderIntoViewport(tester, waitlist);
      await tester.tap(waitlist);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('event-rsvp-waitlist-$_tournamentId')),
        findsOneWidget,
      );
      expect(going, findsNothing);

      final maybe = _eventAction(_tournamentId, 'respond-maybe');
      expect(maybe, findsOneWidget);
      await scrollFinderIntoViewport(tester, maybe);
      await tester.tap(maybe);
      await tester.pumpAndSettle();

      final selectedMaybe = tester.widget<InputChip>(
        find.descendant(of: maybe, matching: find.byType(InputChip)),
      );
      expect(selectedMaybe.selected, isTrue);
      expect(eventCard, findsOneWidget);
      expect(
        find.byKey(ValueKey('event-rsvp-waitlist-$_tournamentId')),
        findsNothing,
      );
    });
  });
}

Finder _agendaEntry(String instanceId) =>
    find.byKey(ValueKey('engine-native-calendar-agenda-$instanceId-0'));

Finder _eventCard(String instanceId) =>
    find.byKey(ValueKey('event-rsvp-card-$instanceId'));

Finder _eventAction(String instanceId, String transitionId) =>
    find.byKey(ValueKey('event-rsvp-$instanceId-action-$transitionId'));

Future<void> _openEvent(WidgetTester tester, String instanceId) async {
  final entry = _agendaEntry(instanceId);
  await scrollFinderIntoViewport(tester, entry);
  await tester.tap(entry, warnIfMissed: false);
  await tester.pumpAndSettle();
  await _waitForEvent(tester, instanceId);
}

Future<void> _waitForEvent(WidgetTester tester, String instanceId) =>
    waitForEngineNativeWidget(
      tester,
      _eventCard(instanceId),
      description: 'engine-native Calendar event $instanceId',
    );

Future<void> _installAndOpen(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId}) fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.package.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.package.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('community-card-${fixture.communityId}')),
  );
  await tester.pumpAndSettle();
  await selectPersona(tester, 'tabletop-member');
}

({EvidencePackagePair package, String communityId})
_writeTabletopClubPackagePair(String suffix, {bool sameDateEvents = false}) {
  final extensionId = '${_extensionId}_$suffix';
  final communityId = '${_communityId}_$suffix';
  final gameNight = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-event-rsvp',
    responseWorkflowType: 'tabletop-event-rsvp-response',
    eventInstanceId: _gameNightId,
    title: 'Friday game night',
    eventDate: '2026-07-10',
    eventTime: '19:00',
    location: 'Community room',
    host: 'Mara, organizer',
    organizerRoleId: 'tabletop-organizer',
    memberRoleId: 'tabletop-member',
    capacity: 20,
    includeWaitlist: true,
    includeReminderAction: true,
    responseSeeds: _goingResponseSeeds(eventId: _gameNightId, count: 12),
  );
  final tournament = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-event-rsvp',
    responseWorkflowType: 'tabletop-event-rsvp-response',
    eventInstanceId: _tournamentId,
    title: 'Saturday tournament',
    eventDate: sameDateEvents ? '2026-07-10' : '2026-07-11',
    eventTime: '13:00',
    location: 'Community hall',
    host: 'Mara, organizer',
    organizerRoleId: 'tabletop-organizer',
    memberRoleId: 'tabletop-member',
    capacity: 20,
    includeWaitlist: true,
    includeReminderAction: true,
    responseSeeds: _goingResponseSeeds(eventId: _tournamentId, count: 20),
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b29_tabletop_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, tournaments, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': _tabletopRoles,
      'workflowDefinitions': gameNight.workflowDefinitions,
      'workflowInstances': <Object?>[
        ...gameNight.workflowInstances,
        ...tournament.workflowInstances,
      ],
    },
    appShell: _calendarAppShell,
  );
  return (package: package, communityId: communityId);
}

List<EngineNativeEventRsvpResponseSeed> _goingResponseSeeds({
  required String eventId,
  required int count,
}) => <EngineNativeEventRsvpResponseSeed>[
  for (var index = 1; index <= count; index++)
    EngineNativeEventRsvpResponseSeed(
      instanceId: '$eventId-response-$index',
      fanId: '$eventId-attendee-$index',
      currentState: 'going',
    ),
];

const _tabletopRoles = <Object?>[
  <String, Object?>{
    'roleId': 'tabletop-organizer',
    'label': 'Organizer',
    'roleLabel': 'Organizer',
    'description': 'Plans game nights and tournaments.',
  },
  <String, Object?>{
    'roleId': 'tabletop-member',
    'label': 'Member',
    'roleLabel': 'Member',
    'description': 'RSVPs to game nights and tournaments.',
  },
];

const _calendarAppShell = <String, Object?>{
  'tabs': <Object?>[
    <String, Object?>{
      'tabId': 'calendar',
      'label': 'Calendar',
      'iconKey': 'calendar_today',
    },
  ],
};
