import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

import 'authz_p6_test_helpers.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Garden fixture');
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
  final temp = await Directory.systemTemp.createTemp('loom-cjm13-$extensionId-');
  final init = File('${temp.path}/garden.loom-init.zip');
  final extension = File('${temp.path}/garden.loom-extension.zip');
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
  experienceForExtensionId(
    community.extensionId,
    displayName: community.displayName,
    experienceConfiguration: community.experienceConfiguration,
  );
  await workflowEngineForExtensionId(community.extensionId);
  return _InstalledFixture(community, temp);
}

Widget _app(_InstalledFixture installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
    authApi: activeAuthForInstalledCommunity(
      community: installed.community,
      personaTypeId: 'garden-coordinator',
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

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Finder _calendarAgendaRows() => find.descendant(
  of: find.byKey(const ValueKey('engine-native-calendar-root')),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is ListTile &&
        widget.key is ValueKey<String> &&
        (widget.key as ValueKey<String>).value.startsWith(
          'engine-native-calendar-agenda-',
        ),
  ),
);

void main() {
  testWidgets(
    'calendar content is not overlapped by the community floating action button',
    (tester) async {
      final installed =
          (await tester.runAsync(() => _install('cjm13-garden-calendar')))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );
        await _pumpUntil(tester, _calendarAgendaRows());

        final fabFinder = find.byKey(
          const ValueKey('creatable-fab-garden-event-rsvp'),
        );
        expect(fabFinder, findsOneWidget);

        final agendaItemElements = _calendarAgendaRows().evaluate().toList();
        expect(agendaItemElements, isNotEmpty);
        final lastAgendaTileKey = agendaItemElements.last.widget.key;
        expect(lastAgendaTileKey, isA<ValueKey<String>>());
        final lastAgendaTileFinder = find.byKey(lastAgendaTileKey as ValueKey<String>);
        expect(lastAgendaTileFinder, findsOneWidget);

        final scrollFinder = find.byKey(
          ValueKey('local-extension-${installed.community.extensionId}'),
        );
        await tester.dragUntilVisible(
          lastAgendaTileFinder,
          scrollFinder,
          const Offset(0, -240),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(lastAgendaTileFinder);
        final agendaRect = tester.getRect(lastAgendaTileFinder);
        final fabRect = tester.getRect(fabFinder);
        expect(
          agendaRect.bottom,
          lessThanOrEqualTo(fabRect.top),
          reason:
              'Expected the final visible agenda card to remain above the FAB',
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
