enum CommunityWorkflowState { started, waiting, completed }

class CommunityExtensionSession {
  const CommunityExtensionSession({
    required this.sessionId,
    required this.extensionId,
    required this.communityId,
    required this.passportId,
    required this.permissions,
  });

  final String sessionId;
  final String extensionId;
  final String communityId;
  final String passportId;
  final List<String> permissions;
}

class CommunityRuntimeCall {
  const CommunityRuntimeCall({
    required this.callId,
    required this.apiName,
    required this.allowed,
    required this.result,
  });

  final String callId;
  final String apiName;
  final bool allowed;
  final Map<String, String> result;
}

class CommunityRuleDecision {
  const CommunityRuleDecision({
    required this.ruleId,
    required this.matched,
    required this.action,
  });

  final String ruleId;
  final bool matched;
  final String action;
}

class CommunityWorkflowRun {
  const CommunityWorkflowRun({
    required this.workflowRunId,
    required this.workflowId,
    required this.state,
    required this.currentStep,
  });

  final String workflowRunId;
  final String workflowId;
  final CommunityWorkflowState state;
  final String currentStep;
}

class CommunityScheduledJob {
  const CommunityScheduledJob({
    required this.jobId,
    required this.ruleId,
    required this.trigger,
    required this.triggered,
  });

  final String jobId;
  final String ruleId;
  final String trigger;
  final bool triggered;
}

class CommunityFunctionResult {
  const CommunityFunctionResult({
    required this.invocationId,
    required this.allowed,
    required this.output,
  });

  final String invocationId;
  final bool allowed;
  final Map<String, String> output;
}

class CommunityDataSchema {
  const CommunityDataSchema({
    required this.schemaId,
    required this.extensionId,
    required this.indexableFields,
    required this.exportable,
  });

  final String schemaId;
  final String extensionId;
  final List<String> indexableFields;
  final bool exportable;
}

class CommunityScopedSecret {
  const CommunityScopedSecret({
    required this.secretId,
    required this.extensionId,
    required this.scope,
    required this.redactedValue,
  });

  final String secretId;
  final String extensionId;
  final String scope;
  final String redactedValue;
}

class CommunityPackageAsset {
  const CommunityPackageAsset({
    required this.path,
    required this.sha256,
    required this.kind,
    required this.width,
    required this.height,
    required this.altText,
  });

  final String path;
  final String sha256;
  final String kind;
  final int width;
  final int height;
  final String altText;
}

class CommunityExtensionPackageManifest {
  const CommunityExtensionPackageManifest({
    required this.extensionId,
    required this.version,
    required this.files,
    required this.assets,
    required this.defaultCardImage,
  });

  final String extensionId;
  final String version;
  final List<String> files;
  final List<CommunityPackageAsset> assets;
  final String defaultCardImage;
}

class CommunityPackageValidation {
  const CommunityPackageValidation({
    required this.packageId,
    required this.valid,
    required this.errors,
  });

  final String packageId;
  final bool valid;
  final List<String> errors;
}

class CommunityInitializationPackage {
  const CommunityInitializationPackage({
    required this.packageId,
    required this.communityHandle,
    required this.displayName,
    required this.logoPath,
    required this.cardImagePath,
    required this.heroImagePath,
    required this.accentColor,
    required this.idempotencyKey,
  });

  final String packageId;
  final String communityHandle;
  final String displayName;
  final String logoPath;
  final String cardImagePath;
  final String heroImagePath;
  final String accentColor;
  final String idempotencyKey;
}

class CommunityInitializationValidation {
  const CommunityInitializationValidation({
    required this.packageId,
    required this.valid,
    required this.importKey,
    required this.brandingComplete,
  });

  final String packageId;
  final bool valid;
  final String importKey;
  final bool brandingComplete;
}

abstract class CommunityExtensionRuntimeApi {
  Future<CommunityExtensionSession> startSession({
    required String extensionId,
    required String communityId,
    required String passportId,
    required List<String> requestedPermissions,
    required String idempotencyKey,
  });

  Future<CommunityRuntimeCall> callApi({
    required CommunityExtensionSession session,
    required String apiName,
    required Map<String, String> arguments,
    required String idempotencyKey,
  });
}

abstract class CommunityRuleEngineApi {
  Future<CommunityRuleDecision> evaluate({
    required String ruleId,
    required Map<String, String> facts,
    required String whenEqualsKey,
    required String whenEqualsValue,
    required String action,
  });
}

abstract class CommunityWorkflowApi {
  Future<CommunityWorkflowRun> startWorkflow({
    required String workflowId,
    required String firstStep,
    required String idempotencyKey,
  });

  Future<CommunityWorkflowRun> transition({
    required String workflowRunId,
    required String nextStep,
    required bool complete,
    required String idempotencyKey,
  });
}

abstract class CommunityJobSchedulerApi {
  Future<CommunityScheduledJob> schedule({
    required String ruleId,
    required String trigger,
    required String idempotencyKey,
  });

  Future<CommunityScheduledJob> trigger({
    required String jobId,
    required String idempotencyKey,
  });
}

abstract class CommunityFunctionRuntimeApi {
  Future<CommunityFunctionResult> invoke({
    required String functionId,
    required List<String> requestedPermissions,
    required List<String> grantedPermissions,
    required Map<String, String> input,
    required String idempotencyKey,
  });
}

abstract class CommunityDataSchemaApi {
  Future<CommunityDataSchema> registerSchema({
    required String extensionId,
    required String schemaId,
    required List<String> indexableFields,
    required bool exportable,
    required String idempotencyKey,
  });

  Future<List<CommunityDataSchema>> exportableSchemas(String extensionId);
}

abstract class CommunitySecretsConnectorApi {
  Future<CommunityScopedSecret> storeSecret({
    required String extensionId,
    required String scope,
    required String value,
    required String idempotencyKey,
  });
}

abstract class CommunityExtensionPackageApi {
  Future<CommunityPackageValidation> validatePackage(
    CommunityExtensionPackageManifest manifest,
  );
}

abstract class CommunityInitializationPackageApi {
  Future<CommunityInitializationValidation> validateInitialization(
    CommunityInitializationPackage package,
  );
}
