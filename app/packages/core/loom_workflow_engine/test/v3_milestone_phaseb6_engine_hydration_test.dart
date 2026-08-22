import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _organizerFanId = 'tabletop-organizer-01';
const _organizerRoleId = 'tabletop-organizer';
const _memberFanId = 'tabletop-member-01';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

Map<String, dynamic> _eventDefinition() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'selectedGame': {'type': 'text'},
  },
};

Map<String, dynamic> _voteDefinition() => {
  'initialState': 'cast',
  'states': {
    'cast': {'label': 'Vote cast', 'isTerminal': true},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'ballotId': {'type': 'text', 'required': true},
    'voterId': {'type': 'fanId', 'required': true},
    'choice': {'type': 'text', 'required': true},
  },
};

Map<String, dynamic> _ballotDefinition() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Voting open'},
    'closed': {'label': 'Closed', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'close-vote',
      'label': 'Close vote',
      'from': ['open'],
      'to': 'closed',
      'guard': {
        'allowedRoleIds': ['tabletop-organizer'],
      },
      'effects': [
        {
          'op': 'branch',
          'if': 'isTie',
          'then': [
            {
              'op': 'createInstance',
              'workflowType': 'tournament-ballot',
              'fields': {
                'eventId': '{eventId}',
                'candidates': '{tiedCandidates}',
                'round': 'runoff',
                'deadline': '{deadline}',
                'reminderOffset': '{reminderOffset}',
                'notificationsEnabled': '{notificationsEnabled}',
              },
            },
            {'op': 'set', 'key': 'outcome', 'value': 'runoff'},
          ],
          'else': [
            {'op': 'set', 'key': 'outcome', 'value': 'decided'},
            {
              'op': 'set',
              'key': 'selectedGame',
              'value': '{winner}',
              'relatedInstance': 'eventId',
            },
          ],
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text', 'required': true},
    'candidates': {'type': 'list', 'required': true},
    'round': {'type': 'text'},
    'deadline': {'type': 'date'},
    'reminderOffset': {'type': 'text'},
    'notificationsEnabled': {'type': 'bool'},
    'dueAt': {
      'type': 'date',
      'formula':
          "subtractHours(deadline, if(reminderOffset == 'one-week', 168, if(reminderOffset == 'one-day', 24, if(reminderOffset == 'one-hour', 1, 0))))",
    },
    'outcome': {'type': 'text', 'writableBy': 'effect'},
    'ballots': {
      'type': 'list',
      'source': 'query(tournament-vote where ballotId == id)',
    },
    'voteCounts': {'type': 'map', 'formula': 'groupCount(ballots, choice)'},
    'winner': {'type': 'text', 'formula': 'argMaxKey(voteCounts)'},
    'tiedCandidates': {'type': 'list', 'formula': 'topKeys(voteCounts)'},
    'isTie': {'type': 'bool', 'formula': 'size(tiedCandidates) > 1'},
  },
};

class _SeededBallot {
  const _SeededBallot({required this.eventId, required this.ballotId});

  final String eventId;
  final String ballotId;
}

LocalWorkflowEngineApi _engine(WorkflowDatabase database) {
  final engine = LocalWorkflowEngineApi(
    db: database,
    communityId: 'phaseb6-engine-hydration',
  );
  engine
    ..setRoleForFan(_organizerFanId, _organizerRoleId)
    ..setRoleForFan(_memberFanId, 'tabletop-member')
    ..registerDefinition(_machine('tournament-event', _eventDefinition()))
    ..registerDefinition(_machine('tournament-vote', _voteDefinition()))
    ..registerDefinition(_machine('tournament-ballot', _ballotDefinition()));
  return engine;
}

Future<_SeededBallot> _seedBallot(
  LocalWorkflowEngineApi engine,
  List<String> choices,
) async {
  final eventId = await engine.createInstance(
    workflowType: 'tournament-event',
    fanId: _organizerFanId,
    initialInstanceData: {'selectedGame': 'TBD'},
  );
  final ballotId = await engine.createInstance(
    workflowType: 'tournament-ballot',
    fanId: _organizerFanId,
    initialInstanceData: {
      'eventId': eventId,
      'candidates': [
        {'id': 'catan', 'name': 'Catan'},
        {'id': 'azul', 'name': 'Azul'},
        {'id': 'wingspan', 'name': 'Wingspan'},
      ],
      'round': 'initial',
      'deadline': '2026-07-20T18:00:00.000Z',
      'reminderOffset': 'one-day',
      'notificationsEnabled': true,
      'outcome': '',
    },
  );
  for (var index = 0; index < choices.length; index++) {
    await engine.createInstance(
      workflowType: 'tournament-vote',
      fanId: _memberFanId,
      initialInstanceData: {
        'ballotId': ballotId,
        'voterId': 'tabletop-member-${index + 1}',
        'choice': choices[index],
      },
    );
  }
  return _SeededBallot(eventId: eventId, ballotId: ballotId);
}

Future<WorkflowInstance> _read(
  LocalWorkflowEngineApi engine,
  String instanceId,
) async {
  final page = await engine.queryInstances(
    tabId: 'home',
    fanId: _organizerFanId,
    limit: 100,
  );
  return page.items.singleWhere(
    (instance) => instance.instanceId == instanceId,
  );
}

Future<List<WorkflowInstance>> _readType(
  LocalWorkflowEngineApi engine,
  String workflowType,
) async {
  final page = await engine.queryInstances(
    tabId: 'home',
    fanId: _organizerFanId,
    limit: 100,
  );
  return page.items
      .where((instance) => instance.workflowType == workflowType)
      .toList();
}

Map<String, int> _counts(dynamic rawCounts) => {
  if (rawCounts is Map)
    for (final entry in rawCounts.entries)
      '${entry.key}': (entry.value as num).toInt(),
};

Set<String> _ids(dynamic rawValues) => {
  if (rawValues is Iterable)
    for (final value in rawValues) '$value',
};

void main() {
  test('close-vote hydrates query-backed fields for a clear winner', () async {
    final database = WorkflowDatabase.memory();
    addTearDown(database.close);
    final engine = _engine(database);
    final seeded = await _seedBallot(engine, [
      'catan',
      'catan',
      'azul',
      'wingspan',
    ]);

    final beforeClose = await _read(engine, seeded.ballotId);
    expect(_counts(beforeClose.instanceData['voteCounts']), {
      'catan': 2,
      'azul': 1,
      'wingspan': 1,
    });
    expect(beforeClose.instanceData['isTie'], isFalse);

    final result = await engine.applyTransition(
      workflowType: 'tournament-ballot',
      instanceId: seeded.ballotId,
      transitionId: 'close-vote',
      fanId: _organizerFanId,
    );
    expect(result.newState, 'closed');

    final ballot = await _read(engine, seeded.ballotId);
    expect(ballot.instanceData['outcome'], 'decided');
    final event = await _read(engine, seeded.eventId);
    expect(event.instanceData['selectedGame'], 'catan');
  });

  test('close-vote hydrates query-backed fields for a tie runoff', () async {
    final database = WorkflowDatabase.memory();
    addTearDown(database.close);
    final engine = _engine(database);
    final seeded = await _seedBallot(engine, [
      'catan',
      'catan',
      'azul',
      'azul',
      'wingspan',
      'wingspan',
    ]);

    final beforeClose = await _read(engine, seeded.ballotId);
    expect(_counts(beforeClose.instanceData['voteCounts']), {
      'catan': 2,
      'azul': 2,
      'wingspan': 2,
    });
    expect(beforeClose.instanceData['isTie'], isTrue);

    final result = await engine.applyTransition(
      workflowType: 'tournament-ballot',
      instanceId: seeded.ballotId,
      transitionId: 'close-vote',
      fanId: _organizerFanId,
    );
    expect(result.newState, 'closed');

    final ballot = await _read(engine, seeded.ballotId);
    expect(ballot.instanceData['outcome'], 'runoff');
    final ballots = await _readType(engine, 'tournament-ballot');
    final runoff = ballots.singleWhere(
      (instance) => instance.instanceId != seeded.ballotId,
    );
    expect(runoff.instanceData['round'], 'runoff');
    expect(runoff.instanceData['eventId'], seeded.eventId);
    expect(_ids(runoff.instanceData['candidates']), {
      'catan',
      'azul',
      'wingspan',
    });
    final event = await _read(engine, seeded.eventId);
    expect(event.instanceData['selectedGame'], 'TBD');
  });
}
