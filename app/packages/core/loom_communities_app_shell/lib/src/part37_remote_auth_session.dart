part of '../loom_communities_app_shell.dart';

/// The app-level remote-service configuration built from compile-time values.
///
/// [session] owns the persisted OAuth2 Authorization Code + PKCE session, and
/// [workflowServiceBaseUri] identifies the workflow service used by the
/// production community-engine factory.
final class LoomRemoteServiceConfiguration {
  const LoomRemoteServiceConfiguration({
    required this.session,
    required this.workflowServiceBaseUri,
  });

  final LoomAuthSession session;
  final Uri workflowServiceBaseUri;
}

LoomAuthSession? _loomAuthSession;

/// The single production identity-provider session owned by the app shell.
///
/// This is `null` until the host explicitly calls
/// [configureLoomRemoteServicesFromEnvironment]. An ordinary local build does
/// not configure a session and therefore keeps every existing community on
/// its unchanged local authentication and workflow-engine paths.
LoomAuthSession? get loomAuthSession => _loomAuthSession;

/// Configures the app shell's real identity-provider session from dart defines.
///
/// Supply all three values at build or run time:
///
/// ```text
/// --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=<absolute token endpoint>
/// --dart-define=LOOM_AUTH_CLIENT_ID=<public client id>
/// --dart-define=LOOM_WORKFLOW_SERVICE_BASE_URI=<absolute service base URI>
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

  final values = <String, String>{
    'LOOM_AUTH_TOKEN_ENDPOINT': tokenEndpointValue,
    'LOOM_AUTH_CLIENT_ID': clientId,
    'LOOM_WORKFLOW_SERVICE_BASE_URI': workflowServiceBaseUriValue,
  };
  if (values.values.every((value) => value.isEmpty)) return null;

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
        tokenEndpointValue,
        defineKey: 'LOOM_AUTH_TOKEN_ENDPOINT',
      ),
      clientId: clientId,
      secureStorage: FlutterSecureStorageBackend(secureStorage),
      httpClient: authHttpClient,
    ),
    workflowServiceBaseUri: _absoluteRemoteServiceUri(
      workflowServiceBaseUriValue,
      defineKey: 'LOOM_WORKFLOW_SERVICE_BASE_URI',
    ),
  );
  _loomAuthSession = configuration.session;
  return configuration;
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
}) =>
    ({required WorkflowDatabase database, required String extensionId}) =>
        RemoteWorkflowEngineApi(
          baseUri: workflowServiceBaseUri,
          communityId: extensionId,
          bearerTokenProvider: session.currentAccessToken,
          httpClient: httpClient,
        );

/// Builds the remote community-engine factory from the app's remote-service
/// configuration.
///
/// Keeping this adapter separate from the selection in part25 makes the
/// remote configuration a production input, not a test override.
EngineNativeCommunityEngineFactory
createRemoteEngineNativeCommunityEngineFactoryForConfiguration({
  required LoomRemoteServiceConfiguration configuration,
  required http.Client httpClient,
}) => createRemoteEngineNativeCommunityEngineFactory(
  session: configuration.session,
  workflowServiceBaseUri: configuration.workflowServiceBaseUri,
  httpClient: httpClient,
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
}) {
  _registerEngineNativeCommunityEngineFactory(
    extensionId: extensionId,
    factory: createRemoteEngineNativeCommunityEngineFactory(
      session: session,
      workflowServiceBaseUri: workflowServiceBaseUri,
      httpClient: httpClient,
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
}
