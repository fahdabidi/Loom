import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p13 creator utilities use typed APIs over local store fakes', () async {
    final store = await DemoLocalStore.seeded();
    final metadataApi = CreatorMetadataFake(store, latency: Duration.zero);
    final entitlementApi = EntitlementLedgerFake(store, latency: Duration.zero);
    final walletApi = FanWalletFake(store, latency: Duration.zero);
    final captureApi = FanFollowCaptureFake(store, latency: Duration.zero);
    final starterPackApi = StarterPackFake(store, latency: Duration.zero);
    final analyticsApi = AudienceAnalyticsFake(store, latency: Duration.zero);
    final importApi = ImportPublicMetadataFake(store, latency: Duration.zero);
    final externalAccountApi = ExternalAccountLinkFake(
      store,
      latency: Duration.zero,
    );
    final adDecisionApi = AdDecisionFake(store, latency: Duration.zero);
    final premiumApi = PremiumNoAdFake(store, latency: Duration.zero);
    final aiApi = AiGatewayFake(store, latency: Duration.zero);

    await captureApi.recordReFollow(
      token: 'cap_creator-solar-sarah_launch',
      passportId: 'passport_demo_fan',
      followVisibility: FollowVisibility.private.name,
      idempotencyKey: 'p13-test-refollow',
    );
    await starterPackApi.bulkFollow(
      channelId: 'creator_solar_sarah',
      passportId: 'passport_demo_fan',
      channelIds: const ['creator_solar_sarah', 'creator_city_ferments'],
      followVisibility: FollowVisibility.private.name,
      idempotencyKey: 'p13-test-bulk-follow',
    );
    final tiers = await metadataApi.defineMembershipTiers(
      channelId: 'creator_solar_sarah',
      tiers: const [
        MembershipTierDraft(
          name: 'Supporter',
          monthlyPriceCents: 500,
          benefits: ['Member posts'],
          entitlementCode: 'member.supporter',
        ),
      ],
      idempotencyKey: 'p13-test-tier',
    );
    await entitlementApi.registerMembershipTierDefinitions(
      channelId: 'creator_solar_sarah',
      tiers: tiers,
      idempotencyKey: 'p13-test-entitlements',
    );
    final intent = await walletApi.createPaymentIntent(
      passportId: 'passport_demo_fan',
      kind: PurchaseKind.creatorMembership,
      creatorId: 'creator_solar_sarah',
      tierId: tiers.first.id,
      idempotencyKey: 'p13-test-membership-intent',
    );
    await walletApi.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p13-test-membership-confirm',
    );
    await premiumApi.recordPremiumNoAdView(
      fanId: 'passport_demo_fan',
      channelId: 'creator_solar_sarah',
      contentId: 'content_solar_001',
      idempotencyKey: 'p13-test-premium-view',
    );

    final funnel = await analyticsApi.getConversionFunnel(
      channelId: 'creator_solar_sarah',
    );
    expect(funnel.aggregateOnly, isTrue);
    expect(_countFor(funnel, 're_followed'), greaterThanOrEqualTo(1));
    expect(_countFor(funnel, 'member'), 1);
    expect(_countFor(funnel, 'premium'), 1);

    final account = (await externalAccountApi.listExternalAccounts(
      channelId: 'creator_solar_sarah',
    )).first;
    final job = await importApi.startImport(
      channelId: 'creator_solar_sarah',
      externalAccountLinkId: account.linkId,
      rightsBasis: 'public_metadata_only',
      idempotencyKey: 'p13-test-public-import',
    );
    final completedJob = await importApi.getImportJob(
      channelId: 'creator_solar_sarah',
      jobId: job.jobId,
    );
    final references = await importApi.listImportedReferences(
      channelId: 'creator_solar_sarah',
      jobId: completedJob.jobId,
    );
    expect(completedJob.status, 'complete');
    expect(references, isNotEmpty);
    expect(references.first.rightsBasis, 'public_metadata_only');

    await metadataApi.setCreatorAdPolicy(
      channelId: 'creator_solar_sarah',
      allowedCategories: const ['sustainable_living'],
      blockedCategories: const ['home_energy', 'gambling', 'alcohol'],
      formats: const ['pre_roll'],
      surfaces: const ['watch'],
      idempotencyKey: 'p13-test-ad-policy',
    );
    final adDecision = await adDecisionApi.decideAds(
      contentId: 'content_solar_001',
      adPosture: 'standard',
      entitlementState: EntitlementState.adSupported.name,
      idempotencyKey: 'p13-test-ad-decision',
    );
    expect(
      adDecision.ads.map((ad) => ad.category),
      isNot(contains('home_energy')),
    );

    await metadataApi.setAIContentPolicy(
      channelId: 'creator_solar_sarah',
      archiveQaEnabled: true,
      summariesEnabled: true,
      citationRequired: true,
      idempotencyKey: 'p13-test-ai-policy',
    );
    final answer = await aiApi.askArchive(
      passportId: 'passport_demo_fan',
      creatorId: 'creator_solar_sarah',
      question: 'What should a new fan watch first?',
      policyRef: 'creator_preview_cited',
      idempotencyKey: 'p13-test-ai-preview',
    );
    expect(answer.citations, isNotEmpty);
    expect(
      answer.receipts.map((receipt) => receipt.type),
      contains(ReceiptType.aiUsage),
    );
  });
}

int _countFor(ConversionFunnel funnel, String stage) {
  return funnel.stages.firstWhere((item) => item.stage == stage).count;
}
