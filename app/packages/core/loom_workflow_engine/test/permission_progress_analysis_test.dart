import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

/// A two-workflow fixture modelled on the Data Portability community: an
/// `exportWizard` workflow whose `failed` state is reachable only by an owner
/// role, plus a second workflow that derives nothing at all (permissions.md
/// step 3d) so the "unprocessed" path is exercised too.
Map<String, dynamic> _rawDefinition({
  required String initialState,
  required Map<String, dynamic> states,
  required List<Map<String, dynamic>> transitions,
  List<Map<String, dynamic>>? bindings,
}) => <String, dynamic>{
  'initialState': initialState,
  'states': states,
  'transitions': transitions,
  'renderBindings': bindings ??
      <Map<String, dynamic>>[
        <String, dynamic>{
          'states': <String>[initialState],
          'audience': 'any',
          'tabId': 'admin',
          'cardSurfaceFamily': 'exportWizard',
          'bindingKind': 'primary',
        },
      ],
};

Map<String, Object?> _replayFixture() => <String, Object?>{
  'export-import-replay': _rawDefinition(
    initialState: 'prepared',
    states: <String, dynamic>{
      'prepared': <String, dynamic>{'label': 'Replay prepared'},
      'validating': <String, dynamic>{'label': 'Validating replay'},
      'replayed': <String, dynamic>{
        'label': 'Replay verified',
        'isTerminal': true,
      },
      'failed': <String, dynamic>{'label': 'Replay validation failed'},
    },
    transitions: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'start-import-replay',
        'label': 'Start replay',
        'action': 'run',
        'from': <String>['prepared'],
        'to': 'validating',
        'guard': <String, dynamic>{
          'allowedRoleIds': <String>['portability-owner'],
        },
      },
      <String, dynamic>{
        'id': 'retry-import-replay',
        'label': 'Retry replay',
        'action': 'retry',
        'from': <String>['failed'],
        'to': 'validating',
        'guard': <String, dynamic>{
          'allowedRoleIds': <String>['portability-owner'],
        },
      },
      <String, dynamic>{
        'id': 'cancel-import-replay-failed',
        'label': 'Cancel replay',
        'action': 'cancel',
        'tone': 'destructive',
        'from': <String>['failed'],
        'to': 'cancelled',
        'guard': <String, dynamic>{
          'allowedRoleIds': <String>[
            'portability-owner',
            'portability-receiving-provider',
          ],
        },
      },
    ],
  ),
  // No bindings and no `responseTable` owner: derives nothing.
  'export-notification': _rawDefinition(
    initialState: 'unread',
    states: <String, dynamic>{
      'unread': <String, dynamic>{'label': 'Unread'},
      'read': <String, dynamic>{'label': 'Read'},
    },
    transitions: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'mark-notification-read',
        'label': 'Mark read',
        'from': <String>['unread'],
        'to': 'read',
        'guard': <String, dynamic>{},
      },
    ],
    bindings: const <Map<String, dynamic>>[],
  ),
};

Map<String, LoomWorkflowStateMachine> _definitions() {
  final raw = _replayFixture();
  return <String, LoomWorkflowStateMachine>{
    for (final entry in raw.entries)
      entry.key: LoomWorkflowStateMachine.fromJson(
        Map<String, dynamic>.from(entry.value! as Map),
        entry.key,
      ),
  };
}

CommunityPermissionProgressReport _analyze(
  Map<String, Set<String>> derivedByRole,
) => const CommunityPermissionProgressAnalyzer.defaults().analyze(
  communityHandle: 'data-portability-community',
  rawWorkflowDefinitions: _replayFixture(),
  workflowDefinitions: _definitions(),
  derivedPermissionIdsByRole: derivedByRole,
);

void main() {
  test('groups a multi-state workflow by state', () {
    final report = _analyze(const {});

    expect(report.groupId, 'loom_communities_data-portability-community');
    final nodes = report.workflowNodes['export-import-replay'];
    expect(nodes, isNotNull);
    expect(
      nodes!.keys,
      containsAll(<String>['prepared', 'validating', 'replayed', 'failed']),
    );

    // Transitions land on the state they leave, not on the workflow as a whole.
    expect(
      nodes['prepared']!.transitions.map((t) => t.transitionId),
      <String>['start-import-replay'],
    );
    expect(
      nodes['failed']!.transitions.map((t) => t.transitionId),
      <String>['retry-import-replay', 'cancel-import-replay-failed'],
    );
    // `replayed` is terminal with no declared exit, so it owns no transitions.
    expect(nodes['replayed']!.transitions, isEmpty);
    expect(nodes['replayed']!.isTerminal, isTrue);
  });

  test('a workflow that derives nothing is recorded, not silently dropped', () {
    final report = _analyze(const {});
    expect(report.unprocessedWorkflowTypes, <String>['export-notification']);
    expect(report.workflowNodes.containsKey('export-notification'), isFalse);
  });

  test(
    'names the state and the permission a role is missing to leave it',
    () {
      // `portability-receiving-provider` may fire `cancel-import-replay-failed`
      // from `failed`, but holds nothing.
      final report = _analyze(const {
        'portability-receiving-provider': <String>{},
      });

      final finding = report.stuckRoleFindings.singleWhere(
        (f) =>
            f.roleId == 'portability-receiving-provider' &&
            f.state == 'failed',
      );
      expect(finding.workflowType, 'export-import-replay');
      expect(finding.blockedTransitions, <String>['cancel-import-replay-failed']);
      expect(
        finding.missingPermissionIds,
        <String>['export_wizard.cancel'],
      );
      expect(
        finding.sentence,
        'portability-receiving-provider cannot leave `failed` on '
        '`export-import-replay`: progressing requires transition '
        '`cancel-import-replay-failed`, which requires `export_wizard.cancel`, '
        'which it does not hold.',
      );
    },
  );

  test('a role holding everything it needs reports no gap', () {
    final report = _analyze(const {
      'portability-owner': <String>{
        'export_wizard.run',
        'export_wizard.retry',
        'export_wizard.cancel',
      },
      'portability-receiving-provider': <String>{'export_wizard.cancel'},
    });

    expect(
      report.stuckRoleFindings,
      isEmpty,
      reason: 'every permitted action is backed by a held permission',
    );
  });

  test('a read-only role that derives nothing is never stuck', () {
    // `portability-member` appears in no transition guard at all. Zero
    // permissions is CORRECT for it, so the analysis must not report a gap --
    // the same rule the parity gate keys on.
    final report = _analyze(const {
      'portability-owner': <String>{
        'export_wizard.run',
        'export_wizard.retry',
        'export_wizard.cancel',
      },
      'portability-receiving-provider': <String>{'export_wizard.cancel'},
      'portability-member': <String>{},
    });

    expect(
      report.stuckRoleFindings.where((f) => f.roleId == 'portability-member'),
      isEmpty,
    );
  });

  test('only the missing permission is named, not the whole action set', () {
    // The owner can fire `retry-import-replay` and
    // `cancel-import-replay-failed` from `failed` but lacks exactly one.
    final report = _analyze(const {
      'portability-owner': <String>{'export_wizard.retry'},
    });

    final finding = report.stuckRoleFindings.singleWhere(
      (f) => f.roleId == 'portability-owner' && f.state == 'failed',
    );
    expect(finding.blockedTransitions, <String>['cancel-import-replay-failed']);
    expect(finding.missingPermissionIds, <String>['export_wizard.cancel']);
  });

  test('a generic family derives its action structurally from the JSON', () {
    // `statusTimeline` is generic: no `action` field, so the permission comes
    // from `tone: destructive` / `isTerminal` / otherwise `advance`.
    final raw = <String, Object?>{
      'request-status': _rawDefinition(
        initialState: 'open',
        states: <String, dynamic>{
          'open': <String, dynamic>{'label': 'Open'},
          'closed': <String, dynamic>{'label': 'Closed'},
          'void': <String, dynamic>{'label': 'Void'},
        },
        transitions: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'advance-status',
            'label': 'Advance',
            'from': <String>['open'],
            'to': 'closed',
            'guard': <String, dynamic>{
              'allowedRoleIds': <String>['participant'],
            },
          },
          <String, dynamic>{
            'id': 'void-status',
            'label': 'Void',
            'tone': 'destructive',
            'from': <String>['open'],
            'to': 'void',
            'guard': <String, dynamic>{
              'allowedRoleIds': <String>['participant'],
            },
          },
        ],
        bindings: const <Map<String, dynamic>>[
          <String, dynamic>{
            'states': <String>['open'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'statusTimeline',
            'bindingKind': 'primary',
          },
        ],
      ),
    };
    final definitions = <String, LoomWorkflowStateMachine>{
      'request-status': LoomWorkflowStateMachine.fromJson(
        Map<String, dynamic>.from(raw['request-status']! as Map),
        'request-status',
      ),
    };
    final report = const CommunityPermissionProgressAnalyzer.defaults().analyze(
      communityHandle: 'camera-club',
      rawWorkflowDefinitions: raw,
      workflowDefinitions: definitions,
      derivedPermissionIdsByRole: const {'participant': <String>{}},
    );

    final finding = report.stuckRoleFindings.single;
    expect(finding.state, 'open');
    expect(finding.blockedTransitions, <String>['advance-status', 'void-status']);
    expect(
      finding.missingPermissionIds,
      <String>['status_timeline.advance', 'status_timeline.terminate'],
    );
  });

  test('a non-role guard is summarized so the runtime report can name it', () {
    final raw = <String, Object?>{
      'owner-approval': _rawDefinition(
        initialState: 'draft',
        states: <String, dynamic>{
          'draft': <String, dynamic>{'label': 'Draft'},
          'approved': <String, dynamic>{'label': 'Approved'},
        },
        transitions: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'approve',
            'label': 'Approve',
            'from': <String>['draft'],
            'to': 'approved',
            'guard': <String, dynamic>{
              'actorEqualsField': <String, dynamic>{'key': 'ownerFanId'},
              'allowedRoleIds': <String>['hoa-board'],
            },
          },
        ],
      ),
    };
    final report = const CommunityPermissionProgressAnalyzer.defaults().analyze(
      communityHandle: 'cedar-commons-hoa',
      rawWorkflowDefinitions: raw,
      workflowDefinitions: <String, LoomWorkflowStateMachine>{
        'owner-approval': LoomWorkflowStateMachine.fromJson(
          Map<String, dynamic>.from(raw['owner-approval']! as Map),
          'owner-approval',
        ),
      },
      derivedPermissionIdsByRole: const {
        'hoa-board': <String>{'form_entry.advance'},
      },
    );

    final node = report.workflowNodes['owner-approval']!['draft']!;
    expect(node.transitions.single.guardSummary, <String>['actorEqualsField:ownerFanId']);
    expect(node.transitions.single.allowedRoleIds, <String>['hoa-board']);
  });

  test('a state-level read guard is retained on the node', () {
    // `WorkflowStateNode.readRoleIds` reads the STATE's own `readGuard`, which
    // is the per-state shape. The workflow-level `visibility.readGuard` is a
    // different declaration and deliberately does not populate it.
    final raw = <String, Object?>{
      'export-import-replay': _rawDefinition(
        initialState: 'prepared',
        states: <String, dynamic>{
          'prepared': <String, dynamic>{
            'label': 'Replay prepared',
            'readGuard': <String, dynamic>{
              'allowedRoleIds': <String>[
                'portability-owner',
                'portability-member',
              ],
            },
          },
        },
        transitions: const <Map<String, dynamic>>[],
      ),
    };
    final report = const CommunityPermissionProgressAnalyzer.defaults().analyze(
      communityHandle: 'data-portability-community',
      rawWorkflowDefinitions: raw,
      workflowDefinitions: <String, LoomWorkflowStateMachine>{
        'export-import-replay': LoomWorkflowStateMachine.fromJson(
          Map<String, dynamic>.from(raw['export-import-replay']! as Map),
          'export-import-replay',
        ),
      },
      derivedPermissionIdsByRole: const {'portability-member': <String>{}},
    );

    final node = report.workflowNodes['export-import-replay']!['prepared']!;
    expect(node.readRoleIds, <String>['portability-owner', 'portability-member']);
    expect(
      report.stuckRoleFindings,
      isEmpty,
      reason: 'a read guard alone never makes a role stuck',
    );
  });

  test('findings are ordered deterministically by role, workflow, state', () {
    final report = _analyze(const {
      'portability-receiving-provider': <String>{},
      'portability-owner': <String>{},
    });
    final keys = [
      for (final f in report.stuckRoleFindings)
        '${f.roleId}|${f.workflowType}|${f.state}',
    ];
    final sorted = [...keys]..sort();
    expect(keys, sorted);
  });
}
