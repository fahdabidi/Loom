import '../models/ai_gateway/archive_models.dart';
import '../models/ai_gateway/summary_draft.dart';
import '../models/fan_vault/ranking_preference.dart';
import '../models/recommendation_referral/discovery_models.dart';

abstract class AiGatewayApi {
  Future<SummaryDraft> generateSummaryDraft({
    required String title,
    required String sourceNote,
  });

  Future<ArchiveAnswer> askArchive({
    required String passportId,
    required String creatorId,
    required String question,
    required String policyRef,
    required String idempotencyKey,
  });

  Future<SummaryRankResult> rankBySummary({
    required RankPreference preference,
    required List<FeedItem> candidates,
  });
}
