part of '../loom_communities_app_shell.dart';

class _EngineNativeCommunityStore {
  static final _stores = <String, _EngineNativeCommunityStore>{};

  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: extensionId,
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
