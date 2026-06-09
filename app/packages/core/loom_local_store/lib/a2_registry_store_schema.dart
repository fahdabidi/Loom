class A2OwnedTable {
  const A2OwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A2RegistryStoreSchema {
  static const tables = [
    A2OwnedTable(
      componentId: 'community-registry',
      tableName: 'community_profiles',
      ownedFields: ['communityId', 'handle', 'displayName', 'branding'],
    ),
    A2OwnedTable(
      componentId: 'spaces-service',
      tableName: 'community_spaces',
      ownedFields: ['spaceId', 'communityId', 'parentSpaceId', 'name'],
    ),
    A2OwnedTable(
      componentId: 'membership-service',
      tableName: 'community_memberships',
      ownedFields: ['membershipId', 'communityId', 'passportId', 'state'],
    ),
    A2OwnedTable(
      componentId: 'invitation-service',
      tableName: 'community_invitations',
      ownedFields: ['invitationId', 'communityId', 'inviterPassportId'],
    ),
    A2OwnedTable(
      componentId: 'certification-system',
      tableName: 'community_certification_decisions',
      ownedFields: ['packageId', 'status', 'riskTier', 'assetEvidenceAccepted'],
    ),
    A2OwnedTable(
      componentId: 'extension-registry',
      tableName: 'community_extension_versions',
      ownedFields: ['extensionId', 'version', 'packageId', 'builderAppId'],
    ),
    A2OwnedTable(
      componentId: 'public-registry-read-model',
      tableName: 'community_public_registry_entries',
      ownedFields: ['communityId', 'handle', 'trustState'],
    ),
    A2OwnedTable(
      componentId: 'workflow-inventory-registry',
      tableName: 'community_workflow_inventory',
      ownedFields: ['workflowId', 'phase', 'ownerComponent', 'testIds'],
    ),
  ];

  const A2RegistryStoreSchema._();
}
