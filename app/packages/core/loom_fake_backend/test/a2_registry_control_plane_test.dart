import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a2_registry_store_schema.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A2 registry/control-plane validation tests', () {
    test('vt_workflow-inventory_test-index', () async {
      final backend = _backend();
      await backend.workflowInventory.registerWorkflow(
        workflowId: 'wf_book-club-headline',
        phase: 'B2',
        ownerComponent: 'workflow-engine',
        testIds: ['wf_book-club-headline'],
      );
      final workflows = await backend.workflowInventory.listByPhase('B2');

      expect(workflows.single.workflowId, 'wf_book-club-headline');
      expect(workflows.single.testIds, contains('wf_book-club-headline'));
    });

    test('vt_test-manifest_staleness', () async {
      final backend = _backend();
      await backend.testManifest.recordStatus(
        testId: 'vt_example',
        status: 'stale',
        stale: true,
      );
      await backend.testManifest.recordStatus(
        testId: 'vt_current',
        status: 'pass',
        stale: false,
      );

      final stale = await backend.testManifest.staleTests();
      expect(stale.map((item) => item.testId), ['vt_example']);
    });

    test('vt_community-registry_discovery', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final byHandle = await backend.communityRegistry.resolveByHandleOrQr(
        communityRegistrySeed.handle,
      );
      final byQr = await backend.communityRegistry.resolveByHandleOrQr(
        profile.qrPayload,
      );

      expect(byHandle?.communityId, profile.communityId);
      expect(byQr?.handle, 'book-club');
    });

    test('vt_community-registry_branding', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final updated = await backend.communityRegistry.updateBranding(
        communityId: profile.communityId,
        branding: const CommunityBranding(
          logoAssetId: 'asset_logo_updated',
          cardImageAssetId: 'asset_card_updated',
          accentColor: '#246B62',
          altText: 'Updated book club table',
        ),
        idempotencyKey: 'branding-update',
      );

      expect(updated.branding.cardImageAssetId, 'asset_card_updated');
      expect(updated.version, 2);
    });

    test('vt_spaces_nesting', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final root = await backend.spaces.createSpace(
        communityId: profile.communityId,
        parentSpaceId: null,
        name: 'Main',
        idempotencyKey: 'space-main',
      );
      final child = await backend.spaces.createSpace(
        communityId: profile.communityId,
        parentSpaceId: root.spaceId,
        name: 'January Read',
        idempotencyKey: 'space-january',
      );
      final spaces = await backend.spaces.listSpaces(profile.communityId);

      expect(child.parentSpaceId, root.spaceId);
      expect(spaces, hasLength(2));
      expect(A2RegistryStoreSchema.tables.map((table) => table.tableName), contains('community_spaces'));
    });

    test('vt_membership_join-approval', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final membership = await backend.membership.requestJoin(
        communityId: profile.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'join-request',
      );
      final approved = await backend.membership.approveJoin(
        membershipId: membership.membershipId,
        approvedBy: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'join-approve',
      );
      final state = await backend.membership.memberState(
        communityId: profile.communityId,
        passportId: communityFoundationSeed.memberPassportId,
      );

      expect(approved.state, CommunityMembershipState.active);
      expect(state?.state, CommunityMembershipState.active);
    });

    test('vt_invitation_create-revoke', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final invitation = await backend.invitations.createInvitation(
        communityId: profile.communityId,
        inviterPassportId: 'passport_a',
        inviteePassportId: 'passport_b',
        idempotencyKey: 'invite-b',
      );
      final revoked = await backend.invitations.revokeInvitation(
        invitationId: invitation.invitationId,
        idempotencyKey: 'revoke-b',
      );

      expect(invitation.revoked, isFalse);
      expect(revoked.revoked, isTrue);
      expect(revoked.version, 2);
    });

    test('vt_extension-registry_resolve-latest', () async {
      final backend = _backend();
      final app = await _registerBuilderApp(backend.foundation);
      await _certify(backend);
      final first = await backend.extensionRegistry.publishVersion(
        extensionId: communityRegistrySeed.extensionId,
        packageId: communityRegistrySeed.packageId,
        builderAppId: app.appId,
        signingScope: 'community.extension.sign',
        idempotencyKey: 'publish-1',
      );
      final latest = await backend.extensionRegistry.resolveLatest(
        communityRegistrySeed.extensionId,
      );

      expect(first.certificationStatus, CommunityCertificationStatus.certified);
      expect(latest?.version, 1);
    });

    test('vt_certification_validate-package', () async {
      final backend = _backend();
      final decision = await _certify(backend);

      expect(decision.status, CommunityCertificationStatus.certified);
      expect(decision.riskTier, 'standard');
    });

    test('vt_certification_asset-evidence', () async {
      final backend = _backend();
      final rejected = await backend.certification.validatePackage(
        packageId: 'pkg_missing_assets',
        assetEvidencePresent: false,
        permissions: ['read.community'],
        idempotencyKey: 'cert-missing-assets',
      );

      expect(rejected.status, CommunityCertificationStatus.rejected);
      expect(rejected.assetEvidenceAccepted, isFalse);
    });

    test('vt_public-registry_status', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final entry = await backend.publicRegistry.projectCommunity(
        profile: profile,
        certifiedExtensionCount: 1,
      );
      final loaded = await backend.publicRegistry.getPublicEntry('book-club');

      expect(entry.trustState, 'certified');
      expect(loaded?.displayName, communityRegistrySeed.displayName);
    });
  });

  group('A2 built-counterpart consumer contract tests', () {
    test('ct_certification__extension-registry_certify-package', () async {
      final backend = _backend();
      final app = await _registerBuilderApp(backend.foundation);
      await _certify(backend);
      final version = await backend.extensionRegistry.publishVersion(
        extensionId: communityRegistrySeed.extensionId,
        packageId: communityRegistrySeed.packageId,
        builderAppId: app.appId,
        signingScope: 'community.extension.sign',
        idempotencyKey: 'contract-publish-certified',
      );

      expect(version.certificationStatus, CommunityCertificationStatus.certified);
    });

    test('ct_community-registry__extension-registry_installed-pointers', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final resolved = await backend.communityRegistry.resolveByHandleOrQr(
        profile.qrPayload,
      );

      expect(resolved?.communityId, profile.communityId);
      expect(resolved?.branding.logoAssetId, communityRegistrySeed.logoAssetId);
    });

    test('ct_invitation__membership_accept', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final invitation = await backend.invitations.createInvitation(
        communityId: profile.communityId,
        inviterPassportId: 'passport_a',
        inviteePassportId: 'passport_b',
        idempotencyKey: 'contract-invite',
      );
      final membership = await backend.membership.requestJoin(
        communityId: invitation.communityId,
        passportId: invitation.inviteePassportId,
        idempotencyKey: 'contract-join',
      );

      expect(membership.state, CommunityMembershipState.requested);
    });

    test('ct_spaces__membership_space-join', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      final space = await backend.spaces.createSpace(
        communityId: profile.communityId,
        parentSpaceId: null,
        name: 'Members',
        idempotencyKey: 'contract-space',
      );
      final membership = await backend.membership.requestJoin(
        communityId: space.communityId,
        passportId: 'passport_space_member',
        idempotencyKey: 'contract-space-join',
      );

      expect(membership.communityId, profile.communityId);
    });
  });

  group('A1 provider contract tests unblocked by A2', () {
    test('ct_connections__invitation_blocked-path', () async {
      final backend = _backend();
      final profile = await _registerCommunity(backend);
      await backend.foundation.connections.block(
        requesterPassportId: 'passport_a',
        targetPassportId: 'passport_b',
        idempotencyKey: 'contract-block',
      );

      expect(
        () => backend.invitations.createInvitation(
          communityId: profile.communityId,
          inviterPassportId: 'passport_a',
          inviteePassportId: 'passport_b',
          idempotencyKey: 'contract-blocked-invite',
        ),
        throwsStateError,
      );
    });

    test('ct_builder-app-id__extension-registry_signing-scope', () async {
      final backend = _backend();
      final app = await _registerBuilderApp(backend.foundation);
      await _certify(backend);

      expect(
        () => backend.extensionRegistry.publishVersion(
          extensionId: communityRegistrySeed.extensionId,
          packageId: communityRegistrySeed.packageId,
          builderAppId: app.appId,
          signingScope: 'wrong.scope',
          idempotencyKey: 'contract-wrong-scope',
        ),
        throwsStateError,
      );
    });
  });

  group('A2 pending counterpart contract kits', () {
    test(
      'ct_community-registry__app-shell_resolve-by-qr',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_extension-registry__app-shell_resolve-latest',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_membership__app-shell_member-state',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_public-registry__app-shell_trust-state',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
  });
}

CommunityRegistryControlPlaneFakeBackend _backend() {
  return CommunityRegistryControlPlaneFakeBackend(
    CommunityFoundationFakeBackend(),
  );
}

Future<CommunityProfile> _registerCommunity(
  CommunityRegistryControlPlaneFakeBackend backend,
) {
  return backend.communityRegistry.registerCommunity(
    handle: communityRegistrySeed.handle,
    displayName: communityRegistrySeed.displayName,
    branding: CommunityBranding(
      logoAssetId: communityRegistrySeed.logoAssetId,
      cardImageAssetId: communityRegistrySeed.cardImageAssetId,
      accentColor: '#246B62',
      altText: 'Book club around a table',
    ),
    ownerPassportId: communityFoundationSeed.ownerActorId,
    idempotencyKey: 'register-community',
  );
}

Future<CommunityCertificationDecision> _certify(
  CommunityRegistryControlPlaneFakeBackend backend,
) {
  return backend.certification.validatePackage(
    packageId: communityRegistrySeed.packageId,
    assetEvidencePresent: true,
    permissions: ['read.community', 'write.workflow'],
    idempotencyKey: 'certify-book-club',
  );
}

Future<CommunityBuilderApp> _registerBuilderApp(
  CommunityFoundationFakeBackend foundation,
) {
  return foundation.builderAppIds.registerBuilderApp(
    builderId: 'builder_ada',
    signingScope: 'community.extension.sign',
    idempotencyKey: 'builder-a2',
  );
}
