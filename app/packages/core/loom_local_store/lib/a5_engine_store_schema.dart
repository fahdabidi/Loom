class A5OwnedTable {
  const A5OwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A5EngineStoreSchema {
  static const tables = [
    A5OwnedTable(
      componentId: 'extension-runtime-bridge',
      tableName: 'community_extension_sessions',
      ownedFields: ['sessionId', 'extensionId', 'communityId', 'permissions'],
    ),
    A5OwnedTable(
      componentId: 'rule-engine',
      tableName: 'community_rules',
      ownedFields: ['ruleId', 'condition', 'action'],
    ),
    A5OwnedTable(
      componentId: 'workflow-engine',
      tableName: 'community_workflow_runs',
      ownedFields: ['workflowRunId', 'workflowId', 'state', 'currentStep'],
    ),
    A5OwnedTable(
      componentId: 'job-scheduler',
      tableName: 'community_jobs',
      ownedFields: ['jobId', 'ruleId', 'trigger', 'triggered'],
    ),
    A5OwnedTable(
      componentId: 'function-runtime',
      tableName: 'community_function_invocations',
      ownedFields: ['invocationId', 'functionId', 'allowed'],
    ),
    A5OwnedTable(
      componentId: 'data-schema-store',
      tableName: 'community_extension_schemas',
      ownedFields: ['schemaId', 'extensionId', 'indexableFields'],
    ),
    A5OwnedTable(
      componentId: 'secrets-connector-broker',
      tableName: 'community_scoped_secrets',
      ownedFields: ['secretId', 'extensionId', 'scope', 'redactedValue'],
    ),
    A5OwnedTable(
      componentId: 'extension-package-validator',
      tableName: 'community_extension_package_validations',
      ownedFields: ['packageId', 'valid', 'errors'],
    ),
    A5OwnedTable(
      componentId: 'initialization-package-schema',
      tableName: 'community_initialization_package_validations',
      ownedFields: ['packageId', 'importKey', 'brandingComplete'],
    ),
  ];

  const A5EngineStoreSchema._();
}
