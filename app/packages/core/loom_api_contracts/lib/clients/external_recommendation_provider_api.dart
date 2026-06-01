import '../models/external_recommendation_provider/external_candidate.dart';

abstract class ExternalRecommendationProviderApi {
  Future<List<ExternalRecommendationCandidate>> getCandidates({
    required String sessionIntentId,
    required List<String> interestIds,
    int limit = 8,
  });
}
