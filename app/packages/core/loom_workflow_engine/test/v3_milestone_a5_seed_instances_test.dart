import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _definition({
  Map<String, dynamic> schema = const {},
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{'label': 'Open'},
    'closed': <String, dynamic>{'label': 'Closed', 'isTerminal': true},
  },
  'transitions': <dynamic>[],
  'instanceDataSchema': schema,
}, 'thing');

Future<LocalWorkflowEngineApi> _engine({
  Map<String, dynamic> schema = const {},
}) async {
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'c',
  );
  engine.registerDefinition(_definition(schema: schema));
  return engine;
}

WorkflowInstance _seed(
  String id, {
  String type = 'thing',
  String state = 'closed',
  Map<String, dynamic> data = const {},
}) => WorkflowInstance(
  instanceId: id,
  workflowType: type,
  currentState: state,
  instanceData: data,
  createdByPersonaId: 'creator',
);
Future<List<WorkflowInstance>> _all(LocalWorkflowEngineApi engine) async =>
    (await engine.queryInstances(
      tabId: 'x',
      personaId: 'creator',
      limit: 50,
    )).items;

void main() {
  test('preserves supplied ID and non-initial state', () async {
    final e = await _engine();
    await e.seedInstances([_seed('fixed')]);
    final row = (await _all(e)).single;
    expect(row.instanceId, 'fixed');
    expect(row.currentState, 'closed');
  });
  test('rejects unknown workflow definition', () async {
    final e = await _engine();
    expect(e.seedInstances([_seed('x', type: 'missing')]), throwsStateError);
  });
  test('rejects undeclared current state', () async {
    final e = await _engine();
    expect(e.seedInstances([_seed('x', state: 'missing')]), throwsStateError);
  });
  test('rejects missing required field', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'name': <String, dynamic>{'type': 'string', 'required': true},
      },
    );
    expect(
      e.seedInstances([_seed('x')]),
      throwsA(isA<WorkflowValidationError>()),
    );
  });
  test('rejects seeded computed field', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'total': <String, dynamic>{'type': 'number', 'formula': '1'},
      },
    );
    expect(
      e.seedInstances([
        _seed('x', data: <String, dynamic>{'total': 1}),
      ]),
      throwsA(isA<WorkflowValidationError>()),
    );
  });
  test('batch atomicity leaves no partial rows', () async {
    final e = await _engine();
    expect(
      e.seedInstances([_seed('good'), _seed('bad', state: 'missing')]),
      throwsStateError,
    );
    expect(await _all(e), isEmpty);
  });
  test('exact repeat is idempotent and conflict does not overwrite', () async {
    final e = await _engine();
    await e.seedInstances([_seed('same')]);
    await e.seedInstances([_seed('same')]);
    expect(await _all(e), hasLength(1));
    expect(e.seedInstances([_seed('same', state: 'open')]), throwsStateError);
    expect((await _all(e)).single.currentState, 'closed');
  });
  test('conflicting batch rolls back a preceding new row', () async {
    final e = await _engine();
    await e.seedInstances([_seed('original')]);
    expect(
      e.seedInstances([_seed('new'), _seed('original', state: 'open')]),
      throwsStateError,
    );
    final rows = await _all(e);
    expect(rows.map((row) => row.instanceId), <String>['original']);
    expect(rows.single.currentState, 'closed');
  });
  test(
    'parses source metadata and retains it after a definition reload',
    () async {
      final machine = _definition(
        schema: <String, dynamic>{
          'remoteItems': <String, dynamic>{
            'type': 'list',
            'source': 'query(remote-item)',
          },
          'remoteCount': <String, dynamic>{
            'type': 'number',
            'formula': 'count(remoteItems)',
          },
        },
      );
      expect(
        machine.instanceDataSchema['remoteItems']!.source,
        'query(remote-item)',
      );
      final db = WorkflowDatabase.memory();
      LocalWorkflowEngineApi(db: db, communityId: 'c')
        ..registerDefinition(machine);
      await Future<void>.delayed(Duration.zero);
      final reloaded = LocalWorkflowEngineApi(db: db, communityId: 'c');
      await reloaded.createInstance(
        workflowType: 'thing',
        initialInstanceData: const <String, dynamic>{},
        personaId: 'creator',
      );
      expect(
        (await _all(reloaded)).single.instanceData,
        isNot(contains('remoteCount')),
      );
    },
  );

  test('defers only formulas dependent on an absent declared source', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'items': <String, dynamic>{'type': 'list'},
        'available': <String, dynamic>{
          'type': 'number',
          'formula': 'count(items)',
        },
        'remoteItems': <String, dynamic>{
          'type': 'list',
          'source': 'query(remote-item)',
        },
        'deferred': <String, dynamic>{
          'type': 'number',
          'formula': 'count(remoteItems)',
        },
        'dependent': <String, dynamic>{
          'type': 'number',
          'formula': 'deferred + 1',
        },
      },
    );
    await e.seedInstances([
      _seed(
        'ok',
        data: <String, dynamic>{
          'items': <Object?>[1],
        },
      ),
    ]);
    final computed = (await _all(e)).single.instanceData;
    expect(computed['available'], 1);
    expect(computed.containsKey('deferred'), isFalse);
    expect(computed.containsKey('dependent'), isFalse);
  });

  test('rejects a formula with an undeclared field', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'total': <String, dynamic>{'type': 'number', 'formula': 'missing + 1'},
      },
    );
    await e.seedInstances([_seed('x')]);
    expect(_all(e), throwsA(isA<FormulaEvaluationException>()));
  });

  test(
    'rejects an unknown function despite an absent declared source',
    () async {
      final e = await _engine(
        schema: <String, dynamic>{
          'remoteItems': <String, dynamic>{
            'type': 'list',
            'source': 'query(remote-item)',
          },
          'total': <String, dynamic>{
            'type': 'number',
            'formula': 'unknown(remoteItems)',
          },
        },
      );
      await e.seedInstances([_seed('x')]);
      expect(_all(e), throwsA(isA<FormulaEvaluationException>()));
    },
  );

  test('rejects a direct computed-field cycle', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'first': <String, dynamic>{'type': 'number', 'formula': 'second + 1'},
        'second': <String, dynamic>{'type': 'number', 'formula': 'first + 1'},
      },
    );
    await e.seedInstances([_seed('x')]);
    expect(_all(e), throwsA(isA<FormulaEvaluationException>()));
  });

  test('rejects a cycle connected to an absent source branch', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'remoteItems': <String, dynamic>{
          'type': 'list',
          'source': 'query(remote-item)',
        },
        'first': <String, dynamic>{
          'type': 'number',
          'formula': 'count(remoteItems) + second',
        },
        'second': <String, dynamic>{'type': 'number', 'formula': 'first + 1'},
      },
    );
    await e.seedInstances([_seed('x')]);
    expect(_all(e), throwsA(isA<FormulaEvaluationException>()));
  });

  test('surfaces invalid runtime types for evaluable formulas', () async {
    final e = await _engine(
      schema: <String, dynamic>{
        'items': <String, dynamic>{'type': 'list'},
        'total': <String, dynamic>{'type': 'number', 'formula': 'count(items)'},
      },
    );
    await e.seedInstances([
      _seed('wrong', data: <String, dynamic>{'items': 'wrong'}),
    ]);
    expect(_all(e), throwsA(isA<FormulaEvaluationException>()));
  });
}
