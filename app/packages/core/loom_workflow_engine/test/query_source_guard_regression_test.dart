import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType,
  Map<String, dynamic> definition,
) => LoomWorkflowStateMachine.fromJson(definition, workflowType);

class _Fixture {
  _Fixture(this.database, this.engine);

  final WorkflowDatabase database;
  final LocalWorkflowEngineApi engine;
}

_Fixture _fixture({
  List<GuardEvaluationUnavailable>? unavailableDiagnostics,
  bool creationGuard = false,
  bool editGuard = false,
}) {
  final database = WorkflowDatabase.memory();
  final engine =
      LocalWorkflowEngineApi(
          db: database,
          communityId: 'query-source-guard-regression',
          onGuardEvaluationUnavailable: unavailableDiagnostics?.add,
        )
        ..registerDefinition(
          _machine('ad-off-entitlement-status', {
            'initialState': 'inactive',
            'states': {
              for (final state in [
                'inactive',
                'active',
                'change-requested',
                'change-declined',
                'expired',
              ])
                state: {'label': state},
            },
            'transitions': <Map<String, dynamic>>[],
            'instanceDataSchema': {
              'checkoutInstanceId': {'type': 'string', 'required': true},
            },
          }),
        )
        ..registerDefinition(
          _machine('ad-off-ad-suppression', {
            'initialState': 'active',
            'states': {
              'active': {
                'label': 'Active',
                if (creationGuard)
                  'creationGuard': {'formula': '!isSuppressionActive'},
                if (editGuard) ...{
                  'editableFields': ['note'],
                  'editGuard': {'formula': '!isSuppressionActive'},
                },
              },
              'restored': {'label': 'Restored'},
            },
            'transitions': [
              {
                'id': 'request-restoration',
                'label': 'Request restoration',
                'from': ['active'],
                'to': 'restored',
                'guard': {'formula': '!isSuppressionActive'},
              },
              {
                'id': 'suppression-is-active',
                'label': 'Suppression is active',
                'from': ['active'],
                'to': 'restored',
                'guard': {'formula': 'isSuppressionActive'},
              },
              {
                'id': 'review-manually',
                'label': 'Review manually',
                'from': ['active'],
                'to': 'active',
              },
            ],
            'instanceDataSchema': {
              'checkoutInstanceId': {'type': 'string'},
              'note': {'type': 'string'},
              'linkedEntitlements': {
                'type': 'list',
                'source':
                    'query(ad-off-entitlement-status where checkoutInstanceId == checkoutInstanceId)',
              },
              'entitlementStateCounts': {
                'type': 'map',
                'formula': r"groupCount(linkedEntitlements, '$state')",
              },
              'isSuppressionActive': {
                'type': 'bool',
                'formula':
                    "mapGet(entitlementStateCounts, 'active') + mapGet(entitlementStateCounts, 'change-requested') + mapGet(entitlementStateCounts, 'change-declined') > 0",
              },
            },
          }),
        );
  return _Fixture(database, engine);
}

Future<String> _suppression(
  _Fixture fixture, {
  String? checkoutInstanceId = 'checkout-1',
}) => fixture.engine.createInstance(
  workflowType: 'ad-off-ad-suppression',
  fanId: 'member-1',
  initialInstanceData: {
    if (checkoutInstanceId != null) 'checkoutInstanceId': checkoutInstanceId,
  },
);

Future<void> _entitlement(
  _Fixture fixture, {
  required String checkoutInstanceId,
  required String state,
  String? instanceId,
  Map<String, dynamic> extraData = const {},
}) => fixture.database.insertInstance(
  instanceId:
      instanceId ??
      'entitlement-$state-${DateTime.now().microsecondsSinceEpoch}',
  communityId: 'query-source-guard-regression',
  workflowType: 'ad-off-entitlement-status',
  currentState: state,
  instanceData: {'checkoutInstanceId': checkoutInstanceId, ...extraData},
  createdByFanId: 'service',
);

Future<Map<String, dynamic>> _stored(
  _Fixture fixture,
  String instanceId,
) async =>
    jsonDecode((await fixture.database.readInstance(instanceId))!.instanceData)
        as Map<String, dynamic>;

Set<String> _ids(List<LoomWorkflowTransition> transitions) =>
    transitions.map((transition) => transition.id).toSet();

Future<WorkflowInstance> _projection(
  _Fixture fixture,
  String instanceId,
) async {
  final page = await fixture.engine.queryInstances(
    tabId: 'home',
    fanId: 'member-1',
    limit: 50,
  );
  return page.items.singleWhere((item) => item.instanceId == instanceId);
}

void main() {
  test(
    'A/B: a zero-match query source lets the restoration guard run',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.database.close);
      final instanceId = await _suppression(fixture);

      final result = await fixture.engine.applyTransition(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        transitionId: 'request-restoration',
        fanId: 'member-1',
      );

      expect(result.newState, 'restored');
    },
  );

  test(
    'matching active entitlement states deny restoration without a guard exception',
    () async {
      final diagnostics = <GuardEvaluationUnavailable>[];
      final fixture = _fixture(unavailableDiagnostics: diagnostics);
      addTearDown(fixture.database.close);
      final instanceId = await _suppression(
        fixture,
        checkoutInstanceId: 'live',
      );
      for (final state in ['active', 'change-requested', 'change-declined']) {
        await _entitlement(fixture, checkoutInstanceId: 'live', state: state);
      }

      final projection = await _projection(fixture, instanceId);
      expect(projection.instanceData['isSuppressionActive'], isTrue);
      final transitions = await fixture.engine.availableTransitionsAsync(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        currentState: 'active',
        instanceData: projection.instanceData,
        fanId: 'member-1',
      );

      expect(_ids(transitions), {'suppression-is-active', 'review-manually'});
      expect(diagnostics, isEmpty);
    },
  );

  test(
    'matching only non-active entitlement states makes restoration eligible',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.database.close);
      final instanceId = await _suppression(
        fixture,
        checkoutInstanceId: 'inactive-only',
      );
      await _entitlement(
        fixture,
        checkoutInstanceId: 'inactive-only',
        state: 'expired',
      );

      final projection = await _projection(fixture, instanceId);
      expect(projection.instanceData['isSuppressionActive'], isFalse);
      final transitions = await fixture.engine.availableTransitionsAsync(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        currentState: 'active',
        instanceData: projection.instanceData,
        fanId: 'member-1',
      );

      expect(_ids(transitions), {'request-restoration', 'review-manually'});
    },
  );

  test('a valid zero-match query resolves [] with no guard deferral', () async {
    final diagnostics = <GuardEvaluationUnavailable>[];
    final fixture = _fixture(unavailableDiagnostics: diagnostics);
    addTearDown(fixture.database.close);
    final instanceId = await _suppression(
      fixture,
      checkoutInstanceId: 'zero-match',
    );

    final transitions = await fixture.engine.availableTransitionsAsync(
      workflowType: 'ad-off-ad-suppression',
      instanceId: instanceId,
      currentState: 'active',
      instanceData: const {'checkoutInstanceId': 'zero-match'},
      fanId: 'member-1',
    );
    expect(_ids(transitions), {'request-restoration', 'review-manually'});
    expect(diagnostics, isEmpty);

    final result = await fixture.engine.applyTransition(
      workflowType: 'ad-off-ad-suppression',
      instanceId: instanceId,
      transitionId: 'request-restoration',
      fanId: 'member-1',
    );
    expect(result.newInstanceData['linkedEntitlements'], <dynamic>[]);
  });

  test(
    'missing joins and source-read failures make both guard polarities unavailable',
    () async {
      final missingDiagnostics = <GuardEvaluationUnavailable>[];
      final missingFixture = _fixture(
        unavailableDiagnostics: missingDiagnostics,
      );
      addTearDown(missingFixture.database.close);
      final missingId = await _suppression(
        missingFixture,
        checkoutInstanceId: null,
      );

      final asyncTransitions = await missingFixture.engine
          .availableTransitionsAsync(
            workflowType: 'ad-off-ad-suppression',
            instanceId: missingId,
            currentState: 'active',
            instanceData: const <String, dynamic>{},
            fanId: 'member-1',
          );
      expect(_ids(asyncTransitions), {'review-manually'});
      expect(
        missingDiagnostics.map((diagnostic) => diagnostic.transitionId).toSet(),
        {'request-restoration', 'suppression-is-active'},
      );
      for (final diagnostic in missingDiagnostics) {
        expect(
          diagnostic.unavailableInputs['linkedEntitlements']!.code,
          'missing_join_value',
        );
      }

      missingDiagnostics.clear();
      final synchronousTransitions = missingFixture.engine.availableTransitions(
        workflowType: 'ad-off-ad-suppression',
        instanceId: missingId,
        currentState: 'active',
        instanceData: const <String, dynamic>{},
        fanId: 'member-1',
      );
      expect(_ids(synchronousTransitions), {'review-manually'});
      expect(
        missingDiagnostics.map((diagnostic) => diagnostic.transitionId).toSet(),
        {'request-restoration', 'suppression-is-active'},
      );
      expect(
        () => missingFixture.engine.applyTransition(
          workflowType: 'ad-off-ad-suppression',
          instanceId: missingId,
          transitionId: 'request-restoration',
          fanId: 'member-1',
        ),
        throwsStateError,
      );
      expect(
        (await missingFixture.database.readInstance(missingId))!.currentState,
        'active',
      );

      final failureDiagnostics = <GuardEvaluationUnavailable>[];
      final failureFixture = _fixture(
        unavailableDiagnostics: failureDiagnostics,
      );
      addTearDown(failureFixture.database.close);
      final failureId = await _suppression(
        failureFixture,
        checkoutInstanceId: 'read-failure',
      );
      await _entitlement(
        failureFixture,
        checkoutInstanceId: 'read-failure',
        state: 'inactive',
        extraData: const {r'$id': 'reserved-id-is-invalid'},
      );

      final failureTransitions = await failureFixture.engine
          .availableTransitionsAsync(
            workflowType: 'ad-off-ad-suppression',
            instanceId: failureId,
            currentState: 'active',
            instanceData: const {'checkoutInstanceId': 'read-failure'},
            fanId: 'member-1',
          );
      expect(_ids(failureTransitions), {'review-manually'});
      expect(
        failureDiagnostics.map((diagnostic) => diagnostic.transitionId).toSet(),
        {'request-restoration', 'suppression-is-active'},
      );
      for (final diagnostic in failureDiagnostics) {
        expect(
          diagnostic.unavailableInputs['linkedEntitlements']!.code,
          'source_read_failed',
        );
        expect(
          diagnostic.unavailableInputs['linkedEntitlements']!.cause,
          isA<StateError>(),
        );
      }
    },
  );

  test('availability and mutation refresh a stale source projection', () async {
    final fixture = _fixture();
    addTearDown(fixture.database.close);
    final instanceId = await _suppression(
      fixture,
      checkoutInstanceId: 'stale-projection',
    );
    final staleProjection = await _projection(fixture, instanceId);
    expect(staleProjection.instanceData['linkedEntitlements'], <dynamic>[]);
    expect(staleProjection.instanceData['isSuppressionActive'], isFalse);

    await _entitlement(
      fixture,
      checkoutInstanceId: 'stale-projection',
      state: 'active',
    );
    final transitions = await fixture.engine.availableTransitionsAsync(
      workflowType: 'ad-off-ad-suppression',
      instanceId: instanceId,
      currentState: 'active',
      instanceData: staleProjection.instanceData,
      fanId: 'member-1',
    );
    expect(_ids(transitions), {'suppression-is-active', 'review-manually'});
    expect(
      () => fixture.engine.applyTransition(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        transitionId: 'request-restoration',
        fanId: 'member-1',
      ),
      throwsStateError,
    );
    expect(
      (await fixture.database.readInstance(instanceId))!.currentState,
      'active',
    );
  });

  test('creation guards resolve query sources before deciding', () async {
    final fixture = _fixture(creationGuard: true);
    addTearDown(fixture.database.close);

    await fixture.engine.createInstance(
      workflowType: 'ad-off-ad-suppression',
      fanId: 'member-1',
      initialInstanceData: const {'checkoutInstanceId': 'creation-zero'},
    );
    await _entitlement(
      fixture,
      checkoutInstanceId: 'creation-active',
      state: 'active',
    );
    expect(
      () => fixture.engine.createInstance(
        workflowType: 'ad-off-ad-suppression',
        fanId: 'member-1',
        initialInstanceData: const {'checkoutInstanceId': 'creation-active'},
      ),
      throwsStateError,
    );
  });

  test('edit guards resolve fresh query sources before deciding', () async {
    final fixture = _fixture(editGuard: true);
    addTearDown(fixture.database.close);
    final instanceId = await _suppression(
      fixture,
      checkoutInstanceId: 'edit-active',
    );
    await fixture.engine.updateInstanceFields(
      workflowType: 'ad-off-ad-suppression',
      instanceId: instanceId,
      fieldUpdates: const {'note': 'first edit'},
      fanId: 'member-1',
    );
    await _entitlement(
      fixture,
      checkoutInstanceId: 'edit-active',
      state: 'active',
    );
    expect(
      () => fixture.engine.updateInstanceFields(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        fieldUpdates: const {'note': 'forbidden edit'},
        fanId: 'member-1',
      ),
      throwsA(isA<WorkflowAuthorizationError>()),
    );
    expect((await _stored(fixture, instanceId))['note'], 'first edit');
  });

  test(
    'a successful transition persists no source or formula snapshot',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.database.close);
      final instanceId = await _suppression(
        fixture,
        checkoutInstanceId: 'storage-only',
      );

      await fixture.engine.applyTransition(
        workflowType: 'ad-off-ad-suppression',
        instanceId: instanceId,
        transitionId: 'request-restoration',
        fanId: 'member-1',
      );

      final stored = await _stored(fixture, instanceId);
      expect(stored, isNot(contains('linkedEntitlements')));
      expect(stored, isNot(contains('entitlementStateCounts')));
      expect(stored, isNot(contains('isSuppressionActive')));
    },
  );
}
