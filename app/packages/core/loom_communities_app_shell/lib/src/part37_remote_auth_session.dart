part of '../loom_communities_app_shell.dart';

/// The app-level remote-service configuration built from compile-time values.
///
/// [session] owns the persisted OAuth2 Authorization Code + PKCE session, and
/// the three service URIs are production inputs for the workflow engine and
/// remote community-auth implementations. [communityGroupIds] is the remote
/// auth copy of the server-returned App Access mapping keyed by canonical
/// community id; it is never derived from a package or extension id.
final class LoomRemoteServiceConfiguration {
  LoomRemoteServiceConfiguration({
    required this.session,
    required this.workflowServiceBaseUri,
    required this.appAccessBaseUri,
    required this.fanPassportBaseUri,
    required Map<String, String> communityGroupIds,
    this.appId = 'loom_communities',
  }) : communityGroupIds = Map.unmodifiable(communityGroupIds);

  final LoomAuthSession session;
  final Uri workflowServiceBaseUri;
  final Uri appAccessBaseUri;
  final Uri fanPassportBaseUri;
  final Map<String, String> communityGroupIds;
  final String appId;

  /// Resolves a real App Access group only from the explicit deployment map.
  ///
  /// The app-shell knows a community's canonical id at installation time, but
  /// it deliberately does not know (or derive) the App Access naming rules.
  String? groupIdForCommunity(String communityId) =>
      communityGroupIds[communityId];
}

LoomAuthSession? _loomAuthSession;
LoomRemoteServiceConfiguration? _loomRemoteServiceConfiguration;

/// The single production identity-provider session owned by the app shell.
///
/// This is `null` until the host explicitly calls
/// [configureLoomRemoteServicesFromEnvironment]. An ordinary local build does
/// not configure a session and therefore keeps every existing community on
/// its unchanged local authentication and workflow-engine paths.
LoomAuthSession? get loomAuthSession => _loomAuthSession;

/// The production remote-services selection, if the host configured one.
///
/// This is intentionally separate from [loomAuthSession]: test code may
/// replace a login session without selecting remote App Access or Fan Passport
/// behavior for a production-auth API.
LoomRemoteServiceConfiguration? get loomRemoteServiceConfiguration =>
    _loomRemoteServiceConfiguration;

/// Configures the app shell's real identity-provider session from dart defines.
///
/// Supply all six values at build or run time:
///
/// ```text
/// --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=<absolute token endpoint>
/// --dart-define=LOOM_AUTH_CLIENT_ID=<public client id>
/// --dart-define=LOOM_WORKFLOW_SERVICE_BASE_URI=<absolute service base URI>
/// --dart-define=LOOM_APP_ACCESS_BASE_URI=<absolute App Access base URI>
/// --dart-define=LOOM_FAN_PASSPORT_BASE_URI=<absolute Fan Passport base URI>
/// --dart-define=LOOM_COMMUNITY_GROUP_IDS=<canonical-community-id JSON map>
/// ```
///
/// When none of the defines are present, this returns `null` and leaves the
/// app shell unconfigured. A partially configured invocation throws a clear
/// [StateError] only when this function is called; configuration is never read
/// eagerly at library import time. App startup supplies the returned
/// configuration to its production community-engine selection.
LoomRemoteServiceConfiguration? configureLoomRemoteServicesFromEnvironment({
  http.Client? authHttpClient,
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
}) {
  const tokenEndpointValue = String.fromEnvironment('LOOM_AUTH_TOKEN_ENDPOINT');
  const clientId = String.fromEnvironment('LOOM_AUTH_CLIENT_ID');
  const workflowServiceBaseUriValue = String.fromEnvironment(
    'LOOM_WORKFLOW_SERVICE_BASE_URI',
  );
  const appAccessBaseUriValue = String.fromEnvironment(
    'LOOM_APP_ACCESS_BASE_URI',
  );
  const fanPassportBaseUriValue = String.fromEnvironment(
    'LOOM_FAN_PASSPORT_BASE_URI',
  );
  const communityGroupIdsValue = String.fromEnvironment(
    'LOOM_COMMUNITY_GROUP_IDS',
  );

  final defineValues = <String, String>{
    'LOOM_AUTH_TOKEN_ENDPOINT': tokenEndpointValue,
    'LOOM_AUTH_CLIENT_ID': clientId,
    'LOOM_WORKFLOW_SERVICE_BASE_URI': workflowServiceBaseUriValue,
    'LOOM_APP_ACCESS_BASE_URI': appAccessBaseUriValue,
    'LOOM_FAN_PASSPORT_BASE_URI': fanPassportBaseUriValue,
    'LOOM_COMMUNITY_GROUP_IDS': communityGroupIdsValue,
  };

  // The named environment supplies every endpoint; the six defines remain as a
  // one-off override so a build can be pointed at another cluster without
  // adding an environment. When no define is present the environment is used
  // verbatim, which is what makes the real backend the default.
  //
  // `resolveLoomServiceEnvironment` returns null only for LOOM_ENV=local, the
  // explicit opt-in to the in-memory engine, and throws for an unknown name.
  // There is no silent fallback to local: a capture that quietly ran against a
  // local engine while appearing to prove the deployed stack is the exact
  // failure this whole migration exists to prevent.
  final environment = resolveLoomServiceEnvironment();
  if (defineValues.values.every((value) => value.isEmpty)) {
    if (environment == null) return null;
    return _configurationFromEnvironment(
      environment,
      authHttpClient: authHttpClient,
      secureStorage: secureStorage,
    );
  }

  final values = <String, String>{
    'LOOM_AUTH_TOKEN_ENDPOINT': tokenEndpointValue.isNotEmpty
        ? tokenEndpointValue
        : environment?.authTokenEndpoint ?? '',
    'LOOM_AUTH_CLIENT_ID': clientId.isNotEmpty
        ? clientId
        : environment?.authClientId ?? '',
    'LOOM_WORKFLOW_SERVICE_BASE_URI': workflowServiceBaseUriValue.isNotEmpty
        ? workflowServiceBaseUriValue
        : environment?.workflowServiceBaseUri ?? '',
    'LOOM_APP_ACCESS_BASE_URI': appAccessBaseUriValue.isNotEmpty
        ? appAccessBaseUriValue
        : environment?.appAccessBaseUri ?? '',
    'LOOM_FAN_PASSPORT_BASE_URI': fanPassportBaseUriValue.isNotEmpty
        ? fanPassportBaseUriValue
        : environment?.fanPassportBaseUri ?? '',
    'LOOM_COMMUNITY_GROUP_IDS': communityGroupIdsValue.isNotEmpty
        ? communityGroupIdsValue
        : environment == null
        ? ''
        : jsonEncode(environment.communityGroupIds),
  };

  final missingKeys = values.entries
      .where((entry) => entry.value.isEmpty)
      .map((entry) => entry.key)
      .join(', ');
  if (missingKeys.isNotEmpty) {
    throw StateError(
      'Remote Loom services are only partially configured. Missing dart '
      'defines: $missingKeys.',
    );
  }

  final configuration = LoomRemoteServiceConfiguration(
    session: LoomAuthSession(
      tokenEndpoint: _absoluteRemoteServiceUri(
        values['LOOM_AUTH_TOKEN_ENDPOINT']!,
        defineKey: 'LOOM_AUTH_TOKEN_ENDPOINT',
      ),
      clientId: values['LOOM_AUTH_CLIENT_ID']!,
      secureStorage: FlutterSecureStorageBackend(secureStorage),
      httpClient: authHttpClient,
    ),
    workflowServiceBaseUri: _absoluteRemoteServiceUri(
      values['LOOM_WORKFLOW_SERVICE_BASE_URI']!,
      defineKey: 'LOOM_WORKFLOW_SERVICE_BASE_URI',
    ),
    appAccessBaseUri: _absoluteRemoteServiceUri(
      values['LOOM_APP_ACCESS_BASE_URI']!,
      defineKey: 'LOOM_APP_ACCESS_BASE_URI',
    ),
    fanPassportBaseUri: _absoluteRemoteServiceUri(
      values['LOOM_FAN_PASSPORT_BASE_URI']!,
      defineKey: 'LOOM_FAN_PASSPORT_BASE_URI',
    ),
    communityGroupIds: _remoteCommunityGroupIdsFromEnvironment(
      values['LOOM_COMMUNITY_GROUP_IDS']!,
    ),
  );
  _loomAuthSession = configuration.session;
  _loomRemoteServiceConfiguration = configuration;
  return configuration;
}

/// Builds a configuration directly from a named environment.
///
/// This is the default path: no defines present, so every endpoint comes from
/// [LoomServiceEnvironment] verbatim. The values are compile-time constants
/// that the environment table already vouches for, so there is nothing to
/// validate for emptiness here — an absent endpoint would be a missing field
/// on a `const` constructor and would not compile.
LoomRemoteServiceConfiguration _configurationFromEnvironment(
  LoomServiceEnvironment environment, {
  http.Client? authHttpClient,
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
}) {
  final configuration = LoomRemoteServiceConfiguration(
    session: LoomAuthSession(
      tokenEndpoint: _absoluteRemoteServiceUri(
        environment.authTokenEndpoint,
        defineKey: 'LOOM_ENV=${environment.name} authTokenEndpoint',
      ),
      clientId: environment.authClientId,
      secureStorage: FlutterSecureStorageBackend(secureStorage),
      httpClient: authHttpClient,
    ),
    workflowServiceBaseUri: _absoluteRemoteServiceUri(
      environment.workflowServiceBaseUri,
      defineKey: 'LOOM_ENV=${environment.name} workflowServiceBaseUri',
    ),
    appAccessBaseUri: _absoluteRemoteServiceUri(
      environment.appAccessBaseUri,
      defineKey: 'LOOM_ENV=${environment.name} appAccessBaseUri',
    ),
    fanPassportBaseUri: _absoluteRemoteServiceUri(
      environment.fanPassportBaseUri,
      defineKey: 'LOOM_ENV=${environment.name} fanPassportBaseUri',
    ),
    communityGroupIds: Map<String, String>.unmodifiable(
      environment.communityGroupIds,
    ),
  );
  _loomAuthSession = configuration.session;
  _loomRemoteServiceConfiguration = configuration;
  return configuration;
}

Map<String, String> _remoteCommunityGroupIdsFromEnvironment(String encoded) {
  final Object? decoded;
  try {
    decoded = jsonDecode(encoded);
  } on FormatException {
    throw StateError(
      'LOOM_COMMUNITY_GROUP_IDS must be a JSON object mapping non-empty '
      'canonical community ids to non-empty App Access group ids.',
    );
  }
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      'LOOM_COMMUNITY_GROUP_IDS must be a JSON object mapping non-empty '
      'canonical community ids to non-empty App Access group ids.',
    );
  }
  final groupIds = <String, String>{};
  for (final entry in decoded.entries) {
    final groupId = entry.value;
    if (entry.key.trim().isEmpty ||
        groupId is! String ||
        groupId.trim().isEmpty) {
      throw StateError(
        'LOOM_COMMUNITY_GROUP_IDS must map non-empty canonical community ids '
        'to non-empty App Access group ids.',
      );
    }
    groupIds[entry.key] = groupId;
  }
  return Map.unmodifiable(groupIds);
}

Uri _absoluteRemoteServiceUri(String value, {required String defineKey}) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw StateError('$defineKey must be an absolute URI.');
  }
  return uri;
}

/// Builds a remote engine factory without changing the app shell's default.
///
/// The returned closure captures the real session and service base URI while
/// preserving the existing [EngineNativeCommunityEngineFactory] signature.
/// Selecting this factory for any community is deliberately separate work.
EngineNativeCommunityEngineFactory
createRemoteEngineNativeCommunityEngineFactory({
  required LoomAuthSession session,
  required Uri workflowServiceBaseUri,
  required http.Client httpClient,
  LoomWorkflowReplicaCoordinator? offlineReplicaCoordinator,
}) => ({required WorkflowDatabase database, required String extensionId}) {
  final remote = RemoteWorkflowEngineApi(
    baseUri: workflowServiceBaseUri,
    communityId: extensionId,
    bearerTokenProvider: session.currentAccessToken,
    httpClient: httpClient,
  );
  final coordinator = offlineReplicaCoordinator;
  return coordinator == null
      ? remote
      : coordinator.wrap(remote, communityId: extensionId);
};

/// Builds the remote community-engine factory from the app's remote-service
/// configuration.
///
/// Keeping this adapter separate from the selection in part25 makes the
/// remote configuration a production input, not a test override.
EngineNativeCommunityEngineFactory
createRemoteEngineNativeCommunityEngineFactoryForConfiguration({
  required LoomRemoteServiceConfiguration configuration,
  required http.Client httpClient,
  LoomWorkflowReplicaCoordinator? offlineReplicaCoordinator,
}) => createRemoteEngineNativeCommunityEngineFactory(
  session: configuration.session,
  workflowServiceBaseUri: configuration.workflowServiceBaseUri,
  httpClient: httpClient,
  offlineReplicaCoordinator: offlineReplicaCoordinator,
);

/// Routes one community to the remote workflow engine.
///
/// This must be called before [experienceForExtensionId] installs the
/// engine-native store for [extensionId]. A per-community registration takes
/// precedence over the process-wide engine factory; communities without a
/// registration continue to use that existing factory unchanged.
void enableRemoteEngineForCommunity({
  required String extensionId,
  required LoomAuthSession session,
  required Uri workflowServiceBaseUri,
  required http.Client httpClient,
  LoomWorkflowReplicaCoordinator? offlineReplicaCoordinator,
}) {
  _registerEngineNativeCommunityEngineFactory(
    extensionId: extensionId,
    factory: createRemoteEngineNativeCommunityEngineFactory(
      session: session,
      workflowServiceBaseUri: workflowServiceBaseUri,
      httpClient: httpClient,
      offlineReplicaCoordinator: offlineReplicaCoordinator,
    ),
  );
}

/// Removes one community's remote workflow-engine registration.
///
/// This is idempotent when [extensionId] has no registration. Like enablement,
/// an existing registration cannot be removed after the community's
/// engine-native store has been installed because that store caches its engine.
void disableRemoteEngineForCommunity({required String extensionId}) {
  _unregisterEngineNativeCommunityEngineFactory(extensionId);
}

@visibleForTesting
void overrideLoomAuthSessionForTesting(LoomAuthSession session) {
  _loomAuthSession = session;
}

@visibleForTesting
void resetLoomAuthSessionForTesting() {
  _loomAuthSession = null;
  _loomRemoteServiceConfiguration = null;
}

/// Test-only replacement for the remote production selection.
///
/// Production code reaches the same selection only through
/// [configureLoomRemoteServicesFromEnvironment]. Keeping this hook separate
/// ensures a test session override cannot accidentally route production auth.
@visibleForTesting
void overrideLoomRemoteServiceConfigurationForTesting(
  LoomRemoteServiceConfiguration configuration,
) {
  _loomRemoteServiceConfiguration = configuration;
}
