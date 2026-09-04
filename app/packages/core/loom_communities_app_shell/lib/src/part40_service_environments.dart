part of '../loom_communities_app_shell.dart';

/// Where every Loom backend service lives, for one named environment.
///
/// This exists because wiring the real backend had grown to six separate
/// `--dart-define`s that every build command had to repeat exactly, and a
/// capture that got one wrong was wrong in a way nothing checked. Endpoints
/// belong in one reviewable place, not spread across build invocations.
///
/// Deliberately a compile-time constant rather than a bundled JSON asset. An
/// asset would need `rootBundle`, which is async and would force `main()` to
/// become async, and it would add a file-not-found failure mode at startup —
/// all to gain nothing, because assets are bundled at build time exactly like
/// constants are. A `const` map is checked by the compiler instead.
///
/// No secrets live here. Endpoints and a public OAuth client id only: the
/// client secret, the fan password and the object-store credentials all stay
/// server side.
final class LoomServiceEnvironment {
  const LoomServiceEnvironment({
    required this.name,
    required this.authTokenEndpoint,
    required this.authClientId,
    required this.workflowServiceBaseUri,
    required this.appAccessBaseUri,
    required this.fanPassportBaseUri,
    required this.communityGroupIds,
  });

  final String name;
  final String authTokenEndpoint;
  final String authClientId;
  final String workflowServiceBaseUri;
  final String appAccessBaseUri;
  final String fanPassportBaseUri;

  /// Canonical community id -> App Access group-id fallback.
  ///
  /// These values are used only when the signed-in fan's live
  /// `listFanCommunities` lookup fails or omits the community. A successful
  /// server response remains the source of the fan's group id, roles, and
  /// membership state. The fallback ids are **handle-derived and hyphenated**
  /// (`loom_communities_cedar-commons-hoa`), while the key is the underscored
  /// canonical community id. One cannot be derived from the other, and the
  /// authority is each `CommunityInstallationResult`'s returned `groupId`.
  /// This map must stay identical to the one the workflow service reads from
  /// `LOOM_COMMUNITY_GROUP_IDS`; a test asserts that, because an app and a
  /// service that disagree about which group a community is would fail as
  /// "no permissions" rather than "wrong group", which is far harder to read.
  final Map<String, String> communityGroupIds;
}

/// The environment name this build targets.
///
/// Defaults to `dev`, which means **the real backend is the default**. A build
/// that wants the in-memory engine has to say so with `LOOM_ENV=local`; there
/// is no silent fallback, because a capture that quietly ran against a local
/// engine while appearing to prove the deployed stack is the exact failure the
/// backend migration exists to prevent.
const String loomServiceEnvironmentName = String.fromEnvironment(
  'LOOM_ENV',
  defaultValue: 'dev',
);

/// The environment name reserved for "use the in-memory engine".
const String loomLocalEnvironmentName = 'local';

/// Every environment this app knows how to reach.
const Map<String, LoomServiceEnvironment>
loomServiceEnvironments = <String, LoomServiceEnvironment>{
  'dev': LoomServiceEnvironment(
    name: 'dev',
    // The k3s cluster on the Loom VM, reachable from the host and from an
    // Android emulator over the host-only network. Plain HTTP: these
    // services have no TLS, which is why the debug manifest carries a
    // cleartext exemption scoped to exactly these hosts, and why TLS is on
    // the pre-GA list — a JWT crosses this link.
    authTokenEndpoint:
        'http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token',
    authClientId: 'loom-test-client',
    workflowServiceBaseUri: 'http://192.168.56.10:30083',
    appAccessBaseUri: 'http://192.168.56.10:30080',
    fanPassportBaseUri: 'http://192.168.56.10:30081',
    communityGroupIds: <String, String>{
      'community_ad_free_community': 'loom_communities_ad-free-community',
      'community_camera_club': 'loom_communities_camera-club',
      'community_cedar_commons_hoa': 'loom_communities_cedar-commons-hoa',
      'community_chess_club': 'loom_communities_chess-club',
      'community_data_portability':
          'loom_communities_data-portability-community',
      'community_garden_club': 'loom_communities_garden-club',
      'community_member_social_space': 'loom_communities_member-social-space',
      'community_mosque': 'loom_communities_masjid-nur',
      'community_neighborhood_book_club':
          'loom_communities_neighborhood-book-club',
      'community_riverside_youth_soccer':
          'loom_communities_riverside-youth-soccer',
      'community_verify_tabletop_club': 'loom_communities_tabletop-club',
    },
  ),
};

/// Forces the in-memory engine regardless of [loomServiceEnvironmentName].
///
/// `LOOM_ENV` is a compile-time constant, so a widget test that drives the
/// app's own `main()` cannot ask for the local engine through it — `main()`
/// would configure the default environment and leave that configuration in
/// module state for every test after it in the same process. That is a real
/// leak: a test passes alone and fails in the suite, which is among the more
/// expensive failure shapes to diagnose.
///
/// A test package sets this from its `flutter_test_config.dart`, which runs
/// before any test in that package, so it is in place before `main()` can be
/// called. Production never touches it.
@visibleForTesting
bool debugForceLoomLocalBackend = false;

/// Resolves the environment this build targets.
///
/// Returns `null` for the reserved `local` environment, which is the explicit
/// opt-in to the in-memory engine. Throws for a name that is neither `local`
/// nor a known environment, naming what was asked for and what exists — a
/// typo'd `LOOM_ENV` must fail loudly rather than quietly running local.
LoomServiceEnvironment? resolveLoomServiceEnvironment([String? name]) {
  if (debugForceLoomLocalBackend && name == null) return null;
  final requested = name ?? loomServiceEnvironmentName;
  if (requested == loomLocalEnvironmentName) return null;
  final environment = loomServiceEnvironments[requested];
  if (environment != null) return environment;
  throw StateError(
    'Unknown LOOM_ENV "$requested". Known environments: '
    '${loomServiceEnvironments.keys.join(', ')}, '
    'or "$loomLocalEnvironmentName" for the in-memory engine.',
  );
}
