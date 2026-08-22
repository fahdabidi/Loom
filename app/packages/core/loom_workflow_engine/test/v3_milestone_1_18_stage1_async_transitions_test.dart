import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  test('availableTransitionsAsync filters a related-list-guarded transition '
      'that the sync variant still exposes', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'async-guard',
    );
    api.registerDefinition(
      _machine('event', {
        'initialState': 'open',
        'states': {
          'open': {
            'label': 'Open',
            'editableFields': ['goingFanIds'],
          },
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'goingFanIds': {'type': 'list', 'writableBy': 'formEntry'},
        },
      }),
    );
    api.registerDefinition(
      _machine('vote', {
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
        },
      }),
    );
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
      initialInstanceData: {'eventId': event},
    );

    final page = await api.queryInstances(tabId: 'x', fanId: 'host', limit: 10);
    final voteInstance = page.items.singleWhere(
      (item) => item.instanceId == vote,
    );

    // Documents the known gap Milestone 1.4 deferred: the sync variant
    // still exposes the guarded transition to an ineligible persona.
    final syncForIneligible = api.availableTransitions(
      workflowType: 'vote',
      instanceId: vote,
      currentState: voteInstance.currentState,
      instanceData: voteInstance.instanceData,
      fanId: 'ineligible-member',
    );
    expect(syncForIneligible.map((t) => t.id), contains('cast'));

    // The new async variant correctly filters it out.
    final asyncForIneligible = await api.availableTransitionsAsync(
      workflowType: 'vote',
      instanceId: vote,
      currentState: voteInstance.currentState,
      instanceData: voteInstance.instanceData,
      fanId: 'ineligible-member',
    );
    expect(asyncForIneligible.map((t) => t.id), isNot(contains('cast')));

    // And correctly includes it for an eligible persona.
    final asyncForEligible = await api.availableTransitionsAsync(
      workflowType: 'vote',
      instanceId: vote,
      currentState: voteInstance.currentState,
      instanceData: voteInstance.instanceData,
      fanId: 'eligible-member',
    );
    expect(asyncForEligible.map((t) => t.id), contains('cast'));
  });
}
