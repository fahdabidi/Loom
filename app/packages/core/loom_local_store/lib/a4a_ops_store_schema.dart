class A4aOwnedTable {
  const A4aOwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A4aOpsStoreSchema {
  static const tables = [
    A4aOwnedTable(
      componentId: 'case-task-service',
      tableName: 'community_cases',
      ownedFields: ['caseId', 'communityId', 'status', 'assigneePassportId'],
    ),
    A4aOwnedTable(
      componentId: 'documents-service',
      tableName: 'community_documents',
      ownedFields: ['documentId', 'communityId', 'visibility', 'version'],
    ),
    A4aOwnedTable(
      componentId: 'facilities-service',
      tableName: 'community_facility_reservations',
      ownedFields: ['reservationId', 'facilityId', 'passportId', 'status'],
    ),
    A4aOwnedTable(
      componentId: 'import-service',
      tableName: 'community_import_runs',
      ownedFields: ['importId', 'sourceKind', 'recordCount', 'warnings'],
    ),
    A4aOwnedTable(
      componentId: 'export-service',
      tableName: 'community_export_bundles',
      ownedFields: ['exportId', 'componentIds', 'checksum', 'redacted'],
    ),
    A4aOwnedTable(
      componentId: 'provider-transfer-service',
      tableName: 'community_provider_transfers',
      ownedFields: ['transferId', 'exportId', 'targetProviderId', 'verified'],
    ),
    A4aOwnedTable(
      componentId: 'abuse-report-service',
      tableName: 'community_abuse_reports',
      ownedFields: ['reportId', 'reporterPassportId', 'subjectId', 'category'],
    ),
    A4aOwnedTable(
      componentId: 'moderation-case-service',
      tableName: 'community_moderation_cases',
      ownedFields: ['moderationCaseId', 'reportId', 'policyVersion', 'status'],
    ),
    A4aOwnedTable(
      componentId: 'incident-service',
      tableName: 'community_incidents',
      ownedFields: ['incidentId', 'communityId', 'subjectId', 'severity'],
    ),
    A4aOwnedTable(
      componentId: 'dispute-service',
      tableName: 'community_disputes',
      ownedFields: ['disputeId', 'communityId', 'subjectId', 'reason'],
    ),
  ];

  const A4aOpsStoreSchema._();
}
