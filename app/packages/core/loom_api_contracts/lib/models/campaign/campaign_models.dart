class Campaign {
  const Campaign({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.description,
    required this.rewardLabel,
    required this.entryCount,
    required this.createdAt,
    required this.endsAt,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String description;
  final String rewardLabel;
  final int entryCount;
  final DateTime createdAt;
  final DateTime endsAt;
}

class CampaignEntry {
  const CampaignEntry({
    required this.id,
    required this.campaignId,
    required this.passportId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String campaignId;
  final String passportId;
  final String status;
  final DateTime createdAt;
}

class Reward {
  const Reward({
    required this.id,
    required this.campaignId,
    required this.entryId,
    required this.passportId,
    required this.label,
    required this.status,
    required this.issuedAt,
  });

  final String id;
  final String campaignId;
  final String entryId;
  final String passportId;
  final String label;
  final String status;
  final DateTime issuedAt;
}

class SponsorProposal {
  const SponsorProposal({
    required this.id,
    required this.sponsorName,
    required this.creatorId,
    required this.campaignId,
    required this.title,
    required this.valueExchange,
    required this.createdAt,
  });

  final String id;
  final String sponsorName;
  final String creatorId;
  final String campaignId;
  final String title;
  final String valueExchange;
  final DateTime createdAt;
}

class FanDataGrantOffer {
  const FanDataGrantOffer({
    required this.id,
    required this.proposalId,
    required this.campaignId,
    required this.creatorId,
    required this.sponsorName,
    required this.fields,
    required this.purpose,
    required this.valueExchange,
    required this.createdAt,
  });

  final String id;
  final String proposalId;
  final String campaignId;
  final String creatorId;
  final String sponsorName;
  final List<String> fields;
  final String purpose;
  final String valueExchange;
  final DateTime createdAt;
}
