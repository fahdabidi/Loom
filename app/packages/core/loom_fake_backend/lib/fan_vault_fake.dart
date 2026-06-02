import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        DemoLocalStore,
        ExternalSourceConnectionRecord,
        FanSearchAgentConfigRecord,
        InterestProfileRecord,
        InterestTokenRecord,
        RankPreferenceRecord;

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

  @override
  Future<AdPreferences> putAdPreferences({
    required String passportId,
    required bool personalizedAds,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.putAdPreferences(
      passportId: passportId,
      personalizedAds: personalizedAds,
      idempotencyKey: idempotencyKey,
    );
    return AdPreferences(
      passportId: record.passportId,
      personalizedAds: record.personalizedAds,
      updatedAt: record.updatedAt,
    );
  }

  @override
  Future<RankPreference> getRankPreference(String passportId) async {
    await Future<void>.delayed(latency);
    return _mapRankPreference(await _store.rankingPreference(passportId));
  }

  @override
  Future<RankPreference> putRankPreference({
    required String passportId,
    required bool summaryFirst,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapRankPreference(
      await _store.putRankingPreference(
        passportId: passportId,
        summaryFirst: summaryFirst,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<FanSearchAgentConfig> getSearchAgentConfig(String passportId) async {
    await Future<void>.delayed(latency);
    return _mapSearchAgentConfig(await _store.searchAgentConfig(passportId));
  }

  @override
  Future<FanSearchAgentConfig> putSearchAgentConfig({
    required String passportId,
    required AiSearchProvider provider,
    required String mcpEndpoint,
    required bool connected,
    required bool preferCreators,
    required bool externalSourcesEnabled,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapSearchAgentConfig(
      await _store.putSearchAgentConfig(
        passportId: passportId,
        provider: _providerName(provider),
        mcpEndpoint: mcpEndpoint,
        connected: connected,
        preferCreators: preferCreators,
        externalSourcesEnabled: externalSourcesEnabled,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<List<ExternalSourceConnection>> getExternalSourceConnections(
    String passportId,
  ) async {
    await Future<void>.delayed(latency);
    final records = await _store.externalSourceConnections(passportId);
    return records.map(_mapExternalSourceConnection).toList(growable: false);
  }

  @override
  Future<ExternalSourceConnection> putExternalSourceConnection({
    required String passportId,
    required ExternalSourceType sourceType,
    required bool connected,
    required String displayName,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapExternalSourceConnection(
      await _store.putExternalSourceConnection(
        passportId: passportId,
        sourceType: _sourceTypeName(sourceType),
        connected: connected,
        displayName: displayName,
        idempotencyKey: idempotencyKey,
      ),
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

RankPreference _mapRankPreference(RankPreferenceRecord record) {
  return RankPreference(
    passportId: record.passportId,
    summaryFirst: record.summaryFirst,
    updatedAt: record.updatedAt,
  );
}

FanSearchAgentConfig _mapSearchAgentConfig(FanSearchAgentConfigRecord record) {
  return FanSearchAgentConfig(
    passportId: record.passportId,
    provider: _provider(record.provider),
    mcpEndpoint: record.mcpEndpoint,
    connected: record.connected,
    preferCreators: record.preferCreators,
    externalSourcesEnabled: record.externalSourcesEnabled,
    updatedAt: record.updatedAt,
  );
}

ExternalSourceConnection _mapExternalSourceConnection(
  ExternalSourceConnectionRecord record,
) {
  return ExternalSourceConnection(
    passportId: record.passportId,
    sourceType: _sourceType(record.sourceType),
    connected: record.connected,
    displayName: record.displayName,
    updatedAt: record.updatedAt,
  );
}

String _providerName(AiSearchProvider provider) {
  switch (provider) {
    case AiSearchProvider.anthropicClaude:
      return 'anthropic_claude';
    case AiSearchProvider.openAi:
      return 'open_ai';
    case AiSearchProvider.googleGemini:
      return 'google_gemini';
    case AiSearchProvider.custom:
      return 'custom';
  }
}

AiSearchProvider _provider(String value) {
  switch (value) {
    case 'open_ai':
      return AiSearchProvider.openAi;
    case 'google_gemini':
      return AiSearchProvider.googleGemini;
    case 'custom':
      return AiSearchProvider.custom;
  }
  return AiSearchProvider.anthropicClaude;
}

String _sourceTypeName(ExternalSourceType sourceType) {
  switch (sourceType) {
    case ExternalSourceType.youtube:
      return 'youtube';
    case ExternalSourceType.twitch:
      return 'twitch';
    case ExternalSourceType.discord:
      return 'discord';
    case ExternalSourceType.blog:
      return 'blog';
    case ExternalSourceType.webpage:
      return 'webpage';
  }
}

ExternalSourceType _sourceType(String value) {
  switch (value) {
    case 'twitch':
      return ExternalSourceType.twitch;
    case 'discord':
      return ExternalSourceType.discord;
    case 'blog':
      return ExternalSourceType.blog;
    case 'webpage':
      return ExternalSourceType.webpage;
  }
  return ExternalSourceType.youtube;
}
