import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _guard = WorkflowGuard(
  cancellationDeadline: CancellationDeadlineGuard(
    dateField: 'eventDate',
    timeField: 'eventTime',
    hoursBefore: 24,
  ),
);

void main() {
  group('cancellationDeadline guard', () {
    test('passes well before the deadline', () {
      expect(
        evaluateGuard(_guard, 'member', {
          'eventDate': '2026-07-10',
          'eventTime': '19:00',
        }, clock: () => DateTime(2026, 7, 7)),
        isTrue,
      );
    });

    test('fails inside the hoursBefore window', () {
      expect(
        evaluateGuard(_guard, 'member', {
          'eventDate': '2026-07-10',
          'eventTime': '19:00',
        }, clock: () => DateTime(2026, 7, 10, 18)),
        isFalse,
      );
    });

    test('fails after the event has passed', () {
      expect(
        evaluateGuard(_guard, 'member', {
          'eventDate': '2026-07-10',
          'eventTime': '19:00',
        }, clock: () => DateTime(2026, 7, 11)),
        isFalse,
      );
    });

    test('uses midnight when the time field is omitted', () {
      const allDayGuard = WorkflowGuard(
        cancellationDeadline: CancellationDeadlineGuard(
          dateField: 'eventDate',
          hoursBefore: 24,
        ),
      );

      expect(
        evaluateGuard(allDayGuard, 'member', {
          'eventDate': '2026-07-10',
        }, clock: () => DateTime(2026, 7, 8, 23, 59)),
        isTrue,
      );
      expect(
        evaluateGuard(allDayGuard, 'member', {
          'eventDate': '2026-07-10',
        }, clock: () => DateTime(2026, 7, 9, 0, 1)),
        isFalse,
      );
    });

    test('fails safely for missing or malformed date and time fields', () {
      expect(
        evaluateGuard(_guard, 'member', const {}, clock: DateTime.now),
        isFalse,
      );
      expect(
        evaluateGuard(_guard, 'member', {
          'eventDate': 'not-a-date',
          'eventTime': '19:00',
        }, clock: DateTime.now),
        isFalse,
      );
      expect(
        evaluateGuard(_guard, 'member', {
          'eventDate': '2026-07-10',
          'eventTime': 'not-a-time',
        }, clock: DateTime.now),
        isFalse,
      );
    });

    test(
      'applyTransition blocks inside the window and succeeds outside it',
      () async {
        final outsideDb = WorkflowDatabase.memory();
        final outsideApi = LocalWorkflowEngineApi(
          db: outsideDb,
          communityId: 'outside-deadline',
          clock: () => DateTime(2026, 7, 8),
        )..registerDefinition(_machine());
        final outsideId = await outsideApi.createInstance(
          workflowType: 'event',
          initialInstanceData: {
            'eventDate': '2026-07-10',
            'eventTime': '19:00',
          },
          fanId: 'member',
        );
        final result = await outsideApi.applyTransition(
          workflowType: 'event',
          instanceId: outsideId,
          transitionId: 'cancel',
          fanId: 'member',
        );
        expect(result.newState, 'cancelled');
        outsideDb.close();

        final insideDb = WorkflowDatabase.memory();
        final insideApi = LocalWorkflowEngineApi(
          db: insideDb,
          communityId: 'inside-deadline',
          clock: () => DateTime(2026, 7, 10, 18),
        )..registerDefinition(_machine());
        final insideId = await insideApi.createInstance(
          workflowType: 'event',
          initialInstanceData: {
            'eventDate': '2026-07-10',
            'eventTime': '19:00',
          },
          fanId: 'member',
        );
        await expectLater(
          insideApi.applyTransition(
            workflowType: 'event',
            instanceId: insideId,
            transitionId: 'cancel',
            fanId: 'member',
          ),
          throwsStateError,
        );
        insideDb.close();
      },
    );
  });
}

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'scheduled',
  'states': {
    'scheduled': {'label': 'Scheduled'},
    'cancelled': {'label': 'Cancelled', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'cancel',
      'label': 'Cancel',
      'from': ['scheduled'],
      'to': 'cancelled',
      'guard': {
        'cancellationDeadline': {
          'dateField': 'eventDate',
          'timeField': 'eventTime',
          'hoursBefore': 24,
        },
      },
    },
  ],
  'instanceDataSchema': {
    'eventDate': {'type': 'date', 'required': true},
    'eventTime': {'type': 'time', 'required': true},
  },
}, 'event');
