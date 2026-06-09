import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';

class DemoWorkflowHarness {
  DemoWorkflowHarness._({
    required this.foundation,
    required this.registry,
    required this.experience,
    required this.economic,
    required this.ops,
    required this.localBackend,
    required this.shell,
    required this.profile,
  });

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;
  final CommunityEconomicServicesFakeBackend economic;
  final CommunityOpsServicesFakeBackend ops;
  final LocalInAppBackend localBackend;
  final CommunityAppShellRuntime shell;
  final CommunityProfile profile;

  String get communityId => profile.communityId;
  String get ownerId => communityFoundationSeed.ownerActorId;
  String get memberId => communityFoundationSeed.memberPassportId;

  static Future<DemoWorkflowHarness> create({
    required String handle,
    required String displayName,
    required String category,
    required String extensionId,
    required String cardAssetId,
    required String logoAssetId,
    required String accentColor,
  }) async {
    final foundation = CommunityFoundationFakeBackend();
    final registry = CommunityRegistryControlPlaneFakeBackend(foundation);
    final experience = CommunityExperienceServicesFakeBackend(
      foundation: foundation,
      registry: registry,
    );
    final economic = CommunityEconomicServicesFakeBackend(
      foundation: foundation,
    );
    final ops = CommunityOpsServicesFakeBackend(
      foundation: foundation,
      registry: registry,
      experience: experience,
    );
    final profile = await registry.communityRegistry.registerCommunity(
      handle: handle,
      displayName: displayName,
      branding: CommunityBranding(
        logoAssetId: logoAssetId,
        cardImageAssetId: cardAssetId,
        accentColor: accentColor,
        altText: displayName,
      ),
      ownerPassportId: communityFoundationSeed.ownerActorId,
      idempotencyKey: 'register-$handle',
    );
    final harness = DemoWorkflowHarness._(
      foundation: foundation,
      registry: registry,
      experience: experience,
      economic: economic,
      ops: ops,
      localBackend: LocalInAppBackend(),
      shell: CommunityAppShellRuntime(),
      profile: profile,
    );
    harness.installLocalCommunity(
      category: category,
      extensionId: extensionId,
      cardAssetId: cardAssetId,
      logoAssetId: logoAssetId,
    );
    return harness;
  }

  void installLocalCommunity({
    required String category,
    required String extensionId,
    required String cardAssetId,
    required String logoAssetId,
  }) {
    localBackend.loadExtensionPackage(
      LoomExtensionPackageSummary(
        extensionId: extensionId,
        displayName: profile.displayName,
        version: '1.0.0',
        permissions: const ['content.publish', 'community.install'],
        assetIds: [cardAssetId, logoAssetId],
      ),
    );
    final report = localBackend.importInitializationPackage(
      LoomInitializationPackageSummary(
        communityId: profile.communityId,
        communityName: profile.displayName,
        extensionId: extensionId,
        seedDataFiles: const ['seed/community.json'],
        cardAssetId: cardAssetId,
      ),
      accentColor: profile.branding.accentColor,
      logoAssetId: logoAssetId,
    );
    shell.installCommunity(
      CommunityCardProps(
        communityId: report.community.communityId,
        handle: profile.handle,
        branding: CommunityCardBranding(
          displayName: report.community.displayName,
          tagline: 'Local workflow validation',
          category: category,
          accentColor: report.community.accentColor,
          altText: profile.branding.altText,
          logoAssetId: report.community.logoAssetId,
          cardImageAssetId: report.community.cardImageAssetId,
          extensionDefaultCardImageAssetId: cardAssetId,
        ),
      ),
    );
  }

  Future<void> grant(String permission) async {
    await foundation.rolePolicy.grantPermission(
      actorId: ownerId,
      communityId: communityId,
      permission: permission,
      grantedBy: 'workflow-test',
      idempotencyKey: 'grant-$permission-$communityId',
    );
  }
}
