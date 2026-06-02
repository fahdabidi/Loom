import 'package:feature_fan_settings/feature_fan_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
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

  test(
    'p22 settings controller persists agent and source preferences',
    () async {
      final controller = FanAiSearchSettingsController();
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.config?.connected, isFalse);
      expect(controller.config?.preferCreators, isTrue);

      await controller.connectAgent(
        provider: AiSearchProvider.anthropicClaude,
        endpoint: 'mcp://demo-agent/search',
      );
      await controller.setExternalSourcesEnabled(true);
      await controller.setSourceConnected(
        sourceType: ExternalSourceType.youtube,
        connected: true,
      );
      await controller.setPreferCreators(false);

      final persisted = await resolveFanVaultApi().getSearchAgentConfig(
        'passport_demo_fan',
      );
      final sources = await resolveFanVaultApi().getExternalSourceConnections(
        'passport_demo_fan',
      );

      expect(persisted.connected, isTrue);
      expect(persisted.externalSourcesEnabled, isTrue);
      expect(persisted.preferCreators, isFalse);
      expect(
        sources
            .singleWhere(
              (source) => source.sourceType == ExternalSourceType.youtube,
            )
            .connected,
        isTrue,
      );
    },
  );

  testWidgets('p22 settings screen renders agent controls and disclosure', (
    tester,
  ) async {
    final controller = FanAiSearchSettingsController();
    addTearDown(controller.dispose);
    await tester.runAsync(controller.load);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: FanAiSearchSettingsScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('p22_fan_settings_screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p22_query_egress_disclosure')),
      findsOneWidget,
    );
    expect(find.text('Disconnected'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p22_connect_agent_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p22_prefer_creators_toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p22_external_sources_toggle')),
      findsOneWidget,
    );
  });
}
