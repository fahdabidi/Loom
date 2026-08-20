import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  test('WorkflowGuard reads only allowedRoleIds', () {
    final v4 = WorkflowGuard.fromJson({
      'allowedRoleIds': ['organizer'],
    });
    final legacy = WorkflowGuard.fromJson({
      'allowedPersonaIds': ['organizer'],
    });

    expect(v4.allowedPersonaIds, ['organizer']);
    expect(legacy.allowedPersonaIds, isNull);
    expect(WorkflowGuard.jsonKeys, isNot(contains('allowedPersonaIds')));
  });

  test('WorkflowAction reads only byRoleIds', () {
    final v4 = WorkflowAction.fromJson({
      'kind': 'create',
      'byRoleIds': ['member'],
    });
    final legacy = WorkflowAction.fromJson({
      'kind': 'create',
      'byPersonaIds': ['member'],
    });

    expect(v4.byPersonaIds, ['member']);
    expect(legacy.byPersonaIds, isNull);
    expect(WorkflowAction.jsonKeys, isNot(contains('byPersonaIds')));
  });

  test('RenderBinding reads only audience', () {
    final v4 = RenderBinding.fromJson({
      'states': ['open'],
      'audience': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': 'formEntry',
      'bindingKind': 'primary',
    });

    expect(v4.role, 'any');
    expect(RenderBinding.jsonKeys, isNot(contains('role')));
    expect(
      () => RenderBinding.fromJson({
        'states': ['open'],
        'role': 'any',
        'tabId': 'home',
        'cardSurfaceFamily': 'formEntry',
        'bindingKind': 'primary',
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('registered definitions emit v4 guard and binding keys', () async {
    final database = WorkflowDatabase.memory();
    addTearDown(database.close);
    final engine = LocalWorkflowEngineApi(
      db: database,
      communityId: 'spec-v4-json-keys',
    );
    engine.registerDefinition(
      LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': [
          {
            'id': 'close',
            'label': 'Close',
            'from': ['open'],
            'to': null,
            'guard': {
              'allowedRoleIds': ['organizer'],
            },
          },
        ],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'formEntry',
            'bindingKind': 'primary',
          },
        ],
      }, 'fixture'),
    );

    final stored = (await database.loadDefinitionsForCommunity(
      'spec-v4-json-keys',
    ))['fixture']!;
    final transition =
        (stored['transitions'] as List<dynamic>).single as Map<String, dynamic>;
    final guard = transition['guard'] as Map<String, dynamic>;
    final binding =
        (stored['renderBindings'] as List<dynamic>).single
            as Map<String, dynamic>;

    expect(guard, containsPair('allowedRoleIds', ['organizer']));
    expect(guard, isNot(contains('allowedPersonaIds')));
    expect(binding, containsPair('audience', 'any'));
    expect(binding, isNot(contains('role')));
  });
}
