import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_extensions/feature_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart'
    show CreatorExperienceConfig, SurfaceModule;
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_design_system/loom_design_system.dart'
    show LoomChannelTheme;
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

  testWidgets('p18 quest and build modules run live on Ember channel', (
    tester,
  ) async {
    await _pumpChannel(tester, 'creator_ember_hollow');

    final completeQuest = find.text('Complete quest', skipOffstage: false);
    final submitBuild = find.text('Submit build', skipOffstage: false);
    expect(completeQuest, findsOneWidget);
    expect(submitBuild, findsOneWidget);

    await tester.ensureVisible(completeQuest);
    await tester.pump();
    await tester.tap(completeQuest);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Shrine keeper', skipOffstage: false), findsWidgets);

    await tester.ensureVisible(submitBuild);
    await tester.pump();
    await tester.tap(submitBuild);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.textContaining('You -', skipOffstage: false), findsWidgets);
  });

  testWidgets('p18 guild quest renders aggregate progress on Drift channel', (
    tester,
  ) async {
    await _pumpChannel(tester, 'creator_drift_and_chill');

    final contribute = find.text('Contribute', skipOffstage: false);
    expect(contribute, findsOneWidget);

    await tester.ensureVisible(contribute);
    await tester.pump();
    await tester.tap(contribute);
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.textContaining('5 / 30', skipOffstage: false), findsWidgets);
    expect(
      find.text('Aggregate community progress only', skipOffstage: false),
      findsWidgets,
    );
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
          onAskArchive: (_) {},
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();
}
