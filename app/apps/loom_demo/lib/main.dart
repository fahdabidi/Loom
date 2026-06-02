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
    show LoomChannelTheme;
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

  @override
  Widget build(BuildContext context) {
    if (_showRevenue) {
      return CreatorRevenueDashboardScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showRevenue = false),
      );
    }
    if (_showAudience) {
      return AudienceInsightsScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showAudience = false),
      );
    }
    if (_showConversion) {
      return CreatorConversionAnalyticsScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showConversion = false),
      );
    }
    if (_showRecommendations) {
      return RecommendationBuilderScreen(
        onBack: () => setState(() => _showRecommendations = false),
      );
    }
    if (_showCampaigns) {
      return CreatorCampaignBuilderScreen(
        onBack: () => setState(() => _showCampaigns = false),
      );
    }
    if (_showExport) {
      return CreatorExportWizardScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showExport = false),
      );
    }
    if (_showLaunch) {
      return CreatorLaunchScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showLaunch = false),
      );
    }
    if (_showCatalogImport) {
      return CatalogImportConsoleScreen(
        channelId: 'creator_solar_sarah',
        onBack: () => setState(() => _showCatalogImport = false),
      );
    }
    if (_showAdPolicy) {
      return CreatorAdPolicyConsoleScreen(
        channelId: 'creator_solar_sarah',
        onBack: () => setState(() => _showAdPolicy = false),
      );
    }
    if (_showCreatorAi) {
      return CreatorArchiveAiPreviewScreen(
        creatorId: 'creator_solar_sarah',
        onBack: () => setState(() => _showCreatorAi = false),
      );
    }
    if (_showMemberships) {
      return CreatorMembershipSetupScreen(
        channelId: 'creator_solar_sarah',
        onBack: () => setState(() => _showMemberships = false),
      );
    }
    if (_showCustomize) {
      return CreatorCustomizeConsoleScreen(
        creatorId: 'creator_nova_clutch',
        onBack: () => setState(() => _showCustomize = false),
      );
    }
    if (_showPublishingSetup) {
      return const CreatorPublishingSetupScreen(channelId: _phaseOneChannelId);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p6_open_revenue_dashboard_button'),
                      onPressed: () => setState(() => _showRevenue = true),
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Revenue'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('p7_open_audience_button'),
                      onPressed: () => setState(() => _showAudience = true),
                      icon: const Icon(Icons.groups_2_rounded),
                      label: const Text('Audience'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p8_open_recommendations_button'),
                      onPressed: () =>
                          setState(() => _showRecommendations = true),
                      icon: const Icon(Icons.recommend_rounded),
                      label: const Text('Recommendations'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('p8_open_campaign_builder_button'),
                      onPressed: () => setState(() => _showCampaigns = true),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Campaigns'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('p11_open_launch_button'),
                      onPressed: () => setState(() => _showLaunch = true),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Launch'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p9_open_export_button'),
                      onPressed: () => setState(() => _showExport = true),
                      icon: const Icon(Icons.archive_rounded),
                      label: const Text('Export'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('p13_open_conversion_button'),
                      onPressed: () => setState(() => _showConversion = true),
                      icon: const Icon(Icons.stacked_bar_chart_rounded),
                      label: const Text('Funnel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p13_open_catalog_import_button'),
                      onPressed: () =>
                          setState(() => _showCatalogImport = true),
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Import'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p13_open_ad_policy_button'),
                      onPressed: () => setState(() => _showAdPolicy = true),
                      icon: const Icon(Icons.policy_outlined),
                      label: const Text('Ads'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('p13_open_creator_ai_button'),
                      onPressed: () => setState(() => _showCreatorAi = true),
                      icon: const Icon(Icons.psychology_alt_outlined),
                      label: const Text('AI'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('p19_open_customize_button'),
                  onPressed: () => setState(() => _showCustomize = true),
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: const Text('Customize fan experience'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('p13_open_membership_button'),
                  onPressed: () => setState(() => _showMemberships = true),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Membership setup'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('p9_open_export_button_full'),
                  onPressed: () => setState(() => _showExport = true),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Export and transparency'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CreatorOnboardingScreen(
            onOpenPublishingSetup: () {
              setState(() => _showPublishingSetup = true);
            },
          ),
        ),
      ],
    );
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
    required this.onOpenOnboarding,
    required this.onOpenImmersive,
    required this.onOpenCapture,
    required this.onOpenWallet,
    required this.onOpenDataRights,
    required this.onOpenCampaigns,
    required this.onOpenSettings,
  });

  final _FanSurfaceTarget active;
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
