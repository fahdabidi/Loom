import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

const _tokenEndpoint = String.fromEnvironment('LOOM_AUTH_TOKEN_ENDPOINT');
const _clientId = String.fromEnvironment('LOOM_AUTH_CLIENT_ID');
const _workflowServiceBaseUri = String.fromEnvironment(
  'LOOM_WORKFLOW_SERVICE_BASE_URI',
);
const _appAccessBaseUri = String.fromEnvironment('LOOM_APP_ACCESS_BASE_URI');
const _fanPassportBaseUri = String.fromEnvironment(
  'LOOM_FAN_PASSPORT_BASE_URI',
);
const _communityGroupIds = String.fromEnvironment('LOOM_COMMUNITY_GROUP_IDS');

final _remoteServiceDefines = <String, String>{
  'LOOM_AUTH_TOKEN_ENDPOINT': _tokenEndpoint,
  'LOOM_AUTH_CLIENT_ID': _clientId,
  'LOOM_WORKFLOW_SERVICE_BASE_URI': _workflowServiceBaseUri,
  'LOOM_APP_ACCESS_BASE_URI': _appAccessBaseUri,
  'LOOM_FAN_PASSPORT_BASE_URI': _fanPassportBaseUri,
  'LOOM_COMMUNITY_GROUP_IDS': _communityGroupIds,
};

final _missingRemoteServiceDefines = _remoteServiceDefines.entries
    .where((entry) => entry.value.isEmpty)
    .map((entry) => entry.key)
    .toList(growable: false);

final _hasAnyRemoteServiceDefine = _remoteServiceDefines.values.any(
  (value) => value.isNotEmpty,
);
final _hasAllRemoteServiceDefines = _missingRemoteServiceDefines.isEmpty;
final _hasPartialRemoteServiceDefines =
    _hasAnyRemoteServiceDefine && !_hasAllRemoteServiceDefines;

void main() {
  tearDown(resetLoomAuthSessionForTesting);

  test(
    'no remote-service defines leaves the app shell local',
    () {
      expect(configureLoomRemoteServicesFromEnvironment(), isNull);
      expect(loomAuthSession, isNull);
    },
    skip: _hasAnyRemoteServiceDefine
        ? 'Run without remote-service dart defines to verify the local '
              'default.'
        : false,
  );

  test(
    'all remote-service defines configure the real-service selection',
    () async {
      final authClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse(_tokenEndpoint));
        expect(request.bodyFields, containsPair('client_id', _clientId));
        return http.Response('{"error":"invalid_client"}', 400);
      });
      addTearDown(authClient.close);

      final configuration = configureLoomRemoteServicesFromEnvironment(
        authHttpClient: authClient,
      );

      expect(configuration, isNotNull);
      expect(
        configuration!.workflowServiceBaseUri,
        Uri.parse(_workflowServiceBaseUri),
      );
      expect(configuration.appAccessBaseUri, Uri.parse(_appAccessBaseUri));
      expect(configuration.fanPassportBaseUri, Uri.parse(_fanPassportBaseUri));
      expect(configuration.communityGroupIds, jsonDecode(_communityGroupIds));
      expect(loomAuthSession, same(configuration.session));
      expect(loomRemoteServiceConfiguration, same(configuration));
      await expectLater(
        configuration.session.loginWithTestCredentials(
          username: 'fake-user',
          password: 'fake-password',
        ),
        throwsA(isA<LoomAuthTokenEndpointException>()),
      );
    },
    skip: _hasAllRemoteServiceDefines
        ? false
        : 'Set every remote-service dart define to run the configured '
              'remote-services assertion.',
  );

  test(
    'partial remote-service defines fail loudly and name every missing key',
    () {
      final expectedMessage =
          'Remote Loom services are only partially configured. Missing dart '
          'defines: ${_missingRemoteServiceDefines.join(', ')}.';

      expect(
        configureLoomRemoteServicesFromEnvironment,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            expectedMessage,
          ),
        ),
      );
    },
    skip: _hasPartialRemoteServiceDefines
        ? false
        : 'Set a strict subset of the remote-service dart defines to run the '
              'partial-configuration failure assertion.',
  );
}
