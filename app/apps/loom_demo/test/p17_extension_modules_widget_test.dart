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

  testWidgets('p17 competitive modules render live in Nova channel', (
    tester,
  ) async {
    await _pumpChannel(tester, 'creator_nova_clutch');

    expect(find.text('Clip Arena'), findsWidgets);
    final submitClip = find.text('Submit clip', skipOffstage: false);
    final voteLeader = find.text('Vote leader', skipOffstage: false);
    expect(submitClip, findsOneWidget);
    expect(voteLeader, findsOneWidget);
    expect(find.text('Pick\'Em'), findsWidgets);
    expect(find.text('HypeWars'), findsWidgets);

    await tester.ensureVisible(submitClip);
    await tester.pump();
    await tester.tap(submitClip);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('You'), findsWidgets);
  });

  testWidgets('p17 hype wars advances through wallet confirmation', (
    tester,
  ) async {
    await _pumpChannel(tester, 'creator_drift_and_chill');

    expect(find.text('HypeWars'), findsWidgets);
    final sendHype = find.text('Send hype', skipOffstage: false);
    expect(sendHype, findsOneWidget);

    await tester.ensureVisible(sendHype);
    await tester.pump();
    await tester.tap(sendHype);
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.textContaining(r'$2.99'), findsWidgets);
    expect(find.textContaining('Session session_'), findsWidgets);
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
