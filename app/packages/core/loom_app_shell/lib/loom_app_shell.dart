import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

export 'package:loom_design_system/loom_design_system.dart' show buildLoomTheme;

enum RoleScope { fanApp, creatorStudio }

extension RoleScopeLabel on RoleScope {
  String get label {
    switch (this) {
      case RoleScope.fanApp:
        return 'Fan App';
      case RoleScope.creatorStudio:
        return 'Creator Studio';
    }
  }
}

typedef RoleSurfaceBuilder = Widget Function(BuildContext context);

CreatorMetadataApi? _creatorMetadataApi;
FanPassportApi? _fanPassportApi;
FanVaultApi? _fanVaultApi;
CreatorAudienceApi? _creatorAudienceApi;
CreatorChannelRegistryApi? _creatorChannelRegistryApi;
CreatorExperienceApi? _creatorExperienceApi;
ContentHostApi? _contentHostApi;
CampaignApi? _campaignApi;
MigrationExportApi? _migrationExportApi;
EntitlementLedgerApi? _entitlementLedgerApi;
ExtensionRegistryApi? _extensionRegistryApi;
ExtensionRuntimeApi? _extensionRuntimeApi;
AiGatewayApi? _aiGatewayApi;
AdDecisionApi? _adDecisionApi;
AudienceAnalyticsApi? _audienceAnalyticsApi;
CreatorAnnouncementApi? _creatorAnnouncementApi;
CrossPostingApi? _crossPostingApi;
ExternalAccountLinkApi? _externalAccountLinkApi;
ExternalContentSourceApi? _externalContentSourceApi;
FanFollowCaptureApi? _fanFollowCaptureApi;
ImportPublicMetadataApi? _importPublicMetadataApi;
PremiumNoAdApi? _premiumNoAdApi;
StarterPackApi? _starterPackApi;
RecommendationReferralApi? _recommendationReferralApi;
ExternalRecommendationProviderApi? _externalRecommendationProviderApi;
SearchApi? _searchApi;
PlaybackAuthorizationApi? _playbackAuthorizationApi;
ReceiptLedgerApi? _receiptLedgerApi;
FanWalletApi? _fanWalletApi;
SettlementEngineApi? _settlementEngineApi;
SponsorCampaignApi? _sponsorCampaignApi;

void registerCreatorMetadataApi(CreatorMetadataApi api) {
  _creatorMetadataApi = api;
}

void registerFanPassportApi(FanPassportApi api) {
  _fanPassportApi = api;
}

void registerFanVaultApi(FanVaultApi api) {
  _fanVaultApi = api;
}

void registerCreatorAudienceApi(CreatorAudienceApi api) {
  _creatorAudienceApi = api;
}

void registerCreatorChannelRegistryApi(CreatorChannelRegistryApi api) {
  _creatorChannelRegistryApi = api;
}

void registerCreatorExperienceApi(CreatorExperienceApi api) {
  _creatorExperienceApi = api;
}

void registerContentHostApi(ContentHostApi api) {
  _contentHostApi = api;
}

void registerCampaignApi(CampaignApi api) {
  _campaignApi = api;
}

void registerMigrationExportApi(MigrationExportApi api) {
  _migrationExportApi = api;
}

void registerEntitlementLedgerApi(EntitlementLedgerApi api) {
  _entitlementLedgerApi = api;
}

void registerExtensionRegistryApi(ExtensionRegistryApi api) {
  _extensionRegistryApi = api;
}

void registerExtensionRuntimeApi(ExtensionRuntimeApi api) {
  _extensionRuntimeApi = api;
}

void registerAiGatewayApi(AiGatewayApi api) {
  _aiGatewayApi = api;
}

void registerAdDecisionApi(AdDecisionApi api) {
  _adDecisionApi = api;
}

void registerAudienceAnalyticsApi(AudienceAnalyticsApi api) {
  _audienceAnalyticsApi = api;
}

void registerCreatorAnnouncementApi(CreatorAnnouncementApi api) {
  _creatorAnnouncementApi = api;
}

void registerCrossPostingApi(CrossPostingApi api) {
  _crossPostingApi = api;
}

void registerExternalAccountLinkApi(ExternalAccountLinkApi api) {
  _externalAccountLinkApi = api;
}

void registerExternalContentSourceApi(ExternalContentSourceApi api) {
  _externalContentSourceApi = api;
}

void registerFanFollowCaptureApi(FanFollowCaptureApi api) {
  _fanFollowCaptureApi = api;
}

void registerImportPublicMetadataApi(ImportPublicMetadataApi api) {
  _importPublicMetadataApi = api;
}

void registerPremiumNoAdApi(PremiumNoAdApi api) {
  _premiumNoAdApi = api;
}

void registerStarterPackApi(StarterPackApi api) {
  _starterPackApi = api;
}

void registerRecommendationReferralApi(RecommendationReferralApi api) {
  _recommendationReferralApi = api;
}

void registerExternalRecommendationProviderApi(
  ExternalRecommendationProviderApi api,
) {
  _externalRecommendationProviderApi = api;
}

void registerSearchApi(SearchApi api) {
  _searchApi = api;
}

void registerPlaybackAuthorizationApi(PlaybackAuthorizationApi api) {
  _playbackAuthorizationApi = api;
}

void registerReceiptLedgerApi(ReceiptLedgerApi api) {
  _receiptLedgerApi = api;
}

void registerFanWalletApi(FanWalletApi api) {
  _fanWalletApi = api;
}

void registerSettlementEngineApi(SettlementEngineApi api) {
  _settlementEngineApi = api;
}

void registerSponsorCampaignApi(SponsorCampaignApi api) {
  _sponsorCampaignApi = api;
}

void resetAppShellDependencies() {
  _creatorMetadataApi = null;
  _fanPassportApi = null;
  _fanVaultApi = null;
  _creatorAudienceApi = null;
  _creatorChannelRegistryApi = null;
  _creatorExperienceApi = null;
  _contentHostApi = null;
  _campaignApi = null;
  _migrationExportApi = null;
  _entitlementLedgerApi = null;
  _extensionRegistryApi = null;
  _extensionRuntimeApi = null;
  _aiGatewayApi = null;
  _adDecisionApi = null;
  _audienceAnalyticsApi = null;
  _creatorAnnouncementApi = null;
  _crossPostingApi = null;
  _externalAccountLinkApi = null;
  _externalContentSourceApi = null;
  _fanFollowCaptureApi = null;
  _importPublicMetadataApi = null;
  _premiumNoAdApi = null;
  _starterPackApi = null;
  _recommendationReferralApi = null;
  _externalRecommendationProviderApi = null;
  _searchApi = null;
  _playbackAuthorizationApi = null;
  _receiptLedgerApi = null;
  _fanWalletApi = null;
  _settlementEngineApi = null;
  _sponsorCampaignApi = null;
}

CreatorMetadataApi resolveCreatorMetadataApi() {
  final api = _creatorMetadataApi;
  if (api == null) {
    throw StateError('CreatorMetadataApi has not been registered.');
  }
  return api;
}

FanPassportApi resolveFanPassportApi() {
  final api = _fanPassportApi;
  if (api == null) {
    throw StateError('FanPassportApi has not been registered.');
  }
  return api;
}

FanVaultApi resolveFanVaultApi() {
  final api = _fanVaultApi;
  if (api == null) {
    throw StateError('FanVaultApi has not been registered.');
  }
  return api;
}

CreatorAudienceApi resolveCreatorAudienceApi() {
  final api = _creatorAudienceApi;
  if (api == null) {
    throw StateError('CreatorAudienceApi has not been registered.');
  }
  return api;
}

CreatorChannelRegistryApi resolveCreatorChannelRegistryApi() {
  final api = _creatorChannelRegistryApi;
  if (api == null) {
    throw StateError('CreatorChannelRegistryApi has not been registered.');
  }
  return api;
}

CreatorExperienceApi resolveCreatorExperienceApi() {
  final api = _creatorExperienceApi;
  if (api == null) {
    throw StateError('CreatorExperienceApi has not been registered.');
  }
  return api;
}

ContentHostApi resolveContentHostApi() {
  final api = _contentHostApi;
  if (api == null) {
    throw StateError('ContentHostApi has not been registered.');
  }
  return api;
}

CampaignApi resolveCampaignApi() {
  final api = _campaignApi;
  if (api == null) {
    throw StateError('CampaignApi has not been registered.');
  }
  return api;
}

MigrationExportApi resolveMigrationExportApi() {
  final api = _migrationExportApi;
  if (api == null) {
    throw StateError('MigrationExportApi has not been registered.');
  }
  return api;
}

SponsorCampaignApi resolveSponsorCampaignApi() {
  final api = _sponsorCampaignApi;
  if (api == null) {
    throw StateError('SponsorCampaignApi has not been registered.');
  }
  return api;
}

EntitlementLedgerApi resolveEntitlementLedgerApi() {
  final api = _entitlementLedgerApi;
  if (api == null) {
    throw StateError('EntitlementLedgerApi has not been registered.');
  }
  return api;
}

ExtensionRegistryApi resolveExtensionRegistryApi() {
  final api = _extensionRegistryApi;
  if (api == null) {
    throw StateError('ExtensionRegistryApi has not been registered.');
  }
  return api;
}

ExtensionRuntimeApi resolveExtensionRuntimeApi() {
  final api = _extensionRuntimeApi;
  if (api == null) {
    throw StateError('ExtensionRuntimeApi has not been registered.');
  }
  return api;
}

AiGatewayApi resolveAiGatewayApi() {
  final api = _aiGatewayApi;
  if (api == null) {
    throw StateError('AiGatewayApi has not been registered.');
  }
  return api;
}

AdDecisionApi resolveAdDecisionApi() {
  final api = _adDecisionApi;
  if (api == null) {
    throw StateError('AdDecisionApi has not been registered.');
  }
  return api;
}

AudienceAnalyticsApi resolveAudienceAnalyticsApi() {
  final api = _audienceAnalyticsApi;
  if (api == null) {
    throw StateError('AudienceAnalyticsApi has not been registered.');
  }
  return api;
}

CreatorAnnouncementApi resolveCreatorAnnouncementApi() {
  final api = _creatorAnnouncementApi;
  if (api == null) {
    throw StateError('CreatorAnnouncementApi has not been registered.');
  }
  return api;
}

CrossPostingApi resolveCrossPostingApi() {
  final api = _crossPostingApi;
  if (api == null) {
    throw StateError('CrossPostingApi has not been registered.');
  }
  return api;
}

ExternalAccountLinkApi resolveExternalAccountLinkApi() {
  final api = _externalAccountLinkApi;
  if (api == null) {
    throw StateError('ExternalAccountLinkApi has not been registered.');
  }
  return api;
}

ExternalContentSourceApi resolveExternalContentSourceApi() {
  final api = _externalContentSourceApi;
  if (api == null) {
    throw StateError('ExternalContentSourceApi has not been registered.');
  }
  return api;
}

FanFollowCaptureApi resolveFanFollowCaptureApi() {
  final api = _fanFollowCaptureApi;
  if (api == null) {
    throw StateError('FanFollowCaptureApi has not been registered.');
  }
  return api;
}

ImportPublicMetadataApi resolveImportPublicMetadataApi() {
  final api = _importPublicMetadataApi;
  if (api == null) {
    throw StateError('ImportPublicMetadataApi has not been registered.');
  }
  return api;
}

PremiumNoAdApi resolvePremiumNoAdApi() {
  final api = _premiumNoAdApi;
  if (api == null) {
    throw StateError('PremiumNoAdApi has not been registered.');
  }
  return api;
}

StarterPackApi resolveStarterPackApi() {
  final api = _starterPackApi;
  if (api == null) {
    throw StateError('StarterPackApi has not been registered.');
  }
  return api;
}

RecommendationReferralApi resolveRecommendationReferralApi() {
  final api = _recommendationReferralApi;
  if (api == null) {
    throw StateError('RecommendationReferralApi has not been registered.');
  }
  return api;
}

ExternalRecommendationProviderApi resolveExternalRecommendationProviderApi() {
  final api = _externalRecommendationProviderApi;
  if (api == null) {
    throw StateError(
      'ExternalRecommendationProviderApi has not been registered.',
    );
  }
  return api;
}

SearchApi resolveSearchApi() {
  final api = _searchApi;
  if (api == null) {
    throw StateError('SearchApi has not been registered.');
  }
  return api;
}

PlaybackAuthorizationApi resolvePlaybackAuthorizationApi() {
  final api = _playbackAuthorizationApi;
  if (api == null) {
    throw StateError('PlaybackAuthorizationApi has not been registered.');
  }
  return api;
}

ReceiptLedgerApi resolveReceiptLedgerApi() {
  final api = _receiptLedgerApi;
  if (api == null) {
    throw StateError('ReceiptLedgerApi has not been registered.');
  }
  return api;
}

FanWalletApi resolveFanWalletApi() {
  final api = _fanWalletApi;
  if (api == null) {
    throw StateError('FanWalletApi has not been registered.');
  }
  return api;
}

SettlementEngineApi resolveSettlementEngineApi() {
  final api = _settlementEngineApi;
  if (api == null) {
    throw StateError('SettlementEngineApi has not been registered.');
  }
  return api;
}

class LoomDemoShell extends StatefulWidget {
  const LoomDemoShell({
    required this.fanBuilder,
    required this.studioBuilder,
    super.key,
  });

  final RoleSurfaceBuilder fanBuilder;
  final RoleSurfaceBuilder studioBuilder;

  @override
  State<LoomDemoShell> createState() => _LoomDemoShellState();
}

class _LoomDemoShellState extends State<LoomDemoShell> {
  RoleScope _role = RoleScope.fanApp;
  int _resetEpoch = 0;
  bool _resetting = false;

  Future<void> _resetDemo() async {
    if (_resetting) {
      return;
    }
    setState(() => _resetting = true);
    await resolveMigrationExportApi().resetDemo(
      idempotencyKey: 'p9-reset-${DateTime.now().microsecondsSinceEpoch}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _role = RoleScope.fanApp;
      _resetEpoch += 1;
      _resetting = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Demo reset to seed v1')));
  }

  @override
  Widget build(BuildContext context) {
    final labels = RoleScope.values.map((role) => role.label).toList();
    final selectedIndex = RoleScope.values.indexOf(_role);

    return LoomNavScaffold(
      brand: 'Loom',
      subtitle: _role == RoleScope.fanApp
          ? 'Home, follows, and trusted discovery'
          : 'Creator workspace and channel setup',
      selectedIndex: selectedIndex,
      destinations: const [
        LoomNavItem(
          label: 'Fan App',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        LoomNavItem(
          label: 'Creator Studio',
          icon: Icons.video_library_outlined,
          selectedIcon: Icons.video_library_rounded,
        ),
      ],
      onDestinationSelected: (index) {
        setState(() {
          _role = RoleScope.values[index];
        });
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            key: const ValueKey('p9_demo_menu_button'),
            tooltip: 'Demo tools',
            icon: _resetting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              if (value == 'reset') {
                unawaited(_resetDemo());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                key: ValueKey('p9_reset_demo_menu_item'),
                value: 'reset',
                child: Text('Reset demo'),
              ),
            ],
          ),
          RoleSwitcher(
            labels: labels,
            selectedIndex: selectedIndex,
            onChanged: (index) {
              setState(() {
                _role = RoleScope.values[index];
              });
            },
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey<String>('${_role.name}-$_resetEpoch'),
          child: _role == RoleScope.fanApp
              ? widget.fanBuilder(context)
              : widget.studioBuilder(context),
        ),
      ),
    );
  }
}
