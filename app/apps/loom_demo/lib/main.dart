import 'dart:io';

import 'package:feature_ai_qa/feature_ai_qa.dart';
import 'package:feature_campaigns/feature_campaigns.dart';
import 'package:feature_creator_ads/feature_creator_ads.dart';
import 'package:feature_creator_ai/feature_creator_ai.dart';
import 'package:feature_creator_audience/feature_creator_audience.dart';
import 'package:feature_creator_campaigns/feature_creator_campaigns.dart';
import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:feature_creator_export/feature_creator_export.dart';
import 'package:feature_creator_launch/feature_creator_launch.dart';
import 'package:feature_creator_monetization/feature_creator_monetization.dart';
import 'package:feature_creator_onboarding/feature_creator_onboarding.dart';
import 'package:feature_creator_publishing/feature_creator_publishing.dart';
import 'package:feature_creator_recommendations/feature_creator_recommendations.dart';
import 'package:feature_creator_revenue/feature_creator_revenue.dart';
import 'package:feature_data_rights/feature_data_rights.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:feature_extensions/feature_extensions.dart';
import 'package:feature_fan_onboarding/feature_fan_onboarding.dart';
import 'package:feature_fan_settings/feature_fan_settings.dart';
import 'package:feature_playback/feature_playback.dart';
import 'package:feature_wallet/feature_wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart'
    show AiSearchItem, CreatorExperienceConfig, SurfaceModule;
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart'
    show LoomChannelTheme, LoomColors;
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoomDemoBootstrap());
}

class LoomDemoBootstrap extends StatefulWidget {
  const LoomDemoBootstrap({super.key});

  @override
  State<LoomDemoBootstrap> createState() => _LoomDemoBootstrapState();
}

class _LoomDemoBootstrapState extends State<LoomDemoBootstrap> {
  late final Future<DemoLocalStore> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = configureDemoDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DemoLocalStore>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Loom Demo',
            debugShowCheckedModeBanner: false,
            theme: buildLoomTheme(),
            home: _StartupErrorScreen(error: snapshot.error),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const LoomDemoApp();
        }
        return MaterialApp(
          title: 'Loom Demo',
          debugShowCheckedModeBanner: false,
          theme: buildLoomTheme(),
          home: const _StartupLoadingScreen(),
        );
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Loom'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 42),
                const SizedBox(height: 16),
                Text(
                  'Loom could not start',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<DemoLocalStore> configureDemoDependencies({
  bool persistent = true,
}) async {
  final store = persistent
      ? await DemoLocalStore.open(databaseFile: await _databaseFile())
      : await DemoLocalStore.seeded();
  registerCreatorMetadataApi(CreatorMetadataFake(store));
  registerFanPassportApi(FanPassportFake(store));
  registerFanVaultApi(FanVaultFake(store));
  registerCreatorAudienceApi(CreatorAudienceFake(store));
  registerCampaignApi(CampaignFake(store));
  registerCreatorChannelRegistryApi(CreatorChannelRegistryFake(store));
  registerCreatorExperienceApi(CreatorExperienceFake(store));
  registerContentHostApi(ContentHostFake(store));
  registerMigrationExportApi(MigrationExportFake(store));
  registerEntitlementLedgerApi(EntitlementLedgerFake(store));
  registerExtensionRegistryApi(ExtensionRegistryFake(store));
  registerExtensionRuntimeApi(ExtensionRuntimeFake(store));
  registerAiGatewayApi(AiGatewayFake(store));
  registerAdDecisionApi(AdDecisionFake(store));
  registerAudienceAnalyticsApi(AudienceAnalyticsFake(store));
  registerCreatorAnnouncementApi(CreatorAnnouncementFake(store));
  registerCrossPostingApi(CrossPostingFake(store));
  registerExternalAccountLinkApi(ExternalAccountLinkFake(store));
  registerExternalContentSourceApi(ExternalContentSourceFake(store));
  registerFanFollowCaptureApi(FanFollowCaptureFake(store));
  registerImportPublicMetadataApi(ImportPublicMetadataFake(store));
  registerPremiumNoAdApi(PremiumNoAdFake(store));
  registerStarterPackApi(StarterPackFake(store));
  registerExternalRecommendationProviderApi(
    ExternalRecommendationProviderFake(store),
  );
  registerRecommendationReferralApi(RecommendationReferralFake(store));
  registerSearchApi(SearchFake(store));
  registerPlaybackAuthorizationApi(PlaybackAuthorizationFake(store));
  registerReceiptLedgerApi(ReceiptLedgerFake(store));
  registerFanWalletApi(FanWalletFake(store));
  registerSettlementEngineApi(SettlementEngineFake(store));
  registerSponsorCampaignApi(SponsorCampaignFake());
  return store;
}

Future<Widget> buildLoomDemoAppForTest() async {
  resetAppShellDependencies();
  await configureDemoDependencies(persistent: false);
  return const LoomDemoApp();
}

Future<File> _databaseFile() async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, 'loom_demo.sqlite'));
}

class LoomDemoApp extends StatelessWidget {
  const LoomDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom Demo',
      debugShowCheckedModeBanner: false,
      theme: buildLoomTheme(),
      home: LoomDemoShell(
        fanBuilder: (_, chrome) =>
            FanAppSurface(searchRequests: chrome.searchRequests),
        studioBuilder: (_, _) => const CreatorStudioSurface(),
      ),
    );
  }
}

class CreatorStudioSurface extends StatefulWidget {
  const CreatorStudioSurface({super.key});

  @override
  State<CreatorStudioSurface> createState() => _CreatorStudioSurfaceState();
}

class _CreatorStudioSurfaceState extends State<CreatorStudioSurface> {
  static const _phaseOneChannelId = 'channel_p1-creator-channel-loom-home-lab';

  bool _showPublishingSetup = false;
  bool _showRevenue = false;
  bool _showAudience = false;
  bool _showConversion = false;
  bool _showRecommendations = false;
  bool _showCampaigns = false;
  bool _showExport = false;
  bool _showLaunch = false;
  bool _showCatalogImport = false;
  bool _showAdPolicy = false;
  bool _showCreatorAi = false;
  bool _showMemberships = false;
  bool _showCustomize = false;

  void _openStudioHome() {
    setState(() {
      _showPublishingSetup = false;
      _showRevenue = false;
      _showAudience = false;
      _showConversion = false;
      _showRecommendations = false;
      _showCampaigns = false;
      _showExport = false;
      _showLaunch = false;
      _showCatalogImport = false;
      _showAdPolicy = false;
      _showCreatorAi = false;
      _showMemberships = false;
      _showCustomize = false;
    });
  }

  void _openCreatorSurface(_CreatorSurfaceTarget target) {
    setState(() {
      _showPublishingSetup = target == _CreatorSurfaceTarget.publishing;
      _showRevenue = target == _CreatorSurfaceTarget.revenue;
      _showAudience = target == _CreatorSurfaceTarget.audience;
      _showConversion = target == _CreatorSurfaceTarget.conversion;
      _showRecommendations = target == _CreatorSurfaceTarget.recommendations;
      _showCampaigns = target == _CreatorSurfaceTarget.campaigns;
      _showExport = target == _CreatorSurfaceTarget.export;
      _showLaunch = target == _CreatorSurfaceTarget.launch;
      _showCatalogImport = target == _CreatorSurfaceTarget.catalogImport;
      _showAdPolicy = target == _CreatorSurfaceTarget.adPolicy;
      _showCreatorAi = target == _CreatorSurfaceTarget.creatorAi;
      _showMemberships = target == _CreatorSurfaceTarget.memberships;
      _showCustomize = target == _CreatorSurfaceTarget.customize;
    });
  }

  Widget _withCreatorRail({
    required _CreatorSurfaceTarget active,
    required Widget child,
  }) {
    return NestedScrollView(
      key: const ValueKey('creator_subsurface_with_rail'),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _CreatorStudioActionRail(
              active: active,
              onOpenHome: _openStudioHome,
              onOpenPublishing: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.publishing),
              onOpenRevenue: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.revenue),
              onOpenAudience: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.audience),
              onOpenConversion: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.conversion),
              onOpenRecommendations: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.recommendations),
              onOpenCampaigns: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.campaigns),
              onOpenExport: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.export),
              onOpenLaunch: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.launch),
              onOpenCatalogImport: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.catalogImport),
              onOpenAdPolicy: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.adPolicy),
              onOpenCreatorAi: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.creatorAi),
              onOpenMemberships: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.memberships),
              onOpenCustomize: () =>
                  _openCreatorSurface(_CreatorSurfaceTarget.customize),
            ),
          ),
        ),
      ],
      body: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRevenue) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.revenue,
        child: CreatorRevenueDashboardScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showAudience) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.audience,
        child: AudienceInsightsScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showConversion) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.conversion,
        child: CreatorConversionAnalyticsScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showRecommendations) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.recommendations,
        child: RecommendationBuilderScreen(onBack: _openStudioHome),
      );
    }
    if (_showCampaigns) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.campaigns,
        child: CreatorCampaignBuilderScreen(onBack: _openStudioHome),
      );
    }
    if (_showExport) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.export,
        child: CreatorExportWizardScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showLaunch) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.launch,
        child: CreatorLaunchScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCatalogImport) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.catalogImport,
        child: CatalogImportConsoleScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showAdPolicy) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.adPolicy,
        child: CreatorAdPolicyConsoleScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCreatorAi) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.creatorAi,
        child: CreatorArchiveAiPreviewScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showMemberships) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.memberships,
        child: CreatorMembershipSetupScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCustomize) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.customize,
        child: CreatorCustomizeConsoleScreen(
          creatorId: 'creator_nova_clutch',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showPublishingSetup) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.publishing,
        child: const CreatorPublishingSetupScreen(
          channelId: _phaseOneChannelId,
        ),
      );
    }

    return _withCreatorRail(
      active: _CreatorSurfaceTarget.channel,
      child: CreatorOnboardingScreen(
        onOpenPublishingSetup: () =>
            _openCreatorSurface(_CreatorSurfaceTarget.publishing),
      ),
    );
  }
}

enum _CreatorSurfaceTarget {
  channel,
  publishing,
  revenue,
  audience,
  conversion,
  recommendations,
  campaigns,
  export,
  launch,
  catalogImport,
  adPolicy,
  creatorAi,
  memberships,
  customize,
}

class _CreatorStudioActionRail extends StatelessWidget {
  const _CreatorStudioActionRail({
    required this.active,
    required this.onOpenHome,
    required this.onOpenPublishing,
    required this.onOpenRevenue,
    required this.onOpenAudience,
    required this.onOpenConversion,
    required this.onOpenRecommendations,
    required this.onOpenCampaigns,
    required this.onOpenExport,
    required this.onOpenLaunch,
    required this.onOpenCatalogImport,
    required this.onOpenAdPolicy,
    required this.onOpenCreatorAi,
    required this.onOpenMemberships,
    required this.onOpenCustomize,
  });

  final _CreatorSurfaceTarget active;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenPublishing;
  final VoidCallback onOpenRevenue;
  final VoidCallback onOpenAudience;
  final VoidCallback onOpenConversion;
  final VoidCallback onOpenRecommendations;
  final VoidCallback onOpenCampaigns;
  final VoidCallback onOpenExport;
  final VoidCallback onOpenLaunch;
  final VoidCallback onOpenCatalogImport;
  final VoidCallback onOpenAdPolicy;
  final VoidCallback onOpenCreatorAi;
  final VoidCallback onOpenMemberships;
  final VoidCallback onOpenCustomize;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('creator_studio_action_panel'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        children: [
          _CreatorRailSection(
            label: 'Setup',
            buttons: [
              _CreatorRailButton(
                keyName: 'creator_studio_home_button',
                tooltip: 'Create channel',
                icon: Icons.add_circle_outline_rounded,
                active: active == _CreatorSurfaceTarget.channel,
                onPressed: onOpenHome,
              ),
              _CreatorRailButton(
                keyName: 'creator_open_publishing_panel_button',
                tooltip: 'Publishing setup',
                icon: Icons.dashboard_customize_outlined,
                active: active == _CreatorSurfaceTarget.publishing,
                onPressed: onOpenPublishing,
              ),
              _CreatorRailButton(
                keyName: 'p13_open_catalog_import_button',
                tooltip: 'Catalog import',
                icon: Icons.cloud_download_outlined,
                active: active == _CreatorSurfaceTarget.catalogImport,
                onPressed: onOpenCatalogImport,
              ),
              _CreatorRailButton(
                keyName: 'p13_open_ad_policy_button',
                tooltip: 'Ad policy',
                icon: Icons.policy_outlined,
                active: active == _CreatorSurfaceTarget.adPolicy,
                onPressed: onOpenAdPolicy,
              ),
            ],
          ),
          _CreatorRailSection(
            label: 'Growth',
            buttons: [
              _CreatorRailButton(
                keyName: 'p11_open_launch_button',
                tooltip: 'Launch',
                icon: Icons.rocket_launch_rounded,
                active: active == _CreatorSurfaceTarget.launch,
                onPressed: onOpenLaunch,
              ),
              _CreatorRailButton(
                keyName: 'p8_open_recommendations_button',
                tooltip: 'Recommendations',
                icon: Icons.recommend_rounded,
                active: active == _CreatorSurfaceTarget.recommendations,
                onPressed: onOpenRecommendations,
              ),
              _CreatorRailButton(
                keyName: 'p8_open_campaign_builder_button',
                tooltip: 'Campaigns',
                icon: Icons.campaign_rounded,
                active: active == _CreatorSurfaceTarget.campaigns,
                onPressed: onOpenCampaigns,
              ),
              _CreatorRailButton(
                keyName: 'p13_open_membership_button',
                tooltip: 'Membership setup',
                icon: Icons.workspace_premium_outlined,
                active: active == _CreatorSurfaceTarget.memberships,
                onPressed: onOpenMemberships,
              ),
            ],
          ),
          _CreatorRailSection(
            label: 'Signals',
            buttons: [
              _CreatorRailButton(
                keyName: 'p6_open_revenue_dashboard_button',
                tooltip: 'Revenue',
                icon: Icons.payments_rounded,
                active: active == _CreatorSurfaceTarget.revenue,
                onPressed: onOpenRevenue,
              ),
              _CreatorRailButton(
                keyName: 'p7_open_audience_button',
                tooltip: 'Audience',
                icon: Icons.groups_2_rounded,
                active: active == _CreatorSurfaceTarget.audience,
                onPressed: onOpenAudience,
              ),
              _CreatorRailButton(
                keyName: 'p13_open_conversion_button',
                tooltip: 'Conversion funnel',
                icon: Icons.stacked_bar_chart_rounded,
                active: active == _CreatorSurfaceTarget.conversion,
                onPressed: onOpenConversion,
              ),
            ],
          ),
          _CreatorRailSection(
            label: 'Demo',
            buttons: [
              _CreatorRailButton(
                keyName: 'p19_open_customize_button',
                tooltip: 'Customize fan experience',
                icon: Icons.dashboard_customize_rounded,
                active: active == _CreatorSurfaceTarget.customize,
                onPressed: onOpenCustomize,
              ),
              _CreatorRailButton(
                keyName: 'p9_open_export_button',
                tooltip: 'Export',
                icon: Icons.archive_rounded,
                active: active == _CreatorSurfaceTarget.export,
                onPressed: onOpenExport,
              ),
              _CreatorRailButton(
                keyName: 'p9_open_export_button_full',
                tooltip: 'Export and transparency',
                icon: Icons.receipt_long_rounded,
                active: active == _CreatorSurfaceTarget.export,
                onPressed: onOpenExport,
              ),
              _CreatorRailButton(
                keyName: 'p13_open_creator_ai_button',
                tooltip: 'Creator AI',
                icon: Icons.psychology_alt_outlined,
                active: active == _CreatorSurfaceTarget.creatorAi,
                onPressed: onOpenCreatorAi,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatorRailSection extends StatelessWidget {
  const _CreatorRailSection({required this.label, required this.buttons});

  final String label;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: LoomColors.mutedInk,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: Wrap(spacing: 4, runSpacing: 4, children: buttons)),
        ],
      ),
    );
  }
}

class _CreatorRailButton extends StatelessWidget {
  const _CreatorRailButton({
    required this.keyName,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String keyName;
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = active
        ? IconButton.filled(
            key: ValueKey(keyName),
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: BoxConstraints.tight(const Size.square(40)),
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: Icon(icon),
          )
        : IconButton.filledTonal(
            key: ValueKey(keyName),
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: BoxConstraints.tight(const Size.square(40)),
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: Icon(icon),
          );
    return SizedBox.square(dimension: 40, child: button);
  }
}

class FanAppSurface extends StatefulWidget {
  const FanAppSurface({this.searchRequests, super.key});

  final ValueListenable<int>? searchRequests;

  @override
  State<FanAppSurface> createState() => _FanAppSurfaceState();
}

class _FanAppSurfaceState extends State<FanAppSurface> {
  bool _showOnboarding = false;
  bool _showCaptureLanding = false;
  bool _showWallet = false;
  bool _showDataRights = false;
  bool _showCampaigns = false;
  bool _showSettings = false;
  bool _openDiscoveryImmersive = false;
  String? _channelId;
  String? _contentId;
  String? _qaCreatorId;
  AiSearchItem? _externalPlaybackItem;

  void _openDiscovery({bool immersive = false}) {
    setState(() {
      _showOnboarding = false;
      _showCaptureLanding = false;
      _showWallet = false;
      _showDataRights = false;
      _showCampaigns = false;
      _showSettings = false;
      _channelId = null;
      _contentId = null;
      _qaCreatorId = null;
      _externalPlaybackItem = null;
      _openDiscoveryImmersive = immersive;
    });
  }

  void _openFanSurface(_FanSurfaceTarget target) {
    setState(() {
      _showOnboarding = target == _FanSurfaceTarget.onboarding;
      _showCaptureLanding = target == _FanSurfaceTarget.capture;
      _showWallet = target == _FanSurfaceTarget.wallet;
      _showDataRights = target == _FanSurfaceTarget.dataRights;
      _showCampaigns = target == _FanSurfaceTarget.campaigns;
      _showSettings = target == _FanSurfaceTarget.settings;
      _channelId = null;
      _contentId = null;
      _qaCreatorId = null;
      _externalPlaybackItem = null;
      _openDiscoveryImmersive = false;
    });
  }

  Widget _withFanRail({
    required _FanSurfaceTarget active,
    required Widget child,
  }) {
    return NestedScrollView(
      key: const ValueKey('fan_subsurface_with_rail'),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _FanSecondaryActionRail(
              active: active,
              onReturnToFeed: _openDiscovery,
              onOpenOnboarding: () =>
                  _openFanSurface(_FanSurfaceTarget.onboarding),
              onOpenImmersive: () => _openDiscovery(immersive: true),
              onOpenCapture: () => _openFanSurface(_FanSurfaceTarget.capture),
              onOpenWallet: () => _openFanSurface(_FanSurfaceTarget.wallet),
              onOpenDataRights: () =>
                  _openFanSurface(_FanSurfaceTarget.dataRights),
              onOpenCampaigns: () =>
                  _openFanSurface(_FanSurfaceTarget.campaigns),
              onOpenSettings: () => _openFanSurface(_FanSurfaceTarget.settings),
            ),
          ),
        ),
      ],
      body: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return _withFanRail(
        active: _FanSurfaceTarget.onboarding,
        child: FanOnboardingScreen(
          onDone: () => _openDiscovery(),
          onBack: () => _openDiscovery(),
        ),
      );
    }
    if (_showCaptureLanding) {
      return _withFanRail(
        active: _FanSurfaceTarget.capture,
        child: FanCaptureLandingScreen(
          captureToken: 'cap_creator-solar-sarah_launch',
          onDone: () => _openDiscovery(),
          onBack: () => _openDiscovery(),
        ),
      );
    }
    if (_showWallet) {
      return _withFanRail(
        active: _FanSurfaceTarget.wallet,
        child: WalletScreen(onBack: () => _openDiscovery()),
      );
    }
    if (_showDataRights) {
      return _withFanRail(
        active: _FanSurfaceTarget.dataRights,
        child: DataRightsDashboardScreen(onBack: () => _openDiscovery()),
      );
    }
    if (_showCampaigns) {
      return _withFanRail(
        active: _FanSurfaceTarget.campaigns,
        child: CampaignEntryScreen(onBack: () => _openDiscovery()),
      );
    }
    if (_showSettings) {
      return _withFanRail(
        active: _FanSurfaceTarget.settings,
        child: FanAiSearchSettingsScreen(onBack: () => _openDiscovery()),
      );
    }
    final qaCreatorId = _qaCreatorId;
    if (qaCreatorId != null) {
      return ArchiveQaScreen(
        creatorId: qaCreatorId,
        onBack: () => setState(() => _qaCreatorId = null),
      );
    }
    final externalPlaybackItem = _externalPlaybackItem;
    if (externalPlaybackItem != null) {
      return ExternalPlaybackScreen(
        initialItem: externalPlaybackItem,
        onBack: () => setState(() => _externalPlaybackItem = null),
        launchExternalUrl: (uri) =>
            launchUrl(uri, mode: LaunchMode.externalApplication),
        onOpenContent: (id) => setState(() {
          _externalPlaybackItem = null;
          _contentId = id;
        }),
      );
    }
    final contentId = _contentId;
    if (contentId != null) {
      return PlaybackScreen(
        contentId: contentId,
        onBack: () => setState(() => _contentId = null),
      );
    }

    final channelId = _channelId;
    if (channelId != null) {
      return CreatorChannelHomeScreen(
        channelId: channelId,
        onBack: () => setState(() => _channelId = null),
        onOpenContent: (id) => setState(() => _contentId = id),
        onOpenExternal: (item) => setState(() => _externalPlaybackItem = item),
        onAskArchive: (id) => setState(() => _qaCreatorId = id),
        extensionModuleBuilder:
            (
              BuildContext context, {
              required String channelId,
              required String passportId,
              required SurfaceModule module,
              required CreatorExperienceConfig config,
              required LoomChannelTheme theme,
            }) {
              return ExtensionRuntimeModule(
                channelId: channelId,
                passportId: passportId,
                module: module,
                theme: theme,
              );
            },
      );
    }

    return DiscoveryHomeScreen(
      initialImmersive: _openDiscoveryImmersive,
      searchRequests: widget.searchRequests,
      onStartOnboarding: () => _openFanSurface(_FanSurfaceTarget.onboarding),
      onOpenCreator: (id) => setState(() => _channelId = id),
      onOpenContent: (id) => setState(() => _contentId = id),
      onOpenExternal: (item) => setState(() => _externalPlaybackItem = item),
      onOpenWallet: () => _openFanSurface(_FanSurfaceTarget.wallet),
      onOpenDataRights: () => _openFanSurface(_FanSurfaceTarget.dataRights),
      onOpenCampaigns: () => _openFanSurface(_FanSurfaceTarget.campaigns),
      onOpenCaptureLink: () => _openFanSurface(_FanSurfaceTarget.capture),
      onOpenSettings: () => _openFanSurface(_FanSurfaceTarget.settings),
    );
  }
}

enum _FanSurfaceTarget {
  onboarding,
  immersive,
  capture,
  wallet,
  dataRights,
  campaigns,
  settings,
}

class _FanSecondaryActionRail extends StatelessWidget {
  const _FanSecondaryActionRail({
    required this.active,
    required this.onReturnToFeed,
    required this.onOpenOnboarding,
    required this.onOpenImmersive,
    required this.onOpenCapture,
    required this.onOpenWallet,
    required this.onOpenDataRights,
    required this.onOpenCampaigns,
    required this.onOpenSettings,
  });

  final _FanSurfaceTarget active;
  final VoidCallback onReturnToFeed;
  final VoidCallback onOpenOnboarding;
  final VoidCallback onOpenImmersive;
  final VoidCallback onOpenCapture;
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenDataRights;
  final VoidCallback onOpenCampaigns;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('fan_secondary_action_rail'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TextButton.icon(
            key: const ValueKey('fan_return_to_feed_button'),
            onPressed: onReturnToFeed,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Return to Feed'),
          ),
          const SizedBox(width: 6),
          _FanRailButton(
            keyName: 'start_fan_onboarding_button',
            tooltip: 'Start onboarding',
            icon: Icons.person_add_alt_1_rounded,
            active: active == _FanSurfaceTarget.onboarding,
            onPressed: onOpenOnboarding,
          ),
          _FanRailButton(
            keyName: 'p14_toggle_immersive_button',
            tooltip: 'Immersive feed',
            icon: Icons.smart_display_rounded,
            active: active == _FanSurfaceTarget.immersive,
            onPressed: onOpenImmersive,
          ),
          _FanRailButton(
            keyName: 'p12_open_capture_link_button',
            tooltip: 'Creator invite',
            icon: Icons.link_rounded,
            active: active == _FanSurfaceTarget.capture,
            onPressed: onOpenCapture,
          ),
          _FanRailButton(
            keyName: 'p6_open_wallet_button',
            tooltip: 'Wallet',
            icon: Icons.account_balance_wallet_rounded,
            active: active == _FanSurfaceTarget.wallet,
            onPressed: onOpenWallet,
          ),
          _FanRailButton(
            keyName: 'p7_open_data_rights_button',
            tooltip: 'Data rights',
            icon: Icons.verified_user_outlined,
            active: active == _FanSurfaceTarget.dataRights,
            onPressed: onOpenDataRights,
          ),
          _FanRailButton(
            keyName: 'p8_open_campaigns_button',
            tooltip: 'Campaigns',
            icon: Icons.emoji_events_outlined,
            active: active == _FanSurfaceTarget.campaigns,
            onPressed: onOpenCampaigns,
          ),
          _FanRailButton(
            keyName: 'p22_open_ai_search_settings_button',
            tooltip: 'AI search settings',
            icon: Icons.tune_rounded,
            active: active == _FanSurfaceTarget.settings,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _FanRailButton extends StatelessWidget {
  const _FanRailButton({
    required this.keyName,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String keyName;
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = active
        ? IconButton.filled(
            key: ValueKey(keyName),
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon),
          )
        : IconButton.filledTonal(
            key: ValueKey(keyName),
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon),
          );
    return Padding(padding: const EdgeInsets.only(right: 8), child: button);
  }
}
