import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
  },
  'transitions': const <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'title': {'type': 'string'},
  },
}, 'grid-repeatable');

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 300, child: child)),
  ),
);

Future<LocalWorkflowEngineApi> _engineWith(int count) async {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'repeater-grid-test',
  );
  api.registerDefinition(_machine());
  for (var index = 0; index < count; index++) {
    await api.createInstance(
      workflowType: 'grid-repeatable',
      fanId: 'member',
      initialInstanceData: {'title': 'Item $index'},
    );
  }
  return api;
}

RepeaterSurface _liveGrid(LocalWorkflowEngineApi api) => RepeaterSurface.live(
  refreshInterval: const Duration(milliseconds: 10),
  querySource: RepeaterQuerySource(
    engine: api,
    workflowType: 'grid-repeatable',
    fanId: 'member',
  ),
  layout: RepeaterLayout.grid,
  gridCrossAxisCount: 2,
  gridShrinkWrap: true,
  gridScrollable: false,
  itemBuilder: (context, item) =>
      Text((item as WorkflowInstance).instanceData['title'] as String),
);

void main() {
  testWidgets('static grid uses its configured columns and item positions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RepeaterSurface.static(
          items: const ['one', 'two', 'three', 'four'],
          layout: RepeaterLayout.grid,
          gridCrossAxisCount: 2,
          gridChildAspectRatio: 1,
          gridMainAxisSpacing: 8,
          gridCrossAxisSpacing: 12,
          gridShrinkWrap: true,
          gridScrollable: false,
          itemBuilder: (context, item) => Center(child: Text(item as String)),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.childAspectRatio, 1);
    expect(delegate.mainAxisSpacing, 8);
    expect(delegate.crossAxisSpacing, 12);
    expect(grid.shrinkWrap, isTrue);
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsOneWidget);

    final first = tester.getTopLeft(
      find.byKey(const ValueKey('repeater-item-0')),
    );
    final second = tester.getTopLeft(
      find.byKey(const ValueKey('repeater-item-1')),
    );
    final third = tester.getTopLeft(
      find.byKey(const ValueKey('repeater-item-2')),
    );
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(third.dx, first.dx);
    expect(third.dy, greaterThan(first.dy));
  });

  testWidgets('live grid grows after an externally created engine instance', (
    tester,
  ) async {
    final api = await _engineWith(3);
    await tester.pumpWidget(_host(_liveGrid(api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsNothing);

    await api.createInstance(
      workflowType: 'grid-repeatable',
      fanId: 'member',
      initialInstanceData: {'title': 'External'},
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.byKey(const ValueKey('repeater-item-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-4')), findsNothing);
  });
}
