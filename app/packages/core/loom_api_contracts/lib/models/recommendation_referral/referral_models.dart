class RecommendationManifest {
  const RecommendationManifest({
    required this.id,
    required this.sourceCreatorId,
    required this.sourceCreatorName,
    required this.destinationCreatorId,
    required this.destinationCreatorName,
    required this.contentId,
    required this.title,
    required this.note,
    required this.disclosureLabel,
    required this.version,
    required this.publishedAt,
  });

  final String id;
  final String sourceCreatorId;
  final String sourceCreatorName;
  final String destinationCreatorId;
  final String destinationCreatorName;
  final String contentId;
  final String title;
  final String note;
  final String disclosureLabel;
  final int version;
  final DateTime publishedAt;
}

class ReferralTerms {
  const ReferralTerms({
    required this.id,
    required this.sourceCreatorId,
    required this.destinationCreatorId,
    required this.windowDays,
    required this.capCents,
    required this.rewardCents,
    required this.version,
    required this.publishedAt,
  });

  final String id;
  final String sourceCreatorId;
  final String destinationCreatorId;
  final int windowDays;
  final int capCents;
  final int rewardCents;
  final int version;
  final DateTime publishedAt;
}

class DiscoveryReceipt {
  const DiscoveryReceipt({
    required this.id,
    required this.manifestId,
    required this.passportId,
    required this.sourceCreatorId,
    required this.destinationCreatorId,
    required this.contentId,
    required this.disclosure,
    required this.createdAt,
  });

  final String id;
  final String manifestId;
  final String passportId;
  final String sourceCreatorId;
  final String destinationCreatorId;
  final String contentId;
  final String disclosure;
  final DateTime createdAt;
}

class CreatorReferralReceipt {
  const CreatorReferralReceipt({
    required this.id,
    required this.termsId,
    required this.discoveryReceiptId,
    required this.passportId,
    required this.sourceCreatorId,
    required this.destinationCreatorId,
    required this.amountCents,
    required this.createdAt,
  });

  final String id;
  final String termsId;
  final String discoveryReceiptId;
  final String passportId;
  final String sourceCreatorId;
  final String destinationCreatorId;
  final int amountCents;
  final DateTime createdAt;
}
