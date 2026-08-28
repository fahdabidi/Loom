import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
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

final class _RemoteExportEngine extends RemoteWorkflowEngineApi {
  _RemoteExportEngine({required this.transitions, required this.nextData})
    : super(
        baseUri: Uri.parse('https://workflow.test/'),
        communityId: 'community-test',
        bearerTokenProvider: () async => 'test-access-token',
        httpClient: MockClient(
          (_) async => throw StateError('The test engine overrides requests.'),
        ),
      );

  final List<LoomWorkflowTransition> transitions;
  final Map<String, dynamic> nextData;

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
  }) async => WorkflowTransitionResult(
    newState: 'generated',
    newInstanceData: nextData,
  );
}

final class _StaticTransitionsEngine implements WorkflowEngineApi {
  _StaticTransitionsEngine(this.transitions);

  final List<LoomWorkflowTransition> transitions;

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) async => transitions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> _bundleJson() => <String, Object?>{
  'exportId': 'export_123',
  'communityId': 'community-test',
  'instanceId': 'export-instance',
  'checksum': 'a' * 64,
  'checksumAlgorithm': 'sha-256',
  'byteSize': 3,
  'recordCount': 2,
  'redacted': true,
  'generatedAt': '2026-08-27T00:00:00.000Z',
};

LoomWorkflowStateMachine _checksumMachine({
  required String state,
  required List<Map<String, Object?>> transitions,
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': state,
  'states': <String, Object?>{
    state: <String, Object?>{'label': state},
    'generated': <String, Object?>{'label': 'Generated'},
  },
  'transitions': transitions,
  'instanceDataSchema': <String, Object?>{
    'checksum': <String, Object?>{
      'type': 'text?',
      'writableBy': 'platform',
      'labelTemplate': 'Checksum: {value}',
      'hideWhenEmpty': true,
      'displayContexts': <String>['tile', 'detail'],
    },
  },
}, 'export-workflow');

EngineNativeResolvedBinding _binding(
  LoomWorkflowStateMachine machine,
  WorkflowInstance instance,
) => EngineNativeResolvedBinding(
  instance: instance,
  machine: machine,
  binding: RenderBinding(
    states: machine.states.keys.toList(growable: false),
    role: 'member',
    tabId: 'exports',
    cardSurfaceFamily: 'exportWizard',
    bindingKind: 'primary',
  ),
  definitionBindingIndex: 0,
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowStateMachine _machineFromAsset(
  String assetName,
  String workflowType,
) {
  final package =
      jsonDecode(
            stripJsonComments(File('assets/$assetName').readAsStringSync()),
          )
          as Map<String, dynamic>;
  final definitions = package['experience'] as Map<String, dynamic>;
  final workflows = definitions['workflowDefinitions'] as Map<String, dynamic>;
  return LoomWorkflowStateMachine.fromJson(
    workflows[workflowType] as Map<String, dynamic>,
    workflowType,
  );
}

void main() {
  tearDown(resetLoomExportBundleClientForTesting);

  test(
    'export client sends correlation id on every call and idempotency on generate',
    () async {
      final requests = <http.Request>[];
      final client = LoomExportBundleClient(
        workflowServiceBaseUri: Uri.parse('https://workflow.test/service/'),
        session: _TokenSession(),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/content')) {
            return http.Response.bytes(const [1, 2, 3], 200);
          }
          if (request.url.path.endsWith('/verification')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'exportId': 'export_123',
                'verified': true,
                'recordedChecksum': 'a' * 64,
                'observedChecksum': 'a' * 64,
                'checksumAlgorithm': 'sha-256',
                'recordedByteSize': 3,
                'observedByteSize': 3,
                'verifiedAt': '2026-08-27T00:00:00.000Z',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode(_bundleJson()),
            request.method == 'POST' ? 201 : 200,
          );
        }),
      );
      addTearDown(client.close);

      await client.generate(
        communityId: 'community-test',
        instanceId: 'export-instance',
        redactProtectedData: true,
      );
      await client.get(communityId: 'community-test', exportId: 'export_123');
      expect(
        await client.download(
          communityId: 'community-test',
          exportId: 'export_123',
        ),
        const <int>[1, 2, 3],
      );
      await client.verify(
        communityId: 'community-test',
        exportId: 'export_123',
      );

      expect(requests, hasLength(4));
      for (final request in requests) {
        expect(
          request.headers['x-loom-correlation-id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(request.headers['authorization'], 'Bearer test-access-token');
      }
      expect(
        requests
            .singleWhere(
              (request) =>
                  request.method == 'POST' &&
                  request.url.path.endsWith('export-bundle'),
            )
            .headers['idempotency-key'],
        isNotEmpty,
      );
      expect(
        requests.where(
          (request) => request.headers.containsKey('idempotency-key'),
        ),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'generation shows the service checksum only after the remote service returns it',
    (tester) async {
      final service = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/v1/communities/community-test/instances/export-instance/export-bundle',
        );
        return http.Response(
          jsonEncode(_bundleJson()),
          request.method == 'POST' ? 201 : 200,
        );
      });
      addTearDown(service.close);
      overrideLoomExportBundleClientForTesting(
        LoomExportBundleClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service,
        ),
      );
      final machine = _checksumMachine(
        state: 'ready',
        transitions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'generate-package',
            'action': 'run',
            'label': 'Generate package',
            'from': <String>['ready'],
            'to': 'generated',
          },
        ],
      );
      final instance = WorkflowInstance(
        instanceId: 'export-instance',
        workflowType: machine.workflowType,
        currentState: 'ready',
        instanceData: const <String, dynamic>{},
        createdByFanId: 'member',
      );
      final engine = _RemoteExportEngine(
        transitions: machine.transitions,
        nextData: <String, dynamic>{'checksum': 'a' * 64},
      );
      await tester.pumpWidget(
        _host(
          ExportWizardArchetypeCard(
            resolved: _binding(machine, instance),
            engine: engine,
            fanId: 'member',
            accent: Colors.blue,
            onInstanceChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Checksum:'), findsNothing);
      await tester.tap(
        find.byKey(
          const ValueKey(
            'export-wizard-export-instance-action-generate-package',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('export-wizard-error-export-instance')),
        findsNothing,
      );
      expect(find.text('Checksum: ${'a' * 64}'), findsOneWidget);
    },
  );

  testWidgets('verification pass and mismatch render differently', (
    tester,
  ) async {
    var generated = false;
    var verificationAttempt = 0;
    final service = MockClient((request) async {
      if (request.url.path.endsWith('/verification')) {
        final verified = verificationAttempt++ == 0;
        return http.Response(
          jsonEncode(<String, Object?>{
            'exportId': 'export_123',
            'verified': verified,
            'recordedChecksum': 'a' * 64,
            'observedChecksum': verified ? 'a' * 64 : 'b' * 64,
            'checksumAlgorithm': 'sha-256',
            'recordedByteSize': 3,
            'observedByteSize': verified ? 3 : 4,
            'verifiedAt': '2026-08-27T00:00:00.000Z',
          }),
          200,
        );
      }
      generated = true;
      return http.Response(jsonEncode(_bundleJson()), 201);
    });
    addTearDown(service.close);
    overrideLoomExportBundleClientForTesting(
      LoomExportBundleClient(
        workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
        session: _TokenSession(),
        httpClient: service,
      ),
    );
    final machine = _checksumMachine(
      state: 'ready',
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'generate-package',
          'action': 'run',
          'label': 'Generate package',
          'from': <String>['ready'],
          'to': 'generated',
        },
      ],
    );
    final engine = _RemoteExportEngine(
      transitions: machine.transitions,
      nextData: <String, dynamic>{'checksum': 'a' * 64},
    );
    await tester.pumpWidget(
      _host(
        ExportWizardArchetypeCard(
          resolved: _binding(
            machine,
            WorkflowInstance(
              instanceId: 'export-instance',
              workflowType: machine.workflowType,
              currentState: 'ready',
              instanceData: const <String, dynamic>{},
              createdByFanId: 'member',
            ),
          ),
          engine: engine,
          fanId: 'member',
          accent: Colors.blue,
          onInstanceChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('export-wizard-export-instance-action-generate-package'),
      ),
    );
    await tester.pumpAndSettle();
    expect(generated, isTrue);
    await tester.tap(
      find.byKey(const ValueKey('export-wizard-verify-export-instance')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Checksum verified.'), findsOneWidget);
    expect(find.text('Checksum mismatch.'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('export-wizard-verify-export-instance')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Checksum mismatch.'), findsOneWidget);
    expect(find.text('Checksum verified.'), findsNothing);
  });

  testWidgets(
    'Cedar and Chess export affordances retain their declared action ids',
    (tester) async {
      final cedar = _machineFromAsset(
        'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
        'hoa-export-evidence',
      );
      final chess = _machineFromAsset(
        'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
        'chess-export-package',
      );
      final cedarTransition = cedar
          .transitionsFrom('ready')
          .singleWhere((transition) => transition.action == 'download');
      final chessTransition = chess
          .transitionsFrom('generated')
          .singleWhere((transition) => transition.action == 'download');
      expect(cedarTransition.id, 'request-export-download');
      expect(chessTransition.id, 'download-export');

      Future<void> expectAction(
        LoomWorkflowStateMachine machine,
        String state,
        LoomWorkflowTransition transition,
        String instanceId,
      ) async {
        await tester.pumpWidget(
          _host(
            ExportWizardArchetypeCard(
              resolved: _binding(
                machine,
                WorkflowInstance(
                  instanceId: instanceId,
                  workflowType: machine.workflowType,
                  currentState: state,
                  instanceData: const <String, dynamic>{},
                  createdByFanId: 'member',
                ),
              ),
              engine: _StaticTransitionsEngine(<LoomWorkflowTransition>[
                transition,
              ]),
              fanId: 'member',
              accent: Colors.blue,
              onInstanceChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey('export-wizard-$instanceId-action-${transition.id}'),
          ),
          findsOneWidget,
        );
        expect(find.text(transition.label), findsOneWidget);
      }

      await expectAction(cedar, 'ready', cedarTransition, 'cedar-export');
      await expectAction(chess, 'generated', chessTransition, 'chess-export');
    },
  );

  testWidgets(
    'an export service error says unavailable and never renders a checksum value',
    (tester) async {
      final service = MockClient((_) async => http.Response('down', 503));
      addTearDown(service.close);
      overrideLoomExportBundleClientForTesting(
        LoomExportBundleClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service,
        ),
      );
      final machine = _checksumMachine(
        state: 'ready',
        transitions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'generate-package',
            'action': 'run',
            'label': 'Generate package',
            'from': <String>['ready'],
            'to': 'generated',
          },
        ],
      );
      await tester.pumpWidget(
        _host(
          ExportWizardArchetypeCard(
            resolved: _binding(
              machine,
              WorkflowInstance(
                instanceId: 'export-instance',
                workflowType: machine.workflowType,
                currentState: 'ready',
                instanceData: const <String, dynamic>{},
                createdByFanId: 'member',
              ),
            ),
            engine: _RemoteExportEngine(
              transitions: machine.transitions,
              nextData: const <String, dynamic>{},
            ),
            fanId: 'member',
            accent: Colors.blue,
            onInstanceChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'export-wizard-export-instance-action-generate-package',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Checksum is unavailable'), findsOneWidget);
      expect(find.textContaining('Checksum: '), findsNothing);
    },
  );
}
