import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

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
    'loom-calr3b-$extensionId-',
  );
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
  // Pre-warm the engine in the real-async installation zone, so its database
  // connection is not first created by a pumped widget and later used from
  // tester.runAsync. This matches the proven calendar end-to-end test pattern.
  experienceForExtensionId(
    extensionId,
    displayName: community.displayName,
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

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('engine-native-calendar-root')),
  );
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

Future<void> _openTournamentCreation(WidgetTester tester) async {
  final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
  if (speedDial.evaluate().isNotEmpty) {
    await tester.tap(speedDial);
    await _settleBounded(tester);
  }
  await tester.tap(
    find.byKey(const ValueKey('creatable-fab-tournament-event')),
  );
  await _settleBounded(tester);
}

Future<void> _settleBounded(WidgetTester tester, {int iterations = 10}) async {
  for (var i = 0; i < iterations; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _submitNewTournament(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('new-tournament-event-editor-title')),
    'Friday Night Magic Draft',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-tournament-event-editor-location')),
    'Community room A',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-tournament-event-editor-minimumAttendance')),
    '8',
  );
  final eventDate = find.byKey(
    const ValueKey('new-tournament-event-editor-eventDate'),
  );
  await tester.ensureVisible(eventDate);
  await tester.tap(eventDate);
  await _settleBounded(tester);
  await tester.tap(find.text('15').last);
  await tester.tap(find.text('OK').last);
  await _settleBounded(tester);
  final eventTime = find.byKey(
    const ValueKey('new-tournament-event-editor-eventTime'),
  );
  await tester.ensureVisible(eventTime);
  await tester.tap(eventTime);
  await _settleBounded(tester);
  await tester.tap(find.text('OK').last);
  await _settleBounded(tester);
  final submit = find.byKey(const ValueKey('new-tournament-event-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await _settleBounded(tester);
}

void main() {
  testWidgets(
    'Creates a tournament-event via FAB and confirms no event-rsvp-response side effect',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('calr3b-tournament'),
      ))!;
      try {
        final beforeCount = (await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final page = await engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return page.items
              .where((item) => item.workflowType == 'event-rsvp-response')
              .length;
        }))!;

        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        await _openTournamentCreation(tester);

        // The tournament creation dialog should be visible.
        expect(find.byType(AlertDialog), findsOneWidget);

        await _submitNewTournament(tester);

        // Dialog should be dismissed after successful creation.
        expect(find.byType(AlertDialog), findsNothing);

        final result = await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          final instances = await engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
          return instances;
        });

        // Confirm the tournament-event instance exists.
        expect(
          result!.items.any(
            (item) =>
                item.workflowType == 'tournament-event' &&
                item.instanceData['title'] == 'Friday Night Magic Draft',
          ),
          isTrue,
        );

        // Confirm tournament creation does not add event-rsvp-response rows.
        final afterCount = result.items
            .where((item) => item.workflowType == 'event-rsvp-response')
            .length;
        expect(
          afterCount,
          beforeCount,
          reason:
              'tournament creation must not trigger the event-rsvp-specific '
              'response-row seeding side effect',
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
