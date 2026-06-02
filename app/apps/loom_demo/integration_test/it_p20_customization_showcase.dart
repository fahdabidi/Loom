import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_extensions/feature_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart'
    show CreatorExperienceConfig, SurfaceModule;
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_design_system/loom_design_system.dart'
    show LoomChannelTheme;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p20_customization_showcase', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    for (final creatorId in _creatorIds) {
      await _pumpChannel(tester, creatorId);
      expect(find.byKey(const ValueKey('p4_channel_home')), findsOneWidget);
      expect(find.byKey(const ValueKey('p14_loading_skeleton')), findsNothing);
    }
  });
}

const _creatorIds = [
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
];

Future<void> _pumpChannel(WidgetTester tester, String channelId) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLoomTheme(),
      home: Scaffold(
        body: CreatorChannelHomeScreen(
          channelId: channelId,
          onOpenContent: (_) {},
          onBack: () {},
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
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
}
