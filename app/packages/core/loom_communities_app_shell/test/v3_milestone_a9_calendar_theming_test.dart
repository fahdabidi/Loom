import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

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

Future<_InstalledTabletop> _install(
  String extensionId, {
  void Function(Map<String, dynamic> source)? configure,
}) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  configure?.call(source);
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

Widget _engineCalendar(
  _InstalledTabletop installed,
  LoomCardTheme? theme, {
  DateTime Function()? currentDate,
}) => MaterialApp(
  home: ActiveIdentityScope(
    identity: ActiveIdentityContext(
      accountId: null,
      authApi: LocalAuthApi(),
      personaId: 'tabletop-member',
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: EngineNativeCalendarSurface(
          experience: installed.experience,
          persona: _member(installed),
          accent: Colors.deepPurple,
          modernTheme: theme,
          engine: installed.engine,
          currentDate: currentDate ?? DateTime.now,
        ),
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

void _replaceEventDates(Map<String, dynamic> source, List<String> dates) {
  var index = 0;
  void visit(Object? value) {
    if (value is Map) {
      for (final key in value.keys.toList()) {
        final child = value[key];
        if (key == 'eventDate' &&
            child is String &&
            !(child.startsWith('{') && child.endsWith('}'))) {
          value[key] = dates[index++];
        } else {
          visit(child);
        }
      }
    } else if (value is List) {
      for (final item in value) {
        visit(item);
      }
    }
  }

  visit(source);
  if (index != dates.length) {
    throw StateError(
      'Expected ${dates.length} fixture event dates, found $index',
    );
  }
}

void _removeEventRsvpStyleField(Map<String, dynamic> source) {
  final experience = source['experience'] as Map<String, dynamic>;
  final definitions = experience['workflowDefinitions'] as Map<String, dynamic>;
  final eventRsvp = definitions['event-rsvp'] as Map<String, dynamic>;
  final bindings = eventRsvp['renderBindings'] as List<dynamic>;
  (bindings.first as Map<String, dynamic>).remove('styleField');
}

Color _agendaBezelColor(WidgetTester tester, String instanceId) {
  final row = find.byKey(
    ValueKey('engine-native-calendar-agenda-$instanceId-0'),
  );
  final bezel = tester.widget<Container>(
    find.ancestor(of: row, matching: find.byType(Container)).first,
  );
  return (bezel.decoration! as BoxDecoration).color!;
}

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
    'engine-native Calendar month grid shows Monday-first weekday header labels',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('a9-theme')))!;
      try {
        await tester.pumpWidget(
          _engineCalendar(
            installed,
            theme,
            currentDate: () => DateTime(2026, 7, 10),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );
        final header = find.byKey(
          const ValueKey('engine-native-calendar-weekday-header'),
        );
        expect(header, findsOneWidget);
        final headerLabels = tester
            .widgetList<Text>(
              find.descendant(
                of: header,
                matching: find.byType(Text),
              ),
            )
            .map((widget) => widget.data!)
            .toList();
        expect(
          headerLabels,
          equals(const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']),
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

  testWidgets(
    'engine-native Calendar today marker appears on month cell for injected today',
    (tester) async {
      final installed = (await tester.runAsync(() => _install('a9-selected')))!;
      try {
        await tester.pumpWidget(
          _engineCalendar(
            installed,
            theme,
            currentDate: () => DateTime(2026, 7, 10),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-month-grid')),
        );
        final todayMarker = find.byKey(
          const ValueKey('engine-native-calendar-today-2026-07-10'),
        );
        expect(todayMarker, findsOneWidget);
        final todayCell = tester.widget<Container>(
          find.byKey(const ValueKey('engine-native-calendar-date-2026-07-10')),
        );
        final todayDecoration = todayCell.decoration! as BoxDecoration;
        final otherCell = tester.widget<Container>(
          find.byKey(const ValueKey('engine-native-calendar-date-2026-07-11')),
        );
        final otherDecoration = otherCell.decoration! as BoxDecoration;
        expect(todayDecoration.border!.top.width, greaterThan(1));
        expect(otherDecoration.border!.top.width, equals(1));
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

  testWidgets(
    'engine-native agenda uses its accent bezel and compact today date rail',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install(
          'a9-agenda-bezel',
          configure: (source) =>
              _replaceEventDates(source, const ['2026-07-10', '2026-07-11']),
        ),
      ))!;
      try {
        await tester.pumpWidget(
          _engineCalendar(
            installed,
            theme,
            currentDate: () => DateTime(2026, 7, 10),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-group-2026-07-11'),
          ),
        );

        final todayRail = find.byKey(
          const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
        );
        expect(todayRail, findsOneWidget);
        expect(
          find.descendant(of: todayRail, matching: find.text('FRI')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: todayRail, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: todayRail, matching: find.text('2026-07-10')),
          findsNothing,
        );

        final row = find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-summer-tournament-0',
          ),
        );
        final bezel = tester.widget<Container>(
          find.ancestor(of: row, matching: find.byType(Container)).first,
        );
        final bezelDecoration = bezel.decoration! as BoxDecoration;
        expect(
          bezelDecoration.color,
          stylePaletteFrom(theme.accent!)[1].withValues(alpha: 0.92),
        );
        expect(bezelDecoration.border, isNull);
        final tile = tester.widget<ListTile>(row);
        expect((tile.title! as Text).style!.color, theme.resolvedHeading);
        final time = tester.widget<Text>(
          find.descendant(of: row, matching: find.text('13:00')),
        );
        expect(time.style!.color, theme.resolvedBody);

        final todayHighlight = tester.widget<Container>(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-today-2026-07-10'),
          ),
        );
        expect(
          (todayHighlight.decoration! as BoxDecoration).color,
          theme.accent,
        );
        expect(
          (todayHighlight.decoration! as BoxDecoration).shape,
          BoxShape.circle,
        );
        expect(
          tester
              .widget<Container>(
                find.byKey(
                  const ValueKey(
                    'engine-native-calendar-agenda-today-2026-07-11',
                  ),
                ),
              )
              .decoration,
          isNull,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'frozen fixture renders its configured date rail and day-instance badge',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('a9-configurable-date-rail'),
      ))!;
      try {
        await tester.pumpWidget(
          _engineCalendar(
            installed,
            theme,
            currentDate: () => DateTime(2026, 7, 10),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
          ),
        );

        final rail = find.byKey(
          const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
        );
        expect(
          find.descendant(of: rail, matching: find.text('FRI')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: rail, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-date-entry-2026-07-10-2',
            ),
          ),
          findsOneWidget,
        );
        // The frozen fixture has both Friday game night and the summer
        // tournament on this date, so the formula is evaluated over two
        // day-local instances rather than a global or hardcoded count.
        expect(
          find.descendant(of: rail, matching: find.text('2')),
          findsOneWidget,
        );

        final group = tester.widget<Container>(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
          ),
        );
        final row = group.child! as Row;
        expect((row.children.first as SizedBox).width, 48);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'an absent date rail retains the default weekday and today-only circle',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install(
          'a9-default-date-rail',
          configure: (source) {
            final experience = source['experience'] as Map<String, dynamic>;
            final theme = experience['theme'] as Map<String, dynamic>;
            theme.remove('calendar');
          },
        ),
      ))!;
      try {
        await tester.pumpWidget(
          _engineCalendar(
            installed,
            theme,
            currentDate: () => DateTime(2026, 7, 10),
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-group-2026-07-10'),
          ),
        );
        final rail = find.byKey(
          const ValueKey('engine-native-calendar-agenda-date-2026-07-10'),
        );
        expect(
          find.descendant(of: rail, matching: find.text('FRI')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: rail, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-date-entry-2026-07-10-2',
            ),
          ),
          findsNothing,
        );
        final today = tester.widget<Container>(
          find.byKey(
            const ValueKey('engine-native-calendar-agenda-today-2026-07-10'),
          ),
        );
        expect((today.decoration! as BoxDecoration).shape, BoxShape.circle);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'frozen fixture resolves distinct style slots and preserves flat accent without styleField',
    (tester) async {
      final styled = (await tester.runAsync(() => _install('a9-style-slots')))!;
      try {
        await tester.pumpWidget(_engineCalendar(styled, null));
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
        );
        final palette = stylePaletteFrom(Colors.deepPurple);
        final summer = _agendaBezelColor(tester, 'event-summer-tournament');
        final friday = _agendaBezelColor(tester, 'event-friday-game-night');
        expect(summer, palette[1].withValues(alpha: 0.92));
        expect(friday, palette[2].withValues(alpha: 0.92));
        expect(friday, isNot(summer));
      } finally {
        await tester.runAsync(styled.dispose);
      }

      final unstyled = (await tester.runAsync(
        () => _install(
          'a9-style-field-fallback',
          configure: _removeEventRsvpStyleField,
        ),
      ))!;
      try {
        await tester.pumpWidget(_engineCalendar(unstyled, theme));
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'engine-native-calendar-agenda-event-friday-game-night-0',
            ),
          ),
        );
        expect(
          _agendaBezelColor(tester, 'event-friday-game-night'),
          theme.accent!.withValues(alpha: 0.92),
        );
      } finally {
        await tester.runAsync(unstyled.dispose);
      }
    },
  );

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
