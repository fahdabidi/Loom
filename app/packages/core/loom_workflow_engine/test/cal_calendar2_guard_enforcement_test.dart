import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

LocalWorkflowEngineApi _api() =>
    LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'calendar-guard-enforcement',
      )
      ..setRoleForFan('organizer-01', 'organizer')
      ..setRoleForFan('member-01', 'member');

Map<String, dynamic> _editableDefinition({
  Map<String, dynamic>? editGuard,
  Map<String, dynamic>? creationGuard,
}) => {
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      'editableFields': ['title'],
      if (editGuard != null) 'editGuard': editGuard,
      if (creationGuard != null) 'creationGuard': creationGuard,
    },
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'title': {'type': 'text', 'required': true, 'writableBy': 'formEntry'},
  },
};

void main() {
  group('CAL.Calendar2.0 state guard enforcement', () {
    test('parses creationGuard and preserves absent defaults distinctly', () {
      final guarded = LoomWorkflowState.fromJson({
        'label': 'Open',
        'creationGuard': {
          'allowedRoleIds': ['organizer'],
        },
      });
      final unguarded = LoomWorkflowState.fromJson({'label': 'Open'});

      expect(guarded.creationGuard!.allowedRoleIds, ['organizer']);
      expect(unguarded.creationGuard, isNull);
    });

    test('refuses an update when editGuard rejects the acting fan', () async {
      final api = _api()
        ..registerDefinition(
          _machine(
            'event',
            _editableDefinition(
              editGuard: {
                'allowedRoleIds': ['organizer'],
              },
            ),
          ),
        );
      final instanceId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: {'title': 'Game night'},
        fanId: 'organizer-01',
      );

      await expectLater(
        api.updateInstanceFields(
          workflowType: 'event',
          instanceId: instanceId,
          fieldUpdates: {'title': 'Updated game night'},
          fanId: 'member-01',
        ),
        throwsA(isA<WorkflowAuthorizationError>()),
      );
    });

    test('allows an update when editGuard accepts the acting fan', () async {
      final api = _api()
        ..registerDefinition(
          _machine(
            'event',
            _editableDefinition(
              editGuard: {
                'allowedRoleIds': ['organizer'],
              },
            ),
          ),
        );
      final instanceId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: {'title': 'Game night'},
        fanId: 'organizer-01',
      );

      await api.updateInstanceFields(
        workflowType: 'event',
        instanceId: instanceId,
        fieldUpdates: {'title': 'Updated game night'},
        fanId: 'organizer-01',
      );

      final rows = await api.queryInstances(
        tabId: 'calendar',
        fanId: 'organizer-01',
      );
      expect(rows.items.single.instanceData['title'], 'Updated game night');
    });

    test('creation remains open when creationGuard is absent', () async {
      final api = _api()
        ..registerDefinition(_machine('event', _editableDefinition()));

      final instanceId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: {'title': 'Open creation'},
        fanId: 'member-01',
      );

      expect(instanceId, isNotEmpty);
    });

    test('creationGuard accepts an allowed fan and rejects another', () async {
      final api = _api()
        ..registerDefinition(
          _machine(
            'event',
            _editableDefinition(
              creationGuard: {
                'allowedRoleIds': ['organizer'],
              },
            ),
          ),
        );

      final instanceId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: {'title': 'Organizer event'},
        fanId: 'organizer-01',
      );
      expect(instanceId, isNotEmpty);

      await expectLater(
        api.createInstance(
          workflowType: 'event',
          initialInstanceData: {'title': 'Member event'},
          fanId: 'member-01',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
