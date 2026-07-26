import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

class _BallotStore {
  _BallotStore(this.api);
  final LocalWorkflowEngineApi api;

  Future<WorkflowInstance> read(String id) async => (await api.queryInstances(
    tabId: 'x',
    personaId: 'organizer',
    limit: 100,
  )).items.singleWhere((i) => i.instanceId == id);

  Future<void> cast(String ballot, String persona, String choice) async {
    await api.updateInstanceFields(
      workflowType: 'ballot',
      instanceId: ballot,
      fieldUpdates: {'pendingChoice': choice},
      personaId: persona,
    );
    await api.applyTransition(
      workflowType: 'ballot',
      instanceId: ballot,
      transitionId: 'cast-vote',
      personaId: persona,
    );
  }

  Future<String?> closeVote(String ballot) async {
    final instance = await read(ballot);
    if (instance.instanceData['isTie'] == true) {
      final tied = (instance.instanceData['tiedCandidates'] as List)
          .cast<String>()
          .toSet();
      final candidates = (instance.instanceData['candidates'] as List)
          .whereType<Map<dynamic, dynamic>>()
          .where((c) => tied.contains(c['id']))
          .map((c) => Map<String, dynamic>.from(c))
          .toList();
      return api.createInstance(
        workflowType: 'ballot',
        personaId: 'organizer',
        initialInstanceData: {
          'eventId': instance.instanceData['eventId'],
          'candidates': candidates,
          'ballots': <dynamic>[],
          'pendingChoice': '',
        },
      );
    }
    await api.applyTransition(
      workflowType: 'ballot',
      instanceId: ballot,
      transitionId: 'close',
      personaId: 'organizer',
    );
    return null;
  }
}

void main() {
  late LocalWorkflowEngineApi api;
  late _BallotStore store;
  late String event;
  final candidates = [
    {'id': 'Catan', 'name': 'Catan', 'description': 'Trade'},
    {'id': 'Azul', 'name': 'Azul', 'description': 'Tiles'},
    {'id': 'Wingspan', 'name': 'Wingspan', 'description': 'Birds'},
  ];
  setUp(() async {
    api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'ballot',
    );
    api.registerDefinition(
      _machine('event', {
        'initialState': 'open',
        'states': {
          'open': {
            'label': 'Open',
            'editableFields': ['goingPersonaIds', 'selectedGame'],
          },
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'goingPersonaIds': {'type': 'list'},
          'selectedGame': {'type': 'string'},
        },
      }),
    );
    api.registerDefinition(
      _machine('ballot', {
        'initialState': 'open',
        'states': {
            'open': {
              'label': 'Open',
              'editableFields': ['pendingChoice', 'ballots'],
            },
          'closed': {'label': 'Closed'},
        },
        'transitions': [
          {
            'id': 'cast-vote',
            'label': 'Cast vote',
            'from': ['open'],
            'to': 'open',
            'guard': {
              'relatedInstanceField': 'eventId',
              'relatedListField': 'goingPersonaIds',
            },
            'effects': [
              {
                'op': 'append',
                'key': 'ballots',
                'value': {'personaId': r'$actor', 'choice': '{pendingChoice}'},
              },
            ],
          },
          {
            'id': 'close',
            'label': 'Close',
            'from': ['open'],
            'to': 'closed',
            'effects': [
              {
                'op': 'set',
                'key': 'selectedGame',
                'value': '{winner}',
                'relatedInstance': 'eventId',
              },
            ],
          },
        ],
        'instanceDataSchema': {
          'eventId': {'type': 'string'},
          'candidates': {'type': 'list'},
          'pendingChoice': {'type': 'string'},
          'ballots': {'type': 'list', 'writableBy': 'formEntry'},
          'voteCounts': {
            'type': 'map',
            'formula': 'groupCount(ballots, choice)',
          },
          'winner': {'type': 'string', 'formula': 'argMaxKey(voteCounts)'},
          'tiedCandidates': {'type': 'list', 'formula': 'topKeys(voteCounts)'},
          'isTie': {'type': 'bool', 'formula': 'size(tiedCandidates) > 1'},
        },
      }),
    );
    event = await api.createInstance(
      workflowType: 'event',
      personaId: 'organizer',
      initialInstanceData: {
        'goingPersonaIds': ['a', 'b', 'c', 'd', 'e'],
        'selectedGame': 'TBD',
      },
    );
    store = _BallotStore(api);
  });
  Future<String> ballot() => api.createInstance(
    workflowType: 'ballot',
    personaId: 'organizer',
    initialInstanceData: {
      'eventId': event,
      'candidates': candidates,
      'ballots': <dynamic>[],
      'pendingChoice': '',
    },
  );

  test('tie creates a real runoff ballot with only tied candidates', () async {
    final id = await ballot();
    for (final vote in [
      ('a', 'Catan'),
      ('b', 'Catan'),
      ('c', 'Azul'),
      ('d', 'Azul'),
      ('e', 'Wingspan'),
    ]) {
      await store.cast(id, vote.$1, vote.$2);
    }
    final runoff = await store.closeVote(id);
    expect(runoff, isNotNull);
    final data = (await store.read(runoff!)).instanceData;
    expect(
      (data['candidates'] as List)
          .cast<Map<dynamic, dynamic>>()
          .map((c) => c['id'])
          .toSet(),
      {'Catan', 'Azul'},
    );
  });
  test('non-going persona cannot cast a guarded vote', () async {
    final id = await ballot();
    await api.updateInstanceFields(
      workflowType: 'ballot',
      instanceId: id,
      fieldUpdates: {'pendingChoice': 'Catan'},
      personaId: 'outsider',
    );
    expect(
      () => api.applyTransition(
        workflowType: 'ballot',
        instanceId: id,
        transitionId: 'cast-vote',
        personaId: 'outsider',
      ),
      throwsStateError,
    );
  });
  test('clear winner propagates to the related event', () async {
    final id = await ballot();
    for (final vote in [('a', 'Catan'), ('b', 'Catan'), ('c', 'Azul')]) {
      await store.cast(id, vote.$1, vote.$2);
    }
    expect(await store.closeVote(id), isNull);
    expect((await store.read(event)).instanceData['selectedGame'], 'Catan');
  });
}
