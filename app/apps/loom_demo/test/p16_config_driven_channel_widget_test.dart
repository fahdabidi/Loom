import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
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

  testWidgets('p16 renderer produces distinct creator worlds', (tester) async {
    await _pumpChannel(tester, 'creator_nova_clutch');
    expect(
      find.byKey(
        const ValueKey('p16_channel_banner_seed://banners/nova-clutch'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p16_module_creator_nova_clutch_clip_arena')),
      findsOneWidget,
    );
    expect(find.textContaining('Tactical coach'), findsWidgets);
    expect(find.textContaining('performance_gear_contextual'), findsWidgets);

    await _pumpChannel(tester, 'creator_ember_hollow');
    expect(
      find.byKey(
        const ValueKey('p16_channel_banner_seed://banners/ember-hollow'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p16_module_creator_ember_hollow_quest_log')),
      findsOneWidget,
    );
    expect(find.textContaining('Warm lorekeeper'), findsWidgets);
    expect(
      find.textContaining('crafting_and_indie_games_contextual'),
      findsWidgets,
    );
  });

  testWidgets('p16 unknown modules render safe placeholders', (tester) async {
    final api = CreatorExperienceFake(store, latency: Duration.zero);
    final config = (await tester.runAsync(
      () => api.getExperienceConfig(channelId: 'creator_frame_by_frame'),
    ))!;
    await tester.runAsync(
      () => api.putExperienceConfig(
        config: CreatorExperienceConfig(
          channelId: config.channelId,
          theme: config.theme,
          bannerRef: config.bannerRef,
          surfaceModules: [
            ...config.surfaceModules,
            const SurfaceModule(
              moduleId: 'mystery_lab',
              kind: 'unknown',
              title: 'Mystery Lab',
              surface: 'feed_module',
              sortOrder: 99,
              enabled: true,
              config: {},
            ),
          ],
          aiPersona: config.aiPersona,
          adPosture: config.adPosture,
          installedExtensions: config.installedExtensions,
          version: config.version + 1,
          updatedAt: config.updatedAt,
        ),
        idempotencyKey: 'p16-widget-unknown-module',
      ),
    );

    await _pumpChannel(tester, 'creator_frame_by_frame');
    expect(
      find.byKey(
        const ValueKey('p16_module_creator_frame_by_frame_mystery_lab'),
      ),
      findsOneWidget,
    );
    expect(find.text('Safe placeholder'), findsOneWidget);
  });

  testWidgets('p16 non-gaming creators render through generic config', (
    tester,
  ) async {
    await _pumpChannel(tester, 'creator_solar_sarah');
    expect(
      find.byKey(const ValueKey('p16_module_creator_solar_sarah_content_rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p4_content_video_content_solar_001')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpChannel(WidgetTester tester, String channelId) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLoomTheme(),
      home: CreatorChannelHomeScreen(
        channelId: channelId,
        onOpenContent: (_) {},
        onBack: () {},
        onAskArchive: (_) {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}
