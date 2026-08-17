import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

final class _TokenLoomAuthSession extends LoomAuthSession {
  _TokenLoomAuthSession(this.token)
    : super(
        tokenEndpoint: Uri.parse(
          'https://identity.test/realms/loom/protocol/openid-connect/token',
        ),
        clientId: 'test-client',
        secureStorage: _MemorySecureStorage(),
      );

  final String token;

  @override
  Future<String> currentAccessToken() async => token;
}

void main() {
  tearDown(() {
    resetLoomAuthSessionForTesting();
    resetEngineNativeCommunityEngineFactoryForTesting();
  });

  test('session seam defaults to null and reset restores that default', () {
    expect(loomAuthSession, isNull);

    final fake = _TokenLoomAuthSession('seam-token');
    overrideLoomAuthSessionForTesting(fake);
    expect(loomAuthSession, same(fake));

    resetLoomAuthSessionForTesting();
    expect(loomAuthSession, isNull);
  });

  test(
    'remote factory exposes the session access-token provider tear-off',
    () async {
      const expectedToken = 'known-remote-bearer-token';
      final session = _TokenLoomAuthSession(expectedToken);
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      final database = WorkflowDatabase.memory();
      addTearDown(database.close);
      addTearDown(httpClient.close);

      final factory = createRemoteEngineNativeCommunityEngineFactory(
        session: session,
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        httpClient: httpClient,
      );
      final engine = factory(
        database: database,
        extensionId: 'remote-factory-test-community',
      );

      expect(engine, isA<RemoteWorkflowEngineApi>());
      final remoteEngine = engine as RemoteWorkflowEngineApi;
      expect(await remoteEngine.bearerTokenProvider(), expectedToken);
    },
  );

  test(
    'real remote engine passes through the store Local-only gates',
    () async {
      const extensionId = 'real-remote-store-gating-test';
      final session = _TokenLoomAuthSession('store-token');
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      addTearDown(httpClient.close);
      overrideEngineNativeCommunityEngineFactoryForTesting(
        createRemoteEngineNativeCommunityEngineFactory(
          session: session,
          workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
          httpClient: httpClient,
        ),
      );

      experienceForExtensionId(
        extensionId,
        experienceConfiguration: const <String, Object?>{
          'experienceSchemaVersion': 2,
          'workflowGrammarVersion': 1,
          'workflowDefinitions': <String, Object?>{
            'remote-workflow': <String, Object?>{
              'initialState': 'open',
              'states': <String, Object?>{
                'open': <String, Object?>{'label': 'Open'},
              },
              'transitions': <Object?>[],
            },
          },
          'workflowInstances': <Object?>[
            <String, Object?>{
              'instanceId': 'remote-seed',
              'workflowType': 'remote-workflow',
              'currentState': 'open',
              'instanceData': <String, Object?>{},
              'createdByPersonaId': 'member',
            },
          ],
        },
      );
      configureEngineAuthorizationForExtensionId(
        extensionId: extensionId,
        appShellConfiguration: const <String, Object?>{},
        activeMembershipLookup: (_) async => true,
      );

      final engine = await workflowEngineForExtensionId(extensionId);

      expect(engine, isA<RemoteWorkflowEngineApi>());
      final remoteEngine = engine as RemoteWorkflowEngineApi;
      expect(await remoteEngine.bearerTokenProvider(), 'store-token');
    },
  );
}
