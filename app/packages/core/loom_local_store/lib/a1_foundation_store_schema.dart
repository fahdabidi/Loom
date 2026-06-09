class A1OwnedTable {
  const A1OwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A1FoundationStoreSchema {
  static const tables = [
    A1OwnedTable(
      componentId: 'passport-ledger',
      tableName: 'community_passports',
      ownedFields: ['passportId', 'displayName', 'version', 'createdAt'],
    ),
    A1OwnedTable(
      componentId: 'role-policy-consent-engine',
      tableName: 'community_permission_grants',
      ownedFields: ['actorId', 'communityId', 'permission', 'version'],
    ),
    A1OwnedTable(
      componentId: 'core-member-vault',
      tableName: 'community_core_preferences',
      ownedFields: ['passportId', 'key', 'value', 'version'],
    ),
    A1OwnedTable(
      componentId: 'protected-visibility-vault',
      tableName: 'community_protected_records',
      ownedFields: ['recordId', 'passportId', 'field', 'redactedValue'],
    ),
    A1OwnedTable(
      componentId: 'connections-graph',
      tableName: 'community_connections',
      ownedFields: ['connectionId', 'requesterPassportId', 'targetPassportId'],
    ),
    A1OwnedTable(
      componentId: 'receipt-ledger',
      tableName: 'community_receipts',
      ownedFields: ['receiptId', 'passportId', 'kind', 'amountCents'],
    ),
    A1OwnedTable(
      componentId: 'audit-ledger',
      tableName: 'community_audit_entries',
      ownedFields: ['auditId', 'actorId', 'componentId', 'action'],
    ),
    A1OwnedTable(
      componentId: 'event-bus',
      tableName: 'community_events',
      ownedFields: ['eventId', 'type', 'sourceComponent', 'subjectId'],
    ),
    A1OwnedTable(
      componentId: 'key-management',
      tableName: 'community_signing_keys',
      ownedFields: ['keyId', 'ownerId', 'scope', 'version'],
    ),
    A1OwnedTable(
      componentId: 'builder-app-id-service',
      tableName: 'community_builder_apps',
      ownedFields: ['appId', 'builderId', 'signingScope', 'keyId'],
    ),
  ];

  const A1FoundationStoreSchema._();
}
