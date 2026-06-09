import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'community_foundation_fake.dart';

class CommunityEngineServicesFakeBackend {
  CommunityEngineServicesFakeBackend({
    required this.foundation,
  }) {
    runtime = CommunityExtensionRuntimeFake(foundation.rolePolicy);
    rules = CommunityRuleEngineFake();
    workflows = CommunityWorkflowFake();
    jobs = CommunityJobSchedulerFake();
    functions = CommunityFunctionRuntimeFake();
    dataSchemas = CommunityDataSchemaFake();
    secrets = CommunitySecretsConnectorFake();
    extensionPackages = CommunityExtensionPackageFake();
    initializationPackages = CommunityInitializationPackageFake();
  }

  final CommunityFoundationFakeBackend foundation;

  late final CommunityExtensionRuntimeFake runtime;
  late final CommunityRuleEngineFake rules;
  late final CommunityWorkflowFake workflows;
  late final CommunityJobSchedulerFake jobs;
  late final CommunityFunctionRuntimeFake functions;
  late final CommunityDataSchemaFake dataSchemas;
  late final CommunitySecretsConnectorFake secrets;
  late final CommunityExtensionPackageFake extensionPackages;
  late final CommunityInitializationPackageFake initializationPackages;
}

class CommunityExtensionRuntimeFake implements CommunityExtensionRuntimeApi {
  CommunityExtensionRuntimeFake(this._policy);

  final CommunityRolePolicyApi _policy;
  final Map<String, CommunityExtensionSession> _sessionsByIdempotency = {};
  final Map<String, CommunityRuntimeCall> _callsByIdempotency = {};

  @override
  Future<CommunityExtensionSession> startSession({
    required String extensionId,
    required String communityId,
    required String passportId,
    required List<String> requestedPermissions,
    required String idempotencyKey,
  }) async {
    final existing = _sessionsByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final granted = <String>[];
    for (final permission in requestedPermissions) {
      final decision = await _policy.effectivePermission(
        actorId: passportId,
        communityId: communityId,
        permission: permission,
      );
      if (decision.allowed) {
        granted.add(permission);
      }
    }
    final session = CommunityExtensionSession(
      sessionId: 'extension_session_${_sessionsByIdempotency.length + 1}',
      extensionId: extensionId,
      communityId: communityId,
      passportId: passportId,
      permissions: List<String>.unmodifiable(granted),
    );
    _sessionsByIdempotency[idempotencyKey] = session;
    return session;
  }

  @override
  Future<CommunityRuntimeCall> callApi({
    required CommunityExtensionSession session,
    required String apiName,
    required Map<String, String> arguments,
    required String idempotencyKey,
  }) async {
    final existing = _callsByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final requiredPermission = arguments['requiredPermission'];
    final allowed =
        requiredPermission == null ||
        session.permissions.contains(requiredPermission);
    final call = CommunityRuntimeCall(
      callId: 'runtime_call_${_callsByIdempotency.length + 1}',
      apiName: apiName,
      allowed: allowed,
      result: allowed
          ? Map<String, String>.unmodifiable(arguments)
          : const {'error': 'permission-denied'},
    );
    _callsByIdempotency[idempotencyKey] = call;
    return call;
  }
}

class CommunityRuleEngineFake implements CommunityRuleEngineApi {
  @override
  Future<CommunityRuleDecision> evaluate({
    required String ruleId,
    required Map<String, String> facts,
    required String whenEqualsKey,
    required String whenEqualsValue,
    required String action,
  }) async {
    final matched = facts[whenEqualsKey] == whenEqualsValue;
    return CommunityRuleDecision(
      ruleId: ruleId,
      matched: matched,
      action: matched ? action : 'noop',
    );
  }
}

class CommunityWorkflowFake implements CommunityWorkflowApi {
  final Map<String, CommunityWorkflowRun> _runs = {};
  final Map<String, CommunityWorkflowRun> _byIdempotency = {};

  @override
  Future<CommunityWorkflowRun> startWorkflow({
    required String workflowId,
    required String firstStep,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final run = CommunityWorkflowRun(
      workflowRunId: 'workflow_run_${_runs.length + 1}',
      workflowId: workflowId,
      state: CommunityWorkflowState.started,
      currentStep: firstStep,
    );
    _runs[run.workflowRunId] = run;
    _byIdempotency[idempotencyKey] = run;
    return run;
  }

  @override
  Future<CommunityWorkflowRun> transition({
    required String workflowRunId,
    required String nextStep,
    required bool complete,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final current = _runs[workflowRunId];
    if (current == null) {
      throw StateError('unknown workflow run: $workflowRunId');
    }
    final updated = CommunityWorkflowRun(
      workflowRunId: current.workflowRunId,
      workflowId: current.workflowId,
      state: complete
          ? CommunityWorkflowState.completed
          : CommunityWorkflowState.waiting,
      currentStep: nextStep,
    );
    _runs[workflowRunId] = updated;
    _byIdempotency[idempotencyKey] = updated;
    return updated;
  }
}

class CommunityJobSchedulerFake implements CommunityJobSchedulerApi {
  final Map<String, CommunityScheduledJob> _jobs = {};
  final Map<String, CommunityScheduledJob> _byIdempotency = {};

  @override
  Future<CommunityScheduledJob> schedule({
    required String ruleId,
    required String trigger,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final job = CommunityScheduledJob(
      jobId: 'job_${_jobs.length + 1}',
      ruleId: ruleId,
      trigger: trigger,
      triggered: false,
    );
    _jobs[job.jobId] = job;
    _byIdempotency[idempotencyKey] = job;
    return job;
  }

  @override
  Future<CommunityScheduledJob> trigger({
    required String jobId,
    required String idempotencyKey,
  }) async {
    final current = _jobs[jobId];
    if (current == null) {
      throw StateError('unknown job: $jobId');
    }
    final triggered = CommunityScheduledJob(
      jobId: current.jobId,
      ruleId: current.ruleId,
      trigger: current.trigger,
      triggered: true,
    );
    _jobs[jobId] = triggered;
    return triggered;
  }
}

class CommunityFunctionRuntimeFake implements CommunityFunctionRuntimeApi {
  final Map<String, CommunityFunctionResult> _byIdempotency = {};

  @override
  Future<CommunityFunctionResult> invoke({
    required String functionId,
    required List<String> requestedPermissions,
    required List<String> grantedPermissions,
    required Map<String, String> input,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final allowed = requestedPermissions.every(grantedPermissions.contains);
    final result = CommunityFunctionResult(
      invocationId: 'function_${_byIdempotency.length + 1}',
      allowed: allowed,
      output: allowed
          ? Map<String, String>.unmodifiable(input)
          : const {'error': 'sandbox-permission-denied'},
    );
    _byIdempotency[idempotencyKey] = result;
    return result;
  }
}

class CommunityDataSchemaFake implements CommunityDataSchemaApi {
  final Map<String, CommunityDataSchema> _schemas = {};
  final Map<String, CommunityDataSchema> _byIdempotency = {};

  @override
  Future<CommunityDataSchema> registerSchema({
    required String extensionId,
    required String schemaId,
    required List<String> indexableFields,
    required bool exportable,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final schema = CommunityDataSchema(
      schemaId: schemaId,
      extensionId: extensionId,
      indexableFields: List<String>.unmodifiable(indexableFields),
      exportable: exportable,
    );
    _schemas[_key(extensionId, schemaId)] = schema;
    _byIdempotency[idempotencyKey] = schema;
    return schema;
  }

  @override
  Future<List<CommunityDataSchema>> exportableSchemas(String extensionId) async {
    return _schemas.values
        .where((schema) => schema.extensionId == extensionId && schema.exportable)
        .toList(growable: false);
  }

  String _key(String extensionId, String schemaId) {
    return '$extensionId::$schemaId';
  }
}

class CommunitySecretsConnectorFake implements CommunitySecretsConnectorApi {
  final Map<String, CommunityScopedSecret> _byIdempotency = {};

  @override
  Future<CommunityScopedSecret> storeSecret({
    required String extensionId,
    required String scope,
    required String value,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final secret = CommunityScopedSecret(
      secretId: 'secret_${_byIdempotency.length + 1}',
      extensionId: extensionId,
      scope: scope,
      redactedValue: value.isEmpty ? '' : '${value.substring(0, 1)}***',
    );
    _byIdempotency[idempotencyKey] = secret;
    return secret;
  }
}

class CommunityExtensionPackageFake implements CommunityExtensionPackageApi {
  @override
  Future<CommunityPackageValidation> validatePackage(
    CommunityExtensionPackageManifest manifest,
  ) async {
    final errors = <String>[];
    final requiredFiles = {
      'loom.extension.json',
      'ui/',
      'assets/',
      'schemas/',
      'rules/',
      'workflows/',
      'jobs/',
      'docs/',
    };
    for (final required in requiredFiles) {
      if (!manifest.files.contains(required)) {
        errors.add('missing:$required');
      }
    }
    if (manifest.defaultCardImage.isEmpty) {
      errors.add('missing-default-card-image');
    }
    for (final asset in manifest.assets) {
      if (!{'png', 'jpg', 'webp'}.contains(asset.kind)) {
        errors.add('unsupported-asset:${asset.path}');
      }
      if (asset.width > 2048 || asset.height > 2048) {
        errors.add('oversized-asset:${asset.path}');
      }
      if (asset.altText.isEmpty) {
        errors.add('missing-alt:${asset.path}');
      }
    }
    return CommunityPackageValidation(
      packageId: '${manifest.extensionId}-${manifest.version}',
      valid: errors.isEmpty,
      errors: List<String>.unmodifiable(errors),
    );
  }
}

class CommunityInitializationPackageFake
    implements CommunityInitializationPackageApi {
  final Map<String, CommunityInitializationValidation> _byImportKey = {};

  @override
  Future<CommunityInitializationValidation> validateInitialization(
    CommunityInitializationPackage package,
  ) async {
    final existing = _byImportKey[package.idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final brandingComplete =
        package.logoPath.isNotEmpty &&
        package.cardImagePath.isNotEmpty &&
        package.heroImagePath.isNotEmpty &&
        package.accentColor.startsWith('#');
    final validation = CommunityInitializationValidation(
      packageId: package.packageId,
      valid:
          package.communityHandle.isNotEmpty &&
          package.displayName.isNotEmpty &&
          brandingComplete,
      importKey: package.idempotencyKey,
      brandingComplete: brandingComplete,
    );
    _byImportKey[package.idempotencyKey] = validation;
    return validation;
  }
}
