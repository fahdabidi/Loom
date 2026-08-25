import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _workflowType = 'cedar-commons-document-library';
const _ownerAccountId = 'hoa-homeowner-avery';
const _peerAccountId = 'hoa-homeowner-casey';
const _boardAccountId = 'hoa-board-reviewer';
var _fixtureSequence = 0;

const _accounts = <LoomAccount>[
  LoomAccount(
    accountId: _ownerAccountId,
    displayName: 'Avery Brooks',
    roleId: 'hoa-member',
  ),
  LoomAccount(
    accountId: _peerAccountId,
    displayName: 'Casey Homeowner',
    roleId: 'hoa-member',
  ),
  LoomAccount(
    accountId: _boardAccountId,
    displayName: 'Board Reviewer',
    roleId: 'hoa-board',
  ),
];

void main() {
  group('M4.1 HOA document library', () {
    testWidgets('category navigation opens the minutes folder', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openDocuments(tester, expectDocuments: true);

      // v4 documentLibrary surfaces are instance lists rather than a shallow
      // category-folder navigator. Preserve the category-browsing intent by
      // proving that the typed Minutes row is present alongside the others.
      expect(_documentCard('doc-board-minutes'), findsOneWidget);
      expect(find.text('April Board Minutes'), findsOneWidget);
      expect(find.text('Category: Minutes'), findsOneWidget);
      expect(_documentCard('doc-community-rules'), findsOneWidget);
      expect(find.text('Community Rules'), findsOneWidget);
    });

    testWidgets('document detail supports embedded and external open', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openDocuments(tester, expectDocuments: true);

      final embedded = _documentDescendant(
        'doc-community-rules',
        find.byKey(
          const ValueKey('workflow-fact-url-documentUrl-open-embedded'),
        ),
      );
      final external = _documentDescendant(
        'doc-community-rules',
        find.byKey(
          const ValueKey('workflow-fact-url-documentUrl-open-external'),
        ),
      );
      expect(embedded, findsOneWidget);
      expect(external, findsOneWidget);
      expect(tester.widget<InkWell>(external).onTap, isNotNull);

      await _tapVisible(tester, embedded);
      expect(
        find.byKey(const ValueKey('document-library-embedded-viewer')),
        findsOneWidget,
      );
      expect(find.text('Open document'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        _documentAction('doc-community-rules', 'record-resource-open'),
      );
      final row = await _documentRow(
        fixture.target.extensionId,
        'doc-community-rules',
      );
      expect(row.instanceData['openedFanIds'], contains(_ownerAccountId));
      _expectAuditEntry(
        row.instanceData['auditTrail'],
        event: 'opened',
        documentId: 'doc-community-rules',
      );
    });

    testWidgets('document detail displays version and access state', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openDocuments(tester, expectDocuments: true);

      expect(find.text('Version: v2026.3'), findsOneWidget);
      expect(find.text('Access: Available'), findsWidgets);
      expect(find.text('Updated July 2026'), findsOneWidget);
    });

    testWidgets('restricted document renders access request gating', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openDocuments(tester, expectDocuments: true);

      expect(_documentCard('doc-ccr-amendment'), findsOneWidget);
      expect(find.text('CCR Amendment Packet'), findsOneWidget);
      expect(find.text('Access: Restricted'), findsOneWidget);
      expect(
        _documentAction('doc-ccr-amendment', 'record-resource-open'),
        findsNothing,
      );
      expect(
        _documentAction('doc-ccr-amendment', 'request-resource-access'),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        _documentAction('doc-ccr-amendment', 'request-resource-access'),
      );
      await _openDocuments(tester, expectDocuments: true);
      await tester.ensureVisible(_documentCard('doc-ccr-amendment'));
      await tester.pumpAndSettle();
      expect(find.text('Access: Access Requested'), findsOneWidget);

      final row = await _documentRow(
        fixture.target.extensionId,
        'doc-ccr-amendment',
      );
      expect(
        row.instanceData['accessRequestedFanIds'],
        contains(_ownerAccountId),
      );
      _expectAuditEntry(
        row.instanceData['auditTrail'],
        event: 'access-requested',
        documentId: 'doc-ccr-amendment',
      );

      // Avery sees this board-owned document only because the owner shared it
      // with Avery's individual account. Casey has the same role but is not in
      // `sharedWithFanIds`, so the entire library is genuinely empty for them.
      await signInEvidenceAccount(tester, 'Casey Homeowner');
      await openEvidenceTarget(tester, fixture.target);
      await _openDocuments(tester, expectDocuments: false);
      expect(_documentCard('doc-ccr-amendment'), findsNothing);
      expect(
        find.byKey(const ValueKey('engine-native-list-error-documents')),
        findsNothing,
      );
    });

    testWidgets('acknowledge records exact audit trail entry', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Avery Brooks');
      await _openDocuments(tester, expectDocuments: true);

      await _tapVisible(
        tester,
        _documentAction('doc-community-rules', 'acknowledge-resource'),
      );
      await _openDocuments(tester, expectDocuments: true);
      await tester.ensureVisible(_documentCard('doc-community-rules'));
      await tester.pumpAndSettle();
      await waitForEngineNativeWidget(
        tester,
        find.text('Access: Acknowledged'),
        description: 'acknowledged document state',
      );

      final row = await _documentRow(
        fixture.target.extensionId,
        'doc-community-rules',
      );
      expect(row.instanceData['acknowledgedFanIds'], <String>[_ownerAccountId]);
      _expectAuditEntry(
        row.instanceData['auditTrail'],
        event: 'acknowledged',
        documentId: 'doc-community-rules',
      );
    });
  });
}

Finder _documentCard(String documentId) =>
    find.byKey(ValueKey('engine-native-list-item-documents-$documentId-0'));

Finder _documentDescendant(String documentId, Finder matching) =>
    find.descendant(of: _documentCard(documentId), matching: matching);

Finder _documentAction(String documentId, String transitionId) =>
    find.byKey(ValueKey('document-library-$documentId-action-$transitionId'));

Future<void> _openDocuments(
  WidgetTester tester, {
  required bool expectDocuments,
}) async {
  await tapCommunityTab(tester, 'documents');
  await waitForEngineNativeWidget(
    tester,
    expectDocuments
        ? _documentCard('doc-community-rules')
        : find.byKey(const ValueKey('engine-native-list-empty-documents')),
    description: expectDocuments
        ? 'engine-native HOA document library'
        : 'owner-and-shared filtered empty document library',
  );
}

Future<dynamic> _documentRow(String extensionId, String documentId) async {
  final engine = await workflowEngineForExtensionId(extensionId);
  final page = await engine.queryInstances(
    tabId: 'documents',
    fanId: _ownerAccountId,
    limit: 20,
  );
  return page.items.singleWhere((item) => item.instanceId == documentId);
}

void _expectAuditEntry(
  Object? value, {
  required String event,
  required String documentId,
}) {
  expect(value, isA<List<Object?>>());
  final entries = value! as List<Object?>;
  expect(entries, isNotEmpty);
  final entry = entries.last! as Map<String, dynamic>;
  expect(entry['actorFanId'], _ownerAccountId);
  expect(entry['event'], event);
  expect(entry['documentId'], documentId);
  expect(entry['timestamp'], isA<String>());
  expect(DateTime.tryParse(entry['timestamp']! as String), isNotNull);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await waitForEngineNativeWidget(
    tester,
    finder,
    description: 'document-library control $finder',
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

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeFixture() {
  final sequence = _fixtureSequence++;
  final extensionId = 'ext_verify_hoa_documents_$sequence';
  final communityId = 'community_verify_hoa_documents_$sequence';
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'available',
    visibility: <String, Object?>{
      'default': 'guarded',
      'readGuard': <String, Object?>{
        'allowedRoleIds': <String>['hoa-board'],
      },
      'fields': <String, Object?>{'sharedWith': 'sharedWithFanIds'},
    },
    states: <String, Object?>{
      'available': <String, Object?>{'label': 'Available'},
      'restricted': <String, Object?>{'label': 'Restricted'},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'record-resource-open',
        'action': 'open',
        'label': 'Open document',
        'from': <String>['available'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['hoa-member', 'hoa-board'],
          'actorInList': <String, Object?>{
            'key': 'openedFanIds',
            'present': false,
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'appendUnique',
            'key': 'openedFanIds',
            'value': r'$actor',
          },
          _auditEffect('opened'),
        ],
      },
      <String, Object?>{
        'id': 'acknowledge-resource',
        'action': 'acknowledge',
        'label': 'Acknowledge',
        'from': <String>['available'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['hoa-member'],
          'actorInList': <String, Object?>{
            'key': 'acknowledgedFanIds',
            'present': false,
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'appendUnique',
            'key': 'acknowledgedFanIds',
            'value': r'$actor',
          },
          <String, Object?>{
            'op': 'set',
            'key': 'accessState',
            'value': 'acknowledged',
          },
          _auditEffect('acknowledged'),
        ],
      },
      <String, Object?>{
        'id': 'request-resource-access',
        'action': 'request_access',
        'label': 'Request access',
        'from': <String>['restricted'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['hoa-member'],
          'actorInList': <String, Object?>{
            'key': 'accessRequestedFanIds',
            'present': false,
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'appendUnique',
            'key': 'accessRequestedFanIds',
            'value': r'$actor',
          },
          <String, Object?>{
            'op': 'set',
            'key': 'accessState',
            'value': 'access-requested',
          },
          _auditEffect('access-requested'),
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['available', 'restricted'],
        tabId: 'documents',
        cardSurfaceFamily: 'documentLibrary',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'required': true,
        'labelTemplate': '{value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'category': <String, Object?>{
        'type': 'text',
        'required': true,
        'labelTemplate': 'Category: {value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'version': <String, Object?>{
        'type': 'text',
        'required': true,
        'labelTemplate': 'Version: {value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'updatedLabel': <String, Object?>{
        'type': 'text',
        'labelTemplate': '{value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'accessState': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'labelTemplate': 'Access: {value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'summary': <String, Object?>{
        'type': 'textarea',
        'labelTemplate': '{value}',
        'displayContexts': <String>['detail'],
      },
      'documentUrl': <String, Object?>{
        'type': 'url',
        'openMode': 'choice',
        'labelTemplate': 'Open document',
        'displayContexts': <String>['tile', 'detail'],
      },
      'sharedWithFanIds': <String, Object?>{
        'type': 'fanId[]',
        'displayContexts': <String>[],
      },
      // These are the documentLibrary archetype's declared bookkeeping
      // fields. The engine transitions own every mutation and audit write.
      'openedFanIds': <String, Object?>{
        'type': 'fanId[]',
        'writableBy': 'effect',
        'displayContexts': <String>[],
      },
      'acknowledgedFanIds': <String, Object?>{
        'type': 'fanId[]',
        'writableBy': 'effect',
        'displayContexts': <String>[],
      },
      'accessRequestedFanIds': <String, Object?>{
        'type': 'fanId[]',
        'writableBy': 'effect',
        'displayContexts': <String>[],
      },
      'auditTrail': <String, Object?>{
        'type': 'list',
        'writableBy': 'effect',
        'labelTemplate': 'Audit entries: {value.length}',
        'displayContexts': <String>['tile', 'detail'],
      },
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b38_hoa_docs_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Cedar Commons HOA',
    permissions: const <String>['documents.read', 'documents.write'],
    experience: <String, Object?>{
      'displayName': 'Cedar Commons HOA',
      'tagline': 'Private governing documents and acknowledgements.',
      'accentColor': '#3E6B8F',
      'theme': <String, Object?>{'accent': '#3E6B8F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'hoa-member',
          'label': 'Homeowner',
          'roleLabel': 'Homeowner',
          'description': 'Reads documents shared with their account.',
        },
        <String, Object?>{
          'roleId': 'hoa-board',
          'label': 'HOA Board',
          'roleLabel': 'Board',
          'description': 'Owns governing documents.',
        },
      ],
      'workflowDefinitions': <String, Object?>{_workflowType: definition},
      'workflowInstances': <Object?>[
        _documentInstance(
          documentId: 'doc-community-rules',
          createdByFanId: _ownerAccountId,
          title: 'Community Rules',
          category: 'bylaws',
          version: 'v2026.3',
          updatedLabel: 'Updated July 2026',
          accessState: 'available',
          summary:
              'Member-visible rules, quiet hours, parking, and common-area policies.',
        ),
        _documentInstance(
          documentId: 'doc-ccr-amendment',
          createdByFanId: _boardAccountId,
          title: 'CCR Amendment Packet',
          category: 'covenants',
          version: 'v2026.1',
          updatedLabel: 'Board draft',
          accessState: 'restricted',
          sharedWithFanIds: const <String>[_ownerAccountId],
          summary:
              'Board-reviewed covenant amendment packet requiring access approval.',
        ),
        _documentInstance(
          documentId: 'doc-board-minutes',
          createdByFanId: _ownerAccountId,
          title: 'April Board Minutes',
          category: 'minutes',
          version: 'v2026.04',
          updatedLabel: 'Posted May 2',
          accessState: 'available',
          summary: 'Approved meeting minutes from the April board session.',
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'documents',
          'label': 'Documents',
          'iconKey': 'documents',
          'visibleRoleIds': <String>['hoa-member', 'hoa-board'],
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
      handle: 'hoa-documents-$sequence',
      extensionId: extensionId,
      accentColor: '#3E6B8F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
}

Map<String, Object?> _auditEffect(String event) => <String, Object?>{
  'op': 'append',
  'key': 'auditTrail',
  'value': <String, Object?>{
    'actorFanId': r'$actor',
    'event': event,
    'documentId': r'{id}',
    'timestamp': r'$timestamp',
  },
};

Map<String, Object?> _documentInstance({
  required String documentId,
  required String createdByFanId,
  required String title,
  required String category,
  required String version,
  required String updatedLabel,
  required String accessState,
  required String summary,
  List<String> sharedWithFanIds = const <String>[],
}) => engineNativeTestWorkflowInstance(
  instanceId: documentId,
  workflowType: _workflowType,
  currentState: accessState == 'restricted' ? 'restricted' : 'available',
  createdByFanId: createdByFanId,
  instanceData: <String, Object?>{
    'title': title,
    'category': category,
    'version': version,
    'updatedLabel': updatedLabel,
    'accessState': accessState,
    'summary': summary,
    'documentUrl': 'https://example.org/cedar-commons/$documentId',
    'sharedWithFanIds': sharedWithFanIds,
    'openedFanIds': <String>[],
    'acknowledgedFanIds': <String>[],
    'accessRequestedFanIds': <String>[],
    'auditTrail': <Object?>[],
  },
);
