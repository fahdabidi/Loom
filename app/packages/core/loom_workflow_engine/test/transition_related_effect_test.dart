import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

Map<String, dynamic> _targetDefinition() => {
  'initialState': 'waitlisted',
  'states': {
    'waitlisted': {'label': 'Waitlisted'},
    'going': {'label': 'Going'},
  },
  'transitions': [
    {
      'id': 'respond-going',
      'label': 'Going',
      'from': ['waitlisted'],
      'to': 'going',
      'guard': {'formula': 'allowPromotion'},
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text'},
    'rsvpedAt': {'type': 'text'},
    'allowPromotion': {'type': 'bool'},
  },
};

Map<String, dynamic> _sourceDefinition() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'done': {'label': 'Done'},
  },
  'transitions': [
    {
      'id': 'release-seat',
      'label': 'Release seat',
      'from': ['open'],
      'to': 'done',
      'effects': [
        {
          'op': 'branch',
          'if': 'true',
          'then': [
            {
              'op': 'transitionRelated',
              'relatedQuery': {
                'workflowType': 'response',
                'filter': {'eventId': '{eventId}', r'$state': 'waitlisted'},
                'sortKey': 'rsvpedAt',
                'limit': 1,
              },
              'transitionId': 'respond-going',
            },
          ],
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text'},
  },
};

Future<String> _stateFor(
  LocalWorkflowEngineApi api,
  String instanceId,
) async => (await api.queryInstances(tabId: 'test', personaId: 'member'))
    .items
    .singleWhere((instance) => instance.instanceId == instanceId)
    .currentState;

void main() {
  test('WorkflowEffect parses transitionRelated query fields', () {
    final effect = WorkflowEffect.fromJson({
      'op': 'transitionRelated',
      'relatedQuery': {
        'workflowType': 'event-rsvp-response',
        'filter': {'eventId': '{eventId}', r'$state': 'waitlisted'},
        'sortKey': 'rsvpedAt',
        'limit': 1,
      },
      'transitionId': 'respond-going',
    });

    expect(effect.relatedQuery?.workflowType, 'event-rsvp-response');
    expect(effect.relatedQuery?.filter, {
      'eventId': '{eventId}',
      r'$state': 'waitlisted',
    });
    expect(effect.relatedQuery?.sortKey, 'rsvpedAt');
    expect(effect.relatedQuery?.limit, 1);
    expect(effect.transitionId, 'respond-going');
  });

  test('transitionRelated promotes the oldest matching instance', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'transition-related-sort',
    );
    api.registerDefinition(_machine('response', _targetDefinition()));
    api.registerDefinition(_machine('event', _sourceDefinition()));
    final older = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {
        'eventId': 'event-1',
        'rsvpedAt': '2026-07-01T10:00:00Z',
        'allowPromotion': true,
      },
    );
    final newer = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {
        'eventId': 'event-1',
        'rsvpedAt': '2026-07-02T10:00:00Z',
        'allowPromotion': true,
      },
    );
    final source = await api.createInstance(
      workflowType: 'event',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-1'},
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: source,
      transitionId: 'release-seat',
      personaId: 'member',
    );

    expect(await _stateFor(api, source), 'done');
    expect(await _stateFor(api, older), 'going');
    expect(await _stateFor(api, newer), 'waitlisted');
  });

  test('transitionRelated silently no-ops when the target guard fails', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'transition-related-guard',
    );
    api.registerDefinition(_machine('response', _targetDefinition()));
    api.registerDefinition(_machine('event', _sourceDefinition()));
    final target = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {
        'eventId': 'event-1',
        'rsvpedAt': '2026-07-01T10:00:00Z',
        'allowPromotion': false,
      },
    );
    final source = await api.createInstance(
      workflowType: 'event',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-1'},
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event',
        instanceId: source,
        transitionId: 'release-seat',
        personaId: 'member',
      ),
      completes,
    );

    expect(await _stateFor(api, source), 'done');
    expect(await _stateFor(api, target), 'waitlisted');
  });

  test('transitionRelated silently no-ops when no instance matches', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'transition-related-empty',
    );
    api.registerDefinition(_machine('response', _targetDefinition()));
    api.registerDefinition(_machine('event', _sourceDefinition()));
    final source = await api.createInstance(
      workflowType: 'event',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-without-responses'},
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event',
        instanceId: source,
        transitionId: 'release-seat',
        personaId: 'member',
      ),
      completes,
    );

    expect(await _stateFor(api, source), 'done');
  });
}
