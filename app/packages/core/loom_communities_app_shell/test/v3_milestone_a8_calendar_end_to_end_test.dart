import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _fixtureRelative =
    'docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

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
Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
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
    return _InstalledTabletop(
      community,
      experience,
      await workflowEngineForExtensionId(community.extensionId),
      temp,
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
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: EngineNativeCalendarSurface(
        key: ValueKey('a8-calendar-$personaId-$revision'),
        experience: installed.experience,
        persona: _persona(installed, personaId),
        accent: Colors.deepPurple,
        engine: installed.engine,
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

Future<void> _tapAction(
  WidgetTester tester,
  String instanceId,
  String transitionId,
) async {
  final action = find.byKey(
    ValueKey('generic-instance-$instanceId-action-$transitionId'),
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

void main() {
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
      expect(find.byType(GenericWorkflowInstanceCard), findsOneWidget);
      expect(find.textContaining('goingPersonaIds'), findsNothing);
      expect(find.textContaining('maybePersonaIds'), findsNothing);
      expect(find.textContaining('notGoingPersonaIds'), findsNothing);
      expect(find.textContaining('waitlistPersonaIds'), findsNothing);
      expect(find.textContaining('isFull'), findsNothing);
      expect(find.textContaining('quorumMet'), findsNothing);

      final group = find.byKey(
        const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
      );
      expect(group, findsOneWidget);
      expect(
        find.descendant(
          of: group,
          matching: find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-summer-tournament-0',
            ),
          ),
        ),
        findsOneWidget,
      );

      final rows = find.byType(ListTile).evaluate().toList();
      expect((rows[0].widget as ListTile).title, isA<Text>());
      expect(
        ((rows[0].widget as ListTile).title! as Text).data,
        'Summer tournament',
      );
      expect(
        ((rows[1].widget as ListTile).title! as Text).data,
        'Friday game night',
      );

      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-next-month')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('engine-native-calendar-previous-month')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('engine-native-calendar-date-strip-2026-07-10'),
        ),
      );
      await tester.pump();

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
      expect(find.text('20 seats'), findsOneWidget);
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
      expect(find.text('Selected game: TBD'), findsOneWidget);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

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
        await tester.tap(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
        );
        await _tapAction(tester, 'event-friday-game-night', 'rsvp-going');
        final going = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(
          going.instanceData['goingPersonaIds'],
          contains('tabletop-organizer'),
        );
        expect(
          going.instanceData['maybePersonaIds'],
          isNot(contains('tabletop-organizer')),
        );
        expect(
          going.instanceData['notGoingPersonaIds'],
          isNot(contains('tabletop-organizer')),
        );
        expect(going.instanceData['goingCount'], 13);
        expect(going.instanceData['seatsRemaining'], 7);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        await _tapAction(tester, 'event-friday-game-night', 'rsvp-maybe');
        final maybe = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(
          maybe.instanceData['goingPersonaIds'],
          isNot(contains('tabletop-organizer')),
        );
        expect(
          maybe.instanceData['maybePersonaIds'],
          contains('tabletop-organizer'),
        );
        expect(maybe.instanceData['goingCount'], 12);
        expect(maybe.instanceData['seatsRemaining'], 8);
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-0',
            ),
          ),
          findsOneWidget,
        );
        await _tapAction(tester, 'event-friday-game-night', 'rsvp-not-going');
        final no = await _instance(
          tester,
          installed,
          'event-friday-game-night',
        );
        expect(
          no.instanceData['goingPersonaIds'],
          isNot(contains('tabletop-organizer')),
        );
        expect(
          no.instanceData['maybePersonaIds'],
          isNot(contains('tabletop-organizer')),
        );
        expect(
          no.instanceData['notGoingPersonaIds'],
          contains('tabletop-organizer'),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('fullness guard reverses through Calendar UI and real formulas', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a8-fullness')))!;
    try {
      await tester.runAsync(() async {
        await installed.engine.applyTransition(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          transitionId: 'rsvp-maybe',
          personaId: 'tabletop-member',
        );
        await installed.engine.updateInstanceFields(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          fieldUpdates: const {'capacity': 12},
          personaId: 'tabletop-organizer',
        );
      });
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-organizer', revision: 2),
      );
      await _pumpUntil(
        tester,
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
      await _tapAction(tester, 'event-friday-game-night', 'rsvp-going');
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-member', revision: 3),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'generic-instance-event-friday-game-night-action-join-waitlist',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'generic-instance-event-friday-game-night-action-rsvp-going',
          ),
        ),
        findsNothing,
      );
      final full = await _instance(
        tester,
        installed,
        'event-friday-game-night',
        personaId: 'tabletop-member',
      );
      expect(full.instanceData['goingCount'], 12);
      expect(full.instanceData['seatsRemaining'], 0);
      expect(full.instanceData['isFull'], isTrue);
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-organizer', revision: 4),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'generic-instance-event-friday-game-night-action-rsvp-maybe',
          ),
        ),
      );
      await _tapAction(tester, 'event-friday-game-night', 'rsvp-maybe');
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-member', revision: 5),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'generic-instance-event-friday-game-night-action-rsvp-going',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'generic-instance-event-friday-game-night-action-join-waitlist',
          ),
        ),
        findsNothing,
      );
      final open = await _instance(
        tester,
        installed,
        'event-friday-game-night',
        personaId: 'tabletop-member',
      );
      expect(open.instanceData['goingCount'], 11);
      expect(open.instanceData['seatsRemaining'], 1);
      expect(open.instanceData['isFull'], isFalse);
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
              'generic-instance-event-summer-tournament-action-rsvp-withdraw',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-event-summer-tournament-action-rsvp-going',
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
        await tester.pumpWidget(
          _calendar(installed, 'tabletop-member', revision: 1),
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
        await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
        await _pumpUntil(
          tester,
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
        await tester.tap(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-1',
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-event-friday-game-night-1',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-event-friday-game-night-action-rsvp-going',
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-event-friday-game-night-action-cancel-event',
            ),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
