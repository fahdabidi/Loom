import 'dart:io';

import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_onboarding/feature_creator_onboarding.dart';
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
        studioBuilder: (_) => const CreatorOnboardingScreen(),
      ),
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
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('start_fan_onboarding_button'),
              onPressed: () => setState(() => _showOnboarding = true),
              child: const Text('Start fan onboarding'),
            ),
          ),
        ),
        const Expanded(
          child: CreatorContentListScreen(channelId: 'creator_solar_sarah'),
        ),
      ],
    );
  }
}
