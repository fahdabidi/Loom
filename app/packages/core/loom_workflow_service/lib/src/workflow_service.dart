import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

import 'app_access_client.dart';
import 'community_group_id_resolver.dart';
import 'definition_validation.dart';
import 'document_access.dart';
import 'document_object_store.dart';
import 'document_repository.dart';
import 'export_bundle_repository.dart';
import 'identity.dart';
import 'item_queue_repository.dart';

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
  final void Function(String) _unexpectedErrorLogSink;
  final Map<String, LocalWorkflowEngineApi> _engines = {};

  /// Document storage, absent when the deployment has none configured.
  ///
  /// Nullable rather than required so the service still starts, and every other
  /// endpoint still works, when object storage is unreachable or simply not
  /// deployed. The document endpoints then answer 503 instead of the whole
  /// service failing to boot over a feature most requests never touch.
  final DocumentRepository? _documentRepository;
  final DocumentObjectStore? _documentObjectStore;
  final ExportBundleRepository? _exportBundleRepository;
  final ItemQueueRepository? _itemQueueRepository;
  final Map<String, Duration> _queueOfferHoldWindows;
  final DateTime Function() _clock;

  // WorkflowDatabase's transaction boundary uses one externally-owned
  // PostgreSQL connection. Keep whole transitions sequential so statements
  // from two HTTP requests cannot interleave between BEGIN and COMMIT.
  final _SerialExecutor _databaseSerialExecutor = _SerialExecutor();

  WorkflowService({
    required WorkflowDatabase database,
    required WorkflowIdentityExtractor identityExtractor,
    required AppAccessDecisionClient appAccessClient,
    required CommunityGroupIdResolver communityGroupIdResolver,
    void Function(String)? unexpectedErrorLogSink,
    DocumentRepository? documentRepository,
    DocumentObjectStore? documentObjectStore,
    ExportBundleRepository? exportBundleRepository,
    ItemQueueRepository? itemQueueRepository,
    Map<String, Duration> queueOfferHoldWindows = const <String, Duration>{},
    DateTime Function()? clock,
  }) : _database = database,
       _documentRepository = documentRepository,
       _documentObjectStore = documentObjectStore,
       _exportBundleRepository = exportBundleRepository,
       _itemQueueRepository = itemQueueRepository,
       _queueOfferHoldWindows = Map.unmodifiable(
         Map<String, Duration>.of(queueOfferHoldWindows),
       ),
       _clock = clock ?? DateTime.now,
       _identityExtractor = identityExtractor,
       _appAccessClient = appAccessClient,
       _communityGroupIdResolver = communityGroupIdResolver,
       _unexpectedErrorLogSink = unexpectedErrorLogSink ?? stderr.writeln;

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
    if (_matchesItemQueueAdvance(segments) && request.method == 'POST') {
      return _advanceItemQueue(request, segments[2], segments[4]);
    }
    if (_matchesItemQueueMember(segments) && request.method == 'DELETE') {
      return _removeFromItemQueue(
        request,
        segments[2],
        segments[4],
        segments[6],
      );
    }
    if (_matchesItemQueue(segments)) {
      if (request.method == 'GET') {
        return _getItemQueue(request, segments[2], segments[4]);
      }
      if (request.method == 'POST') {
        return _joinItemQueue(request, segments[2], segments[4]);
      }
      if (request.method == 'DELETE') {
        return _leaveItemQueue(request, segments[2], segments[4]);
      }
    }
    if (_matchesQueueMemberships(segments) && request.method == 'GET') {
      return _listMyQueueMemberships(request, segments[2]);
    }
    if (_matchesInstanceExportBundle(segments) && request.method == 'POST') {
      return _generateExportBundle(request, segments[2], segments[4]);
    }
    if (_matchesExportBundle(segments) && request.method == 'GET') {
      return _getExportBundle(request, segments[2], segments[4]);
    }
    if (_matchesExportBundleAction(segments, 'content') &&
        request.method == 'GET') {
      return _downloadExportBundle(request, segments[2], segments[4]);
    }
    if (_matchesExportBundleAction(segments, 'verification') &&
        request.method == 'POST') {
      return _verifyExportBundle(request, segments[2], segments[4]);
    }
    if (_matchesInstanceDocuments(segments)) {
      if (request.method == 'POST') {
        return _uploadDocument(request, segments[2], segments[4]);
      }
      if (request.method == 'GET') {
        return _listInstanceDocuments(request, segments[2], segments[4]);
      }
    }
    if (_matchesDocument(segments)) {
      if (request.method == 'GET') {
        return _getDocument(request, segments[2], segments[4]);
      }
      if (request.method == 'DELETE') {
        return _deleteDocument(request, segments[2], segments[4]);
      }
    }
    if (_matchesDocumentAction(segments, 'content') &&
        request.method == 'GET') {
      return _downloadDocumentContent(request, segments[2], segments[4]);
    }
    if (_matchesDocumentAction(segments, 'access') && request.method == 'GET') {
      return _getDocumentAccess(request, segments[2], segments[4]);
    }
    if (_matchesNotificationsDue(segments) && request.method == 'GET') {
      return _dueNotifications(request, segments[2]);
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
    // Only errors block an install. Warnings travel in the success summary, so
    // an advisory finding informs the author instead of rejecting a package
    // that is correct as authored.
    if (findings.any((finding) => finding.isError)) {
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
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } on StateError catch (error, stackTrace) {
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
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instance could not be created.',
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } on StateError catch (error, stackTrace) {
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
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow instances could not be created.',
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } on StateError catch (error, stackTrace) {
      if ('${error.message}'.startsWith('Permission denied for surface')) {
        return _error(
          request: request,
          statusCode: 403,
          code: 'workflow_read_refused',
          message: 'The workflow collection is not available to this caller.',
        );
      }
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Workflow instances could not be queried.',
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Available workflow transitions could not be resolved.',
      );
    }
  }

  // ----------------------------------------------------------- reminders
  //
  // `deliver_reminder` is the one action in any archetype vocabulary that the
  // platform applies rather than a member. permissions.md has said so since it
  // was written -- "the Calendar sweep applies it through the
  // dueNotifications({asOf}) platform service" -- and that service did not
  // exist, so a member could ask to be reminded and nothing would ever remind
  // them.

  bool _matchesNotificationsDue(List<String> segments) =>
      segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'notifications' &&
      segments[4] == 'due';

  /// The caller's reminders that have come due.
  ///
  /// Scoped by the engine's own read model rather than by a recipient filter
  /// written here. The engine's `dueNotifications` returns every instance in
  /// the community carrying a past `dueAt`, which is correct on a device
  /// holding one member's database and would hand every member everyone else's
  /// reminders if returned as-is. Both shipped notification workflows already
  /// declare `readGuard` on their recipient field, so asking the engine who may
  /// read each one is the same answer, derived rather than duplicated.
  Future<Response> _dueNotifications(Request request, String communityId) async {
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

    // `asOf` is the caller's clock, not the server's. A device that has been
    // offline asks for everything due up to now and gets the backlog; without
    // it a reminder that came due while the app was closed would be skipped
    // rather than delivered late.
    final rawAsOf = request.url.queryParameters['asOf'];
    final DateTime asOf;
    if (rawAsOf == null || rawAsOf.isEmpty) {
      asOf = DateTime.now().toUtc();
    } else {
      final parsed = DateTime.tryParse(rawAsOf);
      if (parsed == null) {
        return _error(
          request: request,
          statusCode: 400,
          code: 'invalid_as_of',
          message: 'asOf must be an ISO-8601 timestamp.',
        );
      }
      asOf = parsed.toUtc();
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

        final due = await engine.dueNotifications(asOf: asOf);
        final visible = <Map<String, dynamic>>[];
        for (final notification in due) {
          final readable = await engine.readVisibleInstance(
            instanceId: notification.instanceId,
            fanId: identity.fanId,
          );
          if (readable == null) continue;
          visible.add(_workflowInstanceJson(readable));
        }

        return Response.ok(
          jsonEncode({
            'asOf': asOf.toIso8601String(),
            'items': visible,
          }),
          headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
        );
      });
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'Due notifications could not be resolved.',
      );
    }
  }

  // -------------------------------------------------------------- item queues
  //
  // The equipment-loan queue is persistent service state. Workflow transitions
  // remain the source of authorization, but do not carry the ordered entries:
  // a queue needs join evidence, cross-item lookup, and an expiring offer.

  bool _matchesItemQueue(List<String> segments) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4].isNotEmpty &&
      segments[5] == 'queue';

  bool _matchesItemQueueMember(List<String> segments) =>
      segments.length == 7 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4].isNotEmpty &&
      segments[5] == 'queue' &&
      segments[6].isNotEmpty;

  bool _matchesItemQueueAdvance(List<String> segments) =>
      _matchesItemQueueMember(segments) && segments[6] == 'advance';

  bool _matchesQueueMemberships(List<String> segments) =>
      segments.length == 4 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'queue-memberships';

  Future<Response> _getItemQueue(
    Request request,
    String communityId,
    String instanceId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final lookup = await _readableQueueInstance(
      context: context,
      communityId: communityId,
      instanceId: instanceId,
    );
    if (!lookup.exists) return _queueInstanceNotFound(request);
    final instance = lookup.instance;
    if (instance == null) return _itemQueueReadForbidden(request);

    final entries = await context.repository.listForItem(
      communityId: communityId,
      instanceId: instanceId,
    );
    final queueInstance = _withQueueMemberships(instance, entries);
    final mayAdminister = await _mayAct(
      engine: context.engine,
      instance: queueInstance,
      fanId: context.identity.fanId,
      action: 'decide_request',
    );
    final viewerPosition = _positionFor(entries, context.identity.fanId);
    return Response.ok(
      jsonEncode(<String, dynamic>{
        'instanceId': instanceId,
        'length': entries.length,
        'viewerPosition': viewerPosition,
        if (mayAdminister)
          'entries': <Map<String, dynamic>>[
            for (var index = 0; index < entries.length; index++)
              entries[index].toJson(position: index + 1),
          ],
      }),
      headers: <String, String>{
        ..._jsonHeaders,
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<Response> _joinItemQueue(
    Request request,
    String communityId,
    String instanceId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final lookup = await _readableQueueInstance(
      context: context,
      communityId: communityId,
      instanceId: instanceId,
    );
    if (!lookup.exists) return _queueInstanceNotFound(request);
    final instance = lookup.instance;
    if (instance == null) return _itemQueueReadForbidden(request);

    final entries = await context.repository.listForItem(
      communityId: communityId,
      instanceId: instanceId,
    );
    final existingPosition = _positionFor(entries, context.identity.fanId);
    // The legacy engine adds membership eligibility around `join_queue`. The
    // persistent queue is authoritative here, so omit the caller only while
    // evaluating the community's transition guards and roles. A duplicate
    // request still requires the caller to be authorised, but it cannot move
    // their existing entry once authorised.
    final queueInstance = _withQueueMemberships(
      instance,
      entries
          .where((entry) => entry.fanId != context.identity.fanId)
          .toList(growable: false),
    );
    if (!await _mayAct(
      engine: context.engine,
      instance: queueInstance,
      fanId: context.identity.fanId,
      action: 'join_queue',
    )) {
      return _itemQueueActionForbidden(request, 'join');
    }
    if (existingPosition != 0) {
      return _queueEntryResponse(
        entries[existingPosition - 1],
        position: existingPosition,
        correlationId: context.correlationId,
        statusCode: 200,
      );
    }
    if (_currentlyHoldsItem(instance, context.identity.fanId)) {
      return _error(
        request: request,
        statusCode: 409,
        code: 'item_queue_current_holder',
        message: 'The current holder cannot join this item queue.',
      );
    }

    final joined = await context.repository.join(
      communityId: communityId,
      instanceId: instanceId,
      fanId: context.identity.fanId,
      joinedAt: _clock().toUtc(),
    );
    final currentEntries = await context.repository.listForItem(
      communityId: communityId,
      instanceId: instanceId,
    );
    final position = _positionFor(currentEntries, context.identity.fanId);
    if (position == 0) {
      throw StateError('Queue entry disappeared after a successful join.');
    }
    return _queueEntryResponse(
      joined.entry,
      position: position,
      correlationId: context.correlationId,
      statusCode: joined.created ? 201 : 200,
    );
  });

  Future<Response> _leaveItemQueue(
    Request request,
    String communityId,
    String instanceId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final lookup = await _readableQueueInstance(
      context: context,
      communityId: communityId,
      instanceId: instanceId,
    );
    if (!lookup.exists) return _queueInstanceNotFound(request);
    final instance = lookup.instance;
    if (instance == null) return _itemQueueReadForbidden(request);

    final entries = await context.repository.listForItem(
      communityId: communityId,
      instanceId: instanceId,
    );
    // The engine has a compatibility membership gate for its legacy
    // `queuedFanIds` field. For this service route the repository is
    // authoritative, so evaluate leave permission against a virtual queue in
    // which the caller is present. This preserves the community transition's
    // state and role guards without writing the retired instance-data shape.
    final queueFanIds = entries
        .map((entry) => entry.fanId)
        .toList(growable: true);
    if (!queueFanIds.contains(context.identity.fanId)) {
      queueFanIds.add(context.identity.fanId);
    }
    final queueInstance = _withQueueFanIds(instance, queueFanIds);
    if (!await _mayAct(
      engine: context.engine,
      instance: queueInstance,
      fanId: context.identity.fanId,
      action: 'leave_queue',
    )) {
      return _itemQueueActionForbidden(request, 'leave');
    }

    await context.repository.remove(
      communityId: communityId,
      instanceId: instanceId,
      fanId: context.identity.fanId,
    );
    return Response(
      204,
      headers: <String, String>{'x-loom-correlation-id': context.correlationId},
    );
  });

  Future<Response> _removeFromItemQueue(
    Request request,
    String communityId,
    String instanceId,
    String fanId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final lookup = await _readableQueueInstance(
      context: context,
      communityId: communityId,
      instanceId: instanceId,
    );
    if (!lookup.exists) return _queueInstanceNotFound(request);
    final instance = lookup.instance;
    if (instance == null) return _itemQueueReadForbidden(request);

    if (!await _mayAct(
      engine: context.engine,
      instance: instance,
      fanId: context.identity.fanId,
      action: 'decide_request',
    )) {
      return _itemQueueActionForbidden(request, 'administer');
    }
    await context.repository.remove(
      communityId: communityId,
      instanceId: instanceId,
      fanId: fanId,
    );
    return Response(
      204,
      headers: <String, String>{'x-loom-correlation-id': context.correlationId},
    );
  });

  Future<Response> _listMyQueueMemberships(
    Request request,
    String communityId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final memberships = await context.repository.listForFan(
      communityId: communityId,
      fanId: context.identity.fanId,
    );
    final responseMemberships = <Map<String, dynamic>>[];
    for (final membership in memberships) {
      final entries = await context.repository.listForItem(
        communityId: communityId,
        instanceId: membership.instanceId,
      );
      final position = _positionFor(entries, context.identity.fanId);
      if (position == 0) {
        throw StateError(
          'Membership query returned an entry outside its queue.',
        );
      }
      String? itemTitle;
      final visible = await context.engine.readVisibleInstance(
        instanceId: membership.instanceId,
        fanId: context.identity.fanId,
      );
      if (visible != null) {
        final title = visible.instanceData['title'];
        if (title is String && title.isNotEmpty) itemTitle = title;
      }
      responseMemberships.add(<String, dynamic>{
        'instanceId': membership.instanceId,
        if (itemTitle != null) 'itemTitle': itemTitle,
        'position': position,
        'length': entries.length,
        'joinedAt': membership.joinedAt.toUtc().toIso8601String(),
      });
    }
    return Response.ok(
      jsonEncode(<String, dynamic>{
        'fanId': context.identity.fanId,
        'memberships': responseMemberships,
      }),
      headers: <String, String>{
        ..._jsonHeaders,
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<Response> _advanceItemQueue(
    Request request,
    String communityId,
    String instanceId,
  ) => _withItemQueueRequest(request, communityId, (context) async {
    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null || idempotencyKey.trim().isEmpty) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key is required when advancing an item queue.',
      );
    }
    final lookup = await _readableQueueInstance(
      context: context,
      communityId: communityId,
      instanceId: instanceId,
    );
    if (!lookup.exists) return _queueInstanceNotFound(request);
    final instance = lookup.instance;
    if (instance == null) return _itemQueueReadForbidden(request);
    if (!await _mayAct(
      engine: context.engine,
      instance: instance,
      fanId: context.identity.fanId,
      action: 'decide_request',
    )) {
      return _itemQueueActionForbidden(request, 'administer');
    }

    final now = _clock().toUtc();
    final entries = await context.repository.listForItem(
      communityId: communityId,
      instanceId: instanceId,
    );
    while (entries.isNotEmpty) {
      final head = entries.first;
      final existingExpiry = head.offerExpiresAt;
      if (existingExpiry != null && now.isBefore(existingExpiry)) {
        // A non-lapsed offer remains the head's offer. Repeated delivery work
        // must not keep extending a member's hold indefinitely.
        return _queueOfferResponse(head, context.correlationId);
      }
      if (existingExpiry != null) {
        await context.repository.remove(
          communityId: communityId,
          instanceId: instanceId,
          fanId: head.fanId,
        );
        entries.removeAt(0);
        continue;
      }

      final holdWindow = _queueOfferHoldWindows[communityId];
      if (holdWindow == null || holdWindow <= Duration.zero) {
        return _error(
          request: request,
          statusCode: 503,
          code: 'item_queue_hold_window_unavailable',
          message: 'No positive item-queue hold window is configured.',
        );
      }
      final offeredAt = now;
      final offerExpiresAt = offeredAt.add(holdWindow);
      await context.repository.recordOffer(
        communityId: communityId,
        instanceId: instanceId,
        fanId: head.fanId,
        offeredAt: offeredAt,
        offerExpiresAt: offerExpiresAt,
      );
      return _queueOfferResponse(
        head.withOffer(offeredAt: offeredAt, offerExpiresAt: offerExpiresAt),
        context.correlationId,
      );
    }
    return Response(
      204,
      headers: <String, String>{'x-loom-correlation-id': context.correlationId},
    );
  });

  Future<Response> _withItemQueueRequest(
    Request request,
    String communityId,
    Future<Response> Function(_ItemQueueRequestContext context) body,
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
    final repository = _itemQueueRepository;
    if (repository == null) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'item_queue_storage_unavailable',
        message: 'This deployment has no item queue storage configured.',
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
    final groupId = await _communityGroupIdResolver.resolveGroupId(communityId);
    if (groupId == null || groupId.trim().isEmpty) {
      return _authorizationServiceUnavailable(request);
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
        return body(
          _ItemQueueRequestContext(
            identity: identity,
            correlationId: correlationId,
            engine: engine,
            repository: repository,
          ),
        );
      });
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The item queue request could not be completed.',
      );
    }
  }

  Future<_QueueInstanceLookup> _readableQueueInstance({
    required _ItemQueueRequestContext context,
    required String communityId,
    required String instanceId,
  }) async {
    final stored = await _database.readInstance(instanceId);
    if (stored == null || stored.communityId != communityId) {
      return const _QueueInstanceLookup(exists: false);
    }
    final instance = await context.engine.readVisibleInstance(
      instanceId: instanceId,
      fanId: context.identity.fanId,
    );
    return _QueueInstanceLookup(exists: true, instance: instance);
  }

  WorkflowInstance _withQueueMemberships(
    WorkflowInstance instance,
    List<StoredItemQueueEntry> entries,
  ) => _withQueueFanIds(instance, entries.map((entry) => entry.fanId));

  WorkflowInstance _withQueueFanIds(
    WorkflowInstance instance,
    Iterable<String> fanIds,
  ) => WorkflowInstance(
    instanceId: instance.instanceId,
    workflowType: instance.workflowType,
    currentState: instance.currentState,
    instanceData: <String, dynamic>{
      ...instance.instanceData,
      'queuedFanIds': List<String>.of(fanIds, growable: false),
    },
    createdByFanId: instance.createdByFanId,
  );

  static int _positionFor(List<StoredItemQueueEntry> entries, String fanId) {
    final index = entries.indexWhere((entry) => entry.fanId == fanId);
    return index < 0 ? 0 : index + 1;
  }

  static bool _currentlyHoldsItem(WorkflowInstance instance, String fanId) {
    // These are the three custody fields used by the shipped equipment-loan
    // definitions. Custody remains workflow-owned; this read only enforces the
    // queue contract's "do not queue for an item you hold" rule.
    for (final key in const <String>[
      'currentHolderFanId',
      'holderFanId',
      'borrowerFanId',
    ]) {
      if (instance.instanceData[key] == fanId) return true;
    }
    return false;
  }

  Response _queueEntryResponse(
    StoredItemQueueEntry entry, {
    required int position,
    required String correlationId,
    required int statusCode,
  }) => Response(
    statusCode,
    body: jsonEncode(entry.toJson(position: position)),
    headers: <String, String>{
      ..._jsonHeaders,
      'x-loom-correlation-id': correlationId,
    },
  );

  Response _queueOfferResponse(
    StoredItemQueueEntry entry,
    String correlationId,
  ) {
    final offeredAt = entry.offeredAt;
    final offerExpiresAt = entry.offerExpiresAt;
    if (offeredAt == null || offerExpiresAt == null) {
      throw StateError('Cannot return an offer without both timestamps.');
    }
    return Response.ok(
      jsonEncode(<String, dynamic>{
        'instanceId': entry.instanceId,
        'fanId': entry.fanId,
        'offeredAt': offeredAt.toUtc().toIso8601String(),
        'offerExpiresAt': offerExpiresAt.toUtc().toIso8601String(),
      }),
      headers: <String, String>{
        ..._jsonHeaders,
        'x-loom-correlation-id': correlationId,
      },
    );
  }

  Response _queueInstanceNotFound(Request request) => _error(
    request: request,
    statusCode: 404,
    code: 'workflow_instance_not_found',
    message: 'The requested workflow instance was not found.',
  );

  Response _itemQueueReadForbidden(Request request) => _error(
    request: request,
    statusCode: 403,
    code: 'item_queue_read_forbidden',
    message: 'The item queue is not readable by this caller.',
  );

  Response _itemQueueActionForbidden(Request request, String operation) =>
      _error(
        request: request,
        statusCode: 403,
        code: 'item_queue_${operation}_forbidden',
        message: 'The item queue cannot be $operation by this caller.',
      );

  // ---------------------------------------------------------- export bundles
  //
  // The export wizard's integrity surface. Bundle bytes use the document
  // object-store interface deliberately: storage is an implementation detail
  // shared by both features, while export metadata is distinct from document
  // metadata and must retain the checksum recorded at generation.

  bool _matchesInstanceExportBundle(List<String> segments) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4].isNotEmpty &&
      segments[5] == 'export-bundle';

  bool _matchesExportBundle(List<String> segments) =>
      segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'export-bundles' &&
      segments[4].isNotEmpty;

  bool _matchesExportBundleAction(List<String> segments, String action) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'export-bundles' &&
      segments[4].isNotEmpty &&
      segments[5] == action;

  Future<Response> _generateExportBundle(
    Request request,
    String communityId,
    String instanceId,
  ) => _withExportRequest(request, communityId, (context) async {
    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey == null || idempotencyKey.trim().isEmpty) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_idempotency_key',
        message: 'Idempotency-Key is required for export generation.',
      );
    }

    late final _ExportBundleRequestBody body;
    try {
      body = await _readExportBundleRequestBody(request);
    } on _EmptyExportComponentIds {
      return _error(
        request: request,
        statusCode: 422,
        code: 'export_scope_empty',
        message: 'componentIds must not be empty.',
      );
    } on FormatException catch (error) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_export_bundle_request',
        message: error.message,
      );
    }

    final instance = await context.engine.readVisibleInstance(
      instanceId: instanceId,
      fanId: context.identity.fanId,
    );
    if (instance == null) return _exportBundleNotFound(request);

    if (!await _mayAct(
      engine: context.engine,
      instance: instance,
      fanId: context.identity.fanId,
      action: 'download',
    )) {
      final downloadExistsInThisState = await _hasActionInCurrentState(
        communityId: communityId,
        instance: instance,
        action: 'download',
      );
      return _error(
        request: request,
        statusCode: downloadExistsInThisState ? 403 : 409,
        code: downloadExistsInThisState
            ? 'export_bundle_generate_forbidden'
            : 'export_bundle_state_conflict',
        message: downloadExistsInThisState
            ? 'A download transition is not available to this fan.'
            : 'No download transition is available from the instance state.',
      );
    }

    final existing = await context.repository.findByIdempotencyKey(
      communityId: communityId,
      idempotencyKey: idempotencyKey,
    );
    if (existing != null) {
      return _exportBundleResponse(existing, context.correlationId, 200);
    }

    if (body.includeDocuments && context.documentRepository == null) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'export_document_metadata_unavailable',
        message: 'Document metadata is required when includeDocuments is true.',
      );
    }

    final payload = await _buildExportPayload(
      context: context,
      communityId: communityId,
      sourceInstance: instance,
      body: body,
    );
    if (payload.recordCount == 0) {
      return _error(
        request: request,
        statusCode: 422,
        code: 'export_scope_empty',
        message: 'The export scope selects no records.',
      );
    }

    final exportId = 'export_${_newExportBundleId()}';
    final bundle = StoredExportBundle(
      exportId: exportId,
      communityId: communityId,
      instanceId: instanceId,
      checksum: sha256.convert(payload.bytes).toString(),
      checksumAlgorithm: 'sha-256',
      byteSize: payload.bytes.length,
      recordCount: payload.recordCount,
      redacted: body.redactProtectedData,
      generatedAt: DateTime.now().toUtc(),
      objectKey: exportBundleObjectKey(
        communityId: communityId,
        instanceId: instanceId,
        exportId: exportId,
      ),
    );

    // Store exactly the bytes that were hashed. Download and verification read
    // this object verbatim; neither is allowed to re-serialise the records.
    await context.objectStore.put(
      key: bundle.objectKey,
      bytes: payload.bytes,
      contentType: 'application/octet-stream',
    );
    await context.repository.insert(bundle, idempotencyKey: idempotencyKey);

    // This is platform bookkeeping, not a member field edit. The checksum is
    // intentionally written through the same merge path as document URLs.
    final updates = <String, dynamic>{
      'checksum': bundle.checksum,
      'checksumAlgorithm': bundle.checksumAlgorithm,
    };
    if (await _declaresField(
      communityId,
      instance.workflowType,
      'checksumVerified',
    )) {
      updates['checksumVerified'] = false;
    }
    await _database.mergeInstanceFields(
      instanceId: instanceId,
      fieldUpdates: updates,
    );

    return _exportBundleResponse(bundle, context.correlationId, 201);
  });

  Future<Response> _getExportBundle(
    Request request,
    String communityId,
    String exportId,
  ) => _withExportRequest(request, communityId, (context) async {
    final found = await _readableExportBundle(context, communityId, exportId);
    if (found == null) return _exportBundleNotFound(request);
    if (!await _mayAct(
      engine: context.engine,
      instance: found.instance,
      fanId: context.identity.fanId,
      action: 'download',
    )) {
      return _exportBundleDownloadForbidden(request);
    }
    return _exportBundleResponse(found.bundle, context.correlationId, 200);
  });

  Future<Response> _downloadExportBundle(
    Request request,
    String communityId,
    String exportId,
  ) => _withExportRequest(request, communityId, (context) async {
    final found = await _readableExportBundle(context, communityId, exportId);
    if (found == null) return _exportBundleNotFound(request);
    if (!await _mayAct(
      engine: context.engine,
      instance: found.instance,
      fanId: context.identity.fanId,
      action: 'download',
    )) {
      return _exportBundleDownloadForbidden(request);
    }

    final bytes = await context.objectStore.get(found.bundle.objectKey);
    if (bytes == null) return _exportBundleContentMissing(request);
    return Response.ok(
      bytes,
      headers: <String, String>{
        'content-type': 'application/octet-stream',
        'content-length': '${found.bundle.byteSize}',
        'etag': '"${found.bundle.checksum}"',
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<Response> _verifyExportBundle(
    Request request,
    String communityId,
    String exportId,
  ) => _withExportRequest(request, communityId, (context) async {
    final found = await _readableExportBundle(context, communityId, exportId);
    if (found == null) return _exportBundleNotFound(request);
    if (!await _mayAct(
      engine: context.engine,
      instance: found.instance,
      fanId: context.identity.fanId,
      action: 'download',
    )) {
      return _exportBundleDownloadForbidden(request);
    }

    final bytes = await context.objectStore.get(found.bundle.objectKey);
    if (bytes == null) return _exportBundleContentMissing(request);

    // This must be freshly computed from storage. Reading the recorded value
    // here would make a replacement or truncation verify unconditionally.
    final observedChecksum = sha256.convert(bytes).toString();
    final verified =
        observedChecksum == found.bundle.checksum &&
        bytes.length == found.bundle.byteSize;
    if (await _declaresField(
      communityId,
      found.instance.workflowType,
      'checksumVerified',
    )) {
      await _database.mergeInstanceFields(
        instanceId: found.instance.instanceId,
        fieldUpdates: <String, dynamic>{'checksumVerified': verified},
      );
    }

    return Response.ok(
      jsonEncode(<String, dynamic>{
        'exportId': found.bundle.exportId,
        'verified': verified,
        'recordedChecksum': found.bundle.checksum,
        'observedChecksum': observedChecksum,
        'checksumAlgorithm': found.bundle.checksumAlgorithm,
        'recordedByteSize': found.bundle.byteSize,
        'observedByteSize': bytes.length,
        'verifiedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: <String, String>{
        ..._jsonHeaders,
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<_ExportPayload> _buildExportPayload({
    required _ExportRequestContext context,
    required String communityId,
    required WorkflowInstance sourceInstance,
    required _ExportBundleRequestBody body,
  }) async {
    final definitions = await _database.loadDefinitionsForCommunity(
      communityId,
    );
    final protectedFields = _protectedFieldNames(
      definitions: definitions,
      exportInstanceData: sourceInstance.instanceData,
    );
    final sourceScope = _componentIdsAllowedByExport(
      sourceInstance.instanceData,
    );
    final componentIds = sourceScope == null
        ? body.componentIds
        : body.componentIds == null
        ? sourceScope
        : body.componentIds!
              .where(sourceScope.contains)
              .toList(growable: false);
    final rows = await _database.queryInstancesKeyset(
      communityId: communityId,
      limit: 1 << 30,
      sortKey: 'instanceId',
    );
    final records = <Map<String, dynamic>>[];
    final documents = <Map<String, dynamic>>[];
    for (final row in rows) {
      // Never serialise the export-control record into the bundle it creates:
      // generation stamps its checksum, which would make a second generation
      // over otherwise unchanged data non-deterministic.
      if (row.instanceId == sourceInstance.instanceId) continue;
      if (componentIds != null && !componentIds.contains(row.workflowType)) {
        continue;
      }
      final instance = await context.engine.readVisibleInstance(
        instanceId: row.instanceId,
        fanId: context.identity.fanId,
      );
      if (instance == null) continue;

      final data = Map<String, dynamic>.from(instance.instanceData);
      if (body.redactProtectedData) {
        data.removeWhere((field, _) => protectedFields.contains(field));
      }
      records.add(<String, dynamic>{
        'instanceId': instance.instanceId,
        'workflowType': instance.workflowType,
        'currentState': instance.currentState,
        'createdByFanId': instance.createdByFanId,
        'instanceData': data,
      });

      if (!body.includeDocuments) continue;
      final repository = context.documentRepository;
      if (repository == null) continue;
      final boundDocuments = await repository.listForInstance(
        communityId: communityId,
        instanceId: instance.instanceId,
      );
      for (final document in boundDocuments) {
        final bytes = await context.objectStore.get(document.objectKey);
        if (bytes == null) {
          throw StateError(
            'Document ${document.documentId} is missing its stored bytes.',
          );
        }
        documents.add(<String, dynamic>{
          'documentId': document.documentId,
          'instanceId': document.instanceId,
          'filename': document.filename,
          'contentType': document.contentType,
          'contentBase64': base64Encode(bytes),
        });
      }
    }
    records.sort((a, b) {
      final byType = (a['workflowType'] as String).compareTo(
        b['workflowType'] as String,
      );
      if (byType != 0) return byType;
      return (a['instanceId'] as String).compareTo(b['instanceId'] as String);
    });
    documents.sort(
      (a, b) =>
          (a['documentId'] as String).compareTo(b['documentId'] as String),
    );

    final canonical = _canonicalJson(<String, dynamic>{
      'format': 'loom-export-bundle-v1',
      'communityId': communityId,
      'sourceInstanceId': sourceInstance.instanceId,
      'redacted': body.redactProtectedData,
      'records': records,
      if (body.includeDocuments) 'documents': documents,
    });
    return _ExportPayload(
      bytes: utf8.encode(canonical),
      recordCount: records.length,
    );
  }

  Set<String> _protectedFieldNames({
    required Map<String, Map<String, dynamic>> definitions,
    required Map<String, dynamic> exportInstanceData,
  }) {
    final result = <String>{};
    for (final definition in definitions.values) {
      final schema = definition['instanceDataSchema'];
      if (schema is! Map<String, dynamic>) continue;
      for (final entry in schema.entries) {
        final field = entry.value;
        if (field is! Map<String, dynamic>) continue;
        if (field['protected'] == true ||
            field['isProtected'] == true ||
            field['redactOnExport'] == true ||
            field['visibility'] == 'protected') {
          result.add(entry.key);
        }
      }
    }
    // Existing export workflows commonly carry an explicit list of protected
    // field names. Respect it as export-scoped policy in addition to schema
    // annotations, while ignoring non-string labels safely.
    for (final key in const <String>[
      'protectedFields',
      'redactedFields',
      'protectedFieldLabels',
    ]) {
      final values = exportInstanceData[key];
      if (values is Iterable) {
        result.addAll(values.whereType<String>());
      }
    }
    return result;
  }

  /// The request can narrow an export, but cannot widen the scope configured
  /// on its owning export instance. The corpus uses several historical names
  /// for that list, so preserve all established shapes rather than guessing
  /// from a label or accepting a client-provided role list.
  List<String>? _componentIdsAllowedByExport(
    Map<String, dynamic> instanceData,
  ) {
    for (final key in const <String>[
      'componentIds',
      'exportScope',
      'scope',
      'selectedSchemaIds',
      'selectedScope',
      'includedComponents',
    ]) {
      final value = instanceData[key];
      if (value is! List) continue;
      if (value.any((component) => component is! String)) continue;
      return value.cast<String>();
    }
    return null;
  }

  Future<bool> _hasActionInCurrentState({
    required String communityId,
    required WorkflowInstance instance,
    required String action,
  }) async {
    final definitions = await _database.loadDefinitionsForCommunity(
      communityId,
    );
    final definition = definitions[instance.workflowType];
    if (definition == null) return false;
    final machine = LoomWorkflowStateMachine.fromJson(
      definition,
      instance.workflowType,
    );
    return machine
        .transitionsFrom(instance.currentState)
        .any((transition) => transition.action == action);
  }

  Future<_ReadableExportBundle?> _readableExportBundle(
    _ExportRequestContext context,
    String communityId,
    String exportId,
  ) async {
    final bundle = await context.repository.findById(
      communityId: communityId,
      exportId: exportId,
    );
    if (bundle == null) return null;
    final instance = await context.engine.readVisibleInstance(
      instanceId: bundle.instanceId,
      fanId: context.identity.fanId,
    );
    if (instance == null) return null;
    return _ReadableExportBundle(bundle: bundle, instance: instance);
  }

  Future<_ExportBundleRequestBody> _readExportBundleRequestBody(
    Request request,
  ) async {
    final contentType = request.headers['content-type'];
    if (contentType == null ||
        !contentType.toLowerCase().startsWith('application/json')) {
      throw const FormatException('Content-Type must be application/json.');
    }
    final decoded = await _readJsonObject(request);
    const allowed = <String>{
      'redactProtectedData',
      'componentIds',
      'includeDocuments',
    };
    if (decoded.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException(
        'The export bundle request contains an unknown field.',
      );
    }
    final redactProtectedData = decoded['redactProtectedData'];
    if (redactProtectedData is! bool) {
      throw const FormatException('redactProtectedData must be a boolean.');
    }
    final rawComponentIds = decoded['componentIds'];
    List<String>? componentIds;
    if (rawComponentIds != null) {
      if (rawComponentIds is! List ||
          rawComponentIds.any((value) => value is! String || value.isEmpty)) {
        throw const FormatException(
          'componentIds must be an array of non-empty strings.',
        );
      }
      if (rawComponentIds.isEmpty) {
        throw const _EmptyExportComponentIds();
      }
      componentIds = rawComponentIds.cast<String>();
    }
    final includeDocuments = decoded['includeDocuments'];
    if (includeDocuments != null && includeDocuments is! bool) {
      throw const FormatException('includeDocuments must be a boolean.');
    }
    return _ExportBundleRequestBody(
      redactProtectedData: redactProtectedData,
      componentIds: componentIds,
      includeDocuments: includeDocuments as bool? ?? true,
    );
  }

  String _canonicalJson(Object? value) {
    if (value == null || value is bool || value is num)
      return jsonEncode(value);
    if (value is DateTime) return jsonEncode(value.toUtc().toIso8601String());
    if (value is String) return jsonEncode(_normaliseTimestamp(value));
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    if (value is Map) {
      final keys = value.keys.cast<Object?>().map((key) {
        if (key is! String)
          throw StateError('Export JSON object keys must be strings.');
        return key;
      }).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    throw StateError(
      'Export payload contains unsupported value ${value.runtimeType}.',
    );
  }

  String _normaliseTimestamp(String value) {
    final timestampPattern = RegExp(
      r'^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?(?:Z|[+-]\\d{2}:\\d{2})$',
    );
    if (!timestampPattern.hasMatch(value)) return value;
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : parsed.toUtc().toIso8601String();
  }

  Response _exportBundleNotFound(Request request) => _error(
    request: request,
    statusCode: 404,
    code: 'export_bundle_not_found',
    message: 'The requested export bundle was not found.',
  );

  Response _exportBundleDownloadForbidden(Request request) => _error(
    request: request,
    statusCode: 403,
    code: 'export_bundle_download_forbidden',
    message: 'A download transition is not available to this fan.',
  );

  Response _exportBundleContentMissing(Request request) => _error(
    request: request,
    statusCode: 410,
    code: 'export_bundle_content_missing',
    message: 'The export bundle record exists but its bytes are gone.',
  );

  Response _exportBundleResponse(
    StoredExportBundle bundle,
    String correlationId,
    int statusCode,
  ) => Response(
    statusCode,
    body: jsonEncode(bundle.toJson()),
    headers: <String, String>{
      ..._jsonHeaders,
      'x-loom-correlation-id': correlationId,
    },
  );

  static String _newExportBundleId() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  // --------------------------------------------------------------- documents
  //
  // Bytes for the `documentLibrary` archetype. Every access decision here is
  // the engine's, made against the instance the document belongs to -- see
  // docs/API/OpenAPI/community-surfaces/document-library-api.openapi.yaml.

  /// Refused above this, before anything is read into memory.
  static const _maxDocumentUploadBytes = 25 * 1024 * 1024;

  bool _matchesInstanceDocuments(List<String> segments) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'instances' &&
      segments[4].isNotEmpty &&
      segments[5] == 'documents';

  bool _matchesDocument(List<String> segments) =>
      segments.length == 5 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'documents' &&
      segments[4].isNotEmpty;

  bool _matchesDocumentAction(List<String> segments, String action) =>
      segments.length == 6 &&
      segments[0] == 'v1' &&
      segments[1] == 'communities' &&
      segments[2].isNotEmpty &&
      segments[3] == 'documents' &&
      segments[4].isNotEmpty &&
      segments[5] == action;

  Future<Response> _uploadDocument(
    Request request,
    String communityId,
    String instanceId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final instance = await context.engine.readVisibleInstance(
      instanceId: instanceId,
      fanId: context.identity.fanId,
    );
    if (instance == null) return _documentNotFound(request);

    if (!await _mayAct(
      engine: context.engine,
      instance: instance,
      fanId: context.identity.fanId,
      action: 'upload',
    )) {
      return _error(
        request: request,
        statusCode: 403,
        code: 'document_upload_forbidden',
        message: 'An upload transition is not available to this fan.',
      );
    }

    final idempotencyKey = request.headers['idempotency-key'];
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      final existing = await context.repository.findByIdempotencyKey(
        communityId: communityId,
        idempotencyKey: idempotencyKey,
      );
      if (existing != null) {
        return _documentResponse(existing, context.correlationId, 200);
      }
    }

    final form = request.formData();
    if (form == null) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_document_upload',
        message: 'A multipart/form-data body is required.',
      );
    }

    List<int>? bytes;
    String? filename;
    String? fieldName;
    String? title;
    String? partContentType;
    String? bodyContentType;
    await for (final data in form.formData) {
      switch (data.name) {
        case 'file':
          filename = data.filename;
          partContentType = data.part.headers['content-type'];
          final builder = BytesBuilder(copy: false);
          await for (final chunk in data.part) {
            builder.add(chunk);
            if (builder.length > _maxDocumentUploadBytes) {
              return _error(
                request: request,
                statusCode: 413,
                code: 'document_too_large',
                message:
                    'The file exceeds $_maxDocumentUploadBytes bytes.',
              );
            }
          }
          bytes = builder.takeBytes();
        case 'fieldName':
          fieldName = (await data.part.readString()).trim();
        case 'title':
          title = (await data.part.readString()).trim();
        case 'contentType':
          bodyContentType = (await data.part.readString()).trim();
        default:
          // Drained rather than ignored: an unread part leaves the rest of the
          // body unparsed, so a client sending an extra field would see its
          // file silently truncated.
          await data.part.drain<void>();
      }
    }

    if (bytes == null || fieldName == null || fieldName.isEmpty) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'invalid_document_upload',
        message: 'Both a file part and a fieldName part are required.',
      );
    }

    if (!await _declaresField(communityId, instance.workflowType, fieldName)) {
      return _error(
        request: request,
        statusCode: 400,
        code: 'unknown_document_field',
        message:
            'The workflow does not declare an instance field "$fieldName".',
      );
    }

    final documentId = 'doc_${_newDocumentId()}';
    final objectKey = documentObjectKey(
      communityId: communityId,
      instanceId: instanceId,
      documentId: documentId,
    );
    final document = StoredDocument(
      documentId: documentId,
      communityId: communityId,
      instanceId: instanceId,
      workflowType: instance.workflowType,
      fieldName: fieldName,
      title: (title == null || title.isEmpty)
          ? (filename ?? documentId)
          : title,
      filename: filename ?? documentId,
      contentType:
          (bodyContentType != null && bodyContentType.isNotEmpty)
          ? bodyContentType
          : (partContentType ?? 'application/octet-stream'),
      byteSize: bytes.length,
      ownerFanId: context.identity.fanId,
      objectKey: objectKey,
      uploadedAt: DateTime.now().toUtc(),
    );

    // Bytes first. A metadata row whose object is missing is a document that
    // lists but will not open; an object with no row is unreferenced storage,
    // which is cheaper to reap than a broken document is to explain.
    await context.objectStore.put(
      key: objectKey,
      bytes: bytes,
      contentType: document.contentType,
    );
    await context.repository.insert(
      document,
      idempotencyKey: (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
          ? idempotencyKey
          : null,
    );

    // Publish the reference into the instance field the upload named.
    //
    // Without this the bytes exist and the card renders nothing: a
    // documentLibrary surface draws from instance data, so a document that
    // lives only in the documents table is invisible to the member who just
    // uploaded it.
    //
    // Written through mergeInstanceFields rather than updateInstanceFields.
    // The latter is the member-edit path -- it demands the field appear in the
    // state's editableFields and refuses anything declared writableBy
    // "effect". A document reference is neither: it is archetype-owned
    // bookkeeping, produced by the platform, and a member must not be able to
    // type into it. Authorization already happened above, where an `upload`
    // transition had to be available to this fan.
    await _database.mergeInstanceFields(
      instanceId: instanceId,
      fieldUpdates: <String, dynamic>{fieldName: document.contentUrl},
    );

    return _documentResponse(document, context.correlationId, 201);
  });

  Future<Response> _listInstanceDocuments(
    Request request,
    String communityId,
    String instanceId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final instance = await context.engine.readVisibleInstance(
      instanceId: instanceId,
      fanId: context.identity.fanId,
    );
    if (instance == null) return _documentNotFound(request);

    final documents = await context.repository.listForInstance(
      communityId: communityId,
      instanceId: instanceId,
    );
    return Response.ok(
      jsonEncode({
        'documents': documents.map((d) => d.toJson()).toList(),
      }),
      headers: {
        ..._jsonHeaders,
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<Response> _getDocument(
    Request request,
    String communityId,
    String documentId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final found = await _readableDocument(context, communityId, documentId);
    if (found == null) return _documentNotFound(request);
    return _documentResponse(found.document, context.correlationId, 200);
  });

  Future<Response> _downloadDocumentContent(
    Request request,
    String communityId,
    String documentId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final found = await _readableDocument(context, communityId, documentId);
    if (found == null) return _documentNotFound(request);

    final bytes = await context.objectStore.get(found.document.objectKey);
    if (bytes == null) {
      // The row exists and the object does not. Reported as a server fault
      // rather than a 404: the document is real, and telling the member it does
      // not exist would hide a storage problem as a content problem.
      return _error(
        request: request,
        statusCode: 500,
        code: 'document_content_missing',
        message: 'The document metadata exists but its bytes do not.',
      );
    }
    return Response.ok(
      bytes,
      headers: {
        'content-type': found.document.contentType,
        'content-length': '${bytes.length}',
        // Always an attachment. These bytes came from a member, and serving
        // them inline from a Loom origin would let an uploaded HTML file run
        // against it.
        'content-disposition':
            'attachment; filename="${_sanitiseFilename(found.document.filename)}"',
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  Future<Response> _deleteDocument(
    Request request,
    String communityId,
    String documentId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final found = await _readableDocument(context, communityId, documentId);
    if (found == null) return _documentNotFound(request);

    if (!await _mayAct(
      engine: context.engine,
      instance: found.instance,
      fanId: context.identity.fanId,
      action: 'delete',
    )) {
      return _error(
        request: request,
        statusCode: 403,
        code: 'document_delete_forbidden',
        message: 'A delete transition is not available to this fan.',
      );
    }

    await context.repository.delete(
      communityId: communityId,
      documentId: documentId,
    );
    await context.objectStore.delete(found.document.objectKey);
    return Response(
      204,
      headers: {'x-loom-correlation-id': context.correlationId},
    );
  });

  Future<Response> _getDocumentAccess(
    Request request,
    String communityId,
    String documentId,
  ) => _withDocumentRequest(request, communityId, (context) async {
    final found = await _readableDocument(context, communityId, documentId);
    if (found == null) return _documentNotFound(request);

    final List<GroupMember> members;
    try {
      members = await _appAccessClient.listGroupMembers(
        appId: _appId,
        groupId: context.groupId,
        correlationId: context.correlationId,
      );
    } on AppAccessDecisionException catch (_) {
      return _authorizationServiceUnavailable(request);
    } on SocketException catch (_) {
      return _authorizationServiceUnavailable(request);
    }

    final definitions = await _database.loadDefinitionsForCommunity(
      communityId,
    );
    final resolver = DocumentAccessResolver(
      engine: context.engine,
      definition:
          definitions[found.document.workflowType] ?? const <String, dynamic>{},
    );
    final access = await resolver.resolve(
      documentId: documentId,
      instance: found.instance,
      ownerFanId: found.document.ownerFanId,
      members: members,
    );

    return Response.ok(
      jsonEncode(access.toJson()),
      headers: {
        ..._jsonHeaders,
        'x-loom-correlation-id': context.correlationId,
      },
    );
  });

  /// Shared export preamble: correlation id, identity, storage and roles.
  ///
  /// It intentionally validates the correlation header before reporting an
  /// unavailable storage dependency. A malformed request must not become a
  /// false storage-success signal merely because the deployment is incomplete.
  Future<Response> _withExportRequest(
    Request request,
    String communityId,
    Future<Response> Function(_ExportRequestContext context) body,
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

    final repository = _exportBundleRepository;
    final objectStore = _documentObjectStore;
    if (repository == null || objectStore == null) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'export_bundle_storage_unavailable',
        message: 'This deployment has no export bundle storage configured.',
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

    final groupId = await _communityGroupIdResolver.resolveGroupId(communityId);
    if (groupId == null || groupId.trim().isEmpty) {
      return _authorizationServiceUnavailable(request);
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

        return body(
          _ExportRequestContext(
            identity: identity,
            correlationId: correlationId,
            engine: engine,
            repository: repository,
            objectStore: objectStore,
            documentRepository: _documentRepository,
          ),
        );
      });
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The export bundle request could not be completed.',
      );
    }
  }

  /// Shared preamble: correlation id, identity, storage, roles and membership.
  Future<Response> _withDocumentRequest(
    Request request,
    String communityId,
    Future<Response> Function(_DocumentRequestContext context) body,
  ) async {
    final repository = _documentRepository;
    final objectStore = _documentObjectStore;
    if (repository == null || objectStore == null) {
      return _error(
        request: request,
        statusCode: 503,
        code: 'document_storage_unavailable',
        message: 'This deployment has no document storage configured.',
      );
    }

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

    final groupId = await _communityGroupIdResolver.resolveGroupId(communityId);
    if (groupId == null || groupId.trim().isEmpty) {
      return _authorizationServiceUnavailable(request);
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

        return body(
          _DocumentRequestContext(
            identity: identity,
            correlationId: correlationId,
            groupId: groupId,
            engine: engine,
            repository: repository,
            objectStore: objectStore,
          ),
        );
      });
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The document request could not be completed.',
      );
    }
  }

  /// The document plus its instance, or null when either is unreadable.
  ///
  /// One 404 covers "no such document" and "not yours to read", so an
  /// unauthorised caller cannot map which document ids exist.
  Future<_ReadableDocument?> _readableDocument(
    _DocumentRequestContext context,
    String communityId,
    String documentId,
  ) async {
    final document = await context.repository.findById(
      communityId: communityId,
      documentId: documentId,
    );
    if (document == null) return null;
    final instance = await context.engine.readVisibleInstance(
      instanceId: document.instanceId,
      fanId: context.identity.fanId,
    );
    if (instance == null) return null;
    return _ReadableDocument(document: document, instance: instance);
  }

  /// Whether [fanId] could invoke a transition declaring [action].
  ///
  /// The engine's own guard evaluation, not a permission checked here. A
  /// community that declares no `upload` transition has a library nobody can
  /// write to, which is what it asked for.
  Future<bool> _mayAct({
    required LocalWorkflowEngineApi engine,
    required WorkflowInstance instance,
    required String fanId,
    required String action,
  }) async {
    final transitions = await engine.availableTransitionsAsync(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      currentState: instance.currentState,
      instanceData: instance.instanceData,
      fanId: fanId,
    );
    return transitions.any((transition) => transition.action == action);
  }

  Future<bool> _declaresField(
    String communityId,
    String workflowType,
    String fieldName,
  ) async {
    final definitions = await _database.loadDefinitionsForCommunity(
      communityId,
    );
    final schema = definitions[workflowType]?['instanceDataSchema'];
    return schema is Map<String, dynamic> && schema.containsKey(fieldName);
  }

  Response _documentNotFound(Request request) => _error(
    request: request,
    statusCode: 404,
    code: 'document_not_found',
    message: 'The requested document was not found.',
  );

  Response _documentResponse(
    StoredDocument document,
    String correlationId,
    int statusCode,
  ) => Response(
    statusCode,
    body: jsonEncode(document.toJson()),
    headers: {..._jsonHeaders, 'x-loom-correlation-id': correlationId},
  );

  static String _newDocumentId() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Strips what a filename must not carry into a header.
  ///
  /// Quotes and newlines would end the header value early, which is a response
  /// splitting hole when the value came from a member's chosen filename.
  static String _sanitiseFilename(String filename) => filename
      .replaceAll(RegExp(r'[\r\n"\\]'), '')
      .replaceAll(RegExp(r'[/\\]'), '_');

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

    // Membership is resolved for whichever fan the engine asks about, not only
    // the caller: read filtering evaluates `membersOnly` per instance, and a
    // lookup that answered only for the requester would be wrong for every
    // other fan the visibility rules touch.
    //
    // Without this, the engine's `_isActiveMember` fell through to its
    // no-lookup default of false, so every `membersOnly` instance was readable
    // by its creator alone. The client engine has always installed a lookup;
    // this service never did, which is why the same workflow behaved
    // differently on the device and on the server.
    _installActiveMembershipLookup(
      engine: engine,
      groupId: groupId,
      correlationId: correlationId,
    );

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

  /// Teaches [engine] to answer "is this fan an active member?" for this request.
  ///
  /// Memoised per call, because read filtering asks once per instance and a
  /// twenty-instance page would otherwise make twenty identical calls to App
  /// Access for the same fan. The cache lives no longer than the request: a
  /// membership revoked between two requests must take effect on the second.
  ///
  /// An App Access failure resolves to false rather than propagating. The
  /// alternative is a 500 on a read that is mostly cache-warm anyway, and
  /// failing closed matches every other visibility decision in the engine.
  void _installActiveMembershipLookup({
    required LocalWorkflowEngineApi engine,
    required String groupId,
    required String correlationId,
  }) {
    final cache = <String, Future<bool>>{};
    engine.setActiveMembershipLookup(
      (fanId) => cache.putIfAbsent(fanId, () async {
        try {
          return await _appAccessClient.hasActiveMembership(
            fanId: fanId,
            appId: _appId,
            groupId: groupId,
            correlationId: correlationId,
          );
        } on AppAccessDecisionException catch (_) {
          return false;
        } on SocketException catch (_) {
          return false;
        }
      }),
    );
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
    } on StateError catch (error, stackTrace) {
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
      _logUnexpectedError(request, error, stackTrace);
      return _error(
        request: request,
        statusCode: 500,
        code: 'workflow_service_error',
        message: 'The workflow fields could not be updated.',
      );
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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
    } on StateError catch (error, stackTrace) {
      return _mapEngineStateError(request, error, stackTrace);
    } catch (error, stackTrace) {
      _logUnexpectedError(request, error, stackTrace);
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

  Response _mapEngineStateError(
    Request request,
    StateError error,
    StackTrace stackTrace,
  ) {
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
    _logUnexpectedError(request, error, stackTrace);
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
    final correlationId = _correlationIdForRequest(request);
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

  void _logUnexpectedError(
    Request request,
    Object error,
    StackTrace stackTrace,
  ) {
    _unexpectedErrorLogSink(
      jsonEncode({
        'event': 'workflow_service_unexpected_error',
        'correlationId': _correlationIdForRequest(request),
        'method': request.method,
        'path': request.requestedUri.path,
        'errorType': error.runtimeType.toString(),
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      }),
    );
  }

  String _correlationIdForRequest(Request request) {
    final requestCorrelationId = request.headers['x-loom-correlation-id'];
    return requestCorrelationId != null &&
            _uuidPattern.hasMatch(requestCorrelationId)
        ? requestCorrelationId
        : _newCorrelationId();
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

class _ExportBundleRequestBody {
  const _ExportBundleRequestBody({
    required this.redactProtectedData,
    required this.componentIds,
    required this.includeDocuments,
  });

  final bool redactProtectedData;
  final List<String>? componentIds;
  final bool includeDocuments;
}

class _EmptyExportComponentIds extends FormatException {
  const _EmptyExportComponentIds() : super('componentIds must not be empty.');
}

class _ExportPayload {
  const _ExportPayload({required this.bytes, required this.recordCount});

  final List<int> bytes;
  final int recordCount;
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

/// Everything a document handler needs, resolved once by the preamble.
class _DocumentRequestContext {
  const _DocumentRequestContext({
    required this.identity,
    required this.correlationId,
    required this.groupId,
    required this.engine,
    required this.repository,
    required this.objectStore,
  });

  final WorkflowRequestIdentity identity;
  final String correlationId;
  final String groupId;
  final LocalWorkflowEngineApi engine;
  final DocumentRepository repository;
  final DocumentObjectStore objectStore;
}

/// Everything an item-queue handler needs, resolved once by its preamble.
class _ItemQueueRequestContext {
  const _ItemQueueRequestContext({
    required this.identity,
    required this.correlationId,
    required this.engine,
    required this.repository,
  });

  final WorkflowRequestIdentity identity;
  final String correlationId;
  final LocalWorkflowEngineApi engine;
  final ItemQueueRepository repository;
}

/// A missing instance is distinct from one the caller cannot read.
class _QueueInstanceLookup {
  const _QueueInstanceLookup({required this.exists, this.instance});

  final bool exists;
  final WorkflowInstance? instance;
}

/// Everything an export bundle handler needs, resolved once by its preamble.
class _ExportRequestContext {
  const _ExportRequestContext({
    required this.identity,
    required this.correlationId,
    required this.engine,
    required this.repository,
    required this.objectStore,
    required this.documentRepository,
  });

  final WorkflowRequestIdentity identity;
  final String correlationId;
  final LocalWorkflowEngineApi engine;
  final ExportBundleRepository repository;
  final DocumentObjectStore objectStore;
  final DocumentRepository? documentRepository;
}

class _ReadableExportBundle {
  const _ReadableExportBundle({required this.bundle, required this.instance});

  final StoredExportBundle bundle;
  final WorkflowInstance instance;
}

class _ReadableDocument {
  const _ReadableDocument({required this.document, required this.instance});

  final StoredDocument document;
  final WorkflowInstance instance;
}
