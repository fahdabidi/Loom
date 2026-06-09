import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'community_foundation_fake.dart';

class CommunityRegistryControlPlaneFakeBackend {
  CommunityRegistryControlPlaneFakeBackend(this.foundation) {
    communityRegistry = CommunityRegistryFake();
    spaces = CommunitySpacesFake();
    membership = CommunityMembershipFake(communityRegistry);
    invitations = CommunityInvitationFake(foundation.connections);
    certification = CommunityCertificationFake();
    extensionRegistry = CommunityExtensionRegistryFake(
      certification,
      foundation.builderAppIds,
    );
    publicRegistry = CommunityPublicRegistryFake();
    workflowInventory = CommunityWorkflowInventoryFake();
    testManifest = CommunityTestManifestFake();
  }

  final CommunityFoundationFakeBackend foundation;

  late final CommunityRegistryFake communityRegistry;
  late final CommunitySpacesFake spaces;
  late final CommunityMembershipFake membership;
  late final CommunityInvitationFake invitations;
  late final CommunityCertificationFake certification;
  late final CommunityExtensionRegistryFake extensionRegistry;
  late final CommunityPublicRegistryFake publicRegistry;
  late final CommunityWorkflowInventoryFake workflowInventory;
  late final CommunityTestManifestFake testManifest;
}

class CommunityRegistryFake implements CommunityRegistryApi {
  final Map<String, CommunityProfile> _byId = {};
  final Map<String, CommunityProfile> _byHandle = {};
  final Map<String, CommunityProfile> _byQr = {};
  final Map<String, CommunityProfile> _byIdempotency = {};

  @override
  Future<CommunityProfile> registerCommunity({
    required String handle,
    required String displayName,
    required CommunityBranding branding,
    required String ownerPassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final profile = CommunityProfile(
      communityId: 'community_${_byId.length + 1}',
      handle: _normalizeHandle(handle),
      displayName: displayName,
      qrPayload: 'loom://community/${_normalizeHandle(handle)}',
      branding: branding,
      version: 1,
    );
    _byId[profile.communityId] = profile;
    _byHandle[profile.handle] = profile;
    _byQr[profile.qrPayload] = profile;
    _byIdempotency[idempotencyKey] = profile;
    return profile;
  }

  @override
  Future<CommunityProfile?> resolveByHandleOrQr(String handleOrQrPayload) async {
    return _byHandle[_normalizeHandle(handleOrQrPayload)] ??
        _byQr[handleOrQrPayload] ??
        _byId[handleOrQrPayload];
  }

  @override
  Future<CommunityProfile> updateBranding({
    required String communityId,
    required CommunityBranding branding,
    required String idempotencyKey,
  }) async {
    final current = _byId[communityId];
    if (current == null) {
      throw StateError('unknown community: $communityId');
    }
    final updated = CommunityProfile(
      communityId: current.communityId,
      handle: current.handle,
      displayName: current.displayName,
      qrPayload: current.qrPayload,
      branding: branding,
      version: current.version + 1,
    );
    _byId[communityId] = updated;
    _byHandle[updated.handle] = updated;
    _byQr[updated.qrPayload] = updated;
    return updated;
  }
}

class CommunitySpacesFake implements CommunitySpacesApi {
  final Map<String, CommunitySpace> _spaces = {};
  final Map<String, CommunitySpace> _byIdempotency = {};

  @override
  Future<CommunitySpace> createSpace({
    required String communityId,
    required String? parentSpaceId,
    required String name,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    if (parentSpaceId != null && !_spaces.containsKey(parentSpaceId)) {
      throw StateError('unknown parent space: $parentSpaceId');
    }
    final space = CommunitySpace(
      spaceId: 'space_${_spaces.length + 1}',
      communityId: communityId,
      parentSpaceId: parentSpaceId,
      name: name,
      version: 1,
    );
    _spaces[space.spaceId] = space;
    _byIdempotency[idempotencyKey] = space;
    return space;
  }

  @override
  Future<List<CommunitySpace>> listSpaces(String communityId) async {
    return _spaces.values
        .where((space) => space.communityId == communityId)
        .toList(growable: false);
  }
}

class CommunityMembershipFake implements CommunityMembershipApi {
  CommunityMembershipFake(this._registry);

  final CommunityRegistryApi _registry;
  final Map<String, CommunityMembership> _memberships = {};
  final Map<String, CommunityMembership> _byIdempotency = {};

  @override
  Future<CommunityMembership> requestJoin({
    required String communityId,
    required String passportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final community = await _registry.resolveByHandleOrQr(communityId);
    if (community == null) {
      throw StateError('unknown community: $communityId');
    }
    final membership = CommunityMembership(
      membershipId: 'membership_${_memberships.length + 1}',
      communityId: community.communityId,
      passportId: passportId,
      state: CommunityMembershipState.requested,
      version: 1,
    );
    _memberships[membership.membershipId] = membership;
    _byIdempotency[idempotencyKey] = membership;
    return membership;
  }

  @override
  Future<CommunityMembership> approveJoin({
    required String membershipId,
    required String approvedBy,
    required String idempotencyKey,
  }) async {
    final current = _memberships[membershipId];
    if (current == null) {
      throw StateError('unknown membership: $membershipId');
    }
    final approved = CommunityMembership(
      membershipId: current.membershipId,
      communityId: current.communityId,
      passportId: current.passportId,
      state: CommunityMembershipState.active,
      version: current.version + 1,
    );
    _memberships[membershipId] = approved;
    return approved;
  }

  @override
  Future<CommunityMembership?> memberState({
    required String communityId,
    required String passportId,
  }) async {
    for (final membership in _memberships.values) {
      if (membership.communityId == communityId &&
          membership.passportId == passportId) {
        return membership;
      }
    }
    return null;
  }
}

class CommunityInvitationFake implements CommunityInvitationApi {
  CommunityInvitationFake(this._connections);

  final CommunityConnectionsApi _connections;
  final Map<String, CommunityInvitation> _invitations = {};
  final Map<String, CommunityInvitation> _byIdempotency = {};

  @override
  Future<CommunityInvitation> createInvitation({
    required String communityId,
    required String inviterPassportId,
    required String inviteePassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final canInvite = await _connections.canInvite(
      requesterPassportId: inviterPassportId,
      targetPassportId: inviteePassportId,
    );
    if (!canInvite) {
      throw StateError('connection path is blocked');
    }
    final invitation = CommunityInvitation(
      invitationId: 'invitation_${_invitations.length + 1}',
      communityId: communityId,
      inviterPassportId: inviterPassportId,
      inviteePassportId: inviteePassportId,
      revoked: false,
      version: 1,
    );
    _invitations[invitation.invitationId] = invitation;
    _byIdempotency[idempotencyKey] = invitation;
    return invitation;
  }

  @override
  Future<CommunityInvitation> revokeInvitation({
    required String invitationId,
    required String idempotencyKey,
  }) async {
    final current = _invitations[invitationId];
    if (current == null) {
      throw StateError('unknown invitation: $invitationId');
    }
    final revoked = CommunityInvitation(
      invitationId: current.invitationId,
      communityId: current.communityId,
      inviterPassportId: current.inviterPassportId,
      inviteePassportId: current.inviteePassportId,
      revoked: true,
      version: current.version + 1,
    );
    _invitations[invitationId] = revoked;
    return revoked;
  }
}

class CommunityCertificationFake implements CommunityCertificationApi {
  final Map<String, CommunityCertificationDecision> _decisions = {};
  final Map<String, CommunityCertificationDecision> _byIdempotency = {};

  @override
  Future<CommunityCertificationDecision> validatePackage({
    required String packageId,
    required bool assetEvidencePresent,
    required List<String> permissions,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final decision = CommunityCertificationDecision(
      packageId: packageId,
      status: assetEvidencePresent
          ? CommunityCertificationStatus.certified
          : CommunityCertificationStatus.rejected,
      riskTier: permissions.length > 4 ? 'elevated' : 'standard',
      assetEvidenceAccepted: assetEvidencePresent,
      version: 1,
    );
    _decisions[packageId] = decision;
    _byIdempotency[idempotencyKey] = decision;
    return decision;
  }

  Future<CommunityCertificationDecision?> decisionFor(String packageId) async {
    return _decisions[packageId];
  }
}

class CommunityExtensionRegistryFake implements CommunityExtensionRegistryApi {
  CommunityExtensionRegistryFake(this._certification, this._builderApps);

  final CommunityCertificationFake _certification;
  final CommunityBuilderAppIdApi _builderApps;
  final Map<String, List<CommunityExtensionVersion>> _versions = {};

  @override
  Future<CommunityExtensionVersion> publishVersion({
    required String extensionId,
    required String packageId,
    required String builderAppId,
    required String signingScope,
    required String idempotencyKey,
  }) async {
    final signingOk = await _builderApps.verifySigningScope(
      appId: builderAppId,
      signingScope: signingScope,
    );
    if (!signingOk) {
      throw StateError('builder app signing scope rejected');
    }
    final decision = await _certification.decisionFor(packageId);
    if (decision?.status != CommunityCertificationStatus.certified) {
      throw StateError('package is not certified');
    }
    final existing = _versions[extensionId] ?? const <CommunityExtensionVersion>[];
    final version = CommunityExtensionVersion(
      extensionId: extensionId,
      version: existing.length + 1,
      packageId: packageId,
      certificationStatus: decision!.status,
      builderAppId: builderAppId,
    );
    _versions[extensionId] = [...existing, version];
    return version;
  }

  @override
  Future<CommunityExtensionVersion?> resolveLatest(String extensionId) async {
    final versions = _versions[extensionId];
    if (versions == null || versions.isEmpty) {
      return null;
    }
    return versions.last;
  }
}

class CommunityPublicRegistryFake implements CommunityPublicRegistryApi {
  final Map<String, CommunityPublicRegistryEntry> _byHandle = {};

  @override
  Future<CommunityPublicRegistryEntry> projectCommunity({
    required CommunityProfile profile,
    required int certifiedExtensionCount,
  }) async {
    final entry = CommunityPublicRegistryEntry(
      communityId: profile.communityId,
      handle: profile.handle,
      displayName: profile.displayName,
      trustState: certifiedExtensionCount > 0 ? 'certified' : 'unverified',
      certifiedExtensionCount: certifiedExtensionCount,
    );
    _byHandle[entry.handle] = entry;
    return entry;
  }

  @override
  Future<CommunityPublicRegistryEntry?> getPublicEntry(String handle) async {
    return _byHandle[_normalizeHandle(handle)];
  }
}

class CommunityWorkflowInventoryFake implements CommunityWorkflowInventoryApi {
  final List<CommunityWorkflowDescriptor> _workflows = [];

  @override
  Future<CommunityWorkflowDescriptor> registerWorkflow({
    required String workflowId,
    required String phase,
    required String ownerComponent,
    required List<String> testIds,
  }) async {
    final descriptor = CommunityWorkflowDescriptor(
      workflowId: workflowId,
      phase: phase,
      ownerComponent: ownerComponent,
      testIds: List<String>.unmodifiable(testIds),
    );
    _workflows.removeWhere((item) => item.workflowId == workflowId);
    _workflows.add(descriptor);
    return descriptor;
  }

  @override
  Future<List<CommunityWorkflowDescriptor>> listByPhase(String phase) async {
    return _workflows
        .where((workflow) => workflow.phase == phase)
        .toList(growable: false);
  }
}

class CommunityTestManifestFake implements CommunityTestManifestApi {
  final Map<String, CommunityManifestTestStatus> _statuses = {};

  @override
  Future<CommunityManifestTestStatus> recordStatus({
    required String testId,
    required String status,
    required bool stale,
  }) async {
    final record = CommunityManifestTestStatus(
      testId: testId,
      status: status,
      stale: stale,
    );
    _statuses[testId] = record;
    return record;
  }

  @override
  Future<List<CommunityManifestTestStatus>> staleTests() async {
    return _statuses.values
        .where((status) => status.stale)
        .toList(growable: false);
  }
}

String _normalizeHandle(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
