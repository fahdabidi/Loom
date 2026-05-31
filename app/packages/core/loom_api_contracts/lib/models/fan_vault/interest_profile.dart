import 'interest_token.dart';

class InterestProfile {
  const InterestProfile({
    required this.passportId,
    required this.interests,
    required this.dislikedInterestIds,
    required this.dislikedCreatorIds,
    required this.mutedProviderIds,
    required this.updatedAt,
  });

  final String passportId;
  final List<InterestToken> interests;
  final List<String> dislikedInterestIds;
  final List<String> dislikedCreatorIds;
  final List<String> mutedProviderIds;
  final DateTime updatedAt;
}
