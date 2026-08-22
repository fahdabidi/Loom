import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _requestId = 'cedar-commons-architectural-request';
const _homeownerAccountId = 'hoa-homeowner-avery';
const _peerAccountId = 'hoa-homeowner-casey';
const _boardAccountId = 'hoa-board-reviewer';
var _fixtureSequence = 0;

const _accounts = <LoomAccount>[
  LoomAccount(
    accountId: _homeownerAccountId,
    displayName: 'Avery Brooks',
    roleId: 'hoa-homeowner',
  ),
  LoomAccount(
    accountId: _peerAccountId,
    displayName: 'Casey Homeowner',
    roleId: 'hoa-homeowner',
  ),
  LoomAccount(
    accountId: _boardAccountId,
    displayName: 'Board Reviewer',
    roleId: 'hoa-board',
  ),
];

void main() {
  group('M4.2 HOA architectural requests', () {
    testWidgets(
      'homeowner submits request and editable submitted fields render',
      (tester) async {
        final fixture = _writeFixture();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndSignIn(tester, fixture, 'Avery Brooks');
        await _openTab(tester, 'requests', expectRequest: true);

        expect(_requestCard, findsOneWidget);
        expect(_editor('projectDescription'), findsOneWidget);
        expect(_editor('propertyAddress'), findsOneWidget);
        await _submitRequest(tester, 'Fence color update');

        expect(find.text('State: Submitted'), findsOneWidget);
        expect(find.text('Project: Fence color update'), findsOneWidget);
        expect(_action('withdraw'), findsOneWidget);

        // `approvalQueueItem` visibility is scoped to the two individual
        // parties. Another homeowner must not inherit Avery's request.
        await signInEvidenceAccount(tester, 'Casey Homeowner');
        await openEvidenceTarget(tester, fixture.target);
        await _openTab(tester, 'requests', expectRequest: false);
        expect(_requestCard, findsNothing);
        expect(
          find.byKey(const ValueKey('engine-native-list-error-requests')),
          findsNothing,
        );
      },
    );

    testWidgets('board dashboard queue opens same reviewer timeline', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Pergola review packet');

      await _switchAccount(tester, fixture, 'Board Reviewer');
      await _openTab(tester, 'admin', expectRequest: true);

      expect(_requestCard, findsOneWidget);
      expect(find.text('Project: Pergola review packet'), findsOneWidget);
      expect(_action('start-review'), findsOneWidget);
      expect(_action('request-changes'), findsOneWidget);
      expect(_action('approve'), findsOneWidget);
      expect(_action('reject'), findsOneWidget);
      expect(_action('withdraw'), findsNothing);
    });

    testWidgets('board request-changes sends homeowner back to editable form', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Solar panel sketch');

      await _switchAccount(tester, fixture, 'Board Reviewer');
      await _openTab(tester, 'admin', expectRequest: true);
      await _tapAction(tester, 'request-changes');

      expect(find.text('State: changes needed'), findsOneWidget);
      expect(
        find.text(
          'Reviewer note: Please revise the color sample and setback diagram.',
        ),
        findsOneWidget,
      );

      await _switchAccount(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      expect(find.text('State: changes needed'), findsOneWidget);
      expect(_editor('projectDescription'), findsOneWidget);
      expect(_action('resubmit'), findsOneWidget);
    });

    testWidgets('board approves and homeowner can reopen approved request', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Deck railing update');

      await _switchAccount(tester, fixture, 'Board Reviewer');
      await _openTab(tester, 'admin', expectRequest: true);
      await _tapAction(tester, 'approve');
      expect(find.text('State: Approved'), findsOneWidget);

      await _switchAccount(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      expect(_action('submit'), findsNothing);
      expect(_action('resubmit'), findsNothing);
      await _tapAction(tester, 'reopen');
      expect(find.text('State: Reopened'), findsOneWidget);
    });

    testWidgets('board rejects and homeowner can appeal', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Mailbox replacement');

      await _switchAccount(tester, fixture, 'Board Reviewer');
      await _openTab(tester, 'admin', expectRequest: true);
      await _tapAction(tester, 'reject');
      expect(find.text('State: Denied'), findsOneWidget);

      await _switchAccount(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _tapAction(tester, 'appeal');
      expect(find.text('State: Reopened'), findsOneWidget);
    });

    testWidgets('homeowner can withdraw a submitted request', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Patio light change');

      await _tapAction(tester, 'withdraw');
      expect(find.text('State: Withdrawn'), findsOneWidget);
      expect(_action('submit'), findsNothing);
      expect(_action('withdraw'), findsNothing);
    });

    testWidgets('homeowner can resubmit after reviewer send-back', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _submitRequest(tester, 'Garden wall update');

      await _switchAccount(tester, fixture, 'Board Reviewer');
      await _openTab(tester, 'admin', expectRequest: true);
      await _tapAction(tester, 'request-changes');

      await _switchAccount(tester, fixture, 'Avery Brooks');
      await _openTab(tester, 'requests', expectRequest: true);
      await _tapAction(tester, 'resubmit');
      expect(find.text('State: Submitted'), findsOneWidget);
    });
  });
}

Finder get _requestCard =>
    find.byKey(const ValueKey('generic-instance-card-$_requestId'));

Finder _editor(String field) =>
    find.byKey(ValueKey('generic-instance-editor-$_requestId-$field'));

Finder _action(String transitionId) =>
    find.byKey(ValueKey('generic-instance-$_requestId-action-$transitionId'));

Future<void> _openTab(
  WidgetTester tester,
  String tabId, {
  required bool expectRequest,
}) async {
  await tapCommunityTab(tester, tabId);
  await waitForEngineNativeWidget(
    tester,
    expectRequest
        ? _requestCard
        : find.byKey(ValueKey('engine-native-list-empty-$tabId')),
    description: expectRequest
        ? 'architectural request on $tabId'
        : 'party-filtered empty $tabId surface',
  );
}

Future<void> _submitRequest(WidgetTester tester, String project) async {
  await tester.enterText(_editor('projectDescription'), project);
  await _tapVisible(
    tester,
    find.byKey(const ValueKey('generic-instance-save-$_requestId')),
  );
  await _tapAction(tester, 'submit');
  await waitForEngineNativeWidget(
    tester,
    find.text('State: Submitted'),
    description: 'submitted architectural request',
  );
}

Future<void> _tapAction(WidgetTester tester, String transitionId) async {
  await _tapVisible(tester, _action(transitionId));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await waitForEngineNativeWidget(
    tester,
    finder,
    description: 'architectural request control $finder',
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _installAndSignIn(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
  fixture,
  String displayName,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.package.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.package.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('community-card-${fixture.communityId}')),
  );
  await tester.pumpAndSettle();
  await seedEvidenceAccounts(tester, fixture.target, _accounts);
  await signInEvidenceAccount(tester, displayName);
}

Future<void> _switchAccount(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
  fixture,
  String displayName,
) async {
  await signInEvidenceAccount(tester, displayName);
  await openEvidenceTarget(tester, fixture.target);
}

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeFixture() {
  final sequence = _fixtureSequence++;
  final extensionId = 'ext_verify_hoa_requests_$sequence';
  final communityId = 'community_verify_hoa_requests_$sequence';
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'draft',
    visibility: <String, Object?>{
      'default': 'guarded',
      'readGuard': <String, Object?>{
        'actorEqualsField': <String, Object?>{'key': 'requesterFanId'},
      },
      'fields': <String, Object?>{
        'parties': <String>['requesterFanId', 'reviewerFanId'],
      },
    },
    states: <String, Object?>{
      'draft': <String, Object?>{
        'label': 'Draft',
        'editableFields': <String>[
          'projectDescription',
          'propertyAddress',
          'requestedCompletionDate',
          'attachments',
        ],
      },
      'submitted': <String, Object?>{
        'label': 'Submitted',
        'editableFields': <String>[
          'projectDescription',
          'propertyAddress',
          'requestedCompletionDate',
          'attachments',
        ],
      },
      'under-review': <String, Object?>{'label': 'Under review'},
      'changes-needed': <String, Object?>{
        'label': 'Changes needed',
        'editableFields': <String>[
          'projectDescription',
          'propertyAddress',
          'requestedCompletionDate',
          'attachments',
        ],
      },
      'approved': <String, Object?>{'label': 'Approved'},
      'denied': <String, Object?>{'label': 'Denied'},
      'reopened': <String, Object?>{
        'label': 'Reopened',
        'editableFields': <String>[
          'projectDescription',
          'propertyAddress',
          'requestedCompletionDate',
          'attachments',
        ],
      },
      'withdrawn': <String, Object?>{'label': 'Withdrawn', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      _homeownerTransition(
        id: 'submit',
        label: 'Submit request',
        from: <String>['draft'],
        to: 'submitted',
        stateLabel: 'submitted',
      ),
      _boardTransition(
        id: 'start-review',
        label: 'Start review',
        from: <String>['submitted'],
        to: 'under-review',
        stateLabel: 'under review',
      ),
      _boardTransition(
        id: 'request-changes',
        label: 'Request changes',
        from: <String>['submitted', 'under-review'],
        to: 'changes-needed',
        stateLabel: 'changes needed',
        extraEffects: <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'reviewerNote',
            'value': 'Please revise the color sample and setback diagram.',
          },
        ],
      ),
      _boardTransition(
        id: 'approve',
        label: 'Approve',
        from: <String>['submitted', 'under-review'],
        to: 'approved',
        stateLabel: 'approved',
      ),
      _boardTransition(
        id: 'reject',
        label: 'Reject',
        from: <String>['submitted', 'under-review'],
        to: 'denied',
        stateLabel: 'denied',
      ),
      _homeownerTransition(
        id: 'withdraw',
        label: 'Withdraw',
        from: <String>[
          'submitted',
          'under-review',
          'changes-needed',
          'reopened',
        ],
        to: 'withdrawn',
        stateLabel: 'withdrawn',
      ),
      _homeownerTransition(
        id: 'resubmit',
        label: 'Resubmit',
        from: <String>['changes-needed'],
        to: 'submitted',
        stateLabel: 'submitted',
      ),
      _homeownerTransition(
        id: 'reopen',
        label: 'Reopen',
        from: <String>['approved'],
        to: 'reopened',
        stateLabel: 'reopened',
      ),
      _homeownerTransition(
        id: 'appeal',
        label: 'Appeal',
        from: <String>['denied'],
        to: 'reopened',
        stateLabel: 'reopened',
      ),
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: const <String>[
          'draft',
          'submitted',
          'under-review',
          'changes-needed',
          'approved',
          'denied',
          'reopened',
          'withdrawn',
        ],
        tabId: 'requests',
        cardSurfaceFamily: 'approvalQueueItem',
      ),
      engineNativeTestRenderBinding(
        states: const <String>[
          'submitted',
          'under-review',
          'changes-needed',
          'approved',
          'denied',
          'reopened',
          'withdrawn',
        ],
        tabId: 'admin',
        cardSurfaceFamily: 'approvalQueueItem',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'requesterFanId': <String, Object?>{
        'type': 'fanId',
        'required': true,
        'displayContexts': <String>['detail'],
      },
      'reviewerFanId': <String, Object?>{
        'type': 'fanId',
        'required': true,
        'displayContexts': <String>['detail'],
      },
      'stateLabel': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'labelTemplate': 'State: {value}',
      },
      'projectDescription': <String, Object?>{
        'type': 'textarea',
        'required': true,
        'writableBy': 'formEntry',
        'labelTemplate': 'Project: {value}',
      },
      'propertyAddress': <String, Object?>{
        'type': 'text',
        'required': true,
        'writableBy': 'formEntry',
        'labelTemplate': 'Property: {value}',
      },
      'requestedCompletionDate': <String, Object?>{
        'type': 'date',
        'writableBy': 'formEntry',
        'labelTemplate': 'Requested completion: {value}',
      },
      'attachments': <String, Object?>{
        'type': 'text',
        'writableBy': 'formEntry',
        'labelTemplate': 'Attachments: {value}',
      },
      'reviewerNote': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'labelTemplate': 'Reviewer note: {value}',
        'hideWhenEmpty': true,
      },
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b39_hoa_requests_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Cedar Commons HOA',
    permissions: const <String>['requests.read', 'requests.write'],
    experience: <String, Object?>{
      'displayName': 'Cedar Commons HOA',
      'tagline': 'Account-scoped architectural review.',
      'accentColor': '#3E6B8F',
      'theme': <String, Object?>{'accent': '#3E6B8F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'hoa-homeowner',
          'label': 'Homeowner',
          'roleLabel': 'Homeowner',
          'description': 'Submits architectural requests.',
        },
        <String, Object?>{
          'roleId': 'hoa-board',
          'label': 'HOA Board',
          'roleLabel': 'Board',
          'description': 'Reviews architectural requests.',
        },
      ],
      'workflowDefinitions': <String, Object?>{_requestId: definition},
      'workflowInstances': <Object?>[
        engineNativeTestWorkflowInstance(
          instanceId: _requestId,
          workflowType: _requestId,
          currentState: 'draft',
          createdByFanId: _homeownerAccountId,
          instanceData: <String, Object?>{
            'requesterFanId': _homeownerAccountId,
            'reviewerFanId': _boardAccountId,
            'stateLabel': 'draft',
            'projectDescription': 'Fence color update',
            'propertyAddress': '42 Cedar Loop',
            'requestedCompletionDate': '2026-08-15',
            'attachments': 'site-plan.pdf',
            'reviewerNote': null,
          },
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'requests',
          'label': 'Requests',
          'iconKey': 'home',
          'visibleRoleIds': <String>['hoa-homeowner'],
        },
        <String, Object?>{
          'tabId': 'admin',
          'label': 'Board review',
          'iconKey': 'admin',
          'visibleRoleIds': <String>['hoa-board'],
        },
      ],
    },
  );
  return (
    package: package,
    communityId: communityId,
    target: LoomEvidenceTarget(
      phase: 'test',
      communityId: communityId,
      communityName: 'Cedar Commons HOA',
      handle: 'hoa-requests-$sequence',
      extensionId: extensionId,
      accentColor: '#3E6B8F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
}

Map<String, Object?> _homeownerTransition({
  required String id,
  required String label,
  required List<String> from,
  required String to,
  required String stateLabel,
}) => <String, Object?>{
  'id': id,
  'label': label,
  'from': from,
  'to': to,
  'guard': <String, Object?>{
    'allowedRoleIds': <String>['hoa-homeowner'],
    'actorEqualsField': <String, Object?>{'key': 'requesterFanId'},
  },
  'effects': <Object?>[
    <String, Object?>{'op': 'set', 'key': 'stateLabel', 'value': stateLabel},
  ],
};

Map<String, Object?> _boardTransition({
  required String id,
  required String label,
  required List<String> from,
  required String to,
  required String stateLabel,
  List<Object?> extraEffects = const <Object?>[],
}) => <String, Object?>{
  'id': id,
  'label': label,
  'from': from,
  'to': to,
  'guard': <String, Object?>{
    'allowedRoleIds': <String>['hoa-board'],
    'actorEqualsField': <String, Object?>{'key': 'reviewerFanId'},
  },
  'effects': <Object?>[
    <String, Object?>{'op': 'set', 'key': 'stateLabel', 'value': stateLabel},
    ...extraEffects,
  ],
};
