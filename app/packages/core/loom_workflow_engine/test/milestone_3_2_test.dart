import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Milestone 3.2 cross-workflow dues guard', () {
    test('dues-current member can see and execute borrow', () async {
      final db = WorkflowDatabase.memory();
      final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
      api
        ..registerDefinition(_duesMachine())
        ..registerDefinition(_loanMachine());

      final duesId = await api.createInstance(
        workflowType: 'tabletop-club-dues-payment',
        initialInstanceData: _duesData(),
        personaId: 'tabletop-member',
      );
      await api.applyTransition(
        workflowType: 'tabletop-club-dues-payment',
        instanceId: duesId,
        transitionId: 'pay',
        personaId: 'tabletop-member',
      );
      final listingId = await api.createInstance(
        workflowType: 'marketplace-root',
        initialInstanceData: _listingData(),
        personaId: 'tabletop-member',
      );
      final page = await api.queryInstances(
        tabId: 'marketplace',
        personaId: 'tabletop-member',
      );
      final listing = page.items.firstWhere(
        (item) => item.instanceId == listingId,
      );
      final completed = await api.completedWorkflowIdsForPersona(
        'tabletop-member',
      );

      final transitions = api.availableTransitions(
        workflowType: listing.workflowType,
        instanceId: listing.instanceId,
        currentState: listing.currentState,
        instanceData: listing.instanceData,
        personaId: 'tabletop-member',
      );
      expect(completed, contains('tabletop-membership-dues-current'));
      expect(
        evaluateGuard(
          _loanMachine().transitions.single.guard,
          'tabletop-member',
          listing.instanceData,
          completedWorkflowIds: completed,
        ),
        isTrue,
      );
      expect(
        transitions,
        isEmpty,
        reason: 'sync availableTransitions cannot query cross-workflow state',
      );
      final asyncTransitions = await api.availableTransitionsAsync(
        workflowType: listing.workflowType,
        instanceId: listing.instanceId,
        currentState: listing.currentState,
        instanceData: listing.instanceData,
        personaId: 'tabletop-member',
      );
      expect(
        asyncTransitions.map((transition) => transition.id),
        contains('borrow'),
      );

      final result = await api.applyTransition(
        workflowType: listing.workflowType,
        instanceId: listing.instanceId,
        transitionId: 'borrow',
        personaId: 'tabletop-member',
      );
      expect(result.newState, 'onLoan');
      expect(result.newInstanceData['holderPersonaId'], 'tabletop-member');
      db.close();
    });

    test('dues-not-current member cannot execute borrow', () async {
      final db = WorkflowDatabase.memory();
      final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
      api
        ..registerDefinition(_duesMachine())
        ..registerDefinition(_loanMachine());

      await api.createInstance(
        workflowType: 'tabletop-club-dues-payment',
        initialInstanceData: _duesData(),
        personaId: 'tabletop-member',
      );
      final listingId = await api.createInstance(
        workflowType: 'marketplace-root',
        initialInstanceData: _listingData(),
        personaId: 'tabletop-member',
      );

      final completed = await api.completedWorkflowIdsForPersona(
        'tabletop-member',
      );
      expect(completed, isNot(contains('tabletop-membership-dues-current')));
      await expectLater(
        api.applyTransition(
          workflowType: 'marketplace-root',
          instanceId: listingId,
          transitionId: 'borrow',
          personaId: 'tabletop-member',
        ),
        throwsStateError,
      );
      db.close();
    });

    test(
      'completed lookup is persona-specific across workflow types',
      () async {
        final db = WorkflowDatabase.memory();
        final api = LocalWorkflowEngineApi(db: db, communityId: 'tabletop');
        api.registerDefinition(_duesMachine());

        final paidDuesId = await api.createInstance(
          workflowType: 'tabletop-club-dues-payment',
          initialInstanceData: _duesData(),
          personaId: 'tabletop-member',
        );
        await api.createInstance(
          workflowType: 'tabletop-club-dues-payment',
          initialInstanceData: _duesData(),
          personaId: 'other-member',
        );
        await api.applyTransition(
          workflowType: 'tabletop-club-dues-payment',
          instanceId: paidDuesId,
          transitionId: 'pay',
          personaId: 'tabletop-member',
        );

        expect(
          await api.completedWorkflowIdsForPersona('tabletop-member'),
          contains('tabletop-membership-dues-current'),
        );
        expect(
          await api.completedWorkflowIdsForPersona('other-member'),
          isNot(contains('tabletop-membership-dues-current')),
        );
        db.close();
      },
    );
  });
}

LoomWorkflowStateMachine _duesMachine() {
  return const LoomWorkflowStateMachine(
    workflowType: 'tabletop-club-dues-payment',
    initialState: 'unpaid',
    states: {
      'unpaid': LoomWorkflowState(label: 'Unpaid'),
      'paid': LoomWorkflowState(label: 'Paid', isTerminal: true),
    },
    transitions: [
      LoomWorkflowTransition(
        id: 'pay',
        label: 'Pay dues',
        from: ['unpaid'],
        to: 'paid',
        effects: [
          WorkflowEffect(op: 'set', key: 'receiptStatus', value: 'complete'),
        ],
      ),
    ],
    instanceDataSchema: {
      'workflowId': InstanceDataField(type: 'string', required: true),
      'completionWorkflowId': InstanceDataField(type: 'string'),
      'receiptStatus': InstanceDataField(type: 'string'),
    },
  );
}

LoomWorkflowStateMachine _loanMachine() {
  return const LoomWorkflowStateMachine(
    workflowType: 'marketplace-root',
    initialState: 'available',
    states: {
      'available': LoomWorkflowState(label: 'Available'),
      'onLoan': LoomWorkflowState(label: 'On loan'),
    },
    transitions: [
      LoomWorkflowTransition(
        id: 'borrow',
        label: 'Request loan',
        from: ['available'],
        to: 'onLoan',
        guard: WorkflowGuard(
          allowedPersonaIds: ['tabletop-member'],
          requiresWorkflowsComplete: ['tabletop-membership-dues-current'],
        ),
        effects: [
          WorkflowEffect(op: 'set', key: 'holderPersonaId', value: r'$actor'),
        ],
      ),
    ],
    instanceDataSchema: {
      'title': InstanceDataField(type: 'string', required: true),
      'holderPersonaId': InstanceDataField(type: 'string'),
    },
  );
}

Map<String, dynamic> _duesData() {
  return {
    'workflowId': 'tabletop-club-dues-payment',
    'completionWorkflowId': 'tabletop-membership-dues-current',
    'receiptStatus': '',
  };
}

Map<String, dynamic> _listingData() {
  return {'title': 'Root', 'holderPersonaId': ''};
}
