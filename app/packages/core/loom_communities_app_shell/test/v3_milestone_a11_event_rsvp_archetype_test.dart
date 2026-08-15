import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

// Reuses the same frozen-JSON fixture and installation pattern as
// v3_milestone_a8_calendar_end_to_end_test.dart.

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
const _gardenFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc';

const _customGardenEventWorkflow = 'garden-event-rsvp';
const _customGardenResponseWorkflow = 'garden-event-rsvp-response';
const _customGardenResponseEventField = 'eventId';
const _customGardenEventId = 'spring-workshop';
const _customGardenOrganizerId = 'garden-coordinator';
const _customGardenMemberId = 'garden-member';

File _fixtureFile([String fixtureRelative = _fixtureRelative]) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find fixture at $fixtureRelative');
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

Future<_InstalledTabletop> _install(
  String extensionId, {
  String fixtureRelative = _fixtureRelative,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile(fixtureRelative).readAsStringSync()))
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
      final seedFrom = source['displayName'] == 'Tabletop Club'
          ? 'ext_verify_tabletop_club'
          : community.extensionId;
      final accounts = await LocalAuthApi().listAccounts(
        communityExtensionId: seedFrom,
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
  String? accountId,
  LoomAuthApi? authApi,
  DateTime? currentDate,
}) => MaterialApp(
  home: ActiveIdentityScope(
    identity: ActiveIdentityContext(
      accountId: accountId,
      authApi: authApi ?? LocalAuthApi(),
      personaId: personaId,
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: EngineNativeCalendarSurface(
          key: ValueKey('a11-calendar-$personaId-$revision'),
          experience: installed.experience,
          persona: _persona(installed, personaId),
          accent: Colors.deepPurple,
          modernTheme: null,
          engine: installed.engine,
          currentDate: currentDate == null ? DateTime.now : () => currentDate,
        ),
      ),
    ),
  ),
);

Widget _app(_InstalledTabletop installed, {LoomAuthApi? authApi}) =>
    MaterialApp(
      home: LocalExtensionScreen(
        community: installed.community,
        seedDataFiles: const [],
        authApi:
            authApi ??
            activeAuthForCommunity(
              community: installed.community,
              experience: experienceForExtensionId(
                installed.community.extensionId,
                displayName: installed.community.displayName,
                experienceConfiguration:
                    installed.community.experienceConfiguration,
              ),
              personaTypeId: 'tabletop-organizer',
            ),
      ),
    );

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
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
      of: find.byKey(ValueKey('event-rsvp-$instanceId-action-$transitionId')),
      matching: find.byWidgetPredicate(
        (widget) => widget is InputChip && widget.selected,
      ),
    );

Future<void> _openEventCreation(
  WidgetTester tester, {
  String? workflowType,
}) async {
  // This test mounts the real App Shell, so the Calendar tab's engine-native
  // surface is still loading when _selectCalendar returns after its first
  // frame. The creatable FAB can already be in the tree during that handoff,
  // but it is not yet a reliable interaction target.
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('engine-native-calendar-root')),
  );

  final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
  final createEvent = find.byKey(
    ValueKey(
      workflowType == null ? 'creatable-fab-event-rsvp' : 'creatable-fab-$workflowType',
    ),
  );
  if (speedDial.evaluate().isNotEmpty) {
    await tester.ensureVisible(speedDial);
    await tester.tap(speedDial);
    await tester.pump();
    await _pumpUntil(tester, createEvent);
  }
  await _pumpUntilCreatableFabReady(tester, createEvent);
  await tester.ensureVisible(createEvent);
  await tester.tap(createEvent);
  await tester.pump();
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('new-event-editor-title')),
  );
}

Future<void> _pumpUntilCreatableFabReady(
  WidgetTester tester,
  Finder finder,
) async {
  var lastMatchCount = 0;
  var lastIgnored = false;
  var lastRunningAnimations = false;
  var lastScheduledFrame = false;
  for (var attempt = 0; attempt < 40; attempt++) {
    final matches = finder.evaluate();
    lastMatchCount = matches.length;
    final ignorePointers = find
        .ancestor(of: finder, matching: find.byType(IgnorePointer))
        .evaluate();
    lastIgnored = ignorePointers.any(
      (element) => (element.widget as IgnorePointer).ignoring,
    );
    lastRunningAnimations = tester.hasRunningAnimations;
    lastScheduledFrame = tester.binding.hasScheduledFrame;
    if (lastMatchCount > 0 &&
        !lastIgnored &&
        !lastRunningAnimations &&
        !lastScheduledFrame) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure(
    'Timed out waiting for $finder to become interactive; '
    'last observed matches=$lastMatchCount, '
    'ignored=$lastIgnored, runningAnimations=$lastRunningAnimations, '
    'scheduledFrame=$lastScheduledFrame',
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
  bool awaitSelection = true,
  bool expectDialog = true,
  Map<String, String>? inputs,
}) async {
  final action = find.byKey(
    ValueKey('event-rsvp-$instanceId-action-$transitionId'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
  await tester.pump();
  final dialog = find.byKey(const ValueKey('generic-transition-input-dialog'));
  final requestedInputs = {
    if (transitionId == 'respond-going' && expectDialog)
      'partySize': '${partySize ?? 1}',
    if (inputs != null) ...inputs,
  };
  if (requestedInputs.isNotEmpty) {
    await _pumpUntil(tester, dialog);
  } else {
    // Not every fixture's transition declares inputs (e.g. a plain guarded
    // respond-going with no partySize field) -- give a dialog a brief,
    // non-throwing chance to appear rather than assuming one always will.
    for (var i = 0; i < 5 && dialog.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  if (dialog.evaluate().isNotEmpty) {
    for (final entry in requestedInputs.entries) {
      final input = find.byKey(ValueKey('generic-transition-input-${entry.key}'));
      if (input.evaluate().isEmpty) continue;
      await _pumpUntil(tester, input);
      await tester.ensureVisible(input);
      await tester.enterText(input, entry.value);
    }
    final confirm = find.byKey(
      const ValueKey('generic-transition-input-confirm'),
    );
    await _pumpUntil(tester, confirm);
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
  }
  if (awaitSelection) {
    await _pollUntilObservation(
      tester,
      () => _observeFinder(
        _selectedActionFinder(instanceId, transitionId),
        'selected $transitionId action',
      ),
      description: 'RSVP action $instanceId/$transitionId',
    );
  }
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
  await _pumpUntil(
    tester,
    find.byKey(
      ValueKey('engine-native-calendar-selected-detail-$instanceId-$ordinal'),
    ),
  );
}

Future<void> _selectAgendaById(WidgetTester tester, String instanceId) async {
  final agendaRow = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('engine-native-calendar-agenda-$instanceId-');
  });
  await _pumpUntil(tester, agendaRow);
  await tester.ensureVisible(agendaRow);
  await tester.tap(agendaRow);
  await tester.pump();
  await _pumpUntil(
    tester,
    find.byWidgetPredicate((widget) {
      final selected = widget.key;
      return selected is ValueKey<String> &&
          selected.value.startsWith('engine-native-calendar-selected-detail-$instanceId-');
    }),
  );
}

Future<LoomAuthApi> _useFixtureAccounts(_InstalledTabletop installed) async {
  final auth = LocalAuthApi();
  final seedFrom = installed.experience.personas
          ?.any((persona) => persona.personaId == 'tabletop-member') ==
      true
    ? 'ext_verify_tabletop_club'
    : installed.community.extensionId;
  auth.seedAccounts(
    installed.community.extensionId,
    await auth.listAccounts(communityExtensionId: seedFrom),
  );
  return auth;
}

Future<WorkflowInstance?> _customResponseFor(
  _InstalledTabletop installed, {
  required String responseWorkflowType,
  required String eventField,
  required String eventId,
  required String personaId,
  String persona = _customGardenOrganizerId,
}) async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: persona,
    limit: 250,
  );
  for (final row in page.items) {
    if (row.workflowType != responseWorkflowType) continue;
    if (row.instanceData[eventField] != eventId) continue;
    if (row.instanceData['personaId'] != personaId) continue;
    return row;
  }
  return null;
}

Future<List<WorkflowInstance>> _customResponseRowsForEvent(
  _InstalledTabletop installed, {
  required String responseWorkflowType,
  required String eventField,
  required String eventId,
  String persona = _customGardenOrganizerId,
}) async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: persona,
    limit: 500,
  );
  return page.items
      .where(
        (row) =>
            row.workflowType == responseWorkflowType &&
            row.instanceData[eventField] == eventId,
      )
      .toList();
}

Future<WorkflowInstance?> _customEventByTitle(
  _InstalledTabletop installed, {
  required String title,
  String workflowType = _customGardenEventWorkflow,
  String personaId = _customGardenOrganizerId,
}) async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: personaId,
    limit: 500,
  );
  final matches = page.items.where(
    (row) => row.workflowType == workflowType && row.instanceData['title'] == title,
  );
  return matches.length == 1 ? matches.first : null;
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
          matching: find.byKey(const ValueKey('workflow-fact-paragraph-host')),
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
        final auth = (await tester.runAsync(
          () => _useFixtureAccounts(installed),
        ))!;
        await tester.pumpWidget(
          _calendar(installed, 'tabletop-member', authApi: auth),
        );
        await _selectAgenda(tester, 'event-friday-game-night', 0);

        final attendees = find.byKey(
          const ValueKey('event-rsvp-attendees-event-friday-game-night'),
        );
        await _pumpUntil(tester, attendees);
        await _pumpUntil(tester, find.text('• Jordan W.'));
        expect(
          find.descendant(of: attendees, matching: find.text('Going')),
          findsOneWidget,
        );
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
        final auth = (await tester.runAsync(
          () => _useFixtureAccounts(installed),
        ))!;
        await tester.pumpWidget(
          _calendar(installed, 'tabletop-member', authApi: auth),
        );
        await _selectAgenda(tester, 'event-summer-tournament', 0);

        final attendees = find.byKey(
          const ValueKey('event-rsvp-attendees-event-summer-tournament'),
        );
        await _pumpUntil(tester, attendees);
        await _pumpUntil(tester, find.text('• Jordan W.'));
        expect(
          find.descendant(of: attendees, matching: find.text('Going')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: attendees, matching: find.text('• Jordan W.')),
          findsOneWidget,
        );
        // The frozen list includes this legacy, unseeded persona id. It must
        // remain visible even when account lookup cannot resolve it.
        expect(
          find.descendant(
            of: attendees,
            matching: find.text('• tabletop-member'),
          ),
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
    try {
      await tester.pumpWidget(
        _calendar(
          installed,
          'tabletop-member',
          accountId: 'tabletop-member-14',
        ),
      );
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

  // D7a create-or-get. `tabletop-member-15` has no seeded response row, which
  // is the shape a member who joins *after* an event was created ends up in --
  // the archetype's fan-out only covers members who existed at creation time.
  // This used to be a dead button: `_applyTransition` returned early with no
  // error, no feedback and no state change, so the tap simply did nothing and
  // repeated taps did nothing again.
  testWidgets('a member with no response row can RSVP; the row is created', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-createorget')))!;
    try {
      // The fixture has no late-joiner shape to borrow: every one of its 13
      // accounts already has a row on the only event that has any. So make one
      // -- a real, typed member with no response row.
      //
      // Registering the persona type is the part that matters. Without it the
      // account has no entry in `_personaTypeById`, so `allowedPersonaIds` on
      // `respond-going` refuses it and no actions resolve -- which looks
      // identical to the bug under test while having nothing to do with it.
      final engine = installed.engine;
      if (engine is LocalWorkflowEngineApi) {
        engine.setPersonaType('tabletop-member-15', 'tabletop-member');
      }
      await tester.pumpWidget(
        _calendar(
          installed,
          'tabletop-member',
          accountId: 'tabletop-member-15',
        ),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
      );

      final before = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      expect(
        (before.instanceData['responses'] as List)
            .whereType<Map<String, dynamic>>()
            .where((row) => row['personaId'] == 'tabletop-member-15'),
        isEmpty,
        reason: 'precondition: this member must start with no response row',
      );
      expect(before.instanceData['goingCount'], 11);

      await _tapRsvpAction(
        tester,
        'event-friday-game-night',
        'respond-going',
        partySize: 1,
      );

      final after = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      // The row now exists, carries the response, and counts toward the event's
      // derived aggregate -- proving it went through the real engine rather
      // than being reflected only in the widget.
      expect(_responseFor(after, 'tabletop-member-15')['\$state'], 'going');
      expect(after.instanceData['goingCount'], 12);
    } finally {
      await tester.runAsync(installed.dispose);
    }
    // This covers both halves of D7a together, which is the only way it is
    // worth covering: `_loadActions` offers the controls by resolving
    // availability against a synthetic row at the response workflow's
    // `initialState`, and `_applyTransition` materializes the real row when one
    // is tapped. Either half alone is unobservable -- without the first there
    // is no control to tap, and without the second the tap does nothing.
  });

  testWidgets(
    'seeded pending member-14 goes through its own response row and selected UI state',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a11-member-14'),
      ))!;
      try {
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-member',
            accountId: 'tabletop-member-14',
          ),
        );
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
        _calendar(
          installed,
          'tabletop-member',
          revision: 2,
          accountId: 'tabletop-member-14',
        ),
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

  // ---------------------------------------------------------------------------
  // Test 6: Custom workflow names also use the event-rsvp detail card and response
  //         actions.
  // ---------------------------------------------------------------------------
  testWidgets(
    'custom workflow event uses event-rsvp response actions when the viewer has a seeded response',
    (tester) async {
      final installed = (await tester.runAsync(() => _install(
        'a11-garden-bespoke',
        fixtureRelative: _gardenFixtureRelative,
      )))!;
      try {
        final auth = (await tester.runAsync(() => _useFixtureAccounts(installed)))!;
        await tester.pumpWidget(_calendar(installed, _customGardenMemberId, authApi: auth));
        await _selectAgendaById(tester, _customGardenEventId);

        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('event-rsvp-card-$_customGardenEventId')),
        );
        expect(find.byType(GenericWorkflowInstanceCard), findsNothing);
        expect(
          find.byKey(const ValueKey('event-rsvp-card-$_customGardenEventId')),
          findsOneWidget,
        );

        final seededResponse = await tester.runAsync(() => _customResponseFor(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: _customGardenEventId,
          personaId: _customGardenMemberId,
        ));
        expect(seededResponse, isNotNull);
        expect(seededResponse!.currentState, 'pending');

        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('event-rsvp-$_customGardenEventId-action-respond-going'),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('event-rsvp-$_customGardenEventId-action-respond-maybe'),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'event-rsvp-$_customGardenEventId-action-respond-declined',
            ),
          ),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'custom workflow respond-going updates the response row and event aggregate counts',
    (tester) async {
      final installed = (await tester.runAsync(() => _install(
        'a11-garden-response',
        fixtureRelative: _gardenFixtureRelative,
      )))!;
      try {
        final auth = (await tester.runAsync(() => _useFixtureAccounts(installed)))!;
        await tester.pumpWidget(_calendar(installed, _customGardenMemberId, authApi: auth));
        await _selectAgendaById(tester, _customGardenEventId);
        await _pumpUntil(
          tester,
          find.byKey(ValueKey('event-rsvp-$_customGardenEventId-action-respond-going')),
        );

        final beforeEvent = (await tester.runAsync(() =>
            _customEventByTitle(installed, title: 'Spring Workshop')))!;
        expect(beforeEvent.currentState, 'open');
        final beforeCounts = beforeEvent.instanceData['goingCount'] as num;

        final beforeResponse = await tester.runAsync(() => _customResponseFor(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: _customGardenEventId,
          personaId: _customGardenMemberId,
        ));
        expect(beforeResponse?.currentState, 'pending');

        await _tapRsvpAction(
          tester,
          _customGardenEventId,
          'respond-going',
          expectDialog: false,
        );

        final afterEvent = (await tester.runAsync(() =>
            _customEventByTitle(installed, title: 'Spring Workshop')))!;
        expect(afterEvent.currentState, 'open');
        expect(afterEvent.instanceData['goingCount'], beforeCounts + 1);

        final afterResponse = await tester.runAsync(() => _customResponseFor(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: _customGardenEventId,
          personaId: _customGardenMemberId,
        ));
        expect(afterResponse?.currentState, 'going');
        await _pumpUntil(tester, find.text('2 / 20 going'));

        final selected = find.descendant(
          of: find.byKey(
            ValueKey('event-rsvp-$_customGardenEventId-action-respond-going'),
          ),
          matching: find.byWidgetPredicate(
            (widget) => widget is InputChip && widget.selected,
          ),
        );
        await _pumpUntil(tester, selected);
        final selectedChip = tester.widget<InputChip>(selected);
        expect(selectedChip.selected, isTrue);

        final literalResponses = await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: _customGardenMemberId,
            limit: 200,
          );
          return page.items
              .where((item) => item.workflowType == 'event-rsvp-response')
              .toList();
        });
        expect(literalResponses, isEmpty);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'missing custom response row keeps organizer event-level actions visible',
    (tester) async {
      final installed = (await tester.runAsync(() => _install(
        'a11-garden-missing-row',
        fixtureRelative: _gardenFixtureRelative,
      )))!;
      String customInstanceId = '';
      try {
        customInstanceId = (await tester.runAsync(() async {
          final createdIds = await installed.engine.createInstances(
            workflowType: _customGardenEventWorkflow,
            initialInstanceDataList: const [
              {
                'title': 'Bespoke Garden orphan response event',
                'eventDate': '2026-09-20',
                'eventTime': '09:00',
                'location': 'North Bed',
                'capacity': 18,
                'reminderOffsetHours': 24,
              },
            ],
            personaId: _customGardenOrganizerId,
          );
          return createdIds.first;
        }))!;

        final seededRow = await tester.runAsync(() => _customResponseFor(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: customInstanceId,
          personaId: _customGardenOrganizerId,
        ));
        expect(seededRow, isNull);

        await tester.pumpWidget(_calendar(installed, _customGardenOrganizerId));
        await _selectAgendaById(tester, customInstanceId);

        await _pumpUntil(
          tester,
          find.byKey(
            ValueKey('event-rsvp-card-$customInstanceId'),
          ),
        );
        expect(
          find.byKey(
            ValueKey('event-rsvp-$customInstanceId-action-cancel-event'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            ValueKey('event-rsvp-$customInstanceId-action-respond-going'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('custom workflow reminders are sent on custom response instances', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install(
      'a11-garden-reminder',
      fixtureRelative: _gardenFixtureRelative,
    )))!;
    try {
      final auth = activeAuthForInstalledCommunity(
        community: installed.community,
        personaTypeId: _customGardenMemberId,
      );
      await tester.pumpWidget(
        _calendar(
          installed,
          _customGardenMemberId,
          authApi: auth,
          currentDate: DateTime(2026, 8, 14, 10),
        ),
      );
      await _selectAgendaById(tester, _customGardenEventId);

      final beforeResponse = await tester.runAsync(() => _customResponseFor(
        installed,
        responseWorkflowType: _customGardenResponseWorkflow,
        eventField: _customGardenResponseEventField,
        eventId: _customGardenEventId,
        personaId: _customGardenMemberId,
      ));
      expect(beforeResponse?.instanceData['reminderSentAt'], isNull);

      await _pollUntilObservation(tester, () async {
        final pending = await _customResponseFor(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: _customGardenEventId,
          personaId: _customGardenMemberId,
        );
        return _PollObservation(
          pending?.instanceData['reminderSentAt'] is String,
          'reminderSentAt=${pending?.instanceData['reminderSentAt']}',
        );
      }, description: 'custom response reminder applied');

      final after = await tester.runAsync(() => _customResponseFor(
        installed,
        responseWorkflowType: _customGardenResponseWorkflow,
        eventField: _customGardenResponseEventField,
        eventId: _customGardenEventId,
        personaId: _customGardenMemberId,
      ));
      expect(after?.instanceData['reminderSentAt'], isNotNull);

      final literalReminderTargets = await tester.runAsync(() async {
        final page = await installed.engine.queryInstances(
          tabId: 'calendar',
          personaId: _customGardenMemberId,
          limit: 200,
        );
        return page.items
            .where(
              (row) =>
                  row.workflowType == 'event-rsvp-response' &&
                  row.instanceData[_customGardenResponseEventField] ==
                      _customGardenEventId,
            )
            .toList();
      });
      expect(literalReminderTargets, isEmpty);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'custom event creation and recurring generation seed custom response rows',
    (tester) async {
      final installed = (await tester.runAsync(() => _install(
        'a11-garden-recurring',
        fixtureRelative: _gardenFixtureRelative,
      )))!;
      try {
        final auth = activeAuthForInstalledCommunity(
          community: installed.community,
          personaTypeId: _customGardenOrganizerId,
        );
        await tester.pumpWidget(_app(installed, authApi: auth));
        await _selectCalendar(tester);
        await _openEventCreation(
          tester,
          workflowType: _customGardenEventWorkflow,
        );

        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-title')),
          'CJM5 garden custom event',
        );
        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-location')),
          'South Bed',
        );
        await tester.enterText(
          find.byKey(const ValueKey('new-event-editor-capacity')),
          '12',
        );
        final eventDate = find.byKey(
          const ValueKey('new-event-editor-eventDate'),
        );
        await tester.ensureVisible(eventDate);
        await tester.tap(eventDate);
        await tester.pump();
        await _pumpUntil(tester, find.text('20'));
        await tester.tap(find.text('20').last);
        await tester.pump();
        await _pumpUntil(tester, find.text('OK'));
        await tester.tap(find.text('OK').last);
        await tester.pump();
        final eventTime = find.byKey(
          const ValueKey('new-event-editor-eventTime'),
        );
        await tester.ensureVisible(eventTime);
        await tester.tap(eventTime);
        await tester.pump();
        await _pumpUntil(tester, find.text('OK'));
        await tester.tap(find.text('OK').last);
        await tester.pump();
        final submit = find.byKey(const ValueKey('new-event-submit'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();

        await _pollUntilObservation(tester, () async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: _customGardenOrganizerId,
            limit: 500,
          );
          return _PollObservation(
            page.items.any(
              (item) =>
                  item.workflowType == _customGardenEventWorkflow &&
                  item.instanceData['title'] == 'CJM5 garden custom event',
            ),
            'custom event created',
          );
        }, description: 'custom event created');

        final created = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: _customGardenOrganizerId,
            limit: 500,
          );
          return page.items.singleWhere(
            (item) =>
                item.workflowType == _customGardenEventWorkflow &&
                item.instanceData['title'] == 'CJM5 garden custom event',
          );
        }))!;

        final accountIds = (await tester.runAsync(() async {
          final accounts = await LocalAuthApi().listAccounts(
            communityExtensionId: installed.community.extensionId,
          );
          return accounts.map((account) => account.accountId).toSet();
        }))!;
        final seededResponses = (await tester.runAsync(() => _customResponseRowsForEvent(
          installed,
          responseWorkflowType: _customGardenResponseWorkflow,
          eventField: _customGardenResponseEventField,
          eventId: created.instanceId,
        )))!;
        expect(
          seededResponses.length,
          accountIds.length,
          reason:
              'Create-action flow should seed all response rows with custom response type.',
        );

        await _selectAgendaById(tester, created.instanceId);
        await _tapRsvpAction(
          tester,
          created.instanceId,
          'make-recurring',
          // count is the TOTAL occurrence count including the anchor itself
          // (RecurrenceRule.count's documented semantics) -- 3 here so the
          // poll below (which expects 3 series events) is satisfied.
          inputs: const {'freq': 'weekly', 'count': '3'},
          awaitSelection: false,
        );

        final seriesEvents = <WorkflowInstance>[];
        await _pollUntilObservation(tester, () async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: _customGardenOrganizerId,
            limit: 500,
          );
          final anchor = page.items
              .where(
                (item) =>
                    item.instanceId == created.instanceId &&
                    item.workflowType == _customGardenEventWorkflow,
              )
              .firstOrNull;
          if (anchor == null) return _PollObservation(false, 'missing anchor');
          final seriesId = anchor.instanceData['seriesId'];
          if (seriesId == null) return _PollObservation(false, 'seriesId missing');
          final events = page.items
              .where(
                (item) =>
                    item.workflowType == _customGardenEventWorkflow &&
                    item.instanceData['seriesId'] == seriesId,
              )
              .toList();
          if (events.length != 3) {
            return _PollObservation(false, 'seriesEventCount=${events.length}');
          }
          seriesEvents
            ..clear()
            ..addAll(events);
          return _PollObservation(
            true,
            'seriesEventCount=${events.length}',
          );
        }, description: 'custom recurring series with seeded siblings');
        for (final event in seriesEvents) {
          final responses = (await tester.runAsync(() => _customResponseRowsForEvent(
            installed,
            responseWorkflowType: _customGardenResponseWorkflow,
            eventField: _customGardenResponseEventField,
            eventId: event.instanceId,
          )))!;
          expect(
            responses.length,
            accountIds.length,
            reason:
                'Recurring custom event ${event.instanceId} should seed custom response rows.',
          );
        }
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'organizer creates an event and one pending response per member',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr3-create'),
      ))!;
      try {
        const testAccounts = <LoomAccount>[
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
        ];
        final auth = activeAuthForCommunity(
          community: installed.community,
          experience: installed.experience,
          personaTypeId: 'tabletop-organizer',
          accounts: testAccounts,
        );
        await tester.pumpWidget(_app(installed, authApi: auth));
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
        await tester.pump();
        await _pumpUntil(tester, find.text('15'));
        await tester.tap(find.text('15').last);
        await tester.pump();
        await _pumpUntil(tester, find.text('OK'));
        await tester.tap(find.text('OK').last);
        await tester.pump();
        final eventTime = find.byKey(
          const ValueKey('new-event-editor-eventTime'),
        );
        await tester.ensureVisible(eventTime);
        await tester.tap(eventTime);
        await tester.pump();
        await _pumpUntil(tester, find.text('OK'));
        await tester.tap(find.text('OK').last);
        await tester.pump();
        final submit = find.byKey(const ValueKey('new-event-submit'));
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        await _pollUntilObservation(tester, () async {
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
        }, description: 'created CALR.3 event');

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
          final accounts = await auth.listAccounts(
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
      await selectTestTabletopPersona(tester, 'tabletop-member');
      await _pollUntilObservation(tester, () async {
        final eventFabCount = find
            .byKey(const ValueKey('creatable-fab-event-rsvp'))
            .evaluate()
            .length;
        final speedDialCount = find
            .byKey(const ValueKey('creatable-fab-speed-dial'))
            .evaluate()
            .length;
        return _PollObservation(
          eventFabCount == 0 && speedDialCount == 0,
          'eventFabMatches=$eventFabCount, speedDialMatches=$speedDialCount',
        );
      }, description: 'member persona hides event creation controls');
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
