import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'authz_p6_test_helpers.dart';

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

class _InstalledFixture {
  const _InstalledFixture(this.community, this.temp);

  final LocalInstalledCommunity community;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledFixture> _install(
  String extensionId, {
  void Function(Map<String, dynamic> source)? mutate,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  mutate?.call(source);
  final temp = await Directory.systemTemp.createTemp(
    'loom-calr4f-$extensionId-',
  );
  final init = File('${temp.path}/tabletop.loom-init.zip');
  final extension = File('${temp.path}/tabletop.loom-extension.zip');
  await init.writeAsString(jsonEncode(source));
  await extension.writeAsString(
    jsonEncode(<String, Object?>{
      'specVersion': currentCommunitySpecVersion,
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
  experienceForExtensionId(
    extensionId,
    displayName: community.displayName,
    specVersion: community.specVersion,
    experienceConfiguration: community.experienceConfiguration,
  );
  await workflowEngineForExtensionId(extensionId);
  return _InstalledFixture(community, temp);
}

Widget _app(_InstalledFixture installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
    authApi: activeAuthForInstalledCommunity(
      community: installed.community,
      personaTypeId: 'tabletop-organizer',
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
}

void _addFocusedTournamentFab(Map<String, dynamic> source) {
  final definitions =
      (source['experience'] as Map<String, dynamic>)['workflowDefinitions']
          as Map<String, dynamic>;
  final tournament = Map<String, dynamic>.from(
    definitions['tournament-event'] as Map,
  );
  final bindings = List<dynamic>.from(tournament['renderBindings'] as List);
  final calendarBinding = Map<String, dynamic>.from(bindings.first as Map);
  final actions = List<dynamic>.from(calendarBinding['actions'] as List);
  actions.add(<String, dynamic>{
    'kind': 'create',
    'workflowType': 'tournament-ballot',
    'label': 'Create ballot from focused tournament',
    'byRoleIds': <String>['tabletop-organizer'],
    'scope': 'instance',
    'presentation': 'fab',
    'prefill': <String, dynamic>{
      'eventId': '{context.id}',
      'ownerFanId': '\$actor',
    },
  });
  calendarBinding['actions'] = actions;
  bindings[0] = calendarBinding;
  tournament['renderBindings'] = bindings;
  definitions['tournament-event'] = tournament;
  (source['experience'] as Map<String, dynamic>)['creatableAction'] =
      <String, dynamic>{'multiActionStyle': 'stacked'};
}

void main() {
  testWidgets(
    'focused instance FAB is additional, excludes instance actions from tab FABs, and resolves its prefill',
    (tester) async {
      final installed = (await tester.runAsync(
        () =>
            _install('calr4f-contextual-fab', mutate: _addFocusedTournamentFab),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);

        // The tab-level FAB list contains only the two declared tab actions.
        // The fixture's button action and this synthetic instance FAB both
        // target tournament-ballot, so this also guards against either scope
        // leaking into multiActionStyle resolution.
        expect(
          find.byKey(const ValueKey('creatable-fab-event-rsvp')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('creatable-fab-tournament-event')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('creatable-fab-tournament-ballot')),
          findsNothing,
        );

        final tournamentAgenda = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-summer-tournament-0',
          ),
        );
        await _pumpUntil(tester, tournamentAgenda);
        await tester.ensureVisible(tournamentAgenda);
        await tester.tap(tournamentAgenda);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('instance-creatable-fab-tournament-ballot'),
          ),
        );
        expect(
          find.byKey(const ValueKey('creatable-fab-event-rsvp')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey('instance-creatable-fab-tournament-ballot'),
          ),
        );
        await _settle(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('new-tournament-ballot-editor-candidates')),
          '[]',
        );
        await tester.tap(
          find.byKey(const ValueKey('new-tournament-ballot-submit')),
        );
        await _settle(tester);

        final eventIds = await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final home = await engine.queryInstances(
            tabId: 'home',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return home.items
              .where((item) => item.workflowType == 'tournament-ballot')
              .map((item) => item.instanceData['eventId'])
              .toSet();
        });
        expect(eventIds, contains('event-summer-tournament'));
        final actorIds = await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final home = await engine.queryInstances(
            tabId: 'home',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return home.items
              .where(
                (item) =>
                    item.instanceData['eventId'] == 'event-summer-tournament',
              )
              .map((item) => item.instanceData['ownerFanId'])
              .toSet();
        });
        expect(actorIds, contains('tabletop-organizer'));
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'contextual FAB is absent without focus or for a nonmatching focused type',
    (tester) async {
      final noFocus = (await tester.runAsync(
        () => _install(
          'calr4f-no-focus',
          mutate: (source) {
            _addFocusedTournamentFab(source);
            final experience = source['experience'] as Map<String, dynamic>;
            final instances = List<dynamic>.from(
              experience['workflowInstances'] as List,
            );
            instances.removeWhere((instance) {
              final workflowType = (instance as Map)['workflowType'];
              return workflowType == 'event-rsvp' ||
                  workflowType == 'tournament-event';
            });
            experience['workflowInstances'] = instances;
          },
        ),
      ))!;
      try {
        await tester.pumpWidget(_app(noFocus));
        await _selectCalendar(tester);
        await _settle(tester);
        expect(
          find.byKey(
            const ValueKey('instance-creatable-fab-tournament-ballot'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(noFocus.dispose);
      }

      final nonmatching = (await tester.runAsync(
        () => _install(
          'calr4f-nonmatching-focus',
          mutate: _addFocusedTournamentFab,
        ),
      ))!;
      try {
        await tester.pumpWidget(_app(nonmatching));
        await _selectCalendar(tester);
        final rsvpAgenda = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        );
        await _pumpUntil(tester, rsvpAgenda);
        await tester.ensureVisible(rsvpAgenda);
        await tester.tap(rsvpAgenda);
        await _settle(tester);
        expect(
          find.byKey(
            const ValueKey('instance-creatable-fab-tournament-ballot'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(nonmatching.dispose);
      }
    },
  );
}
