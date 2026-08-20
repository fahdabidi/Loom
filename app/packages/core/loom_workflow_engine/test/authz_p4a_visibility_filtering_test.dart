import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType, {
  required String defaultVisibility,
  Map<String, dynamic>? readGuard,
  Map<String, dynamic>? stateReadGuard,
  Map<String, dynamic>? instanceDataSchema,
  Map<String, dynamic>? visibilityFields,
  List<Map<String, dynamic>>? renderBindings,
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{
      'label': 'Open',
      if (stateReadGuard != null) 'readGuard': stateReadGuard,
    },
  },
  'transitions': const <Map<String, dynamic>>[],
  if (renderBindings != null) 'renderBindings': renderBindings,
  if (instanceDataSchema != null) 'instanceDataSchema': instanceDataSchema,
  'visibility': <String, dynamic>{
    'default': defaultVisibility,
    if (readGuard != null) 'readGuard': readGuard,
    if (visibilityFields != null) 'fields': visibilityFields,
  },
}, workflowType);

Map<String, dynamic> _binding(
  String family, {
  Map<String, dynamic>? responseTable,
}) => <String, dynamic>{
  'states': <String>['open'],
  'audience': 'any',
  'tabId': 'home',
  'cardSurfaceFamily': family,
  'bindingKind': 'primary',
  if (responseTable != null) 'responseTable': responseTable,
};

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

Future<LocalWorkflowEngineApi> _partiesApi({
  required List<Object?> parties,
  Map<String, dynamic> data = const {},
}) async {
  final api = _api(activeMembershipLookup: (_) => false);
  api.registerDefinition(
    _machine(
      'payment',
      defaultVisibility: 'membersOnly',
      visibilityFields: <String, dynamic>{'parties': parties},
      renderBindings: <Map<String, dynamic>>[_binding('paymentCheckout')],
    ),
  );
  await _create(
    api,
    workflowType: 'payment',
    creator: 'seed',
    title: 'private payment',
    data: data,
  );
  return api;
}

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
            'allowedRoleIds': <String>['reviewer'],
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
          'allowedRoleIds': <String>['reviewer'],
        },
        stateReadGuard: <String, dynamic>{
          'allowedRoleIds': <String>['editor'],
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

  // Phase A -- the `owner` visibility model (CONTRACTS.md §3). Every archetype
  // supports it, so it is enforced here rather than per-archetype.
  group('owner visibility model', () {
    test(
      'the creator reads their own membersOnly instance without membership',
      () async {
        final api = _api(activeMembershipLookup: (_) => false);
        api.registerDefinition(
          _machine('members-only', defaultVisibility: 'membersOnly'),
        );
        await _create(
          api,
          workflowType: 'members-only',
          creator: 'author',
          title: 'my own request',
        );

        // Before this model existed, `author` could not read the very request
        // they had submitted the moment their membership lapsed.
        expect(await _read(api, 'author'), hasLength(1));
        expect(await _read(api, 'someone-else'), isEmpty);
      },
    );

    test('an instance with no creator is readable by nobody', () async {
      final api = _api(activeMembershipLookup: (_) => false);
      api.registerDefinition(
        _machine('members-only', defaultVisibility: 'membersOnly'),
      );
      await _create(
        api,
        workflowType: 'members-only',
        creator: '',
        title: 'orphaned seed row',
      );

      // The asymmetry that makes the model fail closed: an unset creator must
      // match nobody, rather than matching an equally unset viewer. Seed data
      // carrying no identity renders to no one instead of leaking to everyone.
      expect(await _read(api, ''), isEmpty);
      expect(await _read(api, 'anyone'), isEmpty);
    });

    test(
      'ownership does not widen a guarded instance to other viewers',
      () async {
        final api = _api();
        api.registerDefinition(
          _machine(
            'guarded',
            defaultVisibility: 'guarded',
            readGuard: <String, dynamic>{
              'allowedRoleIds': <String>['reviewer'],
            },
          ),
        );
        await _create(
          api,
          workflowType: 'guarded',
          creator: 'author',
          title: 'sensitive',
        );

        expect(await _read(api, 'author'), hasLength(1));
        expect(await _read(api, 'reviewer'), hasLength(1));
        expect(await _read(api, 'bystander'), isEmpty);
      },
    );
  });

  group('owner_and_shared visibility model', () {
    test(
      'admits shared viewers through v4 fan-id fields and refuses others',
      () async {
        final api = _api(
          activeMembershipLookup: (personaId) => personaId == 'default-reader',
        );
        api.registerDefinition(
          _machine(
            'documents',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{
              'sharedWith': 'sharedWithFanIds',
            },
            renderBindings: <Map<String, dynamic>>[_binding('documentLibrary')],
          ),
        );
        await _create(
          api,
          workflowType: 'documents',
          creator: 'seed',
          title: 'first shared viewer',
          data: <String, dynamic>{
            'sharedWithFanIds': <String>['first-reader'],
          },
        );
        await _create(
          api,
          workflowType: 'documents',
          creator: 'seed',
          title: 'current spelling',
          data: <String, dynamic>{
            'sharedWithFanIds': <String>['current-reader'],
          },
        );

        expect(await _read(api, 'first-reader'), hasLength(1));
        expect(await _read(api, 'current-reader'), hasLength(1));
        expect(await _read(api, 'wrong-reader'), isEmpty);
        expect(await _read(api, 'default-reader'), hasLength(2));
      },
    );

    test(
      'an unset sharedWith field matches neither empty nor named viewers',
      () async {
        final api = _api(activeMembershipLookup: (_) => false);
        api.registerDefinition(
          _machine(
            'documents',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{
              'sharedWith': 'sharedWithFanIds',
            },
            renderBindings: <Map<String, dynamic>>[_binding('documentLibrary')],
          ),
        );
        await _create(
          api,
          workflowType: 'documents',
          creator: 'seed',
          title: 'unshared seed',
        );

        expect(await _read(api, ''), isEmpty);
        expect(await _read(api, 'named-viewer'), isEmpty);
      },
    );
  });

  group('participants visibility model', () {
    test(
      'inherits the responseTable archetype and unions declared fields',
      () async {
        final api = _api(
          activeMembershipLookup: (personaId) => personaId == 'default-reader',
        );
        api
          ..registerDefinition(
            _machine(
              'thread-list',
              defaultVisibility: 'public',
              renderBindings: <Map<String, dynamic>>[
                _binding(
                  'discussionThread',
                  responseTable: <String, dynamic>{
                    'workflowType': 'thread-response',
                    'eventField': 'threadId',
                    'pendingStates': <String>['open'],
                  },
                ),
              ],
            ),
          )
          ..registerDefinition(
            _machine(
              'thread-response',
              defaultVisibility: 'membersOnly',
              visibilityFields: <String, dynamic>{
                'participants': <String>[
                  'participantFanIds',
                  'participantBFanId',
                ],
              },
            ),
          );
        await _create(
          api,
          workflowType: 'thread-response',
          creator: 'seed',
          title: 'private thread',
          data: <String, dynamic>{
            'participantFanIds': <String>['first-participant'],
            'participantBFanId': 'current-participant',
          },
        );

        expect(await _read(api, 'first-participant'), hasLength(1));
        expect(await _read(api, 'current-participant'), hasLength(1));
        expect(await _read(api, 'wrong-reader'), isEmpty);
        expect(await _read(api, 'default-reader'), hasLength(1));
      },
    );

    test(
      'unset participant fields match neither empty nor named viewers',
      () async {
        final api = _api(activeMembershipLookup: (_) => false);
        api.registerDefinition(
          _machine(
            'threads',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{
              'participants': <String>['participantFanIds'],
            },
            renderBindings: <Map<String, dynamic>>[
              _binding('discussionThread'),
            ],
          ),
        );
        await _create(
          api,
          workflowType: 'threads',
          creator: 'seed',
          title: 'participant-less seed',
        );

        expect(await _read(api, ''), isEmpty);
        expect(await _read(api, 'named-viewer'), isEmpty);
      },
    );
  });

  group('parties visibility model', () {
    test(
      'admits either named side for both parties archetypes and refuses others',
      () async {
        final api = _api(
          activeMembershipLookup: (personaId) => personaId == 'default-reader',
        );
        for (final entry in <String, String>{
          'approval': 'approvalQueueItem',
          'payment': 'paymentCheckout',
        }.entries) {
          api.registerDefinition(
            _machine(
              entry.key,
              defaultVisibility: 'membersOnly',
              visibilityFields: <String, dynamic>{
                'parties': <String>['requesterFanId', 'reviewerFanId'],
              },
              renderBindings: <Map<String, dynamic>>[_binding(entry.value)],
            ),
          );
          await _create(
            api,
            workflowType: entry.key,
            creator: 'seed',
            title: entry.key,
            data: <String, dynamic>{
              'requesterFanId': '${entry.key}-requester',
              'reviewerFanId': '${entry.key}-reviewer',
            },
          );
        }

        expect(await _read(api, 'approval-requester'), hasLength(1));
        expect(await _read(api, 'approval-reviewer'), hasLength(1));
        expect(await _read(api, 'payment-requester'), hasLength(1));
        expect(await _read(api, 'payment-reviewer'), hasLength(1));
        expect(await _read(api, 'wrong-reader'), isEmpty);
        expect(await _read(api, 'default-reader'), hasLength(2));
      },
    );

    test('unset party fields match neither empty nor named viewers', () async {
      final api = _api(activeMembershipLookup: (_) => false);
      api.registerDefinition(
        _machine(
          'approval',
          defaultVisibility: 'membersOnly',
          visibilityFields: <String, dynamic>{
            'parties': <String>['requesterFanId', 'reviewerFanId'],
          },
          renderBindings: <Map<String, dynamic>>[_binding('approvalQueueItem')],
        ),
      );
      await _create(
        api,
        workflowType: 'approval',
        creator: 'seed',
        title: 'party-less seed',
      );

      expect(await _read(api, ''), isEmpty);
      expect(await _read(api, 'named-viewer'), isEmpty);
    });

    test('role party admits a viewer whose resolved role matches', () async {
      final api = await _partiesApi(
        parties: [
          {'role': 'finance-admin'},
          {'role': 'auditor'},
        ],
      );
      api.setPersonaType('admin-account', 'finance-admin');

      expect(await _read(api, 'admin-account'), hasLength(1));
    });

    test('role party denies a viewer with a different resolved role', () async {
      final api = await _partiesApi(
        parties: [
          {'role': 'finance-admin'},
          {'role': 'auditor'},
        ],
      );
      api.setPersonaType('member-account', 'member');

      expect(await _read(api, 'member-account'), isEmpty);
    });

    test(
      'role party denies a viewer absent from the persona type map',
      () async {
        final api = await _partiesApi(
          parties: [
            {'role': 'finance-admin'},
            {'role': 'auditor'},
          ],
        );

        expect(await _read(api, 'unregistered-account'), isEmpty);
      },
    );

    test('role party denies an empty viewer id', () async {
      final api = await _partiesApi(
        parties: [
          {'role': 'finance-admin'},
          {'role': 'auditor'},
        ],
      );
      api.setPersonaType('', 'finance-admin');

      expect(await _read(api, ''), isEmpty);
    });

    test('mixed field and role parties admit both principal kinds', () async {
      final api = await _partiesApi(
        parties: [
          'payerFanId',
          {'role': 'finance-admin'},
        ],
        data: <String, dynamic>{'payerFanId': 'payer-account'},
      );
      api
        ..setPersonaType('admin-account', 'finance-admin')
        ..setPersonaType('member-account', 'member');

      expect(await _read(api, 'payer-account'), hasLength(1));
      expect(await _read(api, 'admin-account'), hasLength(1));
      expect(await _read(api, 'member-account'), isEmpty);
    });

    test('empty declared role denies even an empty resolved role', () async {
      final parsed = _machine(
        'payment',
        defaultVisibility: 'membersOnly',
        visibilityFields: <String, dynamic>{
          'parties': <String>['payerFanId', 'recipientFanId'],
        },
        renderBindings: <Map<String, dynamic>>[_binding('paymentCheckout')],
      );
      final machine = LoomWorkflowStateMachine(
        workflowType: parsed.workflowType,
        initialState: parsed.initialState,
        states: parsed.states,
        transitions: parsed.transitions,
        renderBindings: parsed.renderBindings,
        instanceDataSchema: parsed.instanceDataSchema,
        visibility: const WorkflowVisibility(
          defaultValue: WorkflowVisibilityDefault.membersOnly,
          fields: WorkflowVisibilityFields(
            parties: [
              WorkflowVisibilityRolePrincipal(roleId: ''),
              WorkflowVisibilityFieldPrincipal(fieldName: 'payerFanId'),
            ],
          ),
        ),
      );
      final api = _api(activeMembershipLookup: (_) => false)
        ..registerDefinition(machine)
        ..setPersonaType('viewer', '');
      await _create(
        api,
        workflowType: 'payment',
        creator: 'seed',
        title: 'empty-role payment',
      );

      expect(await _read(api, 'viewer'), isEmpty);
    });

    test(
      'registerDefinition preserves role principals in persisted JSON',
      () async {
        final db = WorkflowDatabase.memory();
        final api = LocalWorkflowEngineApi(
          db: db,
          communityId: 'serialization',
        );
        api.registerDefinition(
          _machine(
            'payment',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{
              'parties': [
                'payerFanId',
                {'role': 'finance-admin'},
              ],
            },
            renderBindings: <Map<String, dynamic>>[_binding('paymentCheckout')],
          ),
        );
        await _create(
          api,
          workflowType: 'payment',
          creator: 'seed',
          title: 'serialization barrier',
        );

        final serialized =
            jsonDecode((await db.loadDefinitionJson('serialization_payment'))!)
                as Map<String, dynamic>;
        expect(
          (serialized['visibility'] as Map<String, dynamic>)['fields'],
          containsPair('parties', [
            'payerFanId',
            {'role': 'finance-admin'},
          ]),
        );
      },
    );
  });

  group('recipient visibility model', () {
    test(
      'admits only the addressee while retaining default visibility',
      () async {
        final api = _api(
          activeMembershipLookup: (personaId) => personaId == 'default-reader',
        );
        api.registerDefinition(
          _machine(
            'notifications',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{'recipient': 'recipientFanId'},
            renderBindings: <Map<String, dynamic>>[
              _binding('notificationInbox'),
            ],
          ),
        );
        await _create(
          api,
          workflowType: 'notifications',
          creator: 'sender',
          title: 'private notification',
          data: <String, dynamic>{'recipientFanId': 'addressee'},
        );

        expect(await _read(api, 'addressee'), hasLength(1));
        expect(await _read(api, 'wrong-reader'), isEmpty);
        expect(await _read(api, 'default-reader'), hasLength(1));
      },
    );

    test(
      'an unset recipient matches neither empty nor named viewers',
      () async {
        final api = _api(activeMembershipLookup: (_) => false);
        api.registerDefinition(
          _machine(
            'notifications',
            defaultVisibility: 'membersOnly',
            visibilityFields: <String, dynamic>{'recipient': 'recipientFanId'},
            renderBindings: <Map<String, dynamic>>[
              _binding('notificationInbox'),
            ],
          ),
        );
        await _create(
          api,
          workflowType: 'notifications',
          creator: 'sender',
          title: 'recipient-less seed',
        );

        expect(await _read(api, ''), isEmpty);
        expect(await _read(api, 'named-viewer'), isEmpty);
      },
    );
  });

  test(
    'absent mappings never infer readers from identity-shaped data',
    () async {
      final api = _api(
        activeMembershipLookup: (personaId) => personaId == 'default-reader',
      );
      final cases = <(String, String, Map<String, dynamic>)>[
        (
          'documents',
          'documentLibrary',
          <String, dynamic>{
            'sharedWithFanIds': <String>['would-be-reader'],
          },
        ),
        (
          'threads',
          'discussionThread',
          <String, dynamic>{
            'participantFanIds': <String>['would-be-reader'],
          },
        ),
        (
          'approvals',
          'approvalQueueItem',
          <String, dynamic>{
            'requesterFanId': 'would-be-reader',
            'reviewerFanId': 'reviewer',
          },
        ),
        (
          'notifications',
          'notificationInbox',
          <String, dynamic>{
            'recipientFanId': 'would-be-reader',
            'senderFanId': 'audit-sender',
          },
        ),
      ];
      for (final (workflowType, family, data) in cases) {
        api.registerDefinition(
          _machine(
            workflowType,
            defaultVisibility: 'membersOnly',
            renderBindings: <Map<String, dynamic>>[_binding(family)],
          ),
        );
        await _create(
          api,
          workflowType: workflowType,
          creator: 'seed',
          title: workflowType,
          data: data,
        );
      }

      expect(await _read(api, 'would-be-reader'), isEmpty);
      expect(await _read(api, 'audit-sender'), isEmpty);
      // An omitted recipient is broadcast: it falls back to the default rather
      // than granting the value of an inferred recipient field.
      expect(await _read(api, 'default-reader'), hasLength(cases.length));
    },
  );

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
