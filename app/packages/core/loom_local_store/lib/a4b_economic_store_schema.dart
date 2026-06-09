class A4bOwnedTable {
  const A4bOwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A4bEconomicStoreSchema {
  static const tables = [
    A4bOwnedTable(
      componentId: 'wallet-dues-donations',
      tableName: 'community_payments',
      ownedFields: ['paymentId', 'communityId', 'passportId', 'receiptId'],
    ),
    A4bOwnedTable(
      componentId: 'ad-campaign-service',
      tableName: 'community_ad_campaigns',
      ownedFields: ['campaignId', 'communityId', 'sponsorName', 'slot'],
    ),
    A4bOwnedTable(
      componentId: 'ad-decision-service',
      tableName: 'community_ad_decisions',
      ownedFields: ['decisionId', 'slot', 'status', 'reason'],
    ),
    A4bOwnedTable(
      componentId: 'indexing-service',
      tableName: 'community_search_index',
      ownedFields: ['recordId', 'communityId', 'visibility', 'sourceComponent'],
    ),
    A4bOwnedTable(
      componentId: 'search-service',
      tableName: 'community_search_queries',
      ownedFields: ['queryId', 'communityId', 'query', 'explanation'],
    ),
    A4bOwnedTable(
      componentId: 'ai-gateway',
      tableName: 'community_ai_answers',
      ownedFields: ['answerId', 'sourcePolicy', 'citationRecordIds'],
    ),
    A4bOwnedTable(
      componentId: 'digest-service',
      tableName: 'community_digests',
      ownedFields: ['digestId', 'communityId', 'summary', 'citationRecordIds'],
    ),
    A4bOwnedTable(
      componentId: 'settlement-engine',
      tableName: 'community_settlements',
      ownedFields: ['settlementId', 'grossCents', 'adjustmentCents', 'netCents'],
    ),
    A4bOwnedTable(
      componentId: 'utility-funding-service',
      tableName: 'community_utility_allocations',
      ownedFields: ['allocationId', 'settlementId', 'utilityCents'],
    ),
    A4bOwnedTable(
      componentId: 'fraud-signal-service',
      tableName: 'community_fraud_signals',
      ownedFields: ['signalId', 'communityId', 'subjectId', 'severity'],
    ),
  ];

  const A4bEconomicStoreSchema._();
}
