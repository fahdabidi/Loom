import '../models/campaign/campaign_models.dart';

abstract class CampaignApi {
  Future<Campaign> createCampaign({
    required String creatorId,
    required String title,
    required String description,
    required String rewardLabel,
    required DateTime endsAt,
    required String idempotencyKey,
  });

  Future<Campaign?> getCampaign(String campaignId);

  Future<List<Campaign>> listActiveCampaigns();

  Future<CampaignEntry> participate({
    required String campaignId,
    required String passportId,
    required String idempotencyKey,
  });

  Future<Reward> issueReward({
    required String campaignId,
    required String entryId,
    required String idempotencyKey,
  });
}
