part of '../loom_communities_app_shell.dart';

/// The identity values needed by engine-native surfaces for one app subtree.
///
/// The role id remains the declared role, while [accountId] carries
/// the optional signed-in individual account. This keeps role/policy lookups
/// and per-individual engine calls explicit without relying on process-global
/// mutable state.
class ActiveIdentityContext {
  const ActiveIdentityContext({
    required this.accountId,
    required this.authApi,
    required this.roleId,
  });

  final String? accountId;
  final LoomAuthApi authApi;
  final String? roleId;

  /// Resolves the engine actor id, preferring the signed-in individual.
  String resolveEngineFanId(String fallbackFanId) => accountId ?? fallbackFanId;

  @override
  bool operator ==(Object other) =>
      other is ActiveIdentityContext &&
      other.accountId == accountId &&
      identical(other.authApi, authApi) &&
      other.roleId == roleId;

  @override
  int get hashCode => Object.hash(accountId, identityHashCode(authApi), roleId);
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
  String? get roleId => identity.roleId;

  /// Resolves the effective actor id for an engine call in this scope.
  String resolveEngineFanId(String fallbackFanId) =>
      identity.resolveEngineFanId(fallbackFanId);

  /// Updates this scope's active individual without affecting any other
  /// LocalExtensionScreen subtree.
  void setCurrentActiveAccountId(String? accountId) {
    if (identity.accountId == accountId) return;
    _identity.value = ActiveIdentityContext(
      accountId: accountId,
      authApi: identity.authApi,
      roleId: identity.roleId,
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

/// The factory selected by the production host at app startup.
///
/// It intentionally defaults to the exact local factory used before the
/// production seam existed. Stores capture the selected factory when they are
/// installed, so hosts should configure this before resolving any community
/// experience.
EngineNativeCommunityEngineFactory
_productionEngineNativeCommunityEngineFactory =
    _createLocalEngineNativeCommunityEngine;

/// Selects the engine factory for newly installed community stores.
///
/// This is the production configuration surface. It is deliberately distinct
/// from [overrideEngineNativeCommunityEngineFactoryForTesting], whose only
/// purpose is to replace the normal production selection inside tests.
void configureEngineNativeCommunityEngineFactoryForProduction(
  EngineNativeCommunityEngineFactory factory,
) {
  _productionEngineNativeCommunityEngineFactory = factory;
}

EngineNativeCommunityEngineFactory?
_engineNativeCommunityEngineFactoryOverrideForTesting;

final Map<String, EngineNativeCommunityEngineFactory>
_engineNativeCommunityEngineFactoriesByExtensionId =
    <String, EngineNativeCommunityEngineFactory>{};

@visibleForTesting
void overrideEngineNativeCommunityEngineFactoryForTesting(
  EngineNativeCommunityEngineFactory factory,
) {
  _engineNativeCommunityEngineFactoryOverrideForTesting = factory;
}

@visibleForTesting
void resetEngineNativeCommunityEngineFactoryForTesting() {
  _engineNativeCommunityEngineFactoryOverrideForTesting = null;
}

@visibleForTesting
void resetProductionEngineNativeCommunityEngineFactoryForTesting() {
  _productionEngineNativeCommunityEngineFactory =
      _createLocalEngineNativeCommunityEngine;
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
      _engineNativeCommunityEngineFactoryOverrideForTesting ??
      _productionEngineNativeCommunityEngineFactory)(
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
      final creator = seed.createdByFanId;
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
          createdByFanId: creator,
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
      required String fanId,
      String? roleId,
      String? tabId,
      String? workflowType,
    }) async {
      if (roleId == null) return false;
      if (tabId != null) {
        // Notification chrome is backed by the always-present Messages
        // platform surface but uses an internal query ID. Instance filtering
        // still limits the result to the addressed recipient.
        if (tabId == 'notifications' || tabId == 'notification-inbox') {
          return true;
        }
        return roleHasPermission(experience, roleId, tabId: tabId);
      }

      final machine = workflowType == null
          ? null
          : experience.workflowDefinitions?[workflowType];
      if (machine == null) return true;
      return roleHasPermission(experience, roleId, workflowType: workflowType);
    });
  }
}

void _installEngineNativeExperience(
  String extensionId,
  LoomExperienceDefinition experience,
) {
  if (experience.workflowDefinitions == null) return;
  final store = _EngineNativeCommunityStore.install(extensionId, experience);
  unawaited(
    store
        .ensureReady()
        .then((_) {
          // Opening a community is the first chance to deliver anything that came
          // due while the app was closed. Fire-and-forget: the screen must not wait
          // on a notification, and a failed sweep is recoverable by the next one.
          unawaited(sweepLoomRemindersForExtensionId(extensionId));
        })
        .catchError((Object _, StackTrace __) {}),
  );
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

/// Opens the opt-in offline replica for the member currently entering a
/// remote-backed community.
///
/// Returns whether a configured remote engine was opened. The false branch is
/// deliberately a no-op for local engines and for hosts that did not configure
/// an offline directory, preserving the previous path.
Future<bool> openOfflineReplicaForExtensionId({
  required String extensionId,
  required String fanId,
}) async {
  final engine = await workflowEngineForExtensionId(extensionId);
  if (engine is! LoomReplicaFallbackWorkflowEngineApi) return false;
  final coordinator = loomWorkflowReplicaCoordinator;
  if (coordinator == null) return false;
  await coordinator.open(fanId: fanId, communityId: engine.communityId);
  return true;
}

/// Performs the explicit refresh requested by a surface for the active
/// remote-backed community. There is intentionally no read-triggered or timed
/// synchronization path.
Future<void> refreshOfflineReplicaForExtensionId({
  required String extensionId,
}) async {
  final engine = await workflowEngineForExtensionId(extensionId);
  if (engine is! LoomReplicaFallbackWorkflowEngineApi) return;
  final coordinator = loomWorkflowReplicaCoordinator;
  if (coordinator == null) return;
  if (coordinator.activeCommunityId != engine.communityId) {
    throw StateError(
      'No offline replica is open for "${engine.communityId}". Open the '
      'community before refreshing it.',
    );
  }
  await coordinator.refresh();
}

/// Closes the active member/community replica when its screen leaves.
///
/// The coordinator is host-owned and one active replica is intentionally not
/// shared with another community route. A subsequent unavailable read through
/// the wrapped engine therefore fails closed rather than consulting the row
/// that belonged to the departed member.
void disposeOfflineReplicaForExtensionId({required String extensionId}) {
  final engine = _EngineNativeCommunityStore._stores[extensionId]?.engine;
  if (engine is! LoomReplicaFallbackWorkflowEngineApi) return;
  final coordinator = loomWorkflowReplicaCoordinator;
  if (coordinator == null ||
      coordinator.activeCommunityId != engine.communityId) {
    return;
  }
  coordinator.dispose();
}

/// One reminder sweeper per community, built on first use.
final Map<String, LoomReminderSweeper> _reminderSweepersByExtensionId = {};

/// Delivers any reminders that have come due for this community.
///
/// Returns how many were shown, and never throws — see [LoomReminderSweeper].
/// Call it when a community opens and whenever the app returns to the
/// foreground; a reminder that came due while the app was closed is delivered
/// late rather than lost, because the sweep asks for everything due as of now.
Future<int> sweepLoomRemindersForExtensionId(String extensionId) async {
  final store = _EngineNativeCommunityStore._stores[extensionId];
  if (store == null) return 0;
  await store.ensureReady();
  final sweeper = _reminderSweepersByExtensionId.putIfAbsent(
    extensionId,
    () => LoomReminderSweeper(
      engine: store.engine,
      delivery: LocalNotificationDeliveryService(),
      notificationConfiguration: store.experience.notificationConfiguration,
    ),
  );
  return sweeper.sweep();
}

@visibleForTesting
void resetLoomReminderSweepersForTesting() {
  _reminderSweepersByExtensionId.clear();
}

/// Wires the app-shell account store into the already-installed shared engine.
///
/// Engine-native stores are installed while package configuration is parsed,
/// before the screen's auth API is constructed. This late-binding hook reuses
/// the same [ActiveMembershipLookup] used by P4a and supplies the
/// app-shell-owned [roleHasPermission] policy without creating a package
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
