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
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledTabletop {
  const _InstalledTabletop(this.community, this.engine, this.temp);

  final LocalInstalledCommunity community;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-b1-$extensionId-');
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
    // Register and fully resolve the engine-native store before the widget
    // is pumped. This keeps the native sqlite connection in the real async
    // zone, matching the proven Phase B test-install pattern.
    experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      specVersion: community.specVersion,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    return _InstalledTabletop(community, engine, temp);
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
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

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  await selectTestTabletopPersona(tester, personaId);
}

void main() {
  testWidgets(
    'Home renders only its JSON-declared bindings through the generic '
    'engine-native pipeline, not the legacy blanket workflow dump',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('b1-home')))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
              authApi: activeAuthForInstalledCommunity(
                community: installed.community,
                personaTypeId: 'tabletop-organizer',
              ),
            ),
          ),
        );
        await _selectPersona(tester, 'tabletop-organizer');

        // Home is the default tab -- no tap needed to select it.
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-list-root-home')),
        );

        // The ballot (tournament-ballot, primary votePoll binding, role:any,
        // state:open) is JSON-declared for tabId:"home" -- must appear.
        // (The generic fallback card doesn't yet render candidate names --
        // `candidates` is a detail-only field; that's B.2/B.3's job. This
        // milestone only proves the right instance/binding resolves here.)
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-home-ballot-summer-tournament-0',
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Round: initial'), findsOneWidget);

        // The tournament event's own summary binding (also tabId:"home",
        // role:any, state:open) shares the same instance rendering twice --
        // once via Calendar's own binding, once here.
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-home-event-summer-tournament-1',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Summer tournament'), findsWidgets);
        expect(
          find.byKey(
            const ValueKey('votepoll-attendance-event-summer-tournament'),
          ),
          findsOneWidget,
        );
        expect(find.text('Accepted: 8 / 8'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('votepoll-quorum-event-summer-tournament')),
          findsOneWidget,
        );
        expect(find.text('Quorum met'), findsOneWidget);

        // The v4 fixture publishes this announcement and declares its Home
        // summary binding, so the engine-native pipeline must render it.
        expect(
          find.text('Game night moves to the larger room'),
          findsOneWidget,
        );

        // Equipment listings (Marketplace-only bindings) must not leak onto
        // Home either.
        expect(find.textContaining('Board Games'), findsNothing);

        // Switch to the member persona and confirm role:"actor" gating is
        // enforced by the real engine-native path too, not just role:"any"
        // items: both of tabletop-member's own game-purchase-proposal
        // instances (creator == viewer) must appear.
        await _selectPersona(tester, 'tabletop-member');
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-list-root-home')),
        );
        expect(find.textContaining('Wingspan'), findsWidgets);
        expect(find.textContaining('Brass: Birmingham'), findsOneWidget);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'publishing the seeded announcement makes its title and body appear on Home',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('b7-announcements'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
              authApi: activeAuthForInstalledCommunity(
                community: installed.community,
                personaTypeId: 'tabletop-organizer',
              ),
            ),
          ),
        );
        await _selectPersona(tester, 'tabletop-organizer');
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-list-root-home')),
        );

        const title = 'A newly published Tabletop announcement';
        const body = 'This draft is created and published during the test.';
        final announcementId = (await tester.runAsync(
          () => installed.engine.createInstance(
            workflowType: 'tabletop-meetup-announcement',
            initialInstanceData: const {'title': title, 'body': body},
            personaId: 'tabletop-organizer',
          ),
        ))!;
        expect(find.text(title), findsNothing);
        expect(find.text(body), findsNothing);

        await tester.runAsync(() async {
          await installed.engine.applyTransition(
            workflowType: 'tabletop-meetup-announcement',
            instanceId: announcementId,
            transitionId: 'publish',
            personaId: 'tabletop-organizer',
          );
        });

        await _selectPersona(tester, 'tabletop-member');
        await _pumpUntil(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
        final published = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'home',
            personaId: 'tabletop-member',
            limit: 100,
          );
          return page.items.singleWhere(
            (instance) => instance.instanceId == announcementId,
          );
        }))!;
        expect(published.instanceData['body'], body);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
