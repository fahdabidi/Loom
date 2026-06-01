import '../recommendation_referral/discovery_models.dart';

class SearchResult {
  const SearchResult({
    required this.tile,
    required this.matchedTerms,
    required this.neutralityLabel,
  });

  final ContentTile tile;
  final List<String> matchedTerms;
  final String neutralityLabel;
}
