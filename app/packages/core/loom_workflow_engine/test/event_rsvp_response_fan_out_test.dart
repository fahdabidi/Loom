import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType,
  Map<String, dynamic> json,
) => LoomWorkflowStateMachine.fromJson(json, workflowType);

Map<String, dynamic> _eventDefinition({
  required String responseWorkflowType,
  String family = 'event-rsvp',
  String transitionAction = 'create',
  String eventField = 'eventId',
  List<Map<String, dynamic>> effects = const [],
  Map<String, dynamic>? inputs,
}) => <String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{'label': 'Open'},
  },
  'transitions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'act',
      'label': 'Act',
      'action': transitionAction,
      'from': <String>['open'],
      'to': null,
      if (effects.isNotEmpty) 'effects': effects,
      if (inputs != null) 'inputs': inputs,
    },
  ],
  'renderBindings': <Map<String, dynamic>>[
    <String, dynamic>{
      'states': <String>['open'],
      'audience': 'any',
      'tabId': 'calendar',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
      'responseTable': <String, dynamic>{
        'workflowType': responseWorkflowType,
        'eventField': eventField,
        'pendingStates': <String>['pending'],
      },
    },
  ],
  'instanceDataSchema': <String, dynamic>{
    'title': <String, dynamic>{'type': 'text'},
    'eventDate': <String, dynamic>{'type': 'date'},
    'seriesId': <String, dynamic>{'type': 'text', 'writableBy': 'effect'},
  },
};

Map<String, dynamic> _responseDefinition({
  String eventField = 'eventId',
  String identityField = 'fanId',
}) => <String, dynamic>{
  'initialState': 'pending',
  'states': <String, dynamic>{
    'pending': <String, dynamic>{'label': 'Pending'},
  },
  'transitions': <Map<String, dynamic>>[],
  'renderBindings': <Map<String, dynamic>>[],
  'instanceDataSchema': <String, dynamic>{
    eventField: <String, dynamic>{'type': 'text', 'required': true},
    identityField: <String, dynamic>{'type': 'text', 'required': true},
  },
};

Future<List<WorkflowInstance>> _instancesOf(
  LocalWorkflowEngineApi api,
  String workflowType,
) async => (await api.queryInstances(
  tabId: 'calendar',
  fanId: 'organizer',
  limit: 1000,
)).items.where((row) => row.workflowType == workflowType).toList();

Future<String> _createRawEvent(
  LocalWorkflowEngineApi api,
  String workflowType,
) async => (await api.createInstances(
  workflowType: workflowType,
  initialInstanceDataList: const <Map<String, dynamic>>[
    <String, dynamic>{'title': 'Event'},
  ],
  fanId: 'organizer',
)).single;

void main() {
  test(
    'create action fans out one initial-state row per active registered member',
    () async {
      final api =
          LocalWorkflowEngineApi(
              db: WorkflowDatabase.memory(),
              communityId: 'fan-out',
              activeMembershipLookup: (fanId) => fanId != 'inactive',
            )
            ..setRoleForFan('organizer', 'organizer-role')
            ..setRoleForFan('member-a', 'member-role')
            ..setRoleForFan('member-b', 'member-role')
            ..setRoleForFan('inactive', 'member-role')
            ..registerDefinition(
              _machine(
                'event',
                _eventDefinition(responseWorkflowType: 'response'),
              ),
            )
            ..registerDefinition(_machine('response', _responseDefinition()));
      final eventId = await _createRawEvent(api, 'event');
      expect(await _instancesOf(api, 'response'), isEmpty);

      await api.applyTransition(
        workflowType: 'event',
        instanceId: eventId,
        transitionId: 'act',
        fanId: 'organizer',
      );

      final responses = await _instancesOf(api, 'response');
      expect(responses, hasLength(3));
      expect(responses.map((row) => row.currentState).toSet(), {'pending'});
      expect(responses.map((row) => row.instanceData['eventId']).toSet(), {
        eventId,
      });
      expect(responses.map((row) => row.instanceData['fanId']).toSet(), {
        'organizer',
        'member-a',
        'member-b',
      });

      // An orthogonal create transition may remain available. Reapplying it
      // must not duplicate the already-materialized (event, member) rows.
      await api.applyTransition(
        workflowType: 'event',
        instanceId: eventId,
        transitionId: 'act',
        fanId: 'organizer',
      );
      expect(await _instancesOf(api, 'response'), hasLength(3));
    },
  );

  test('fan-out writes custom eventField and the v4 fanId spelling', () async {
    final api =
        LocalWorkflowEngineApi(
            db: WorkflowDatabase.memory(),
            communityId: 'fan-id',
          )
          ..setRoleForFan('member-a', 'member-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(
                responseWorkflowType: 'response',
                eventField: 'parentEventKey',
              ),
            ),
          )
          ..registerDefinition(
            _machine(
              'response',
              _responseDefinition(
                eventField: 'parentEventKey',
                identityField: 'fanId',
              ),
            ),
          );
    final eventId = await _createRawEvent(api, 'event');

    await api.applyTransition(
      workflowType: 'event',
      instanceId: eventId,
      transitionId: 'act',
      fanId: 'member-a',
    );

    final response = (await _instancesOf(api, 'response')).single;
    expect(response.instanceData, <String, dynamic>{
      'parentEventKey': eventId,
      'fanId': 'member-a',
    });
    expect(response.instanceData, isNot(contains('personaId')));
  });

  test('fan-out is exclusive to event-rsvp create actions', () async {
    final api =
        LocalWorkflowEngineApi(
            db: WorkflowDatabase.memory(),
            communityId: 'scope',
          )
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'document',
              _eventDefinition(
                responseWorkflowType: 'document-response',
                family: 'documentLibrary',
              ),
            ),
          )
          ..registerDefinition(
            _machine('document-response', _responseDefinition()),
          )
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(
                responseWorkflowType: 'event-response',
                transitionAction: 'edit',
              ),
            ),
          )
          ..registerDefinition(
            _machine('event-response', _responseDefinition()),
          );
    final documentId = await _createRawEvent(api, 'document');
    final eventId = await _createRawEvent(api, 'event');

    await api.applyTransition(
      workflowType: 'document',
      instanceId: documentId,
      transitionId: 'act',
      fanId: 'organizer',
    );
    await api.applyTransition(
      workflowType: 'event',
      instanceId: eventId,
      transitionId: 'act',
      fanId: 'organizer',
    );

    expect(await _instancesOf(api, 'document-response'), isEmpty);
    expect(await _instancesOf(api, 'event-response'), isEmpty);
  });

  test(
    'singular create API fans out binding create actions immediately',
    () async {
      final definition = _eventDefinition(
        responseWorkflowType: 'response',
        transitionAction: 'edit',
      );
      final api =
          LocalWorkflowEngineApi(
              db: WorkflowDatabase.memory(),
              communityId: 'binding-create',
            )
            ..setRoleForFan('organizer', 'organizer-role')
            ..setRoleForFan('member-a', 'member-role')
            ..registerDefinition(_machine('event', definition))
            ..registerDefinition(_machine('response', _responseDefinition()));

      final eventId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: const <String, dynamic>{'title': 'Event'},
        fanId: 'organizer',
      );

      final responses = await _instancesOf(api, 'response');
      expect(responses, hasLength(2));
      expect(responses.map((row) => row.instanceData['eventId']).toSet(), {
        eventId,
      });
    },
  );

  test(
    'recurrence-generated event instances fan out before transition returns',
    () async {
      final recurrenceEffects = <Map<String, dynamic>>[
        <String, dynamic>{
          'op': 'generateRecurringInstances',
          'workflowType': 'event',
          'anchorField': 'eventDate',
          'fields': <String, dynamic>{
            'title': '{title}',
            'eventDate': '{eventDate}',
            'seriesId': r'$newSeriesId',
          },
          'recurrenceRule': <String, dynamic>{
            'freq': '{input.freq}',
            'count': '{input.count}',
          },
        },
      ];
      final api =
          LocalWorkflowEngineApi(
              db: WorkflowDatabase.memory(),
              communityId: 'recurrence',
            )
            ..setRoleForFan('organizer', 'organizer-role')
            ..setRoleForFan('member-a', 'member-role')
            ..registerDefinition(
              _machine(
                'event',
                _eventDefinition(
                  responseWorkflowType: 'response',
                  transitionAction: 'edit',
                  effects: recurrenceEffects,
                  inputs: <String, dynamic>{
                    'freq': <String, dynamic>{'type': 'text', 'required': true},
                    'count': <String, dynamic>{
                      'type': 'number',
                      'required': true,
                    },
                  },
                ),
              ),
            )
            ..registerDefinition(_machine('response', _responseDefinition()));
      final anchorId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: const <String, dynamic>{
          'title': 'Weekly event',
          'eventDate': '2026-08-14',
        },
        fanId: 'organizer',
      );

      await api.applyTransition(
        workflowType: 'event',
        instanceId: anchorId,
        transitionId: 'act',
        fanId: 'organizer',
        inputs: const <String, dynamic>{'freq': 'weekly', 'count': 3},
      );

      final events = await _instancesOf(api, 'event');
      final responses = await _instancesOf(api, 'response');
      expect(events, hasLength(3));
      expect(responses, hasLength(6));
      for (final event in events) {
        expect(
          responses.where(
            (row) => row.instanceData['eventId'] == event.instanceId,
          ),
          hasLength(2),
        );
      }
    },
  );
}
