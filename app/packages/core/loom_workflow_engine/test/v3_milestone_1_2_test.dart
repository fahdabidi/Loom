import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  test(
    'V3 1.2 effects, aggregate API, and computed guard use real instances',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'v3-test',
      );
      api.registerDefinition(
        _machine('target', {
          'initialState': 'open',
          'states': {
            'open': {
              'label': 'Open',
              'editableFields': ['status'],
            },
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'status': {'type': 'string', 'writableBy': 'formEntry'},
          },
        }),
      );
      api.registerDefinition(
        _machine('child', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open', 'isTerminal': true},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'label': {'type': 'string'},
          },
        }),
      );
      api.registerDefinition(
        _machine('source', {
          'initialState': 'open',
          'states': {
            'open': {
              'label': 'Open',
              'editableFields': ['votes'],
            },
            'done': {'label': 'Done', 'isTerminal': true},
          },
          'transitions': [
            {
              'id': 'run',
              'label': 'Run',
              'from': ['open'],
              'to': null,
              'effects': [
                {
                  'op': 'createInstance',
                  'workflowType': 'child',
                  'fields': {'label': r'from $actor'},
                },
                {
                  'op': 'set',
                  'relatedInstance': 'targetId',
                  'key': 'status',
                  'value': 'updated',
                },
                {
                  'op': 'branch',
                  'if': 'votes > 1',
                  'then': [
                    {'op': 'set', 'key': 'branch', 'value': 'then'},
                  ],
                  'else': [
                    {'op': 'set', 'key': 'branch', 'value': 'else'},
                  ],
                },
              ],
            },
            {
              'id': 'guarded',
              'label': 'Guarded',
              'from': ['open'],
              'to': 'done',
              'guard': {'formula': 'isQuorumMet'},
            },
          ],
          'instanceDataSchema': {
            'targetId': {'type': 'string'},
            'votes': {'type': 'number', 'writableBy': 'formEntry'},
            'branch': {'type': 'string'},
            'isQuorumMet': {'type': 'bool', 'formula': 'votes >= 2'},
          },
        }),
      );
      final target = await api.createInstance(
        workflowType: 'target',
        fanId: 'p',
        initialInstanceData: {'status': 'new'},
      );
      final source = await api.createInstance(
        workflowType: 'source',
        fanId: 'p',
        initialInstanceData: {'targetId': target, 'votes': 1},
      );
      await expectLater(
        api.applyTransition(
          workflowType: 'source',
          instanceId: source,
          transitionId: 'guarded',
          fanId: 'p',
        ),
        throwsStateError,
      );
      await api.applyTransition(
        workflowType: 'source',
        instanceId: source,
        transitionId: 'run',
        fanId: 'p',
      );
      final page = await api.queryInstances(tabId: 'x', fanId: 'p');
      expect(
        page.items.where((item) => item.workflowType == 'child'),
        hasLength(1),
      );
      expect(
        page.items
            .firstWhere((item) => item.instanceId == target)
            .instanceData['status'],
        'updated',
      );
      expect(
        page.items
            .firstWhere((item) => item.instanceId == source)
            .instanceData['branch'],
        'else',
      );
      await api.updateInstanceFields(
        workflowType: 'source',
        instanceId: source,
        fanId: 'p',
        fieldUpdates: {'votes': 2},
      );
      await api.applyTransition(
        workflowType: 'source',
        instanceId: source,
        transitionId: 'guarded',
        fanId: 'p',
      );
      await api.createInstance(
        workflowType: 'target',
        fanId: 'p',
        initialInstanceData: {'status': 'updated'},
      );
      expect(
        await api.aggregate(
          workflowType: 'target',
          column: 'status',
          op: 'count',
        ),
        2,
      );
      expect(
        await api.aggregate(
          workflowType: 'target',
          column: 'status',
          op: 'count',
          groupBy: 'status',
        ),
        [
          {'status': 'updated', 'count': 2},
        ],
      );
    },
  );
}
