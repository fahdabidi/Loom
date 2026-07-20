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
      'schemaVersion': 1,
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
  ),
);

Future<void> _selectCalendar(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-calendar'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void _addSecondCalendarCreatable(Map<String, dynamic> source) {
  final experience = source['experience'] as Map<String, dynamic>;
  final definitions = experience['workflowDefinitions'] as Map<String, dynamic>;
  final event = Map<String, dynamic>.from(definitions['event-rsvp'] as Map);
  final bindings = List<dynamic>.from(event['renderBindings'] as List);
  final first = Map<String, dynamic>.from(bindings.first as Map);
  first['creatable'] = <String, dynamic>{
    'byPersonaIds': <String>['tabletop-organizer'],
    'label': 'New synthetic event',
  };
  event['renderBindings'] = <dynamic>[first];
  definitions['synthetic-event'] = event;
}

void main() {
  testWidgets('a real Tabletop calendar action opens the reused event dialog', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('calr3g-real')))!;
    try {
      await tester.pumpWidget(_app(installed));
      await _selectCalendar(tester);
      // The single-action branch supplies an extended FAB directly to the
      // Scaffold.  Let the Scaffold's FAB entrance transition paint before
      // deriving the tap coordinate.  `ensureVisible` cannot help here: this
      // widget is in Scaffold.floatingActionButton, not the scrollable body.
      await tester.pump(const Duration(milliseconds: 50));
      final fab = find.byKey(const ValueKey('creatable-fab-event-rsvp'));
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('New event'),
        ),
        findsOneWidget,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  for (final style in const ['speedDial', 'stacked', 'singleFirst']) {
    testWidgets('$style resolves a two-action Calendar fixture correctly', (
      tester,
    ) async {
      final installed = (await tester.runAsync(
        () => _install(
          'calr3g-$style',
          mutate: (source) {
            _addSecondCalendarCreatable(source);
            final experience = source['experience'] as Map<String, dynamic>;
            experience['creatableAction'] = <String, dynamic>{
              'multiActionStyle': style,
            };
          },
        ),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectCalendar(tester);
        final first = find.byKey(const ValueKey('creatable-fab-event-rsvp'));
        final second = find.byKey(
          const ValueKey('creatable-fab-synthetic-event'),
        );
        if (style == 'speedDial') {
          await tester.tap(
            find.byKey(const ValueKey('creatable-fab-speed-dial')),
          );
          await tester.pumpAndSettle();
          expect(first, findsOneWidget);
          expect(second, findsOneWidget);
          await tester.tap(second);
          await tester.pumpAndSettle();
          expect(
            find.text('Creation for synthetic-event is not wired up yet.'),
            findsOneWidget,
          );
        } else if (style == 'stacked') {
          expect(first, findsOneWidget);
          expect(second, findsOneWidget);
        } else {
          expect(first, findsOneWidget);
          expect(second, findsNothing);
        }
      } finally {
        await tester.runAsync(installed.dispose);
      }
    });
  }
}
