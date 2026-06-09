import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';

void main() {
  test('wf_build-publish-discover-install', () async {
    final foundation = CommunityFoundationFakeBackend();
    final controlPlane = CommunityRegistryControlPlaneFakeBackend(foundation);
    final localBackend = LocalInAppBackend();
    final shell = CommunityAppShellRuntime();
    final package = _extensionPackage();

    final builderApp = await foundation.builderAppIds.registerBuilderApp(
      builderId: 'skill_book_club_builder',
      signingScope: 'extensions.publish:book-club',
      idempotencyKey: 'b1b-builder-app',
    );
    final certification = await controlPlane.certification.validatePackage(
      packageId: communityRegistrySeed.packageId,
      assetEvidencePresent: true,
      permissions: package.permissions,
      idempotencyKey: 'b1b-certify-package',
    );
    final published = await controlPlane.extensionRegistry.publishVersion(
      extensionId: package.extensionId,
      packageId: communityRegistrySeed.packageId,
      builderAppId: builderApp.appId,
      signingScope: builderApp.signingScope,
      idempotencyKey: 'b1b-publish-version',
    );
    final profile = await controlPlane.communityRegistry.registerCommunity(
      handle: communityRegistrySeed.handle,
      displayName: communityRegistrySeed.displayName,
      branding: const CommunityBranding(
        logoAssetId: 'asset_logo_book_club',
        cardImageAssetId: 'asset_card_book_club',
        accentColor: '#246B62',
        altText: 'Book club table',
      ),
      ownerPassportId: communityFoundationSeed.ownerActorId,
      idempotencyKey: 'b1b-register-community',
    );
    await controlPlane.publicRegistry.projectCommunity(
      profile: profile,
      certifiedExtensionCount: 1,
    );

    final byHandle = await controlPlane.communityRegistry.resolveByHandleOrQr(
      'book-club',
    );
    final byQr = await controlPlane.communityRegistry.resolveByHandleOrQr(
      profile.qrPayload,
    );
    final publicEntry = await controlPlane.publicRegistry.getPublicEntry(
      'book-club',
    );
    final latest = await controlPlane.extensionRegistry.resolveLatest(
      package.extensionId,
    );

    localBackend.loadExtensionPackage(package);
    final imported = localBackend.importInitializationPackage(
      _initializationPackage(profile.communityId),
      logoAssetId: profile.branding.logoAssetId,
    );
    shell.installCommunity(
      CommunityCardProps(
        communityId: imported.community.communityId,
        handle: profile.handle,
        branding: CommunityCardBranding(
          displayName: imported.community.displayName,
          tagline: 'Certified extension',
          category: 'book',
          accentColor: profile.branding.accentColor,
          altText: profile.branding.altText,
          logoAssetId: imported.community.logoAssetId,
          cardImageAssetId: imported.community.cardImageAssetId,
          extensionDefaultCardImageAssetId: 'asset_default_book_club',
        ),
      ),
    );
    shell.openExtension('local:${latest!.extensionId}@latest');

    expect(certification.status, CommunityCertificationStatus.certified);
    expect(published.version, 1);
    expect(byHandle?.communityId, profile.communityId);
    expect(byQr?.communityId, profile.communityId);
    expect(publicEntry?.trustState, 'certified');
    expect(latest.packageId, communityRegistrySeed.packageId);
    expect(localBackend.isExtensionLoaded(package.extensionId), isTrue);
    expect(shell.cards.single.communityId, profile.communityId);
    expect(shell.openExtensionId, 'local:ext_book_club@latest');
  });
}

LoomExtensionPackageSummary _extensionPackage() {
  return const LoomExtensionPackageSummary(
    extensionId: 'ext_book_club',
    displayName: 'Book Club',
    version: '1.0.1',
    permissions: ['content.publish', 'community.install', 'registry.publish'],
    assetIds: ['asset_card_book_club', 'asset_logo_book_club'],
  );
}

LoomInitializationPackageSummary _initializationPackage(String communityId) {
  return LoomInitializationPackageSummary(
    communityId: communityId,
    communityName: communityRegistrySeed.displayName,
    extensionId: communityRegistrySeed.extensionId,
    seedDataFiles: const [
      'seed/community.json',
      'seed/publish.json',
      'seed/certification.json',
    ],
    cardAssetId: communityRegistrySeed.cardImageAssetId,
  );
}
