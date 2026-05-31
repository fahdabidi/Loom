import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, InterestProfileRecord, InterestTokenRecord;

/// Implements [FanVaultApi] over [DemoLocalStore].
///
/// Seed tables used: `interest_taxonomy`; writes `fan_interest_profiles`
/// and `ad_preferences`.
class FanVaultFake implements FanVaultApi {
  const FanVaultFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<InterestToken>> getInterestTaxonomy() async {
    await Future<void>.delayed(latency);
    final records = await _store.interestTaxonomy();
    return records.map(_mapToken).toList(growable: false);
  }

  @override
  Future<InterestProfile> getInterestProfile(String passportId) async {
    await Future<void>.delayed(latency);
    return _mapProfile(await _store.interestProfile(passportId));
  }

  @override
  Future<InterestProfile> putInterests({
    required String passportId,
    required List<String> interestIds,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapProfile(
      await _store.putInterests(
        passportId: passportId,
        interestIds: interestIds,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<InterestProfile> putDislikes({
    required String passportId,
    required List<String> dislikedInterestIds,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapProfile(
      await _store.putDislikes(
        passportId: passportId,
        dislikedInterestIds: dislikedInterestIds,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<AdPreferences> getAdPreferences(String passportId) async {
    await Future<void>.delayed(latency);
    final record = await _store.adPreferences(passportId);
    return AdPreferences(
      passportId: record.passportId,
      personalizedAds: record.personalizedAds,
      updatedAt: record.updatedAt,
    );
  }
}

InterestToken _mapToken(InterestTokenRecord record) {
  return InterestToken(
    id: record.id,
    label: record.label,
    category: record.category,
  );
}

InterestProfile _mapProfile(InterestProfileRecord record) {
  return InterestProfile(
    passportId: record.passportId,
    interests: record.interests.map(_mapToken).toList(growable: false),
    dislikedInterestIds: record.dislikedInterestIds,
    dislikedCreatorIds: record.dislikedCreatorIds,
    mutedProviderIds: record.mutedProviderIds,
    updatedAt: record.updatedAt,
  );
}
