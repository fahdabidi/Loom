part of '../loom_communities_app_shell.dart';

/// Mutable reference to the auth API — set by the app shell so engine
/// callers can translate persona types to individual account IDs.
LoomAuthApi? _globalAuthApi;

/// The currently signed-in individual account id for engine calls.
String? _currentActiveAccountId;

void setCurrentActiveAccountId(String? accountId) {
  _currentActiveAccountId = accountId;
}

/// Resolves the effective persona id for engine calls, preferring the
/// individual account id when a user is signed in.
String resolveEnginePersonaId(String personaTypeId) {
  return _currentActiveAccountId ?? personaTypeId;
}

void setGlobalAuthApi(LoomAuthApi authApi) {
  _globalAuthApi = authApi;
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
    // Register persona-type mappings from seeded accounts
    final auth = _globalAuthApi;
    if (auth != null) {
      final accounts = await auth.listAccounts(
        communityExtensionId: extensionId,
      );
      for (final account in accounts) {
        engine.setPersonaType(account.accountId, account.personaTypeId);
      }
    }
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
