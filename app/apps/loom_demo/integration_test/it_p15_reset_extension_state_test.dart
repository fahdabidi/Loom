import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p15_reset_extension_state', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    final runtime = resolveExtensionRuntimeApi();
    final experience = resolveCreatorExperienceApi();
    final reset = resolveMigrationExportApi();

    final before = await experience.getExperienceConfig(
      channelId: 'creator_nova_clutch',
    );
    final install = before.installedExtensions.first;
    final session = await runtime.createExtensionSession(
      channelId: 'creator_nova_clutch',
      extensionId: install.extensionId,
      surface: install.surfaces.first,
      fanId: 'passport_demo_fan',
      idempotencyKey: 'it-p15-reset-session',
    );
    await runtime.submitExtensionEvent(
      sessionId: session.sessionId,
      type: 'reward_earned',
      payload: const {'rewardCode': 'integration-reset'},
      idempotencyKey: 'it-p15-reset-event',
    );
    expect(
      (await runtime.createExtensionStateExport(
        channelId: 'creator_nova_clutch',
        fanId: 'passport_demo_fan',
      )).entries.map((entry) => entry.key),
      contains('last_event_reward-earned'),
    );

    await reset.resetDemo(idempotencyKey: 'it-p15-reset-demo');
    final after = await experience.getExperienceConfig(
      channelId: 'creator_nova_clutch',
    );
    final exportAfterReset = await runtime.createExtensionStateExport(
      channelId: 'creator_nova_clutch',
      fanId: 'passport_demo_fan',
    );
    expect(
      after.installedExtensions,
      hasLength(before.installedExtensions.length),
    );
    expect(
      exportAfterReset.entries.map((entry) => entry.key),
      isNot(contains('last_event_reward-earned')),
    );
  });
}
