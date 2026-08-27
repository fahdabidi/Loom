import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

/// `ArchetypeContract.sharingGrantable`, made real.
///
/// `documentLibrary` declares `{open, download, edit}`: a fan the document was
/// shared with may do those three things and nothing else, whatever roles they
/// hold. Lifecycle actions are not in that set and must stay unreachable.
void main() {
  late WorkflowDatabase database;
  late LocalWorkflowEngineApi engine;

  setUp(() async {
    database = WorkflowDatabase.memory();
    engine = LocalWorkflowEngineApi(db: database, communityId: _communityId);
    engine.setActiveMembershipLookup((_) async => true);
    await _install(database);
  });

  tearDown(() {
    database.close();
  });

  test('a shared-with fan gains exactly the grantable actions', () async {
    final instanceId = await _seed(engine, sharedWith: const [_guest]);
    // No roles at all. Everything they can do comes from the grant.
    engine.setRolesForFan(_guest, const {});

    final actions = await _actionsFor(engine, instanceId, _guest);

    // open, download and edit are what the contract grants.
    expect(actions, containsAll(<String>['open', 'download', 'edit']));

    // publish, archive and delete are not in sharingGrantable, so a grant
    // cannot confer them. A shared document is not a transferred community
    // role.
    expect(actions, isNot(contains('publish')));
    expect(actions, isNot(contains('archive')));
    expect(actions, isNot(contains('delete')));
  });

  test('a fan the document was not shared with gains nothing', () async {
    final instanceId = await _seed(engine, sharedWith: const [_guest]);
    engine.setRolesForFan(_stranger, const {});

    expect(await _actionsFor(engine, instanceId, _stranger), isEmpty);
  });

  test('an empty share list admits nobody, rather than everybody', () async {
    final instanceId = await _seed(engine, sharedWith: const []);
    engine.setRolesForFan(_guest, const {});

    expect(await _actionsFor(engine, instanceId, _guest), isEmpty);
  });

  test('a granted transition can actually be applied, not just offered',
      () async {
    // The half-wired failure this suite exists to catch: availability and
    // application resolve transitions through different call sites, so a grant
    // wired into one and not the other produces a button that refuses the fan
    // who was just offered it.
    final instanceId = await _seed(engine, sharedWith: const [_guest]);
    engine.setRolesForFan(_guest, const {});

    await engine.applyTransition(
      workflowType: _workflowType,
      instanceId: instanceId,
      transitionId: 'record-open',
      fanId: _guest,
    );

    final stored = await database.readInstance(instanceId);
    expect(stored, isNotNull);
  });

  test('an ungranted transition is still refused on apply', () async {
    final instanceId = await _seed(engine, sharedWith: const [_guest]);
    engine.setRolesForFan(_guest, const {});

    // `publish` is guarded to a role the guest does not hold and is not
    // grantable, so both paths must refuse it.
    await expectLater(
      engine.applyTransition(
        workflowType: _workflowType,
        instanceId: instanceId,
        transitionId: 'publish-document',
        fanId: _guest,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('the role holder keeps every action a grant does not cover', () async {
    final instanceId = await _seed(engine, sharedWith: const []);
    engine.setRolesForFan(_board, const {'hoa-board'});

    final actions = await _actionsFor(engine, instanceId, _board);

    // The grant is an alternative to the guard, never a replacement for it.
    expect(actions, containsAll(<String>['publish', 'edit']));
  });
}

const _communityId = 'sharing-grants';
const _workflowType = 'hoa-member-document';
const _board = 'fan-board';
const _guest = 'fan-guest';
const _stranger = 'fan-stranger';

Future<Set<String>> _actionsFor(
  LocalWorkflowEngineApi engine,
  String instanceId,
  String fanId,
) async {
  final instance = await engine.readVisibleInstance(
    instanceId: instanceId,
    fanId: fanId,
  );
  if (instance == null) return <String>{};
  final transitions = await engine.availableTransitionsAsync(
    workflowType: _workflowType,
    instanceId: instanceId,
    currentState: instance.currentState,
    instanceData: instance.instanceData,
    fanId: fanId,
  );
  return {
    for (final transition in transitions)
      if (transition.action != null) transition.action!,
  };
}

Future<String> _seed(
  LocalWorkflowEngineApi engine, {
  required List<String> sharedWith,
}) async {
  engine.setRolesForFan(_board, const {'hoa-board'});
  final instanceId = await engine.createInstance(
    workflowType: _workflowType,
    initialInstanceData: <String, dynamic>{
      'explicitReaderFanIds': sharedWith,
    },
    fanId: _board,
  );
  return instanceId;
}

/// Cedar's shape: documentLibrary, sharing keyed to `explicitReaderFanIds`.
Future<void> _install(WorkflowDatabase database) => database.upsertDefinition(
  definitionId: '${_communityId}_$_workflowType',
  workflowType: _workflowType,
  definitionJson: '''
{
  "initialState": "published",
  "visibility": {
    "default": "membersOnly",
    "fields": {"sharedWith": "explicitReaderFanIds"}
  },
  "states": {
    "published": {"label": "Published"},
    "archived": {"label": "Archived"}
  },
  "renderBindings": [
    {
      "states": ["published"],
      "audience": "any",
      "tabId": "documents",
      "cardSurfaceFamily": "documentLibrary",
      "bindingKind": "primary",
      "actions": [
        {"kind": "create", "label": "Add", "scope": "tab",
         "presentation": "fab"}
      ]
    }
  ],
  "transitions": [
    {"id": "record-open", "label": "Open", "action": "open",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-member"]}},
    {"id": "confirm-download", "label": "Download", "action": "download",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-member"]}},
    {"id": "record-document-edit", "label": "Edit", "action": "edit",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-board"]}},
    {"id": "publish-document", "label": "Publish", "action": "publish",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-board"]}},
    {"id": "archive-document", "label": "Archive", "action": "archive",
     "from": ["published"], "to": "archived",
     "guard": {"allowedRoleIds": ["hoa-board"]}},
    {"id": "delete-document", "label": "Delete", "action": "delete",
     "from": ["published"], "to": null,
     "guard": {"allowedRoleIds": ["hoa-board"]}}
  ],
  "instanceDataSchema": {
    "explicitReaderFanIds": {
      "type": "fanId[]",
      "writableBy": "formEntry",
      "storage": "inline"
    }
  }
}
''',
  version: 4,
);
