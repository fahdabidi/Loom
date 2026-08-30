part of '../loom_communities_app_shell.dart';

/// Where the most recently completed workflow read came from.
enum LoomWorkflowReadSource { remote, replica }

/// Freshness information for a workflow read made through the offline façade.
///
/// A replica result is intentionally marked separately from a normal remote
/// response. [replicaCursor] and [replicaCursorAge] let a surface tell a
/// member that it is showing a stored snapshot, rather than presenting stale
/// data as live.
final class LoomWorkflowReadMetadata {
  const LoomWorkflowReadMetadata._({
    required this.source,
    this.replicaCursor,
    this.replicaCursorAge,
  });

  const LoomWorkflowReadMetadata.remote()
    : this._(source: LoomWorkflowReadSource.remote);

  const LoomWorkflowReadMetadata.replica({
    required WorkflowReplicaCursor cursor,
    required Duration? cursorAge,
  }) : this._(
         source: LoomWorkflowReadSource.replica,
         replicaCursor: cursor,
         replicaCursorAge: cursorAge,
       );

  final LoomWorkflowReadSource source;

  /// The server-owned cursor that produced this local snapshot.
  final WorkflowReplicaCursor? replicaCursor;

  /// Age of [replicaCursor]'s epoch-millisecond position at the time of read.
  ///
  /// It is null only for an initial cursor, which has no server timestamp.
  final Duration? replicaCursorAge;

  bool get cameFromReplica => source == LoomWorkflowReadSource.replica;
}

/// Owns the one active server-fed replica for a signed-in member/community.
///
/// A host creates this only after injecting a writable [databaseDirectory].
/// It never discovers a platform directory. Opening a pair synchronizes its
/// replica once; callers may use [refresh] for an explicit later sync. Reads
/// are never themselves a reason to synchronize.
final class LoomWorkflowReplicaCoordinator {
  LoomWorkflowReplicaCoordinator({
    required String databaseDirectory,
    required LoomVisibleChangesClient visibleChangesClient,
    DateTime Function()? now,
  }) : databaseDirectory = _requireReplicaDirectory(databaseDirectory),
       _visibleChangesClient = visibleChangesClient,
       _now = now ?? DateTime.now;

  /// The host-supplied directory that contains one file per fan/community.
  final String databaseDirectory;
  final LoomVisibleChangesClient _visibleChangesClient;
  final DateTime Function() _now;

  Future<void> _serial = Future<void>.value();
  LoomWorkflowReplica? _activeReplica;
  LoomWorkflowReadMetadata? _lastRead;
  LoomVisibleChangesException? _lastOpenSyncFailure;
  bool _disposed = false;

  /// The active replica, if a member/community pair has been opened.
  LoomWorkflowReplica? get activeReplica => _activeReplica;

  String? get activeFanId => _activeReplica?.fanId;
  String? get activeCommunityId => _activeReplica?.communityId;

  /// Metadata for the most recent completed read through any wrapped engine.
  ///
  /// Surfaces can inspect this after their read when deciding whether to show
  /// an offline/stale-data treatment.
  LoomWorkflowReadMetadata? get lastRead => _lastRead;

  /// An unavailable change-feed refresh encountered while opening.
  ///
  /// Opening keeps a previously stored snapshot usable for an unavailable
  /// service. Non-availability failures, including 403, still surface.
  LoomVisibleChangesException? get lastOpenSyncFailure => _lastOpenSyncFailure;

  /// Opens and synchronizes the active fan/community replica.
  ///
  /// An active handle for another fan or community is closed before the new
  /// file is opened. An unavailable feed leaves an existing on-disk snapshot
  /// available for read fallback; a real HTTP response such as 403 is never
  /// hidden.
  Future<void> open({required String fanId, required String communityId}) =>
      _runSerial(() async {
        _ensureUsable();
        _requireNonEmpty(fanId, 'fanId');
        _requireNonEmpty(communityId, 'communityId');

        var replica = _activeReplica;
        if (replica == null ||
            replica.fanId != fanId ||
            replica.communityId != communityId) {
          _closeActiveReplica();
          replica = await LoomWorkflowReplica.openFile(
            databasePath: _databasePathFor(
              fanId: fanId,
              communityId: communityId,
            ),
            fanId: fanId,
            communityId: communityId,
          );
          _activeReplica = replica;
          _lastRead = null;
        }

        try {
          await replica.sync(_visibleChangesClient);
          _lastOpenSyncFailure = null;
        } on LoomVisibleChangesException catch (error) {
          if (!error.isUnavailable) rethrow;
          _lastOpenSyncFailure = error;
        }
      });

  /// Explicitly synchronizes the currently open replica.
  ///
  /// Unlike [open], this reports all failures to its caller because the caller
  /// deliberately asked to refresh. No periodic or read-triggered sync exists.
  Future<void> refresh() => _runSerial(() async {
    _ensureUsable();
    final replica = _activeReplica;
    if (replica == null) {
      throw StateError(
        'No offline replica is open. Open a member and community first.',
      );
    }
    await replica.sync(_visibleChangesClient);
    _lastOpenSyncFailure = null;
  });

  /// Wraps one remote community engine with availability-only read fallback.
  ///
  /// The wrapper still makes every write against [remoteEngine] first. It is
  /// intentionally useful only for the injected production offline seam; the
  /// default local engine remains unchanged.
  LoomReplicaFallbackWorkflowEngineApi wrap(
    WorkflowEngineApi remoteEngine, {
    required String communityId,
  }) => LoomReplicaFallbackWorkflowEngineApi._(
    coordinator: this,
    remoteEngine: remoteEngine,
    communityId: communityId,
  );

  /// Closes the active database handle. The injected change client is not
  /// closed because its host owns that transport.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _closeActiveReplica();
    _lastRead = null;
  }

  Future<T> _runSerial<T>(Future<T> Function() action) {
    final scheduled = _serial.then<T>((_) => action());
    _serial = scheduled.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return scheduled;
  }

  ReadOnlyWorkflowReplicaApi? _replicaFor({
    required String fanId,
    required String communityId,
  }) {
    final replica = _activeReplica;
    if (replica == null ||
        replica.isClosed ||
        replica.fanId != fanId ||
        replica.communityId != communityId) {
      return null;
    }
    return replica.engine;
  }

  ReadOnlyWorkflowReplicaApi? _replicaForCommunity(String communityId) {
    final replica = _activeReplica;
    if (replica == null ||
        replica.isClosed ||
        replica.communityId != communityId) {
      return null;
    }
    return replica.engine;
  }

  Future<void> _recordReplicaRead(ReadOnlyWorkflowReplicaApi replica) async {
    final cursor = await replica._database.readReplicaCursor(
      fanId: replica.fanId,
      communityId: replica.communityId,
    );
    final updatedSince = cursor.nextUpdatedSince;
    final age = updatedSince == null
        ? null
        : _nonNegativeAge(
            _now().toUtc().difference(
              DateTime.fromMillisecondsSinceEpoch(updatedSince, isUtc: true),
            ),
          );
    _lastRead = LoomWorkflowReadMetadata.replica(
      cursor: cursor,
      cursorAge: age,
    );
  }

  void _recordRemoteRead() {
    _lastRead = const LoomWorkflowReadMetadata.remote();
  }

  String _databasePathFor({
    required String fanId,
    required String communityId,
  }) {
    // URL-safe base64 gives each pair one portable filename without allowing
    // either externally supplied identifier to create path components.
    final encodedPair = base64Url.encode(
      utf8.encode('$fanId\u0000$communityId'),
    );
    return '$databaseDirectory/$encodedPair.sqlite';
  }

  void _closeActiveReplica() {
    final replica = _activeReplica;
    _activeReplica = null;
    replica?.close();
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('This offline replica coordinator has been disposed.');
    }
  }
}

/// A remote-engine façade that reads a visible replica only after remote
/// unavailability. It deliberately has no replica mutation route.
final class LoomReplicaFallbackWorkflowEngineApi implements WorkflowEngineApi {
  LoomReplicaFallbackWorkflowEngineApi._({
    required LoomWorkflowReplicaCoordinator coordinator,
    required this.remoteEngine,
    required this.communityId,
  }) : _coordinator = coordinator;

  final LoomWorkflowReplicaCoordinator _coordinator;
  final WorkflowEngineApi remoteEngine;
  final String communityId;

  /// The source and age of the most recently completed read.
  LoomWorkflowReadMetadata? get lastRead => _coordinator.lastRead;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String fanId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) => _readForFan(
    fanId: fanId,
    remote: () => remoteEngine.queryInstances(
      tabId: tabId,
      fanId: fanId,
      query: query,
      limit: limit,
      cursor: cursor,
    ),
    replica: (engine) => engine.queryInstances(
      tabId: tabId,
      fanId: fanId,
      query: query,
      limit: limit,
      cursor: cursor,
    ),
  );

  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) => remoteEngine.availableTransitions(
    workflowType: workflowType,
    instanceId: instanceId,
    currentState: currentState,
    instanceData: instanceData,
    fanId: fanId,
  );

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) => _readForFan(
    fanId: fanId,
    remote: () => remoteEngine.availableTransitionsAsync(
      workflowType: workflowType,
      instanceId: instanceId,
      currentState: currentState,
      instanceData: instanceData,
      fanId: fanId,
    ),
    replica: (engine) => engine.availableTransitionsAsync(
      workflowType: workflowType,
      instanceId: instanceId,
      currentState: currentState,
      instanceData: instanceData,
      fanId: fanId,
    ),
  );

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
  }) => _write(
    () => remoteEngine.applyTransition(
      workflowType: workflowType,
      instanceId: instanceId,
      transitionId: transitionId,
      fanId: fanId,
      inputs: inputs,
    ),
  );

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  }) => _write(
    () => remoteEngine.createInstance(
      workflowType: workflowType,
      initialInstanceData: initialInstanceData,
      fanId: fanId,
    ),
  );

  @override
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String fanId,
  }) => _write(
    () => remoteEngine.createInstances(
      workflowType: workflowType,
      initialInstanceDataList: initialInstanceDataList,
      fanId: fanId,
    ),
  );

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String fanId,
  }) => _write(
    () => remoteEngine.updateInstanceFields(
      workflowType: workflowType,
      instanceId: instanceId,
      fieldUpdates: fieldUpdates,
      fanId: fanId,
    ),
  );

  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? fanId,
  }) {
    final remote = () => remoteEngine.aggregate(
      workflowType: workflowType,
      column: column,
      op: op,
      filter: filter,
      groupBy: groupBy,
      fanId: fanId,
    );
    // An unscoped aggregate is system truth used by guard evaluation. A
    // viewer-scoped replica must never stand in for it.
    if (fanId == null) return remote();
    return _readForFan(
      fanId: fanId,
      remote: remote,
      replica: (engine) => engine.aggregate(
        workflowType: workflowType,
        column: column,
        op: op,
        filter: filter,
        groupBy: groupBy,
        fanId: fanId,
      ),
    );
  }

  @override
  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf}) =>
      _readForCommunity(
        remote: () => remoteEngine.dueNotifications(asOf: asOf),
        replica: (engine) => engine.dueNotifications(asOf: asOf),
      );

  Future<T> _readForFan<T>({
    required String fanId,
    required Future<T> Function() remote,
    required Future<T> Function(ReadOnlyWorkflowReplicaApi engine) replica,
  }) async {
    try {
      final value = await remote();
      _coordinator._recordRemoteRead();
      return value;
    } on RemoteWorkflowEngineException catch (error) {
      if (!_isUnavailable(error)) rethrow;
      final engine = _coordinator._replicaFor(
        fanId: fanId,
        communityId: communityId,
      );
      if (engine == null) rethrow;
      final value = await replica(engine);
      await _coordinator._recordReplicaRead(engine);
      return value;
    }
  }

  Future<T> _readForCommunity<T>({
    required Future<T> Function() remote,
    required Future<T> Function(ReadOnlyWorkflowReplicaApi engine) replica,
  }) async {
    try {
      final value = await remote();
      _coordinator._recordRemoteRead();
      return value;
    } on RemoteWorkflowEngineException catch (error) {
      if (!_isUnavailable(error)) rethrow;
      final engine = _coordinator._replicaForCommunity(communityId);
      if (engine == null) rethrow;
      final value = await replica(engine);
      await _coordinator._recordReplicaRead(engine);
      return value;
    }
  }

  Future<T> _write<T>(Future<T> Function() remote) async {
    try {
      return await remote();
    } on RemoteWorkflowEngineException catch (error) {
      if (!_isUnavailable(error)) rethrow;
      throw StateError(LoomWorkflowReplica.offlineWriteMessage);
    }
  }
}

bool _isUnavailable(RemoteWorkflowEngineException error) =>
    error.statusCode == null || error.statusCode! >= 500;

Duration _nonNegativeAge(Duration value) =>
    value.isNegative ? Duration.zero : value;

String _requireReplicaDirectory(String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      'databaseDirectory',
      'must be a non-empty host-supplied writable directory',
    );
  }
  return value;
}

void _requireNonEmpty(String value, String name) {
  if (value.trim().isNotEmpty) return;
  throw ArgumentError.value(value, name, 'must not be empty');
}

LoomWorkflowReplicaCoordinator? _loomWorkflowReplicaCoordinator;

/// The production coordinator when a host has opted into offline replicas.
///
/// It is null by default. That keeps the app's previous remote-only behavior
/// exactly intact when the host has not supplied a writable directory.
LoomWorkflowReplicaCoordinator? get loomWorkflowReplicaCoordinator =>
    _loomWorkflowReplicaCoordinator;

/// Configures opt-in offline replica support from explicit host-owned inputs.
///
/// This function deliberately performs no platform-directory lookup. The host
/// supplies [databaseDirectory], while remote-session configuration supplies
/// the authenticated change-feed client. Calling it does not open a database;
/// opening is deferred until a member opens a community.
void configureLoomOfflineReplicaSupportForProduction({
  required String databaseDirectory,
  required LoomRemoteServiceConfiguration remoteServices,
  http.Client? httpClient,
}) {
  _loomWorkflowReplicaCoordinator?.dispose();
  _loomWorkflowReplicaCoordinator = LoomWorkflowReplicaCoordinator(
    databaseDirectory: databaseDirectory,
    visibleChangesClient: LoomVisibleChangesClient(
      workflowServiceBaseUri: remoteServices.workflowServiceBaseUri,
      session: remoteServices.session,
      httpClient: httpClient,
    ),
  );
}

@visibleForTesting
void resetLoomOfflineReplicaSupportForTesting() {
  _loomWorkflowReplicaCoordinator?.dispose();
  _loomWorkflowReplicaCoordinator = null;
}
