import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _eventMachine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'draft',
  'states': {
    'draft': {'label': 'Draft'},
    'published': {'label': 'Published'},
  },
  'transitions': [
    {
      'id': 'make-recurring',
      'label': 'Make recurring',
      'from': ['draft'],
      'to': 'published',
      'inputs': {
        'freq': {'type': 'text', 'required': true},
        'count': {'type': 'number', 'required': true},
        'interval': {'type': 'number'},
        'byDayOfWeek': {'type': 'text'},
        'byMonthDay': {'type': 'number'},
        'bySetPos': {'type': 'text'},
      },
      'effects': [
        {
          'op': 'generateRecurringInstances',
          'workflowType': 'event-rsvp',
          'anchorField': 'eventDate',
          'fields': {
            'title': '{title}',
            'eventDate': '{eventDate}',
            'location': '{location}',
            'capacity': '{capacity}',
            'goingCount': '{goingCount}',
            'seriesId': r'$newSeriesId',
          },
          'recurrenceRule': {
            'freq': '{input.freq}',
            'interval': '{input.interval}',
            'count': '{input.count}',
            'byDayOfWeek': '{input.byDayOfWeek}',
            'byMonthDay': '{input.byMonthDay}',
            'bySetPos': '{input.bySetPos}',
          },
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'title': {'type': 'text', 'required': true},
    'eventDate': {'type': 'date', 'required': true},
    'location': {'type': 'text', 'required': true},
    'capacity': {'type': 'number', 'required': true},
    'goingCount': {'type': 'number', 'required': true},
    'isFull': {'type': 'bool', 'formula': 'goingCount >= capacity'},
    'seriesId': {'type': 'text'},
  },
}, 'event-rsvp');

Future<List<WorkflowInstance>> _events(LocalWorkflowEngineApi api) async =>
    (await api.queryInstances(tabId: 'events', fanId: 'organizer', limit: 50))
        .items
        .where((instance) => instance.workflowType == 'event-rsvp')
        .toList();

void main() {
  test('generates sibling instances and stamps one minted series id', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'recurrence-series',
    );
    api.registerDefinition(_eventMachine());
    final anchorId = await api.createInstance(
      workflowType: 'event-rsvp',
      fanId: 'organizer',
      initialInstanceData: {
        'title': 'Friday social',
        'eventDate': '2026-07-10',
        'location': 'Clubhouse',
        'capacity': 20,
        'goingCount': 3,
      },
    );

    await api.applyTransition(
      workflowType: 'event-rsvp',
      instanceId: anchorId,
      transitionId: 'make-recurring',
      fanId: 'organizer',
      inputs: {'freq': 'weekly', 'count': 12},
    );

    final events = await _events(api);
    expect(events, hasLength(12));
    final anchor = events.singleWhere((event) => event.instanceId == anchorId);
    final seriesId = anchor.instanceData['seriesId'];
    expect(seriesId, isA<String>());
    expect(seriesId, isNotEmpty);
    expect(
      events.every((event) => event.instanceData['seriesId'] == seriesId),
      isTrue,
    );
    final dates =
        events
            .map((event) => event.instanceData['eventDate'] as String)
            .toList()
          ..sort();
    expect(
      dates,
      List.generate(
        12,
        (i) => DateTime(
          2026,
          7,
          10,
        ).add(Duration(days: i * 7)).toIso8601String().substring(0, 10),
      ),
    );
  });

  test(
    'preserves number copies for generated siblings and evaluates their formulas',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'recurrence-number-copy',
      );
      api.registerDefinition(_eventMachine());
      final anchorId = await api.createInstance(
        workflowType: 'event-rsvp',
        fanId: 'organizer',
        initialInstanceData: {
          'title': 'Friday social',
          'eventDate': '2026-07-10',
          'location': 'Clubhouse',
          'capacity': 20,
          'goingCount': 3,
        },
      );

      await api.applyTransition(
        workflowType: 'event-rsvp',
        instanceId: anchorId,
        transitionId: 'make-recurring',
        fanId: 'organizer',
        inputs: {
          'freq': 'weekly',
          'count': 3,
          'byDayOfWeek': ['FR'],
        },
      );

      final siblings = (await _events(
        api,
      )).where((event) => event.instanceId != anchorId).toList();
      expect(siblings, hasLength(2));
      for (final sibling in siblings) {
        expect(sibling.instanceData['capacity'], isA<num>());
        expect(sibling.instanceData['capacity'], 20);
        expect(sibling.instanceData['isFull'], isFalse);
      }
    },
  );

  test(
    'uses supplied weekly weekdays while omitted optional fields resolve null',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'recurrence-optional-weekly',
      );
      api.registerDefinition(_eventMachine());
      final anchorId = await api.createInstance(
        workflowType: 'event-rsvp',
        fanId: 'organizer',
        initialInstanceData: {
          'title': 'Wednesday social',
          'eventDate': '2026-07-08',
          'location': 'Clubhouse',
          'capacity': 20,
          'goingCount': 3,
        },
      );

      await api.applyTransition(
        workflowType: 'event-rsvp',
        instanceId: anchorId,
        transitionId: 'make-recurring',
        fanId: 'organizer',
        inputs: {
          'freq': 'weekly',
          'count': 5,
          'byDayOfWeek': ['MO'],
        },
      );

      final dates =
          (await _events(api))
              .map((event) => event.instanceData['eventDate'] as String)
              .toList()
            ..sort();
      expect(dates, [
        '2026-07-08',
        '2026-07-13',
        '2026-07-20',
        '2026-07-27',
        '2026-08-03',
      ]);
    },
  );

  test(
    'defaults daily interval when all optional inputs are omitted',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'recurrence-optional-daily',
      );
      api.registerDefinition(_eventMachine());
      final anchorId = await api.createInstance(
        workflowType: 'event-rsvp',
        fanId: 'organizer',
        initialInstanceData: {
          'title': 'Daily standup',
          'eventDate': '2026-07-10',
          'location': 'Clubhouse',
          'capacity': 20,
          'goingCount': 3,
        },
      );

      await api.applyTransition(
        workflowType: 'event-rsvp',
        instanceId: anchorId,
        transitionId: 'make-recurring',
        fanId: 'organizer',
        inputs: {'freq': 'daily', 'count': 3},
      );

      final dates =
          (await _events(api))
              .map((event) => event.instanceData['eventDate'] as String)
              .toList()
            ..sort();
      expect(dates, ['2026-07-10', '2026-07-11', '2026-07-12']);
    },
  );

  test('rolls back the series when a runtime rule value is invalid', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'recurrence-atomic',
    );
    api.registerDefinition(_eventMachine());
    final anchorId = await api.createInstance(
      workflowType: 'event-rsvp',
      fanId: 'organizer',
      initialInstanceData: {
        'title': 'Friday social',
        'eventDate': '2026-07-10',
        'location': 'Clubhouse',
        'capacity': 20,
        'goingCount': 3,
      },
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event-rsvp',
        instanceId: anchorId,
        transitionId: 'make-recurring',
        fanId: 'organizer',
        inputs: {'freq': 'weekly', 'count': 5000},
      ),
      throwsA(isA<StateError>()),
    );

    final events = await _events(api);
    expect(events, hasLength(1));
    expect(events.single.instanceId, anchorId);
    expect(events.single.instanceData['seriesId'], isNull);
  });

  test(
    'createInstance still interpolates embedded field tokens as strings',
    () async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'embedded-field-copy',
      );
      api.registerDefinition(
        LoomWorkflowStateMachine.fromJson({
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'note': {'type': 'text'},
          },
        }, 'event-copy'),
      );
      api.registerDefinition(
        LoomWorkflowStateMachine.fromJson({
          'initialState': 'draft',
          'states': {
            'draft': {'label': 'Draft'},
          },
          'transitions': [
            {
              'id': 'copy',
              'label': 'Copy',
              'from': ['draft'],
              'to': null,
              'effects': [
                {
                  'op': 'createInstance',
                  'workflowType': 'event-copy',
                  'fields': {'note': '{title} (copy)'},
                },
              ],
            },
          ],
          'instanceDataSchema': {
            'title': {'type': 'text'},
          },
        }, 'event-source'),
      );
      final sourceId = await api.createInstance(
        workflowType: 'event-source',
        fanId: 'organizer',
        initialInstanceData: {'title': 'Friday social'},
      );

      await api.applyTransition(
        workflowType: 'event-source',
        instanceId: sourceId,
        transitionId: 'copy',
        fanId: 'organizer',
      );

      final copies =
          (await api.queryInstances(tabId: 'events', fanId: 'organizer')).items
              .where((instance) => instance.workflowType == 'event-copy')
              .toList();
      expect(copies, hasLength(1));
      expect(copies.single.instanceData['note'], 'Friday social (copy)');
    },
  );
}
