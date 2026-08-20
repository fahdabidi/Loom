import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _memberPersonaId = 'tabletop-member-01';
var _extensionSequence = 0;

class _ReminderHarness {
  const _ReminderHarness({
    required this.extensionId,
    required this.experience,
    required this.engine,
    required this.eventId,
    required this.responseId,
  });

  final String extensionId;
  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final String eventId;
  final String responseId;
}

Future<_ReminderHarness> _installReminderFixture({
  required String eventDate,
  required String eventTime,
  String responseState = 'pending',
  int eventCount = 1,
  bool failAfterNotification = false,
}) async {
  final extensionId = 'cal-notify2-9-${_extensionSequence++}';
  final eventId = 'event-$extensionId';
  final responseId = 'response-$extensionId';
  final experience = experienceForExtensionId(
    extensionId,
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: _configuration(
      eventId: eventId,
      responseId: responseId,
      eventDate: eventDate,
      eventTime: eventTime,
      responseState: responseState,
      eventCount: eventCount,
      failAfterNotification: failAfterNotification,
    ),
  );
  final engine = await workflowEngineForExtensionId(extensionId);
  return _ReminderHarness(
    extensionId: extensionId,
    experience: experience,
    engine: engine,
    eventId: eventId,
    responseId: responseId,
  );
}

Map<String, Object?> _configuration({
  required String eventId,
  required String responseId,
  required String eventDate,
  required String eventTime,
  required String responseState,
  int eventCount = 1,
  bool failAfterNotification = false,
}) {
  final workflowInstances = <Map<String, Object?>>[];
  for (var index = 0; index < eventCount; index++) {
    final currentEventId = index == 0 ? eventId : '$eventId-$index';
    final currentResponseId = index == 0 ? responseId : '$responseId-$index';
    workflowInstances
      ..add({
        'instanceId': currentEventId,
        'workflowType': 'event-rsvp',
        'currentState': 'open',
        'createdByFanId': _memberPersonaId,
        'instanceData': {
          'title': index == 0
              ? 'Friday game night'
              : 'Friday game night #$index',
          'eventDate': eventDate,
          'eventTime': eventTime,
        },
      })
      ..add({
        'instanceId': currentResponseId,
        'workflowType': 'event-rsvp-response',
        'currentState': responseState,
        'createdByFanId': _memberPersonaId,
        'instanceData': {'eventId': currentEventId, 'fanId': _memberPersonaId},
      });
  }

  return {
    'displayName': 'Reminder Test Tabletop Club',
    'tagline': 'Synthetic calendar reminder coverage.',
    'accentColor': '#6B4EFF',
    'roles': [
      {
        'roleId': _memberPersonaId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'A synthetic tabletop club member.',
      },
    ],
    'workflowDefinitions': {
      'event-rsvp': {
        'initialState': 'open',
        'states': {
          'open': {'label': 'RSVP open'},
        },
        'transitions': <Object?>[],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
            'responseTable': {
              'workflowType': 'event-rsvp-response',
              'eventField': 'eventId',
              'pendingStates': ['pending'],
            },
          },
        ],
        'instanceDataSchema': {
          'title': {
            'type': 'text',
            'required': true,
            'storage': 'inline',
            'displayContexts': ['tile', 'detail'],
          },
          'eventDate': {
            'type': 'date',
            'required': true,
            'storage': 'inline',
            'displayContexts': ['tile', 'detail'],
          },
          'eventTime': {
            'type': 'time',
            'required': true,
            'storage': 'inline',
            'displayContexts': ['tile', 'detail'],
          },
          'reminderOffsetHours': {'type': 'number', 'storage': 'inline'},
          'reminderAt': {
            'type': 'date',
            'formula':
                'subtractHours(combineDateAndTime(eventDate, eventTime), if(reminderOffsetHours == null, 24, reminderOffsetHours))',
          },
          'responses': {
            'type': 'list',
            'source': 'query(event-rsvp-response where eventId == id)',
          },
        },
      },
      'event-rsvp-response': {
        'initialState': 'pending',
        'states': {
          'pending': {'label': 'No response yet'},
          'going': {'label': 'Going'},
          'maybe': {'label': 'Maybe'},
          'declined': {'label': "Can't go"},
          'waitlisted': {'label': 'Waitlisted'},
        },
        'transitions': [
          {
            'id': 'respond-going',
            'label': 'Going',
            'from': ['pending'],
            'to': 'going',
          },
          {
            'id': 'respond-maybe',
            'label': 'Maybe',
            'from': ['pending'],
            'to': 'maybe',
          },
          {
            'id': 'respond-declined',
            'label': "Can't go",
            'from': ['pending'],
            'to': 'declined',
          },
          {
            'id': 'send-reminder',
            'label': 'Send reminder',
            'from': ['pending', 'maybe', 'going', 'waitlisted'],
            'to': null,
            'guard': {
              'actorEqualsField': {'key': 'fanId'},
            },
            'inputs': {
              'notificationTitle': {'type': 'text', 'required': true},
              'notificationBody': {'type': 'text', 'required': true},
              'notificationCreatedAt': {'type': 'text', 'required': true},
            },
            'effects': [
              {
                'op': 'createInstance',
                'workflowType': 'notification',
                'fields': {
                  'recipientFanId': '{fanId}',
                  'title': '{input.notificationTitle}',
                  'body': '{input.notificationBody}',
                  'createdAt': '{input.notificationCreatedAt}',
                },
              },
              if (failAfterNotification)
                {
                  'op': 'createInstance',
                  'workflowType': 'notification',
                  'fields': {'recipientFanId': '{fanId}'},
                },
              {'op': 'set', 'key': 'reminderSentAt', 'value': r'$timestamp'},
            ],
          },
        ],
        'renderBindings': <Object?>[],
        'instanceDataSchema': {
          'eventId': {'type': 'text', 'required': true, 'storage': 'inline'},
          'fanId': {'type': 'fanId', 'required': true, 'storage': 'inline'},
          'reminderSentAt': {
            'type': 'text',
            'writableBy': 'effect',
            'storage': 'inline',
          },
        },
      },
      'notification': {
        'initialState': 'unread',
        'states': {
          'unread': {'label': 'Unread'},
          'read': {'label': 'Read', 'isTerminal': true},
        },
        'transitions': <Object?>[],
        'renderBindings': <Object?>[],
        'instanceDataSchema': {
          'recipientFanId': {
            'type': 'fanId',
            'required': true,
            'writableBy': 'effect',
            'storage': 'inline',
          },
          'title': {
            'type': 'text',
            'required': true,
            'writableBy': 'effect',
            'storage': 'inline',
          },
          'body': {
            'type': 'text',
            'required': true,
            'writableBy': 'effect',
            'storage': 'inline',
          },
          'createdAt': {
            'type': 'text',
            'required': true,
            'writableBy': 'effect',
            'storage': 'inline',
          },
        },
      },
    },
    'workflowInstances': workflowInstances,
  };
}

class _ControlledReminderEngine implements WorkflowEngineApi {
  _ControlledReminderEngine(this.delegate);

  final WorkflowEngineApi delegate;
  final Completer<void> foregroundTransitionCompleted = Completer<void>();
  final List<String> transitionIds = <String>[];
  List<String>? transitionIdsAtForegroundCompletion;
  final List<String> directCreateWorkflowTypes = <String>[];
  Completer<InstancePage>? _heldFreshnessRead;
  InstancePage? _firstCalendarPage;
  int _calendarQueryCount = 0;

  bool get freshnessReadHeld => _heldFreshnessRead != null;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) async {
    final calendarOrdinal = tabId == 'calendar' ? _calendarQueryCount++ : null;
    if (calendarOrdinal == 1) {
      final held = Completer<InstancePage>();
      _heldFreshnessRead = held;
      return held.future;
    }
    final page = await delegate.queryInstances(
      tabId: tabId,
      personaId: personaId,
      query: query,
      limit: limit,
      cursor: cursor,
    );
    if (calendarOrdinal == 0) _firstCalendarPage = page;
    return page;
  }

  void releaseFreshnessRead() {
    final held = _heldFreshnessRead;
    if (held == null) throw StateError('No freshness read is being held');
    final page = _firstCalendarPage;
    if (page == null) {
      throw StateError('The first Calendar page was not retained');
    }
    held.complete(page);
    _heldFreshnessRead = null;
  }

  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) => delegate.availableTransitions(
    workflowType: workflowType,
    instanceId: instanceId,
    currentState: currentState,
    instanceData: instanceData,
    personaId: personaId,
  );

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) => delegate.availableTransitionsAsync(
    workflowType: workflowType,
    instanceId: instanceId,
    currentState: currentState,
    instanceData: instanceData,
    personaId: personaId,
  );

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
    Map<String, dynamic>? inputs,
  }) async {
    transitionIds.add(transitionId);
    final isForeground = transitionId != 'send-reminder';
    final result = await delegate.applyTransition(
      workflowType: workflowType,
      instanceId: instanceId,
      transitionId: transitionId,
      personaId: personaId,
      inputs: inputs,
    );
    if (isForeground && !foregroundTransitionCompleted.isCompleted) {
      transitionIdsAtForegroundCompletion = List<String>.of(transitionIds);
      foregroundTransitionCompleted.complete();
    }
    return result;
  }

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  }) {
    directCreateWorkflowTypes.add(workflowType);
    return delegate.createInstance(
      workflowType: workflowType,
      initialInstanceData: initialInstanceData,
      personaId: personaId,
    );
  }

  @override
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String personaId,
  }) => delegate.createInstances(
    workflowType: workflowType,
    initialInstanceDataList: initialInstanceDataList,
    personaId: personaId,
  );

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) => delegate.updateInstanceFields(
    workflowType: workflowType,
    instanceId: instanceId,
    fieldUpdates: fieldUpdates,
    personaId: personaId,
  );

  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? personaId,
  }) => delegate.aggregate(
    workflowType: workflowType,
    column: column,
    op: op,
    filter: filter,
    groupBy: groupBy,
    personaId: personaId,
  );

  @override
  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf}) =>
      delegate.dueNotifications(asOf: asOf);
}

Widget _calendar(
  _ReminderHarness harness, {
  required DateTime currentDate,
  int revision = 0,
}) => MaterialApp(
  home: ActiveIdentityScope(
    identity: ActiveIdentityContext(
      accountId: null,
      authApi: LocalAuthApi(),
      personaId: harness.experience.personas!.single.personaId,
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        child: EngineNativeCalendarSurface(
          key: ValueKey('calendar-${harness.extensionId}-$revision'),
          experience: harness.experience,
          persona: harness.experience.personas!.single,
          accent: Colors.deepPurple,
          modernTheme: null,
          engine: harness.engine,
          currentDate: () => currentDate,
        ),
      ),
    ),
  ),
);

Future<void> _settleCalendar(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<WorkflowInstance> _response(_ReminderHarness harness) async =>
    (await harness.engine.queryInstances(
      tabId: 'calendar',
      personaId: _memberPersonaId,
      limit: 100,
    )).items.singleWhere((item) => item.instanceId == harness.responseId);

Future<int> _notificationCount(_ReminderHarness harness) async =>
    (await harness.engine.queryInstances(
      tabId: 'notifications',
      personaId: _memberPersonaId,
      limit: 100,
    )).items.where((item) => item.workflowType == 'notification').length;

Future<void> _waitForReminderStamp(
  WidgetTester tester,
  _ReminderHarness harness,
) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final response = await _response(harness);
    if (response.instanceData['reminderSentAt'] != null) return;
    await _settleCalendar(tester);
  }
  fail('Timed out waiting for reminderSentAt on ${harness.responseId}');
}

Future<void> _pumpUntilFinder(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpUntilForegroundTransitionCompleted(
  WidgetTester tester,
  _ControlledReminderEngine engine,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (engine.foregroundTransitionCompleted.isCompleted) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  fail(
    'Timed out waiting for the foreground transition: '
    'completed=${engine.foregroundTransitionCompleted.isCompleted}, '
    'freshnessReadHeld=${engine.freshnessReadHeld}, '
    'calendarQueryCount=${engine._calendarQueryCount}, '
    'transitionIds=${engine.transitionIds}, '
    'directCreateWorkflowTypes=${engine.directCreateWorkflowTypes}',
  );
}

Future<void> _pumpUntilFreshnessRead(
  WidgetTester tester,
  _ControlledReminderEngine engine,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (engine.freshnessReadHeld) return;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  fail('Timed out waiting for the controlled reminder freshness read');
}

_ReminderHarness _withEngine(
  _ReminderHarness harness,
  WorkflowEngineApi engine,
) => _ReminderHarness(
  extensionId: harness.extensionId,
  experience: harness.experience,
  engine: engine,
  eventId: harness.eventId,
  responseId: harness.responseId,
);

void main() {
  testWidgets(
    'creates exactly one due reminder and stamps the viewer response',
    (tester) async {
      final harness = await _installReminderFixture(
        eventDate: '2026-07-10',
        eventTime: '19:00',
      );
      await tester.pumpWidget(
        _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
      );
      await _waitForReminderStamp(tester, harness);

      expect(await _notificationCount(harness), 1);
      final notification = (await harness.engine.queryInstances(
        tabId: 'notifications',
        personaId: _memberPersonaId,
        limit: 100,
      )).items.singleWhere((item) => item.workflowType == 'notification');
      expect(notification.instanceData['recipientFanId'], _memberPersonaId);
      expect(notification.instanceData['title'], 'Reminder: Friday game night');
      expect(
        notification.instanceData['body'],
        'Starts soon — check Calendar for details.',
      );
      expect(
        (await _response(harness)).instanceData['reminderSentAt'],
        isNotNull,
      );
    },
  );

  testWidgets('a stamped response does not create a second reminder', (
    tester,
  ) async {
    final harness = await _installReminderFixture(
      eventDate: '2026-07-10',
      eventTime: '19:00',
    );
    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
    );
    await _waitForReminderStamp(tester, harness);
    expect(await _notificationCount(harness), 1);

    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 10, 20), revision: 1),
    );
    await _settleCalendar(tester);
    expect(await _notificationCount(harness), 1);
  });

  testWidgets('does not remind before the computed reminderAt', (tester) async {
    final harness = await _installReminderFixture(
      eventDate: '2026-07-10',
      eventTime: '19:00',
    );
    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 9, 18, 59)),
    );
    await _settleCalendar(tester);

    expect(await _notificationCount(harness), 0);
    expect((await _response(harness)).instanceData['reminderSentAt'], isNull);
  });

  testWidgets('does not remind a declined response', (tester) async {
    final harness = await _installReminderFixture(
      eventDate: '2026-07-10',
      eventTime: '19:00',
      responseState: 'declined',
    );
    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
    );
    await _settleCalendar(tester);

    expect(await _notificationCount(harness), 0);
    expect((await _response(harness)).instanceData['reminderSentAt'], isNull);
  });

  testWidgets('hides send-reminder while retaining normal RSVP chips', (
    tester,
  ) async {
    final harness = await _installReminderFixture(
      eventDate: '2026-07-10',
      eventTime: '19:00',
    );
    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
    );
    await _waitForReminderStamp(tester, harness);
    await _settleCalendar(tester);

    expect(
      find.byKey(
        ValueKey('event-rsvp-${harness.eventId}-action-send-reminder'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey('event-rsvp-${harness.eventId}-action-respond-going'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey('event-rsvp-${harness.eventId}-action-respond-maybe'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey('event-rsvp-${harness.eventId}-action-respond-declined'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'held reminder freshness yields to a foreground RSVP before any reminder write',
    (tester) async {
      final installed = await _installReminderFixture(
        eventDate: '2026-07-10',
        eventTime: '19:00',
      );
      final controlled = _ControlledReminderEngine(installed.engine);
      final harness = _withEngine(installed, controlled);
      await tester.pumpWidget(
        _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
      );
      await _pumpUntilFreshnessRead(tester, controlled);

      final action = find.byKey(
        ValueKey('event-rsvp-${harness.eventId}-action-respond-going'),
      );
      await _pumpUntilFinder(tester, action);
      await tester.ensureVisible(action);
      await tester.pump();
      await tester.tap(action);
      await tester.pump();

      expect(controlled.transitionIds, isEmpty);
      controlled.releaseFreshnessRead();
      await _pumpUntilForegroundTransitionCompleted(tester, controlled);

      expect(controlled.transitionIdsAtForegroundCompletion, <String>[
        'respond-going',
      ]);
      expect(controlled.directCreateWorkflowTypes, isEmpty);
      // A deferred retry may legitimately stamp the live response before the
      // polling helper observes completion; the snapshot is the ordering
      // proof for the instant the foreground transition finished.
      final response = await _response(harness);
      expect(response.currentState, 'going');
    },
  );

  testWidgets('foreground RSVP wins over multiple queued reminder jobs', (
    tester,
  ) async {
    final installed = await _installReminderFixture(
      eventDate: '2026-07-10',
      eventTime: '19:00',
      eventCount: 3,
    );
    final controlled = _ControlledReminderEngine(installed.engine);
    final harness = _withEngine(installed, controlled);
    await tester.pumpWidget(
      _calendar(harness, currentDate: DateTime(2026, 7, 10, 20)),
    );
    await _pumpUntilFreshnessRead(tester, controlled);

    final action = find.byKey(
      ValueKey('event-rsvp-${harness.eventId}-action-respond-going'),
    );
    await _pumpUntilFinder(tester, action);
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    controlled.releaseFreshnessRead();
    await _pumpUntilForegroundTransitionCompleted(tester, controlled);

    expect(controlled.transitionIdsAtForegroundCompletion, <String>[
      'respond-going',
    ]);
    await _settleCalendar(tester);
    final foregroundIndex = controlled.transitionIds.indexOf('respond-going');
    final reminderIndices = <int>[
      for (var index = 0; index < controlled.transitionIds.length; index++)
        if (controlled.transitionIds[index] == 'send-reminder') index,
    ];
    expect(reminderIndices.length, greaterThanOrEqualTo(2));
    expect(reminderIndices, everyElement(greaterThan(foregroundIndex)));
  });

  test(
    'failed atomic reminder transition rolls back its notification and stamp',
    () async {
      final harness = await _installReminderFixture(
        eventDate: '2026-07-10',
        eventTime: '19:00',
        failAfterNotification: true,
      );

      await expectLater(
        harness.engine.applyTransition(
          workflowType: 'event-rsvp-response',
          instanceId: harness.responseId,
          transitionId: 'send-reminder',
          personaId: _memberPersonaId,
          inputs: {
            'notificationTitle': 'Reminder: Friday game night',
            'notificationBody': 'Starts soon — check Calendar for details.',
            'notificationCreatedAt': '2026-07-10T20:00:00.000',
          },
        ),
        throwsA(anything),
      );

      expect(await _notificationCount(harness), 0);
      expect((await _response(harness)).instanceData['reminderSentAt'], isNull);
    },
  );
}
