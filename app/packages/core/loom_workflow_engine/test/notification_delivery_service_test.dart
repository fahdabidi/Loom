import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

class _FakeNotificationDeliveryService implements NotificationDeliveryService {
  final deliveries = <WorkflowInstance>[];

  @override
  Future<void> deliver(WorkflowInstance notification) async {
    deliveries.add(notification);
  }
}

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

Map<String, dynamic> _notificationDefinition() => {
  'initialState': 'unread',
  'states': {
    'unread': {'label': 'Unread'},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'recipientFanId': {'type': 'fanId', 'required': true},
    'title': {'type': 'text', 'required': true},
    'body': {'type': 'text', 'required': true},
    'createdAt': {'type': 'text', 'required': true},
  },
};

Map<String, dynamic> _plainDefinition() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'title': {'type': 'text', 'required': true},
  },
};

Map<String, dynamic> _promotionSourceDefinition() => {
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
          'op': 'transitionRelated',
          'relatedQuery': {
            'workflowType': 'response',
            'filter': {'eventId': '{eventId}', r'$state': 'waitlisted'},
            'sortKey': 'rsvpedAt',
            'limit': 1,
          },
          'transitionId': 'promote',
          'onSuccessEffects': [
            {
              'op': 'createInstance',
              'workflowType': 'notification',
              'fields': {
                'recipientFanId': '{fanId}',
                'title': 'You are off the waitlist',
                'body': 'A seat opened up for this event.',
                'createdAt': '2026-07-31T12:00:00Z',
              },
            },
          ],
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text', 'required': true},
  },
};

Map<String, dynamic> _responseDefinition() => {
  'initialState': 'waitlisted',
  'states': {
    'waitlisted': {'label': 'Waitlisted'},
    'going': {'label': 'Going'},
  },
  'transitions': [
    {
      'id': 'promote',
      'label': 'Promote',
      'from': ['waitlisted'],
      'to': 'going',
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text', 'required': true},
    'rsvpedAt': {'type': 'text', 'required': true},
    'fanId': {'type': 'fanId', 'required': true},
  },
};

LocalWorkflowEngineApi _api(
  _FakeNotificationDeliveryService? deliveryService, {
  required String communityId,
}) {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: communityId,
    notificationDeliveryService: deliveryService,
  );
  api.registerDefinition(_machine('notification', _notificationDefinition()));
  return api;
}

Future<void> _allowFireAndForgetToRun() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'creating a notification directly delivers exactly once with title and body',
    () async {
      final fake = _FakeNotificationDeliveryService();
      final api = _api(fake, communityId: 'notification-direct');

      await api.createInstance(
        workflowType: 'notification',
        fanId: 'member',
        initialInstanceData: {
          'recipientFanId': 'member',
          'title': 'A seat opened',
          'body': 'You are now going to Friday game night.',
          'createdAt': '2026-07-31T12:00:00Z',
        },
      );
      await _allowFireAndForgetToRun();

      expect(fake.deliveries, hasLength(1));
      expect(fake.deliveries.single.instanceData['title'], 'A seat opened');
      expect(
        fake.deliveries.single.instanceData['body'],
        'You are now going to Friday game night.',
      );
    },
  );

  test('creating a non-notification instance does not deliver', () async {
    final fake = _FakeNotificationDeliveryService();
    final api = _api(fake, communityId: 'notification-filter');
    api.registerDefinition(_machine('event', _plainDefinition()));

    await api.createInstance(
      workflowType: 'event',
      fanId: 'organizer',
      initialInstanceData: {'title': 'Friday game night'},
    );
    await _allowFireAndForgetToRun();

    expect(fake.deliveries, isEmpty);
  });

  test(
    'transitionRelated onSuccessEffects deliver the created notification once',
    () async {
      final fake = _FakeNotificationDeliveryService();
      final api = _api(fake, communityId: 'notification-promotion');
      api
        ..registerDefinition(_machine('response', _responseDefinition()))
        ..registerDefinition(_machine('event', _promotionSourceDefinition()));

      await api.createInstance(
        workflowType: 'response',
        fanId: 'promoted-member',
        initialInstanceData: {
          'eventId': 'event-1',
          'rsvpedAt': '2026-07-01T10:00:00Z',
          'fanId': 'promoted-member',
        },
      );
      final eventId = await api.createInstance(
        workflowType: 'event',
        fanId: 'organizer',
        initialInstanceData: {'eventId': 'event-1'},
      );

      await api.applyTransition(
        workflowType: 'event',
        instanceId: eventId,
        transitionId: 'release-seat',
        fanId: 'organizer',
      );
      await _allowFireAndForgetToRun();

      expect(fake.deliveries, hasLength(1));
      expect(
        fake.deliveries.single.instanceData['title'],
        'You are off the waitlist',
      );
      expect(
        fake.deliveries.single.instanceData['body'],
        'A seat opened up for this event.',
      );
      expect(
        fake.deliveries.single.instanceData['recipientFanId'],
        'promoted-member',
      );
    },
  );

  test(
    'notification creation succeeds when no delivery service is configured',
    () async {
      final api = _api(null, communityId: 'notification-optional');

      final id = await api.createInstance(
        workflowType: 'notification',
        fanId: 'member',
        initialInstanceData: {
          'recipientFanId': 'member',
          'title': 'Still persisted',
          'body': 'Delivery is optional.',
          'createdAt': '2026-07-31T12:00:00Z',
        },
      );

      final notification = (await api.queryInstances(
        tabId: 'notifications',
        fanId: 'member',
      )).items.singleWhere((instance) => instance.instanceId == id);
      expect(notification.instanceData['title'], 'Still persisted');
    },
  );
}
