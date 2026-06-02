import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p10_reset_launch_state', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    const creatorId = 'creator_solar_sarah';
    final capture = resolveFanFollowCaptureApi();
    final announcement = resolveCreatorAnnouncementApi();
    final starterPack = resolveStarterPackApi();
    final reset = resolveMigrationExportApi();

    final mutableLink = await capture.createCaptureLink(
      channelId: creatorId,
      channel: 'email',
      starterPackEnabled: true,
      idempotencyKey: 'it-p10-reset-capture',
    );
    await reset.resetDemo(idempotencyKey: 'it-p10-reset');

    await expectLater(
      capture.resolveCaptureLink(
        token: mutableLink.token,
        passportId: 'passport_demo_fan',
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      await announcement.listAnnouncementTemplates(channelId: creatorId),
      isNotEmpty,
    );
    expect(
      (await starterPack.getStarterPack(
        channelId: creatorId,
        passportId: 'passport_demo_fan',
      )).members,
      isNotEmpty,
    );
  });
}
