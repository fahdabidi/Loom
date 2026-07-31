import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  test('createInstances is atomic and preserves input order', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'bulk',
    );
    api.registerDefinition(
      _machine('row', {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'name': {'type': 'text', 'required': true},
        },
      }),
    );

    await expectLater(
      api.createInstances(
        workflowType: 'row',
        personaId: 'member',
        initialInstanceDataList: [
          {'name': 'first'},
          <String, dynamic>{},
        ],
      ),
      throwsA(isA<WorkflowValidationError>()),
    );
    expect(
      (await api.queryInstances(tabId: 'x', personaId: 'member')).items,
      isEmpty,
    );

    final ids = await api.createInstances(
      workflowType: 'row',
      personaId: 'member',
      initialInstanceDataList: [
        {'name': 'first'},
        {'name': 'second'},
      ],
    );
    final rows = (await api.queryInstances(
      tabId: 'x',
      personaId: 'member',
    )).items.where((row) => row.workflowType == 'row').toList();
    expect(ids, hasLength(2));
    expect(rows.map((row) => row.instanceId), containsAll(ids));
  });

  test(
    'relatedAggregate guards pass below a related-table capacity and fail at it',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'aggregate-guard',
      );
      api.setPersonaType('member-1', 'member');
      api.registerDefinition(
        _machine('event', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'capacity': {'type': 'number'},
          },
        }),
      );
      api.registerDefinition(
        _machine('response', {
          'initialState': 'pending',
          'states': {
            'pending': {'label': 'Pending'},
            'going': {'label': 'Going'},
          },
          'transitions': [
            {
              'id': 'going',
              'label': 'Going',
              'from': ['pending'],
              'to': 'going',
              'guard': {
                'relatedAggregate': {
                  'workflowType': 'response',
                  'filter': {'eventId': '{eventId}', r'$state': 'going'},
                  'op': 'count',
                  'comparator': '<',
                  'compareTo': {
                    'relatedInstanceField': 'eventId',
                    'field': 'capacity',
                  },
                },
              },
            },
          ],
          'instanceDataSchema': {
            'eventId': {'type': 'text'},
          },
        }),
      );
      final event = await api.createInstance(
        workflowType: 'event',
        personaId: 'member-1',
        initialInstanceData: {'capacity': 1},
      );
      final responses = await api.createInstances(
        workflowType: 'response',
        personaId: 'member-1',
        initialInstanceDataList: [
          {'eventId': event},
          {'eventId': event},
        ],
      );
      final first = await api.availableTransitionsAsync(
        workflowType: 'response',
        instanceId: responses[0],
        currentState: 'pending',
        instanceData: {'eventId': event},
        personaId: 'member-1',
      );
      expect(first.map((t) => t.id), contains('going'));
      await api.applyTransition(
        workflowType: 'response',
        instanceId: responses[0],
        transitionId: 'going',
        personaId: 'member-1',
      );
      final second = await api.availableTransitionsAsync(
        workflowType: 'response',
        instanceId: responses[1],
        currentState: 'pending',
        instanceData: {'eventId': event},
        personaId: 'member-1',
      );
      expect(second.map((t) => t.id), isNot(contains('going')));
    },
  );

  test(
    'relatedAggregate sum guards aggregate their declared field, not row count',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'aggregate-field-guard',
      );
      api.setPersonaType('member-1', 'member');
      api.registerDefinition(
        _machine('event', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'capacity': {'type': 'number'},
          },
        }),
      );
      api.registerDefinition(
        _machine('response', {
          'initialState': 'pending',
          'states': {
            'pending': {'label': 'Pending'},
            'going': {'label': 'Going'},
          },
          'transitions': [
            {
              'id': 'going',
              'label': 'Going',
              'from': ['pending'],
              'to': 'going',
              'guard': {
                'relatedAggregate': {
                  'workflowType': 'response',
                  'filter': {'eventId': '{eventId}', r'$state': 'going'},
                  'op': 'sum',
                  'field': 'partySize',
                  'comparator': '<',
                  'compareTo': {
                    'relatedInstanceField': 'eventId',
                    'field': 'capacity',
                  },
                },
              },
            },
          ],
          'instanceDataSchema': {
            'eventId': {'type': 'text'},
            'partySize': {'type': 'number'},
          },
        }),
      );
      final event = await api.createInstance(
        workflowType: 'event',
        personaId: 'member-1',
        initialInstanceData: {'capacity': 4},
      );
      final responses = await api.createInstances(
        workflowType: 'response',
        personaId: 'member-1',
        initialInstanceDataList: [
          {'eventId': event, 'partySize': 3},
          {'eventId': event, 'partySize': 1},
          {'eventId': event, 'partySize': 1},
        ],
      );

      await api.applyTransition(
        workflowType: 'response',
        instanceId: responses[0],
        transitionId: 'going',
        personaId: 'member-1',
      );
      final second = await api.availableTransitionsAsync(
        workflowType: 'response',
        instanceId: responses[1],
        currentState: 'pending',
        instanceData: {'eventId': event, 'partySize': 1},
        personaId: 'member-1',
      );
      expect(second.map((transition) => transition.id), contains('going'));
      await api.applyTransition(
        workflowType: 'response',
        instanceId: responses[1],
        transitionId: 'going',
        personaId: 'member-1',
      );
      final third = await api.availableTransitionsAsync(
        workflowType: 'response',
        instanceId: responses[2],
        currentState: 'pending',
        instanceData: {'eventId': event, 'partySize': 1},
        personaId: 'member-1',
      );

      // Two rows are going, but their declared party sizes already sum to 4.
      expect(third.map((transition) => transition.id), isNot(contains('going')));
    },
  );

  test(r'$state and $id are available to query-backed source fields', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'state',
    );
    api.registerDefinition(
      _machine('response', {
        'initialState': 'going',
        'states': {
          'going': {'label': 'Going'},
          'maybe': {'label': 'Maybe'},
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'eventId': {'type': 'text'},
        },
      }),
    );
    api.registerDefinition(
      _machine('event', {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'responses': {
            'type': 'list',
            'source': 'query(response where eventId == id)',
          },
          'counts': {
            'type': 'map',
            'formula': r"groupCount(responses, '$state')",
          },
        },
      }),
    );
    final event = await api.createInstance(
      workflowType: 'event',
      personaId: 'host',
      initialInstanceData: {},
    );
    final response = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {'eventId': event},
    );
    final page = await api.queryInstances(tabId: 'x', personaId: 'host');
    final eventData = page.items
        .singleWhere((row) => row.instanceId == event)
        .instanceData;
    expect(eventData['counts'], {'going': 1});
    expect(eventData['responses'], [
      {'eventId': event, r'$state': 'going', r'$id': response},
    ]);
  });

  test('relatedAggregate guard fails closed for an empty avg', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'empty-average-guard',
    );
    api.registerDefinition(
      _machine('response', {
        'initialState': 'pending',
        'states': {
          'pending': {'label': 'Pending'},
          'going': {'label': 'Going'},
        },
        'transitions': [
          {
            'id': 'going',
            'label': 'Going',
            'from': ['pending'],
            'to': 'going',
            'guard': {
              'relatedAggregate': {
                'workflowType': 'response',
                'filter': {'eventId': '{eventId}', r'$state': 'going'},
                'op': 'avg',
                'comparator': '<',
                'compareTo': 2,
              },
            },
          },
        ],
        'instanceDataSchema': {
          'eventId': {'type': 'text'},
        },
      }),
    );
    final response = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-1'},
    );

    final transitions = await api.availableTransitionsAsync(
      workflowType: 'response',
      instanceId: response,
      currentState: 'pending',
      instanceData: {'eventId': 'event-1'},
      personaId: 'member',
    );

    expect(
      transitions.map((transition) => transition.id),
      isNot(contains('going')),
    );
  });

  group('CALR.1 formula functions', () {
    test('subtractHours returns a new earlier DateTime', () {
      expect(
        evaluateFormula(
          'subtractHours("2026-07-20T12:00:00Z", 3)',
          instanceData: {},
        ),
        DateTime.parse('2026-07-20T09:00:00Z'),
      );
    });
    test('mapGet defaults absent keys to zero', () {
      expect(
        evaluateFormula(
          'mapGet(counts, "going")',
          instanceData: {
            'counts': {'going': 2},
          },
        ),
        2,
      );
      expect(
        evaluateFormula(
          'mapGet(counts, "missing")',
          instanceData: {
            'counts': {'going': 2},
          },
        ),
        0,
      );
    });
  });
}
