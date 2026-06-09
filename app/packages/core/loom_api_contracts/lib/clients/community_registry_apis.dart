enum CommunityMembershipState { requested, active, revoked }

enum CommunityCertificationStatus { draft, certified, rejected }

class CommunityBranding {
  const CommunityBranding({
    required this.logoAssetId,
    required this.cardImageAssetId,
    required this.accentColor,
    required this.altText,
  });

  final String logoAssetId;
  final String cardImageAssetId;
  final String accentColor;
  final String altText;
}

class CommunityProfile {
  const CommunityProfile({
    required this.communityId,
    required this.handle,
    required this.displayName,
    required this.qrPayload,
    required this.branding,
    required this.version,
  });

  final String communityId;
  final String handle;
  final String displayName;
  final String qrPayload;
  final CommunityBranding branding;
  final int version;
}

class CommunitySpace {
  const CommunitySpace({
    required this.spaceId,
    required this.communityId,
    required this.parentSpaceId,
    required this.name,
    required this.version,
  });

  final String spaceId;
  final String communityId;
  final String? parentSpaceId;
  final String name;
  final int version;
}

class CommunityMembership {
  const CommunityMembership({
    required this.membershipId,
    required this.communityId,
    required this.passportId,
    required this.state,
    required this.version,
  });

  final String membershipId;
  final String communityId;
  final String passportId;
  final CommunityMembershipState state;
  final int version;
}

class CommunityInvitation {
  const CommunityInvitation({
    required this.invitationId,
    required this.communityId,
    required this.inviterPassportId,
    required this.inviteePassportId,
    required this.revoked,
    required this.version,
  });

  final String invitationId;
  final String communityId;
  final String inviterPassportId;
  final String inviteePassportId;
  final bool revoked;
  final int version;
}

class CommunityCertificationDecision {
  const CommunityCertificationDecision({
    required this.packageId,
    required this.status,
    required this.riskTier,
    required this.assetEvidenceAccepted,
    required this.version,
  });

  final String packageId;
  final CommunityCertificationStatus status;
  final String riskTier;
  final bool assetEvidenceAccepted;
  final int version;
}

class CommunityExtensionVersion {
  const CommunityExtensionVersion({
    required this.extensionId,
    required this.version,
    required this.packageId,
    required this.certificationStatus,
    required this.builderAppId,
  });

  final String extensionId;
  final int version;
  final String packageId;
  final CommunityCertificationStatus certificationStatus;
  final String builderAppId;
}

class CommunityPublicRegistryEntry {
  const CommunityPublicRegistryEntry({
    required this.communityId,
    required this.handle,
    required this.displayName,
    required this.trustState,
    required this.certifiedExtensionCount,
  });

  final String communityId;
  final String handle;
  final String displayName;
  final String trustState;
  final int certifiedExtensionCount;
}

class CommunityWorkflowDescriptor {
  const CommunityWorkflowDescriptor({
    required this.workflowId,
    required this.phase,
    required this.ownerComponent,
    required this.testIds,
  });

  final String workflowId;
  final String phase;
  final String ownerComponent;
  final List<String> testIds;
}

class CommunityManifestTestStatus {
  const CommunityManifestTestStatus({
    required this.testId,
    required this.status,
    required this.stale,
  });

  final String testId;
  final String status;
  final bool stale;
}

abstract class CommunityRegistryApi {
  Future<CommunityProfile> registerCommunity({
    required String handle,
    required String displayName,
    required CommunityBranding branding,
    required String ownerPassportId,
    required String idempotencyKey,
  });

  Future<CommunityProfile?> resolveByHandleOrQr(String handleOrQrPayload);

  Future<CommunityProfile> updateBranding({
    required String communityId,
    required CommunityBranding branding,
    required String idempotencyKey,
  });
}

abstract class CommunitySpacesApi {
  Future<CommunitySpace> createSpace({
    required String communityId,
    required String? parentSpaceId,
    required String name,
    required String idempotencyKey,
  });

  Future<List<CommunitySpace>> listSpaces(String communityId);
}

abstract class CommunityMembershipApi {
  Future<CommunityMembership> requestJoin({
    required String communityId,
    required String passportId,
    required String idempotencyKey,
  });

  Future<CommunityMembership> approveJoin({
    required String membershipId,
    required String approvedBy,
    required String idempotencyKey,
  });

  Future<CommunityMembership?> memberState({
    required String communityId,
    required String passportId,
  });
}

abstract class CommunityInvitationApi {
  Future<CommunityInvitation> createInvitation({
    required String communityId,
    required String inviterPassportId,
    required String inviteePassportId,
    required String idempotencyKey,
  });

  Future<CommunityInvitation> revokeInvitation({
    required String invitationId,
    required String idempotencyKey,
  });
}

abstract class CommunityCertificationApi {
  Future<CommunityCertificationDecision> validatePackage({
    required String packageId,
    required bool assetEvidencePresent,
    required List<String> permissions,
    required String idempotencyKey,
  });
}

abstract class CommunityExtensionRegistryApi {
  Future<CommunityExtensionVersion> publishVersion({
    required String extensionId,
    required String packageId,
    required String builderAppId,
    required String signingScope,
    required String idempotencyKey,
  });

  Future<CommunityExtensionVersion?> resolveLatest(String extensionId);
}

abstract class CommunityPublicRegistryApi {
  Future<CommunityPublicRegistryEntry> projectCommunity({
    required CommunityProfile profile,
    required int certifiedExtensionCount,
  });

  Future<CommunityPublicRegistryEntry?> getPublicEntry(String handle);
}

abstract class CommunityWorkflowInventoryApi {
  Future<CommunityWorkflowDescriptor> registerWorkflow({
    required String workflowId,
    required String phase,
    required String ownerComponent,
    required List<String> testIds,
  });

  Future<List<CommunityWorkflowDescriptor>> listByPhase(String phase);
}

abstract class CommunityTestManifestApi {
  Future<CommunityManifestTestStatus> recordStatus({
    required String testId,
    required String status,
    required bool stale,
  });

  Future<List<CommunityManifestTestStatus>> staleTests();
}
