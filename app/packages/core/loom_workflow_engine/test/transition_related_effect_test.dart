import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

Map<String, dynamic> _targetDefinition() => {
  'initialState': 'waitlisted',
  'states': {
    'waitlisted': {'label': 'Waitlisted'},
    'going': {'label': 'Going'},
  },
  'transitions': [
    {
      'id': 'respond-going',
      'label': 'Going',
      'from': ['waitlisted'],
      'to': 'going',
      'guard': {'formula': 'allowPromotion'},
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text'},
    'rsvpedAt': {'type': 'text'},
    'allowPromotion': {'type': 'bool'},
    'fanId': {'type': 'fanId'},
  },
};

Map<String, dynamic> _sourceDefinition({
  List<Map<String, dynamic>>? onSuccessEffects,
}) {
  final transitionRelated = <String, dynamic>{
    'op': 'transitionRelated',
    'relatedQuery': {
      'workflowType': 'response',
      'filter': {'eventId': '{eventId}', r'$state': 'waitlisted'},
      'sortKey': 'rsvpedAt',
      'limit': 1,
    },
    'transitionId': 'respond-going',
    if (onSuccessEffects != null) 'onSuccessEffects': onSuccessEffects,
  };

  return {
    'initialState': 'open',
    'states': {
      'open': {'label': 'Open'},
      'done': {'label': 'Done'},
    },
    'transitions': [
      {
        'id': 'release-seat',
        'label': 'Release seat',
        'from': ['open'],
        'to': 'done',
        'effects': [
          {
            'op': 'branch',
            'if': 'true',
            'then': [transitionRelated],
          },
        ],
      },
    ],
    'instanceDataSchema': {
      'eventId': {'type': 'text'},
      'fanId': {'type': 'fanId'},
    },
  };
}

Map<String, dynamic> _notificationDefinition() => {
  'initialState': 'unread',
  'states': {
    'unread': {'label': 'Unread'},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'recipientFanId': {'type': 'fanId', 'required': true},
    'kind': {'type': 'text', 'required': true},
  },
};

Future<String> _stateFor(LocalWorkflowEngineApi api, String instanceId) async =>
    (await api.queryInstances(tabId: 'test', personaId: 'member')).items
        .singleWhere((instance) => instance.instanceId == instanceId)
        .currentState;

void main() {
  test('WorkflowEffect parses transitionRelated query fields', () {
    final effect = WorkflowEffect.fromJson({
      'op': 'transitionRelated',
      'relatedQuery': {
        'workflowType': 'event-rsvp-response',
        'filter': {'eventId': '{eventId}', r'$state': 'waitlisted'},
        'sortKey': 'rsvpedAt',
        'limit': 1,
      },
      'transitionId': 'respond-going',
    });

    expect(effect.relatedQuery?.workflowType, 'event-rsvp-response');
    expect(effect.relatedQuery?.filter, {
      'eventId': '{eventId}',
      r'$state': 'waitlisted',
    });
    expect(effect.relatedQuery?.sortKey, 'rsvpedAt');
    expect(effect.relatedQuery?.limit, 1);
    expect(effect.transitionId, 'respond-going');
  });

  test(
    'WorkflowEffect parses recursive transitionRelated onSuccessEffects',
    () {
      final effect = WorkflowEffect.fromJson({
        'op': 'transitionRelated',
        'relatedQuery': {
          'workflowType': 'response',
          'filter': {'eventId': '{eventId}'},
        },
        'transitionId': 'respond-going',
        'onSuccessEffects': [
          {
            'op': 'branch',
            'if': 'true',
            'then': [
              {
                'op': 'createInstance',
                'workflowType': 'notification',
                'fields': {'recipientFanId': '{fanId}'},
              },
            ],
          },
        ],
      });

      expect(effect.onSuccessEffects, hasLength(1));
      expect(effect.onSuccessEffects!.single.thenEffects, hasLength(1));
      expect(
        effect.onSuccessEffects!.single.thenEffects.single.workflowType,
        'notification',
      );
    },
  );

  test('transitionRelated promotes the oldest matching instance', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'transition-related-sort',
    );
    api.registerDefinition(_machine('response', _targetDefinition()));
    api.registerDefinition(_machine('event', _sourceDefinition()));
    final older = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {
        'eventId': 'event-1',
        'rsvpedAt': '2026-07-01T10:00:00Z',
        'allowPromotion': true,
      },
    );
    final newer = await api.createInstance(
      workflowType: 'response',
      personaId: 'member',
      initialInstanceData: {
        'eventId': 'event-1',
        'rsvpedAt': '2026-07-02T10:00:00Z',
        'allowPromotion': true,
      },
    );
    final source = await api.createInstance(
      workflowType: 'event',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-1'},
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: source,
      transitionId: 'release-seat',
      personaId: 'member',
    );

    expect(await _stateFor(api, source), 'done');
    expect(await _stateFor(api, older), 'going');
    expect(await _stateFor(api, newer), 'waitlisted');
  });

  test(
    'transitionRelated silently no-ops when the target guard fails',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'transition-related-guard',
      );
      api.registerDefinition(_machine('response', _targetDefinition()));
      api.registerDefinition(_machine('event', _sourceDefinition()));
      final target = await api.createInstance(
        workflowType: 'response',
        personaId: 'member',
        initialInstanceData: {
          'eventId': 'event-1',
          'rsvpedAt': '2026-07-01T10:00:00Z',
          'allowPromotion': false,
        },
      );
      final source = await api.createInstance(
        workflowType: 'event',
        personaId: 'member',
        initialInstanceData: {'eventId': 'event-1'},
      );

      await expectLater(
        api.applyTransition(
          workflowType: 'event',
          instanceId: source,
          transitionId: 'release-seat',
          personaId: 'member',
        ),
        completes,
      );

      expect(await _stateFor(api, source), 'done');
      expect(await _stateFor(api, target), 'waitlisted');
    },
  );

  test('transitionRelated silently no-ops when no instance matches', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'transition-related-empty',
    );
    api.registerDefinition(_machine('response', _targetDefinition()));
    api.registerDefinition(_machine('event', _sourceDefinition()));
    final source = await api.createInstance(
      workflowType: 'event',
      personaId: 'member',
      initialInstanceData: {'eventId': 'event-without-responses'},
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event',
        instanceId: source,
        transitionId: 'release-seat',
        personaId: 'member',
      ),
      completes,
    );

    expect(await _stateFor(api, source), 'done');
  });

  test(
    'transitionRelated onSuccessEffects run once with target data',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'transition-related-success-effects',
      );
      api.registerDefinition(_machine('response', _targetDefinition()));
      api.registerDefinition(
        _machine(
          'event',
          _sourceDefinition(
            onSuccessEffects: [
              {
                'op': 'createInstance',
                'workflowType': 'notification',
                'fields': {'recipientFanId': '{fanId}', 'kind': 'promotion'},
              },
              {
                'op': 'createInstance',
                'workflowType': 'notification',
                'fields': {'recipientFanId': '{fanId}', 'kind': 'audit'},
              },
            ],
          ),
        ),
      );
      api.registerDefinition(
        _machine('notification', _notificationDefinition()),
      );

      final target = await api.createInstance(
        workflowType: 'response',
        personaId: 'promoted-member',
        initialInstanceData: {
          'eventId': 'event-1',
          'rsvpedAt': '2026-07-01T10:00:00Z',
          'allowPromotion': true,
          'fanId': 'promoted-member',
        },
      );
      final source = await api.createInstance(
        workflowType: 'event',
        personaId: 'source-actor',
        initialInstanceData: {'eventId': 'event-1', 'fanId': 'source-actor'},
      );

      await api.applyTransition(
        workflowType: 'event',
        instanceId: source,
        transitionId: 'release-seat',
        personaId: 'source-actor',
      );

      final notifications =
          (await api.queryInstances(
                tabId: 'messages',
                personaId: 'source-actor',
              )).items
              .where((instance) => instance.workflowType == 'notification')
              .toList();
      expect(notifications, hasLength(2));
      expect(
        notifications.map((instance) => instance.instanceData['kind']).toSet(),
        {'promotion', 'audit'},
      );
      expect(
        notifications
            .map((instance) => instance.instanceData['recipientFanId'])
            .toSet(),
        {'promoted-member'},
      );
      expect(await _stateFor(api, target), 'going');
    },
  );

  test(
    'transitionRelated onSuccessEffects do not run on target guard failure',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'transition-related-failed-success-effects',
      );
      api.registerDefinition(_machine('response', _targetDefinition()));
      api.registerDefinition(
        _machine(
          'event',
          _sourceDefinition(
            onSuccessEffects: [
              {
                'op': 'createInstance',
                'workflowType': 'notification',
                'fields': {'recipientFanId': '{fanId}', 'kind': 'promotion'},
              },
            ],
          ),
        ),
      );
      api.registerDefinition(
        _machine('notification', _notificationDefinition()),
      );

      final target = await api.createInstance(
        workflowType: 'response',
        personaId: 'promoted-member',
        initialInstanceData: {
          'eventId': 'event-1',
          'rsvpedAt': '2026-07-01T10:00:00Z',
          'allowPromotion': false,
          'fanId': 'promoted-member',
        },
      );
      final source = await api.createInstance(
        workflowType: 'event',
        personaId: 'source-actor',
        initialInstanceData: {'eventId': 'event-1', 'fanId': 'source-actor'},
      );

      await api.applyTransition(
        workflowType: 'event',
        instanceId: source,
        transitionId: 'release-seat',
        personaId: 'source-actor',
      );

      final notifications =
          (await api.queryInstances(
                tabId: 'messages',
                personaId: 'source-actor',
              )).items
              .where((instance) => instance.workflowType == 'notification')
              .toList();
      expect(notifications, isEmpty);
      expect(await _stateFor(api, target), 'waitlisted');
    },
  );
}
