import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

// Reuses the same frozen-JSON fixture and installation pattern as
// v3_milestone_a8_calendar_end_to_end_test.dart.

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledTabletop {
  const _InstalledTabletop(
    this.community,
    this.experience,
    this.engine,
    this.temp,
  );
  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

class _PollObservation {
  const _PollObservation(this.satisfied, this.state);

  final bool satisfied;
  final String state;
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-a11-$extensionId-');
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    final community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: init.path,
        )
        .community;
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    if (engine is LocalWorkflowEngineApi) {
      final accounts = await LocalAuthApi().listAccounts(
        communityExtensionId: 'ext_verify_tabletop_club',
      );
      for (final account in accounts) {
        engine.setPersonaType(account.accountId, account.personaTypeId);
      }
    }
    return _InstalledTabletop(community, experience, engine, temp);
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

LoomPersonaDefinition _persona(_InstalledTabletop installed, String id) =>
    installed.experience.personas!.firstWhere(
      (persona) => persona.personaId == id,
    );

Widget _calendar(
  _InstalledTabletop installed,
  String personaId, {
  int revision = 0,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: EngineNativeCalendarSurface(
        key: ValueKey('a11-calendar-$personaId-$revision'),
        experience: installed.experience,
        persona: _persona(installed, personaId),
        accent: Colors.deepPurple,
        modernTheme: null,
        engine: installed.engine,
      ),
    ),
  ),
);

Widget _app(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
  ),
);

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _pollUntilObservation(
  WidgetTester tester,
  Future<_PollObservation> Function() observe, {
  required String description,
}) async {
  _PollObservation? last;
  for (var attempt = 0; attempt < 120; attempt++) {
    last = await tester.runAsync(observe);
    if (last?.satisfied ?? false) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure(
    'Timed out waiting for $description; '
    'last observed state=${last?.state ?? 'no observation'}',
  );
}

Future<_PollObservation> _observeFinder(Finder finder, String label) async {
  final count = finder.evaluate().length;
  return _PollObservation(count > 0, '$label matches=$count');
}

Finder _selectedActionFinder(String instanceId, String transitionId) =>
    find.descendant(
      of: find.byKey(
        ValueKey('event-rsvp-$instanceId-action-$transitionId'),
      ),
      matching: find.byWidgetPredicate(
        (widget) => widget is InputChip && widget.selected,
      ),
    );

Future<void> _openEventCreation(WidgetTester tester) async {
  final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
  if (speedDial.evaluate().isNotEmpty) {
    await tester.ensureVisible(speedDial);
    await tester.tap(speedDial);
    await tester.pump();
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('creatable-fab-event-rsvp')),
    );
  }
  final createEvent = find.byKey(const ValueKey('creatable-fab-event-rsvp'));
  await _pumpUntil(tester, createEvent);
  await tester.ensureVisible(createEvent);
  await tester.tap(createEvent);
  await tester.pump();
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('new-event-editor-title')),
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  var lastMatchCount = 0;
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    lastMatchCount = finder.evaluate().length;
    if (lastMatchCount > 0) return;
  }
  throw TestFailure(
    'Timed out waiting for $finder; last observed matches=$lastMatchCount',
  );
}

Future<WorkflowInstance> _instance(
  WidgetTester tester,
  _InstalledTabletop installed,
  String id, {
  String personaId = 'tabletop-organizer',
}) async => (await tester.runAsync(() async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: personaId,
    limit: 50,
  );
  return page.items.singleWhere((row) => row.instanceId == id);
}))!;

Map<String, dynamic> _responseFor(WorkflowInstance event, String personaId) =>
    (event.instanceData['responses'] as List)
        .whereType<Map<String, dynamic>>()
        .map((response) => Map<String, dynamic>.from(response))
        .singleWhere((response) => response['personaId'] == personaId);

/// Taps an action chip keyed to the bespoke event-rsvp widget.
Future<void> _tapRsvpAction(
  WidgetTester tester,
  String instanceId,
  String transitionId, {
  num? partySize,
}) async {
  final action = find.byKey(
    ValueKey('event-rsvp-$instanceId-action-$transitionId'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
  await tester.pump();
  final dialog = find.byKey(
    const ValueKey('generic-transition-input-dialog'),
  );
  if (dialog.evaluate().isNotEmpty) {
    final partySizeInput = find.byKey(
      const ValueKey('generic-transition-input-partySize'),
    );
    if (partySizeInput.evaluate().isNotEmpty) {
      await tester.enterText(
        partySizeInput,
        (partySize ?? 1).toString(),
      );
    }
    final confirm = find.byKey(
      const ValueKey('generic-transition-input-confirm'),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
  }
  await _pollUntilObservation(
    tester,
    () => _observeFinder(
      _selectedActionFinder(instanceId, transitionId),
      'selected $transitionId action',
    ),
    description: 'RSVP action $instanceId/$transitionId',
  );
}

Future<void> _selectAgenda(
  WidgetTester tester,
  String instanceId,
  int ordinal,
) async {
  final row = find.byKey(
    ValueKey('engine-native-calendar-agenda-$instanceId-$ordinal'),
  );
  await _pumpUntil(tester, row);
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pump();
}

Future<void> _useFixtureAccounts(_InstalledTabletop installed) async {
  final auth = LocalAuthApi();
  auth.seedAccounts(
    installed.community.extensionId,
    await auth.listAccounts(communityExtensionId: 'ext_verify_tabletop_club'),
  );
  setGlobalAuthApi(auth);
}

void main() {
  // ---------------------------------------------------------------------------
  // Test 1: Selecting the Friday game-night event renders the bespoke
  //         _EventRsvpDetailCard, NOT GenericWorkflowInstanceCard.
  // ---------------------------------------------------------------------------
  testWidgets('Friday game-night renders bespoke event-rsvp card, not generic', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-bespoke')))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
      );
      await tester.pump();

      // The detail card should be the bespoke widget, not the generic one.
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-friday-game-night-0',
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
        findsOneWidget,
      );
      expect(find.byType(GenericWorkflowInstanceCard), findsNothing);

      final title = find.byKey(
        const ValueKey('event-rsvp-title-event-friday-game-night'),
      );
      expect(title, findsOneWidget);
      expect(tester.widget<Text>(title).style?.fontWeight, FontWeight.w700);
      final facts = find.byKey(
        const ValueKey('event-rsvp-fallback-facts-event-friday-game-night'),
      );
      expect(
        find.descendant(of: facts, matching: find.text('Friday game night')),
        findsNothing,
      );
      expect(
        find.descendant(of: facts, matching: find.text('2026-07-10')),
        findsNothing,
      );
      // The frozen fixture does not declare maxLength for these fallback
      // fields. They must remain compact pills because their runtime values
      // are short, rather than being promoted to paragraph blocks.
      expect(
        find.descendant(of: facts, matching: find.text('Community room')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: facts,
          matching: find.byIcon(Icons.location_on_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: facts,
          matching: find.byKey(
            const ValueKey('workflow-fact-paragraph-location'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: facts,
          matching: find.byKey(
            const ValueKey('workflow-fact-paragraph-host'),
          ),
        ),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 2: The capacity visualization reflects the real going-count/capacity
  //         (Friday seed: 11 response rows going, capacity 20).
  // ---------------------------------------------------------------------------
  testWidgets('capacity bar reflects real going count and capacity', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-capacity')))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
      );

      // Going: 11 / 20
      expect(find.text('11 / 20 going'), findsOneWidget);
      expect(find.text('9 seats left'), findsOneWidget);

      // Progress bar present
      final bar = find.byKey(
        const ValueKey('event-rsvp-capacity-bar-event-friday-game-night'),
      );
      expect(bar, findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(bar);
      expect(indicator.value, 11 / 20);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'Calendar attendee lists resolve frozen-fixture names by response state',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a11-attendee-names'),
      ))!;
      try {
        await tester.runAsync(() => _useFixtureAccounts(installed));
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);

        final attendees = find.byKey(
          const ValueKey('event-rsvp-attendees-event-friday-game-night'),
        );
        await _pumpUntil(tester, attendees);
        await _pumpUntil(tester, find.text('• Jordan W.'));
        expect(find.descendant(of: attendees, matching: find.text('Going')), findsOneWidget);
        expect(
          find.descendant(of: attendees, matching: find.text('• Jordan W.')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: attendees,
            matching: find.text('• tabletop-member-03'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Calendar attendee lists resolve tournament names and retain unknown ids',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a11-tournament-attendees'),
      ))!;
      try {
        await tester.runAsync(() => _useFixtureAccounts(installed));
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-summer-tournament', 0);

        final attendees = find.byKey(
          const ValueKey('event-rsvp-attendees-event-summer-tournament'),
        );
        await _pumpUntil(tester, attendees);
        await _pumpUntil(tester, find.text('• Jordan W.'));
        expect(find.descendant(of: attendees, matching: find.text('Going')), findsOneWidget);
        expect(
          find.descendant(of: attendees, matching: find.text('• Jordan W.')),
          findsOneWidget,
        );
        // The frozen list includes this legacy, unseeded persona id. It must
        // remain visible even when account lookup cannot resolve it.
        expect(
          find.descendant(of: attendees, matching: find.text('• tabletop-member')),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Test 3: Tapping "Going" updates the viewer's response row through the
  //         real engine, then rehydrates the event detail.
  // ---------------------------------------------------------------------------
  testWidgets('Going action persists through real engine and updates the card', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-going')))!;
    setCurrentActiveAccountId('tabletop-member-14');
    addTearDown(() => setCurrentActiveAccountId(null));
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
      );

      // Before: this seeded row is pending.
      final before = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      expect(
        _responseFor(before, 'tabletop-member-14')['\$id'],
        'resp-friday-member-14',
      );
      expect(_responseFor(before, 'tabletop-member-14')['\$state'], 'pending');
      expect(before.instanceData['goingCount'], 11);

      await _tapRsvpAction(
        tester,
        'event-friday-game-night',
        'respond-going',
        partySize: 3,
      );

      // After: the same real response row is going and the event formula updates.
      final after = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      expect(
        _responseFor(after, 'tabletop-member-14')['\$id'],
        'resp-friday-member-14',
      );
      expect(_responseFor(after, 'tabletop-member-14')['\$state'], 'going');
      expect(_responseFor(after, 'tabletop-member-14')['partySize'], 3);
      expect(after.instanceData['goingCount'], 12);
      expect(after.instanceData['seatsRemaining'], 8);

      // UI reflects new state
      await _pumpUntil(tester, find.text('12 / 20 going'));
      expect(find.text('12 / 20 going'), findsOneWidget);
      expect(find.text('8 seats left'), findsOneWidget);
      final goingChipFinder = find.descendant(
        of: find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-respond-going',
          ),
        ),
        matching: find.byWidgetPredicate(
          (widget) => widget is InputChip && widget.selected,
        ),
      );
      await _pumpUntil(tester, goingChipFinder);
      final goingChip = tester.widget<InputChip>(goingChipFinder);
      expect(goingChip.selected, isTrue);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'seeded pending member-14 goes through its own response row and selected UI state',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a11-member-14'),
      ))!;
      setCurrentActiveAccountId('tabletop-member-14');
      addTearDown(() => setCurrentActiveAccountId(null));
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final before = await _instance(
          tester,
          installed,
          'event-friday-game-night',
          personaId: 'tabletop-member-14',
        );
        expect(
          _responseFor(before, 'tabletop-member-14')['\$id'],
          'resp-friday-member-14',
        );
        expect(
          _responseFor(before, 'tabletop-member-14')['\$state'],
          'pending',
        );
        final goingBefore = before.instanceData['goingCount'] as num;

        await _tapRsvpAction(
          tester,
          'event-friday-game-night',
          'respond-going',
        );

        final after = await _instance(
          tester,
          installed,
          'event-friday-game-night',
          personaId: 'tabletop-member-14',
        );
        expect(_responseFor(after, 'tabletop-member-14')['\$state'], 'going');
        expect(after.instanceData['goingCount'], goingBefore + 1);
        final goingChipFinder = find.descendant(
          of: find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-respond-going',
            ),
          ),
          matching: find.byWidgetPredicate(
            (widget) => widget is InputChip && widget.selected,
          ),
        );
        await _pumpUntil(tester, goingChipFinder);
        final goingChip = tester.widget<InputChip>(goingChipFinder);
        expect(goingChip.selected, isTrue);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Test 4: The waitlist state renders distinctly once response rows fill
  //         capacity.
  // ---------------------------------------------------------------------------
  testWidgets('waitlist indicator renders when capacity is reached', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-waitlist')))!;
    setCurrentActiveAccountId('tabletop-member-14');
    addTearDown(() => setCurrentActiveAccountId(null));
    try {
      // Set up: the seed has 11 going rows; reduce capacity to 11.
      await tester.runAsync(() async {
        await installed.engine.updateInstanceFields(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          fieldUpdates: const {'capacity': 11},
          personaId: 'tabletop-organizer',
        );
      });

      // Now 11 going, capacity 11 → full. tabletop-member-14 is pending.
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-member', revision: 2),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
      );

      // Full capacity bar
      expect(find.text('11 / 11 going'), findsOneWidget);
      expect(find.text('0 seats left'), findsOneWidget);

      // Join waitlist action should be available (not Going)
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-respond-waitlist',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-respond-going',
          ),
        ),
        findsNothing,
      );

      // No waitlist indicator yet
      expect(
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
        findsNothing,
      );

      // Join waitlist
      await _tapRsvpAction(
        tester,
        'event-friday-game-night',
        'respond-waitlist',
      );

      final waitlisted = await _instance(
        tester,
        installed,
        'event-friday-game-night',
        personaId: 'tabletop-member-14',
      );
      expect(
        _responseFor(waitlisted, 'tabletop-member-14')['\$state'],
        'waitlisted',
      );
      expect(waitlisted.instanceData['goingCount'], 11);

      // Waitlist indicator appears
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
        findsOneWidget,
      );
      expect(find.text('You are on the waitlist'), findsOneWidget);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 5: Selecting the Summer Tournament (tournament-event, which shares
  //         cardSurfaceFamily 'event-rsvp') also renders the bespoke widget.
  // ---------------------------------------------------------------------------
  testWidgets('Summer Tournament also renders bespoke event-rsvp card', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a11-tournament'),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _selectAgenda(tester, 'event-summer-tournament', 0);

      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-summer-tournament-0',
          ),
        ),
      );

      // Bespoke card, not generic
      expect(
        find.byKey(const ValueKey('event-rsvp-card-event-summer-tournament')),
        findsOneWidget,
      );
      expect(find.byType(GenericWorkflowInstanceCard), findsNothing);

      // Tournament-specific: Accepted count, quorum met indicator
      expect(
        find.text('8 / 8 going'),
        findsOneWidget,
      ); // accepted=8, minimumAttendance=8
      expect(
        find.byKey(
          const ValueKey('event-rsvp-capacity-bar-event-summer-tournament'),
        ),
        findsOneWidget,
      );

      // tabletop-member is in goingPersonaIds, so withdraw should be visible
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'event-rsvp-event-summer-tournament-action-rsvp-withdraw',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'event-rsvp-event-summer-tournament-action-rsvp-going',
          ),
        ),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'organizer creates an event and one pending response per member',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr3-create'),
      ))!;
      try {
        LocalAuthApi().seedAccounts(installed.community.extensionId, const [
          LoomAccount(
            accountId: 'calr3-organizer',
            displayName: 'Test Organizer',
            personaTypeId: 'tabletop-organizer',
          ),
          LoomAccount(
            accountId: 'calr3-member-a',
            displayName: 'Test Member A',
            personaTypeId: 'tabletop-member',
          ),
          LoomAccount(
            accountId: 'calr3-member-b',
            displayName: 'Test Member B',
            personaTypeId: 'tabletop-member',
          ),
        ]);
        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        await _openEventCreation(tester);

        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-title')),
          'CALR.3 test event',
        );
        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-location')),
          'Community room',
        );
        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-capacity')),
          '24',
        );
        final eventDate = find.byKey(
          const ValueKey('new-event-editor-eventDate'),
        );
        await tester.ensureVisible(eventDate);
        await tester.tap(eventDate);
        await tester.pumpAndSettle();
        await tester.tap(find.text('15').last);
        await tester.tap(find.text('OK').last);
        await tester.pumpAndSettle();
        final eventTime = find.byKey(
          const ValueKey('new-event-editor-eventTime'),
        );
        await tester.ensureVisible(eventTime);
        await tester.tap(eventTime);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK').last);
        await tester.pumpAndSettle();
        final submit = find.byKey(const ValueKey('new-event-submit'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        await _pollUntilObservation(
          tester,
          () async {
            final page = await installed.engine.queryInstances(
              tabId: 'calendar',
              personaId: 'tabletop-organizer',
              limit: 100,
            );
            final events = page.items
                .where(
                  (item) =>
                      item.workflowType == 'event-rsvp' &&
                      item.instanceData['title'] == 'CALR.3 test event',
                )
                .toList();
            return _PollObservation(
              events.isNotEmpty,
              'matching events=${events.length}',
            );
          },
          description: 'created CALR.3 event',
        );

        final result = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          final event = page.items.singleWhere(
            (item) =>
                item.workflowType == 'event-rsvp' &&
                item.instanceData['title'] == 'CALR.3 test event',
          );
          final accounts = await LocalAuthApi().listAccounts(
            communityExtensionId: installed.community.extensionId,
          );
          final responses = page.items.where(
            (item) =>
                item.workflowType == 'event-rsvp-response' &&
                item.instanceData['eventId'] == event.instanceId,
          );
          return (accounts: accounts, responses: responses.toList());
        }))!;
        expect(result.responses, hasLength(result.accounts.length));
        for (final response in result.responses) {
          expect(response.currentState, 'pending');
          expect(
            result.accounts.map((account) => account.accountId),
            contains(response.instanceData['personaId']),
          );
        }
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('new event control is hidden from a non-creatable persona', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('calr3-hidden')))!;
    try {
      await tester.pumpWidget(_app(installed));
      await _selectCalendar(tester);
      // Switch to the tabletop-member persona so the creatable-action
      // FAB is hidden (the fixture only lists tabletop-organizer
      // in creatable.byPersonaIds).
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('persona-option-tabletop-member')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('creatable-fab-event-rsvp')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('creatable-fab-speed-dial')),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });
}
