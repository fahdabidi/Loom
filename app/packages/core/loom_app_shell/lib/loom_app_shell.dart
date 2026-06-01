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
ContentHostApi? _contentHostApi;
CampaignApi? _campaignApi;
MigrationExportApi? _migrationExportApi;
EntitlementLedgerApi? _entitlementLedgerApi;
AiGatewayApi? _aiGatewayApi;
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

void registerAiGatewayApi(AiGatewayApi api) {
  _aiGatewayApi = api;
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
  _contentHostApi = null;
  _campaignApi = null;
  _migrationExportApi = null;
  _entitlementLedgerApi = null;
  _aiGatewayApi = null;
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

AiGatewayApi resolveAiGatewayApi() {
  final api = _aiGatewayApi;
  if (api == null) {
    throw StateError('AiGatewayApi has not been registered.');
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
