import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test('p8 referral receipts settle to creator revenue', () async {
    final store = await DemoLocalStore.seeded();
    final recommendationApi = RecommendationReferralFake(
      store,
      latency: Duration.zero,
    );
    final settlementApi = SettlementEngineFake(store, latency: Duration.zero);

    final manifest = await recommendationApi.publishRecommendationManifest(
      sourceCreatorId: 'creator_solar_sarah',
      destinationCreatorId: 'creator_city_ferments',
      contentId: 'content_ferment_001',
      note: 'Useful companion channel for resilient home routines.',
      idempotencyKey: 'test-p8-rec',
    );
    final terms = await recommendationApi.publishReferralTerms(
      sourceCreatorId: 'creator_solar_sarah',
      destinationCreatorId: 'creator_city_ferments',
      windowDays: 14,
      capCents: 5000,
      rewardCents: 350,
      idempotencyKey: 'test-p8-terms',
    );
    final discovery = await recommendationApi.recordDiscovery(
      manifestId: manifest.id,
      passportId: 'passport_demo_fan',
      idempotencyKey: 'test-p8-discovery',
    );
    final referral = await recommendationApi.recordReferralConversion(
      discoveryReceiptId: discovery.id,
      termsId: terms.id,
      idempotencyKey: 'test-p8-referral',
    );

    await settlementApi.runSettlement(idempotencyKey: 'test-p8-settlement');
    final statement = await settlementApi.getCreatorPayoutStatement(
      creatorId: 'creator_solar_sarah',
    );

    expect(referral.amountCents, 350);
    expect(
      statement.bySource.any(
        (source) => source.label == 'Referrals' && source.amountCents == 350,
      ),
      isTrue,
    );
    expect(
      statement.recentReceipts.any(
        (receipt) => receipt.type == ReceiptType.referral,
      ),
      isTrue,
    );
    await store.close();
  });

  test('p8 campaign entry and reward are idempotent', () async {
    final store = await DemoLocalStore.seeded();
    final campaignApi = CampaignFake(store, latency: Duration.zero);

    final campaign = await campaignApi.createCampaign(
      creatorId: 'creator_solar_sarah',
      title: 'Clean Energy Setup Giveaway',
      description: 'Receipt-backed fan giveaway.',
      rewardLabel: 'Home energy kit',
      endsAt: DateTime.utc(2026, 6, 15),
      idempotencyKey: 'test-p8-campaign',
    );
    final entry = await campaignApi.participate(
      campaignId: campaign.id,
      passportId: 'passport_demo_fan',
      idempotencyKey: 'test-p8-entry',
    );
    final duplicateEntry = await campaignApi.participate(
      campaignId: campaign.id,
      passportId: 'passport_demo_fan',
      idempotencyKey: 'test-p8-entry',
    );
    final reward = await campaignApi.issueReward(
      campaignId: campaign.id,
      entryId: entry.id,
      idempotencyKey: 'test-p8-reward',
    );

    expect(duplicateEntry.id, entry.id);
    expect(reward.status, 'issued');
    expect(reward.passportId, 'passport_demo_fan');
    await store.close();
  });

  test(
    'p8 sponsor data offer reuses fan consent and emits access receipt',
    () async {
      final store = await DemoLocalStore.seeded();
      final campaignApi = CampaignFake(store, latency: Duration.zero);
      final sponsorApi = SponsorCampaignFake(latency: Duration.zero);
      final audienceApi = CreatorAudienceFake(store, latency: Duration.zero);
      final passportApi = FanPassportFake(store, latency: Duration.zero);

      final campaign = await campaignApi.createCampaign(
        creatorId: 'creator_solar_sarah',
        title: 'Clean Energy Setup Giveaway',
        description: 'Receipt-backed fan giveaway.',
        rewardLabel: 'Home energy kit',
        endsAt: DateTime.utc(2026, 6, 15),
        idempotencyKey: 'test-p8-campaign-offer',
      );
      final proposal = await sponsorApi.createProposal(
        sponsorName: 'Gridwise Home',
        creatorId: campaign.creatorId,
        campaignId: campaign.id,
        title: 'Energy category insight exchange',
        valueExchange: 'Extra giveaway entry for approved interest fields.',
        idempotencyKey: 'test-p8-proposal',
      );
      final offer = await sponsorApi.attachFanDataGrantOffer(
        proposalId: proposal.id,
        fields: const ['interest_categories'],
        purpose: 'Sponsor fit for home energy giveaway rewards',
        valueExchange: 'Extra giveaway entry and access receipt.',
        idempotencyKey: 'test-p8-offer',
      );

      final request = await audienceApi.createDataGrantRequest(
        creatorId: offer.creatorId,
        passportId: 'passport_demo_fan',
        fields: offer.fields,
        purpose: offer.purpose,
        retention: 'Demo session only',
        valueExchange: offer.valueExchange,
        idempotencyKey: 'test-p8-request',
      );
      await passportApi.reviewDataGrantRequest(
        requestId: request.id,
        passportId: 'passport_demo_fan',
        state: ConsentGrantState.approved,
        approvedFields: offer.fields,
        idempotencyKey: 'test-p8-approve',
      );
      final data = await audienceApi.queryPermissionedInterestData(
        creatorId: offer.creatorId,
        passportId: 'passport_demo_fan',
        purpose: offer.purpose,
        idempotencyKey: 'test-p8-query',
      );
      final receipts = await audienceApi.dataAccessReceipts(
        'passport_demo_fan',
      );

      expect(data.fields, contains('interest_categories'));
      expect(receipts, isNotEmpty);
      expect(receipts.first.purpose, offer.purpose);
      await store.close();
    },
  );
}
