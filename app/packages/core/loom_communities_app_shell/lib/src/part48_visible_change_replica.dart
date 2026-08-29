part of '../loom_communities_app_shell.dart';

/// One full workflow instance snapshot supplied by the visible-change feed.
///
/// This is deliberately a transport model rather than an engine model: the
/// feed includes server timestamps used for its cursor, while
/// [WorkflowInstance] intentionally does not expose timestamps to cards.
final class LoomVisibleWorkflowInstanceSnapshot {
  const LoomVisibleWorkflowInstanceSnapshot({
    required this.instanceId,
    required this.workflowType,
    required this.currentState,
    required this.instanceData,
    required this.updatedAt,
    this.createdAt,
    this.createdByFanId,
  });

  factory LoomVisibleWorkflowInstanceSnapshot.fromJson(
    Map<String, Object?> json,
  ) {
    final instanceData = json['instanceData'];
    if (json['instanceId'] is! String ||
        json['workflowType'] is! String ||
        json['currentState'] is! String ||
        instanceData is! Map ||
        json['updatedAt'] is! int ||
        json.containsKey('createdAt') && json['createdAt'] is! int ||
        json.containsKey('createdByFanId') &&
            json['createdByFanId'] is! String) {
      throw const FormatException(
        'Workflow change snapshot has an invalid response shape.',
      );
    }
    final instanceId = json['instanceId']! as String;
    final workflowType = json['workflowType']! as String;
    final currentState = json['currentState']! as String;
    if (instanceId.isEmpty || workflowType.isEmpty || currentState.isEmpty) {
      throw const FormatException(
        'Workflow change snapshot contains an empty required identifier.',
      );
    }
    return LoomVisibleWorkflowInstanceSnapshot(
      instanceId: instanceId,
      workflowType: workflowType,
      currentState: currentState,
      instanceData: Map<String, dynamic>.from(instanceData),
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt']! as int,
      createdByFanId: json['createdByFanId'] as String?,
    );
  }

  final String instanceId;
  final String workflowType;
  final String currentState;
  final Map<String, dynamic> instanceData;
  final int? createdAt;
  final int updatedAt;
  final String? createdByFanId;
}

/// A page from `GET /v1/communities/{communityId}/changes`.
final class LoomVisibleChangePage {
  LoomVisibleChangePage({
    required this.communityId,
    required List<LoomVisibleWorkflowInstanceSnapshot> changed,
    required Set<String> visibleInstanceIds,
    required this.nextUpdatedSince,
    required this.nextAfterInstanceId,
    required this.nextRoleCursor,
    required this.hasMore,
    required this.resyncRequired,
  }) : changed = List.unmodifiable(changed),
       visibleInstanceIds = Set.unmodifiable(visibleInstanceIds);

  factory LoomVisibleChangePage.fromJson(Map<String, Object?> json) {
    final changed = json['changed'];
    final visibleInstanceIds = json['visibleInstanceIds'];
    if (json['communityId'] is! String ||
        changed is! List ||
        visibleInstanceIds is! List ||
        json['nextUpdatedSince'] is! int ||
        json['nextAfterInstanceId'] is! String ||
        json['nextRoleCursor'] is! String ||
        json['hasMore'] is! bool ||
        json['resyncRequired'] is! bool) {
      throw const FormatException(
        'Visible change page has an invalid response shape.',
      );
    }
    final snapshots = changed
        .map(
          (value) => LoomVisibleWorkflowInstanceSnapshot.fromJson(
            _visibleChangeObject(value, 'Visible change page.changed'),
          ),
        )
        .toList(growable: false);
    final changedIds = <String>{};
    for (final snapshot in snapshots) {
      if (!changedIds.add(snapshot.instanceId)) {
        throw const FormatException(
          'Visible change page contains duplicate changed instance ids.',
        );
      }
    }
    final ids = <String>{};
    for (final value in visibleInstanceIds) {
      if (value is! String || value.isEmpty || !ids.add(value)) {
        throw const FormatException(
          'visibleInstanceIds must contain unique, non-empty strings.',
        );
      }
    }
    if (!ids.containsAll(changedIds)) {
      throw const FormatException(
        'Every changed instance must be present in visibleInstanceIds.',
      );
    }
    final communityId = json['communityId']! as String;
    if (communityId.isEmpty) {
      throw const FormatException(
        'Visible change page has an empty communityId.',
      );
    }
    return LoomVisibleChangePage(
      communityId: communityId,
      changed: snapshots,
      visibleInstanceIds: ids,
      nextUpdatedSince: json['nextUpdatedSince']! as int,
      nextAfterInstanceId: json['nextAfterInstanceId']! as String,
      nextRoleCursor: json['nextRoleCursor']! as String,
      hasMore: json['hasMore']! as bool,
      resyncRequired: json['resyncRequired']! as bool,
    );
  }

  final String communityId;
  final List<LoomVisibleWorkflowInstanceSnapshot> changed;

  /// The complete current server-authorized id set for this viewer.
  final Set<String> visibleInstanceIds;
  final int nextUpdatedSince;
  final String nextAfterInstanceId;

  /// Opaque role-set binding for the cursor. This client never interprets it.
  final String nextRoleCursor;
  final bool hasMore;
  final bool resyncRequired;
}

/// Failure returned while fetching the server-authoritative change feed.
final class LoomVisibleChangesException implements Exception {
  const LoomVisibleChangesException(
    this.message, {
    this.statusCode,
    this.body = '',
  });

  final String message;
  final int? statusCode;
  final String body;

  bool get isUnavailable => statusCode == null || statusCode! >= 500;

  @override
  String toString() =>
      'LoomVisibleChangesException(${statusCode ?? 'unavailable'}): $message'
      '${body.isEmpty ? '' : ' -- $body'}';
}

/// HTTP client for the viewer-scoped workflow change feed.
///
/// It deliberately accepts no fan identifier. The service derives the viewer
/// from [session]'s bearer token, which is the only identity whose visibility
/// decision may populate a replica.
final class LoomVisibleChangesClient {
  LoomVisibleChangesClient({
    required Uri workflowServiceBaseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(workflowServiceBaseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  Future<LoomVisibleChangePage> listVisibleChanges({
    required String communityId,
    WorkflowReplicaCursor? cursor,
  }) async {
    if (communityId.trim().isEmpty) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }
    if (cursor != null) {
      if (cursor.communityId != communityId) {
        throw ArgumentError.value(
          cursor,
          'cursor',
          'must belong to the requested community',
        );
      }
      if ((cursor.nextUpdatedSince == null) !=
          (cursor.nextAfterInstanceId == null)) {
        throw ArgumentError.value(
          cursor,
          'cursor',
          'must contain updatedSince and afterInstanceId together',
        );
      }
    }
    final queryParameters = <String, String>{
      if (cursor?.nextUpdatedSince != null)
        'updatedSince': '${cursor!.nextUpdatedSince}',
      if (cursor?.nextAfterInstanceId != null)
        'afterInstanceId': cursor!.nextAfterInstanceId!,
      if (cursor?.nextRoleCursor != null) 'roleCursor': cursor!.nextRoleCursor!,
    };
    final uri = _changeUri(communityId).replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final token = await _session.currentAccessToken();
    if (token.trim().isEmpty) {
      throw const LoomVisibleChangesException(
        'Sign in is required before offline data can be refreshed.',
      );
    }
    final request = http.Request('GET', uri)
      ..headers.addAll(<String, String>{
        'authorization': 'Bearer $token',
        'accept': 'application/json',
        'x-loom-correlation-id': _newUuidV4(),
      });
    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on Exception catch (error) {
      throw LoomVisibleChangesException(
        'Could not reach the workflow service to refresh offline data: $error',
      );
    }
    if (response.statusCode != 200) {
      throw LoomVisibleChangesException(
        'GET $uri failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('Visible change page is not valid JSON.');
    }
    final page = LoomVisibleChangePage.fromJson(
      _visibleChangeObject(decoded, 'Visible change page'),
    );
    if (page.communityId != communityId) {
      throw FormatException(
        'Visible change page was for "${page.communityId}", not "$communityId".',
      );
    }
    return page;
  }

  void close() => _httpClient.close();

  Uri _changeUri(String communityId) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/changes',
  );
}

/// A persistent, server-fed workflow replica for exactly one fan/community.
///
/// The [databasePath] must name a file dedicated to that pair. The database
/// also records the owner, so accidentally passing an existing replica path
/// for another fan or community fails instead of sharing its rows.
final class LoomWorkflowReplica {
  LoomWorkflowReplica._({
    required WorkflowDatabase database,
    required this.databasePath,
    required this.fanId,
    required this.communityId,
  }) : _database = database,
       engine = ReadOnlyWorkflowReplicaApi._(
         database: database,
         fanId: fanId,
         communityId: communityId,
       );

  static Future<LoomWorkflowReplica> openFile({
    required String databasePath,
    required String fanId,
    required String communityId,
  }) async {
    if (databasePath.trim().isEmpty) {
      throw ArgumentError.value(
        databasePath,
        'databasePath',
        'must not be empty',
      );
    }
    final database = WorkflowDatabase.file(databasePath);
    try {
      await database.claimReplica(fanId: fanId, communityId: communityId);
    } catch (_) {
      database.close();
      rethrow;
    }
    return LoomWorkflowReplica._(
      database: database,
      databasePath: databasePath,
      fanId: fanId,
      communityId: communityId,
    );
  }

  final WorkflowDatabase _database;
  final String databasePath;
  final String fanId;
  final String communityId;

  /// The API to give an offline view. It has no local mutation path.
  final ReadOnlyWorkflowReplicaApi engine;

  Future<WorkflowReplicaCursor> get cursor =>
      _database.readReplicaCursor(fanId: fanId, communityId: communityId);

  /// Refreshes pages until the service reports a complete current window.
  ///
  /// A role-invalidated cursor clears this database before making the next
  /// request with no cursor. The server, never this replica, remains the only
  /// writer of workflow state.
  Future<void> sync(LoomVisibleChangesClient client) async {
    while (true) {
      final storedCursor = await cursor;
      final page = await client.listVisibleChanges(
        communityId: communityId,
        cursor: storedCursor.isInitial ? null : storedCursor,
      );
      if (page.resyncRequired) {
        await _database.clearReplica(fanId: fanId, communityId: communityId);
        continue;
      }
      await _database.replaceReplicaPage(
        fanId: fanId,
        communityId: communityId,
        snapshots: page.changed
            .map(
              (snapshot) => WorkflowInstanceRow(
                instanceId: snapshot.instanceId,
                communityId: communityId,
                workflowType: snapshot.workflowType,
                currentState: snapshot.currentState,
                instanceData: jsonEncode(snapshot.instanceData),
                // The API intentionally makes creation metadata optional. It
                // is not used for replica visibility, so its only required
                // storage representation is a stable non-null timestamp/id.
                createdAt: snapshot.createdAt ?? snapshot.updatedAt,
                updatedAt: snapshot.updatedAt,
                createdByFanId: snapshot.createdByFanId ?? '',
              ),
            )
            .toList(growable: false),
        visibleInstanceIds: page.visibleInstanceIds,
        nextUpdatedSince: page.nextUpdatedSince,
        nextAfterInstanceId: page.nextAfterInstanceId,
        nextRoleCursor: page.nextRoleCursor,
      );
      if (!page.hasMore) return;
    }
  }

  void close() => _database.close();
}

/// A [WorkflowEngineApi] that only serves rows the server already authorized.
///
/// It intentionally does not load definitions or rerun read guards. Applying
/// visibility locally would either duplicate a server security decision or
/// make the replica disappear when an offline role lookup is stale.
final class ReadOnlyWorkflowReplicaApi implements WorkflowEngineApi {
  ReadOnlyWorkflowReplicaApi._({
    required WorkflowDatabase database,
    required this.fanId,
    required this.communityId,
  }) : _database = database;

  static const offlineWriteMessage =
      'Offline browsing is read-only. Reconnect to make changes.';

  final WorkflowDatabase _database;
  final String fanId;
  final String communityId;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String fanId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) async {
    _requireOwner(fanId);
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
    // [tabId] is deliberately not interpreted here. It is a UI routing value,
    // not an authorization rule, and the server already determined the rows
    // this fan may read. The same applies to SurfaceQuery's audience fields.
    final sortKey = query.sort?.key ?? 'title';
    final rows = await _database.queryInstancesKeyset(
      communityId: communityId,
      cursor: cursor,
      limit: limit,
      sortKey: sortKey,
    );
    final items = rows
        .take(limit)
        .map(_instanceFromReplicaRow)
        .toList(growable: false);
    final hasMore = rows.length > limit;
    return InstancePage(
      items: items,
      hasMore: hasMore,
      nextCursor: hasMore && items.isNotEmpty
          ? _cursorForRow(sortKey, rows[limit - 1])
          : null,
    );
  }

  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) {
    _requireOwner(fanId);
    // No transitions are exposed for a replica. Any direct attempt to apply
    // one below fails with [offlineWriteMessage] rather than doing nothing.
    return const <LoomWorkflowTransition>[];
  }

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) async {
    _requireOwner(fanId);
    return const <LoomWorkflowTransition>[];
  }

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
  }) async => _refuseWrite<WorkflowTransitionResult>(fanId);

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String fanId,
  }) async => _refuseWrite<String>(fanId);

  @override
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String fanId,
  }) async => _refuseWrite<List<String>>(fanId);

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String fanId,
  }) async => _refuseWrite<void>(fanId);

  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? fanId,
  }) async {
    if (fanId != null) _requireOwner(fanId);
    const supported = {'count', 'sum', 'avg', 'min', 'max', 'countDistinct'};
    if (!supported.contains(op)) {
      throw ArgumentError.value(op, 'op', 'Unsupported aggregate operation');
    }
    final rows = await _database.queryInstancesKeyset(
      communityId: communityId,
      limit: 1 << 30,
      sortKey: 'instanceId',
    );
    final data = rows
        .where((row) => row.workflowType == workflowType)
        .map((row) {
          final instanceData = _instanceDataFromReplicaRow(row);
          return <String, dynamic>{
            ...instanceData,
            r'$state': row.currentState,
            r'$id': row.instanceId,
          };
        })
        .where(
          (row) =>
              filter == null ||
              filter.entries.every((entry) => row[entry.key] == entry.value),
        )
        .toList(growable: false);
    if (groupBy == null) {
      return aggregateValues(data.map((row) => row[column]), op);
    }
    final groups = <dynamic, List<dynamic>>{};
    for (final row in data) {
      groups.putIfAbsent(row[groupBy], () => <dynamic>[]).add(row[column]);
    }
    return groups.entries
        .map(
          (entry) => <String, dynamic>{
            groupBy: entry.key,
            op: aggregateValues(entry.value, op),
          },
        )
        .toList(growable: false);
  }

  @override
  Future<List<WorkflowInstance>> dueNotifications({
    required DateTime asOf,
  }) async {
    final rows = await _database.queryInstancesKeyset(
      communityId: communityId,
      limit: 1 << 30,
      sortKey: 'dueAt',
    );
    return rows
        .map(_instanceFromReplicaRow)
        .where((instance) {
          final dueAt = instance.instanceData['dueAt'];
          return dueAt is String &&
              DateTime.tryParse(dueAt)?.isBefore(asOf) == true;
        })
        .toList(growable: false);
  }

  Never _refuseWrite<T>(String requestedFanId) {
    _requireOwner(requestedFanId);
    throw StateError(offlineWriteMessage);
  }

  void _requireOwner(String requestedFanId) {
    if (requestedFanId == fanId) return;
    throw StateError(
      'This offline copy belongs to another member and cannot be opened here.',
    );
  }

  WorkflowInstance _instanceFromReplicaRow(WorkflowInstanceRow row) =>
      WorkflowInstance(
        instanceId: row.instanceId,
        workflowType: row.workflowType,
        currentState: row.currentState,
        instanceData: _instanceDataFromReplicaRow(row),
        createdByFanId: row.createdByFanId,
      );

  Map<String, dynamic> _instanceDataFromReplicaRow(WorkflowInstanceRow row) {
    final decoded = jsonDecode(row.instanceData);
    if (decoded is! Map) {
      throw StateError(
        'Offline replica instance ${row.instanceId} is corrupt.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _cursorForRow(String sortKey, WorkflowInstanceRow row) {
    final cursorValue = '${_instanceDataFromReplicaRow(row)[sortKey] ?? ''}';
    return '$sortKey\x1f$cursorValue\x1f${row.instanceId}';
  }
}

Map<String, Object?> _visibleChangeObject(Object? value, String source) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('$source must be a JSON object.');
}
