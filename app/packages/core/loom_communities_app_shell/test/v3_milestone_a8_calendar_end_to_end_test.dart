import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 24; i++) {
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
    this.registeredAccountIds,
  );
  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final Directory temp;
  final Set<String> registeredAccountIds;

  Future<void> dispose() => temp.delete(recursive: true);
}

class _PollObservation {
  const _PollObservation(this.satisfied, this.state);

  final bool satisfied;
  final String state;
}

/// Real package installation deliberately happens in [tester.runAsync], not in
/// the widget test's fake-async zone. Every scenario owns its extension ID so
/// A.5's memoized shared engine cannot leak persisted state between tests.
Future<_InstalledTabletop> _install(
  String extensionId, {
  void Function(Map<String, dynamic> source)? configure,
  Set<String>? accountIdsToRegister,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  configure?.call(source);
  final temp = await Directory.systemTemp.createTemp('loom-a8-$extensionId-');
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
      specVersion: community.specVersion,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    final registeredAccountIds = <String>{};
    if (engine is LocalWorkflowEngineApi) {
      final accounts = await LocalAuthApi().listAccounts(
        communityExtensionId: 'ext_verify_tabletop_club',
      );
      for (final account in accounts) {
        if (accountIdsToRegister != null &&
            !accountIdsToRegister.contains(account.accountId)) {
          continue;
        }
        engine.setPersonaType(account.accountId, account.personaTypeId);
        registeredAccountIds.add(account.accountId);
      }
    }
    return _InstalledTabletop(
      community,
      experience,
      engine,
      temp,
      Set<String>.unmodifiable(registeredAccountIds),
    );
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

Widget _appShell(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
    authApi: activeAuthForCommunity(
      community: installed.community,
      experience: installed.experience,
      personaTypeId: 'tabletop-organizer',
    ),
  ),
);

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
  ScrollController? scrollController,
  ValueChanged<WorkflowInstance?>? onFocusedInstanceChanged,
}) => MaterialApp(
  home: ActiveIdentityScope(
    identity: ActiveIdentityContext(
      accountId: accountId,
      authApi: authApi ?? LocalAuthApi(),
      personaId: personaId,
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: EngineNativeCalendarSurface(
          key: ValueKey('a8-calendar-$personaId-$revision'),
          experience: installed.experience,
          persona: _persona(installed, personaId),
          accent: Colors.deepPurple,
          modernTheme: null,
          engine: installed.engine,
          onFocusedInstanceChanged: onFocusedInstanceChanged,
        ),
      ),
    ),
  ),
);

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

Finder _actionResultFinder(String instanceId, String transitionId) =>
    switch (transitionId) {
      'respond-going' ||
      'respond-maybe' ||
      'respond-declined' ||
      'respond-waitlist' =>
        transitionId == 'respond-waitlist'
            ? find.byKey(ValueKey('event-rsvp-waitlist-$instanceId'))
            : _selectedActionFinder(instanceId, transitionId),
      'rsvp-withdraw' => find.byKey(
        ValueKey('event-rsvp-$instanceId-action-rsvp-going'),
      ),
      'rsvp-going' => find.byKey(
        ValueKey('event-rsvp-$instanceId-action-rsvp-withdraw'),
      ),
      'cancel-event' => find.byKey(
        ValueKey('engine-native-calendar-selected-detail-$instanceId-1'),
      ),
      _ => throw ArgumentError('No observable result for $transitionId'),
    };

Future<_PollObservation> _observeInstancesCondition(
  _InstalledTabletop installed, {
  required Iterable<String> instanceIds,
  String personaId = 'tabletop-organizer',
  required bool Function(WorkflowInstance) condition,
  required String Function(WorkflowInstance) state,
}) async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: personaId,
    limit: 100,
  );
  final instancesById = <String, WorkflowInstance>{
    for (final item in page.items) item.instanceId: item,
  };
  final observations = <String>[];
  var satisfied = true;
  for (final instanceId in instanceIds) {
    final instance = instancesById[instanceId];
    if (instance == null) {
      satisfied = false;
      observations.add('$instanceId=missing');
      continue;
    }
    final instanceSatisfied = condition(instance);
    satisfied = satisfied && instanceSatisfied;
    observations.add('$instanceId: ${state(instance)}');
  }
  return _PollObservation(satisfied, observations.join('; '));
}

Future<_PollObservation> _observeInstanceCondition(
  _InstalledTabletop installed, {
  required String instanceId,
  String personaId = 'tabletop-organizer',
  required bool Function(WorkflowInstance) condition,
  required String Function(WorkflowInstance) state,
}) => _observeInstancesCondition(
  installed,
  instanceIds: [instanceId],
  personaId: personaId,
  condition: condition,
  state: state,
);

Future<_PollObservation> _observeRecurringEvents(
  _InstalledTabletop installed, {
  required int expectedCount,
  Set<String>? expectedDates,
}) async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: 'tabletop-organizer',
    limit: 100,
  );
  final events = page.items
      .where(
        (item) =>
            item.workflowType == 'event-rsvp' &&
            item.instanceData['seriesId'] != null,
      )
      .toList();
  final dates = events
      .map((event) => event.instanceData['eventDate']?.toString())
      .whereType<String>()
      .toSet();
  final datesMatch = expectedDates == null || dates.containsAll(expectedDates);
  return _PollObservation(
    events.length == expectedCount && datesMatch,
    'seriesCount=${events.length}, dates=$dates',
  );
}

Future<List<WorkflowInstance>> _allCalendarInstances(
  _InstalledTabletop installed,
) async {
  final instances = <WorkflowInstance>[];
  final seenCursors = <String>{};
  String? cursor;
  while (true) {
    final page = await installed.engine.queryInstances(
      tabId: 'calendar',
      personaId: 'tabletop-organizer',
      limit: 100,
      cursor: cursor,
    );
    instances.addAll(page.items);
    if (!page.hasMore) return instances;
    final nextCursor = page.nextCursor;
    if (nextCursor == null ||
        nextCursor.isEmpty ||
        !seenCursors.add(nextCursor)) {
      throw StateError('Calendar pagination returned an invalid cursor.');
    }
    cursor = nextCursor;
  }
}

Future<void> _expectRefused(
  WidgetTester tester,
  Future<void> Function() operation,
) async {
  final refused = (await tester.runAsync(() async {
    try {
      await operation();
      return false;
    } on StateError {
      return true;
    }
  }))!;
  expect(refused, isTrue);
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

Future<void> _tapAction(
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
  final dialog = find.byKey(const ValueKey('generic-transition-input-dialog'));
  final partySizeInput = find.byKey(
    const ValueKey('generic-transition-input-partySize'),
  );
  if (transitionId == 'respond-going') {
    await _pumpUntil(tester, dialog);
    await _pumpUntil(tester, partySizeInput);
  }
  if (dialog.evaluate().isNotEmpty) {
    if (partySizeInput.evaluate().isNotEmpty) {
      await tester.enterText(partySizeInput, (partySize ?? 1).toString());
    }
    final confirm = find.byKey(
      const ValueKey('generic-transition-input-confirm'),
    );
    await _pumpUntil(tester, confirm);
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
  }
  await _pollUntilObservation(
    tester,
    () => _observeFinder(
      _actionResultFinder(instanceId, transitionId),
      'result for $instanceId/$transitionId',
    ),
    description: 'Calendar action $instanceId/$transitionId',
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
  await _pumpUntil(
    tester,
    find.byKey(
      ValueKey('engine-native-calendar-selected-detail-$instanceId-$ordinal'),
    ),
  );
}

Future<void> _selectCalendarTab(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
}

Finder _keyPrefix(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(prefix),
  description: 'key beginning with $prefix',
);

Finder _agendaEntries() => find.byWidgetPredicate(
  (widget) =>
      widget is ListTile &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'engine-native-calendar-agenda-',
      ),
  description: 'Calendar agenda entry',
);

Finder _calendarOrdinal(int ordinal) => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      ((widget.key! as ValueKey<String>).value.startsWith(
            'engine-native-calendar-entry-',
          ) ||
          (widget.key! as ValueKey<String>).value.startsWith(
            'engine-native-calendar-agenda-',
          ) ||
          (widget.key! as ValueKey<String>).value.startsWith(
            'engine-native-calendar-selected-detail-',
          )) &&
      (widget.key! as ValueKey<String>).value.endsWith('-$ordinal'),
  description: 'Calendar binding ordinal $ordinal',
);

void _addScopedCalendarFixture(Map<String, dynamic> source) {
  final experience = source['experience'] as Map<String, dynamic>;
  final definitions = experience['workflowDefinitions'] as Map<String, dynamic>;
  definitions['neighborhood-gathering'] = <String, dynamic>{
    'initialState': 'scheduled',
    'states': <String, dynamic>{
      'scheduled': <String, dynamic>{'label': 'Scheduled'},
    },
    'transitions': <dynamic>[],
    'renderBindings': <dynamic>[
      <String, dynamic>{
        'states': <dynamic>['scheduled'],
        'role': 'any',
        'tabId': 'calendar',
        'cardSurfaceFamily': 'event-rsvp',
        'bindingKind': 'primary',
        'responseTable': <String, dynamic>{
          'workflowType': 'attendance-record',
          'eventField': 'gatheringKey',
          'pendingStates': <dynamic>['awaiting'],
        },
        'filterableFacets': <dynamic>[
          <String, dynamic>{'field': 'featured', 'label': 'Featured'},
          <String, dynamic>{'field': 'neighborhood', 'label': 'Neighborhood'},
          <String, dynamic>{
            'field': 'attendeeTotal',
            'label': 'Gathering attendees',
          },
        ],
      },
    ],
    'instanceDataSchema': <String, dynamic>{
      'title': <String, dynamic>{'type': 'text', 'storage': 'inline'},
      'eventDate': <String, dynamic>{'type': 'date', 'storage': 'inline'},
      'eventTime': <String, dynamic>{'type': 'time', 'storage': 'inline'},
      'attendanceRows': <String, dynamic>{
        'type': 'list',
        'source': 'query(attendance-record where gatheringKey == id)',
      },
      'featured': <String, dynamic>{'type': 'bool', 'storage': 'inline'},
      'neighborhood': <String, dynamic>{'type': 'text', 'storage': 'inline'},
      'attendeeTotal': <String, dynamic>{'type': 'number', 'storage': 'inline'},
    },
  };
  definitions['attendance-record'] = <String, dynamic>{
    'initialState': 'awaiting',
    'states': <String, dynamic>{
      'awaiting': <String, dynamic>{'label': 'Awaiting'},
      'addressed': <String, dynamic>{'label': 'Addressed'},
    },
    'transitions': <dynamic>[],
    'renderBindings': <dynamic>[],
    'instanceDataSchema': <String, dynamic>{
      'gatheringKey': <String, dynamic>{'type': 'text', 'storage': 'inline'},
      'personaId': <String, dynamic>{'type': 'text', 'storage': 'inline'},
    },
  };
  final instances = experience['workflowInstances'] as List<dynamic>;
  instances.addAll(<dynamic>[
    <String, dynamic>{
      'instanceId': 'gathering-sunday',
      'workflowType': 'neighborhood-gathering',
      'currentState': 'scheduled',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'title': 'Sunday gathering',
        'eventDate': '2026-07-12',
        'eventTime': '09:00',
        'featured': true,
        'neighborhood': 'Lakeside',
        'attendeeTotal': 2,
      },
    },
    <String, dynamic>{
      'instanceId': 'gathering-tuesday',
      'workflowType': 'neighborhood-gathering',
      'currentState': 'scheduled',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'title': 'Tuesday gathering',
        'eventDate': '2026-07-14',
        'eventTime': '10:00',
        'featured': false,
        'neighborhood': 'Riverside',
        'attendeeTotal': 3,
      },
    },
    <String, dynamic>{
      'instanceId': 'gathering-saturday',
      'workflowType': 'neighborhood-gathering',
      'currentState': 'scheduled',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'title': 'Saturday gathering',
        'eventDate': '2026-07-18',
        'eventTime': '11:00',
        'featured': false,
        'neighborhood': 'Lakeside',
        'attendeeTotal': 5,
      },
    },
    <String, dynamic>{
      'instanceId': 'attendance-sunday-member',
      'workflowType': 'attendance-record',
      'currentState': 'addressed',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'gatheringKey': 'gathering-sunday',
        'personaId': 'tabletop-member',
      },
    },
    <String, dynamic>{
      'instanceId': 'attendance-saturday-member',
      'workflowType': 'attendance-record',
      'currentState': 'awaiting',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'gatheringKey': 'gathering-saturday',
        'personaId': 'tabletop-member',
      },
    },
  ]);
}

void _addAgendaTileFactFixture(Map<String, dynamic> source) {
  final definitions =
      (source['experience'] as Map<String, dynamic>)['workflowDefinitions']
          as Map<String, dynamic>;
  final schema =
      (definitions['event-rsvp'] as Map<String, dynamic>)['instanceDataSchema']
          as Map<String, dynamic>;
  (schema['location'] as Map<String, dynamic>)['displayContexts'] = <String>[
    'tile',
  ];
  schema['organizerNote'] = <String, dynamic>{
    'type': 'text',
    'storage': 'inline',
    'labelTemplate': '{value}',
  };

  final instances =
      (source['experience'] as Map<String, dynamic>)['workflowInstances']
          as List<dynamic>;
  final friday =
      (instances.firstWhere(
                (instance) =>
                    (instance as Map<String, dynamic>)['instanceId'] ==
                    'event-friday-game-night',
              )
              as Map<String, dynamic>)['instanceData']
          as Map<String, dynamic>;
  friday['organizerNote'] = 'Keep this off the compact row';
}

void _addContainerFixture(Map<String, dynamic> source) {
  final instances =
      (source['experience'] as Map<String, dynamic>)['workflowInstances']
          as List<dynamic>;
  for (final event in const <(String, String, String)>[
    ('event-container-monday', '2026-07-13', 'Monday meetup'),
    ('event-container-tuesday', '2026-07-14', 'Tuesday meetup'),
    ('event-container-saturday', '2026-07-18', 'Saturday meetup'),
    ('event-container-outside-week', '2026-07-21', 'Outside-week meetup'),
  ]) {
    instances.add(<String, dynamic>{
      'instanceId': event.$1,
      'workflowType': 'event-rsvp',
      'currentState': 'open',
      'createdByPersonaId': 'tabletop-organizer',
      'instanceData': <String, dynamic>{
        'title': event.$3,
        'eventDate': event.$2,
        'eventTime': '18:00',
        'location': 'Community room',
        'host': 'Alex Chen (Organizer)',
        'capacity': 20,
      },
    });
  }
}

void _addEditScopeSeriesFixture(Map<String, dynamic> source) {
  final instances =
      (source['experience'] as Map<String, dynamic>)['workflowInstances']
          as List<dynamic>;
  final anchor =
      instances.firstWhere(
            (instance) =>
                (instance as Map<String, dynamic>)['instanceId'] ==
                'event-friday-game-night',
          )
          as Map<String, dynamic>;
  final anchorData = anchor['instanceData'] as Map<String, dynamic>;
  anchorData
    ..['seriesId'] = 'edit-scope-series'
    ..['eventDate'] = '2026-07-17'
    ..['location'] = 'Anchor location';
  for (final sibling in const <(String, String, String)>[
    ('event-edit-scope-earlier', '2026-07-10', 'Earlier location'),
    ('event-edit-scope-later', '2026-07-24', 'Later location'),
  ]) {
    instances.add(<String, dynamic>{
      ...anchor,
      'instanceId': sibling.$1,
      'instanceData': <String, dynamic>{
        ...anchorData,
        'title': sibling.$1,
        'eventDate': sibling.$2,
        'location': sibling.$3,
      },
    });
  }
}

Future<void> _settleMutation(
  WidgetTester tester, {
  required Future<_PollObservation> Function() observe,
  required String description,
}) => _pollUntilObservation(tester, observe, description: description);

Future<void> _saveLocationWithScope(
  WidgetTester tester, {
  required _InstalledTabletop installed,
  required String instanceId,
  required String location,
  required Iterable<String> settledInstanceIds,
  String? scope,
}) async {
  final editor = find.byKey(ValueKey('event-rsvp-editor-$instanceId-location'));
  await _pumpUntil(tester, editor);
  await tester.ensureVisible(editor);
  await tester.enterText(editor, location);
  // enterText updates _edits synchronously, but the Save button remains the
  // previously rendered disabled button until this rebuild runs.
  await tester.pump();
  final save = find.byKey(ValueKey('event-rsvp-save-$instanceId'));
  await tester.ensureVisible(save);
  await tester.pump();
  await tester.tap(save, warnIfMissed: false);
  await tester.pump();
  if (scope != null) {
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('edit-scope-picker-dialog')),
    );
    final scopeOption = find.byKey(ValueKey('edit-scope-picker-$scope'));
    await _pumpUntil(tester, scopeOption);
    await tester.tap(scopeOption);
    await tester.pump();
    final confirm = find.byKey(const ValueKey('edit-scope-picker-confirm'));
    await _pumpUntil(tester, confirm);
    await tester.tap(confirm);
    await tester.pump();
  }
  await _settleMutation(
    tester,
    observe: () => _observeInstancesCondition(
      installed,
      instanceIds: settledInstanceIds,
      condition: (instance) => instance.instanceData['location'] == location,
      state: (instance) =>
          'location=${instance.instanceData['location']}, '
          'state=${instance.currentState}',
    ),
    description: 'location $location on ${settledInstanceIds.join(', ')}',
  );
}

Future<void> _deleteSeriesWithScope(
  WidgetTester tester, {
  required _InstalledTabletop installed,
  required String instanceId,
  required String scope,
  required Iterable<String> settledInstanceIds,
}) async {
  final deleteSeries = find.byKey(
    ValueKey('event-rsvp-delete-series-$instanceId'),
  );
  await _pumpUntil(tester, deleteSeries);
  await tester.ensureVisible(deleteSeries);
  await tester.tap(deleteSeries, warnIfMissed: false);
  await tester.pump();
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('delete-scope-picker-dialog')),
  );
  final scopeOption = find.byKey(ValueKey('delete-scope-picker-$scope'));
  await _pumpUntil(tester, scopeOption);
  await tester.tap(scopeOption);
  await tester.pump();
  final confirm = find.byKey(const ValueKey('delete-scope-picker-confirm'));
  await _pumpUntil(tester, confirm);
  await tester.tap(confirm);
  await tester.pump();
  await _settleMutation(
    tester,
    observe: () => _observeInstancesCondition(
      installed,
      instanceIds: settledInstanceIds,
      condition: (instance) => instance.currentState == 'cancelled',
      state: (instance) => 'currentState=${instance.currentState}',
    ),
    description: 'cancellation of ${settledInstanceIds.join(', ')}',
  );
}

void main() {
  testWidgets(
    'Calendar event detail editors are organizer-only and persist through the engine',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr10a-edit-guard'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final titleEditor = find.byKey(
          const ValueKey('event-rsvp-editor-event-friday-game-night-title'),
        );
        await _pumpUntil(tester, titleEditor);
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-editor-event-friday-game-night-eventDate',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-editor-event-friday-game-night-capacity',
            ),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(titleEditor);
        await tester.enterText(titleEditor, 'Friday game night updated');
        await tester.pump();
        final save = find.byKey(
          const ValueKey('event-rsvp-save-event-friday-game-night'),
        );
        await _pumpUntil(tester, save);
        // The detail card is inside the Calendar's scroll view. The title
        // editor is visible after the preceding ensureVisible call, but Save
        // is below the remaining editors; bring the actual action into view
        // before tapping it so this test exercises the mutation path.
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        final title = find.byKey(
          const ValueKey('event-rsvp-title-event-friday-game-night'),
        );
        await _pollUntilObservation(tester, () async {
          final titleMatches = title.evaluate();
          String? renderedTitle;
          if (titleMatches.length == 1 && titleMatches.single.widget is Text) {
            renderedTitle = (titleMatches.single.widget as Text).data;
          }
          final persisted = await _observeInstanceCondition(
            installed,
            instanceId: 'event-friday-game-night',
            condition: (instance) =>
                instance.instanceData['title'] == 'Friday game night updated',
            state: (instance) =>
                'title=${instance.instanceData['title']}, '
                'currentState=${instance.currentState}',
          );
          return _PollObservation(
            renderedTitle == 'Friday game night updated' && persisted.satisfied,
            'renderedTitle=$renderedTitle; persisted=${persisted.state}',
          );
        }, description: 'rendered and persisted title edit');
        expect(tester.widget<Text>(title).data, 'Friday game night updated');
        expect(
          find.byKey(
            const ValueKey('event-rsvp-error-event-friday-game-night'),
          ),
          findsNothing,
        );
        final updated = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(updated.instanceData['title'], 'Friday game night updated');

        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          _keyPrefix('event-rsvp-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('event-rsvp-save-event-friday-game-night')),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('recurring edit scope saves only the selected occurrence', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () =>
          _install('a8-edit-scope-this', configure: _addEditScopeSeriesFixture),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _saveLocationWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        location: 'This event location',
        settledInstanceIds: const ['event-friday-game-night'],
        scope: 'thisEvent',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-earlier',
        )).instanceData['location'],
        'Earlier location',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-friday-game-night',
        )).instanceData['location'],
        'This event location',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-later',
        )).instanceData['location'],
        'Later location',
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('recurring edit scope saves this and following occurrences', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install(
        'a8-edit-scope-following',
        configure: _addEditScopeSeriesFixture,
      ),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _saveLocationWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        location: 'Following location',
        settledInstanceIds: const [
          'event-friday-game-night',
          'event-edit-scope-later',
        ],
        scope: 'thisAndFollowing',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-earlier',
        )).instanceData['location'],
        'Earlier location',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-friday-game-night',
        )).instanceData['location'],
        'Following location',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-later',
        )).instanceData['location'],
        'Following location',
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('recurring edit scope saves every occurrence in the series', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () =>
          _install('a8-edit-scope-all', configure: _addEditScopeSeriesFixture),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _saveLocationWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        location: 'Series location',
        settledInstanceIds: const [
          'event-edit-scope-earlier',
          'event-friday-game-night',
          'event-edit-scope-later',
        ],
        scope: 'all',
      );
      for (final instanceId in const [
        'event-edit-scope-earlier',
        'event-friday-game-night',
        'event-edit-scope-later',
      ]) {
        expect(
          (await _instance(
            tester,
            installed,
            instanceId,
          )).instanceData['location'],
          'Series location',
        );
      }
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('single-event edits do not show a recurring edit scope picker', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a8-edit-scope-none'),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _saveLocationWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        location: 'Single event location',
        settledInstanceIds: const ['event-friday-game-night'],
      );
      expect(
        find.byKey(const ValueKey('edit-scope-picker-dialog')),
        findsNothing,
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-friday-game-night',
        )).instanceData['location'],
        'Single event location',
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('recurring delete scope cancels only the selected occurrence', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install(
        'a8-delete-scope-this',
        configure: _addEditScopeSeriesFixture,
      ),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _deleteSeriesWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        scope: 'thisEvent',
        settledInstanceIds: const ['event-friday-game-night'],
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-earlier',
        )).currentState,
        'open',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-friday-game-night',
        )).currentState,
        'cancelled',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-later',
        )).currentState,
        'open',
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('recurring delete scope cancels this and following occurrences', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install(
        'a8-delete-scope-following',
        configure: _addEditScopeSeriesFixture,
      ),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _deleteSeriesWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        scope: 'thisAndFollowing',
        settledInstanceIds: const [
          'event-friday-game-night',
          'event-edit-scope-later',
        ],
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-earlier',
        )).currentState,
        'open',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-friday-game-night',
        )).currentState,
        'cancelled',
      );
      expect(
        (await _instance(
          tester,
          installed,
          'event-edit-scope-later',
        )).currentState,
        'cancelled',
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('recurring delete scope cancels every occurrence', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install(
        'a8-delete-scope-all',
        configure: _addEditScopeSeriesFixture,
      ),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _deleteSeriesWithScope(
        tester,
        installed: installed,
        instanceId: 'event-friday-game-night',
        scope: 'all',
        settledInstanceIds: const [
          'event-edit-scope-earlier',
          'event-friday-game-night',
          'event-edit-scope-later',
        ],
      );
      for (final instanceId in const [
        'event-edit-scope-earlier',
        'event-friday-game-night',
        'event-edit-scope-later',
      ]) {
        expect(
          (await _instance(tester, installed, instanceId)).currentState,
          'cancelled',
        );
      }
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'Make recurring creates calendar occurrences and seeds every RSVP response row',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-make-recurring'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final action = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-make-recurring',
          ),
        );
        await _pumpUntil(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('generic-transition-input-dialog')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-freq')),
          'weekly',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-count')),
          '3',
        );
        await tester.tap(
          find.byKey(
            const ValueKey('generic-transition-input-byDayOfWeekWeekly-FR'),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-confirm')),
        );
        await _pollUntilObservation(
          tester,
          () => _observeRecurringEvents(
            installed,
            expectedCount: 3,
            expectedDates: const {'2026-07-10', '2026-07-17', '2026-07-24'},
          ),
          description: 'weekly recurring events',
        );

        final events = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          final anchor = page.items.singleWhere(
            (item) => item.instanceId == 'event-friday-game-night',
          );
          return page.items
              .where(
                (item) =>
                    item.workflowType == 'event-rsvp' &&
                    item.instanceData['seriesId'] ==
                        anchor.instanceData['seriesId'],
              )
              .toList();
        }))!;
        expect(events, hasLength(3));
        expect(
          events.map((event) => event.instanceData['eventDate']).toSet(),
          containsAll(<String>['2026-07-10', '2026-07-17', '2026-07-24']),
        );
        final accountIds = installed.registeredAccountIds;
        expect(accountIds, hasLength(13));
        for (final event in events.where(
          (event) => event.instanceId != 'event-friday-game-night',
        )) {
          await _pumpUntil(
            tester,
            _keyPrefix('engine-native-calendar-entry-${event.instanceId}-'),
          );
          final responses = (await tester.runAsync(() async {
            final page = await installed.engine.queryInstances(
              tabId: 'calendar',
              personaId: 'tabletop-organizer',
              limit: 100,
            );
            return page.items
                .where(
                  (item) =>
                      item.workflowType == 'event-rsvp-response' &&
                      item.instanceData['eventId'] == event.instanceId,
                )
                .toList();
          }))!;
          expect(responses, hasLength(13));
          expect(
            responses
                .map((response) => response.instanceData['personaId'])
                .toSet(),
            accountIds,
          );
        }
        expect(action, findsNothing);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Make recurring creates no duplicate event/persona response pairs',
    (tester) async {
      const accounts = <LoomAccount>[
        LoomAccount(
          accountId: 'tabletop-organizer',
          displayName: 'Alex T.',
          personaTypeId: 'tabletop-organizer',
        ),
        LoomAccount(
          accountId: 'tabletop-member-04',
          displayName: 'Sam K.',
          personaTypeId: 'tabletop-member',
        ),
      ];
      final installed = (await tester.runAsync(
        () => _install(
          'a8-make-recurring-unique-responses',
          accountIdsToRegister: {
            for (final account in accounts) account.accountId,
          },
        ),
      ))!;
      final auth = activeAuthForCommunity(
        community: installed.community,
        experience: installed.experience,
        accountId: 'tabletop-organizer',
        accounts: accounts,
      );
      try {
        expect(installed.registeredAccountIds, hasLength(2));
        expect(
          await tester.runAsync(
            () => auth.listAccounts(
              communityExtensionId: installed.community.extensionId,
            ),
          ),
          hasLength(2),
        );
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-organizer',
            accountId: 'tabletop-organizer',
            authApi: auth,
          ),
        );
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final action = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-make-recurring',
          ),
        );
        await _pumpUntil(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('generic-transition-input-dialog')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-freq')),
          'weekly',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-count')),
          '3',
        );
        await tester.tap(
          find.byKey(
            const ValueKey('generic-transition-input-byDayOfWeekWeekly-FR'),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-confirm')),
        );
        await _pollUntilObservation(
          tester,
          () => _observeRecurringEvents(
            installed,
            expectedCount: 3,
            expectedDates: const {'2026-07-10', '2026-07-17', '2026-07-24'},
          ),
          description: 'weekly recurring events for response uniqueness',
        );

        final seriesRows = (await tester.runAsync(() async {
          final rows = await _allCalendarInstances(installed);
          final anchor = rows.singleWhere(
            (row) => row.instanceId == 'event-friday-game-night',
          );
          final seriesId = anchor.instanceData['seriesId'];
          final events = rows
              .where(
                (row) =>
                    row.workflowType == 'event-rsvp' &&
                    row.instanceData['seriesId'] == seriesId,
              )
              .toList();
          final eventIds = events.map((event) => event.instanceId).toSet();
          final responses = rows
              .where(
                (row) =>
                    row.workflowType == 'event-rsvp-response' &&
                    eventIds.contains(row.instanceData['eventId']),
              )
              .toList();
          return (events: events, responses: responses);
        }))!;
        expect(
          seriesRows.events
              .where((event) => event.instanceId != 'event-friday-game-night')
              .toList(),
          hasLength(2),
        );
        expect(
          seriesRows.responses.any(
            (response) =>
                response.instanceData['eventId'] == 'event-friday-game-night',
          ),
          isTrue,
        );
        final responsePairs = seriesRows.responses
            .map(
              (response) => (
                eventId: response.instanceData['eventId'] as String,
                personaId: response.instanceData['personaId'] as String,
              ),
            )
            .toList();
        expect(responsePairs.toSet(), hasLength(responsePairs.length));
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Make recurring uses the final monthly weekday-position chip values',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final installed = (await tester.runAsync(
        () => _install('a8-monthly-weekday-position'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final action = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-make-recurring',
          ),
        );
        await _pumpUntil(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('generic-transition-input-dialog')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-freq')),
          'monthly',
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey(
              'generic-transition-input-mode-monthlyPattern-lastOrNthWeekday',
            ),
          ),
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-count')),
          '3',
        );
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-bySetPos-third')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-bySetPos-last')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey('generic-transition-input-byDayOfWeekMonthly-FR'),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey('generic-transition-input-byDayOfWeekMonthly-WE'),
          ),
        );
        await tester.pump();

        final confirm = find.byKey(
          const ValueKey('generic-transition-input-confirm'),
        );
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await _pollUntilObservation(
          tester,
          () => _observeRecurringEvents(
            installed,
            expectedCount: 3,
            expectedDates: const {'2026-07-10', '2026-08-26', '2026-09-30'},
          ),
          description: 'monthly weekday-position recurring events',
        );

        final dates = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return page.items
              .where(
                (item) =>
                    item.workflowType == 'event-rsvp' &&
                    item.instanceData['seriesId'] != null,
              )
              .map((item) => item.instanceData['eventDate'])
              .toList();
        }))!;
        // Last Wednesday proves the final (rather than initial or first changed)
        // ordinal and weekday values were passed to applyTransition.
        expect(dates, hasLength(3));
        expect(
          dates,
          containsAll(<String>['2026-07-10', '2026-08-26', '2026-09-30']),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Make recurring creates monthly day-of-month occurrences through generic inputs',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-monthly-day-of-month'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        final action = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-make-recurring',
          ),
        );
        await _pumpUntil(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('generic-transition-input-dialog')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-freq')),
          'monthly',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-count')),
          '3',
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-byMonthDay')),
          '15',
        );
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-confirm')),
        );
        await _pollUntilObservation(
          tester,
          () => _observeRecurringEvents(
            installed,
            expectedCount: 3,
            expectedDates: const {'2026-07-10', '2026-08-15', '2026-09-15'},
          ),
          description: 'monthly day-of-month recurring events',
        );

        final dates = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return page.items
              .where(
                (item) =>
                    item.workflowType == 'event-rsvp' &&
                    item.instanceData['seriesId'] != null,
              )
              .map((item) => item.instanceData['eventDate'])
              .toList();
        }))!;
        expect(dates, hasLength(3));
        expect(
          dates,
          containsAll(<String>['2026-07-10', '2026-08-15', '2026-09-15']),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Calendar event detail stays closed when editable fields have no editGuard',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install(
          'calr10a-no-edit-guard',
          configure: (source) {
            final definitions =
                (source['experience']
                        as Map<String, dynamic>)['workflowDefinitions']
                    as Map<String, dynamic>;
            final states =
                (definitions['event-rsvp'] as Map<String, dynamic>)['states']
                    as Map<String, dynamic>;
            (states['open'] as Map<String, dynamic>).remove('editGuard');
          },
        ),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          _keyPrefix('event-rsvp-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('event-rsvp-save-event-friday-game-night')),
          findsNothing,
        );
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          _keyPrefix('event-rsvp-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('event-rsvp-save-event-friday-game-night')),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('projects the frozen Calendar into its native product structure', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a8-structure')))!;
    try {
      expect(installed.experience.workflows, isEmpty);
      expect(
        appShellTabsFor(
          experience: installed.experience,
          personaId: 'tabletop-member',
        ).map((tab) => tab.tabId),
        contains('calendar'),
      );
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-member', revision: 1),
      );
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-root')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-month-navigation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-date-strip')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-date-strip-2026-07-10'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-grouped-agenda')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-entry-event-summer-tournament-0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-entry-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-summer-tournament-0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
      final julyDay = find.byKey(
        const ValueKey('engine-native-calendar-date-2026-07-10'),
      );
      expect(julyDay, findsOneWidget);
      expect(
        find.descendant(
          of: julyDay,
          matching: _keyPrefix('engine-native-calendar-entry-event-'),
        ),
        findsNWidgets(2),
      );
      expect(find.textContaining('responses'), findsNothing);
      expect(find.textContaining('responseCounts'), findsNothing);
      expect(find.textContaining('maybeCount'), findsNothing);
      expect(find.textContaining('declinedCount'), findsNothing);
      expect(find.textContaining('waitlistedCount'), findsNothing);
      expect(find.textContaining('isFull'), findsNothing);
      expect(find.textContaining('quorumMet'), findsNothing);

      final group = find.byKey(
        const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
      );
      expect(group, findsOneWidget);
      final agendaDate = find.descendant(
        of: group,
        matching: find.byKey(
          const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
        ),
      );
      expect(agendaDate, findsOneWidget);
      expect(
        find.descendant(
          of: group,
          matching: _keyPrefix('engine-native-calendar-agenda-event-'),
        ),
        findsNWidgets(2),
      );
      expect(_calendarOrdinal(1), findsNothing);

      final rows = find
          .descendant(of: group, matching: find.byType(ListTile))
          .evaluate()
          .toList();
      expect(rows, hasLength(2));
      expect((rows[0].widget as ListTile).title, isA<Text>());
      expect(
        ((rows[0].widget as ListTile).title! as Text).data,
        'Summer tournament',
      );
      expect(
        ((rows[1].widget as ListTile).title! as Text).data,
        'Friday game night',
      );
      expect(
        tester.getTopLeft(agendaDate).dx,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(
                  const ValueKey(
                    'engine-native-calendar-agenda-event-summer-tournament-0',
                  ),
                ),
              )
              .dx,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-next-month')),
      );
      await tester.pump();
      expect(find.text('Aug 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          matching: _keyPrefix('engine-native-calendar-entry-event-'),
        ),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-previous-month')),
      );
      await tester.pump();
      expect(find.text('Jul 2026'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          matching: _keyPrefix('engine-native-calendar-entry-event-'),
        ),
        findsNWidgets(2),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('engine-native-calendar-date-strip-2026-07-10'),
        ),
      );
      await tester.pump();
      expect(find.text('Jul 2026'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(
                const ValueKey('engine-native-calendar-date-strip-2026-07-10'),
              ),
            )
            .selected,
        isTrue,
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
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
      final fridayDetail = find.byKey(
        const ValueKey(
          'engine-native-calendar-selected-detail-event-friday-game-night-0',
        ),
      );
      expect(
        find.descendant(of: group, matching: fridayDetail),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(fridayDetail).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.byKey(
                  const ValueKey(
                    'engine-native-calendar-agenda-event-friday-game-night-0',
                  ),
                ),
              )
              .dy,
        ),
      );
      expect(find.text('11 / 20 going'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-summer-tournament-0',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('event-rsvp-card-event-friday-game-night')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-summer-tournament-0',
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-summer-tournament-0',
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-summer-tournament-0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-facts-event-summer-tournament-0',
          ),
        ),
        findsNothing,
      );
      expect(find.text('Selected game: TBD'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-friday-game-night-0',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('event-rsvp-card-event-summer-tournament')),
        findsOneWidget,
      );

      final layers = <Finder>[
        find.byKey(const ValueKey('engine-native-calendar-month-navigation')),
        find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        find.byKey(const ValueKey('engine-native-calendar-date-strip')),
        group,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-summer-tournament-0',
          ),
        ),
      ];
      final verticalOffsets = layers
          .map((finder) => tester.getTopLeft(finder).dy)
          .toList();
      for (var index = 1; index < verticalOffsets.length; index++) {
        expect(verticalOffsets[index], greaterThan(verticalOffsets[index - 1]));
      }
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('agenda rows render only explicit tile-context fact pills', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('calr9a-tile-facts', configure: _addAgendaTileFactFixture),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      final agenda = find.byKey(
        const ValueKey(
          'engine-native-calendar-agenda-event-friday-game-night-0',
        ),
      );
      await _pumpUntil(tester, agenda);

      expect(
        find.descendant(of: agenda, matching: find.text('Friday game night')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: agenda, matching: find.text('19:00')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-facts-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: agenda, matching: find.text('Community room')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: agenda,
          matching: find.text('Host: Alex Chen (Organizer)'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: agenda,
          matching: find.text('Keep this off the compact row'),
        ),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'scopes Calendar entries by date range and generic response tables',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr5a-scopes', configure: _addScopedCalendarFixture),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );

        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('calendar-scope-month')),
              )
              .selected,
          isTrue,
        );
        expect(_agendaEntries().evaluate(), hasLength(5));

        await tester.tap(
          find.byKey(
            const ValueKey('engine-native-calendar-date-strip-2026-07-14'),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('calendar-scope-day')));
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsNothing,
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-gathering-saturday-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
          findsNothing,
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-month')));
        await tester.pump();
        expect(_agendaEntries().evaluate(), hasLength(5));

        await tester.tap(find.byKey(const ValueKey('calendar-scope-pending')));
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-gathering-saturday-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
          findsNothing,
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-month')));
        await tester.pump();
        final tuesdayCellEntry = find.byKey(
          const ValueKey('engine-native-calendar-entry-gathering-tuesday-0'),
        );
        await tester.ensureVisible(tuesdayCellEntry);
        await tester.tap(tuesdayCellEntry);
        await tester.pump();
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('calendar-scope-day')),
              )
              .selected,
          isTrue,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'reshapes Calendar containers for Week, Day, Month, and Pending scopes',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr6a-containers', configure: _addContainerFixture),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );

        await tester.tap(
          find.byKey(
            const ValueKey('engine-native-calendar-date-strip-2026-07-14'),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-week-strip')),
          findsOneWidget,
        );
        final weekCells = <String>[
          '2026-07-13',
          '2026-07-14',
          '2026-07-15',
          '2026-07-16',
          '2026-07-17',
          '2026-07-18',
          '2026-07-19',
        ];
        for (final date in weekCells) {
          expect(
            find.byKey(ValueKey('engine-native-calendar-week-cell-$date')),
            findsOneWidget,
          );
        }
        expect(
          _keyPrefix('engine-native-calendar-week-cell-').evaluate(),
          hasLength(7),
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-day')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-week-strip')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-month')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-week-strip')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsNothing,
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-pending')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-week-strip')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('projects a multi-day event into Month, Week, and Day dates', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install(
        'calr24-multi-day',
        configure: (source) {
          final instances =
              (source['experience']
                      as Map<String, dynamic>)['workflowInstances']
                  as List<dynamic>;
          final friday = instances.cast<Map<String, dynamic>>().firstWhere(
            (instance) => instance['instanceId'] == 'event-friday-game-night',
          );
          (friday['instanceData'] as Map<String, dynamic>)['eventEndDate'] =
              '2026-07-12';
        },
      ),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-month-grid')),
      );
      for (final day in ['2026-07-10', '2026-07-11', '2026-07-12']) {
        final cell = find.byKey(ValueKey('engine-native-calendar-date-$day'));
        expect(cell, findsOneWidget);
        expect(
          find.descendant(of: cell, matching: find.text('Friday game night')),
          findsOneWidget,
        );
      }

      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-date-2026-07-11')),
      );
      await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('engine-native-calendar-week-cell-2026-07-11'),
          ),
          matching: find.text('Friday game night'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-11'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('calendar-scope-day')));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('engine-native-calendar-agenda-group-2026-07-11'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'places Calendar scope selector before the active scope container',
    (tester) async {
      final installed = (await tester.runAsync(
        () =>
            _install('calr7b-scope-selector', configure: _addContainerFixture),
      ))!;
      final selectorRow = find
          .ancestor(
            of: find.byKey(const ValueKey('calendar-scope-day')),
            matching: find.byType(Row),
          )
          .first;

      void expectSelectorBefore(Finder container) {
        expect(
          tester.getTopLeft(selectorRow).dy,
          lessThan(tester.getTopLeft(container).dy),
        );
      }

      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );
        expectSelectorBefore(
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();
        expectSelectorBefore(
          find.byKey(const ValueKey('engine-native-calendar-week-navigation')),
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-day')));
        await tester.pump();
        expectSelectorBefore(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
        );

        await tester.tap(find.byKey(const ValueKey('calendar-scope-pending')));
        await tester.pump();
        expect(
          tester.getTopLeft(selectorRow).dy,
          lessThan(
            tester
                .getTopLeft(
                  find.byKey(
                    const ValueKey('engine-native-calendar-grouped-agenda'),
                  ),
                )
                .dy,
          ),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'navigates Week by full weeks with native previous and next buttons',
    (tester) async {
      final installed = (await tester.runAsync(
        () =>
            _install('calr7a-week-navigation', configure: _addContainerFixture),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );

        await tester.tap(
          find.byKey(
            const ValueKey('engine-native-calendar-date-strip-2026-07-14'),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('engine-native-calendar-previous-week')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('engine-native-calendar-next-week')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-week-cell-2026-07-13'),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('engine-native-calendar-next-week')),
        );
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-week-cell-2026-07-13'),
          ),
          findsNothing,
        );
        for (final date in <String>[
          '2026-07-20',
          '2026-07-21',
          '2026-07-22',
          '2026-07-23',
          '2026-07-24',
          '2026-07-25',
          '2026-07-26',
        ]) {
          expect(
            find.byKey(ValueKey('engine-native-calendar-week-cell-$date')),
            findsOneWidget,
          );
        }

        await tester.tap(
          find.byKey(const ValueKey('engine-native-calendar-previous-week')),
        );
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-week-cell-2026-07-13'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-week-cell-2026-07-20'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'opens Day for empty month and week cells while entry titles select details',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr6b-day-cells', configure: _addContainerFixture),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );

        final emptyMonthCell = find.byKey(
          const ValueKey('engine-native-calendar-date-2026-07-15'),
        );
        await tester.ensureVisible(emptyMonthCell);
        await tester.tap(emptyMonthCell);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsOneWidget,
        );
        expect(find.text('Jul 15, 2026'), findsOneWidget);
        expect(_agendaEntries(), findsNothing);

        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();
        final emptyWeekCell = find.byKey(
          const ValueKey('engine-native-calendar-week-cell-2026-07-16'),
        );
        await tester.ensureVisible(emptyWeekCell);
        await tester.tap(emptyWeekCell);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsOneWidget,
        );
        expect(find.text('Jul 16, 2026'), findsOneWidget);
        expect(_agendaEntries(), findsNothing);

        await tester.tap(find.byKey(const ValueKey('calendar-scope-week')));
        await tester.pump();
        final tuesdayEntry = find.byKey(
          const ValueKey(
            'engine-native-calendar-entry-event-container-tuesday-0',
          ),
        );
        await tester.ensureVisible(tuesdayEntry);
        await tester.tap(tuesdayEntry);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('engine-native-calendar-day-header')),
          findsOneWidget,
        );
        expect(find.text('Jul 14, 2026'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-container-tuesday-0',
            ),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'filters declared boolean facets without affecting other bindings and aggregates scoped stats',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr5b-facets', configure: _addScopedCalendarFixture),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );

        final featured = find.byKey(const ValueKey('calendar-facet-featured'));
        await tester.ensureVisible(featured);
        expect(featured, findsOneWidget);
        expect(
          find.byKey(const ValueKey('calendar-facet-stat-attendeeTotal')),
          findsOneWidget,
        );
        expect(find.text('Gathering attendees: 10'), findsOneWidget);

        final tuesday = find.byKey(
          const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
        );
        await tester.ensureVisible(tuesday);
        await tester.tap(tuesday);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-gathering-tuesday-0',
            ),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(featured);
        await tester.tap(featured);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-gathering-tuesday-0',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(featured);
        await tester.pump();
        final date = find.byKey(
          const ValueKey('engine-native-calendar-date-strip-2026-07-14'),
        );
        await tester.ensureVisible(date);
        await tester.tap(date);
        final day = find.byKey(const ValueKey('calendar-scope-day'));
        await tester.ensureVisible(day);
        await tester.tap(day);
        await tester.pump();
        expect(find.text('Gathering attendees: 3'), findsOneWidget);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'filters text facets by one value at a time and combines them with boolean facets',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install(
          'cal-category-filter',
          configure: _addScopedCalendarFixture,
        ),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );

        final lakeside = find.byKey(
          const ValueKey('calendar-facet-value-neighborhood-Lakeside'),
        );
        final riverside = find.byKey(
          const ValueKey('calendar-facet-value-neighborhood-Riverside'),
        );
        await tester.ensureVisible(lakeside);
        expect(lakeside, findsOneWidget);
        expect(riverside, findsOneWidget);

        await tester.tap(lakeside);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-gathering-saturday-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsNothing,
        );

        await tester.tap(riverside);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsOneWidget,
        );

        await tester.tap(riverside);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsOneWidget,
        );

        await tester.tap(lakeside);
        await tester.pump();
        final featured = find.byKey(const ValueKey('calendar-facet-featured'));
        await tester.ensureVisible(featured);
        await tester.tap(featured);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-sunday-0'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-gathering-saturday-0',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-gathering-tuesday-0'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'App Shell selects the frozen engine-native Calendar through its shared engine',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-app-shell'),
      ))!;
      try {
        await tester.pumpWidget(_appShell(installed));
        await _selectCalendarTab(tester);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );
        expect(
          find.byKey(const ValueKey('calendar-tab-surface')),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('repairs a real projection error and Retry re-queries Calendar', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a8-projection-retry'),
    ))!;
    try {
      await tester.runAsync(
        () => installed.engine.updateInstanceFields(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          fieldUpdates: const {'eventDate': 'not-a-date'},
          personaId: 'tabletop-organizer',
        ),
      );
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-projection-error-calendar::event-friday-game-night::0',
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-projection-retry')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-root')),
        findsNothing,
      );
      await tester.runAsync(
        () => installed.engine.updateInstanceFields(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          fieldUpdates: const {'eventDate': '2026-07-10'},
          personaId: 'tabletop-organizer',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-projection-retry')),
      );
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-root')),
      );
      expect(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('renders the explicit empty Calendar state with a real engine', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a8-empty-definitions'),
    ))!;
    final database = WorkflowDatabase.memory();
    final engine = LocalWorkflowEngineApi(
      db: database,
      communityId: 'a8-empty-calendar',
    );
    for (final definition in installed.experience.workflowDefinitions!.values) {
      engine.registerDefinition(definition);
    }
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveIdentityScope(
            identity: ActiveIdentityContext(
              accountId: null,
              authApi: LocalAuthApi(),
              personaId: 'tabletop-member',
            ),
            child: Scaffold(
              body: EngineNativeCalendarSurface(
                experience: installed.experience,
                persona: _persona(installed, 'tabletop-member'),
                accent: Colors.deepPurple,
                modernTheme: null,
                engine: engine,
              ),
            ),
          ),
        ),
      );
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-empty')),
      );
      expect(
        find.byKey(const ValueKey('engine-native-calendar-root')),
        findsNothing,
      );
      expect(find.byType(GenericWorkflowInstanceCard), findsNothing);
    } finally {
      database.close();
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'Calendar reports its default and explicitly selected focused instances',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-focused-instance-callback'),
      ))!;
      final focusedInstances = <WorkflowInstance?>[];
      try {
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-member',
            onFocusedInstanceChanged: focusedInstances.add,
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
        );
        await tester.pump();

        expect(focusedInstances, hasLength(1));
        expect(focusedInstances.single?.instanceId, 'event-summer-tournament');

        final fridayEntry = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        );
        await tester.ensureVisible(fridayEntry);
        await tester.tap(fridayEntry);
        await tester.pump();

        expect(focusedInstances, hasLength(2));
        expect(focusedInstances.last?.instanceId, 'event-friday-game-night');
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Friday Calendar actions persist exclusive RSVP formulas and refresh detail',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-friday-actions'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
        );
        final fridayAgendaEntry = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'event-rsvp-event-summer-tournament-action-rsvp-going',
            ),
          ),
        );
        await tester.ensureVisible(fridayAgendaEntry);
        await _pumpUntil(tester, fridayAgendaEntry);
        await tester.tap(fridayAgendaEntry);
        await _tapAction(tester, 'event-friday-game-night', 'respond-going');
        final going = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(_responseFor(going, 'tabletop-organizer')['\$state'], 'going');
        expect(going.instanceData['goingCount'], 12);
        expect(going.instanceData['seatsRemaining'], 8);
        await _pumpUntil(tester, find.text('12 / 20 going'));
        expect(find.text('12 / 20 going'), findsOneWidget);
        expect(find.text('8 seats left'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-summer-tournament-0',
            ),
          ),
          findsNothing,
        );
        await _tapAction(tester, 'event-friday-game-night', 'respond-maybe');
        final maybe = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(_responseFor(maybe, 'tabletop-organizer')['\$state'], 'maybe');
        expect(maybe.instanceData['goingCount'], 11);
        expect(maybe.instanceData['seatsRemaining'], 9);
        await _pumpUntil(tester, find.text('11 / 20 going'));
        expect(find.text('11 / 20 going'), findsOneWidget);
        expect(find.text('9 seats left'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        await _tapAction(tester, 'event-friday-game-night', 'respond-declined');
        final no = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(_responseFor(no, 'tabletop-organizer')['\$state'], 'declined');
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'Calendar RSVP refresh keeps the outer scroll position for a lower event',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('as2-calendar-scroll'),
      ))!;
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      try {
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-organizer',
            scrollController: scrollController,
          ),
        );
        final fridayAgendaEntry = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        );
        await _pumpUntil(tester, fridayAgendaEntry);
        await tester.ensureVisible(fridayAgendaEntry);
        await tester.tap(fridayAgendaEntry);
        final action = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-respond-going',
          ),
        );
        await _pumpUntil(tester, action);
        await tester.ensureVisible(action);
        await tester.pump();
        expect(scrollController.offset, greaterThan(0));

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
            await tester.enterText(partySizeInput, '1');
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
            _selectedActionFinder('event-friday-game-night', 'respond-going'),
            'selected Going action',
          ),
          description: 'Going action UI state',
        );

        expect(scrollController.offset, greaterThan(0));
        final going = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(_responseFor(going, 'tabletop-organizer')['\$state'], 'going');
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('Calendar RSVP shows dietary notes below the attendee name', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a8-rsvp-dietary-notes'),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      final action = find.byKey(
        const ValueKey(
          'event-rsvp-event-friday-game-night-action-respond-going',
        ),
      );
      await _pumpUntil(tester, action);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pump();
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('generic-transition-input-dialog')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-dietaryNotes')),
        'Vegetarian',
      );
      final partySizeInput = find.byKey(
        const ValueKey('generic-transition-input-partySize'),
      );
      if (partySizeInput.evaluate().isNotEmpty) {
        await tester.enterText(partySizeInput, '1');
      }
      final confirm = find.byKey(
        const ValueKey('generic-transition-input-confirm'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-attendee-dietary-tabletop-organizer'),
        ),
      );

      final attendees = find.byKey(
        const ValueKey('event-rsvp-attendees-event-friday-game-night'),
      );
      expect(
        find.descendant(of: attendees, matching: find.text('Vegetarian')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('event-rsvp-attendee-dietary-tabletop-organizer'),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets(
    'fullness guard auto-promotes a waitlisted member through Calendar UI',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('a8-fullness')))!;
      try {
        await tester.runAsync(() async {
          await installed.engine.updateInstanceFields(
            workflowType: 'event-rsvp',
            instanceId: 'event-friday-game-night',
            fieldUpdates: const {'capacity': 11},
            personaId: 'tabletop-organizer',
          );
        });
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
        final full = await _instance(
          tester,
          installed,
          'event-friday-game-night',
          personaId: 'tabletop-member-14',
        );
        expect(full.instanceData['goingCount'], 11);
        expect(full.instanceData['seatsRemaining'], 0);
        expect(full.instanceData['isFull'], isTrue);
        await _tapAction(tester, 'event-friday-game-night', 'respond-waitlist');
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
        await tester.runAsync(
          () => installed.engine.applyTransition(
            workflowType: 'event-rsvp-response',
            instanceId: 'resp-friday-member-03',
            transitionId: 'respond-declined',
            personaId: 'tabletop-member-03',
          ),
        );
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-member',
            revision: 3,
            accountId: 'tabletop-member-14',
          ),
        );
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-respond-maybe',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-respond-declined',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-respond-waitlist',
            ),
          ),
          findsNothing,
        );
        final open = await _instance(
          tester,
          installed,
          'event-friday-game-night',
          personaId: 'tabletop-member-14',
        );
        expect(_responseFor(open, 'tabletop-member-14')['\$state'], 'going');
        expect(open.instanceData['goingCount'], 11);
        expect(open.instanceData['seatsRemaining'], 0);
        expect(open.instanceData['isFull'], isTrue);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'tournament actor-in-list guard and withdrawal are enforced through Calendar',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-tournament'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
        );
        await tester.ensureVisible(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
        );
        await tester.tap(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
        );
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
        await _expectRefused(tester, () async {
          await installed.engine.applyTransition(
            workflowType: 'tournament-event',
            instanceId: 'event-summer-tournament',
            transitionId: 'rsvp-going',
            personaId: 'tabletop-member',
          );
        });
        await _tapAction(tester, 'event-summer-tournament', 'rsvp-withdraw');
        final withdrawn = await _instance(
          tester,
          installed,
          'event-summer-tournament',
          personaId: 'tabletop-member',
        );
        expect(
          withdrawn.instanceData['goingPersonaIds'],
          isNot(contains('tabletop-member')),
        );
        expect(withdrawn.instanceData['accepted'], 7);
        expect(withdrawn.instanceData['quorumMet'], isFalse);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'event-rsvp-event-summer-tournament-action-rsvp-going',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-event-summer-tournament-action-rsvp-withdraw',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-summer-tournament-0',
            ),
          ),
          findsOneWidget,
        );
        await _tapAction(tester, 'event-summer-tournament', 'rsvp-going');
        final restored = await _instance(
          tester,
          installed,
          'event-summer-tournament',
          personaId: 'tabletop-member',
        );
        expect(
          restored.instanceData['goingPersonaIds'],
          contains('tabletop-member'),
        );
        expect(restored.instanceData['accepted'], 8);
        expect(restored.instanceData['quorumMet'], isTrue);
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
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-summer-tournament-0',
            ),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'organizers can delete a recurring series while members and single events cannot',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-delete-recurring-series'),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          find.byKey(
            const ValueKey('event-rsvp-delete-series-event-friday-game-night'),
          ),
          findsNothing,
        );

        final makeRecurring = find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-make-recurring',
          ),
        );
        await _pumpUntil(tester, makeRecurring);
        await tester.ensureVisible(makeRecurring);
        await tester.tap(makeRecurring);
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('generic-transition-input-dialog')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-freq')),
          'weekly',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('generic-transition-input-count')),
          '3',
        );
        await tester.tap(
          find.byKey(
            const ValueKey('generic-transition-input-byDayOfWeekWeekly-FR'),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('generic-transition-input-confirm')),
        );
        await _pollUntilObservation(
          tester,
          () => _observeRecurringEvents(
            installed,
            expectedCount: 3,
            expectedDates: const {'2026-07-10', '2026-07-17', '2026-07-24'},
          ),
          description: 'recurring events before series deletion',
        );

        final seriesMembers = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          final anchor = page.items.singleWhere(
            (item) => item.instanceId == 'event-friday-game-night',
          );
          return page.items
              .where(
                (item) =>
                    item.workflowType == 'event-rsvp' &&
                    item.instanceData['seriesId'] ==
                        anchor.instanceData['seriesId'],
              )
              .toList();
        }))!;
        expect(seriesMembers, hasLength(3));

        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        await _pumpUntil(
          tester,
          find.text('No response record is available for you for this event.'),
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-delete-series-event-friday-game-night'),
          ),
          findsNothing,
        );

        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        await _deleteSeriesWithScope(
          tester,
          installed: installed,
          instanceId: 'event-friday-game-night',
          scope: 'all',
          settledInstanceIds: seriesMembers.map((member) => member.instanceId),
        );

        final cancelledMembers = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          final memberIds = seriesMembers
              .map((member) => member.instanceId)
              .toSet();
          return page.items
              .where((item) => memberIds.contains(item.instanceId))
              .toList();
        }))!;
        expect(cancelledMembers, hasLength(3));
        expect(
          cancelledMembers.map((member) => member.currentState),
          everyElement('cancelled'),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'only organizer cancels Friday and its summary binding remains read-only',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-cancellation'),
      ))!;
      try {
        await _expectRefused(tester, () async {
          await installed.engine.applyTransition(
            workflowType: 'event-rsvp',
            instanceId: 'event-friday-game-night',
            transitionId: 'cancel-event',
            personaId: 'tabletop-member',
          );
        });
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
          find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-respond-going',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'event-rsvp-event-friday-game-night-action-cancel-event',
            ),
          ),
          findsNothing,
        );
        await tester.pumpWidget(
          _calendar(
            installed,
            'tabletop-organizer',
            accountId: 'tabletop-organizer',
          ),
        );
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        await _tapAction(tester, 'event-friday-game-night', 'cancel-event');
        final cancelled = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(cancelled.currentState, 'cancelled');
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-1',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-1',
            ),
          ),
          findsOneWidget,
        );
        expect(
          _keyPrefix('engine-native-calendar-entry-event-friday-game-night-0'),
          findsNothing,
        );
        expect(
          _keyPrefix('engine-native-calendar-agenda-event-friday-game-night-0'),
          findsNothing,
        );
        expect(
          _keyPrefix(
            'engine-native-calendar-selected-detail-event-friday-game-night-0',
          ),
          findsNothing,
        );
        expect(
          _keyPrefix('engine-native-calendar-agenda-event-friday-game-night-1'),
          findsOneWidget,
        );
        expect(
          _keyPrefix('engine-native-calendar-agenda-event-friday-game-night-'),
          findsOneWidget,
        );
        for (final action in const [
          'respond-going',
          'respond-maybe',
          'respond-declined',
          'respond-waitlist',
          'cancel-event',
        ]) {
          expect(
            find.byKey(
              ValueKey('event-rsvp-event-friday-game-night-action-$action'),
            ),
            findsNothing,
          );
        }
        expect(
          _keyPrefix('generic-instance-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('generic-instance-save-event-friday-game-night'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
