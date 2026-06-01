import '../models/fan_vault/ad_preferences.dart';
import '../models/fan_vault/interest_profile.dart';
import '../models/fan_vault/interest_token.dart';
import '../models/fan_vault/ranking_preference.dart';

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

  Future<RankPreference> getRankPreference(String passportId);

  Future<RankPreference> putRankPreference({
    required String passportId,
    required bool summaryFirst,
    required String idempotencyKey,
  });
}
