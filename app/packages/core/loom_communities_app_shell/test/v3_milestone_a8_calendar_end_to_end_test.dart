import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

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

/// Real package installation deliberately happens in [tester.runAsync], not in
/// the widget test's fake-async zone. Every scenario owns its extension ID so
/// A.5's memoized shared engine cannot leak persisted state between tests.
Future<_InstalledTabletop> _install(
  String extensionId, {
  void Function(Map<String, dynamic> source)? configure,
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

Widget _appShell(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
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
  ScrollController? scrollController,
  ValueChanged<WorkflowInstance?>? onFocusedInstanceChanged,
}) => MaterialApp(
  home: Scaffold(
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
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
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
  String transitionId,
) async {
  final action = find.byKey(
    ValueKey('event-rsvp-$instanceId-action-$transitionId'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
  await tester.pump();
  // The selected A.6 card mutates and then A.7 re-queries the shared engine.
  // Give both real database operations a bounded real-async/pump handshake.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
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
      'attendeeTotal': <String, dynamic>{
        'type': 'number',
        'storage': 'inline',
      },
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
        'featured': true,
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
  final friday = (instances.firstWhere(
        (instance) =>
            (instance as Map<String, dynamic>)['instanceId'] ==
            'event-friday-game-night',
      ) as Map<String, dynamic>)['instanceData'] as Map<String, dynamic>;
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
            const ValueKey('event-rsvp-editor-event-friday-game-night-eventDate'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-editor-event-friday-game-night-capacity'),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(titleEditor);
        await tester.enterText(titleEditor, 'Friday game night updated');
        final save = find.byKey(
          const ValueKey('event-rsvp-save-event-friday-game-night'),
        );
        // The detail card is inside the Calendar's scroll view.  The title
        // editor is visible after the preceding ensureVisible call, but Save
        // is below the remaining editors; bring the actual action into view
        // before tapping it so this test exercises the mutation path.
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        final title = find.byKey(
          const ValueKey('event-rsvp-title-event-friday-game-night'),
        );
        // This is the optimistic result from _runMutation, before the
        // dispatcher's follow-up query can replace the card's instance.
        expect(tester.widget<Text>(title).data, 'Friday game night updated');
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.widget<Text>(title).data, 'Friday game night updated');
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
          find.byKey(
            const ValueKey('event-rsvp-save-event-friday-game-night'),
          ),
          findsNothing,
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
        () => _install('calr10a-no-edit-guard', configure: (source) {
          final definitions =
              (source['experience'] as Map<String, dynamic>)['workflowDefinitions']
                  as Map<String, dynamic>;
          final states = (definitions['event-rsvp'] as Map<String, dynamic>)['states']
              as Map<String, dynamic>;
          (states['open'] as Map<String, dynamic>).remove('editGuard');
        }),
      ))!;
      try {
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          _keyPrefix('event-rsvp-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-save-event-friday-game-night'),
          ),
          findsNothing,
        );
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
        await _selectAgenda(tester, 'event-friday-game-night', 0);
        expect(
          _keyPrefix('event-rsvp-editor-event-friday-game-night-'),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-save-event-friday-game-night'),
          ),
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

  testWidgets(
    'agenda rows render only explicit tile-context fact pills',
    (tester) async {
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

        expect(find.descendant(of: agenda, matching: find.text('Friday game night')), findsOneWidget);
        expect(find.descendant(of: agenda, matching: find.text('19:00')), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-facts-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        expect(find.descendant(of: agenda, matching: find.text('Community room')), findsOneWidget);
        expect(find.descendant(of: agenda, matching: find.text('Host: Alex Chen (Organizer)')), findsNothing);
        expect(find.descendant(of: agenda, matching: find.text('Keep this off the compact row')), findsNothing);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

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
            const ValueKey(
              'engine-native-calendar-agenda-gathering-tuesday-0',
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
            const ValueKey('engine-native-calendar-agenda-gathering-saturday-0'),
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
            const ValueKey(
              'engine-native-calendar-agenda-gathering-tuesday-0',
            ),
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
            const ValueKey(
              'engine-native-calendar-agenda-gathering-tuesday-0',
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

  testWidgets(
    'places Calendar scope selector before the active scope container',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr7b-scope-selector', configure: _addContainerFixture),
      ))!;
      final selectorRow = find.ancestor(
        of: find.byKey(const ValueKey('calendar-scope-day')),
        matching: find.byType(Row),
      ).first;

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

  testWidgets('navigates Week by full weeks with native previous and next buttons', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('calr7a-week-navigation', configure: _addContainerFixture),
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
  });

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
          const ValueKey('engine-native-calendar-entry-event-container-tuesday-0'),
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
          home: Scaffold(
            body: EngineNativeCalendarSurface(
              experience: installed.experience,
              persona: _persona(installed, 'tabletop-member'),
              accent: Colors.deepPurple,
              modernTheme: null,
              engine: engine,
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
        await tester.pumpAndSettle();
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
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }

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

  testWidgets('fullness guard reverses through Calendar UI and real formulas', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a8-fullness')))!;
    setCurrentActiveAccountId('tabletop-member-14');
    addTearDown(() => setCurrentActiveAccountId(null));
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
        _calendar(installed, 'tabletop-member', revision: 2),
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
        _calendar(installed, 'tabletop-member', revision: 3),
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
      expect(open.instanceData['goingCount'], 10);
      expect(open.instanceData['seatsRemaining'], 1);
      expect(open.instanceData['isFull'], isFalse);
      await _tapAction(tester, 'event-friday-game-night', 'respond-going');
      final going = await _instance(
        tester,
        installed,
        'event-friday-game-night',
        personaId: 'tabletop-member-14',
      );
      expect(_responseFor(going, 'tabletop-member-14')['\$state'], 'going');
      expect(going.instanceData['goingCount'], 11);
      expect(going.instanceData['seatsRemaining'], 0);
      expect(going.instanceData['isFull'], isTrue);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

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
    'only organizer cancels Friday and its summary binding remains read-only',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a8-cancellation'),
      ))!;
      setCurrentActiveAccountId('tabletop-member-14');
      addTearDown(() => setCurrentActiveAccountId(null));
      try {
        await _expectRefused(tester, () async {
          await installed.engine.applyTransition(
            workflowType: 'event-rsvp',
            instanceId: 'event-friday-game-night',
            transitionId: 'cancel-event',
            personaId: 'tabletop-member',
          );
        });
        await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
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
        setCurrentActiveAccountId('tabletop-organizer');
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
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
