import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/workflow_models.dart';
import 'local_workflow_engine_api.dart';
import 'workflow_engine_api.dart';

/// A server response that has no equivalent failure mode in the local engine.
abstract class RemoteWorkflowEngineException implements Exception {
  const RemoteWorkflowEngineException({
    required this.code,
    required this.message,
    this.statusCode,
    this.correlationId,
  });

  final String code;
  final String message;
  final int? statusCode;
  final String? correlationId;

  @override
  String toString() {
    final status = statusCode == null ? '' : ', HTTP $statusCode';
    final correlation = correlationId == null
        ? ''
        : ', correlationId: $correlationId';
    return 'Remote workflow error ($code$status$correlation): $message';
  }
}

/// The workflow service rejected or could not establish authentication.
class RemoteWorkflowAuthenticationError extends RemoteWorkflowEngineException {
  const RemoteWorkflowAuthenticationError({
    required super.code,
    required super.message,
    super.statusCode,
    super.correlationId,
  });
}

/// The client and workflow service disagreed about the HTTP/API contract.
class RemoteWorkflowProtocolError extends RemoteWorkflowEngineException {
  const RemoteWorkflowProtocolError({
    required super.code,
    required super.message,
    super.statusCode,
    super.correlationId,
  });
}

/// The remote workflow or authorization service was unavailable or failed.
class RemoteWorkflowServiceError extends RemoteWorkflowEngineException {
  const RemoteWorkflowServiceError({
    required super.code,
    required super.message,
    super.statusCode,
    super.correlationId,
  });
}

/// HTTP-backed [WorkflowEngineApi] for the deployed workflow service.
///
/// Identity is intentionally not accepted from method arguments. The service
/// derives the acting fan from the bearer token supplied by
/// [bearerTokenProvider]. Compatibility-only identity and rendering arguments
/// remain on the methods because they are part of [WorkflowEngineApi].
class RemoteWorkflowEngineApi implements WorkflowEngineApi {
  RemoteWorkflowEngineApi({
    required Uri baseUri,
    required String communityId,
    required this.bearerTokenProvider,
    required http.Client httpClient,
  }) : _baseUri = _normalizeBaseUri(baseUri),
       _communityId = _requireNonEmpty(communityId, 'communityId'),
       _httpClient = httpClient;

  final Uri _baseUri;
  final String _communityId;
  final http.Client _httpClient;
  final Future<String> Function() bearerTokenProvider;

  static final Random _secureRandom = Random.secure();

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    String? workflowType,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) async {
    final response = await _request(
      method: 'GET',
      pathSegments: _instanceCollectionSegments,
      queryParameters: {
        if (workflowType != null) 'workflowType': workflowType,
        if (query.sort != null) 'sortKey': query.sort!.key,
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
      },
      expectedStatusCodes: const {200},
    );
    final decoded = _decodeObject(response);
    final rawItems = decoded['items'];
    if (rawItems is! List<dynamic>) {
      throw _malformedResponse(response, 'items must be a JSON array.');
    }
    final pageInfo = decoded['pageInfo'];
    if (pageInfo != null && pageInfo is! Map<String, dynamic>) {
      throw _malformedResponse(response, 'pageInfo must be a JSON object.');
    }
    final pageInfoMap = pageInfo as Map<String, dynamic>?;
    final hasMore = pageInfoMap?['hasMore'] ?? false;
    final nextCursor = pageInfoMap?['nextCursor'];
    if (hasMore is! bool || nextCursor != null && nextCursor is! String) {
      throw _malformedResponse(
        response,
        'pageInfo has invalid hasMore or nextCursor values.',
      );
    }
    return InstancePage(
      items: rawItems
          .map(
            (item) => _decodeInstance(item, response, createdByPersonaId: ''),
          )
          .toList(),
      nextCursor: nextCursor as String?,
      hasMore: hasMore,
    );
  }

  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) {
    throw UnsupportedError(
      'RemoteWorkflowEngineApi cannot perform a network round trip from the '
      'synchronous availableTransitions method. Use '
      'availableTransitionsAsync instead.',
    );
  }

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) async {
    final response = await _request(
      method: 'GET',
      pathSegments: [
        ..._instanceCollectionSegments,
        instanceId,
        'available-transitions',
      ],
      expectedStatusCodes: const {200},
    );
    final decoded = _decodeObject(response);
    final responseInstanceId = decoded['instanceId'];
    final responseState = decoded['currentState'];
    final rawTransitions = decoded['transitions'];
    if (responseInstanceId is! String ||
        responseState is! String ||
        rawTransitions is! List<dynamic>) {
      throw _malformedResponse(
        response,
        'instanceId, currentState, and transitions are required.',
      );
    }
    return rawTransitions
        .map(
          (transition) => _decodeTransition(
            transition,
            response,
            currentState: responseState,
          ),
        )
        .toList();
  }

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
    Map<String, dynamic>? inputs,
  }) async {
    final response = await _request(
      method: 'POST',
      pathSegments: [..._instanceCollectionSegments, instanceId, 'transitions'],
      body: {
        'transitionId': transitionId,
        if (inputs != null) 'inputs': inputs,
      },
      includeIdempotencyKey: true,
      expectedStatusCodes: const {200},
    );
    final instance = _decodeInstance(
      _decodeObject(response),
      response,
      createdByPersonaId: '',
    );
    return WorkflowTransitionResult(
      newState: instance.currentState,
      newInstanceData: instance.instanceData,
    );
  }

  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  }) async {
    final fanId = personaId;
    final response = await _request(
      method: 'POST',
      pathSegments: _instanceCollectionSegments,
      body: {'workflowType': workflowType, 'instanceData': initialInstanceData},
      includeIdempotencyKey: true,
      expectedStatusCodes: const {201},
    );
    return _decodeInstance(
      _decodeObject(response),
      response,
      createdByPersonaId: fanId,
    ).instanceId;
  }

  @override
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String personaId,
  }) async {
    final fanId = personaId;
    final response = await _request(
      method: 'POST',
      pathSegments: [..._instanceCollectionSegments, 'batch'],
      body: {
        'workflowType': workflowType,
        'initialInstanceDataList': initialInstanceDataList,
      },
      includeIdempotencyKey: true,
      expectedStatusCodes: const {201},
    );
    final decoded = _decodeList(response);
    return decoded
        .map(
          (instance) => _decodeInstance(
            instance,
            response,
            createdByPersonaId: fanId,
          ).instanceId,
        )
        .toList();
  }

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    final response = await _request(
      method: 'PATCH',
      pathSegments: [..._instanceCollectionSegments, instanceId, 'fields'],
      body: {'fieldUpdates': fieldUpdates},
      includeIdempotencyKey: true,
      expectedStatusCodes: const {200},
    );
    _decodeInstance(_decodeObject(response), response, createdByPersonaId: '');
  }

  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? personaId,
  }) async {
    final response = await _request(
      method: 'POST',
      pathSegments: [..._instanceCollectionSegments, 'aggregate'],
      body: {
        'workflowType': workflowType,
        'column': column,
        'op': op,
        if (filter != null) 'filter': filter,
        if (groupBy != null) 'groupBy': groupBy,
      },
      expectedStatusCodes: const {200},
    );
    final decoded = _decodeObject(response);
    if (!decoded.containsKey('result')) {
      throw _malformedResponse(response, 'result is required.');
    }
    return decoded['result'];
  }

  @override
  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf}) {
    throw UnsupportedError(
      'RemoteWorkflowEngineApi cannot resolve dueNotifications because the '
      'workflow-service OpenAPI contract defines no such operation.',
    );
  }

  List<String> get _instanceCollectionSegments => [
    'v1',
    'communities',
    _communityId,
    'instances',
  ];

  Future<http.Response> _request({
    required String method,
    required List<String> pathSegments,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool includeIdempotencyKey = false,
    required Set<int> expectedStatusCodes,
  }) async {
    final token = await bearerTokenProvider();
    if (token.trim().isEmpty) {
      throw const RemoteWorkflowAuthenticationError(
        code: 'authentication_required',
        message: 'bearerTokenProvider returned an empty bearer token.',
      );
    }

    final relative = Uri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    );
    final uri = _baseUri.resolveUri(relative);
    final request = http.Request(method, uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['X-Loom-Correlation-Id'] = _newUuid();
    if (includeIdempotencyKey) {
      request.headers['Idempotency-Key'] = _newUuid();
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on RemoteWorkflowEngineException {
      rethrow;
    } catch (error) {
      throw RemoteWorkflowServiceError(
        code: 'network_error',
        message: 'The workflow service request failed: $error',
      );
    }
    if (!expectedStatusCodes.contains(response.statusCode)) {
      _throwMappedError(response);
    }
    return response;
  }

  Never _throwMappedError(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _malformedErrorResponse(response);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['code'] is! String ||
        decoded['message'] is! String ||
        decoded['correlationId'] != null &&
            decoded['correlationId'] is! String) {
      throw _malformedErrorResponse(response);
    }
    final code = decoded['code'] as String;
    final message = decoded['message'] as String;
    final correlationId = decoded['correlationId'] as String?;
    final informativeMessage = _errorMessage(
      code: code,
      message: message,
      statusCode: response.statusCode,
      correlationId: correlationId,
    );

    switch (code) {
      case 'workflow_field_edit_refused':
        throw WorkflowAuthorizationError(informativeMessage);
      case 'workflow_guard_refused':
      case 'workflow_read_refused':
      case 'workflow_instance_not_found':
      case 'workflow_type_not_found':
      case 'workflow_state_conflict':
      case 'workflow_create_refused':
      case 'invalid_transition_request':
        throw StateError(informativeMessage);
      case 'invalid_request':
        throw RemoteWorkflowProtocolError(
          code: code,
          message: message,
          statusCode: response.statusCode,
          correlationId: correlationId,
        );
      case 'authentication_required':
        throw RemoteWorkflowAuthenticationError(
          code: code,
          message: message,
          statusCode: response.statusCode,
          correlationId: correlationId,
        );
      case 'invalid_correlation_id':
      case 'invalid_idempotency_key':
      case 'unsupported_spec_version':
      case 'route_not_found':
        throw RemoteWorkflowProtocolError(
          code: code,
          message: message,
          statusCode: response.statusCode,
          correlationId: correlationId,
        );
      case 'authorization_service_unavailable':
      case 'workflow_service_error':
        throw RemoteWorkflowServiceError(
          code: code,
          message: message,
          statusCode: response.statusCode,
          correlationId: correlationId,
        );
      default:
        throw RemoteWorkflowProtocolError(
          code: code,
          message:
              'The workflow service returned an unknown error code: '
              '$message',
          statusCode: response.statusCode,
          correlationId: correlationId,
        );
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _malformedResponse(response, 'Body is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw _malformedResponse(response, 'Body must be a JSON object.');
    }
    return decoded;
  }

  List<dynamic> _decodeList(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _malformedResponse(response, 'Body is not valid JSON.');
    }
    if (decoded is! List<dynamic>) {
      throw _malformedResponse(response, 'Body must be a JSON array.');
    }
    return decoded;
  }

  WorkflowInstance _decodeInstance(
    Object? value,
    http.Response response, {
    required String createdByPersonaId,
  }) {
    if (value is! Map<String, dynamic> ||
        value['instanceId'] is! String ||
        value['workflowType'] is! String ||
        value['currentState'] is! String ||
        value['instanceData'] is! Map<String, dynamic>) {
      throw _malformedResponse(
        response,
        'A workflow instance has an invalid shape.',
      );
    }
    return WorkflowInstance(
      instanceId: value['instanceId'] as String,
      workflowType: value['workflowType'] as String,
      currentState: value['currentState'] as String,
      instanceData: Map<String, dynamic>.from(
        value['instanceData'] as Map<String, dynamic>,
      ),
      // The OpenAPI projection deliberately does not expose creator identity.
      createdByPersonaId: createdByPersonaId,
    );
  }

  LoomWorkflowTransition _decodeTransition(
    Object? value,
    http.Response response, {
    required String currentState,
  }) {
    if (value is! Map<String, dynamic> ||
        value['transitionId'] is! String ||
        value['label'] is! String ||
        value['action'] != null && value['action'] is! String ||
        value['tone'] != null && value['tone'] is! String ||
        value['inputs'] != null && value['inputs'] is! Map<String, dynamic>) {
      throw _malformedResponse(
        response,
        'An available transition has an invalid shape.',
      );
    }
    final rawInputs = value['inputs'] as Map<String, dynamic>?;
    final inputs = rawInputs?.map((name, input) {
      if (input is! Map<String, dynamic>) {
        throw _malformedResponse(
          response,
          'Transition input "$name" must be a JSON object.',
        );
      }
      try {
        return MapEntry(name, TransitionInputSpec.fromJson(input));
      } catch (_) {
        throw _malformedResponse(
          response,
          'Transition input "$name" has an invalid shape.',
        );
      }
    });
    return LoomWorkflowTransition(
      id: value['transitionId'] as String,
      label: value['label'] as String,
      action: value['action'] as String?,
      tone: value['tone'] as String?,
      from: [currentState],
      inputs: inputs,
    );
  }

  RemoteWorkflowProtocolError _malformedResponse(
    http.Response response,
    String detail,
  ) => RemoteWorkflowProtocolError(
    code: 'malformed_response',
    message:
        'The workflow service returned a malformed success response. '
        '$detail',
    statusCode: response.statusCode,
    correlationId: response.headers['x-loom-correlation-id'],
  );

  RemoteWorkflowProtocolError _malformedErrorResponse(http.Response response) =>
      RemoteWorkflowProtocolError(
        code: 'malformed_error_response',
        message:
            'The workflow service returned HTTP ${response.statusCode} '
            'without a valid API error body.',
        statusCode: response.statusCode,
        correlationId: response.headers['x-loom-correlation-id'],
      );

  static String _errorMessage({
    required String code,
    required String message,
    required int statusCode,
    String? correlationId,
  }) {
    final correlation = correlationId == null
        ? ''
        : ', correlationId: $correlationId';
    return 'Remote workflow request failed ($code, HTTP $statusCode'
        '$correlation): $message';
  }

  static Uri _normalizeBaseUri(Uri baseUri) {
    if (!baseUri.hasScheme || baseUri.host.isEmpty) {
      throw ArgumentError.value(baseUri, 'baseUri', 'must be an absolute URI');
    }
    final path = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
    return baseUri.replace(path: path, query: null, fragment: null);
  }

  static String _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return value;
  }

  static String _newUuid() {
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
