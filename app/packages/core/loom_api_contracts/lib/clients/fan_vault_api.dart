import '../models/external_content/external_content_models.dart';
import '../models/fan_vault/ad_preferences.dart';
import '../models/fan_vault/interest_profile.dart';
import '../models/fan_vault/interest_token.dart';
import '../models/fan_vault/ranking_preference.dart';
import '../models/fan_vault/search_agent_config.dart';

abstract class FanVaultApi {
  Future<List<InterestToken>> getInterestTaxonomy();

  Future<InterestProfile> getInterestProfile(String passportId);

  Future<InterestProfile> putInterests({
    required String passportId,
    required List<String> interestIds,
    required String idempotencyKey,
  });

  Future<InterestProfile> putDislikes({
    required String passportId,
    required List<String> dislikedInterestIds,
    required String idempotencyKey,
  });

  Future<AdPreferences> getAdPreferences(String passportId);

  Future<AdPreferences> putAdPreferences({
    required String passportId,
    required bool personalizedAds,
    required String idempotencyKey,
  });

  Future<RankPreference> getRankPreference(String passportId);

  Future<RankPreference> putRankPreference({
    required String passportId,
    required bool summaryFirst,
    required String idempotencyKey,
  });

  Future<FanSearchAgentConfig> getSearchAgentConfig(String passportId);

  Future<FanSearchAgentConfig> putSearchAgentConfig({
    required String passportId,
    required AiSearchProvider provider,
    required String mcpEndpoint,
    required bool connected,
    required bool preferCreators,
    required bool externalSourcesEnabled,
    required String idempotencyKey,
  });

  Future<List<ExternalSourceConnection>> getExternalSourceConnections(
    String passportId,
  );

  Future<ExternalSourceConnection> putExternalSourceConnection({
    required String passportId,
    required ExternalSourceType sourceType,
    required bool connected,
    required String displayName,
    required String idempotencyKey,
  });
}
