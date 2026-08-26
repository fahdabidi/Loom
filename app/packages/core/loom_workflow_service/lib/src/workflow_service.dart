import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:shelf/shelf.dart';

import 'app_access_client.dart';
import 'community_group_id_resolver.dart';
import 'definition_validation.dart';
import 'identity.dart';

/// Shelf HTTP adapter for the workflow-engine OpenAPI surface.
///
/// Implements the workflow-engine OpenAPI operations over the shared engine,
/// with instance creation authorized by the live App Access service.
class WorkflowService {
  static const _appId = 'loom_communities';
  static const _jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final Random _secureRandom = Random.secure();
  static const _supportedAggregateOperations = {
    'count',
    'sum',
    'avg',
    'min',
    'max',
    'countDistinct',
  };

  final WorkflowDatabase _database;
  final WorkflowIdentityExtractor _identityExtractor;
  final AppAccessDecisionClient _appAccessClient;
  final CommunityGroupIdResolver _communityGroupIdResolver;
  final Map<String, LocalWorkflowEngineApi> _engines = {};

  // WorkflowDatabase's transaction boundary uses one externally-owned
  // PostgreSQL connection. Keep whole transitions sequential so statements
  // from two HTTP requests cannot interleave between BEGIN and COMMIT.
  final _SerialExecutor _databaseSerialExecutor = _SerialExecutor();

  WorkflowService({
    required WorkflowDatabase database,
    required WorkflowIdentityExtractor identityExtractor,
    required AppAccessDecisionClient appAccessClient,
    required CommunityGroupIdResolver communityGroupIdResolver,
  }) : _database = database,
       _identityExtractor = identityExtractor,
       _appAccessClient = appAccessClient,
       _communityGroupIdResolver = communityGroupIdResolver;

  Handler get handler => _handle;

  Future<Response> _handle(Request request) async {
    final segments = request.url.pathSegments;

    if (_matchesCollection(segments, 'workflow-definitions') &&
        request.method == 'PUT') {
      return _replaceWorkflowDefinitions(request, segments[2]);
    }
    if (_matchesInstancesBatch(segments) && request.method == 'POST') {
      return _createInstances(request, segments[2]);
    }
    if (_matchesInstancesAggregate(segments) && request.method == 'POST') {
      return _aggregate(request, segments[2]);
    }
    if (_matchesCollection(segments, 'instances')) {
      if (request.method == 'GET') {
        return _queryInstances(request, segments[2]);
      }
      if (request.method == 'POST') {
        return _createInstance(request, segments[2]);
      }
    }
    if (_matchesInstanceAction(segments, 'available-transitions') &&
        request.method == 'GET') {
      return _availableTransitions(request, segments[2], segments[4]);
    }
    if (_matchesInstanceAction(segments, 'transitions') &&
        request.method == 'POST') {
      return _applyTransition(request, segments[2], segments[4]);
    }
    if (_matchesInstanceAction(segments, 'fields') &&
        request.method == 'PATCH') {
      return _updateInstanceFields(request, segments[2], segments[4]);
    }

    return _error(
      request: request,
      statusCode: 404,
      code: 'route_not_found',
      message: 'The requested workflow-service route does not exist.',
    );
  }

  bool _matchesCollection(List<String> segments, String collection) =>
      segments.length == 4 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == collection;

  bool _matchesInstancesBatch(List<String> segments) =>
      segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4] == 'batch';

  bool _matchesInstancesAggregate(List<String> segments) =>
      segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4] == 'aggregate';

  bool _matchesInstanceAction(List<String> segments, String action) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4].isNotEmpty &&
      segments[5] == action;

  Future<Response> _replaceWorkflowDefinitions(
    Request request,
    String communityId,
  ) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null ||
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 200) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key must contain between 8 and 200 characters.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _ReplaceWorkflowDefinitionsBody body;
    try {
      body = await _readReplaceWorkflowDefinitionsBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    if (!supportedWorkflowSpecVersions.contains(body.specVersion)) {
      return _workflowDefinitionsSummary(
        statusCode: 422,
        communityId: communityId,
        specVersion: body.specVersion,
        workflowTypes: body.definitions.keys,
        findings: [
          WorkflowDefinitionFinding(
            code: 'unsupported_spec_version',
            message:
                'specVersion ${body.specVersion} is not implemented by this '
                'service.',
          ),
        ],
        correlationId: correlationId,
      );
    }

    try {
      for (final entry in body.definitions.entries) {
        LoomWorkflowStateMachine.fromJson(entry.value, entry.key);
      }
    } catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: 'A workflow definition is structurally invalid: $error',
      );
    }
    final referenceError = _definitionReferenceStructureError(body.definitions);
    if (referenceError != null) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: referenceError,
      );
    }

    final findings = validateExecutableDefinitions(body.definitions);
    if (findings.isNotEmpty) {
      return _workflowDefinitionsSummary(
        statusCode: 422,
        communityId: communityId,
        specVersion: body.specVersion,
        workflowTypes: body.definitions.keys,
        findings: findings,
        correlationId: correlationId,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final removed = await _authoritativeEngine(communityId)
            .replaceDefinitions(
              definitions: body.definitions,
              version: body.specVersion,
            );
        return _workflowDefinitionsSummary(
          statusCode: 200,
          communityId: communityId,
          specVersion: body.specVersion,
          workflowTypes: body.definitions.keys,
          removedWorkflowTypes: removed,
          findings: const [],
          correlationId: correlationId,
        );
      });
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow definitions could not be replaced.',
      );
    }
  }

  Future<_ReplaceWorkflowDefinitionsBody> _readReplaceWorkflowDefinitionsBody(
    Request request,
  ) async {
    final decoded = await _readJsonObject(request);
    final specVersion = decoded['specVersion'];
    if (specVersion is! int) {
      throw const FormatException('specVersion must be an integer.');
    }
    final rawDefinitions = decoded['definitions'];
    if (rawDefinitions is! Map<String, dynamic>) {
      throw const FormatException('definitions must be a JSON object.');
    }

    final definitions = <String, Map<String, dynamic>>{};
    for (final entry in rawDefinitions.entries) {
      if (entry.key.trim().isEmpty || entry.value is! Map<String, dynamic>) {
        throw const FormatException(
          'Every definition must have a non-empty type and an object value.',
        );
      }
      final definition = entry.value as Map<String, dynamic>;
      definitions[entry.key] = definition;
    }
    return _ReplaceWorkflowDefinitionsBody(
      specVersion: specVersion,
      definitions: definitions,
    );
  }

  String? _definitionReferenceStructureError(
    Map<String, Map<String, dynamic>> definitions,
  ) {
    for (final entry in definitions.entries) {
      final states = entry.value['states'] as Map<String, dynamic>;
      final initialState = entry.value['initialState'] as String;
      if (!states.containsKey(initialState)) {
        return 'Workflow "${entry.key}" initialState "$initialState" is not '
            'declared in states.';
      }

      final transitionIds = <String>{};
      for (final rawTransition in entry.value['transitions'] as List<dynamic>) {
        final transition = rawTransition as Map<String, dynamic>;
        final transitionId = transition['id'] as String;
        if (!transitionIds.add(transitionId)) {
          return 'Workflow "${entry.key}" declares transition '
              '"$transitionId" more than once.';
        }
        for (final source in transition['from'] as List<dynamic>) {
          if (!states.containsKey(source)) {
            return 'Transition "$transitionId" of workflow "${entry.key}" '
                'references unknown source state "$source".';
          }
        }
        final target = transition['to'];
        if (target != null && !states.containsKey(target)) {
          return 'Transition "$transitionId" of workflow "${entry.key}" '
              'references unknown target state "$target".';
        }
      }
    }
    return null;
  }

  Future<Response> _createInstance(Request request, String communityId) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null ||
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 200) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key must contain between 8 and 200 characters.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _CreateInstanceBody body;
    try {
      body = await _readCreateInstanceBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final definitions = await _database.loadDefinitionsForCommunity(
          communityId,
        );
        if (!definitions.containsKey(body.workflowType)) {
          return _error(
            request: request,
            statusCode: 404,
            code: 'workflow_type_not_found',
            message: 'The requested workflow type was not found.',
          );
        }

        const resolver = ArchetypeResolver();
        final archetype = resolver.resolveAll(definitions)[body.workflowType];
        if (archetype?.origin == ArchetypeOrigin.inheritedFromResponseTable) {
          return _createRefused(request);
        }
        final family = archetype?.family;
        final permissionId = family == null
            ? null
            : resolver.permissionId(family, 'create');
        if (permissionId == null ||
            archetype!.conflictingBespokeFamilies.isNotEmpty) {
          return _createRefused(request);
        }

        final groupId = await _communityGroupIdResolver.resolveGroupId(
          communityId,
        );
        if (groupId == null || groupId.trim().isEmpty) {
          return _error(
            request: request,
            statusCode: 503,
            code: 'authorization_service_unavailable',
            message: 'Workflow creation authorization is unavailable.',
          );
        }

        final allowed = await _appAccessClient.checkAccess(
          fanId: identity.fanId,
          appId: _appId,
          permissionId: permissionId,
          groupId: groupId,
          correlationId: correlationId,
        );
        if (!allowed) return _createRefused(request);

        final instanceId = await _authoritativeEngine(communityId)
            .createInstance(
              workflowType: body.workflowType,
              initialInstanceData: body.instanceData,
              fanId: identity.fanId,
            );
        final created = await _database.readInstance(instanceId);
        if (created == null) {
          throw StateError(
            'Workflow instance disappeared after successful creation',
          );
        }
        return Response(
          201,
          body: jsonEncode({
            'instanceId': created.instanceId,
            'workflowType': created.workflowType,
            'currentState': created.currentState,
            'instanceData': jsonDecode(created.instanceData),
            'updatedAt': DateTime.fromMillisecondsSinceEpoch(
              created.updatedAt,
              isUtc: true,
            ).toIso8601String(),
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } on AppAccessDecisionException catch (_) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'authorization_service_unavailable',
        message: 'Workflow creation authorization is unavailable.',
      );
    } on SocketException catch (_) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'authorization_service_unavailable',
        message: 'Workflow creation authorization is unavailable.',
      );
    } on WorkflowValidationError catch (_) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: 'The workflow instance data is invalid.',
      );
    } on StateError catch (error) {
      final message = '${error.message}';
      if (message.startsWith('Creation of ')) return _createRefused(request);
      if (message.startsWith('Unknown workflow type:')) {
        return _error(
          request: request,
          statusCode: 404,
          code: 'workflow_type_not_found',
          message: 'The requested workflow type was not found.',
        );
      }
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instance could not be created.',
      );
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instance could not be created.',
      );
    }
  }

  Future<_CreateInstanceBody> _readCreateInstanceBody(Request request) async {
    final decoded = await _readJsonObject(request);
    final workflowType = decoded['workflowType'];
    if (workflowType is! String || workflowType.trim().isEmpty) {
      throw const FormatException('workflowType must be a non-empty string.');
    }
    final rawInstanceData = decoded['instanceData'];
    if (rawInstanceData != null && rawInstanceData is! Map<String, dynamic>) {
      throw const FormatException('instanceData must be a JSON object.');
    }
    return _CreateInstanceBody(
      workflowType: workflowType,
      instanceData: rawInstanceData as Map<String, dynamic>? ?? const {},
    );
  }

  Response _createRefused(Request request) => _error(
    request: request,
    statusCode: 403,
    code: 'workflow_create_refused',
    message: 'The workflow instance cannot be created by this caller.',
  );

  Future<Response> _createInstances(Request request, String communityId) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null ||
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 200) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key must contain between 8 and 200 characters.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _CreateInstancesBody body;
    try {
      body = await _readCreateInstancesBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final definitions = await _database.loadDefinitionsForCommunity(
          communityId,
        );
        if (!definitions.containsKey(body.workflowType)) {
          return _error(
            request: request,
            statusCode: 404,
            code: 'workflow_type_not_found',
            message: 'The requested workflow type was not found.',
          );
        }

        const resolver = ArchetypeResolver();
        final archetype = resolver.resolveAll(definitions)[body.workflowType];
        if (archetype?.origin == ArchetypeOrigin.inheritedFromResponseTable) {
          return _createRefused(request);
        }
        final family = archetype?.family;
        final permissionId = family == null
            ? null
            : resolver.permissionId(family, 'create');
        if (permissionId == null ||
            archetype!.conflictingBespokeFamilies.isNotEmpty) {
          return _createRefused(request);
        }

        final groupId = await _communityGroupIdResolver.resolveGroupId(
          communityId,
        );
        if (groupId == null || groupId.trim().isEmpty) {
          return _error(
            request: request,
            statusCode: 503,
            code: 'authorization_service_unavailable',
            message: 'Workflow creation authorization is unavailable.',
          );
        }

        final allowed = await _appAccessClient.checkAccess(
          fanId: identity.fanId,
          appId: _appId,
          permissionId: permissionId,
          groupId: groupId,
          correlationId: correlationId,
        );
        if (!allowed) return _createRefused(request);

        final instanceIds = await _authoritativeEngine(communityId)
            .createInstances(
              workflowType: body.workflowType,
              initialInstanceDataList: body.initialInstanceDataList,
              fanId: identity.fanId,
            );
        final created = <Map<String, dynamic>>[];
        for (final instanceId in instanceIds) {
          final instance = await _database.readInstance(instanceId);
          if (instance == null) {
            throw StateError(
              'Workflow instance disappeared after successful creation',
            );
          }
          created.add({
            'instanceId': instance.instanceId,
            'workflowType': instance.workflowType,
            'currentState': instance.currentState,
            'instanceData': jsonDecode(instance.instanceData),
            'updatedAt': DateTime.fromMillisecondsSinceEpoch(
              instance.updatedAt,
              isUtc: true,
            ).toIso8601String(),
          });
        }
        return Response(
          201,
          body: jsonEncode(created),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } on AppAccessDecisionException catch (_) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'authorization_service_unavailable',
        message: 'Workflow creation authorization is unavailable.',
      );
    } on SocketException catch (_) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'authorization_service_unavailable',
        message: 'Workflow creation authorization is unavailable.',
      );
    } on WorkflowValidationError catch (_) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: 'The workflow instance data is invalid.',
      );
    } on StateError catch (error) {
      final message = '${error.message}';
      if (message.startsWith('Creation of ')) return _createRefused(request);
      if (message.startsWith('Unknown workflow type:')) {
        return _error(
          request: request,
          statusCode: 404,
          code: 'workflow_type_not_found',
          message: 'The requested workflow type was not found.',
        );
      }
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instances could not be created.',
      );
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instances could not be created.',
      );
    }
  }

  Future<_CreateInstancesBody> _readCreateInstancesBody(Request request) async {
    final decoded = await _readJsonObject(request);
    final workflowType = decoded['workflowType'];
    if (workflowType is! String || workflowType.trim().isEmpty) {
      throw const FormatException('workflowType must be a non-empty string.');
    }
    final rawList = decoded['initialInstanceDataList'];
    if (rawList is! List<dynamic>) {
      throw const FormatException(
        'initialInstanceDataList must be a JSON array.',
      );
    }
    if (rawList.isEmpty) {
      throw const FormatException(
        'initialInstanceDataList must contain at least one item.',
      );
    }
    final initialInstanceDataList = <Map<String, dynamic>>[];
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Every initialInstanceDataList item must be a JSON object.',
        );
      }
      initialInstanceDataList.add(item);
    }
    return _CreateInstancesBody(
      workflowType: workflowType,
      initialInstanceDataList: initialInstanceDataList,
    );
  }

  Future<Response> _queryInstances(Request request, String communityId) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    final params = request.url.queryParameters;
    final rawLimit = params['limit'];
    final limit = rawLimit == null ? 25 : int.tryParse(rawLimit);
    if (limit == null || limit < 1 || limit > 100) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: 'limit must be an integer between 1 and 100.',
      );
    }

    final workflowType = params['workflowType'];
    final sortKey = params['sortKey'];
    if (workflowType != null && workflowType.trim().isEmpty ||
        sortKey != null && sortKey.trim().isEmpty) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: 'workflowType and sortKey must be non-empty when supplied.',
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final engine = _authoritativeEngine(communityId);
        final roleResolutionError = await _resolveRolesForRequest(
          request: request,
          communityId: communityId,
          identity: identity,
          correlationId: correlationId,
          engine: engine,
        );
        if (roleResolutionError != null) return roleResolutionError;
        final page = await engine.queryInstances(
          tabId: 'workflow-service',
          fanId: identity.fanId,
          workflowType: workflowType,
          query: SurfaceQuery(
            sort: sortKey == null ? null : SortSpec(key: sortKey),
          ),
          limit: limit,
          cursor: params['cursor'],
        );
        return Response.ok(
          jsonEncode({
            'items': page.items.map(_workflowInstanceJson).toList(),
            'pageInfo': {
              'hasMore': page.hasMore,
              'nextCursor': page.nextCursor,
            },
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } on StateError catch (error) {
      if ('${error.message}'.startsWith('Permission denied for surface')) {
        return _error(
          request: request,
          statusCode: 403,
          code: 'workflow_read_refused',
          message: 'The workflow collection is not available to this caller.',
        );
      }
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Workflow instances could not be queried.',
      );
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Workflow instances could not be queried.',
      );
    }
  }

  Future<Response> _aggregate(Request request, String communityId) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _AggregateBody body;
    try {
      body = await _readAggregateBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final engine = _authoritativeEngine(communityId);
        final roleResolutionError = await _resolveRolesForRequest(
          request: request,
          communityId: communityId,
          identity: identity,
          correlationId: correlationId,
          engine: engine,
        );
        if (roleResolutionError != null) return roleResolutionError;
        final result = await engine.aggregate(
          workflowType: body.workflowType,
          column: body.column,
          op: body.op,
          filter: body.filter,
          groupBy: body.groupBy,
          fanId: identity.fanId,
        );
        return Response.ok(
          jsonEncode({'result': result}),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Workflow instances could not be aggregated.',
      );
    }
  }

  Future<_AggregateBody> _readAggregateBody(Request request) async {
    final decoded = await _readJsonObject(request);
    final workflowType = decoded['workflowType'];
    if (workflowType is! String || workflowType.trim().isEmpty) {
      throw const FormatException('workflowType must be a non-empty string.');
    }
    final column = decoded['column'];
    if (column is! String || column.trim().isEmpty) {
      throw const FormatException('column must be a non-empty string.');
    }
    final op = decoded['op'];
    if (op is! String || !_supportedAggregateOperations.contains(op)) {
      throw const FormatException(
        'op must be a supported aggregate operation.',
      );
    }
    final filter = decoded['filter'];
    if (filter != null && filter is! Map<String, dynamic>) {
      throw const FormatException('filter must be a JSON object.');
    }
    final groupBy = decoded['groupBy'];
    if (groupBy != null && (groupBy is! String || groupBy.trim().isEmpty)) {
      throw const FormatException(
        'groupBy must be a non-empty string when supplied.',
      );
    }
    return _AggregateBody(
      workflowType: workflowType,
      column: column,
      op: op,
      filter: filter as Map<String, dynamic>?,
      groupBy: groupBy as String?,
    );
  }

  Future<Response> _availableTransitions(
    Request request,
    String communityId,
    String instanceId,
  ) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final engine = _authoritativeEngine(communityId);
        final roleResolutionError = await _resolveRolesForRequest(
          request: request,
          communityId: communityId,
          identity: identity,
          correlationId: correlationId,
          engine: engine,
        );
        if (roleResolutionError != null) return roleResolutionError;
        final instance = await engine.readVisibleInstance(
          instanceId: instanceId,
          fanId: identity.fanId,
        );
        if (instance == null) {
          return _error(
            request: request,
            statusCode: 404,
            code: 'workflow_instance_not_found',
            message: 'The requested workflow instance was not found.',
          );
        }

        final transitions = await engine.availableTransitionsAsync(
          workflowType: instance.workflowType,
          instanceId: instance.instanceId,
          currentState: instance.currentState,
          instanceData: instance.instanceData,
          fanId: identity.fanId,
        );
        return Response.ok(
          jsonEncode({
            'instanceId': instance.instanceId,
            'currentState': instance.currentState,
            'transitions': transitions.map(_availableTransitionJson).toList(),
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Available workflow transitions could not be resolved.',
      );
    }
  }

  LocalWorkflowEngineApi _authoritativeEngine(String communityId) {
    final engine = _engines.putIfAbsent(
      communityId,
      () => LocalWorkflowEngineApi(db: _database, communityId: communityId),
    );
    engine.setFailClosedOnMissingDefinition(true);
    return engine;
  }

  Future<Response?> _resolveRolesForRequest({
    required Request request,
    required String communityId,
    required WorkflowRequestIdentity identity,
    required String correlationId,
    required LocalWorkflowEngineApi engine,
  }) async {
    final groupId = await _communityGroupIdResolver.resolveGroupId(communityId);
    if (groupId == null || groupId.trim().isEmpty) {
      engine.setRolesForFan(identity.fanId, <String>{});
      return _authorizationServiceUnavailable(request);
    }

    try {
      final roleIds = await _appAccessClient.resolveRoleIds(
        fanId: identity.fanId,
        appId: _appId,
        groupId: groupId,
        correlationId: correlationId,
      );
      engine.setRolesForFan(identity.fanId, roleIds);
      return null;
    } on AppAccessDecisionException catch (_) {
      engine.setRolesForFan(identity.fanId, <String>{});
      return _authorizationServiceUnavailable(request);
    } on SocketException catch (_) {
      engine.setRolesForFan(identity.fanId, <String>{});
      return _authorizationServiceUnavailable(request);
    }
  }

  Response _authorizationServiceUnavailable(Request request) => _error(
    request: request,
    statusCode: 503,
    code: 'authorization_service_unavailable',
    message: 'Workflow creation authorization is unavailable.',
  );

  Map<String, dynamic> _workflowInstanceJson(WorkflowInstance instance) => {
    'instanceId': instance.instanceId,
    'workflowType': instance.workflowType,
    'currentState': instance.currentState,
    'instanceData': instance.instanceData,
  };

  Map<String, dynamic> _availableTransitionJson(
    LoomWorkflowTransition transition,
  ) => {
    'transitionId': transition.id,
    'label': transition.label,
    if (transition.action != null) 'action': transition.action,
    if (transition.tone != null) 'tone': transition.tone,
    if (transition.inputs != null)
      'inputs': transition.inputs!.map(
        (name, input) => MapEntry(name, {
          'type': input.type,
          'required': input.required,
          if (input.visibleWhen != null) 'visibleWhen': input.visibleWhen,
          if (input.options != null) 'options': input.options,
          if (input.modeGroup != null) 'modeGroup': input.modeGroup,
          if (input.modeValue != null) 'modeValue': input.modeValue,
          if (input.maxSelections != null) 'maxSelections': input.maxSelections,
          if (input.writesTo != null) 'writesTo': input.writesTo,
        }),
      ),
  };

  Future<Map<String, dynamic>> _readJsonObject(Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType == null ||
        !contentType.toLowerCase().startsWith('application/json')) {
      throw const FormatException('Content-Type must be application/json.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(await request.readAsString());
    } on JsonUnsupportedObjectError {
      throw const FormatException('Request body must be valid JSON.');
    } on FormatException {
      throw const FormatException('Request body must be valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return decoded;
  }

  Response _workflowDefinitionsSummary({
    required int statusCode,
    required String communityId,
    required int specVersion,
    required Iterable<String> workflowTypes,
    Iterable<String> removedWorkflowTypes = const [],
    required Iterable<WorkflowDefinitionFinding> findings,
    required String correlationId,
  }) {
    final sortedWorkflowTypes = workflowTypes.toList()..sort();
    final sortedRemovedWorkflowTypes = removedWorkflowTypes.toList()..sort();
    return Response(
      statusCode,
      body: jsonEncode({
        'communityId': communityId,
        'specVersion': specVersion,
        'workflowTypes': sortedWorkflowTypes,
        'removedWorkflowTypes': sortedRemovedWorkflowTypes,
        'findings': findings.map((finding) => finding.toJson()).toList(),
      }),
      headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
    );
  }

  Future<Response> _updateInstanceFields(
    Request request,
    String communityId,
    String instanceId,
  ) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null ||
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 200) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key must contain between 8 and 200 characters.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _UpdateInstanceFieldsBody body;
    try {
      body = await _readUpdateInstanceFieldsBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final before = await _database.readInstance(instanceId);
        if (before == null || before.communityId != communityId) {
          return _error(
            request: request,
            statusCode: 404,
            code: 'workflow_instance_not_found',
            message: 'The requested workflow instance was not found.',
          );
        }

        final engine = _engines.putIfAbsent(
          communityId,
          () => LocalWorkflowEngineApi(db: _database, communityId: communityId),
        );
        await engine.updateInstanceFields(
          workflowType: before.workflowType,
          instanceId: instanceId,
          fieldUpdates: body.fieldUpdates,
          fanId: identity.fanId,
        );
        final after = await _database.readInstance(instanceId);
        if (after == null) {
          throw StateError(
            'Workflow instance disappeared after a successful field update',
          );
        }

        return Response.ok(
          jsonEncode({
            'instanceId': after.instanceId,
            'workflowType': after.workflowType,
            'currentState': after.currentState,
            'instanceData': jsonDecode(after.instanceData),
            'updatedAt': DateTime.fromMillisecondsSinceEpoch(
              after.updatedAt,
              isUtc: true,
            ).toIso8601String(),
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } on WorkflowAuthorizationError catch (_) {
      return _error(
        request: request,
        statusCode: 403,
        code: 'workflow_field_edit_refused',
        message: 'The workflow fields cannot be edited by this caller.',
      );
    } on StateError catch (error) {
      final message = '${error.message}';
      if (message.startsWith('Instance ') ||
          message.startsWith('Unknown workflow type:')) {
        return _error(
          request: request,
          statusCode: 404,
          code: 'workflow_instance_not_found',
          message: 'The requested workflow instance was not found.',
        );
      }
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow fields could not be updated.',
      );
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow fields could not be updated.',
      );
    }
  }

  Future<_UpdateInstanceFieldsBody> _readUpdateInstanceFieldsBody(
    Request request,
  ) async {
    final decoded = await _readJsonObject(request);
    final fieldUpdates = decoded['fieldUpdates'];
    if (fieldUpdates is! Map<String, dynamic>) {
      throw const FormatException('fieldUpdates must be a JSON object.');
    }
    if (fieldUpdates.isEmpty) {
      throw const FormatException(
        'fieldUpdates must contain at least one field.',
      );
    }
    return _UpdateInstanceFieldsBody(fieldUpdates: fieldUpdates);
  }

  Future<Response> _applyTransition(
    Request request,
    String communityId,
    String instanceId,
  ) async {
    final correlationId = request.headers['x-loom-correlation-id'];
    if (correlationId == null || !_uuidPattern.hasMatch(correlationId)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_correlation_id',
        message: 'X-Loom-Correlation-Id must be a UUID.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null ||
        idempotencyKey.length < 8 ||
        idempotencyKey.length > 200) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key must contain between 8 and 200 characters.',
      );
    }

    final identity = await _identityExtractor.extract(request);
    if (identity == null) {
      return _error(
        request: request,
        statusCode: 401,
        code: 'authentication_required',
        message: 'An authenticated fan identity is required.',
      );
    }

    late final _ApplyTransitionBody body;
    try {
      body = await _readApplyTransitionBody(request);
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_request',
        message: error.message,
      );
    }

    try {
      return await _databaseSerialExecutor.run(() async {
        final before = await _database.readInstance(instanceId);
        if (before == null || before.communityId != communityId) {
          return _error(
            request: request,
            statusCode: 404,
            code: 'workflow_instance_not_found',
            message: 'The requested workflow instance was not found.',
          );
        }

        final engine = _engines.putIfAbsent(
          communityId,
          () => LocalWorkflowEngineApi(db: _database, communityId: communityId),
        );
        final roleResolutionError = await _resolveRolesForRequest(
          request: request,
          communityId: communityId,
          identity: identity,
          correlationId: correlationId,
          engine: engine,
        );
        if (roleResolutionError != null) return roleResolutionError;
        final result = await engine.applyTransition(
          workflowType: before.workflowType,
          instanceId: instanceId,
          transitionId: body.transitionId,
          fanId: identity.fanId,
          inputs: body.inputs,
        );
        final after = await _database.readInstance(instanceId);
        if (after == null) {
          throw StateError(
            'Workflow instance disappeared after a successful transition',
          );
        }

        return Response.ok(
          jsonEncode({
            'instanceId': instanceId,
            'workflowType': before.workflowType,
            'currentState': result.newState,
            'instanceData': result.newInstanceData,
            'updatedAt': DateTime.fromMillisecondsSinceEpoch(
              after.updatedAt,
              isUtc: true,
            ).toIso8601String(),
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } on StateError catch (error) {
      return _mapEngineStateError(request, error);
    } catch (_) {
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow transition could not be completed.',
      );
    }
  }

  Future<_ApplyTransitionBody> _readApplyTransitionBody(Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType == null ||
        !contentType.toLowerCase().startsWith('application/json')) {
      throw const FormatException('Content-Type must be application/json.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(await request.readAsString());
    } on JsonUnsupportedObjectError {
      throw const FormatException('Request body must be valid JSON.');
    } on FormatException {
      throw const FormatException('Request body must be valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Request body must be a JSON object.');
    }

    final transitionId = decoded['transitionId'];
    if (transitionId is! String || transitionId.trim().isEmpty) {
      throw const FormatException('transitionId must be a non-empty string.');
    }
    final rawInputs = decoded['inputs'];
    if (rawInputs != null && rawInputs is! Map<String, dynamic>) {
      throw const FormatException('inputs must be a JSON object.');
    }
    return _ApplyTransitionBody(
      transitionId: transitionId,
      inputs: rawInputs as Map<String, dynamic>?,
    );
  }

  Response _mapEngineStateError(Request request, StateError error) {
    final message = '${error.message}';
    if (message.contains('not available from state')) {
      return _error(
        request: request,
        statusCode: 409,
        code: 'workflow_state_conflict',
        message: 'The workflow instance is no longer in the required state.',
      );
    }
    if (message.contains('is not available for') ||
        message.startsWith('Permission denied for surface')) {
      return _error(
        request: request,
        statusCode: 403,
        code: 'workflow_guard_refused',
        message: 'The requested transition is not allowed.',
      );
    }
    if (message.startsWith('Instance ') ||
        message.startsWith('Unknown workflow type:')) {
      return _error(
        request: request,
        statusCode: 404,
        code: 'workflow_instance_not_found',
        message: 'The requested workflow instance was not found.',
      );
    }
    if (message.startsWith('Unknown transition ') ||
        message.contains(' requires input ')) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_transition_request',
        message: 'The transition request is invalid.',
      );
    }
    return _error(
      request: request,
      statusCode: 500,
      code: 'workflow_service_error',
      message: 'The workflow transition could not be completed.',
    );
  }

  Response _error({
    required Request request,
    required int statusCode,
    required String code,
    required String message,
  }) {
    final requestCorrelationId = request.headers['x-loom-correlation-id'];
    final correlationId =
        requestCorrelationId != null &&
            _uuidPattern.hasMatch(requestCorrelationId)
        ? requestCorrelationId
        : _newCorrelationId();
    return Response(
      statusCode,
      body: jsonEncode({
        'code': code,
        'message': message,
        'correlationId': correlationId,
      }),
      headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
    );
  }

  String _newCorrelationId() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class _ApplyTransitionBody {
  final String transitionId;
  final Map<String, dynamic>? inputs;

  const _ApplyTransitionBody({
    required this.transitionId,
    required this.inputs,
  });
}

class _UpdateInstanceFieldsBody {
  final Map<String, dynamic> fieldUpdates;

  const _UpdateInstanceFieldsBody({required this.fieldUpdates});
}

class _CreateInstanceBody {
  const _CreateInstanceBody({
    required this.workflowType,
    required this.instanceData,
  });

  final String workflowType;
  final Map<String, dynamic> instanceData;
}

class _CreateInstancesBody {
  const _CreateInstancesBody({
    required this.workflowType,
    required this.initialInstanceDataList,
  });

  final String workflowType;
  final List<Map<String, dynamic>> initialInstanceDataList;
}

class _AggregateBody {
  const _AggregateBody({
    required this.workflowType,
    required this.column,
    required this.op,
    required this.filter,
    required this.groupBy,
  });

  final String workflowType;
  final String column;
  final String op;
  final Map<String, dynamic>? filter;
  final String? groupBy;
}

class _ReplaceWorkflowDefinitionsBody {
  final int specVersion;
  final Map<String, Map<String, dynamic>> definitions;

  const _ReplaceWorkflowDefinitionsBody({
    required this.specVersion,
    required this.definitions,
  });
}

class _SerialExecutor {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
