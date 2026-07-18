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

  test(r'$state is available to query-backed groupCount formulas', () async {
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
    await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {'eventId': event},
    );
    final page = await api.queryInstances(tabId: 'x', personaId: 'host');
    expect(
      page.items
          .singleWhere((row) => row.instanceId == event)
          .instanceData['counts'],
      {'going': 1},
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
