import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

/// A declared reminder, replacing the formula that used to compute one.
///
/// Cedar Commons HOA carried
/// `if(reminderEnabled == true, subtractHours(combineDateAndTime(eventDate,
/// eventTime), 24), null)`. The block below says the same thing without an
/// expression, and the platform resolves it — which is what lets the timezone
/// question have one home rather than one per formula.
const _communityId = 'declared-reminder';
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

  test('resolves to the same instant the formula produced', () async {
    final id = await _seed(engine, reminderEnabled: true);

    // Event 2026-03-10 18:00, lead 24h, so due 2026-03-09 18:00 UTC.
    expect(
      await _dueIds(engine, DateTime.utc(2026, 3, 9, 17, 59)),
      isEmpty,
      reason: 'one minute early is not due',
    );
    expect(
      await _dueIds(engine, DateTime.utc(2026, 3, 9, 18, 1)),
      contains(id),
      reason: 'one minute late is due',
    );
  });

  test('the enabled gate is honoured', () async {
    await _seed(engine, reminderEnabled: false);
    // A member who has not asked to be reminded is swept and skipped, which is
    // not the same as a workflow with no reminder block at all.
    expect(await _dueIds(engine, DateTime.utc(2027)), isEmpty);
  });

  test('a declared reminder needs no dueAt field at all', () async {
    final id = await _seed(engine, reminderEnabled: true);
    final stored = await database.readInstance(id);
    // The whole point: nothing computes or stores `dueAt` on the instance. The
    // package declares intent and the platform derives the instant.
    expect(stored!.instanceData, isNot(contains('dueAt')));
    expect(await _dueIds(engine, DateTime.utc(2026, 3, 11)), contains(id));
  });

  test('a workflow with no reminder block is never swept', () async {
    await database.upsertDefinition(
      definitionId: '${_communityId}_plain',
      workflowType: 'plain',
      definitionJson: _plainDefinitionJson,
      version: 4,
    );
    await engine.createInstance(
      workflowType: 'plain',
      initialInstanceData: const {'eventDate': '2026-03-10'},
      fanId: 'fan-alice',
    );
    expect(await _dueIds(engine, DateTime.utc(2027)), isEmpty);
  });

  test('a member-chosen lead time wins over the declared default', () async {
    // Book Club and Garden Club both let a member pick their own offset, so a
    // fixed number could not express what they already ship.
    await database.upsertDefinition(
      definitionId: '${_communityId}_chosen',
      workflowType: 'chosen',
      definitionJson: _chosenLeadDefinitionJson,
      version: 4,
    );
    final id = await engine.createInstance(
      workflowType: 'chosen',
      initialInstanceData: const {
        'eventDate': '2026-03-10',
        'eventTime': '18:00',
        'reminderOffsetHours': 48,
      },
      fanId: 'fan-alice',
    );

    // 48 hours before, not the declared default of 24.
    expect(await _dueIds(engine, DateTime.utc(2026, 3, 8, 17, 59)), isEmpty);
    expect(await _dueIds(engine, DateTime.utc(2026, 3, 8, 18, 1)), contains(id));
  });

  test('the declared default applies when the member chose nothing', () async {
    await database.upsertDefinition(
      definitionId: '${_communityId}_chosen',
      workflowType: 'chosen',
      definitionJson: _chosenLeadDefinitionJson,
      version: 4,
    );
    final id = await engine.createInstance(
      workflowType: 'chosen',
      initialInstanceData: const {
        'eventDate': '2026-03-10',
        'eventTime': '18:00',
      },
      fanId: 'fan-alice',
    );

    // Falls back to 24, which is what Book Club's `if(x == null, 24, x)` said.
    expect(await _dueIds(engine, DateTime.utc(2026, 3, 9, 17, 59)), isEmpty);
    expect(await _dueIds(engine, DateTime.utc(2026, 3, 9, 18, 1)), contains(id));
  });

  test('the resolved instant is surfaced as reminderAt for readers', () async {
    // Book Club and Garden Club computed `reminderAt` with a formula, and the
    // calendar surface reads that key to decide whether a reminder has fired.
    // Moving the calculation to the platform must not remove the value those
    // readers depend on -- the package stops declaring how, and still gets what.
    final id = await _seed(engine, reminderEnabled: true);
    final visible = await engine.readVisibleInstance(
      instanceId: id,
      fanId: 'fan-alice',
    );
    expect(visible!.instanceData['reminderAt'], DateTime.utc(2026, 3, 9, 18));
  });

  test('reminderAt is absent, not null, when no reminder is wanted', () async {
    final id = await _seed(engine, reminderEnabled: false);
    final visible = await engine.readVisibleInstance(
      instanceId: id,
      fanId: 'fan-alice',
    );
    // A key holding null and a missing key read the same to every consumer,
    // and omitting it keeps instance data free of fields that mean nothing.
    expect(visible!.instanceData.containsKey('reminderAt'), isFalse);
  });

  test('the block rejects a lead time that points the wrong way', () {
    // A reminder after the thing it reminds you about is not a reminder, and
    // the grammar should say so at parse time rather than at sweep time.
    expect(
      () => WorkflowReminder.fromJson(const {
        'anchorDateField': 'eventDate',
        'leadHours': -1,
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => WorkflowReminder.fromJson(const {'leadHours': 24}),
      throwsA(isA<FormatException>()),
    );
    // Neither a number nor a field means the block cannot say when.
    expect(
      () => WorkflowReminder.fromJson(const {'anchorDateField': 'eventDate'}),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<String> _seed(
  LocalWorkflowEngineApi engine, {
  required bool reminderEnabled,
}) => engine.createInstance(
  workflowType: _workflowType,
  initialInstanceData: {
    'eventDate': '2026-03-10',
    'eventTime': '18:00',
    'reminderEnabled': reminderEnabled,
  },
  fanId: 'fan-alice',
);

Future<List<String>> _dueIds(
  LocalWorkflowEngineApi engine,
  DateTime asOf,
) async => (await engine.dueNotifications(
  asOf: asOf,
)).map((instance) => instance.instanceId).toList();

const _definitionJson = '''
{
  "initialState": "reserved",
  "states": {"reserved": {"label": "Reserved"}},
  "reminder": {
    "anchorDateField": "eventDate",
    "anchorTimeField": "eventTime",
    "leadHours": 24,
    "enabledField": "reminderEnabled"
  },
  "renderBindings": [
    {"states": ["reserved"], "audience": "any", "tabId": "calendar",
     "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary",
     "actions": [{"kind": "create", "label": "Reserve", "scope": "tab",
                  "presentation": "fab"}]}
  ],
  "transitions": [],
  "instanceDataSchema": {
    "eventDate": {"type": "date", "writableBy": "formEntry", "storage": "inline"},
    "eventTime": {"type": "time", "writableBy": "formEntry", "storage": "inline"},
    "reminderEnabled": {"type": "bool", "writableBy": "formEntry", "storage": "inline"}
  }
}
''';

const _plainDefinitionJson = '''
{
  "initialState": "open",
  "states": {"open": {"label": "Open"}},
  "renderBindings": [
    {"states": ["open"], "audience": "any", "tabId": "home",
     "cardSurfaceFamily": "formEntry", "bindingKind": "primary",
     "actions": [{"kind": "create", "label": "Add", "scope": "tab",
                  "presentation": "fab"}]}
  ],
  "transitions": [],
  "instanceDataSchema": {
    "eventDate": {"type": "date", "writableBy": "formEntry", "storage": "inline"}
  }
}
''';

const _chosenLeadDefinitionJson = '''
{
  "initialState": "open",
  "states": {"open": {"label": "Open"}},
  "reminder": {
    "anchorDateField": "eventDate",
    "anchorTimeField": "eventTime",
    "leadHoursField": "reminderOffsetHours",
    "leadHours": 24
  },
  "renderBindings": [
    {"states": ["open"], "audience": "any", "tabId": "calendar",
     "cardSurfaceFamily": "event-rsvp", "bindingKind": "primary",
     "actions": [{"kind": "create", "label": "Add", "scope": "tab",
                  "presentation": "fab"}]}
  ],
  "transitions": [],
  "instanceDataSchema": {
    "eventDate": {"type": "date", "writableBy": "formEntry", "storage": "inline"},
    "eventTime": {"type": "time", "writableBy": "formEntry", "storage": "inline"},
    "reminderOffsetHours": {"type": "number", "writableBy": "formEntry", "storage": "inline"}
  }
}
''';
