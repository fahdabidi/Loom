import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'community_foundation_fake.dart';

class CommunityEconomicServicesFakeBackend {
  CommunityEconomicServicesFakeBackend({
    required this.foundation,
  }) {
    wallet = CommunityWalletFake(foundation.receiptLedger);
    adCampaigns = CommunityAdCampaignFake();
    adDecisions = CommunityAdDecisionFake(wallet, adCampaigns);
    final searchIndex = CommunitySearchIndexStore();
    indexing = CommunityIndexingFake(searchIndex);
    search = CommunitySearchFake(searchIndex, foundation.rolePolicy);
    aiGateway = CommunityAiGatewayFake(search);
    digest = CommunityDigestFake();
    settlement = CommunitySettlementFake(foundation.receiptLedger);
    utilityFunding = CommunityUtilityFundingFake();
    fraud = CommunityFraudFake();
  }

  final CommunityFoundationFakeBackend foundation;

  late final CommunityWalletFake wallet;
  late final CommunityAdCampaignFake adCampaigns;
  late final CommunityAdDecisionFake adDecisions;
  late final CommunityIndexingFake indexing;
  late final CommunitySearchFake search;
  late final CommunityAiGatewayFake aiGateway;
  late final CommunityDigestFake digest;
  late final CommunitySettlementFake settlement;
  late final CommunityUtilityFundingFake utilityFunding;
  late final CommunityFraudFake fraud;
}

class CommunityWalletFake implements CommunityWalletApi {
  CommunityWalletFake(this._receipts);

  final CommunityReceiptLedgerApi _receipts;
  final Map<String, CommunityPaymentRecord> _paymentsByIdempotency = {};
  final Map<String, CommunityAdOffEntitlement> _adOffByIdempotency = {};
  final Map<String, CommunityAdOffEntitlement> _adOffByScopeAndPassport = {};

  @override
  Future<CommunityPaymentRecord> recordPayment({
    required String communityId,
    required String passportId,
    required CommunityPaymentKind kind,
    required int amountCents,
    required String idempotencyKey,
  }) async {
    final existing = _paymentsByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final receipt = await _receipts.appendReceipt(
      passportId: passportId,
      kind: kind.name,
      amountCents: amountCents,
      currency: 'USD',
      summary: '$kind payment for $communityId',
      idempotencyKey: 'receipt_$idempotencyKey',
    );
    final payment = CommunityPaymentRecord(
      paymentId: 'payment_${_paymentsByIdempotency.length + 1}',
      communityId: communityId,
      passportId: passportId,
      kind: kind,
      amountCents: amountCents,
      receiptId: receipt.receiptId,
      version: 1,
    );
    _paymentsByIdempotency[idempotencyKey] = payment;
    return payment;
  }

  @override
  Future<CommunityAdOffEntitlement> purchaseAdOff({
    required String scopeId,
    required String passportId,
    required int amountCents,
    required String idempotencyKey,
  }) async {
    final existing = _adOffByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final payment = await recordPayment(
      communityId: scopeId,
      passportId: passportId,
      kind: CommunityPaymentKind.adOff,
      amountCents: amountCents,
      idempotencyKey: 'payment_$idempotencyKey',
    );
    final entitlement = CommunityAdOffEntitlement(
      entitlementId: 'ad_off_${_adOffByIdempotency.length + 1}',
      scopeId: scopeId,
      passportId: passportId,
      active: true,
      receiptId: payment.receiptId,
    );
    _adOffByIdempotency[idempotencyKey] = entitlement;
    _adOffByScopeAndPassport[_key(scopeId, passportId)] = entitlement;
    return entitlement;
  }

  @override
  Future<bool> hasAdOff({
    required String scopeId,
    required String passportId,
  }) async {
    return _adOffByScopeAndPassport[_key(scopeId, passportId)]?.active ??
        false;
  }

  String _key(String scopeId, String passportId) {
    return '$scopeId::$passportId';
  }
}

class CommunityAdCampaignFake implements CommunityAdCampaignApi {
  final Map<String, CommunityAdCampaign> _campaignsByIdempotency = {};
  final List<CommunityAdCampaign> _campaigns = [];

  @override
  Future<CommunityAdCampaign> createCampaign({
    required String communityId,
    required String sponsorName,
    required String slot,
    required String idempotencyKey,
  }) async {
    final existing = _campaignsByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final campaign = CommunityAdCampaign(
      campaignId: 'campaign_${_campaigns.length + 1}',
      communityId: communityId,
      sponsorName: sponsorName,
      slot: slot,
      active: true,
      version: 1,
    );
    _campaigns.add(campaign);
    _campaignsByIdempotency[idempotencyKey] = campaign;
    return campaign;
  }

  @override
  Future<List<CommunityAdCampaign>> activeCampaigns({
    required String communityId,
    required String slot,
  }) async {
    return _campaigns
        .where(
          (campaign) =>
              campaign.communityId == communityId &&
              campaign.slot == slot &&
              campaign.active,
        )
        .toList(growable: false);
  }
}

class CommunityAdDecisionFake implements CommunityAdDecisionApi {
  CommunityAdDecisionFake(this._wallet, this._campaigns);

  final CommunityWalletApi _wallet;
  final CommunityAdCampaignApi _campaigns;
  final Map<String, CommunityAdDecision> _byIdempotency = {};

  @override
  Future<CommunityAdDecision> decide({
    required String communityId,
    required String passportId,
    required String slot,
    required bool sensitiveContext,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final adOff = await _wallet.hasAdOff(
      scopeId: communityId,
      passportId: passportId,
    );
    final decision = await _makeDecision(
      communityId: communityId,
      slot: slot,
      sensitiveContext: sensitiveContext,
      adOff: adOff,
    );
    _byIdempotency[idempotencyKey] = decision;
    return decision;
  }

  Future<CommunityAdDecision> _makeDecision({
    required String communityId,
    required String slot,
    required bool sensitiveContext,
    required bool adOff,
  }) async {
    if (sensitiveContext) {
      return CommunityAdDecision(
        decisionId: 'ad_decision_${_byIdempotency.length + 1}',
        slot: slot,
        status: CommunityAdDecisionStatus.noFill,
        campaignId: null,
        reason: 'sensitive-context',
      );
    }
    if (adOff) {
      return CommunityAdDecision(
        decisionId: 'ad_decision_${_byIdempotency.length + 1}',
        slot: slot,
        status: CommunityAdDecisionStatus.noFill,
        campaignId: null,
        reason: 'ad-off-entitlement',
      );
    }
    final campaigns = await _campaigns.activeCampaigns(
      communityId: communityId,
      slot: slot,
    );
    if (campaigns.isEmpty) {
      return CommunityAdDecision(
        decisionId: 'ad_decision_${_byIdempotency.length + 1}',
        slot: slot,
        status: CommunityAdDecisionStatus.noFill,
        campaignId: null,
        reason: 'no-campaign',
      );
    }
    return CommunityAdDecision(
      decisionId: 'ad_decision_${_byIdempotency.length + 1}',
      slot: slot,
      status: CommunityAdDecisionStatus.fill,
      campaignId: campaigns.first.campaignId,
      reason: 'eligible',
    );
  }
}

class CommunitySearchIndexStore {
  final Map<String, CommunitySearchRecord> records = {};
}

class CommunityIndexingFake implements CommunityIndexingApi {
  CommunityIndexingFake(this._store);

  final CommunitySearchIndexStore _store;
  final Map<String, CommunitySearchRecord> _byIdempotency = {};

  @override
  Future<CommunitySearchRecord> indexRecord({
    required String communityId,
    required String title,
    required String body,
    required String visibility,
    required String sourceComponent,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final record = CommunitySearchRecord(
      recordId: 'search_${_store.records.length + 1}',
      communityId: communityId,
      title: title,
      body: body,
      visibility: visibility,
      sourceComponent: sourceComponent,
    );
    _store.records[record.recordId] = record;
    _byIdempotency[idempotencyKey] = record;
    return record;
  }

  @override
  Future<void> removeRecord(String recordId) async {
    _store.records.remove(recordId);
  }
}

class CommunitySearchFake implements CommunitySearchApi {
  CommunitySearchFake(this._store, this._policy);

  final CommunitySearchIndexStore _store;
  final CommunityRolePolicyApi _policy;

  @override
  Future<List<CommunitySearchHit>> search({
    required String communityId,
    required String query,
    required String actorPassportId,
    required bool includeRestricted,
  }) async {
    final restrictedRead = await _policy.effectivePermission(
      actorId: actorPassportId,
      communityId: communityId,
      permission: 'search.restricted.read',
    );
    final normalized = query.toLowerCase();
    return _store.records.values.where((record) {
      final matchesCommunity = record.communityId == communityId;
      final matchesQuery =
          record.title.toLowerCase().contains(normalized) ||
          record.body.toLowerCase().contains(normalized);
      final visible =
          record.visibility != 'restricted' ||
          (includeRestricted && restrictedRead.allowed);
      return matchesCommunity && matchesQuery && visible;
    }).map((record) {
      return CommunitySearchHit(
        recordId: record.recordId,
        title: record.title,
        explanation: 'matched ${record.sourceComponent}',
      );
    }).toList(growable: false);
  }
}

class CommunityAiGatewayFake implements CommunityAiGatewayApi {
  CommunityAiGatewayFake(this._search);

  final CommunitySearchApi _search;
  final Map<String, CommunityAiAnswer> _byIdempotency = {};

  @override
  Future<CommunityAiAnswer> answerQuestion({
    required String communityId,
    required String question,
    required String actorPassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final hits = await _search.search(
      communityId: communityId,
      query: question,
      actorPassportId: actorPassportId,
      includeRestricted: false,
    );
    final answer = CommunityAiAnswer(
      answerId: 'answer_${_byIdempotency.length + 1}',
      answer: hits.isEmpty
          ? 'No matching community source found.'
          : 'Based on ${hits.first.title}.',
      citationRecordIds: hits.map((hit) => hit.recordId).toList(growable: false),
      sourcePolicy: 'permission-aware-search-only',
    );
    _byIdempotency[idempotencyKey] = answer;
    return answer;
  }
}

class CommunityDigestFake implements CommunityDigestApi {
  final Map<String, CommunityDigest> _byIdempotency = {};

  @override
  Future<CommunityDigest> createDigest({
    required String communityId,
    required CommunityAiAnswer answer,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final digest = CommunityDigest(
      digestId: 'digest_${_byIdempotency.length + 1}',
      communityId: communityId,
      summary: answer.answer,
      citationRecordIds: answer.citationRecordIds,
    );
    _byIdempotency[idempotencyKey] = digest;
    return digest;
  }
}

class CommunitySettlementFake implements CommunitySettlementApi {
  CommunitySettlementFake(this._receipts);

  final CommunityReceiptLedgerApi _receipts;
  final Map<String, CommunitySettlementRun> _byIdempotency = {};

  @override
  Future<CommunitySettlementRun> runSettlement({
    required String communityId,
    required String passportId,
    required int adjustmentCents,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final receipts = await _receipts.listReceipts(passportId);
    final gross = receipts.fold<int>(
      0,
      (total, receipt) => total + receipt.amountCents,
    );
    final settlement = CommunitySettlementRun(
      settlementId: 'settlement_${_byIdempotency.length + 1}',
      communityId: communityId,
      grossCents: gross,
      adjustmentCents: adjustmentCents,
      netCents: gross + adjustmentCents,
      receiptIds: receipts.map((receipt) => receipt.receiptId).toList(
        growable: false,
      ),
    );
    _byIdempotency[idempotencyKey] = settlement;
    return settlement;
  }
}

class CommunityUtilityFundingFake implements CommunityUtilityFundingApi {
  final Map<String, CommunityUtilityFundingAllocation> _byIdempotency = {};

  @override
  Future<CommunityUtilityFundingAllocation> calculate({
    required CommunitySettlementRun settlement,
    required int basisPoints,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final utilityCents = settlement.netCents * basisPoints ~/ 10000;
    final allocation = CommunityUtilityFundingAllocation(
      allocationId: 'utility_${_byIdempotency.length + 1}',
      settlementId: settlement.settlementId,
      utilityCents: utilityCents,
      ownerCents: settlement.netCents - utilityCents,
    );
    _byIdempotency[idempotencyKey] = allocation;
    return allocation;
  }
}

class CommunityFraudFake implements CommunityFraudApi {
  final Map<String, CommunityFraudSignal> _byIdempotency = {};

  @override
  Future<CommunityFraudSignal> createSignal({
    required String communityId,
    required String subjectId,
    required CommunityFraudSignalSeverity severity,
    required int adjustmentCents,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final signal = CommunityFraudSignal(
      signalId: 'fraud_${_byIdempotency.length + 1}',
      communityId: communityId,
      subjectId: subjectId,
      severity: severity,
      adjustmentCents: adjustmentCents,
    );
    _byIdempotency[idempotencyKey] = signal;
    return signal;
  }
}
