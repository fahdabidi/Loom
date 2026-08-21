import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';
const _communityId = 'community_verify_tabletop_club';

void main() {
  group('B27 Calendar tab real data (Phase 2 spike)', () {
    testWidgets('wf_calendar-tab-renders-real-package-declared-agenda', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair('agenda');

      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForCalendar(tester, 'tabletop-game-night-rsvp');

      expect(
        find.byKey(const ValueKey('engine-native-calendar-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-grouped-agenda')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
        ),
        findsOneWidget,
      );
      // The real state-machine card and agenda replace the removed shallow
      // CalendarWorkflowDefinition detail/strip widgets.
      expect(
        find.byKey(const ValueKey('event-rsvp-card-tabletop-game-night-rsvp')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('calendar-week-strip')), findsNothing);
      expect(find.text('Community room'), findsOneWidget);
      expect(find.text('12 / 20 going'), findsOneWidget);
    });

    testWidgets(
      'wf_calendar-tab-groups-same-date-events-and-uses-semantic-icons',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair(
          'same-day',
          includeHost: true,
          includeSecondEvent: true,
        );
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await tapCommunityTab(tester, 'calendar');
        await _waitForCalendar(tester, 'tabletop-tournament-rsvp');

        final dateGroup = find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
        );
        expect(dateGroup, findsOneWidget);
        expect(
          find.descendant(
            of: dateGroup,
            matching: find.byKey(
              const ValueKey(
                'engine-native-calendar-agenda-tabletop-game-night-rsvp-0',
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dateGroup,
            matching: find.byKey(
              const ValueKey(
                'engine-native-calendar-agenda-tabletop-tournament-rsvp-0',
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
          ),
          findsOneWidget,
          reason: 'same-date events share one declarative agenda date rail',
        );

        final detail = find.byKey(
          const ValueKey('event-rsvp-card-tabletop-tournament-rsvp'),
        );
        expect(detail, findsOneWidget);
        for (final icon in <IconData>[
          Icons.schedule,
          Icons.location_on_outlined,
          Icons.person_outline,
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
              const ValueKey(
                'event-rsvp-capacity-bar-tabletop-tournament-rsvp',
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      },
    );

    testWidgets('wf_calendar-tab-renders-host-when-declared', (tester) async {
      final fixture = _writeTabletopClubPackagePair('host', includeHost: true);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForCalendar(tester, 'tabletop-game-night-rsvp');

      expect(find.textContaining('Alex Chen (Organizer)'), findsOneWidget);
    });

    testWidgets('wf_calendar-tab-still-renders-without-host', (tester) async {
      final fixture = _writeTabletopClubPackagePair('no-host');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await tapCommunityTab(tester, 'calendar');
      await _waitForCalendar(tester, 'tabletop-game-night-rsvp');

      expect(
        find.byKey(const ValueKey('engine-native-calendar-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-rsvp-card-tabletop-game-night-rsvp')),
        findsOneWidget,
      );
      expect(find.textContaining('Alex Chen'), findsNothing);
    });

    testWidgets('wf_calendar-tab-catalog-community-uses-engine-agenda', (
      tester,
    ) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_camera_club',
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installEvidenceTarget(tester, target, useShippedPackage: true);
      await openEvidenceTarget(tester, target);
      await selectPersona(tester, 'camera-club-member');
      await tapCommunityTab(tester, 'calendar');
      await _waitForCalendar(tester, 'walk-golden-gate-sunrise');

      expect(
        find.byKey(const ValueKey('engine-native-calendar-root')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-rsvp-card-walk-golden-gate-sunrise')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('camera-engine-calendar')),
        findsNothing,
        reason:
            'the shipped event-rsvp package renders the generic engine calendar',
      );
    });
  });
}

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

Future<void> _waitForCalendar(
  WidgetTester tester,
  String selectedEventId,
) async {
  await waitForEngineNativeWidget(
    tester,
    find.byKey(ValueKey('event-rsvp-card-$selectedEventId')),
    description: 'engine-native Calendar event $selectedEventId',
  );
}

({EvidencePackagePair package, String communityId})
_writeTabletopClubPackagePair(
  String suffix, {
  bool includeHost = false,
  bool includeSecondEvent = false,
}) {
  final extensionId = '${_extensionId}_$suffix';
  final communityId = '${_communityId}_$suffix';
  final gameNight = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-event-rsvp',
    responseWorkflowType: 'tabletop-event-rsvp-response',
    eventInstanceId: 'tabletop-game-night-rsvp',
    title: 'Friday game night',
    eventDate: '2026-07-10',
    eventTime: '19:00',
    location: 'Community room',
    host: includeHost ? 'Alex Chen (Organizer)' : null,
    organizerRoleId: 'tabletop-organizer',
    memberRoleId: 'tabletop-member',
    capacity: 20,
    responseSeeds: _goingResponseSeeds(
      eventId: 'tabletop-game-night-rsvp',
      count: 12,
    ),
  );
  final tournament = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-event-rsvp',
    responseWorkflowType: 'tabletop-event-rsvp-response',
    eventInstanceId: 'tabletop-tournament-rsvp',
    title: 'Saturday tournament',
    eventDate: '2026-07-10',
    eventTime: '13:00',
    location: 'Community hall',
    host: includeHost ? 'Alex Chen (Organizer)' : null,
    organizerRoleId: 'tabletop-organizer',
    memberRoleId: 'tabletop-member',
    capacity: 20,
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b27_tabletop_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, loaner games, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': _tabletopRoles,
      'workflowDefinitions': gameNight.workflowDefinitions,
      'workflowInstances': <Object?>[
        ...gameNight.workflowInstances,
        if (includeSecondEvent) ...tournament.workflowInstances,
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
