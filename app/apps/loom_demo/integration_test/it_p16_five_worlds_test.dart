import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p16_five_worlds', (tester) async {
    resetAppShellDependencies();
    await configureDemoDependencies(persistent: false);

    for (final entry in _expectedModules.entries) {
      await _pumpChannel(tester, entry.key);
      expect(
        find.byKey(ValueKey('p16_module_${entry.key}_${entry.value}')),
        findsOneWidget,
      );
    }
  });
}

const _expectedModules = {
  'creator_nova_clutch': 'clip_arena',
  'creator_ember_hollow': 'quest_log',
  'creator_frame_by_frame': 'clip_arena',
  'creator_drift_and_chill': 'hypewars',
  'creator_iron_vael': 'guild_quest',
};

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
