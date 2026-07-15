import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _fixtureRelative =
    'docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

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
  const _InstalledTabletop(
    this.community,
    this.experience,
    this.engine,
    this.temp,
  );

  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-a9-$extensionId-');
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
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    return _InstalledTabletop(
      community,
      experience,
      await workflowEngineForExtensionId(community.extensionId),
      temp,
    );
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

LoomPersonaDefinition _member(_InstalledTabletop installed) => installed
    .experience
    .personas!
    .firstWhere((persona) => persona.personaId == 'tabletop-member');

Widget _engineCalendar(_InstalledTabletop installed, LoomCardTheme? theme) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EngineNativeCalendarSurface(
            experience: installed.experience,
            persona: _member(installed),
            accent: Colors.deepPurple,
            modernTheme: theme,
            engine: installed.engine,
          ),
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

BoxDecoration _decoration(WidgetTester tester, String key) =>
    tester.widget<Container>(find.byKey(ValueKey(key))).decoration!
        as BoxDecoration;

LoomWorkflowDefinition _legacyEvent(String id, DateTime date) =>
    LoomWorkflowDefinition(
      workflowId: id,
      title: id,
      entryText: '',
      actionText: '',
      resultText: '',
      calendarItem: LoomCalendarItem(
        dateTime: date,
        host: 'Host',
        location: 'Room',
      ),
    );

double _contrastRatio(Color first, Color second) {
  final brightest = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darkest = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (brightest + 0.05) / (darkest + 0.05);
}

void main() {
  const theme = LoomCardTheme(
    accent: Color(0xffe60073),
    fillColor: Color(0xff123456),
    borderColor: Color(0xff00e5ff),
    headingColor: Color(0xffffd600),
    bodyColor: Color(0xff7cff00),
  );

  testWidgets(
    'engine-native Calendar month grid uses resolved fill border heading and body colors',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('a9-theme')))!;
      try {
        await tester.pumpWidget(_engineCalendar(installed, theme));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );
        final unselected = _decoration(
          tester,
          'engine-native-calendar-date-2026-07-09',
        );
        expect(unselected.color, theme.resolvedFill);
        expect(unselected.border!.top.color, theme.resolvedBorder);
        expect(
          tester.widget<Text>(find.text('9').first).style!.color,
          theme.resolvedHeading,
        );
        expect(
          tester
              .widget<Text>(find.text('Friday game night').first)
              .style!
              .color,
          theme.resolvedBody,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'engine-native Calendar selected date has an accent-driven highlight',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('a9-selected')))!;
      try {
        await tester.pumpWidget(_engineCalendar(installed, theme));
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );
        expect(
          _decoration(tester, 'engine-native-calendar-date-2026-07-10').color,
          isNot(
            _decoration(tester, 'engine-native-calendar-date-2026-07-09').color,
          ),
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets('engine-native Calendar null modernTheme derives from accent', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a9-fallback')))!;
    final derived = LoomCardTheme.deriveFromAccent(Colors.deepPurple);
    try {
      await tester.pumpWidget(_engineCalendar(installed, null));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('engine-native-calendar-month-grid')),
      );
      final fallback = _decoration(
        tester,
        'engine-native-calendar-date-2026-07-09',
      );
      expect(fallback.color, derived.resolvedFill);
      expect(fallback.border!.top.color, derived.resolvedBorder);
      expect(
        tester.widget<Text>(find.text('9').first).style!.color,
        derived.resolvedHeading,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  testWidgets('legacy CalendarMonthGrid border ignores ambient divider color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(dividerColor: const Color(0xffff0000)),
        home: Scaffold(
          body: CalendarMonthGrid(
            workflows: [_legacyEvent('legacy', DateTime(2026, 7, 10))],
            onSelect: (_) {},
            accent: Colors.blue,
            modernTheme: theme,
          ),
        ),
      ),
    );
    final decoration =
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('calendar-day-cell-2026-07-10')),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.border!.top.color, theme.resolvedBorder);
    expect(decoration.border!.top.color, isNot(const Color(0xffff0000)));
  });

  test('resolved Calendar foregrounds meet the legibility contrast bar', () {
    final dark = LoomCardTheme.deriveFromAccent(Colors.deepPurple);
    final light = LoomCardTheme.deriveFromAccent(
      Colors.teal,
      lightSurface: true,
    );
    expect(
      _contrastRatio(dark.resolvedFill, dark.resolvedHeading),
      greaterThan(4.5),
    );
    expect(
      _contrastRatio(dark.resolvedFill, dark.resolvedBody),
      greaterThan(4.5),
    );
    expect(
      _contrastRatio(light.resolvedFill, light.resolvedHeading),
      greaterThan(4.5),
    );
    expect(
      _contrastRatio(light.resolvedFill, light.resolvedBody),
      greaterThan(4.5),
    );
  });
}
