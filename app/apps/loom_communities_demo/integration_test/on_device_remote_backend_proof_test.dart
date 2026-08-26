import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_communities_demo/main.dart' as demo;
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _authTokenEndpoint = String.fromEnvironment('LOOM_AUTH_TOKEN_ENDPOINT');
const _authClientId = String.fromEnvironment('LOOM_AUTH_CLIENT_ID');
const _workflowServiceBaseUri = String.fromEnvironment(
  'LOOM_WORKFLOW_SERVICE_BASE_URI',
);
const _appAccessBaseUri = String.fromEnvironment('LOOM_APP_ACCESS_BASE_URI');
const _fanPassportBaseUri = String.fromEnvironment(
  'LOOM_FAN_PASSPORT_BASE_URI',
);
const _communityGroupIds = String.fromEnvironment('LOOM_COMMUNITY_GROUP_IDS');

const _liveCommunityId = 'community_cedar_commons_hoa';
const _cedarReservationWorkflowType = 'hoa-facility-reservation';
const _cedarPackageAsset =
    'packages/loom_communities_app_shell/assets/'
    'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc';

final _remoteServiceDefines = <String, String>{
  'LOOM_AUTH_TOKEN_ENDPOINT': _authTokenEndpoint,
  'LOOM_AUTH_CLIENT_ID': _authClientId,
  'LOOM_WORKFLOW_SERVICE_BASE_URI': _workflowServiceBaseUri,
  'LOOM_APP_ACCESS_BASE_URI': _appAccessBaseUri,
  'LOOM_FAN_PASSPORT_BASE_URI': _fanPassportBaseUri,
  'LOOM_COMMUNITY_GROUP_IDS': _communityGroupIds,
};

final _missingRemoteServiceDefines = _remoteServiceDefines.entries
    .where((entry) => entry.value.isEmpty)
    .map((entry) => entry.key)
    .toList(growable: false);

final _remoteProofSkipReason = _missingRemoteServiceDefines.isEmpty
    ? false
    : 'Set every remote-service dart define to run the on-device remote-backend '
          'proof.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production factory uses the remote engine to read Cedar HOA data',
    () async {
      // Invoke the same entrypoint that configures the production factory in a
      // normal Android launch. The test must not recreate that configuration.
      demo.main();

      final session = loomAuthSession;
      expect(
        session,
        isNotNull,
        reason: 'The app entrypoint did not configure its remote auth session.',
      );

      final cedarPackage = await _readCedarPackage();
      expect(cedarPackage.communityId, _liveCommunityId);
      expect(
        cedarPackage.workflowDefinitions,
        contains(_cedarReservationWorkflowType),
      );
      expect(cedarPackage.workflowDefinitions, hasLength(7));

      // The live service is installed under its community id. Installing the
      // shipped experience under that id makes the production factory create
      // a client whose remote path is the deployed community, not a fixture.
      experienceForExtensionId(
        _liveCommunityId,
        displayName: cedarPackage.displayName,
        specVersion: cedarPackage.specVersion,
        experienceConfiguration: cedarPackage.experienceConfiguration,
      );
      final engine = await workflowEngineForExtensionId(_liveCommunityId);
      expect(engine, isA<RemoteWorkflowEngineApi>());
      final remoteEngine = engine as RemoteWorkflowEngineApi;
      expect(remoteEngine.communityId, _liveCommunityId);
      expect(
        remoteEngine.baseUri.scheme,
        Uri.parse(_workflowServiceBaseUri).scheme,
      );
      expect(
        remoteEngine.baseUri.host,
        Uri.parse(_workflowServiceBaseUri).host,
      );
      expect(
        remoteEngine.baseUri.port,
        Uri.parse(_workflowServiceBaseUri).port,
      );

      // Test-only credentials already committed with the live auth-session
      // coverage. This stores the app's own session and never prints its token.
      await session!.loginWithTestCredentials(
        username: 'test-fan-alice',
        password: 'LoomTest123!',
      );

      final page = await remoteEngine.queryInstances(
        tabId: 'calendar',
        fanId: 'fan-test-alice',
        workflowType: _cedarReservationWorkflowType,
        limit: 100,
      );
      expect(page.items, isNotEmpty);

      final reservation = page.items.first;
      expect(reservation.instanceId, isNotEmpty);
      expect(reservation.workflowType, _cedarReservationWorkflowType);
      expect(reservation.currentState, isNotEmpty);
      expect(reservation.instanceData, isNotEmpty);

      debugPrint(
        'ON_DEVICE_REMOTE_PROOF '
        'instanceCount=${page.items.length} '
        'instanceId=${reservation.instanceId} '
        'workflowType=${reservation.workflowType} '
        'state=${reservation.currentState} '
        'instanceData=${reservation.instanceData}',
      );
    },
    skip: _remoteProofSkipReason,
  );
}

Future<_CedarPackage> _readCedarPackage() async {
  final source = await rootBundle.loadString(_cedarPackageAsset);
  final decoded = jsonDecode(stripJsonComments(source));
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      'The bundled Cedar community package must be a JSON object.',
    );
  }
  final communityId = decoded['communityId'];
  final displayName = decoded['displayName'];
  final specVersion = decoded['specVersion'];
  final experience = decoded['experience'];
  if (communityId is! String ||
      displayName is! String ||
      specVersion is! int ||
      experience is! Map) {
    throw StateError(
      'The bundled Cedar community package must declare communityId, '
      'displayName, specVersion, and experience.',
    );
  }
  final workflowDefinitions = experience['workflowDefinitions'];
  if (workflowDefinitions is! Map) {
    throw StateError(
      'The bundled Cedar community package must declare '
      'experience.workflowDefinitions.',
    );
  }
  return _CedarPackage(
    communityId: communityId,
    displayName: displayName,
    specVersion: specVersion,
    experienceConfiguration: Map<String, Object?>.from(experience),
    workflowDefinitions: workflowDefinitions.keys.map((key) => '$key').toSet(),
  );
}

class _CedarPackage {
  const _CedarPackage({
    required this.communityId,
    required this.displayName,
    required this.specVersion,
    required this.experienceConfiguration,
    required this.workflowDefinitions,
  });

  final String communityId;
  final String displayName;
  final int specVersion;
  final Map<String, Object?> experienceConfiguration;
  final Set<String> workflowDefinitions;
}
