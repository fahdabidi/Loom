import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      'editableFields': ['location'],
      'creationGuard': {
        'locationOverlap': {
          'locationField': 'location',
          'dateField': 'eventDate',
          'timeField': 'eventTime',
          'durationMinutes': 120,
        },
      },
      'editGuard': {
        'locationOverlap': {
          'locationField': 'location',
          'dateField': 'eventDate',
          'timeField': 'eventTime',
          'durationMinutes': 120,
        },
      },
    },
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'location': {'type': 'text', 'required': true},
    'eventDate': {'type': 'date', 'required': true},
    'eventTime': {'type': 'time', 'required': true},
  },
}, 'event');

Map<String, dynamic> _event(String location, String time) => {
  'location': location,
  'eventDate': '2026-07-10',
  'eventTime': time,
};

void main() {
  group('locationOverlap creationGuard', () {
    late LocalWorkflowEngineApi api;

    setUp(() {
      api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'location-overlap',
      )..registerDefinition(_machine());
    });

    test(
      'blocks creation of an overlapping booking at the same location',
      () async {
        await api.createInstance(
          workflowType: 'event',
          initialInstanceData: _event('Main hall', '10:00'),
          fanId: 'organizer',
        );

        await expectLater(
          api.createInstance(
            workflowType: 'event',
            initialInstanceData: _event('Main hall', '11:30'),
            fanId: 'organizer',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'allows adjacent, non-overlapping bookings at the same location',
      () async {
        await api.createInstance(
          workflowType: 'event',
          initialInstanceData: _event('Main hall', '10:00'),
          fanId: 'organizer',
        );

        final secondId = await api.createInstance(
          workflowType: 'event',
          initialInstanceData: _event('Main hall', '12:00'),
          fanId: 'organizer',
        );

        expect(secondId, isNotEmpty);
      },
    );

    test('allows overlapping bookings at different locations', () async {
      await api.createInstance(
        workflowType: 'event',
        initialInstanceData: _event('Main hall', '10:00'),
        fanId: 'organizer',
      );

      final secondId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: _event('Community room', '10:30'),
        fanId: 'organizer',
      );

      expect(secondId, isNotEmpty);
    });

    test('excludes the instance being edited from its sibling scan', () async {
      final instanceId = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: _event('Main hall', '10:00'),
        fanId: 'organizer',
      );

      await api.updateInstanceFields(
        workflowType: 'event',
        instanceId: instanceId,
        fieldUpdates: {'location': 'Main hall'},
        fanId: 'organizer',
      );
    });
  });
}
