import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

/// A `dueAt` that is computed, not stored.
///
/// Cedar Commons HOA derives its reservation reminder rather than storing it —
/// `reminderEnabled` is the stored fact and `dueAt` is a formula over the event
/// time. `dueNotifications` used to read the raw stored map, so every such row
/// was skipped and the community that models reminders most completely could
/// never receive one.
const _communityId = 'computed-due';
const _workflowType = 'facility-reservation';

void main() {
  late WorkflowDatabase database;
  late LocalWorkflowEngineApi engine;

  setUp(() async {
    database = WorkflowDatabase.memory();
    engine = LocalWorkflowEngineApi(db: database, communityId: _communityId);
    engine.setActiveMembershipLookup((_) async => true);
    await database.upsertDefinition(
      definitionId: '${_communityId}_$_workflowType',
      workflowType: _workflowType,
      definitionJson: _definitionJson,
      version: 4,
    );
  });

  tearDown(() {
    database.close();
  });

  test('a formula-computed dueAt is found once the reminder is enabled',
      () async {
    final instanceId = await engine.createInstance(
      workflowType: _workflowType,
      initialInstanceData: const {
        'eventDate': '2026-03-10',
        'eventTime': '18:00',
        'reminderEnabled': true,
      },
      fanId: 'fan-alice',
    );

    // The reminder derives to 24 hours before the event: 2026-03-09 18:00,
    // timezone-naive, so its absolute instant depends on where this runs.
    // Asking as of the 11th is unambiguous in every zone; asking as of the 10th
    // is not, and my first version of this test failed on a PDT machine for
    // exactly that reason. Nothing stored `dueAt` -- the row carries
    // `reminderEnabled` and the formula supplies the rest.
    final due = await engine.dueNotifications(asOf: DateTime.utc(2026, 3, 11));
    expect(
      due.map((instance) => instance.instanceId),
      contains(instanceId),
      reason: 'a computed dueAt must be visible to the sweep',
    );
  });

  test('the same reservation is not due before its computed instant', () async {
    await engine.createInstance(
      workflowType: _workflowType,
      initialInstanceData: const {
        'eventDate': '2026-03-10',
        'eventTime': '18:00',
        'reminderEnabled': true,
      },
      fanId: 'fan-alice',
    );

    // A week out, the reminder has not come due. Without this the fix could be
    // "return everything", which would find the row for the wrong reason.
    expect(await engine.dueNotifications(asOf: DateTime.utc(2026, 3, 1)), isEmpty);
  });

  test('a reminder nobody enabled never comes due', () async {
    await engine.createInstance(
      workflowType: _workflowType,
      initialInstanceData: const {
        'eventDate': '2026-03-10',
        'eventTime': '18:00',
        'reminderEnabled': false,
      },
      fanId: 'fan-alice',
    );

    // The formula yields null when the member has not asked to be reminded.
    expect(
      await engine.dueNotifications(asOf: DateTime.utc(2027, 1, 1)),
      isEmpty,
    );
  });

  test('a stored dueAt still works', () async {
    // Book Club and Garden Club store theirs, written by a createInstance
    // effect. Computing before filtering must not break the case that worked.
    await database.upsertDefinition(
      definitionId: '${_communityId}_club-notification',
      workflowType: 'club-notification',
      definitionJson: _storedDefinitionJson,
      version: 4,
    );
    final instanceId = await engine.createInstance(
      workflowType: 'club-notification',
      initialInstanceData: const {'dueAt': '2026-01-01T09:00:00Z'},
      fanId: 'fan-alice',
    );

    final due = await engine.dueNotifications(asOf: DateTime.utc(2026, 6, 1));
    expect(due.map((instance) => instance.instanceId), contains(instanceId));
  });
}

/// Cedar's shape: `reminderEnabled` stored, `dueAt` derived from it.
const _definitionJson = '''
{
  "initialState": "reserved",
  "states": {"reserved": {"label": "Reserved"}},
  "renderBindings": [
    {
      "states": ["reserved"],
      "audience": "any",
      "tabId": "calendar",
      "cardSurfaceFamily": "event-rsvp",
      "bindingKind": "primary",
      "actions": [
        {"kind": "create", "label": "Reserve", "scope": "tab",
         "presentation": "fab"}
      ]
    }
  ],
  "transitions": [],
  "instanceDataSchema": {
    "eventDate": {"type": "date", "writableBy": "formEntry", "storage": "inline"},
    "eventTime": {"type": "time", "writableBy": "formEntry", "storage": "inline"},
    "reminderEnabled": {"type": "bool", "writableBy": "effect", "storage": "inline"},
    "dueAt": {
      "type": "date?",
      "formula": "if(reminderEnabled == true, subtractHours(combineDateAndTime(eventDate, eventTime), 24), null)"
    }
  }
}
''';

/// Book Club's shape: `dueAt` stored outright.
const _storedDefinitionJson = '''
{
  "initialState": "unread",
  "states": {"unread": {"label": "Unread"}},
  "renderBindings": [
    {
      "states": ["unread"],
      "audience": "any",
      "tabId": "home",
      "cardSurfaceFamily": "notificationInbox",
      "bindingKind": "primary",
      "actions": [
        {"kind": "create", "label": "Remind", "scope": "tab",
         "presentation": "fab"}
      ]
    }
  ],
  "transitions": [],
  "instanceDataSchema": {
    "dueAt": {"type": "text", "writableBy": "formEntry", "storage": "inline"}
  }
}
''';
