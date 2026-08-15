import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:shelf/shelf.dart';

import 'identity.dart';

/// Shelf HTTP adapter for the workflow-engine OpenAPI surface.
///
/// Phase B.1 implements only `applyTransition`. The other four declared
/// operations return explicit 501 responses so callers cannot mistake an
/// omitted route for a different failure.
class WorkflowService {
  static const _jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final Random _secureRandom = Random.secure();

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
      return _notImplemented(request, 'replaceWorkflowDefinitions');
    }
    if (_matchesCollection(segments, 'instances')) {
      if (request.method == 'GET') {
        return _notImplemented(request, 'queryInstances');
      }
      if (request.method == 'POST') {
        return _notImplemented(request, 'createInstance');
      }
    }
    if (_matchesInstanceAction(segments, 'available-transitions') &&
        request.method == 'GET') {
      return _notImplemented(request, 'availableTransitions');
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
