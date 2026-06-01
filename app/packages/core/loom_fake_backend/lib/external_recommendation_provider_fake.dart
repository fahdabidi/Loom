import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, ExternalProviderCandidateRecord;

class ExternalRecommendationProviderFake
    implements ExternalRecommendationProviderApi {
  const ExternalRecommendationProviderFake(
    this._store, {
    this.latency = const Duration(milliseconds: 80),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<ExternalRecommendationCandidate>> getCandidates({
    required String sessionIntentId,
    required List<String> interestIds,
    int limit = 8,
  }) async {
    await Future<void>.delayed(latency);
    final candidates = await _store.externalCandidates(
      interestIds: interestIds,
      limit: limit,
    );
    return candidates.map(_mapCandidate).toList(growable: false);
  }
}

ExternalRecommendationCandidate _mapCandidate(
  ExternalProviderCandidateRecord record,
) {
  return ExternalRecommendationCandidate(
    providerId: record.providerId,
    providerLabel: record.providerLabel,
    contentId: record.contentId,
    interestIds: record.interestIds,
    score: record.score,
    reason: record.reason,
  );
}
