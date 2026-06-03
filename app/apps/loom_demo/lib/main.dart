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

  bool _showChannelSetup = false;
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
  bool _creatorOnboardingComplete = false;

  void _openStudioHome() {
    setState(() {
      _showChannelSetup = false;
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
      _showChannelSetup = target == _CreatorSurfaceTarget.channel;
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
    required String title,
    required Widget child,
  }) {
    return Column(
      key: const ValueKey('creator_subsurface_with_rail'),
      children: [
        _CreatorReturnHeader(title: title, onReturnToStudio: _openStudioHome),
        _CreatorStudioActionRail(
          active: active,
          onOpenStudioHome: _openStudioHome,
          onOpenChannelSetup: () =>
              _openCreatorSurface(_CreatorSurfaceTarget.channel),
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
          onOpenExport: () => _openCreatorSurface(_CreatorSurfaceTarget.export),
          onOpenLaunch: () => _openCreatorSurface(_CreatorSurfaceTarget.launch),
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
        Expanded(child: child),
      ],
    );
  }

  Widget _withCreatorHome(Widget child) {
    return Column(
      children: [
        _CreatorStudioActionRail(
          active: null,
          onOpenStudioHome: _openStudioHome,
          onOpenChannelSetup: () =>
              _openCreatorSurface(_CreatorSurfaceTarget.channel),
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
          onOpenExport: () => _openCreatorSurface(_CreatorSurfaceTarget.export),
          onOpenLaunch: () => _openCreatorSurface(_CreatorSurfaceTarget.launch),
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
        Expanded(child: child),
      ],
    );
  }

  void _markCreatorOnboardingComplete() {
    if (_creatorOnboardingComplete) {
      return;
    }
    setState(() {
      _creatorOnboardingComplete = true;
    });
  }

  VoidCallback _openCompletedPublishingSetup() {
    return () {
      setState(() {
        _creatorOnboardingComplete = true;
        _showChannelSetup = false;
        _showPublishingSetup = true;
      });
    };
  }

  Widget _studioLanding() {
    return _withCreatorHome(
      CreatorStudioLandingScreen(
        onboardingComplete: _creatorOnboardingComplete,
        onOpenChannelSetup: () =>
            _openCreatorSurface(_CreatorSurfaceTarget.channel),
        onOpenPublishingSetup: () =>
            _openCreatorSurface(_CreatorSurfaceTarget.publishing),
        onOpenRevenue: () => _openCreatorSurface(_CreatorSurfaceTarget.revenue),
        onOpenAudience: () =>
            _openCreatorSurface(_CreatorSurfaceTarget.audience),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRevenue) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.revenue,
        title: 'Revenue',
        child: CreatorRevenueDashboardScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showAudience) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.audience,
        title: 'Audience',
        child: AudienceInsightsScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showConversion) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.conversion,
        title: 'Conversion funnel',
        child: CreatorConversionAnalyticsScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showRecommendations) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.recommendations,
        title: 'Recommendations',
        child: RecommendationBuilderScreen(onBack: _openStudioHome),
      );
    }
    if (_showCampaigns) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.campaigns,
        title: 'Campaigns',
        child: CreatorCampaignBuilderScreen(onBack: _openStudioHome),
      );
    }
    if (_showExport) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.export,
        title: 'Export',
        child: CreatorExportWizardScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showLaunch) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.launch,
        title: 'Launch',
        child: CreatorLaunchScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCatalogImport) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.catalogImport,
        title: 'Catalog import',
        child: CatalogImportConsoleScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showAdPolicy) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.adPolicy,
        title: 'Ad policy',
        child: CreatorAdPolicyConsoleScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCreatorAi) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.creatorAi,
        title: 'Creator AI',
        child: CreatorArchiveAiPreviewScreen(
          creatorId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showMemberships) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.memberships,
        title: 'Membership setup',
        child: CreatorMembershipSetupScreen(
          channelId: 'creator_solar_sarah',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showCustomize) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.customize,
        title: 'Customize',
        child: CreatorCustomizeConsoleScreen(
          creatorId: 'creator_nova_clutch',
          onBack: _openStudioHome,
        ),
      );
    }
    if (_showPublishingSetup) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.publishing,
        title: 'Publishing setup',
        child: const CreatorPublishingSetupScreen(
          channelId: _phaseOneChannelId,
        ),
      );
    }

    if (_showChannelSetup) {
      return _withCreatorRail(
        active: _CreatorSurfaceTarget.channel,
        title: 'Channel setup',
        child: CreatorOnboardingScreen(
          onComplete: _markCreatorOnboardingComplete,
          onOpenPublishingSetup: _openCompletedPublishingSetup(),
        ),
      );
    }

    return _studioLanding();
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
    required this.onOpenStudioHome,
    required this.onOpenChannelSetup,
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

  final _CreatorSurfaceTarget? active;
  final VoidCallback onOpenStudioHome;
  final VoidCallback onOpenChannelSetup;
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
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _CreatorRailButton(
              keyName: 'creator_studio_home_button',
              tooltip: 'Studio home',
              icon: Icons.home_rounded,
              active: active == null,
              onPressed: onOpenStudioHome,
            ),
            _CreatorRailButton(
              keyName: 'creator_open_channel_setup_button',
              tooltip: 'Channel setup',
              icon: Icons.person_add_alt_1_rounded,
              active: active == _CreatorSurfaceTarget.channel,
              onPressed: onOpenChannelSetup,
            ),
            _CreatorRailButton(
              keyName: 'creator_open_publishing_panel_button',
              tooltip: 'Publishing setup',
              icon: Icons.play_circle_outline_rounded,
              active: active == _CreatorSurfaceTarget.publishing,
              onPressed: onOpenPublishing,
            ),
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
            _CreatorRailButton(
              keyName: 'p13_open_creator_ai_button',
              tooltip: 'Creator AI',
              icon: Icons.psychology_alt_outlined,
              active: active == _CreatorSurfaceTarget.creatorAi,
              onPressed: onOpenCreatorAi,
            ),
            _CreatorRailButton(
              keyName: 'p13_open_membership_button',
              tooltip: 'Membership setup',
              icon: Icons.workspace_premium_outlined,
              active: active == _CreatorSurfaceTarget.memberships,
              onPressed: onOpenMemberships,
            ),
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
          ],
        ),
      ),
    );
  }
}

class _CreatorReturnHeader extends StatelessWidget {
  const _CreatorReturnHeader({
    required this.title,
    required this.onReturnToStudio,
  });

  final String title;
  final VoidCallback onReturnToStudio;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('creator_return_to_studio_button'),
              onPressed: onReturnToStudio,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return to Studio'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatorStudioLandingScreen extends StatelessWidget {
  const CreatorStudioLandingScreen({
    required this.onboardingComplete,
    required this.onOpenChannelSetup,
    required this.onOpenPublishingSetup,
    required this.onOpenRevenue,
    required this.onOpenAudience,
    super.key,
  });

  final bool onboardingComplete;
  final VoidCallback onOpenChannelSetup;
  final VoidCallback onOpenPublishingSetup;
  final VoidCallback onOpenRevenue;
  final VoidCallback onOpenAudience;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('creator_studio_landing'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _CreatorLandingHero(
          onboardingComplete: onboardingComplete,
          onOpenChannelSetup: onOpenChannelSetup,
          onOpenPublishingSetup: onOpenPublishingSetup,
        ),
        const SizedBox(height: 12),
        _CreatorMetricTile(
          keyValue: 'creator_monthly_active_fans_tile',
          icon: Icons.groups_2_rounded,
          title: 'Monthly active fans',
          value: '18.4K',
          delta: '+12% vs last 28 days',
          body:
              'Unique viewers with recent watches, saves, follows, or member actions.',
          onTap: onOpenAudience,
        ),
        _CreatorMetricTile(
          keyValue: 'creator_top_content_tile',
          icon: Icons.workspace_premium_rounded,
          title: 'Most watched content',
          value: 'Solar audit walk-through',
          delta: '4.8K views · 41h watch time',
          body:
              'Filtered view: long-form video, Home energy, ranked by watch time.',
          onTap: onOpenPublishingSetup,
        ),
        _CreatorMetricTile(
          keyValue: 'creator_search_rank_tile',
          icon: Icons.manage_search_rounded,
          title: 'Average fan-search rank',
          value: '#3.2',
          delta: '+0.8 positions',
          body:
              'Mean rank for approved fan queries where your content appears in Loom AI search.',
          onTap: onOpenAudience,
        ),
        const _CreatorMetricTile(
          keyValue: 'creator_ad_serving_tile',
          icon: Icons.ads_click_rounded,
          title: 'Most served ad category',
          value: 'Home efficiency',
          delta: '62% of eligible ad slots',
          body:
              'Shows the top contextual ad category served against your channel inventory.',
        ),
        _CreatorMetricTile(
          keyValue: 'creator_subscriptions_tile',
          icon: Icons.card_membership_rounded,
          title: 'Subscriptions',
          value: '642 weekly · 2.7K monthly',
          delta: '+9% monthly recurring',
          body:
              'Member counts and simulated recurring revenue trend for the current launch demo.',
          onTap: onOpenRevenue,
        ),
      ],
    );
  }
}

class _CreatorLandingHero extends StatelessWidget {
  const _CreatorLandingHero({
    required this.onboardingComplete,
    required this.onOpenChannelSetup,
    required this.onOpenPublishingSetup,
  });

  final bool onboardingComplete;
  final VoidCallback onOpenChannelSetup;
  final VoidCallback onOpenPublishingSetup;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('creator_complete_onboarding_tile'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: onboardingComplete
                    ? LoomColors.moss.withAlpha(38)
                    : LoomColors.sun.withAlpha(48),
                child: Icon(
                  onboardingComplete
                      ? Icons.check_rounded
                      : Icons.flag_outlined,
                  color: onboardingComplete ? LoomColors.moss : LoomColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onboardingComplete
                          ? 'Onboarding complete'
                          : 'Complete onboarding',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      onboardingComplete
                          ? 'Phase 1 identity is ready. Continue publishing setup and launch work.'
                          : 'Phase 1 starts with channel identity, handle, and managed hosting.',
                      style: const TextStyle(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('creator_landing_onboarding_button'),
            onPressed: onboardingComplete
                ? onOpenPublishingSetup
                : onOpenChannelSetup,
            icon: Icon(
              onboardingComplete
                  ? Icons.dashboard_customize_outlined
                  : Icons.add_circle_outline_rounded,
            ),
            label: Text(
              onboardingComplete ? 'Open publishing setup' : 'Complete setup',
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorMetricTile extends StatelessWidget {
  const _CreatorMetricTile({
    required this.keyValue,
    required this.icon,
    required this.title,
    required this.value,
    required this.delta,
    required this.body,
    this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final String title;
  final String value;
  final String delta;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey(keyValue),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LoomColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LoomColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: LoomColors.aqua.withAlpha(36),
                child: Icon(icon, color: LoomColors.aqua),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delta,
                      style: const TextStyle(
                        color: LoomColors.moss,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(
                        color: LoomColors.mutedInk,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox.square(dimension: 40, child: button),
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
    return Column(
      key: const ValueKey('fan_subsurface_with_rail'),
      children: [
        _FanReturnHeader(
          active: active,
          title: _fanSurfaceTitle(active),
          onReturnToFeed: _openDiscovery,
        ),
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: _FanSecondaryActionRail(
                    active: active,
                    onOpenOnboarding: () =>
                        _openFanSurface(_FanSurfaceTarget.onboarding),
                    onOpenImmersive: () => _openDiscovery(immersive: true),
                    onOpenCapture: () =>
                        _openFanSurface(_FanSurfaceTarget.capture),
                    onOpenWallet: () =>
                        _openFanSurface(_FanSurfaceTarget.wallet),
                    onOpenDataRights: () =>
                        _openFanSurface(_FanSurfaceTarget.dataRights),
                    onOpenCampaigns: () =>
                        _openFanSurface(_FanSurfaceTarget.campaigns),
                    onOpenSettings: () =>
                        _openFanSurface(_FanSurfaceTarget.settings),
                  ),
                ),
              ),
            ],
            body: child,
          ),
        ),
      ],
    );
  }

  String _fanSurfaceTitle(_FanSurfaceTarget active) {
    return switch (active) {
      _FanSurfaceTarget.onboarding => 'Setup your fan passport',
      _FanSurfaceTarget.immersive => 'Immersive feed',
      _FanSurfaceTarget.capture => 'Creator invite',
      _FanSurfaceTarget.wallet => 'Wallet',
      _FanSurfaceTarget.dataRights => 'Data rights',
      _FanSurfaceTarget.campaigns => 'Campaigns',
      _FanSurfaceTarget.settings => 'AI search settings',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return _withFanRail(
        active: _FanSurfaceTarget.onboarding,
        child: FanOnboardingScreen(onDone: () => _openDiscovery()),
      );
    }
    if (_showCaptureLanding) {
      return _withFanRail(
        active: _FanSurfaceTarget.capture,
        child: FanCaptureLandingScreen(
          captureToken: 'cap_creator-solar-sarah_launch',
          onDone: () => _openDiscovery(),
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

class _FanReturnHeader extends StatelessWidget {
  const _FanReturnHeader({
    required this.active,
    required this.title,
    required this.onReturnToFeed,
  });

  final _FanSurfaceTarget active;
  final String title;
  final VoidCallback onReturnToFeed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            KeyedSubtree(
              key: const ValueKey('fan_return_to_feed_button'),
              child: TextButton.icon(
                key: ValueKey(_fanReturnKey(active)),
                onPressed: onReturnToFeed,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Return to Feed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fanReturnKey(_FanSurfaceTarget active) {
  return switch (active) {
    _FanSurfaceTarget.onboarding => 'fan_onboarding_feed_back_button',
    _FanSurfaceTarget.immersive => 'fan_return_to_feed_button_active',
    _FanSurfaceTarget.capture => 'p12_capture_back_button',
    _FanSurfaceTarget.wallet => 'p6_wallet_back_button',
    _FanSurfaceTarget.dataRights => 'p7_data_rights_back_button',
    _FanSurfaceTarget.campaigns => 'p8_campaigns_back_button',
    _FanSurfaceTarget.settings => 'p22_settings_back_button',
  };
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
