import '../fan_vault/ranking_preference.dart';
import '../receipt/receipt_models.dart';
import '../recommendation_referral/discovery_models.dart';

class Citation {
  const Citation({
    required this.contentId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.segment,
    required this.startLabel,
    required this.royaltyBasis,
  });

  final String contentId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String segment;
  final String startLabel;
  final String royaltyBasis;
}

class ArchiveAnswer {
  const ArchiveAnswer({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.question,
    required this.answer,
    required this.confidenceLabel,
    required this.citations,
    required this.receipts,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String question;
  final String answer;
  final String confidenceLabel;
  final List<Citation> citations;
  final List<ReceiptView> receipts;
  final DateTime createdAt;
}

class SummaryRankResult {
  const SummaryRankResult({
    required this.preference,
    required this.items,
    required this.candidateCount,
  });

  final RankPreference preference;
  final List<FeedItem> items;
  final int candidateCount;
}
