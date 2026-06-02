import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p10_launch_contract_smoke', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    const creatorId = 'creator_solar_sarah';
    const passportId = 'passport_demo_fan';
    final capture = resolveFanFollowCaptureApi();
    final announcement = resolveCreatorAnnouncementApi();
    final starterPack = resolveStarterPackApi();
    final analytics = resolveAudienceAnalyticsApi();

    final link = await capture.createCaptureLink(
      channelId: creatorId,
      channel: 'qr',
      starterPackEnabled: true,
      idempotencyKey: 'it-p10-capture',
    );
    final landing = await capture.resolveCaptureLink(
      token: link.token,
      passportId: passportId,
    );
    final templates = await announcement.listAnnouncementTemplates(
      channelId: creatorId,
    );
    final rendered = await announcement.renderAnnouncement(
      channelId: creatorId,
      templateId: templates.first.templateId,
      captureLinkToken: link.token,
      fields: const {},
      idempotencyKey: 'it-p10-render',
    );
    final pack = await starterPack.getStarterPack(
      channelId: creatorId,
      passportId: passportId,
    );
    final bulk = await starterPack.bulkFollow(
      channelId: creatorId,
      passportId: passportId,
      channelIds: pack.members.map((member) => member.channelId).toList(),
      followVisibility: 'creator_visible',
      idempotencyKey: 'it-p10-bulk-follow',
    );
    final funnel = await analytics.getConversionFunnel(channelId: creatorId);

    expect(landing.starterPackToken, isNotNull);
    expect(rendered.renderedBody, contains(link.url));
    expect(pack.members, isNotEmpty);
    expect(bulk.feedReady, isTrue);
    expect(funnel.aggregateOnly, isTrue);
  });
}
