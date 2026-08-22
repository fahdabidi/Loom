import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
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
    'loom-calr3g-$extensionId-',
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
  return _InstalledFixture(
    LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: init.path,
        )
        .community,
    temp,
  );
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

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void _setPresentationStyle(Map<String, dynamic> source, String style) {
  final experience = source['experience'] as Map<String, dynamic>;
  experience['creatableAction'] = <String, dynamic>{
    'presentationStyle': 'popup',
  };
  final tabStyles = Map<String, dynamic>.from(
    experience['tabCreatableActionStyles'] as Map? ?? const <String, dynamic>{},
  );
  if (style == 'popup') {
    tabStyles.remove('calendar');
  } else {
    tabStyles['calendar'] = <String, dynamic>{'presentationStyle': style};
  }
  experience['tabCreatableActionStyles'] = tabStyles;
}

Future<void> _openEventCreation(WidgetTester tester) async {
  final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
  if (speedDial.evaluate().isNotEmpty) {
    await tester.tap(speedDial);
    await _settleBounded(tester);
  }
  await tester.tap(find.byKey(const ValueKey('creatable-fab-event-rsvp')));
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

void main() {
  testWidgets('popup presents the same event creation flow', (tester) async {
    final installed = (await tester.runAsync(
      () => _install(
        'calr3h1-popup',
        mutate: (source) => _setPresentationStyle(source, 'popup'),
      ),
    ))!;
    try {
      await tester.pumpWidget(_app(installed));
      await _selectCalendar(tester);
      expect(find.byType(OpenContainer<bool>), findsOneWidget);
      await _openEventCreation(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      // Close it via Cancel so OpenContainer's animation controller gets a
      // clean teardown instead of leaking into the next test.
      await tester.tap(find.text('Cancel'));
      await _settleBounded(tester);
      expect(find.byType(AlertDialog), findsNothing);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });
}
