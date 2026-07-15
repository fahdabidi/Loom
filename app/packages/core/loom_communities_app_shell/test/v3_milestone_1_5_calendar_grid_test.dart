import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowDefinition _event(String id, DateTime date) =>
    LoomWorkflowDefinition(
      workflowId: id,
      title: id,
      entryText: '',
      actionText: '',
      resultText: '',
      calendarItem: LoomCalendarItem(
        dateTime: date,
        host: 'Host $id',
        location: 'Room $id',
      ),
    );

void main() {
  testWidgets('same-date events are distinct items in one calendar cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CalendarMonthGrid(
          workflows: [
            _event('a', DateTime(2026, 7, 12)),
            _event('b', DateTime(2026, 7, 12)),
          ],
          onSelect: (_) {},
          accent: Colors.blue,
        ),
      ),
    );
    final cell = find.byKey(const ValueKey('calendar-day-cell-2026-07-12'));
    expect(cell, findsOneWidget);
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(const ValueKey('calendar-grid-event-a')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(const ValueKey('calendar-grid-event-b')),
      ),
      findsOneWidget,
    );
  });
  testWidgets('different dates use distinct calendar cells', (tester) async {
    await tester.pumpWidget(
      _host(
        CalendarMonthGrid(
          workflows: [
            _event('a', DateTime(2026, 7, 12)),
            _event('b', DateTime(2026, 7, 13)),
          ],
          onSelect: (_) {},
          accent: Colors.blue,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('calendar-day-cell-2026-07-12')),
        matching: find.byKey(const ValueKey('calendar-grid-event-a')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('calendar-day-cell-2026-07-13')),
        matching: find.byKey(const ValueKey('calendar-grid-event-b')),
      ),
      findsOneWidget,
    );
  });
  testWidgets('tapping an event reveals its existing detail content', (
    tester,
  ) async {
    final event = _event('detail', DateTime(2026, 7, 12));
    String? selected;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              Expanded(
                child: CalendarMonthGrid(
                  workflows: [event],
                  onSelect: (id) => setState(() => selected = id),
                  accent: Colors.blue,
                ),
              ),
              if (selected != null)
                CalendarEventDetail(
                  accent: Colors.blue,
                  workflow: event,
                  personaId: 'member',
                  onTransitionApplied: (_, __) async {},
                ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('calendar-grid-event-detail')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('calendar-event-detail-detail')),
      findsOneWidget,
    );
    expect(find.text('Host detail'), findsOneWidget);
    expect(find.text('Room detail'), findsOneWidget);
  });
}
