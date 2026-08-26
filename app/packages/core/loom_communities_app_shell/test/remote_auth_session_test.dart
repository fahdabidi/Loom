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

final class _FakeWorkflowEngineApi implements WorkflowEngineApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _installEngineNativeTestExperience(String extensionId) {
  experienceForExtensionId(
    extensionId,
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: const <String, Object?>{
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
          'createdByFanId': 'member',
        },
      ],
    },
  );
}

void main() {
  tearDown(() {
    resetLoomAuthSessionForTesting();
    resetEngineNativeCommunityFactoryRegistrationsForTesting();
    resetEngineNativeCommunityEngineFactoryForTesting();
    resetProductionEngineNativeCommunityEngineFactoryForTesting();
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
    'configured production factory returns the configured remote engine',
    () async {
      const expectedToken = 'known-remote-bearer-token';
      final session = _TokenLoomAuthSession(expectedToken);
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      addTearDown(httpClient.close);

      configureEngineNativeCommunityEngineFactoryForProduction(
        createRemoteEngineNativeCommunityEngineFactoryForConfiguration(
          configuration: LoomRemoteServiceConfiguration(
            session: session,
            workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
          ),
          httpClient: httpClient,
        ),
      );
      const extensionId = 'remote-factory-test-community';
      _installEngineNativeTestExperience(extensionId);
      final engine = await workflowEngineForExtensionId(extensionId);

      expect(engine, isA<RemoteWorkflowEngineApi>());
      final remoteEngine = engine as RemoteWorkflowEngineApi;
      expect(remoteEngine.communityId, extensionId);
      expect(remoteEngine.baseUri, Uri.parse('https://workflow.test/api/'));
      expect(await remoteEngine.bearerTokenProvider(), expectedToken);
    },
  );

  test('production factory defaults to the local engine', () async {
    const firstExtensionId = 'production-default-local-first';
    const secondExtensionId = 'production-default-local-second';
    _installEngineNativeTestExperience(firstExtensionId);
    _installEngineNativeTestExperience(secondExtensionId);

    final engines = await Future.wait(<Future<WorkflowEngineApi>>[
      workflowEngineForExtensionId(firstExtensionId),
      workflowEngineForExtensionId(secondExtensionId),
    ]);

    expect(engines, everyElement(isA<LocalWorkflowEngineApi>()));
  });

  test('resetting all registrations restores local routing for all', () async {
    const firstExtensionId = 'per-community-reset-first';
    const secondExtensionId = 'per-community-reset-second';
    final session = _TokenLoomAuthSession('reset-token');
    final httpClient = MockClient(
      (_) async => throw StateError('No HTTP request expected in this test.'),
    );
    addTearDown(httpClient.close);

    for (final extensionId in <String>[firstExtensionId, secondExtensionId]) {
      enableRemoteEngineForCommunity(
        extensionId: extensionId,
        session: session,
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        httpClient: httpClient,
      );
    }
    resetEngineNativeCommunityFactoryRegistrationsForTesting();
    _installEngineNativeTestExperience(firstExtensionId);
    _installEngineNativeTestExperience(secondExtensionId);

    final engines = await Future.wait(<Future<WorkflowEngineApi>>[
      workflowEngineForExtensionId(firstExtensionId),
      workflowEngineForExtensionId(secondExtensionId),
    ]);

    expect(engines, everyElement(isA<LocalWorkflowEngineApi>()));
  });

  test(
    'testing override takes precedence temporarily over production selection',
    () async {
      const overriddenExtensionId = 'production-seam-testing-override';
      const productionExtensionId = 'production-seam-after-test-override';
      final fake = _FakeWorkflowEngineApi();
      final session = _TokenLoomAuthSession('override-token');
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      addTearDown(httpClient.close);

      configureEngineNativeCommunityEngineFactoryForProduction(
        createRemoteEngineNativeCommunityEngineFactoryForConfiguration(
          configuration: LoomRemoteServiceConfiguration(
            session: session,
            workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
          ),
          httpClient: httpClient,
        ),
      );
      overrideEngineNativeCommunityEngineFactoryForTesting(({
        required WorkflowDatabase database,
        required String extensionId,
      }) {
        expect(extensionId, overriddenExtensionId);
        return fake;
      });
      _installEngineNativeTestExperience(overriddenExtensionId);

      expect(
        await workflowEngineForExtensionId(overriddenExtensionId),
        same(fake),
      );

      resetEngineNativeCommunityEngineFactoryForTesting();
      _installEngineNativeTestExperience(productionExtensionId);
      expect(
        await workflowEngineForExtensionId(productionExtensionId),
        isA<RemoteWorkflowEngineApi>(),
      );
    },
  );

  test(
    'one registered community is remote while another remains local',
    () async {
      const remoteExtensionId = 'per-community-headline-remote';
      const localExtensionId = 'per-community-headline-local';
      final session = _TokenLoomAuthSession('headline-token');
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      addTearDown(httpClient.close);

      enableRemoteEngineForCommunity(
        extensionId: remoteExtensionId,
        session: session,
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        httpClient: httpClient,
      );
      _installEngineNativeTestExperience(remoteExtensionId);
      _installEngineNativeTestExperience(localExtensionId);

      final engines = await Future.wait(<Future<WorkflowEngineApi>>[
        workflowEngineForExtensionId(remoteExtensionId),
        workflowEngineForExtensionId(localExtensionId),
      ]);

      expect(engines[0], isA<RemoteWorkflowEngineApi>());
      expect(engines[1], isA<LocalWorkflowEngineApi>());
    },
  );

  test('disable removes remote routing before store installation', () async {
    const extensionId = 'per-community-disable-before-install';
    final session = _TokenLoomAuthSession('disable-token');
    final httpClient = MockClient(
      (_) async => throw StateError('No HTTP request expected in this test.'),
    );
    addTearDown(httpClient.close);

    enableRemoteEngineForCommunity(
      extensionId: extensionId,
      session: session,
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      httpClient: httpClient,
    );
    disableRemoteEngineForCommunity(extensionId: extensionId);
    _installEngineNativeTestExperience(extensionId);

    expect(
      await workflowEngineForExtensionId(extensionId),
      isA<LocalWorkflowEngineApi>(),
    );
  });

  test('enablement after store installation fails loudly', () async {
    const extensionId = 'per-community-too-late-enable';
    final session = _TokenLoomAuthSession('too-late-token');
    final httpClient = MockClient(
      (_) async => throw StateError('No HTTP request expected in this test.'),
    );
    addTearDown(httpClient.close);
    _installEngineNativeTestExperience(extensionId);
    final originalEngine = await workflowEngineForExtensionId(extensionId);

    expect(
      () => enableRemoteEngineForCommunity(
        extensionId: extensionId,
        session: session,
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        httpClient: httpClient,
      ),
      throwsA(
        isA<StateError>()
            .having((error) => error.message, 'message', contains(extensionId))
            .having(
              (error) => error.message,
              'message',
              contains('before installing'),
            ),
      ),
    );
    expect(
      await workflowEngineForExtensionId(extensionId),
      same(originalEngine),
    );
    expect(originalEngine, isA<LocalWorkflowEngineApi>());
  });

  test(
    'per-community remote engine passes through the store Local-only gates',
    () async {
      const extensionId = 'real-remote-store-gating-test';
      final session = _TokenLoomAuthSession('store-token');
      final httpClient = MockClient(
        (_) async => throw StateError('No HTTP request expected in this test.'),
      );
      addTearDown(httpClient.close);
      enableRemoteEngineForCommunity(
        extensionId: extensionId,
        session: session,
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        httpClient: httpClient,
      );

      _installEngineNativeTestExperience(extensionId);
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
