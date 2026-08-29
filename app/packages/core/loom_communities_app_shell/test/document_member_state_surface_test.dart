import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _TokenSession extends LoomAuthSession {
  _TokenSession()
    : super(
        tokenEndpoint: Uri.parse('https://identity.test/token'),
        clientId: 'test-client',
        secureStorage: _MemoryStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'test-access-token';
}

final class _RemoteDocumentEngine extends RemoteWorkflowEngineApi {
  _RemoteDocumentEngine(this.transitions)
    : super(
        baseUri: Uri.parse('https://workflow.test/'),
        communityId: 'community-test',
        bearerTokenProvider: () async => 'test-access-token',
        httpClient: MockClient(
          (_) async => throw StateError('The test engine overrides requests.'),
        ),
      );

  final List<LoomWorkflowTransition> transitions;
  final List<String> appliedTransitionIds = <String>[];

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) async => transitions;

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
  }) async {
    appliedTransitionIds.add(transitionId);
    return const WorkflowTransitionResult(
      newState: 'active',
      newInstanceData: <String, dynamic>{
        'title': 'Community policy',
        'documentUrl': '/v1/communities/community-test/documents/doc-1/content',
      },
    );
  }
}

/// A minimal remote Document Library service whose state is actor-owned.
final class _DocumentStateService {
  late final http.Client client = MockClient(_handle);

  int version = 1;
  bool read = false;
  bool saved = false;
  int? acknowledgedVersion;
  bool failMemberState = false;
  var documentCount = 1;
  final List<Map<String, Object?>> memberStateWrites = <Map<String, Object?>>[];
  var revisionRequests = 0;

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'GET' &&
        path.endsWith('/instances/doc-1/documents')) {
      return _json(<String, Object?>{
        'documents': <Object?>[
          for (var index = 1; index <= documentCount; index++)
            <String, Object?>{..._document(), 'documentId': 'doc-$index'},
        ],
      });
    }
    if (request.method == 'POST' &&
        path.endsWith('/documents/doc-1/revisions')) {
      revisionRequests += 1;
      version += 1;
      return _json(_document(), statusCode: 201);
    }
    if (path.endsWith('/documents/doc-1/state')) {
      if (failMemberState) return http.Response('service unavailable', 503);
      if (request.method == 'GET') return _json(_state());
      if (request.method == 'PUT') {
        final update = Map<String, Object?>.from(
          jsonDecode(request.body) as Map,
        );
        memberStateWrites.add(update);
        if (update['read'] is bool) read = update['read']! as bool;
        if (update['saved'] is bool) saved = update['saved']! as bool;
        if (update['acknowledged'] == true) acknowledgedVersion = version;
        return _json(_state());
      }
    }
    if (request.method == 'GET' &&
        path.endsWith('/documents/doc-1/acknowledgements')) {
      return _json(<String, Object?>{
        'documentId': 'doc-1',
        'currentVersion': version,
        'acknowledgements': acknowledgedVersion == null
            ? <Object?>[]
            : <Object?>[
                <String, Object?>{
                  'fanId': 'member',
                  'version': acknowledgedVersion,
                  'acknowledgedAt': '2026-08-29T00:00:00.000Z',
                  'stale': acknowledgedVersion! < version,
                },
              ],
      });
    }
    return http.Response('unexpected request: ${request.method} $path', 500);
  }

  Map<String, Object?> _document() => <String, Object?>{
    'documentId': 'doc-1',
    'communityId': 'community-test',
    'instanceId': 'doc-1',
    'workflowType': 'document-library-test',
    'fieldName': 'documentUrl',
    'title': 'Community policy',
    'filename': 'policy.pdf',
    'contentType': 'application/pdf',
    'byteSize': 11,
    'ownerFanId': 'board',
    'uploadedAt': '2026-08-29T00:00:00.000Z',
    'version': version,
    'revisedAt': '2026-08-29T00:00:00.000Z',
    'contentUrl': '/v1/communities/community-test/documents/doc-1/content',
  };

  Map<String, Object?> _state() => <String, Object?>{
    'documentId': 'doc-1',
    'fanId': 'member',
    'currentVersion': version,
    'read': read,
    'saved': saved,
    'acknowledged': acknowledgedVersion != null,
    if (acknowledgedVersion != null) ...<String, Object?>{
      'acknowledgedAt': '2026-08-29T00:00:00.000Z',
      'acknowledgedVersion': acknowledgedVersion,
    },
  };

  void close() => client.close();
}

http.Response _json(Object body, {int statusCode = 200}) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: const {'content-type': 'application/json'},
);

LoomDocumentClient _client(http.Client httpClient) => LoomDocumentClient(
  workflowServiceBaseUri: Uri.parse('https://workflow.test/service/'),
  session: _TokenSession(),
  httpClient: httpClient,
);

LoomWorkflowStateMachine _documentMachine({
  List<Map<String, Object?>> transitions = const <Map<String, Object?>>[],
  bool storedDocument = false,
}) => LoomWorkflowStateMachine.fromJson(<String, Object?>{
  'initialState': 'active',
  'states': <String, Object?>{
    'active': <String, Object?>{'label': 'Active'},
  },
  'transitions': transitions,
  'instanceDataSchema': <String, Object?>{
    'title': <String, Object?>{
      'type': 'text',
      'writableBy': 'formEntry',
      'labelTemplate': '{value}',
    },
    storedDocument ? 'documentUrl' : 'materialUrl': <String, Object?>{
      'type': 'url',
      'writableBy': storedDocument ? 'platform' : 'formEntry',
      'labelTemplate': 'Open {value}',
    },
  },
}, 'document-library-test');

Map<String, Object?> _transition({
  required String id,
  required String action,
  String? label,
}) => <String, Object?>{
  'id': id,
  'action': action,
  'label': label ?? action,
  'icon': 'check_circle_outline',
  'tone': 'secondary',
  'from': <String>['active'],
  'to': null,
};

EngineNativeResolvedBinding _binding(
  LoomWorkflowStateMachine machine, {
  Map<String, dynamic> instanceData = const <String, dynamic>{
    'title': 'Community policy',
    'documentUrl': '/v1/communities/community-test/documents/doc-1/content',
  },
}) => EngineNativeResolvedBinding(
  instance: WorkflowInstance(
    instanceId: 'doc-1',
    workflowType: machine.workflowType,
    currentState: 'active',
    instanceData: instanceData,
    createdByFanId: 'board',
  ),
  machine: machine,
  binding: const RenderBinding(
    states: <String>['active'],
    role: 'member',
    tabId: 'documents',
    cardSurfaceFamily: 'documentLibrary',
    bindingKind: 'primary',
  ),
  definitionBindingIndex: 0,
);

Widget _card({
  required LoomWorkflowStateMachine machine,
  required _RemoteDocumentEngine engine,
  ValueChanged<WorkflowInstance>? onInstanceChanged,
}) => MaterialApp(
  home: Scaffold(
    body: DocumentLibraryArchetypeCard(
      resolved: _binding(machine),
      engine: engine,
      fanId: 'member',
      accent: Colors.blue,
      displayContext: 'detail',
      onInstanceChanged: onInstanceChanged ?? (_) {},
    ),
  ),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required _DocumentStateService service,
  required LoomWorkflowStateMachine machine,
  ValueChanged<WorkflowInstance>? onInstanceChanged,
}) async {
  overrideLoomDocumentClientForTesting(_client(service.client));
  await tester.pumpWidget(
    _card(
      machine: machine,
      engine: _RemoteDocumentEngine(machine.transitions),
      onInstanceChanged: onInstanceChanged,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    resetLoomDocumentPickerForTesting();
    resetLoomDocumentClientForTesting();
  });
  tearDown(() {
    resetLoomDocumentPickerForTesting();
    resetLoomDocumentClientForTesting();
  });

  test(
    'document client sends UUID correlation ids on all four member-state operations',
    () async {
      final requests = <http.Request>[];
      final httpClient = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return _json(
            (_DocumentStateService()..version = 2)._document(),
            statusCode: 201,
          );
        }
        if (request.method == 'PUT') {
          expect(jsonDecode(request.body), <String, Object?>{'read': true});
          return _json(<String, Object?>{
            'documentId': 'doc-1',
            'fanId': 'member',
            'currentVersion': 2,
            'read': true,
            'acknowledged': false,
            'saved': false,
          });
        }
        if (request.url.path.endsWith('/acknowledgements')) {
          expect(request.url.queryParameters['currentVersionOnly'], 'true');
          return _json(<String, Object?>{
            'documentId': 'doc-1',
            'currentVersion': 2,
            'acknowledgements': <Object?>[
              <String, Object?>{
                'fanId': 'member',
                'version': 1,
                'acknowledgedAt': '2026-08-29T00:00:00.000Z',
                'stale': true,
              },
            ],
          });
        }
        return _json(<String, Object?>{
          'documentId': 'doc-1',
          'fanId': 'member',
          'currentVersion': 2,
          'read': false,
          'acknowledged': false,
          'saved': false,
        });
      });
      final client = _client(httpClient);
      addTearDown(client.close);

      final revision = await client.addRevision(
        communityId: 'community-test',
        documentId: 'doc-1',
        filename: 'policy-v2.pdf',
        bytes: <int>[1, 2, 3],
        changeNote: 'Clarified the policy.',
        contentType: 'application/pdf',
      );
      final state = await client.getDocumentMemberState(
        communityId: 'community-test',
        documentId: 'doc-1',
      );
      final updated = await client.setDocumentMemberState(
        communityId: 'community-test',
        documentId: 'doc-1',
        read: true,
      );
      final acknowledgements = await client.listDocumentAcknowledgements(
        communityId: 'community-test',
        documentId: 'doc-1',
        currentVersionOnly: true,
      );

      expect(revision.version, 2);
      expect(state.currentVersion, 2);
      expect(updated.read, isTrue);
      expect(acknowledgements.acknowledgements.single.stale, isTrue);
      expect(requests, hasLength(4));
      for (final request in requests) {
        expect(request.headers['authorization'], 'Bearer test-access-token');
        expect(
          request.headers['x-loom-correlation-id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      }
      expect(requests.first.headers['idempotency-key'], isNotNull);
      expect(requests[2].headers, isNot(contains('idempotency-key')));
    },
  );

  testWidgets(
    'each declared member action records its state by action, never transition id',
    (tester) async {
      final service = _DocumentStateService();
      addTearDown(service.close);
      final machine = _documentMachine(
        transitions: <Map<String, Object?>>[
          _transition(id: 'record-material-open', action: 'open'),
          _transition(id: 'read-with-a-different-id', action: 'mark_read'),
          _transition(id: 'mark-this-unread', action: 'mark_unread'),
          _transition(id: 'confirm-receipt', action: 'acknowledge'),
          _transition(id: 'keep-it-handy', action: 'save'),
        ],
      );
      WorkflowInstance? changed;
      await _pumpCard(
        tester,
        service: service,
        machine: machine,
        onInstanceChanged: (instance) => changed = instance,
      );

      for (final id in <String>[
        'record-material-open',
        'read-with-a-different-id',
        'mark-this-unread',
        'confirm-receipt',
        'keep-it-handy',
      ]) {
        await tester.tap(find.byKey(ValueKey('document-library-action-$id')));
        await tester.pumpAndSettle();
      }

      expect(service.memberStateWrites, <Map<String, Object?>>[
        <String, Object?>{'read': true},
        <String, Object?>{'read': true},
        <String, Object?>{'read': false},
        <String, Object?>{'acknowledged': true},
        <String, Object?>{'saved': true},
      ]);
      expect(service.read, isFalse);
      expect(service.saved, isTrue);
      expect(service.acknowledgedVersion, 1);
      expect(changed, isNotNull);
      for (final key in <String>[
        'read',
        'saved',
        'acknowledged',
        'acknowledgedVersion',
      ]) {
        expect(changed!.instanceData, isNot(contains(key)));
      }
    },
  );

  testWidgets(
    'acknowledge-material and acknowledge-document both record acknowledgement',
    (tester) async {
      for (final id in <String>[
        'acknowledge-material',
        'acknowledge-document',
      ]) {
        final service = _DocumentStateService();
        addTearDown(service.close);
        final machine = _documentMachine(
          transitions: <Map<String, Object?>>[
            _transition(id: id, action: 'acknowledge'),
          ],
        );
        await _pumpCard(tester, service: service, machine: machine);
        await tester.tap(find.byKey(ValueKey('document-library-action-$id')));
        await tester.pumpAndSettle();

        expect(service.memberStateWrites, <Map<String, Object?>>[
          <String, Object?>{'acknowledged': true},
        ]);
      }
    },
  );

  testWidgets(
    'an acknowledgement of version one is stale after a version-two revision',
    (tester) async {
      final service = _DocumentStateService()..acknowledgedVersion = 1;
      addTearDown(service.close);
      final machine = _documentMachine(
        transitions: <Map<String, Object?>>[
          _transition(id: 'replace-policy', action: 'upload', label: 'Upload'),
        ],
        storedDocument: true,
      );
      await _pumpCard(tester, service: service, machine: machine);
      expect(find.text('Document version: 1'), findsOneWidget);
      expect(
        find.text('Acknowledgement: current (version 1).'),
        findsOneWidget,
      );
      expect(find.text('Add revision'), findsOneWidget);

      overrideLoomDocumentPickerForTesting(
        () async => LoomPickedDocument(
          filename: 'policy-v2.pdf',
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          contentType: 'application/pdf',
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('document-library-action-replace-policy')),
      );
      await tester.pumpAndSettle();

      expect(service.revisionRequests, 1);
      expect(find.text('Document version: 2'), findsOneWidget);
      expect(
        find.text('Acknowledgement: stale (version 1; current version 2).'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a member-state service error is unavailable, not not acknowledged',
    (tester) async {
      final service = _DocumentStateService()..failMemberState = true;
      addTearDown(service.close);
      final machine = _documentMachine(
        transitions: <Map<String, Object?>>[
          _transition(id: 'acknowledge-document', action: 'acknowledge'),
        ],
      );
      await _pumpCard(tester, service: service, machine: machine);

      expect(find.text('Member state unavailable.'), findsOneWidget);
      expect(find.text('Acknowledgement: not acknowledged.'), findsNothing);
    },
  );

  testWidgets(
    'several service documents are reported as ambiguous rather than choosing one',
    (tester) async {
      final service = _DocumentStateService()..documentCount = 2;
      addTearDown(service.close);
      final machine = _documentMachine(
        transitions: <Map<String, Object?>>[
          _transition(id: 'acknowledge-material', action: 'acknowledge'),
        ],
      );
      await _pumpCard(tester, service: service, machine: machine);

      expect(find.text('Member state unavailable.'), findsOneWidget);
      expect(find.textContaining('multiple stored documents'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('document-library-action-acknowledge-material'),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.memberStateWrites, isEmpty);
    },
  );

  testWidgets(
    'a community without mark_read has no mark-read affordance and does not error',
    (tester) async {
      final service = _DocumentStateService();
      addTearDown(service.close);
      final machine = _documentMachine(
        transitions: <Map<String, Object?>>[
          _transition(id: 'record-open', action: 'open'),
        ],
      );
      await _pumpCard(tester, service: service, machine: machine);

      expect(
        find.byKey(const ValueKey('document-library-action-mark-read')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('document-library-error-doc-1')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
