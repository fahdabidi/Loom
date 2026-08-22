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
const _memberRoleId = 'tabletop-member';
// This fixture's default member account and member role deliberately use the
// same textual id; keep the two typed constants separate at the boundary.
const _memberFanId = 'tabletop-member';

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
    'loom-calnotify2-7-$extensionId-',
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
  // Pre-warm the engine in the real-async installation zone, matching the
  // proven Tabletop Club installation tests.
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
      roleId: _memberRoleId,
    ),
  ),
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _settleBounded(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectPersona(WidgetTester tester, String roleId) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await _pumpUntil(tester, find.byKey(ValueKey('persona-option-$roleId')));
  await tester.tap(find.byKey(ValueKey('persona-option-$roleId')));
  await _settleBounded(tester);
}

Finder _badgeLabel(String label) => find.descendant(
  of: find.byKey(const ValueKey('notification-bell-badge')),
  matching: find.text(label),
);

void main() {
  testWidgets(
    'real Tabletop Club fixture activates only the bell notification presentation',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('cal-notify2-7-bell-activation'),
      ))!;
      try {
        final experience = experienceForExtensionId(
          installed.community.extensionId,
          displayName: installed.community.displayName,
          specVersion: installed.community.specVersion,
          experienceConfiguration: installed.community.experienceConfiguration,
        );
        expect(experience.resolvedNotificationPresentationStyle, 'bell');

        final notificationId = (await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          return engine.createInstance(
            workflowType: 'notification',
            fanId: 'notification-effect',
            initialInstanceData: const {
              'recipientFanId': _memberFanId,
              'title': 'Tournament reminder',
              'body': 'The summer tournament ballot opens soon.',
              'createdAt': '2026-07-31T12:00:00Z',
            },
          );
        }))!;

        await tester.pumpWidget(_app(installed));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('notification-bell-button')),
        );

        await _selectPersona(tester, _memberRoleId);
        await _pumpUntil(tester, _badgeLabel('2'));

        expect(
          find.byKey(const ValueKey('notification-bell-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('notification-dedicated-tab-list')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('notification-fixed-card')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('notification-fab')), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey('notification-bell-button')),
        );
        await _pumpUntil(
          tester,
          find.byKey(ValueKey('notification-bell-row-$notificationId')),
        );

        expect(find.text('Tournament reminder'), findsOneWidget);
        expect(
          find.textContaining('The summer tournament ballot opens soon.'),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('notification-sheet-close')),
        );
        await _settleBounded(tester);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
