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
  final temp = await Directory.systemTemp.createTemp('loom-gp2-$extensionId-');
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

void main() {
  testWidgets(
    'Giving projects the frozen dues instance through the generic engine-native list',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('gp2-giving'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
            ),
          ),
        );
        final personaPicker = find.byKey(
          const ValueKey('persona-picker-button'),
        );
        await _pumpUntil(tester, personaPicker);
        await tester.tap(personaPicker);
        await tester.pump();
        final member = find.byKey(
          const ValueKey('persona-option-tabletop-member'),
        );
        await _pumpUntil(tester, member);
        await tester.tap(member);
        await tester.pump();
        final givingTab = find.byKey(const ValueKey('community-tab-giving'));
        await _pumpUntil(tester, givingTab);
        await tester.ensureVisible(givingTab);
        await tester.tap(givingTab);
        await tester.pump();

        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-list-root-giving')),
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-giving-dues-2026-q3-member-0',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(GenericWorkflowInstanceCard), findsOneWidget);
        expect(find.text(r'$15.00'), findsOneWidget);
        expect(find.text('Quarterly club dues'), findsOneWidget);
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'generic-instance-dues-2026-q3-member-action-pay',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-dues-2026-q3-member-action-pay',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Pay \$15'), findsOneWidget);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
