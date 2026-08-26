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
    'no remote-service defines uses the default environment, not local',
    () {
      // The default is the real backend. Before 2026-08-26 an unconfigured
      // build silently returned null and ran an in-memory engine, which made
      // "uses the real backend" a property of the build command rather than of
      // the codebase -- and a capture that forgot the defines proved nothing
      // while looking like proof.
      final configuration = configureLoomRemoteServicesFromEnvironment();
      expect(configuration, isNotNull);

      final environment = resolveLoomServiceEnvironment();
      expect(environment, isNotNull);
      expect(
        configuration!.workflowServiceBaseUri.toString(),
        startsWith(environment!.workflowServiceBaseUri),
      );
      expect(configuration.communityGroupIds, environment.communityGroupIds);
      expect(loomAuthSession, isNotNull);
    },
    skip: _hasAnyRemoteServiceDefine
        ? 'Run without remote-service dart defines to verify the default '
              'environment is used.'
        : false,
  );

  test('LOOM_ENV=local is the explicit opt-in to the in-memory engine', () {
    // Local is still reachable, but only by asking for it. That is the whole
    // point of the flip: silence now means the backend, and local has to be
    // stated.
    expect(resolveLoomServiceEnvironment('local'), isNull);
  });

  test('an unknown environment name fails loudly and names what exists', () {
    // A typo'd LOOM_ENV must not quietly fall back to local -- that would
    // reintroduce exactly the silent-local failure this change removes.
    expect(
      () => resolveLoomServiceEnvironment('dveelopment'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('dveelopment'),
            contains('dev'),
            contains('local'),
          ),
        ),
      ),
    );
  });

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

  test('dev group ids are handle-derived, not derived from the community id', () {
    // The authority for these is each CommunityInstallationResult's returned
    // groupId, which App Access derives from the community HANDLE: hyphenated,
    // e.g. loom_communities_cedar-commons-hoa. The map key is the underscored
    // canonical community id, e.g. community_cedar_commons_hoa.
    //
    // The tempting bug is to synthesise the value as
    // 'loom_communities_' + communityId. That produces
    // loom_communities_community_cedar_commons_hoa -- a group that does not
    // exist -- and it fails as "no permissions" rather than "wrong group",
    // which is considerably harder to read. This asserts nobody has done that.
    //
    // Cross-checking against the workflow service's own map is not possible
    // from here: it lives in loom-backend/deploy/k8s/workflow-service.yaml, a
    // different repository. This catches the error mode that map is most
    // likely to disagree by.
    final environment = resolveLoomServiceEnvironment('dev')!;
    expect(environment.communityGroupIds, hasLength(11));

    environment.communityGroupIds.forEach((communityId, groupId) {
      expect(
        groupId,
        startsWith('loom_communities_'),
        reason: '$communityId maps to a group outside the app namespace',
      );
      expect(
        groupId,
        isNot('loom_communities_$communityId'),
        reason:
            '$communityId looks derived from the community id rather than '
            'taken from the installation result',
      );
      expect(
        groupId,
        isNot(contains('_community_')),
        reason: '$groupId retains the community-id prefix',
      );
    });
  });
}
