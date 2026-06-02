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

  testWidgets('it_p18_build_showcase', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await _pumpChannel(tester, 'creator_iron_vael');
    final submitBuild = find.text('Submit build', skipOffstage: false);
    await tester.ensureVisible(submitBuild);
    await tester.pump();
    await tester.tap(submitBuild);
    await tester.pump(const Duration(milliseconds: 1200));

    final voteFeatured = find.text('Vote featured', skipOffstage: false);
    await tester.ensureVisible(voteFeatured);
    await tester.pump();
    await tester.tap(voteFeatured);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.textContaining('You -', skipOffstage: false), findsWidgets);
    expect(find.textContaining('votes', skipOffstage: false), findsWidgets);
  });
}

Future<void> _pumpChannel(WidgetTester tester, String channelId) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLoomTheme(),
      home: Scaffold(
        body: CreatorChannelHomeScreen(
          channelId: channelId,
          onOpenContent: (_) {},
          onBack: () {},
          extensionModuleBuilder: _buildExtension,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();
}

Widget _buildExtension(
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
}
