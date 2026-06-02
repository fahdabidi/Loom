import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p19_author_experience', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: CreatorCustomizeConsoleScreen(
            creatorId: 'creator_ember_hollow',
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.ensureVisible(
      find.byKey(const ValueKey('p19_theme_nova-arena')),
    );
    await tester.tap(find.byKey(const ValueKey('p19_theme_nova-arena')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('p19_save_experience_button')));
    await tester.pump(const Duration(milliseconds: 900));

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.textContaining('Arena broadcast'), findsWidgets);
  });
}
