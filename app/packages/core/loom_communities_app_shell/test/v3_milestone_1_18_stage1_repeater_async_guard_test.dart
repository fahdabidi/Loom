import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

LoomWorkflowStateMachine _eventMachine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      'editableFields': ['goingFanIds'],
    },
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'goingFanIds': {'type': 'fanId[]', 'writableBy': 'formEntry'},
  },
}, 'event');

LoomWorkflowStateMachine _voteMachine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'cast': {'label': 'Cast', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'cast',
      'label': 'Cast',
      'from': ['open'],
      'to': 'cast',
      'guard': {
        'relatedInstanceField': 'eventId',
        'relatedListField': 'goingFanIds',
      },
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'string'},
    'candidate': {'type': 'string'},
  },
}, 'vote');

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

RepeaterSurface _live(LocalWorkflowEngineApi api, String fanId) =>
    RepeaterSurface.live(
      refreshInterval: const Duration(milliseconds: 10),
      querySource: RepeaterQuerySource(
        engine: api,
        workflowType: 'vote',
        fanId: fanId,
      ),
      itemBuilder: (context, item) =>
          Text((item as WorkflowInstance).instanceData['candidate'] as String),
    );

void main() {
  testWidgets(
    'per-item action for a related-list-guarded transition is hidden for '
    'an ineligible persona and shown/tappable for an eligible one',
    (tester) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'repeater-async-guard',
      );
      api.registerDefinition(_eventMachine());
      api.registerDefinition(_voteMachine());
      final event = await api.createInstance(
        workflowType: 'event',
        fanId: 'host',
        initialInstanceData: {
          'goingFanIds': <String>['eligible-member'],
        },
      );
      final vote = await api.createInstance(
        workflowType: 'vote',
        fanId: 'host',
        initialInstanceData: {'eventId': event, 'candidate': 'Chess'},
      );

      await tester.pumpWidget(_host(_live(api, 'ineligible-member')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Chess'), findsOneWidget);
      expect(
        find.byKey(ValueKey('repeater-transition-$vote-cast')),
        findsNothing,
      );

      await tester.pumpWidget(_host(_live(api, 'eligible-member')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.byKey(ValueKey('repeater-transition-$vote-cast')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('repeater-transition-$vote-cast')));
      await tester.pump(const Duration(milliseconds: 20));

      final after = await api.queryInstances(
        tabId: 'verify',
        fanId: 'eligible-member',
        limit: 10,
      );
      expect(
        after.items.firstWhere((item) => item.instanceId == vote).currentState,
        'cast',
      );
    },
  );
}
