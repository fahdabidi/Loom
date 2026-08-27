import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

/// A state's `readGuard` narrows, whatever `visibility.default` says.
///
/// Pinned as its own suite because the previous behaviour was not a crash or a
/// wrong value -- the guard was parsed, stored, and ignored. Nothing failed,
/// and three shipped workflows were unenforced for as long as that was true.
void main() {
  late WorkflowDatabase database;
  late LocalWorkflowEngineApi engine;

  setUp(() {
    database = WorkflowDatabase.memory();
    engine = LocalWorkflowEngineApi(db: database, communityId: _communityId);
    engine.setActiveMembershipLookup((fanId) async => fanId != _outsider);
  });

  tearDown(() {
    database.close();
  });

  for (final visibilityDefault in const ['public', 'membersOnly', 'guarded']) {
    test(
      'a state readGuard withholds a draft under a $visibilityDefault default',
      () async {
        await _install(database, visibilityDefault);
        engine.setRolesForFan(_board, const {'hoa-board'});
        engine.setRolesForFan(_member, const {'hoa-member'});
        engine.setRolesForFan(_outsider, const {});

        final instanceId = await _seedDraft(engine);

        // The guarded state admits the role it names, and nobody else. Under
        // `public` this is the difference between a draft the whole internet
        // could read and one only the board can.
        expect(await _canRead(engine, instanceId, _board), isTrue);
        expect(await _canRead(engine, instanceId, _member), isFalse);
        expect(await _canRead(engine, instanceId, _outsider), isFalse);
      },
    );
  }

  test('a state without a readGuard still falls back to the default', () async {
    await _install(database, 'membersOnly');
    engine.setRolesForFan(_member, const {'hoa-member'});
    engine.setRolesForFan(_outsider, const {});

    final instanceId = await _seedDraft(engine);
    await engine.applyTransition(
      workflowType: _workflowType,
      instanceId: instanceId,
      transitionId: 'publish',
      fanId: _board,
    );

    // `published` declares no guard, so membersOnly governs it: the member
    // reads it and the outsider does not. Narrowing must not become a rule
    // that every state needs a guard to be visible at all.
    expect(await _canRead(engine, instanceId, _member), isTrue);
    expect(await _canRead(engine, instanceId, _outsider), isFalse);
  });

  test('the author reads their own guarded draft', () async {
    await _install(database, 'membersOnly');
    engine.setRolesForFan(_member, const {'hoa-member'});

    // Seeded by the member, who the board-only state guard would refuse.
    final instanceId = await _seedDraft(engine, fanId: _member);

    // Creator visibility is decided before any guard and must survive this
    // change, or narrowing a state would hide a member's own draft from them.
    expect(await _canRead(engine, instanceId, _member), isTrue);
  });
}

const _communityId = 'guard-precedence';
const _workflowType = 'hoa-member-document';
const _board = 'fan-board';
const _member = 'fan-member';
const _outsider = 'fan-outsider';

Future<bool> _canRead(
  LocalWorkflowEngineApi engine,
  String instanceId,
  String fanId,
) async =>
    await engine.readVisibleInstance(instanceId: instanceId, fanId: fanId) !=
    null;

Future<String> _seedDraft(
  LocalWorkflowEngineApi engine, {
  String fanId = _board,
}) async {
  return engine.createInstance(
    workflowType: _workflowType,
    initialInstanceData: const <String, dynamic>{},
    fanId: fanId,
  );
}

Future<void> _install(WorkflowDatabase database, String visibilityDefault) {
  // A workflow-level readGuard is present only for the `guarded` case, so the
  // three defaults differ in exactly the field under test.
  final workflowGuard = visibilityDefault == 'guarded'
      ? ', "readGuard": {"allowedRoleIds": ["hoa-member"]}'
      : '';
  return database.upsertDefinition(
    definitionId: '${_communityId}_$_workflowType',
    workflowType: _workflowType,
    definitionJson:
        '''
{
  "initialState": "draft",
  "visibility": {"default": "$visibilityDefault"$workflowGuard},
  "states": {
    "draft": {"label": "Draft", "readGuard": {"allowedRoleIds": ["hoa-board"]}},
    "published": {"label": "Published"}
  },
  "transitions": [
    {"id": "publish", "label": "Publish", "action": "publish",
     "from": ["draft"], "to": "published"}
  ],
  "instanceDataSchema": {}
}
''',
    version: 4,
  );
}
