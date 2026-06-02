import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_design_system/loom_design_system.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;

  setUp(() async {
    resetAppShellDependencies();
    store = await configureDemoDependencies(persistent: false);
  });

  tearDown(() async {
    await store.close();
    resetAppShellDependencies();
  });

  testWidgets('p20 channel banner uses procedural media backdrop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: const ChannelBanner(
          theme: LoomChannelTheme.fallback,
          bannerRef: 'seed://banners/nova-clutch',
          child: const SizedBox(height: 180),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey('p20_channel_media_seed://banners/nova-clutch'),
      ),
      findsOneWidget,
    );
    expect(find.text('Arena media'), findsOneWidget);
  });

  testWidgets('p20 creator channel exposes loading and empty module states', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final api = resolveCreatorExperienceApi();
      final config = await api.getExperienceConfig(
        channelId: 'creator_ember_hollow',
      );
      await api.putExperienceConfig(
        config: CreatorExperienceConfig(
          channelId: config.channelId,
          theme: config.theme,
          bannerRef: config.bannerRef,
          surfaceModules: config.surfaceModules
              .map(
                (module) => SurfaceModule(
                  moduleId: module.moduleId,
                  kind: module.kind,
                  title: module.title,
                  surface: module.surface,
                  sortOrder: module.sortOrder,
                  enabled: false,
                  extensionId: module.extensionId,
                  config: module.config,
                ),
              )
              .toList(growable: false),
          aiPersona: config.aiPersona,
          adPosture: config.adPosture,
          installedExtensions: config.installedExtensions,
          version: config.version + 1,
          updatedAt: DateTime.now().toUtc(),
        ),
        idempotencyKey: 'p20-empty-modules',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: CreatorChannelHomeScreen(
            channelId: 'creator_ember_hollow',
            onOpenContent: (_) {},
            onBack: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('p20_channel_loading_state')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('p14_loading_skeleton')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.byKey(const ValueKey('p20_channel_empty_modules')),
      findsOneWidget,
    );
  });
}
