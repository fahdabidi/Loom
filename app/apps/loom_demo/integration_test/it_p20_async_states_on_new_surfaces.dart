import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p20_async_states_on_new_surfaces', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: CreatorChannelHomeScreen(
            channelId: 'creator_nova_clutch',
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
    await tester.pump(const Duration(milliseconds: 900));
    expect(
      find.byKey(
        const ValueKey('p20_channel_media_seed://banners/nova-clutch'),
      ),
      findsOneWidget,
    );
  });
}
