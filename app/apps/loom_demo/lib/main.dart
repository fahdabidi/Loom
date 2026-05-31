import 'dart:io';

import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_onboarding/feature_creator_onboarding.dart';
import 'package:feature_creator_publishing/feature_creator_publishing.dart';
import 'package:feature_fan_onboarding/feature_fan_onboarding.dart';
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
  registerCreatorChannelRegistryApi(CreatorChannelRegistryFake(store));
  registerContentHostApi(ContentHostFake(store));
  registerMigrationExportApi(MigrationExportFake(store));
  registerEntitlementLedgerApi(EntitlementLedgerFake(store));
  registerAiGatewayApi(const AiGatewayFake());
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

  @override
  Widget build(BuildContext context) {
    if (_showPublishingSetup) {
      return const CreatorPublishingSetupScreen(channelId: _phaseOneChannelId);
    }

    return CreatorOnboardingScreen(
      onOpenPublishingSetup: () {
        setState(() => _showPublishingSetup = true);
      },
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

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return const FanOnboardingScreen();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FanHomeHeader(
                onStartOnboarding: () => setState(() => _showOnboarding = true),
              ),
              const SizedBox(height: 18),
              const _TopicRail(),
              const SizedBox(height: 20),
              Text(
                'For you',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Creator-led videos and posts seeded from your demo world.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF59636E),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: CreatorContentListScreen(channelId: 'creator_solar_sarah'),
        ),
      ],
    );
  }
}

class _FanHomeHeader extends StatelessWidget {
  const _FanHomeHeader({required this.onStartOnboarding});

  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171A1F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Build a feed that explains itself.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C8EA8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Start with interests, follow a creator, then every card can show why it belongs here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(214),
              height: 1.28,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('start_fan_onboarding_button'),
                  onPressed: onStartOnboarding,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Start fan onboarding'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF111417),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(30),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicRail extends StatelessWidget {
  const _TopicRail();

  static const _topics = [
    ('Energy', Icons.bolt_rounded, Color(0xFFF2C94C)),
    ('Food craft', Icons.restaurant_rounded, Color(0xFFE45858)),
    ('Movement', Icons.directions_run_rounded, Color(0xFF1C8EA8)),
    ('Family', Icons.groups_rounded, Color(0xFF167A55)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          return _TopicPill(label: topic.$1, icon: topic.$2, color: topic.$3);
        },
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withAlpha(44),
            child: Icon(icon, color: color, size: 19),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
