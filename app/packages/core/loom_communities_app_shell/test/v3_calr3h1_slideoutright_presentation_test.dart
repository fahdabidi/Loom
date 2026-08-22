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

Future<void> _pumpUntilCreationDismissed(WidgetTester tester) async {
  final dialog = find.byType(AlertDialog);
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (dialog.evaluate().isEmpty) return;
  }

  final errorTexts = tester
      .widgetList<Text>(find.byKey(const ValueKey('new-event-error')))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.isNotEmpty)
      .toList(growable: false);
  throw TestFailure(
    'Timed out waiting for event creation to dismiss; '
    'visible errors: ${errorTexts.isEmpty ? '<none>' : errorTexts.join(' | ')}',
  );
}

Future<void> _submitNewEvent(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('new-event-editor-title')),
    'Container presentation test event',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-event-editor-location')),
    'Community room',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-event-editor-capacity')),
    '24',
  );
  final eventDate = find.byKey(const ValueKey('new-event-editor-eventDate'));
  await tester.ensureVisible(eventDate);
  await tester.tap(eventDate);
  await _settleBounded(tester);
  await tester.tap(find.text('15').last);
  await tester.tap(find.text('OK').last);
  await _settleBounded(tester);
  final eventTime = find.byKey(const ValueKey('new-event-editor-eventTime'));
  await tester.ensureVisible(eventTime);
  await tester.tap(eventTime);
  await _settleBounded(tester);
  await tester.tap(find.text('OK').last);
  await _settleBounded(tester);
  final submit = find.byKey(const ValueKey('new-event-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await _pumpUntilCreationDismissed(tester);
}

void main() {
  testWidgets(
    'slideOutRight presents and submits the same event creation flow',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install(
          'calr3h1-slideOutRight',
          mutate: (source) => _setPresentationStyle(source, 'slideOutRight'),
        ),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        await _openEventCreation(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(AlertDialog),
            matching: find.byType(SlideTransition),
          ),
          findsOneWidget,
        );
        await _submitNewEvent(tester);
        expect(find.byType(AlertDialog), findsNothing);
        final events = await tester.runAsync(() async {
          final engine = await workflowEngineForExtensionId(
            installed.community.extensionId,
          );
          return engine.queryInstances(
            tabId: 'calendar',
            personaId: 'tabletop-organizer',
            limit: 100,
          );
        });
        expect(
          events!.items.any(
            (item) =>
                item.workflowType == 'event-rsvp' &&
                item.instanceData['title'] ==
                    'Container presentation test event',
          ),
          isTrue,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
