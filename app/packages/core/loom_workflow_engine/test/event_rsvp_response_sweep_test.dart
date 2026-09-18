// Tests for the engine-owned response-row sweep that runs when an
// `event-rsvp` parent event is cancelled -- the exact mirror of
// `_fanOutEventRsvpResponseRows`, which creates those same rows on `create`.
// See `docs/references/archetypes/event-rsvp.md` §4 "Who ends a row".

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType,
  Map<String, dynamic> json,
) => LoomWorkflowStateMachine.fromJson(json, workflowType);

Map<String, dynamic> _eventDefinition({
  required String responseWorkflowType,
  String family = 'event-rsvp',
  bool declareResponseTable = true,
  Map<String, dynamic>? cancelGuard,
}) => <String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{'label': 'Open'},
    'cancelled': <String, dynamic>{'label': 'Cancelled', 'isTerminal': true},
  },
  'transitions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'cancel-event',
      'label': 'Cancel event',
      'action': 'cancel',
      'from': <String>['open'],
      'to': 'cancelled',
      'guard':
          cancelGuard ??
          <String, dynamic>{
            'allowedRoleIds': <String>['organizer-role'],
          },
    },
  ],
  'renderBindings': <Map<String, dynamic>>[
    <String, dynamic>{
      'states': <String>['open'],
      'audience': 'any',
      'tabId': 'calendar',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
      if (declareResponseTable)
        'responseTable': <String, dynamic>{
          'workflowType': responseWorkflowType,
          'eventField': 'eventId',
          'pendingStates': <String>['pending'],
        },
    },
  ],
  'instanceDataSchema': <String, dynamic>{
    'title': <String, dynamic>{'type': 'text'},
  },
};

/// The default response definition's single `response-cancelled` transition
/// mirrors Garden/Book/Camera/Soccer's shape: one `action: "cancel"`
/// transition whose `from` lists every non-terminal state. Its
/// `sweepMarker` effect (`$actor`) doubles as evidence the sweep both
/// reaches a row's effects and threads the cancelling actor through, the way
/// `transitionRelated`'s cross-instance effects already do.
Map<String, dynamic> _responseDefinition({
  List<Map<String, dynamic>>? transitions,
}) => <String, dynamic>{
  'initialState': 'pending',
  'states': <String, dynamic>{
    'pending': <String, dynamic>{'label': 'Pending'},
    'going': <String, dynamic>{'label': 'Going'},
    'maybe': <String, dynamic>{'label': 'Maybe'},
    'waitlisted': <String, dynamic>{'label': 'Waitlisted'},
    'declined': <String, dynamic>{'label': 'Declined'},
    'cancelled': <String, dynamic>{'label': 'Cancelled', 'isTerminal': true},
  },
  'transitions':
      transitions ??
      <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'response-cancelled',
          'label': 'Event cancelled',
          'action': 'cancel',
          'from': <String>[
            'pending',
            'going',
            'maybe',
            'waitlisted',
            'declined',
          ],
          'to': 'cancelled',
          'guard': <String, dynamic>{
            'allowedRoleIds': <String>['coordinator-role'],
          },
          'effects': <Map<String, dynamic>>[
            <String, dynamic>{
              'op': 'set',
              'key': 'sweepMarker',
              'value': r'$actor',
            },
          ],
        },
      ],
  'renderBindings': <Map<String, dynamic>>[],
  'instanceDataSchema': <String, dynamic>{
    'eventId': <String, dynamic>{'type': 'text', 'required': true},
    'fanId': <String, dynamic>{'type': 'text', 'required': true},
    'sweepMarker': <String, dynamic>{'type': 'text', 'writableBy': 'effect'},
  },
};

Future<void> _seedEvent(
  LocalWorkflowEngineApi api, {
  required String workflowType,
  required String instanceId,
  String state = 'open',
}) => api.seedInstances(<WorkflowInstance>[
  WorkflowInstance(
    instanceId: instanceId,
    workflowType: workflowType,
    currentState: state,
    instanceData: const <String, dynamic>{'title': 'Event'},
    createdByFanId: 'organizer',
  ),
]);

Future<void> _seedResponse(
  LocalWorkflowEngineApi api, {
  required String workflowType,
  required String instanceId,
  required String eventId,
  required String fanId,
  required String state,
}) => api.seedInstances(<WorkflowInstance>[
  WorkflowInstance(
    instanceId: instanceId,
    workflowType: workflowType,
    currentState: state,
    instanceData: <String, dynamic>{'eventId': eventId, 'fanId': fanId},
    createdByFanId: fanId,
  ),
]);

Future<WorkflowInstance> _read(
  LocalWorkflowEngineApi api,
  String workflowType,
  String instanceId,
) async =>
    (await api.queryInstances(
      tabId: 'calendar',
      fanId: 'organizer',
      limit: 1000,
    )).items.singleWhere(
      (row) => row.workflowType == workflowType && row.instanceId == instanceId,
    );

Future<List<WorkflowInstance>> _all(
  LocalWorkflowEngineApi api,
  String workflowType,
) async => (await api.queryInstances(
  tabId: 'calendar',
  fanId: 'organizer',
  limit: 1000,
)).items.where((row) => row.workflowType == workflowType).toList();

void main() {
  test('cancelling the event moves every response row, even duplicates within '
      'one state -- the shipped defect moved only one row per state', () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'a')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(_machine('response', _responseDefinition()));

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-going-1',
      eventId: 'evt',
      fanId: 'member-a',
      state: 'going',
    );
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-going-2',
      eventId: 'evt',
      fanId: 'member-b',
      state: 'going',
    );
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-maybe',
      eventId: 'evt',
      fanId: 'member-c',
      state: 'maybe',
    );
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-waitlisted',
      eventId: 'evt',
      fanId: 'member-d',
      state: 'waitlisted',
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final rows = await _all(api, 'response');
    expect(rows, hasLength(4));
    expect(rows.map((row) => row.currentState).toSet(), {'cancelled'});
    // The cancelling actor -- not the response row's own fanId -- is what
    // the sweep threads through as $actor.
    expect(rows.map((row) => row.instanceData['sweepMarker']).toSet(), {
      'organizer',
    });
  });

  test('a row already in a terminal state is left exactly as it was', () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'b')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(_machine('response', _responseDefinition()));

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-already-cancelled',
      eventId: 'evt',
      fanId: 'member-a',
      state: 'cancelled',
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final row = await _read(api, 'response', 'r-already-cancelled');
    expect(row.currentState, 'cancelled');
    // Untouched, not merely re-cancelled: the terminal-state effect never ran.
    expect(row.instanceData.containsKey('sweepMarker'), isFalse);
  });

  test('the sweep still moves a row whose response transition guard the '
      "cancelling actor doesn't satisfy", () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'c')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(
            _machine(
              'response',
              _responseDefinition(
                transitions: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'response-cancelled',
                    'label': 'Event cancelled',
                    'action': 'cancel',
                    'from': <String>[
                      'pending',
                      'going',
                      'maybe',
                      'waitlisted',
                      'declined',
                    ],
                    'to': 'cancelled',
                    // Nobody the cancelling actor could ever be holds this
                    // role -- proves the guard is bypassed, not satisfied.
                    'guard': <String, dynamic>{
                      'allowedRoleIds': <String>['nobody-role'],
                    },
                  },
                ],
              ),
            ),
          );

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-going',
      eventId: 'evt',
      fanId: 'member-a',
      state: 'going',
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final row = await _read(api, 'response', 'r-going');
    expect(row.currentState, 'cancelled');
  });

  test('a non-event-rsvp cancel transition never touches an unrelated, '
      'unregistered response workflow', () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'd1')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'document',
              _eventDefinition(
                responseWorkflowType: 'never-registered',
                family: 'documentLibrary',
              ),
            ),
          );
    // No 'never-registered' definition is registered. If the gate ever
    // let this through, resolving it would throw.

    await _seedEvent(api, workflowType: 'document', instanceId: 'doc');

    await api.applyTransition(
      workflowType: 'document',
      instanceId: 'doc',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final row = await _read(api, 'document', 'doc');
    expect(row.currentState, 'cancelled');
  });

  test('an event-rsvp cancel transition with no declared responseTable never '
      'touches an unrelated, unregistered response workflow', () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'd2')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(
                responseWorkflowType: 'never-registered',
                declareResponseTable: false,
              ),
            ),
          );

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final row = await _read(api, 'event', 'evt');
    expect(row.currentState, 'cancelled');
  });

  test("only the cancelled event's own response rows move; a sibling event's "
      'rows are untouched', () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'e')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(_machine('response', _responseDefinition()));

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt-1');
    await _seedEvent(api, workflowType: 'event', instanceId: 'evt-2');
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r1-going',
      eventId: 'evt-1',
      fanId: 'member-a',
      state: 'going',
    );
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r1-maybe',
      eventId: 'evt-1',
      fanId: 'member-b',
      state: 'maybe',
    );
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r2-going',
      eventId: 'evt-2',
      fanId: 'member-c',
      state: 'going',
    );

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt-1',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    expect(
      (await _read(api, 'response', 'r1-going')).currentState,
      'cancelled',
    );
    expect(
      (await _read(api, 'response', 'r1-maybe')).currentState,
      'cancelled',
    );
    expect((await _read(api, 'response', 'r2-going')).currentState, 'going');
    expect((await _read(api, 'event', 'evt-2')).currentState, 'open');
  });

  test('throws naming the workflow type, row id and state when no cancel '
      "transition's from covers a row's state", () async {
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'f')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(
            _machine(
              'response',
              _responseDefinition(
                transitions: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'response-cancelled',
                    'label': 'Event cancelled',
                    'action': 'cancel',
                    // Deliberately omits "waitlisted".
                    'from': <String>['pending', 'going', 'maybe', 'declined'],
                    'to': 'cancelled',
                    'guard': <String, dynamic>{
                      'allowedRoleIds': <String>['coordinator-role'],
                    },
                  },
                ],
              ),
            ),
          );

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
    await _seedResponse(
      api,
      workflowType: 'response',
      instanceId: 'r-waitlisted',
      eventId: 'evt',
      fanId: 'member-a',
      state: 'waitlisted',
    );

    await expectLater(
      api.applyTransition(
        workflowType: 'event',
        instanceId: 'evt',
        transitionId: 'cancel-event',
        fanId: 'organizer',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('response'),
            contains('r-waitlisted'),
            contains('waitlisted'),
          ),
        ),
      ),
    );
  });

  test(
    "a sweep failure rolls back the parent event's own state change too",
    () async {
      final api =
          LocalWorkflowEngineApi(
              db: WorkflowDatabase.memory(),
              communityId: 'g',
            )
            ..setRoleForFan('organizer', 'organizer-role')
            ..registerDefinition(
              _machine(
                'event',
                _eventDefinition(responseWorkflowType: 'response'),
              ),
            )
            ..registerDefinition(
              _machine(
                'response',
                _responseDefinition(
                  transitions: <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'response-cancelled',
                      'label': 'Event cancelled',
                      'action': 'cancel',
                      'from': <String>['pending', 'going', 'maybe', 'declined'],
                      'to': 'cancelled',
                      'guard': <String, dynamic>{
                        'allowedRoleIds': <String>['coordinator-role'],
                      },
                    },
                  ],
                ),
              ),
            );

      await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
      await _seedResponse(
        api,
        workflowType: 'response',
        instanceId: 'r-waitlisted',
        eventId: 'evt',
        fanId: 'member-a',
        state: 'waitlisted',
      );

      await expectLater(
        api.applyTransition(
          workflowType: 'event',
          instanceId: 'evt',
          transitionId: 'cancel-event',
          fanId: 'organizer',
        ),
        throwsStateError,
      );

      final event = await _read(api, 'event', 'evt');
      expect(event.currentState, 'open');
      final response = await _read(api, 'response', 'r-waitlisted');
      expect(response.currentState, 'waitlisted');
    },
  );

  test('per-state-split cancel transitions (Tabletop\'s shape) collectively '
      'cover every non-terminal state, one transition per state', () async {
    Map<String, dynamic> cancelFrom(String state) => <String, dynamic>{
      'id': 'cancel-$state-response',
      'label': 'Close cancelled event response',
      'action': 'cancel',
      'from': <String>[state],
      'to': 'cancelled',
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['coordinator-role'],
      },
    };
    final api =
        LocalWorkflowEngineApi(db: WorkflowDatabase.memory(), communityId: 'h')
          ..setRoleForFan('organizer', 'organizer-role')
          ..registerDefinition(
            _machine(
              'event',
              _eventDefinition(responseWorkflowType: 'response'),
            ),
          )
          ..registerDefinition(
            _machine(
              'response',
              _responseDefinition(
                transitions: <Map<String, dynamic>>[
                  cancelFrom('pending'),
                  cancelFrom('going'),
                  cancelFrom('maybe'),
                  cancelFrom('waitlisted'),
                  cancelFrom('declined'),
                ],
              ),
            ),
          );

    await _seedEvent(api, workflowType: 'event', instanceId: 'evt');
    for (final state in <String>[
      'pending',
      'going',
      'maybe',
      'waitlisted',
      'declined',
    ]) {
      await _seedResponse(
        api,
        workflowType: 'response',
        instanceId: 'r-$state',
        eventId: 'evt',
        fanId: 'member-$state',
        state: state,
      );
    }

    await api.applyTransition(
      workflowType: 'event',
      instanceId: 'evt',
      transitionId: 'cancel-event',
      fanId: 'organizer',
    );

    final rows = await _all(api, 'response');
    expect(rows, hasLength(5));
    expect(rows.map((row) => row.currentState).toSet(), {'cancelled'});
  });
}
