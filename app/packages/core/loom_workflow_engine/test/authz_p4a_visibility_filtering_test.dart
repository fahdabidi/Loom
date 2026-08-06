import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType, {
  required String defaultVisibility,
  Map<String, dynamic>? readGuard,
  Map<String, dynamic>? stateReadGuard,
  Map<String, dynamic>? instanceDataSchema,
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{
      'label': 'Open',
      if (stateReadGuard != null) 'readGuard': stateReadGuard,
    },
  },
  'transitions': const <Map<String, dynamic>>[],
  if (instanceDataSchema != null) 'instanceDataSchema': instanceDataSchema,
  'visibility': <String, dynamic>{
    'default': defaultVisibility,
    if (readGuard != null) 'readGuard': readGuard,
  },
}, workflowType);

LocalWorkflowEngineApi _api({ActiveMembershipLookup? activeMembershipLookup}) {
  return LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'authz-p4a',
    activeMembershipLookup: activeMembershipLookup,
  );
}

Future<String> _create(
  LocalWorkflowEngineApi api, {
  required String workflowType,
  required String creator,
  required String title,
  Map<String, dynamic>? data,
}) => api.createInstance(
  workflowType: workflowType,
  personaId: creator,
  initialInstanceData: <String, dynamic>{'title': title, ...?data},
);

Future<List<WorkflowInstance>> _read(
  LocalWorkflowEngineApi api,
  String personaId, {
  int limit = 25,
  String? cursor,
}) async => (await api.queryInstances(
  tabId: 'home',
  personaId: personaId,
  limit: limit,
  cursor: cursor,
  query: const SurfaceQuery(sort: SortSpec(key: 'title')),
)).items;

void main() {
  test(
    'queryInstances enforces guarded allowlists and author ownership',
    () async {
      final api = _api();
      api.registerDefinition(
        _machine(
          'guarded',
          defaultVisibility: 'guarded',
          readGuard: <String, dynamic>{
            'allowedPersonaIds': <String>['reviewer'],
          },
        ),
      );
      final authorId = await _create(
        api,
        workflowType: 'guarded',
        creator: 'author',
        title: 'author row',
      );
      final otherId = await _create(
        api,
        workflowType: 'guarded',
        creator: 'other-author',
        title: 'other row',
      );
      api.setPersonaType('reviewer-account', 'reviewer');

      expect((await _read(api, 'outsider')), isEmpty);
      expect(
        (await _read(api, 'reviewer-account')).map((row) => row.instanceId),
        containsAll(<String>[authorId, otherId]),
      );
      expect(
        (await _read(api, 'author')).map((row) => row.instanceId),
        <String>[authorId],
      );
      expect(
        await api.aggregate(
          workflowType: 'guarded',
          column: 'title',
          op: 'count',
          personaId: 'outsider',
        ),
        0,
      );
      expect(
        await api.aggregate(
          workflowType: 'guarded',
          column: 'title',
          op: 'count',
          personaId: 'reviewer-account',
        ),
        2,
      );
    },
  );

  test('state readGuard overrides the workflow readGuard', () async {
    final api = _api();
    api.registerDefinition(
      _machine(
        'state-guarded',
        defaultVisibility: 'guarded',
        readGuard: <String, dynamic>{
          'allowedPersonaIds': <String>['reviewer'],
        },
        stateReadGuard: <String, dynamic>{
          'allowedPersonaIds': <String>['editor'],
        },
      ),
    );
    await _create(
      api,
      workflowType: 'state-guarded',
      creator: 'author',
      title: 'state row',
    );
    api
      ..setPersonaType('reviewer-account', 'reviewer')
      ..setPersonaType('editor-account', 'editor');

    expect(await _read(api, 'reviewer-account'), isEmpty);
    expect((await _read(api, 'editor-account')), hasLength(1));
  });

  test('membersOnly uses the injected active-membership lookup', () async {
    final lookups = <String>[];
    final api = _api(
      activeMembershipLookup: (personaId) {
        lookups.add(personaId);
        return personaId == 'active-member';
      },
    );
    api.registerDefinition(
      _machine('members-only', defaultVisibility: 'membersOnly'),
    );
    await _create(
      api,
      workflowType: 'members-only',
      creator: 'author',
      title: 'member row',
    );

    expect((await _read(api, 'active-member')), hasLength(1));
    expect(await _read(api, 'pending-member'), isEmpty);
    expect(lookups, <String>['active-member', 'pending-member']);
  });

  test(
    'omitted and public visibility remain readable by every persona',
    () async {
      final api = _api(
        activeMembershipLookup: (_) =>
            fail('public rows must not look up membership'),
      );
      api
        ..registerDefinition(
          LoomWorkflowStateMachine.fromJson(<String, dynamic>{
            'initialState': 'open',
            'states': <String, dynamic>{
              'open': <String, dynamic>{'label': 'Open'},
            },
            'transitions': const <Map<String, dynamic>>[],
          }, 'omitted-public'),
        )
        ..registerDefinition(
          _machine('explicit-public', defaultVisibility: 'public'),
        );
      await _create(
        api,
        workflowType: 'omitted-public',
        creator: 'author',
        title: 'omitted',
      );
      await _create(
        api,
        workflowType: 'explicit-public',
        creator: 'author',
        title: 'explicit',
      );

      expect(await _read(api, 'unrelated-person'), hasLength(2));
    },
  );

  test('readGuard formulas evaluate against computed instance data', () async {
    final api = _api();
    api.registerDefinition(
      _machine(
        'computed-guarded',
        defaultVisibility: 'guarded',
        readGuard: <String, dynamic>{'formula': 'isReadable'},
        instanceDataSchema: <String, dynamic>{
          'tags': <String, dynamic>{'type': 'list'},
          'isReadable': <String, dynamic>{
            'type': 'bool',
            'formula': 'size(tags) > 0',
          },
        },
      ),
    );
    await _create(
      api,
      workflowType: 'computed-guarded',
      creator: 'author',
      title: 'readable',
      data: <String, dynamic>{
        'tags': <String>['visible'],
      },
    );
    await _create(
      api,
      workflowType: 'computed-guarded',
      creator: 'author',
      title: 'hidden',
      data: <String, dynamic>{'tags': <String>[]},
    );

    expect(
      (await _read(api, 'outsider')).map((row) => row.instanceData['title']),
      <String>['readable'],
    );
  });

  test('filtered pagination reports cursors from filtered rows', () async {
    final api = _api();
    api.registerDefinition(
      _machine(
        'paged-guarded',
        defaultVisibility: 'guarded',
        readGuard: <String, dynamic>{
          'actorEqualsField': <String, dynamic>{'key': 'readerId'},
        },
      ),
    );
    for (final row in <Map<String, dynamic>>[
      <String, dynamic>{'title': 'a-visible', 'readerId': 'viewer'},
      <String, dynamic>{'title': 'b-hidden', 'readerId': 'other'},
      <String, dynamic>{'title': 'c-hidden', 'readerId': 'other'},
      <String, dynamic>{'title': 'd-visible', 'readerId': 'viewer'},
      <String, dynamic>{'title': 'e-visible', 'readerId': 'viewer'},
    ]) {
      await _create(
        api,
        workflowType: 'paged-guarded',
        creator: 'seed',
        title: row['title'] as String,
        data: <String, dynamic>{'readerId': row['readerId']},
      );
    }

    final first = await api.queryInstances(
      tabId: 'home',
      personaId: 'viewer',
      limit: 2,
      query: const SurfaceQuery(sort: SortSpec(key: 'title')),
    );
    expect(first.items.map((row) => row.instanceData['title']), <String>[
      'a-visible',
      'd-visible',
    ]);
    expect(first.hasMore, isTrue);
    expect(first.nextCursor, contains('d-visible'));

    final second = await api.queryInstances(
      tabId: 'home',
      personaId: 'viewer',
      limit: 2,
      cursor: first.nextCursor,
      query: const SurfaceQuery(sort: SortSpec(key: 'title')),
    );
    expect(second.items.map((row) => row.instanceData['title']), <String>[
      'e-visible',
    ]);
    expect(second.hasMore, isFalse);
    expect(second.nextCursor, isNull);
  });
}
