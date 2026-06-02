import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p16_generic_regression', (tester) async {
    resetAppShellDependencies();
    await configureDemoDependencies(persistent: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: CreatorChannelHomeScreen(
          channelId: 'creator_solar_sarah',
          onOpenContent: (_) {},
          onBack: () {},
          onAskArchive: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

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
