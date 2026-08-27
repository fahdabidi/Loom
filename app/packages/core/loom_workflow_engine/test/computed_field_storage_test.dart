import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType,
  Map<String, dynamic> definition,
) => LoomWorkflowStateMachine.fromJson(definition, workflowType);

Map<String, dynamic> _computedTransitionDefinition() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'closed': {'label': 'Closed'},
  },
  'transitions': [
    {
      'id': 'close',
      'label': 'Close',
      'from': ['open'],
      'to': 'closed',
    },
  ],
  'instanceDataSchema': {
    'title': {'type': 'text', 'required': true},
    'eventDate': {'type': 'date', 'required': true},
    'eventTime': {'type': 'time', 'required': true},
    'reminderOffsetHours': {'type': 'number', 'required': true},
    'reminderAt': {
      'type': 'date',
      'formula':
          'subtractHours(combineDateAndTime(eventDate, eventTime), reminderOffsetHours)',
    },
  },
};

Map<String, dynamic> _relatedTargetDefinition() => {
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
    'eventDate': {'type': 'date', 'required': true},
    'eventTime': {'type': 'time', 'required': true},
    'reminderOffsetHours': {'type': 'number', 'required': true},
    'marker': {'type': 'text', 'required': true},
    'reminderAt': {
      'type': 'date',
      'formula':
          'subtractHours(combineDateAndTime(eventDate, eventTime), reminderOffsetHours)',
    },
  },
};

Map<String, dynamic> _relatedSourceDefinition() => {
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
            'sortKey': 'eventDate',
            'limit': 1,
          },
          'transitionId': 'promote',
          'onSuccessEffects': [
            {'op': 'set', 'key': 'marker', 'value': 'promoted'},
          ],
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'eventId': {'type': 'text', 'required': true},
    'eventDate': {'type': 'date', 'required': true},
    'eventTime': {'type': 'time', 'required': true},
    'reminderOffsetHours': {'type': 'number', 'required': true},
    'reminderAt': {
      'type': 'date',
      'formula':
          'subtractHours(combineDateAndTime(eventDate, eventTime), reminderOffsetHours)',
    },
  },
};

Future<Map<String, dynamic>> _rawStoredData(
  WorkflowDatabase database,
  String instanceId,
) async {
  final row = await database.readInstance(instanceId);
  expect(row, isNotNull);
  return jsonDecode(row!.instanceData) as Map<String, dynamic>;
}

void main() {
  test(
    'transition writes omit date-valued computed fields and re-evaluate them on read',
    () async {
      final database = WorkflowDatabase.memory();
      addTearDown(database.close);
      final api = LocalWorkflowEngineApi(
        db: database,
        communityId: 'computed-transition-storage',
      )..registerDefinition(_machine('event', _computedTransitionDefinition()));

      final instanceId = await api.createInstance(
        workflowType: 'event',
        fanId: 'organizer',
        initialInstanceData: {
          'title': 'Evening game',
          'eventDate': '2026-07-20',
          'eventTime': '19:30',
          'reminderOffsetHours': 24,
        },
      );

      final result = await api.applyTransition(
        workflowType: 'event',
        instanceId: instanceId,
        transitionId: 'close',
        fanId: 'organizer',
      );

      expect(result.newState, 'closed');
      final stored = await _rawStoredData(database, instanceId);
      expect(stored, isNot(contains('reminderAt')));

      final page = await api.queryInstances(
        tabId: 'calendar',
        fanId: 'member',
        limit: 10,
      );
      final instance = page.items.singleWhere(
        (item) => item.instanceId == instanceId,
      );
      expect(instance.currentState, 'closed');
      expect(
        instance.instanceData['reminderAt'],
        DateTime.utc(2026, 7, 19, 19, 30),
      );
    },
  );

  test(
    'transitionRelated onSuccessEffects omit computed fields from the target write',
    () async {
      final database = WorkflowDatabase.memory();
      addTearDown(database.close);
      final api =
          LocalWorkflowEngineApi(
              db: database,
              communityId: 'computed-related-storage',
            )
            ..registerDefinition(
              _machine('response', _relatedTargetDefinition()),
            )
            ..registerDefinition(_machine('event', _relatedSourceDefinition()));

      final targetId = await api.createInstance(
        workflowType: 'response',
        fanId: 'member',
        initialInstanceData: {
          'eventId': 'event-1',
          'eventDate': '2026-07-20',
          'eventTime': '19:30',
          'reminderOffsetHours': 24,
          'marker': 'waiting',
        },
      );
      final sourceId = await api.createInstance(
        workflowType: 'event',
        fanId: 'organizer',
        initialInstanceData: {
          'eventId': 'event-1',
          'eventDate': '2026-07-21',
          'eventTime': '19:30',
          'reminderOffsetHours': 24,
        },
      );

      final result = await api.applyTransition(
        workflowType: 'event',
        instanceId: sourceId,
        transitionId: 'release-seat',
        fanId: 'organizer',
      );

      expect(result.newState, 'done');
      final storedSource = await _rawStoredData(database, sourceId);
      expect(storedSource, isNot(contains('reminderAt')));
      final storedTarget = await _rawStoredData(database, targetId);
      expect(storedTarget, isNot(contains('reminderAt')));
      expect(storedTarget['marker'], 'promoted');

      final page = await api.queryInstances(
        tabId: 'calendar',
        fanId: 'member',
        limit: 10,
      );
      final target = page.items.singleWhere(
        (item) => item.instanceId == targetId,
      );
      expect(target.currentState, 'going');
      expect(target.instanceData['reminderAt'], DateTime.utc(2026, 7, 19, 19, 30));
    },
  );
}
