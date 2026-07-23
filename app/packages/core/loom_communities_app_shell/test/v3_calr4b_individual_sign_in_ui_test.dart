import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
const _fridayInstanceId = 'event-friday-game-night';

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

Future<_InstalledFixture> _installFrozenTabletop() async {
  final source = jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
      as Map<String, dynamic>;
  final extensionId = source['extensionId'] as String;
  final temp = await Directory.systemTemp.createTemp('loom-calr4b-');
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'extensionId': extensionId,
      'displayName': source['displayName'],
      'version': '1.0.0',
      'mode': 'local-demo',
      'permissions': <String>[],
    }));
    return _InstalledFixture(
      LocalInAppBackend()
          .installLocalPackagePairFromFiles(
            extensionPackagePath: extension.path,
            initializationPackagePath: init.path,
          )
          .community,
      temp,
    );
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

Widget _app(_InstalledFixture fixture) => MaterialApp(
  home: LocalExtensionScreen(
    community: fixture.community,
    seedDataFiles: const [],
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _signInAs(WidgetTester tester, String displayName) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('persona-sign-in-specific-person')),
  );
  await tester.tap(
    find.byKey(const ValueKey('persona-sign-in-specific-person')),
  );
  await _pumpUntil(tester, find.text(displayName));
  await tester.tap(find.text(displayName).first);
  await _pumpUntil(tester, find.byKey(const ValueKey('persona-picker-button')));
  await _settle(tester);
}

Future<void> _openFridayDetail(WidgetTester tester) async {
  final calendarTab = find.byKey(const ValueKey('community-tab-calendar'));
  await _pumpUntil(tester, calendarTab);
  await tester.tap(calendarTab);
  final agenda = find.byKey(
    const ValueKey('engine-native-calendar-agenda-event-friday-game-night-0'),
  );
  await _pumpUntil(tester, agenda);
  await tester.ensureVisible(agenda);
  await tester.tap(agenda);
  await _pumpUntil(
    tester,
    find.byKey(ValueKey('event-rsvp-card-$_fridayInstanceId')),
  );
  await _settle(tester);
}

InputChip _responseChip(WidgetTester tester, String transitionId) =>
    tester.widget<InputChip>(
      find.descendant(
        of: find.byKey(
          ValueKey('event-rsvp-$_fridayInstanceId-action-$transitionId'),
        ),
        matching: find.byType(InputChip),
      ),
    );

void main() {
  testWidgets(
    'individual account sign-in resolves Friday RSVP rows through the app shell',
    (tester) async {
      final fixture = (await tester.runAsync(_installFrozenTabletop))!;
      try {
        await tester.pumpWidget(_app(fixture));

        await _signInAs(tester, 'Priya N.');
        await _openFridayDetail(tester);

        expect(
          find.byKey(ValueKey('event-rsvp-error-$_fridayInstanceId')),
          findsNothing,
        );
        expect(
          find.text('No response record is available for you for this event.'),
          findsNothing,
        );
        expect(_responseChip(tester, 'respond-going').selected, isTrue);

        await tester.tap(
          find.byKey(
            ValueKey('event-rsvp-$_fridayInstanceId-action-respond-maybe'),
          ),
        );
        await _settle(tester);
        expect(_responseChip(tester, 'respond-maybe').selected, isTrue);

        await _signInAs(tester, 'Casey M.');
        await _openFridayDetail(tester);

        expect(
          find.byKey(ValueKey('event-rsvp-error-$_fridayInstanceId')),
          findsNothing,
        );
        expect(
          find.text('No response record is available for you for this event.'),
          findsNothing,
        );
        expect(_responseChip(tester, 'respond-going').selected, isTrue);
        expect(_responseChip(tester, 'respond-maybe').selected, isFalse);
      } finally {
        await tester.runAsync(fixture.dispose);
      }
    },
  );
}
