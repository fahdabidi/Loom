import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine({
  required String workflowType,
  required String family,
  required String action,
  Map<String, dynamic>? instanceDataSchema,
  List<Map<String, dynamic>> effects = const [],
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{'label': 'Open'},
  },
  'transitions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'act',
      'label': 'Act',
      'action': action,
      'from': <String>['open'],
      'to': null,
      if (effects.isNotEmpty) 'effects': effects,
    },
  ],
  'renderBindings': <Map<String, dynamic>>[
    <String, dynamic>{
      'states': <String>['open'],
      'audience': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
    },
  ],
  if (instanceDataSchema != null) 'instanceDataSchema': instanceDataSchema,
}, workflowType);

LocalWorkflowEngineApi _api(String communityId) => LocalWorkflowEngineApi(
  db: WorkflowDatabase.memory(),
  communityId: communityId,
);

Future<String> _create(
  LocalWorkflowEngineApi api,
  String workflowType, [
  Map<String, dynamic> data = const {},
]) => api.createInstance(
  workflowType: workflowType,
  initialInstanceData: data,
  fanId: 'creator',
);

Future<WorkflowTransitionResult> _apply(
  LocalWorkflowEngineApi api,
  String workflowType,
  String instanceId,
) => api.applyTransition(
  workflowType: workflowType,
  instanceId: instanceId,
  transitionId: 'act',
  fanId: 'actor',
);

void main() {
  test(
    'dual writer: archetype and community effect leave one bookkeeping entry',
    () async {
      final api = _api('dual-writer')
        ..registerDefinition(
          _machine(
            workflowType: 'documents',
            family: 'documentLibrary',
            action: 'open',
            instanceDataSchema: <String, dynamic>{
              'openedFanIds': <String, dynamic>{
                'type': 'fanId[]',
                'writableBy': 'effect',
              },
            },
            effects: <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'appendUnique',
                'key': 'openedFanIds',
                'value': r'$actor',
              },
            ],
          ),
        );
      final instanceId = await _create(api, 'documents');

      await _apply(api, 'documents', instanceId);
      final result = await _apply(api, 'documents', instanceId);

      expect(result.newInstanceData['openedFanIds'], <String>['actor']);
      expect(
        result.newInstanceData,
        isNot(
          contains(
            'openedPer'
            'sonaIds',
          ),
        ),
      );
    },
  );

  test(
    'undeclared owned field: archetype bookkeeping creates the field',
    () async {
      final api = _api('undeclared-owned-field')
        ..registerDefinition(
          _machine(
            workflowType: 'documents',
            family: 'documentLibrary',
            action: 'open',
          ),
        );
      final instanceId = await _create(api, 'documents');

      await _apply(api, 'documents', instanceId);
      final result = await _apply(api, 'documents', instanceId);

      expect(result.newInstanceData['openedFanIds'], <String>['actor']);
      expect(
        result.newInstanceData,
        isNot(
          contains(
            'openedPer'
            'sonaIds',
          ),
        ),
      );
    },
  );

  test('unowned field: community effect remains untouched', () async {
    final api = _api('unowned-field')
      ..registerDefinition(
        _machine(
          workflowType: 'documents',
          family: 'documentLibrary',
          action: 'open',
          instanceDataSchema: <String, dynamic>{
            'communityAuditFanIds': <String, dynamic>{
              'type': 'fanId[]',
              'writableBy': 'effect',
            },
          },
          effects: <Map<String, dynamic>>[
            <String, dynamic>{
              'op': 'append',
              'key': 'communityAuditFanIds',
              'value': r'$actor',
            },
          ],
        ),
      );
    final instanceId = await _create(api, 'documents');

    await _apply(api, 'documents', instanceId);
    final result = await _apply(api, 'documents', instanceId);

    expect(result.newInstanceData['openedFanIds'], <String>['actor']);
    expect(result.newInstanceData['communityAuditFanIds'], <String>[
      'actor',
      'actor',
    ]);
  });

  test('contract action mappings maintain each actor set', () async {
    const cases = <(String, String, String, _ExpectedOperation)>[
      ('documentLibrary', 'open', 'openedFanIds', _ExpectedOperation.add),
      (
        'documentLibrary',
        'acknowledge',
        'acknowledgedFanIds',
        _ExpectedOperation.add,
      ),
      ('documentLibrary', 'save', 'savedFanIds', _ExpectedOperation.add),
      ('documentLibrary', 'unsave', 'savedFanIds', _ExpectedOperation.remove),
      (
        'documentLibrary',
        'download',
        'downloadedFanIds',
        _ExpectedOperation.add,
      ),
      (
        'documentLibrary',
        'request_access',
        'accessRequestedFanIds',
        _ExpectedOperation.add,
      ),
      (
        'documentLibrary',
        'withdraw_access_request',
        'accessRequestedFanIds',
        _ExpectedOperation.remove,
      ),
      ('equipment-loan', 'join_queue', 'queuedFanIds', _ExpectedOperation.add),
      (
        'equipment-loan',
        'leave_queue',
        'queuedFanIds',
        _ExpectedOperation.remove,
      ),
      ('event-rsvp', 'set_reminder', 'reminderFanIds', _ExpectedOperation.add),
    ];
    final api = _api('all-mappings');

    for (var index = 0; index < cases.length; index++) {
      final (family, action, contractField, operation) = cases[index];
      final workflowType = 'workflow-$index';
      api.registerDefinition(
        _machine(
          workflowType: workflowType,
          family: family,
          action: action,
          instanceDataSchema: <String, dynamic>{
            contractField: <String, dynamic>{
              'type': 'fanId[]',
              'writableBy': 'effect',
            },
          },
        ),
      );
      final initial = operation == _ExpectedOperation.add
          ? <String>['other']
          : <String>['actor', 'other'];
      final instanceId = await _create(api, workflowType, <String, dynamic>{
        contractField: initial,
      });

      final firstResult = await _apply(api, workflowType, instanceId);
      // Repeating join/leave is now rejected by action eligibility. Other
      // bookkeeping actions retain their public idempotence coverage here.
      final result = family == 'equipment-loan'
          ? firstResult
          : await _apply(api, workflowType, instanceId);

      final expected = operation == _ExpectedOperation.add
          ? <String>['other', 'actor']
          : <String>['other'];
      expect(
        result.newInstanceData[contractField],
        expected,
        reason: '$family.$action must maintain $contractField',
      );
    }
  });
}

enum _ExpectedOperation { add, remove }
