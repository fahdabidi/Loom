import 'package:feature_fan_settings/feature_fan_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p22 connect simulated agent and YouTube source', (tester) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });

    final controller = FanAiSearchSettingsController();
    addTearDown(controller.dispose);
    await controller.load();
    await controller.connectAgent(
      provider: AiSearchProvider.anthropicClaude,
      endpoint: 'mcp://demo-agent/search',
    );
    await controller.setExternalSourcesEnabled(true);
    await controller.setSourceConnected(
      sourceType: ExternalSourceType.youtube,
      connected: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: FanAiSearchSettingsScreen(controller: controller, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
  });
}
