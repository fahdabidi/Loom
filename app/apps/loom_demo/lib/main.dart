import 'dart:io';

import 'package:feature_ai_qa/feature_ai_qa.dart';
import 'package:feature_campaigns/feature_campaigns.dart';
import 'package:feature_creator_audience/feature_creator_audience.dart';
import 'package:feature_creator_campaigns/feature_creator_campaigns.dart';
import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_export/feature_creator_export.dart';
import 'package:feature_creator_launch/feature_creator_launch.dart';
import 'package:feature_creator_onboarding/feature_creator_onboarding.dart';
import 'package:feature_creator_publishing/feature_creator_publishing.dart';
import 'package:feature_creator_recommendations/feature_creator_recommendations.dart';
import 'package:feature_creator_revenue/feature_creator_revenue.dart';
import 'package:feature_data_rights/feature_data_rights.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:feature_fan_onboarding/feature_fan_onboarding.dart';
import 'package:feature_playback/feature_playback.dart';
import 'package:feature_wallet/feature_wallet.dart';
import 'package:flutter/material.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDemoDependencies();
  runApp(const LoomDemoApp());
}

Future<void> configureDemoDependencies({bool persistent = true}) async {
  final store = persistent
      ? await DemoLocalStore.open(databaseFile: await _databaseFile())
      : await DemoLocalStore.seeded();
  registerCreatorMetadataApi(CreatorMetadataFake(store));
  registerFanPassportApi(FanPassportFake(store));
  registerFanVaultApi(FanVaultFake(store));
  registerCreatorAudienceApi(CreatorAudienceFake(store));
  registerCampaignApi(CampaignFake(store));
  registerCreatorChannelRegistryApi(CreatorChannelRegistryFake(store));
  registerContentHostApi(ContentHostFake(store));
  registerMigrationExportApi(MigrationExportFake(store));
  registerEntitlementLedgerApi(EntitlementLedgerFake(store));
  registerAiGatewayApi(AiGatewayFake(store));
  registerAdDecisionApi(AdDecisionFake(store));
  registerAudienceAnalyticsApi(AudienceAnalyticsFake(store));
  registerCreatorAnnouncementApi(CreatorAnnouncementFake(store));
  registerCrossPostingApi(CrossPostingFake(store));
  registerExternalAccountLinkApi(ExternalAccountLinkFake(store));
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
        fanBuilder: (_) => const FanAppSurface(),
        studioBuilder: (_) => const CreatorStudioSurface(),
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
  bool _showRecommendations = false;
  bool _showCampaigns = false;
  bool _showExport = false;
  bool _showLaunch = false;

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
  const FanAppSurface({super.key});

  @override
  State<FanAppSurface> createState() => _FanAppSurfaceState();
}

class _FanAppSurfaceState extends State<FanAppSurface> {
  bool _showOnboarding = false;
  bool _showWallet = false;
  bool _showDataRights = false;
  bool _showCampaigns = false;
  String? _channelId;
  String? _contentId;
  String? _qaCreatorId;

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return const FanOnboardingScreen();
    }
    if (_showWallet) {
      return WalletScreen(onBack: () => setState(() => _showWallet = false));
    }
    if (_showDataRights) {
      return DataRightsDashboardScreen(
        onBack: () => setState(() => _showDataRights = false),
      );
    }
    if (_showCampaigns) {
      return CampaignEntryScreen(
        onBack: () => setState(() => _showCampaigns = false),
      );
    }
    final qaCreatorId = _qaCreatorId;
    if (qaCreatorId != null) {
      return ArchiveQaScreen(
        creatorId: qaCreatorId,
        onBack: () => setState(() => _qaCreatorId = null),
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
        onAskArchive: (id) => setState(() => _qaCreatorId = id),
      );
    }

    return DiscoveryHomeScreen(
      onStartOnboarding: () => setState(() => _showOnboarding = true),
      onOpenCreator: (id) => setState(() => _channelId = id),
      onOpenContent: (id) => setState(() => _contentId = id),
      onOpenWallet: () => setState(() => _showWallet = true),
      onOpenDataRights: () => setState(() => _showDataRights = true),
      onOpenCampaigns: () => setState(() => _showCampaigns = true),
    );
  }
}
