import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _communityId = 'community_cedar_commons_hoa';
const _extensionId = 'ext_cedar_commons_hoa';

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _TokenSession extends LoomAuthSession {
  _TokenSession(this.token)
    : super(
        tokenEndpoint: Uri.parse(
          'https://identity.test/realms/loom/protocol/openid-connect/token',
        ),
        clientId: 'test-client',
        secureStorage: _MemoryStorage(),
      );

  final String token;

  @override
  Future<String> currentAccessToken() async => token;
}

LoomRemoteServiceConfiguration _configuration(_TokenSession session) =>
    LoomRemoteServiceConfiguration(
      session: session,
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
      fanPassportBaseUri: Uri.parse('https://fan-passport.test/api/'),
      communityGroupIds: const {_communityId: 'cedar-group'},
    );

void main() {
  tearDown(() {
    resetLoomAuthSessionForTesting();
    resetLoomServiceBindingRegistryForTesting();
  });

  test(
    'remote auth resolution records the selected endpoint and remote mode',
    () {
      final session = _TokenSession('remote-token');
      overrideLoomRemoteServiceConfigurationForTesting(_configuration(session));

      final api = resolveLoomAuthApiForCommunity(
        communityId: _communityId,
        communityExtensionId: _extensionId,
        actorIdentityResolver: (_) => const [],
        experienceResolver: (_) => throw StateError('not used'),
      );

      expect(api, isA<RemoteLoomAuthApi>());
      final binding = loomServiceBindingRegistry.find(
        service: LoomServiceBindingNames.appAccess,
        scope: _extensionId,
      );
      expect(binding, isNotNull);
      expect(binding!.mode, LoomServiceBindingMode.remote);
      expect(binding.endpoint, Uri.parse('https://app-access.test/api/'));
      expect(
        binding.lastCallOutcome.kind,
        LoomServiceCallOutcomeKind.neverCalled,
      );
      expect(
        loomServiceBindingRegistry
            .find(
              service: LoomServiceBindingNames.fanPassport,
              scope: _extensionId,
            )!
            .endpoint,
        Uri.parse('https://fan-passport.test/api/'),
      );
    },
  );

  test('unconfigured auth resolution records local bindings explicitly', () {
    final api = resolveLoomAuthApiForCommunity(
      communityId: _communityId,
      communityExtensionId: _extensionId,
      actorIdentityResolver: (_) => const [],
      experienceResolver: (_) => throw StateError('not used'),
    );

    expect(api, isA<LocalAuthApi>());
    for (final service in <String>[
      LoomServiceBindingNames.appAccess,
      LoomServiceBindingNames.fanPassport,
    ]) {
      final binding = loomServiceBindingRegistry.find(
        service: service,
        scope: _extensionId,
      );
      expect(binding, isNotNull);
      expect(binding!.mode, LoomServiceBindingMode.local);
      expect(binding.endpoint, isNull);
      expect(
        binding.lastCallOutcome.kind,
        LoomServiceCallOutcomeKind.notApplicable,
      );
    }
  });

  test(
    'a failing remote call records failure without changing remote mode',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'workflow_service_error', 'message': 'down'}),
          503,
        ),
      );
      addTearDown(client.close);
      loomServiceBindingRegistry.recordBinding(
        service: LoomServiceBindingNames.workflowEngine,
        mode: LoomServiceBindingMode.remote,
        endpoint: Uri.parse('https://workflow.test/api/'),
        scope: _extensionId,
      );
      final engine = RemoteWorkflowEngineApi(
        baseUri: Uri.parse('https://workflow.test/api/'),
        communityId: _extensionId,
        bearerTokenProvider: () async => 'remote-token',
        httpClient: client,
        onCallOutcome:
            ({required bool success, int? statusCode, String? errorKind}) =>
                _recordWorkflowCall(
                  success: success,
                  statusCode: statusCode,
                  errorKind: errorKind,
                ),
      );

      await expectLater(
        engine.queryInstances(tabId: 'home', fanId: 'fan-alice'),
        throwsA(isA<RemoteWorkflowServiceError>()),
      );

      final binding = loomServiceBindingRegistry.find(
        service: LoomServiceBindingNames.workflowEngine,
        scope: _extensionId,
      )!;
      expect(binding.mode, LoomServiceBindingMode.remote);
      expect(binding.lastCallOutcome.kind, LoomServiceCallOutcomeKind.failure);
      expect(binding.lastCallOutcome.statusCode, 503);
    },
  );

  testWidgets(
    'warning badge is silent for healthy remote bindings and rows are complete',
    (tester) async {
      for (final service in LoomServiceBindingNames.healthChecked) {
        final scope = service == LoomServiceBindingNames.authTokenEndpoint
            ? LoomServiceBindingNames.processScope
            : _extensionId;
        loomServiceBindingRegistry.recordBinding(
          service: service,
          mode: LoomServiceBindingMode.remote,
          endpoint: Uri.parse('https://$service.test/'),
          scope: scope,
        );
      }
      loomServiceBindingRegistry.recordBinding(
        service: LoomServiceBindingNames.offlineReplica,
        mode: LoomServiceBindingMode.unconfigured,
        endpoint: null,
        scope: LoomServiceBindingNames.processScope,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  LoomServiceBindingWarningBadge(communityScope: _extensionId),
                  LoomServiceBindingDiagnosticsPanel(
                    communityScope: _extensionId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('service-binding-warning-badge')),
        findsNothing,
      );
      for (final service in LoomServiceBindingNames.all) {
        expect(
          find.byKey(ValueKey('service-binding-row-$service')),
          findsOneWidget,
        );
      }

      loomServiceBindingRegistry.recordCallFailure(
        service: LoomServiceBindingNames.workflowEngine,
        scope: _extensionId,
        statusCode: 503,
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('service-binding-warning-badge')),
        findsOneWidget,
      );
      expect(find.textContaining('BACKEND UNREACHABLE'), findsOneWidget);
    },
  );
}

void _recordWorkflowCall({
  required bool success,
  int? statusCode,
  String? errorKind,
}) {
  if (success) {
    loomServiceBindingRegistry.recordCallSuccess(
      service: LoomServiceBindingNames.workflowEngine,
      scope: _extensionId,
      statusCode: statusCode,
    );
  } else {
    loomServiceBindingRegistry.recordCallFailure(
      service: LoomServiceBindingNames.workflowEngine,
      scope: _extensionId,
      statusCode: statusCode,
      errorKind: errorKind,
    );
  }
}
