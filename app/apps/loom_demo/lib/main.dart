import 'dart:io';

import 'package:feature_creator_channel/feature_creator_channel.dart';
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
        fanBuilder: (_) =>
            const CreatorContentListScreen(channelId: 'creator_solar_sarah'),
        studioBuilder: (_) => const StudioProofSliceScreen(),
      ),
    );
  }
}

class StudioProofSliceScreen extends StatelessWidget {
  const StudioProofSliceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Creator Studio scaffold is ready. Phase 1 adds channel onboarding.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
