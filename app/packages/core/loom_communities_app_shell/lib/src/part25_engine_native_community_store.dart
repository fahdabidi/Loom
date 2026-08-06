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

class _EngineNativeCommunityStore {
  static final _stores = <String, _EngineNativeCommunityStore>{};

  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: extensionId,
    notificationDeliveryService: LocalNotificationDeliveryService(),
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
    final definitions = experience.workflowDefinitions!;
    for (final definition in definitions.values) {
      engine.registerDefinition(definition);
    }
    final seeds = <WorkflowInstance>[];
    for (final seed
        in experience.workflowInstances ?? const <LoomWorkflowSeedInstance>[]) {
      final creator = seed.createdByPersonaId;
      if (creator == null) {
        throw StateError(
          'Engine-native seed ${seed.instanceId} is missing createdByPersonaId',
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
    await engine.seedInstances(seeds);
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
