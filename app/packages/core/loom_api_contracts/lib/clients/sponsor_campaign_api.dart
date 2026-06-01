import '../models/campaign/campaign_models.dart';

abstract class SponsorCampaignApi {
  Future<SponsorProposal> createProposal({
    required String sponsorName,
    required String creatorId,
    required String campaignId,
    required String title,
    required String valueExchange,
    required String idempotencyKey,
  });

  Future<FanDataGrantOffer> attachFanDataGrantOffer({
    required String proposalId,
    required List<String> fields,
    required String purpose,
    required String valueExchange,
    required String idempotencyKey,
  });

  Future<List<FanDataGrantOffer>> listOffersForCampaign(String campaignId);
}
