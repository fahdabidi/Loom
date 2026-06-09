enum CommunityPaymentKind { dues, donation, adOff, reservation }

enum CommunityAdDecisionStatus { fill, noFill }

enum CommunityFraudSignalSeverity { watch, hold, adjustment }

class CommunityPaymentRecord {
  const CommunityPaymentRecord({
    required this.paymentId,
    required this.communityId,
    required this.passportId,
    required this.kind,
    required this.amountCents,
    required this.receiptId,
    required this.version,
  });

  final String paymentId;
  final String communityId;
  final String passportId;
  final CommunityPaymentKind kind;
  final int amountCents;
  final String receiptId;
  final int version;
}

class CommunityAdOffEntitlement {
  const CommunityAdOffEntitlement({
    required this.entitlementId,
    required this.scopeId,
    required this.passportId,
    required this.active,
    required this.receiptId,
  });

  final String entitlementId;
  final String scopeId;
  final String passportId;
  final bool active;
  final String receiptId;
}

class CommunityAdCampaign {
  const CommunityAdCampaign({
    required this.campaignId,
    required this.communityId,
    required this.sponsorName,
    required this.slot,
    required this.active,
    required this.version,
  });

  final String campaignId;
  final String communityId;
  final String sponsorName;
  final String slot;
  final bool active;
  final int version;
}

class CommunityAdDecision {
  const CommunityAdDecision({
    required this.decisionId,
    required this.slot,
    required this.status,
    required this.campaignId,
    required this.reason,
  });

  final String decisionId;
  final String slot;
  final CommunityAdDecisionStatus status;
  final String? campaignId;
  final String reason;
}

class CommunitySearchRecord {
  const CommunitySearchRecord({
    required this.recordId,
    required this.communityId,
    required this.title,
    required this.body,
    required this.visibility,
    required this.sourceComponent,
  });

  final String recordId;
  final String communityId;
  final String title;
  final String body;
  final String visibility;
  final String sourceComponent;
}

class CommunitySearchHit {
  const CommunitySearchHit({
    required this.recordId,
    required this.title,
    required this.explanation,
  });

  final String recordId;
  final String title;
  final String explanation;
}

class CommunityAiAnswer {
  const CommunityAiAnswer({
    required this.answerId,
    required this.answer,
    required this.citationRecordIds,
    required this.sourcePolicy,
  });

  final String answerId;
  final String answer;
  final List<String> citationRecordIds;
  final String sourcePolicy;
}

class CommunityDigest {
  const CommunityDigest({
    required this.digestId,
    required this.communityId,
    required this.summary,
    required this.citationRecordIds,
  });

  final String digestId;
  final String communityId;
  final String summary;
  final List<String> citationRecordIds;
}

class CommunitySettlementRun {
  const CommunitySettlementRun({
    required this.settlementId,
    required this.communityId,
    required this.grossCents,
    required this.adjustmentCents,
    required this.netCents,
    required this.receiptIds,
  });

  final String settlementId;
  final String communityId;
  final int grossCents;
  final int adjustmentCents;
  final int netCents;
  final List<String> receiptIds;
}

class CommunityUtilityFundingAllocation {
  const CommunityUtilityFundingAllocation({
    required this.allocationId,
    required this.settlementId,
    required this.utilityCents,
    required this.ownerCents,
  });

  final String allocationId;
  final String settlementId;
  final int utilityCents;
  final int ownerCents;
}

class CommunityFraudSignal {
  const CommunityFraudSignal({
    required this.signalId,
    required this.communityId,
    required this.subjectId,
    required this.severity,
    required this.adjustmentCents,
  });

  final String signalId;
  final String communityId;
  final String subjectId;
  final CommunityFraudSignalSeverity severity;
  final int adjustmentCents;
}

abstract class CommunityWalletApi {
  Future<CommunityPaymentRecord> recordPayment({
    required String communityId,
    required String passportId,
    required CommunityPaymentKind kind,
    required int amountCents,
    required String idempotencyKey,
  });

  Future<CommunityAdOffEntitlement> purchaseAdOff({
    required String scopeId,
    required String passportId,
    required int amountCents,
    required String idempotencyKey,
  });

  Future<bool> hasAdOff({
    required String scopeId,
    required String passportId,
  });
}

abstract class CommunityAdCampaignApi {
  Future<CommunityAdCampaign> createCampaign({
    required String communityId,
    required String sponsorName,
    required String slot,
    required String idempotencyKey,
  });

  Future<List<CommunityAdCampaign>> activeCampaigns({
    required String communityId,
    required String slot,
  });
}

abstract class CommunityAdDecisionApi {
  Future<CommunityAdDecision> decide({
    required String communityId,
    required String passportId,
    required String slot,
    required bool sensitiveContext,
    required String idempotencyKey,
  });
}

abstract class CommunityIndexingApi {
  Future<CommunitySearchRecord> indexRecord({
    required String communityId,
    required String title,
    required String body,
    required String visibility,
    required String sourceComponent,
    required String idempotencyKey,
  });

  Future<void> removeRecord(String recordId);
}

abstract class CommunitySearchApi {
  Future<List<CommunitySearchHit>> search({
    required String communityId,
    required String query,
    required String actorPassportId,
    required bool includeRestricted,
  });
}

abstract class CommunityAiGatewayApi {
  Future<CommunityAiAnswer> answerQuestion({
    required String communityId,
    required String question,
    required String actorPassportId,
    required String idempotencyKey,
  });
}

abstract class CommunityDigestApi {
  Future<CommunityDigest> createDigest({
    required String communityId,
    required CommunityAiAnswer answer,
    required String idempotencyKey,
  });
}

abstract class CommunitySettlementApi {
  Future<CommunitySettlementRun> runSettlement({
    required String communityId,
    required String passportId,
    required int adjustmentCents,
    required String idempotencyKey,
  });
}

abstract class CommunityUtilityFundingApi {
  Future<CommunityUtilityFundingAllocation> calculate({
    required CommunitySettlementRun settlement,
    required int basisPoints,
    required String idempotencyKey,
  });
}

abstract class CommunityFraudApi {
  Future<CommunityFraudSignal> createSignal({
    required String communityId,
    required String subjectId,
    required CommunityFraudSignalSeverity severity,
    required int adjustmentCents,
    required String idempotencyKey,
  });
}
