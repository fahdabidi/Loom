import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:shelf/shelf.dart';

import 'definition_validation.dart';
import 'identity.dart';

/// Shelf HTTP adapter for the workflow-engine OpenAPI surface.
///
/// Phase B.2 implements definition replacement and authoritative reads in
/// addition to Phase B.1's transition mutation. `createInstance` remains an
/// explicit 501 until App Access role resolution is available.
class WorkflowService {
  static const _jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final Random _secureRandom = Random.secure();
  static const _unresolvedRoleId = '\u0000loom-role-resolution-pending';

  final WorkflowDatabase _database;
  final WorkflowIdentityExtractor _identityExtractor;
  final Map<String, LocalWorkflowEngineApi> _engines = {};

  // WorkflowDatabase's transaction boundary uses one externally-owned
  // PostgreSQL connection. Keep whole transitions sequential so statements
  // from two HTTP requests cannot interleave between BEGIN and COMMIT.
  final _SerialExecutor _databaseSerialExecutor = _SerialExecutor();

  WorkflowService({
    required WorkflowDatabase database,
    required WorkflowIdentityExtractor identityExtractor,
  }) : _database = database,
       _identityExtractor = identityExtractor;

  Handler get handler => _handle;

  Future<Response> _handle(Request request) async {
    final segments = request.url.pathSegments;

    if (_matchesCollection(segments, 'workflow-definitions') &&
        request.method == 'PUT') {
      return _replaceWorkflowDefinitions(request, segments[2]);
    }
    if (_matchesCollection(segments, 'instances')) {
      if (request.method == 'GET') {
        return _queryInstances(request, segments[2]);
      }
      if (request.method == 'POST') {
        return _notImplemented(request, 'createInstance');
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
        // Phase B.3 replaces this fail-closed placeholder with roles resolved
        // by App Access. A fan id must never be treated as a claimed role id.
        engine.setPersonaType(identity.fanId, _unresolvedRoleId);
        final page = await engine.queryInstances(
          tabId: 'workflow-service',
          personaId: identity.fanId,
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
        engine.setPersonaType(identity.fanId, _unresolvedRoleId);
        final instance = await engine.readVisibleInstance(
          instanceId: instanceId,
          personaId: identity.fanId,
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
          personaId: identity.fanId,
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
        final result = await engine.applyTransition(
          workflowType: before.workflowType,
          instanceId: instanceId,
          transitionId: body.transitionId,
          personaId: identity.fanId,
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

  Response _notImplemented(Request request, String operationId) => _error(
    request: request,
    statusCode: 501,
    code: 'operation_not_implemented',
    message: '$operationId is declared but not implemented in Phase B.1.',
  );

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
