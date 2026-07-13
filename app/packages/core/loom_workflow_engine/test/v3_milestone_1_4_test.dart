import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  test('dueNotifications filters real dueAt values by asOf', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'due',
    );
    api.registerDefinition(
      _machine('notice', {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open', 'isTerminal': true},
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'dueAt': {'type': 'string'},
        },
      }),
    );
    final past = await api.createInstance(
      workflowType: 'notice',
      personaId: 'p',
      initialInstanceData: {'dueAt': '2026-01-01T00:00:00Z'},
    );
    await api.createInstance(
      workflowType: 'notice',
      personaId: 'p',
      initialInstanceData: {'dueAt': '2026-12-01T00:00:00Z'},
    );
    expect(
      (await api.dueNotifications(
        asOf: DateTime.utc(2026, 6),
      )).map((item) => item.instanceId),
      [past],
    );
    expect((await api.dueNotifications(asOf: DateTime.utc(2027))).length, 2);
  });

  test(
    'related-list guard blocks then live-re-evaluates after related update',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'guard',
      );
      api.registerDefinition(
        _machine('event', {
          'initialState': 'open',
          'states': {
            'open': {
              'label': 'Open',
              'editableFields': ['goingPersonaIds'],
            },
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'goingPersonaIds': {'type': 'list', 'writableBy': 'formEntry'},
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
                'relatedListField': 'goingPersonaIds',
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
        personaId: 'host',
        initialInstanceData: {'goingPersonaIds': <String>[]},
      );
      final vote = await api.createInstance(
        workflowType: 'vote',
        personaId: 'host',
        initialInstanceData: {'eventId': event},
      );
      await expectLater(
        api.applyTransition(
          workflowType: 'vote',
          instanceId: vote,
          transitionId: 'cast',
          personaId: 'member',
        ),
        throwsStateError,
      );
      await api.updateInstanceFields(
        workflowType: 'event',
        instanceId: event,
        personaId: 'host',
        fieldUpdates: {
          'goingPersonaIds': ['member'],
        },
      );
      await api.applyTransition(
        workflowType: 'vote',
        instanceId: vote,
        transitionId: 'cast',
        personaId: 'member',
      );
      final page = await api.queryInstances(
        tabId: 'x',
        personaId: 'member',
        limit: 10,
      );
      expect(
        page.items.singleWhere((item) => item.instanceId == vote).currentState,
        'cast',
      );
    },
  );
}
