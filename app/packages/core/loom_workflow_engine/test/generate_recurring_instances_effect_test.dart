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
            'seriesId': r'$newSeriesId',
          },
          'recurrenceRule': {
            'freq': '{input.freq}',
            'interval': 1,
            'count': '{input.count}',
          },
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'title': {'type': 'text', 'required': true},
    'eventDate': {'type': 'date', 'required': true},
    'location': {'type': 'text', 'required': true},
    'seriesId': {'type': 'text'},
  },
}, 'event-rsvp');

Future<List<WorkflowInstance>> _events(LocalWorkflowEngineApi api) async =>
    (await api.queryInstances(
      tabId: 'events',
      personaId: 'organizer',
      limit: 50,
    ))
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
      personaId: 'organizer',
      initialInstanceData: {
        'title': 'Friday social',
        'eventDate': '2026-07-10',
        'location': 'Clubhouse',
      },
    );

    await api.applyTransition(
      workflowType: 'event-rsvp',
      instanceId: anchorId,
      transitionId: 'make-recurring',
      personaId: 'organizer',
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
    final dates = events
        .map((event) => event.instanceData['eventDate'] as String)
        .toList()
      ..sort();
    expect(
      dates,
      List.generate(
        12,
        (i) => DateTime(2026, 7, 10)
            .add(Duration(days: i * 7))
            .toIso8601String()
            .substring(0, 10),
      ),
    );
  });

  test('rolls back the series when a runtime rule value is invalid', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'recurrence-atomic',
    );
    api.registerDefinition(_eventMachine());
    final anchorId = await api.createInstance(
      workflowType: 'event-rsvp',
      personaId: 'organizer',
      initialInstanceData: {
        'title': 'Friday social',
        'eventDate': '2026-07-10',
        'location': 'Clubhouse',
      },
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event-rsvp',
        instanceId: anchorId,
        transitionId: 'make-recurring',
        personaId: 'organizer',
        inputs: {'freq': 'weekly', 'count': 5000},
      ),
      throwsA(isA<StateError>()),
    );

    final events = await _events(api);
    expect(events, hasLength(1));
    expect(events.single.instanceId, anchorId);
    expect(events.single.instanceData['seriesId'], isNull);
  });
}
