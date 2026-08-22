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

Future<_InstalledFixture> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp(
    'loom-calr4e-$extensionId-',
  );
  final init = File('${temp.path}/tabletop.loom-init.zip');
  final extension = File('${temp.path}/tabletop.loom-extension.zip');
  await init.writeAsString(jsonEncode(source));
  await extension.writeAsString(
    jsonEncode({
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
      roleId: 'tabletop-organizer',
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

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

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
}

Future<void> _createBallotFor(WidgetTester tester, String eventId) async {
  final agenda = find.byKey(
    ValueKey('engine-native-calendar-agenda-$eventId-0'),
  );
  await _pumpUntil(tester, agenda);
  await tester.ensureVisible(agenda);
  await tester.tap(agenda);
  await tester.pump();
  final action = find.byKey(
    ValueKey('instance-create-action-$eventId-tournament-ballot'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await _settle(tester);
  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('new-tournament-ballot-editor-candidates')),
    '[]',
  );
  await tester.tap(find.byKey(const ValueKey('new-tournament-ballot-submit')));
  await _settle(tester);
}

void main() {
  testWidgets(
    'instance create button binds a ballot to its tournament and hides for members',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr4e-instance-create'),
      ))!;
      try {
        final eventId = (await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final existing = await engine.queryInstances(
            tabId: 'calendar',
            fanId: 'tabletop-organizer',
            limit: 100,
          );
          return existing.items
              .firstWhere((item) => item.workflowType == 'tournament-event')
              .instanceId;
        }))!;

        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        await _createBallotFor(tester, eventId);

        final ballotEventIds = await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final home = await engine.queryInstances(
            tabId: 'home',
            fanId: 'tabletop-organizer',
            limit: 100,
          );
          return home.items
              .where((item) => item.workflowType == 'tournament-ballot')
              .map((item) => item.instanceData['eventId'])
              .toSet();
        });
        expect(ballotEventIds, contains(eventId));

        await tester.pumpWidget(_app(installed));
        await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Member').last);
        await tester.pumpAndSettle();
        await _selectCalendar(tester);
        final memberAgenda = find.byKey(
          ValueKey('engine-native-calendar-agenda-$eventId-0'),
        );
        await _pumpUntil(tester, memberAgenda);
        await tester.ensureVisible(memberAgenda);
        await tester.tap(memberAgenda);
        await tester.pump();
        expect(
          find.byKey(
            ValueKey('instance-create-action-$eventId-tournament-ballot'),
          ),
          findsNothing,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
