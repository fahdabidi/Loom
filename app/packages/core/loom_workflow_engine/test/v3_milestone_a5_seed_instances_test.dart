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
}
