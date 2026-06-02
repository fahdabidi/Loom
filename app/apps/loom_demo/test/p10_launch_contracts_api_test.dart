import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p10 launch contracts persist through local store fakes', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);

    const creatorId = 'creator_solar_sarah';
    const passportId = 'passport_demo_fan';

    final capture = FanFollowCaptureFake(store, latency: Duration.zero);
    final announcement = CreatorAnnouncementFake(store, latency: Duration.zero);
    final starterPack = StarterPackFake(store, latency: Duration.zero);
    final analytics = AudienceAnalyticsFake(store, latency: Duration.zero);
    final external = ExternalAccountLinkFake(store, latency: Duration.zero);
    final importMetadata = ImportPublicMetadataFake(
      store,
      latency: Duration.zero,
    );
    final crossPosting = CrossPostingFake(store, latency: Duration.zero);
    final adDecision = AdDecisionFake(store, latency: Duration.zero);
    final wallet = FanWalletFake(store, latency: Duration.zero);
    final premiumNoAd = PremiumNoAdFake(store, latency: Duration.zero);

    final link = await capture.createCaptureLink(
      channelId: creatorId,
      channel: 'social_post',
      starterPackEnabled: true,
      idempotencyKey: 'p10-capture',
    );
    final replayedLink = await capture.createCaptureLink(
      channelId: creatorId,
      channel: 'social_post',
      starterPackEnabled: true,
      idempotencyKey: 'p10-capture',
    );
    expect(replayedLink.token, link.token);
    expect(
      (await capture.resolveCaptureLink(
        token: link.token,
        passportId: passportId,
      )).starterPackToken,
      isNotNull,
    );

    final refollow = await capture.recordReFollow(
      token: link.token,
      passportId: passportId,
      followVisibility: 'creator_visible',
      idempotencyKey: 'p10-refollow',
    );
    final refollowReplay = await capture.recordReFollow(
      token: link.token,
      passportId: passportId,
      followVisibility: 'creator_visible',
      idempotencyKey: 'p10-refollow',
    );
    expect(refollow.followState, ReFollowState.followed);
    expect(refollowReplay.pairwiseCreatorFanId, refollow.pairwiseCreatorFanId);

    final templates = await announcement.listAnnouncementTemplates(
      channelId: creatorId,
    );
    final rendered = await announcement.renderAnnouncement(
      channelId: creatorId,
      templateId: templates.first.templateId,
      captureLinkToken: link.token,
      fields: const {},
      idempotencyKey: 'p10-render',
    );
    final bio = await announcement.getLinkInBio(channelId: creatorId);
    expect(rendered.renderedBody, contains(link.url));
    expect(bio.captureLinkUrl, startsWith('https://loom.example/c/'));

    final pack = await starterPack.getStarterPack(
      channelId: creatorId,
      passportId: passportId,
    );
    final bulk = await starterPack.bulkFollow(
      channelId: creatorId,
      passportId: passportId,
      channelIds: pack.members.map((member) => member.channelId).toList(),
      followVisibility: 'creator_visible',
      idempotencyKey: 'p10-bulk-follow',
    );
    final bulkReplay = await starterPack.bulkFollow(
      channelId: creatorId,
      passportId: passportId,
      channelIds: pack.members.map((member) => member.channelId).toList(),
      followVisibility: 'creator_visible',
      idempotencyKey: 'p10-bulk-follow',
    );
    expect(pack.members.length, greaterThanOrEqualTo(2));
    expect(bulk.feedReady, isTrue);
    expect(bulkReplay.followed, bulk.followed);

    final accounts = await external.listExternalAccounts(channelId: creatorId);
    final linked = await external.linkExternalAccount(
      channelId: creatorId,
      platform: 'tiktok',
      handle: '@solar-sarah',
      idempotencyKey: 'p10-link-external',
    );
    final verified = await external.verifyExternalAccount(
      channelId: creatorId,
      linkId: linked.linkId,
      method: 'posted_code',
      idempotencyKey: 'p10-verify-external',
    );
    expect(accounts, isNotEmpty);
    expect(verified.verificationState, 'verified');

    final importJob = await importMetadata.startImport(
      channelId: creatorId,
      externalAccountLinkId: verified.linkId,
      rightsBasis: 'own_public_content',
      idempotencyKey: 'p10-import-public',
    );
    final completedImport = await importMetadata.getImportJob(
      channelId: creatorId,
      jobId: importJob.jobId,
    );
    final references = await importMetadata.listImportedReferences(
      channelId: creatorId,
      jobId: importJob.jobId,
    );
    expect(completedImport.status, 'complete');
    expect(references, isNotEmpty);

    final post = await crossPosting.createCrossPost(
      channelId: creatorId,
      targetLinkIds: [verified.linkId],
      message: rendered.renderedBody,
      announcementId: rendered.announcementId,
      captureLinkUrl: link.url,
      idempotencyKey: 'p10-cross-post',
    );
    final delivered = await crossPosting.getCrossPost(
      channelId: creatorId,
      crossPostId: post.crossPostId,
    );
    expect(delivered.targets.single.deliveryStatus, 'complete');

    final decision = await adDecision.decideAds(
      contentId: 'content_solar_001',
      adPosture: 'standard',
      entitlementState: 'ad_supported',
      idempotencyKey: 'p10-ad-decision',
    );
    final impression = await adDecision.recordAdImpression(
      decisionId: decision.decisionId,
      adId: decision.ads.first.adId,
      completed: true,
      idempotencyKey: 'p10-ad-impression',
    );
    final noAdsDecision = await adDecision.decideAds(
      contentId: 'content_solar_001',
      adPosture: 'none',
      entitlementState: 'premium_no_ad',
      idempotencyKey: 'p10-ad-decision-none',
    );
    expect(impression.receiptId, isNotNull);
    expect(noAdsDecision.ads, isEmpty);

    final intent = await wallet.createPaymentIntent(
      passportId: passportId,
      kind: PurchaseKind.noAdsPremium,
      idempotencyKey: 'p10-no-ad-intent',
    );
    await wallet.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p10-no-ad-confirm',
    );
    final status = await premiumNoAd.getPremiumNoAdStatus(fanId: passportId);
    final noAdView = await premiumNoAd.recordPremiumNoAdView(
      fanId: passportId,
      contentId: 'content_solar_001',
      channelId: creatorId,
      sessionIntent: 'support',
      idempotencyKey: 'p10-no-ad-view',
    );
    expect(status.active, isTrue);
    expect(noAdView.noAdApplied, isTrue);
    expect(noAdView.receiptId, isNotNull);

    final funnel = await analytics.getConversionFunnel(channelId: creatorId);
    expect(funnel.aggregateOnly, isTrue);
    expect(funnel.stages.map((stage) => stage.stage), [
      'reached',
      're_followed',
      'member',
      'premium',
    ]);
    expect(funnel.byChannelSource, isNotEmpty);
  });
}
