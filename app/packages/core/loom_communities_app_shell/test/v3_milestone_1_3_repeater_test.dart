import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'one': {'label': 'One'},
    'two': {'label': 'Two'},
    'done': {'label': 'Done', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'make-one',
      'label': 'Make one',
      'from': ['open'],
      'to': 'one',
    },
    {
      'id': 'make-two',
      'label': 'Make two',
      'from': ['open'],
      'to': 'two',
    },
    {
      'id': 'complete-one',
      'label': 'Complete one',
      'from': ['one'],
      'to': 'done',
    },
    {
      'id': 'complete-two',
      'label': 'Complete two',
      'from': ['two'],
      'to': 'done',
    },
  ],
  'instanceDataSchema': {
    'title': {'type': 'string'},
  },
}, 'repeatable');

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<LocalWorkflowEngineApi> _engineWith(int count) async {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'repeater-test',
  );
  api.registerDefinition(_machine());
  for (var index = 0; index < count; index++) {
    await api.createInstance(
      workflowType: 'repeatable',
      fanId: 'member',
      initialInstanceData: {'title': 'Item $index'},
    );
  }
  return api;
}

RepeaterSurface _live(LocalWorkflowEngineApi api) => RepeaterSurface.live(
  refreshInterval: const Duration(milliseconds: 10),
  querySource: RepeaterQuerySource(
    engine: api,
    workflowType: 'repeatable',
    fanId: 'member',
  ),
  itemBuilder: (context, item) =>
      Text((item as WorkflowInstance).instanceData['title'] as String),
);

void main() {
  testWidgets('static source cardinality follows the supplied list', (
    tester,
  ) async {
    Widget repeater(List<String> items) => _host(
      RepeaterSurface.static(
        items: items,
        itemBuilder: (context, item) => Text(item as String),
      ),
    );
    await tester.pumpWidget(repeater(['one', 'two', 'three']));
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsNothing);

    await tester.pumpWidget(repeater(['one', 'two', 'three', 'four', 'five']));
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-5')), findsNothing);
  });

  testWidgets('live source grows after an externally created engine instance', (
    tester,
  ) async {
    final api = await _engineWith(3);
    await tester.pumpWidget(_host(_live(api)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('repeater-item-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-3')), findsNothing);

    await api.createInstance(
      workflowType: 'repeatable',
      fanId: 'member',
      initialInstanceData: {'title': 'External'},
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.byKey(const ValueKey('repeater-item-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('repeater-item-4')), findsNothing);
  });

  testWidgets(
    'live transition action applies to the second repeated instance',
    (tester) async {
      final api = await _engineWith(3);
      final seeded = await api.queryInstances(
        tabId: 'seed',
        fanId: 'member',
        limit: 10,
      );
      final first = seeded.items[0];
      final second = seeded.items[1];
      await api.applyTransition(
        workflowType: 'repeatable',
        instanceId: first.instanceId,
        transitionId: 'make-one',
        fanId: 'member',
      );
      await api.applyTransition(
        workflowType: 'repeatable',
        instanceId: second.instanceId,
        transitionId: 'make-two',
        fanId: 'member',
      );

      await tester.pumpWidget(_host(_live(api)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(
        find.byKey(
          ValueKey('repeater-transition-${second.instanceId}-complete-two'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
      final after = await api.queryInstances(
        tabId: 'verify',
        fanId: 'member',
        limit: 10,
      );
      expect(
        after.items
            .firstWhere((item) => item.instanceId == second.instanceId)
            .currentState,
        'done',
      );
      expect(
        after.items
            .firstWhere((item) => item.instanceId == first.instanceId)
            .currentState,
        'one',
      );
    },
  );
}
