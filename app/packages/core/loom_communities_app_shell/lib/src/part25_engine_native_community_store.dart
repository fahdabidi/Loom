part of '../loom_communities_app_shell.dart';

/// The identity values needed by engine-native surfaces for one app subtree.
///
/// The persona id remains the declared persona type, while [accountId] carries
/// the optional signed-in individual account. This keeps role/policy lookups
/// and per-individual engine calls explicit without relying on process-global
/// mutable state.
class ActiveIdentityContext {
  const ActiveIdentityContext({
    required this.accountId,
    required this.authApi,
    required this.personaId,
  });

  final String? accountId;
  final LoomAuthApi authApi;
  final String? personaId;

  /// Resolves the engine actor id, preferring the signed-in individual.
  String resolveEnginePersonaId(String personaTypeId) =>
      accountId ?? personaTypeId;

  @override
  bool operator ==(Object other) =>
      other is ActiveIdentityContext &&
      other.accountId == accountId &&
      identical(other.authApi, authApi) &&
      other.personaId == personaId;

  @override
  int get hashCode =>
      Object.hash(accountId, identityHashCode(authApi), personaId);
}

/// Provides the active identity explicitly to the LocalExtensionScreen
/// subtree and to engine-native surfaces rendered beneath it.
class ActiveIdentityScope extends StatefulWidget {
  const ActiveIdentityScope({
    super.key,
    required this.identity,
    required this.child,
  });

  final ActiveIdentityContext identity;
  final Widget child;

  /// Finds the nearest active identity scope and registers the caller as a
  /// dependent so it rebuilds when the identity changes.
  static ActiveIdentityScopeState of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ActiveIdentityInherited>();
    assert(
      inherited != null,
      'ActiveIdentityScope.of() called without an ActiveIdentityScope ancestor.',
    );
    return inherited!.scope;
  }

  /// Finds the nearest active identity scope and registers the caller as a
  /// dependent so it rebuilds when the identity changes.
  ///
  /// Returns `null` when no [ActiveIdentityScope] ancestor exists.
  static ActiveIdentityScopeState? maybeOf(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_ActiveIdentityInherited>();
    return inherited?.scope;
  }

  @override
  State<ActiveIdentityScope> createState() => ActiveIdentityScopeState();
}

class ActiveIdentityScopeState extends State<ActiveIdentityScope> {
  late final ValueNotifier<ActiveIdentityContext> _identity = ValueNotifier(
    widget.identity,
  );

  ActiveIdentityContext get identity => _identity.value;
  String? get accountId => identity.accountId;
  LoomAuthApi get authApi => identity.authApi;
  String? get personaId => identity.personaId;

  /// Resolves the effective actor id for an engine call in this scope.
  String resolveEnginePersonaId(String personaTypeId) =>
      identity.resolveEnginePersonaId(personaTypeId);

  /// Updates this scope's active individual without affecting any other
  /// LocalExtensionScreen subtree.
  void setCurrentActiveAccountId(String? accountId) {
    if (identity.accountId == accountId) return;
    _identity.value = ActiveIdentityContext(
      accountId: accountId,
      authApi: identity.authApi,
      personaId: identity.personaId,
    );
  }

  @override
  void didUpdateWidget(covariant ActiveIdentityScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      _identity.value = widget.identity;
    }
  }

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ActiveIdentityInherited(
    notifier: _identity,
    scope: this,
    child: widget.child,
  );
}

class _ActiveIdentityInherited
    extends InheritedNotifier<ValueNotifier<ActiveIdentityContext>> {
  const _ActiveIdentityInherited({
    required ValueNotifier<ActiveIdentityContext> notifier,
    required this.scope,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  final ActiveIdentityScopeState scope;
}

typedef EngineNativeCommunityEngineFactory =
    WorkflowEngineApi Function({
      required WorkflowDatabase database,
      required String extensionId,
    });

WorkflowEngineApi _createLocalEngineNativeCommunityEngine({
  required WorkflowDatabase database,
  required String extensionId,
}) => LocalWorkflowEngineApi(
  db: database,
  communityId: extensionId,
  notificationDeliveryService: LocalNotificationDeliveryService(),
);

EngineNativeCommunityEngineFactory _engineNativeCommunityEngineFactory =
    _createLocalEngineNativeCommunityEngine;

final Map<String, EngineNativeCommunityEngineFactory>
_engineNativeCommunityEngineFactoriesByExtensionId =
    <String, EngineNativeCommunityEngineFactory>{};

@visibleForTesting
void overrideEngineNativeCommunityEngineFactoryForTesting(
  EngineNativeCommunityEngineFactory factory,
) {
  _engineNativeCommunityEngineFactory = factory;
}

@visibleForTesting
void resetEngineNativeCommunityEngineFactoryForTesting() {
  _engineNativeCommunityEngineFactory = _createLocalEngineNativeCommunityEngine;
}

void _registerEngineNativeCommunityEngineFactory({
  required String extensionId,
  required EngineNativeCommunityEngineFactory factory,
}) {
  _ensureEngineNativeCommunityRoutingCanChange(extensionId);
  _engineNativeCommunityEngineFactoriesByExtensionId[extensionId] = factory;
}

void _unregisterEngineNativeCommunityEngineFactory(String extensionId) {
  if (!_engineNativeCommunityEngineFactoriesByExtensionId.containsKey(
    extensionId,
  )) {
    return;
  }
  _ensureEngineNativeCommunityRoutingCanChange(extensionId);
  _engineNativeCommunityEngineFactoriesByExtensionId.remove(extensionId);
}

void _ensureEngineNativeCommunityRoutingCanChange(String extensionId) {
  if (_EngineNativeCommunityStore._stores.containsKey(extensionId)) {
    throw StateError(
      'Engine routing for "$extensionId" cannot be changed after its '
      'engine-native store has been installed. Configure routing before '
      'installing the community experience.',
    );
  }
}

@visibleForTesting
void resetEngineNativeCommunityFactoryRegistrationsForTesting() {
  _engineNativeCommunityEngineFactoriesByExtensionId.clear();
}

class _EngineNativeCommunityStore {
  static final _stores = <String, _EngineNativeCommunityStore>{};

  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final WorkflowEngineApi engine =
      (_engineNativeCommunityEngineFactoriesByExtensionId[extensionId] ??
      _engineNativeCommunityEngineFactory)(
        database: _database,
        extensionId: extensionId,
      );
  final LoomExperienceDefinition experience;
  final String extensionId;
  Future<void>? _ready;

  _EngineNativeCommunityStore._(this.extensionId, this.experience);

  static _EngineNativeCommunityStore install(
    String extensionId,
    LoomExperienceDefinition experience,
  ) => _stores.putIfAbsent(
    extensionId,
    () => _EngineNativeCommunityStore._(extensionId, experience),
  );

  Future<void> ensureReady() {
    final inFlight = _ready;
    if (inFlight != null) return inFlight;
    final future = _initialize();
    _ready = future;
    return future.catchError((Object error, StackTrace stack) {
      if (identical(_ready, future)) _ready = null;
      throw error;
    });
  }

  Future<void> _initialize() async {
    final local = engine;
    if (local is! LocalWorkflowEngineApi) return;
    final definitions = experience.workflowDefinitions!;
    for (final definition in definitions.values) {
      local.registerDefinition(definition);
    }
    final seeds = <WorkflowInstance>[];
    for (final seed
        in experience.workflowInstances ?? const <LoomWorkflowSeedInstance>[]) {
      final creator = seed.createdByPersonaId;
      if (creator == null) {
        throw StateError(
          'Engine-native seed ${seed.instanceId} is missing createdByFanId',
        );
      }
      seeds.add(
        WorkflowInstance(
          instanceId: seed.instanceId,
          workflowType: seed.workflowType,
          currentState: seed.currentState,
          instanceData: seed.instanceData,
          createdByPersonaId: creator,
        ),
      );
    }
    await local.seedInstances(seeds);
  }

  void configureAuthorization({
    required Map<String, Object?> appShellConfiguration,
    required ActiveMembershipLookup activeMembershipLookup,
  }) {
    final local = engine;
    if (local is! LocalWorkflowEngineApi) return;
    local.setActiveMembershipLookup(activeMembershipLookup);
    local.setSurfacePermissionLookup(({
      required String personaId,
      String? personaTypeId,
      String? tabId,
      String? workflowType,
    }) async {
      final effectivePersonaTypeId = personaTypeId ?? personaId;
      if (tabId != null) {
        final permission = requiredPermissionForTab(
          experience: experience,
          tabId: tabId,
          personaId: effectivePersonaTypeId,
          appShellConfiguration: appShellConfiguration,
        );
        if (permission == null) return false;
        return personaHasPermissionAsync(
          experience,
          personaId,
          permission,
          activeMembershipLookup: activeMembershipLookup,
          tabId: tabId,
          personaTypeId: effectivePersonaTypeId,
        );
      }

      final machine = workflowType == null
          ? null
          : experience.workflowDefinitions?[workflowType];
      if (machine == null) return true;
      final permissions = <String>{};
      for (final binding in machine.renderBindings) {
        final permission = requiredPermissionForTab(
          experience: experience,
          tabId: binding.tabId,
          personaId: effectivePersonaTypeId,
          appShellConfiguration: appShellConfiguration,
        );
        if (permission != null) permissions.add(permission);
      }
      if (permissions.isEmpty) return true;
      for (final permission in permissions) {
        if (await personaHasPermissionAsync(
          experience,
          personaId,
          permission,
          activeMembershipLookup: activeMembershipLookup,
          workflowType: workflowType,
          personaTypeId: effectivePersonaTypeId,
        )) {
          return true;
        }
      }
      return false;
    });
  }
}

void _installEngineNativeExperience(
  String extensionId,
  LoomExperienceDefinition experience,
) {
  if (experience.workflowDefinitions == null) return;
  final store = _EngineNativeCommunityStore.install(extensionId, experience);
  unawaited(store.ensureReady().catchError((Object _, StackTrace __) {}));
}

/// Returns the single ready workflow engine for an installed engine-native community.
Future<WorkflowEngineApi> workflowEngineForExtensionId(
  String extensionId,
) async {
  final store = _EngineNativeCommunityStore._stores[extensionId];
  if (store == null) {
    throw StateError(
      'No engine-native experience is installed for "$extensionId"',
    );
  }
  await store.ensureReady();
  return store.engine;
}

/// Wires the app-shell account store into the already-installed shared engine.
///
/// Engine-native stores are installed while package configuration is parsed,
/// before the screen's auth API is constructed. This late-binding hook reuses
/// the same [ActiveMembershipLookup] used by P4a and supplies the
/// app-shell-owned [personaHasPermission] policy without creating a package
/// dependency cycle.
void configureEngineAuthorizationForExtensionId({
  required String extensionId,
  required Map<String, Object?> appShellConfiguration,
  required ActiveMembershipLookup activeMembershipLookup,
}) {
  final store = _EngineNativeCommunityStore._stores[extensionId];
  if (store == null) return;
  store.configureAuthorization(
    appShellConfiguration: appShellConfiguration,
    activeMembershipLookup: activeMembershipLookup,
  );
}
