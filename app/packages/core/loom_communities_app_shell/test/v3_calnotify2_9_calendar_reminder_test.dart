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
}) async {
  final extensionId = 'cal-notify2-9-${_extensionSequence++}';
  final eventId = 'event-$extensionId';
  final responseId = 'response-$extensionId';
  final experience = experienceForExtensionId(
    extensionId,
    experienceConfiguration: _configuration(
      eventId: eventId,
      responseId: responseId,
      eventDate: eventDate,
      eventTime: eventTime,
      responseState: responseState,
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
}) => {
  'experienceSchemaVersion': 2,
  'workflowGrammarVersion': 1,
  'displayName': 'Reminder Test Tabletop Club',
  'tagline': 'Synthetic calendar reminder coverage.',
  'accentColor': '#6B4EFF',
  'personas': [
    {
      'personaId': _memberPersonaId,
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
          'role': 'any',
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
            'actorEqualsField': {'key': 'personaId'},
          },
          'effects': [
            {'op': 'set', 'key': 'reminderSentAt', 'value': r'$timestamp'},
          ],
        },
      ],
      'renderBindings': <Object?>[],
      'instanceDataSchema': {
        'eventId': {'type': 'text', 'required': true, 'storage': 'inline'},
        'personaId': {'type': 'text', 'required': true, 'storage': 'inline'},
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
        'recipientPersonaId': {
          'type': 'personaId',
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
  'workflowInstances': [
    {
      'instanceId': eventId,
      'workflowType': 'event-rsvp',
      'currentState': 'open',
      'createdByPersonaId': _memberPersonaId,
      'instanceData': {
        'title': 'Friday game night',
        'eventDate': eventDate,
        'eventTime': eventTime,
      },
    },
    {
      'instanceId': responseId,
      'workflowType': 'event-rsvp-response',
      'currentState': responseState,
      'createdByPersonaId': _memberPersonaId,
      'instanceData': {'eventId': eventId, 'personaId': _memberPersonaId},
    },
  ],
};

Widget _calendar(
  _ReminderHarness harness, {
  required DateTime currentDate,
  int revision = 0,
}) => MaterialApp(
  home: Scaffold(
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
      expect(notification.instanceData['recipientPersonaId'], _memberPersonaId);
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
}
