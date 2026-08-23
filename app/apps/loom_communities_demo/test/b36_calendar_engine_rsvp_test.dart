import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_calendar_engine';
const _communityId = 'community_verify_tabletop_calendar_engine';
const _gameNightId = 'tabletop-game-night-rsvp';
const _tournamentId = 'tabletop-tournament-rsvp';
void main() {
  group('M2.3 Calendar engine RSVP path', () {
    testWidgets('date rail groups same-date events and navigates agenda', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture('same-date');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final dateGroup = find.byKey(
        const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
      );
      expect(dateGroup, findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
        ),
        findsOneWidget,
      );
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

    testWidgets('agenda list renders both events and detail opens in place', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(
        'two-dates',
        sameDateEvents: false,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      expect(find.text('Friday game night'), findsWidgets);
      expect(find.text('Saturday tournament'), findsWidgets);
      expect(_eventCard(_gameNightId), findsOneWidget);

      await _openEvent(tester, _tournamentId);
      expect(_eventCard(_tournamentId), findsOneWidget);
    });

    testWidgets('RSVP choices persist independently for two members', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(
        'independent',
        sameDateEvents: false,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await seedEvidenceAccounts(tester, fixture.target, const <LoomAccount>[
        LoomAccount(
          accountId: 'tabletop-member-alex',
          displayName: 'Alex Member',
          roleId: 'tabletop-member',
        ),
        LoomAccount(
          accountId: 'tabletop-member-blair',
          displayName: 'Blair Member',
          roleId: 'tabletop-member',
        ),
      ]);
      await signInEvidenceAccount(tester, 'Alex Member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final going = _eventAction(_gameNightId, 'respond-going');
      await _tapCalendarAction(tester, going);
      expect(_selectedChip(tester, going), isTrue);

      await signInEvidenceAccount(tester, 'Blair Member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);
      final blairGoing = _eventAction(_gameNightId, 'respond-going');
      expect(_selectedChip(tester, blairGoing), isFalse);

      final maybe = _eventAction(_gameNightId, 'respond-maybe');
      await _tapCalendarAction(tester, maybe);
      expect(_selectedChip(tester, maybe), isTrue);

      await signInEvidenceAccount(tester, 'Alex Member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);
      final alexGoing = _eventAction(_gameNightId, 'respond-going');
      final alexMaybe = _eventAction(_gameNightId, 'respond-maybe');
      expect(_selectedChip(tester, alexGoing), isTrue);
      expect(_selectedChip(tester, alexMaybe), isFalse);
    });

    testWidgets('RSVP maybe is handled by calendar engine action row', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture('maybe');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final maybe = _eventAction(_gameNightId, 'respond-maybe');
      await _tapCalendarAction(tester, maybe);
      expect(_selectedChip(tester, maybe), isTrue);
    });

    testWidgets('RSVP not-going is handled by calendar engine action row', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture('declined');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final declined = _eventAction(_gameNightId, 'respond-declined');
      await _tapCalendarAction(tester, declined);
      expect(_selectedChip(tester, declined), isTrue);
    });

    testWidgets('capacity and waitlist update from response instances', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(
        'waitlist',
        onlyTournament: true,
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _tournamentId);

      final eventCard = _eventCard(_tournamentId);
      final going = _eventAction(_tournamentId, 'respond-going');
      final waitlist = _eventAction(_tournamentId, 'respond-waitlist');
      expect(eventCard, findsOneWidget);
      expect(find.text('20 / 20 going'), findsOneWidget);
      expect(waitlist, findsOneWidget);
      expect(
        going,
        findsNothing,
        reason: 'the relatedAggregate guard must close Going at capacity',
      );

      await _tapCalendarAction(tester, waitlist);
      expect(
        find.byKey(ValueKey('event-rsvp-waitlist-$_tournamentId')),
        findsOneWidget,
      );
      expect(_selectedChip(tester, waitlist), isTrue);
      expect(find.text('20 / 20 going'), findsOneWidget);
    });

    testWidgets('event detail uses distinct schema-driven facts', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture('facts');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectActorIdentity(tester, 'tabletop-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForEvent(tester, _gameNightId);

      final detail = _eventCard(_gameNightId);
      expect(detail, findsOneWidget);
      for (final icon in <IconData>[
        Icons.schedule,
        Icons.person_outline,
        Icons.location_on_outlined,
      ]) {
        expect(
          find.descendant(of: detail, matching: find.byIcon(icon)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: detail,
          matching: find.byKey(
            const ValueKey('event-rsvp-capacity-bar-$_gameNightId'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('calendar fixture declares per-member response instances', (
      tester,
    ) async {
      final fixture = _writeTabletopCalendarFixture(
        'shape',
        onlyTournament: true,
      );
      final package =
          jsonDecode(
                File(fixture.package.initializationPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final experience = package['experience'] as Map<String, dynamic>;
      expect(experience.containsKey('workflows'), isFalse);

      final definitions =
          experience['workflowDefinitions'] as Map<String, dynamic>;
      final event = definitions['tabletop-event-rsvp'] as Map<String, dynamic>;
      final binding =
          (event['renderBindings'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(binding['tabId'], 'calendar');
      expect(binding['cardSurfaceFamily'], 'event-rsvp');
      expect(binding['responseTable'], <String, dynamic>{
        'workflowType': 'tabletop-event-rsvp-response',
        'eventField': 'eventId',
        'pendingStates': <String>['pending'],
      });

      final instances = experience['workflowInstances'] as List<dynamic>;
      final eventInstance = instances.cast<Map<String, dynamic>>().singleWhere(
        (instance) => instance['workflowType'] == 'tabletop-event-rsvp',
      );
      expect(eventInstance['instanceData'], isNot(contains('responseChoices')));
      final responses = instances
          .cast<Map<String, dynamic>>()
          .where(
            (instance) =>
                instance['workflowType'] == 'tabletop-event-rsvp-response',
          )
          .toList();
      expect(responses, hasLength(20));
      expect(
        responses,
        everyElement(
          predicate<Map<String, dynamic>>(
            (response) =>
                response['currentState'] == 'going' &&
                (response['instanceData'] as Map<String, dynamic>)['eventId'] ==
                    _tournamentId &&
                (response['instanceData'] as Map<String, dynamic>)['fanId'] !=
                    null,
          ),
        ),
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

bool _selectedChip(WidgetTester tester, Finder action) => tester
    .widget<InputChip>(
      find.descendant(of: action, matching: find.byType(InputChip)),
    )
    .selected;

Future<void> _tapCalendarAction(WidgetTester tester, Finder action) async {
  expect(action, findsOneWidget);
  await scrollFinderIntoViewport(tester, action);
  await tester.tap(action, warnIfMissed: false);
  await tester.pumpAndSettle();
}

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
  ({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
  fixture,
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
}

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeTabletopCalendarFixture(
  String suffix, {
  bool sameDateEvents = true,
  bool onlyTournament = false,
}) {
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
    organizerFanId: 'tabletop-organizer-01',
    memberRoleId: 'tabletop-member',
    capacity: 20,
    includeWaitlist: true,
    responseSeeds: _goingResponseSeeds(eventId: _gameNightId, count: 12),
  );
  final tournament = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-event-rsvp',
    responseWorkflowType: 'tabletop-event-rsvp-response',
    eventInstanceId: _tournamentId,
    title: 'Saturday tournament',
    eventDate: sameDateEvents ? '2026-07-10' : '2026-07-11',
    eventTime: '20:00',
    location: 'Community room',
    host: 'Mara, organizer',
    organizerRoleId: 'tabletop-organizer',
    organizerFanId: 'tabletop-organizer-01',
    memberRoleId: 'tabletop-member',
    capacity: 20,
    includeWaitlist: true,
    responseSeeds: _goingResponseSeeds(eventId: _tournamentId, count: 20),
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b36_calendar_',
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
        if (!onlyTournament) ...gameNight.workflowInstances,
        ...tournament.workflowInstances,
      ],
    },
    appShell: _calendarAppShell,
  );
  return (
    package: package,
    communityId: communityId,
    target: LoomEvidenceTarget(
      phase: 'test',
      communityId: communityId,
      communityName: 'Tabletop Club',
      handle: 'tabletop-calendar-engine-$suffix',
      extensionId: extensionId,
      accentColor: '#C4703F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
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
