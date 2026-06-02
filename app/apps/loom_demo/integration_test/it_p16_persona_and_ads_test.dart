import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p16_persona_and_ads', (tester) async {
    resetAppShellDependencies();
    await configureDemoDependencies(persistent: false);

    await _pumpChannel(tester, 'creator_nova_clutch');
    expect(find.textContaining('Tactical coach'), findsWidgets);
    expect(find.textContaining('performance_gear_contextual'), findsWidgets);

    await _pumpChannel(tester, 'creator_ember_hollow');
    expect(find.textContaining('Warm lorekeeper'), findsWidgets);
    expect(
      find.textContaining('crafting_and_indie_games_contextual'),
      findsWidgets,
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
