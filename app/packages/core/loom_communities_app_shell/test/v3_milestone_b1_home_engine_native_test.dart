import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

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
  const _InstalledTabletop(this.community, this.temp);

  final LocalInstalledCommunity community;
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
    return _InstalledTabletop(community, temp);
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
  final personaPicker = find.byKey(const ValueKey('persona-picker-button'));
  await _pumpUntil(tester, personaPicker);
  await tester.tap(personaPicker);
  await tester.pump();
  final option = find.byKey(ValueKey('persona-option-$personaId'));
  await _pumpUntil(tester, option);
  await tester.tap(option);
  await tester.pump();
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

        // The seeded announcement is still in state "draft" -- its
        // renderBinding only matches state:"published" -- so it must NOT
        // appear. This is the actual regression-proof for retiring the
        // blanket `_communitySectionsFor` dump: the legacy path would have
        // shown every workflow regardless of state.
        expect(
          find.text('Game night moves to the larger room'),
          findsNothing,
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
}
