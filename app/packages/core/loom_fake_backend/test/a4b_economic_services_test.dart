import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a4b_economic_store_schema.dart';
import 'package:loom_seed_data/community_economic_seed_data.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_ops_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A4b economic/search/ad validation tests', () {
    test('vt_wallet_payment', () async {
      final harness = await _harness();
      final payment = await harness.economic.wallet.recordPayment(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        kind: CommunityPaymentKind.dues,
        amountCents: 5000,
        idempotencyKey: 'wallet-dues',
      );
      final receipts = await harness.foundation.receiptLedger.listReceipts(
        communityFoundationSeed.memberPassportId,
      );

      expect(payment.receiptId, receipts.single.receiptId);
      expect(payment.amountCents, 5000);
    });

    test('vt_wallet_ad-off', () async {
      final harness = await _harness();
      final entitlement = await harness.economic.wallet.purchaseAdOff(
        scopeId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        amountCents: 299,
        idempotencyKey: 'wallet-ad-off',
      );
      final hasAdOff = await harness.economic.wallet.hasAdOff(
        scopeId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
      );

      expect(entitlement.active, isTrue);
      expect(hasAdOff, isTrue);
    });

    test('vt_wallet_community-ad-off', () async {
      final harness = await _harness();
      final entitlement = await harness.economic.wallet.purchaseAdOff(
        scopeId: harness.community.communityId,
        passportId: 'community',
        amountCents: 1999,
        idempotencyKey: 'wallet-community-ad-off',
      );
      final memberHasAdOff = await harness.economic.wallet.hasAdOff(
        scopeId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
      );

      expect(entitlement.active, isTrue);
      expect(entitlement.passportId, 'community');
      expect(memberHasAdOff, isTrue);
    });

    test('vt_ad-campaign_setup', () async {
      final harness = await _harness();
      final campaign = await harness.economic.adCampaigns.createCampaign(
        communityId: harness.community.communityId,
        sponsorName: communityEconomicSeed.sponsorName,
        slot: communityEconomicSeed.adSlotTopBanner,
        idempotencyKey: 'campaign-top',
      );
      final active = await harness.economic.adCampaigns.activeCampaigns(
        communityId: harness.community.communityId,
        slot: communityEconomicSeed.adSlotTopBanner,
      );

      expect(campaign.active, isTrue);
      expect(active.single.campaignId, campaign.campaignId);
    });

    test('vt_ad-decision_slot-eligibility', () async {
      final harness = await _harnessWithCampaign();
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotTopBanner,
        sensitiveContext: false,
        idempotencyKey: 'ad-eligible',
      );

      expect(decision.status, CommunityAdDecisionStatus.fill);
      expect(decision.reason, 'eligible');
    });

    test('vt_ad-decision_sensitive-no-fill', () async {
      final harness = await _harnessWithCampaign();
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotTopBanner,
        sensitiveContext: true,
        idempotencyKey: 'ad-sensitive',
      );

      expect(decision.status, CommunityAdDecisionStatus.noFill);
      expect(decision.reason, 'sensitive-context');
    });

    test('vt_ad-decision_ad-off', () async {
      final harness = await _harnessWithCampaign();
      await harness.economic.wallet.purchaseAdOff(
        scopeId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        amountCents: 299,
        idempotencyKey: 'ad-decision-ad-off-entitlement',
      );
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotTopBanner,
        sensitiveContext: false,
        idempotencyKey: 'ad-decision-ad-off',
      );

      expect(decision.status, CommunityAdDecisionStatus.noFill);
      expect(decision.reason, 'ad-off-entitlement');
    });

    test('vt_search_permission-aware', () async {
      final harness = await _harness();
      await harness.economic.indexing.indexRecord(
        communityId: harness.community.communityId,
        title: communityEconomicSeed.searchTitle,
        body: communityEconomicSeed.searchBody,
        visibility: 'restricted',
        sourceComponent: 'documents-service',
        idempotencyKey: 'index-restricted',
      );
      final hidden = await harness.economic.search.search(
        communityId: harness.community.communityId,
        query: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: true,
      );
      await harness.foundation.rolePolicy.grantPermission(
        actorId: communityFoundationSeed.memberPassportId,
        communityId: harness.community.communityId,
        permission: 'search.restricted.read',
        grantedBy: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'grant-search-restricted',
      );
      final visible = await harness.economic.search.search(
        communityId: harness.community.communityId,
        query: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: true,
      );

      expect(hidden, isEmpty);
      expect(visible.single.explanation, contains('documents-service'));
      expect(
        A4bEconomicStoreSchema.tables.map((table) => table.componentId),
        contains('search-service'),
      );
    });

    test('vt_search_deindex', () async {
      final harness = await _harness();
      final record = await harness.economic.indexing.indexRecord(
        communityId: harness.community.communityId,
        title: 'Old policy',
        body: 'This should be removed.',
        visibility: 'public',
        sourceComponent: 'documents-service',
        idempotencyKey: 'index-old',
      );
      await harness.economic.indexing.removeRecord(record.recordId);
      final results = await harness.economic.search.search(
        communityId: harness.community.communityId,
        query: 'policy',
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: false,
      );

      expect(results, isEmpty);
    });

    test('vt_ai-gateway_answer', () async {
      final harness = await _harnessWithSearchRecord();
      final answer = await harness.economic.aiGateway.answerQuestion(
        communityId: harness.community.communityId,
        question: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'ai-answer',
      );

      expect(answer.answer, contains(communityEconomicSeed.searchTitle));
      expect(answer.citationRecordIds, isNotEmpty);
    });

    test('vt_ai-gateway_source-policy', () async {
      final harness = await _harnessWithSearchRecord();
      final answer = await harness.economic.aiGateway.answerQuestion(
        communityId: harness.community.communityId,
        question: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'ai-policy',
      );

      expect(answer.sourcePolicy, 'permission-aware-search-only');
    });

    test('vt_digest_on-demand', () async {
      final harness = await _harnessWithSearchRecord();
      final answer = await harness.economic.aiGateway.answerQuestion(
        communityId: harness.community.communityId,
        question: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'digest-answer',
      );
      final digest = await harness.economic.digest.createDigest(
        communityId: harness.community.communityId,
        answer: answer,
        idempotencyKey: 'digest-create',
      );

      expect(digest.summary, answer.answer);
      expect(digest.citationRecordIds, answer.citationRecordIds);
    });

    test('vt_settlement_run', () async {
      final harness = await _harnessWithPayment();
      final settlement = await harness.economic.settlement.runSettlement(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        adjustmentCents: 0,
        idempotencyKey: 'settlement-run',
      );

      expect(settlement.grossCents, 5000);
      expect(settlement.netCents, 5000);
      expect(settlement.receiptIds, isNotEmpty);
    });

    test('vt_utility-funding_calculate', () async {
      final harness = await _harnessWithPayment();
      final settlement = await harness.economic.settlement.runSettlement(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        adjustmentCents: 0,
        idempotencyKey: 'settlement-for-utility',
      );
      final allocation = await harness.economic.utilityFunding.calculate(
        settlement: settlement,
        basisPoints: 1000,
        idempotencyKey: 'utility-calc',
      );

      expect(allocation.utilityCents, 500);
      expect(allocation.ownerCents, 4500);
    });

    test('vt_fraud_create-signal', () async {
      final harness = await _harness();
      final signal = await harness.economic.fraud.createSignal(
        communityId: harness.community.communityId,
        subjectId: 'payment_1',
        severity: CommunityFraudSignalSeverity.hold,
        adjustmentCents: -1000,
        idempotencyKey: 'fraud-signal',
      );

      expect(signal.severity, CommunityFraudSignalSeverity.hold);
      expect(signal.adjustmentCents, -1000);
    });
  });

  group('A4b built-counterpart consumer contract tests', () {
    test('ct_wallet__ad-decision_ad-off-entitlement', () async {
      final harness = await _harnessWithCampaign();
      await harness.economic.wallet.purchaseAdOff(
        scopeId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        amountCents: 299,
        idempotencyKey: 'contract-ad-off',
      );
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotTopBanner,
        sensitiveContext: false,
        idempotencyKey: 'contract-ad-off-decision',
      );

      expect(decision.status, CommunityAdDecisionStatus.noFill);
      expect(decision.reason, 'ad-off-entitlement');
    });

    test('ct_search__ai-gateway_retrieval', () async {
      final harness = await _harnessWithSearchRecord();
      final answer = await harness.economic.aiGateway.answerQuestion(
        communityId: harness.community.communityId,
        question: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'contract-search-ai',
      );

      expect(answer.citationRecordIds, isNotEmpty);
    });

    test('ct_ai-gateway__digest_citations', () async {
      final harness = await _harnessWithSearchRecord();
      final answer = await harness.economic.aiGateway.answerQuestion(
        communityId: harness.community.communityId,
        question: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'contract-ai-digest-answer',
      );
      final digest = await harness.economic.digest.createDigest(
        communityId: harness.community.communityId,
        answer: answer,
        idempotencyKey: 'contract-ai-digest',
      );

      expect(digest.citationRecordIds, answer.citationRecordIds);
    });

    test('ct_receipt-ledger__settlement_read-window', () async {
      final harness = await _harnessWithPayment();
      final settlement = await harness.economic.settlement.runSettlement(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        adjustmentCents: 0,
        idempotencyKey: 'contract-receipt-settlement',
      );

      expect(settlement.receiptIds, isNotEmpty);
      expect(settlement.grossCents, 5000);
    });

    test('ct_settlement__utility-funding_allocation', () async {
      final harness = await _harnessWithPayment();
      final settlement = await harness.economic.settlement.runSettlement(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        adjustmentCents: 0,
        idempotencyKey: 'contract-settlement',
      );
      final allocation = await harness.economic.utilityFunding.calculate(
        settlement: settlement,
        basisPoints: 500,
        idempotencyKey: 'contract-utility',
      );

      expect(allocation.utilityCents, 250);
    });

    test('ct_fraud__settlement_apply-adjustment', () async {
      final harness = await _harnessWithPayment();
      final signal = await harness.economic.fraud.createSignal(
        communityId: harness.community.communityId,
        subjectId: 'payment_1',
        severity: CommunityFraudSignalSeverity.adjustment,
        adjustmentCents: -1000,
        idempotencyKey: 'contract-fraud-adjustment',
      );
      final settlement = await harness.economic.settlement.runSettlement(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        adjustmentCents: signal.adjustmentCents,
        idempotencyKey: 'contract-fraud-settlement',
      );

      expect(settlement.adjustmentCents, -1000);
      expect(settlement.netCents, 4000);
    });
  });

  group('A1-A4a provider contracts unblocked by A4b', () {
    test('ct_protected-vault__ads_no-fill-sensitive', () async {
      final harness = await _harnessWithCampaign();
      await harness.foundation.protectedVault.writeProtectedRecord(
        passportId: communityFoundationSeed.memberPassportId,
        field: 'care',
        value: 'needs private support',
        visibility: CommunityProtectedVisibility.permissionGated,
        actorId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'contract-protected-ad',
      );
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotTopBanner,
        sensitiveContext: true,
        idempotencyKey: 'contract-sensitive-ad',
      );

      expect(decision.status, CommunityAdDecisionStatus.noFill);
      expect(decision.reason, 'sensitive-context');
    });

    test('ct_receipt-ledger__wallet_append-payment', () async {
      final harness = await _harness();
      final payment = await harness.economic.wallet.recordPayment(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        kind: CommunityPaymentKind.donation,
        amountCents: 1200,
        idempotencyKey: 'contract-wallet-receipt',
      );
      final receipts = await harness.foundation.receiptLedger.listReceipts(
        communityFoundationSeed.memberPassportId,
      );

      expect(receipts.single.receiptId, payment.receiptId);
    });

    test('ct_publishing__search_index-visible-content', () async {
      final harness = await _harnessWithPublisher();
      final post = await harness.experience.publishing.publishPost(
        communityId: harness.community.communityId,
        authorPassportId: communityFoundationSeed.ownerActorId,
        title: 'Parable discussion',
        body: 'Public discussion prompt.',
        visibility: CommunityContentVisibility.public,
        idempotencyKey: 'contract-publish-search',
      );
      await harness.economic.indexing.indexRecord(
        communityId: harness.community.communityId,
        title: post.title,
        body: post.body,
        visibility: 'public',
        sourceComponent: 'publishing-service',
        idempotencyKey: 'contract-index-post',
      );
      final hits = await harness.economic.search.search(
        communityId: harness.community.communityId,
        query: 'Parable',
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: false,
      );

      expect(hits.single.explanation, contains('publishing-service'));
    });

    test('ct_messaging__ad-decision_in-stream-insertion', () async {
      final harness = await _harnessWithCampaign();
      final decision = await harness.economic.adDecisions.decide(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        slot: communityEconomicSeed.adSlotInStream,
        sensitiveContext: false,
        idempotencyKey: 'contract-message-ad',
      );

      expect(decision.status, CommunityAdDecisionStatus.fill);
      expect(decision.slot, communityEconomicSeed.adSlotInStream);
    });

    test('ct_documents__search_index-visible-documents', () async {
      final harness = await _harnessWithDocumentWriter();
      final document = await harness.ops.documents.uploadDocument(
        communityId: harness.community.communityId,
        title: communityOpsSeed.documentTitle,
        body: 'Searchable handbook.',
        visibility: CommunityDocumentVisibility.members,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'contract-doc-search',
      );
      await harness.economic.indexing.indexRecord(
        communityId: harness.community.communityId,
        title: document.title,
        body: document.body,
        visibility: 'members',
        sourceComponent: 'documents-service',
        idempotencyKey: 'contract-index-doc',
      );
      final hits = await harness.economic.search.search(
        communityId: harness.community.communityId,
        query: 'handbook',
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: false,
      );

      expect(hits.single.title, communityOpsSeed.documentTitle);
    });

    test('ct_facilities__wallet_reservation-payment', () async {
      final harness = await _harness();
      final reservation = await harness.ops.facilities.reserveFacility(
        communityId: harness.community.communityId,
        facilityId: communityOpsSeed.facilityId,
        passportId: communityFoundationSeed.memberPassportId,
        amountCents: 2500,
        idempotencyKey: 'contract-reservation',
      );
      final payment = await harness.economic.wallet.recordPayment(
        communityId: harness.community.communityId,
        passportId: reservation.passportId,
        kind: CommunityPaymentKind.reservation,
        amountCents: reservation.amountCents,
        idempotencyKey: 'contract-reservation-payment',
      );

      expect(payment.amountCents, reservation.amountCents);
    });

    test('ct_fraud__dispute_resolution-path', () async {
      final harness = await _harness();
      final dispute = await harness.ops.disputes.openDispute(
        communityId: harness.community.communityId,
        subjectId: 'payment_1',
        reason: 'duplicate charge',
        idempotencyKey: 'contract-dispute',
      );
      final signal = await harness.economic.fraud.createSignal(
        communityId: harness.community.communityId,
        subjectId: dispute.disputeId,
        severity: CommunityFraudSignalSeverity.hold,
        adjustmentCents: -1000,
        idempotencyKey: 'contract-fraud-dispute',
      );

      expect(signal.subjectId, dispute.disputeId);
    });
  });

  group('A4b pending counterpart contract kits', () {
    test(
      'ct_ad-decision__app-shell_banner-fill',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_ad-decision__stream-renderer_in-stream-ad',
      () {},
      skip: 'stream-renderer is built in A6',
    );
    test(
      'ct_search__app-shell_result-explanations',
      () {},
      skip: 'app-shell-runtime is built in A6',
    );
    test(
      'ct_wallet__payment-surface_checkout',
      () {},
      skip: 'payment-surface is built in A6',
    );
  });
}

Future<_EconomicHarness> _harness() async {
  final foundation = CommunityFoundationFakeBackend();
  final registry = CommunityRegistryControlPlaneFakeBackend(foundation);
  final community = await registry.communityRegistry.registerCommunity(
    handle: communityRegistrySeed.handle,
    displayName: communityRegistrySeed.displayName,
    branding: CommunityBranding(
      logoAssetId: communityRegistrySeed.logoAssetId,
      cardImageAssetId: communityRegistrySeed.cardImageAssetId,
      accentColor: '#246B62',
      altText: 'Book club table',
    ),
    ownerPassportId: communityFoundationSeed.ownerActorId,
    idempotencyKey: 'a4b-register-community',
  );
  final experience = CommunityExperienceServicesFakeBackend(
    foundation: foundation,
    registry: registry,
  );
  final ops = CommunityOpsServicesFakeBackend(
    foundation: foundation,
    registry: registry,
    experience: experience,
  );
  final economic = CommunityEconomicServicesFakeBackend(foundation: foundation);
  return _EconomicHarness(
    foundation: foundation,
    registry: registry,
    experience: experience,
    ops: ops,
    economic: economic,
    community: community,
  );
}

Future<_EconomicHarness> _harnessWithCampaign() async {
  final harness = await _harness();
  await harness.economic.adCampaigns.createCampaign(
    communityId: harness.community.communityId,
    sponsorName: communityEconomicSeed.sponsorName,
    slot: communityEconomicSeed.adSlotTopBanner,
    idempotencyKey: 'shared-campaign-top',
  );
  await harness.economic.adCampaigns.createCampaign(
    communityId: harness.community.communityId,
    sponsorName: communityEconomicSeed.sponsorName,
    slot: communityEconomicSeed.adSlotInStream,
    idempotencyKey: 'shared-campaign-stream',
  );
  return harness;
}

Future<_EconomicHarness> _harnessWithSearchRecord() async {
  final harness = await _harness();
  await harness.economic.indexing.indexRecord(
    communityId: harness.community.communityId,
    title: communityEconomicSeed.searchTitle,
    body: communityEconomicSeed.searchBody,
    visibility: 'public',
    sourceComponent: 'publishing-service',
    idempotencyKey: 'shared-index',
  );
  return harness;
}

Future<_EconomicHarness> _harnessWithPayment() async {
  final harness = await _harness();
  await harness.economic.wallet.recordPayment(
    communityId: harness.community.communityId,
    passportId: communityFoundationSeed.memberPassportId,
    kind: CommunityPaymentKind.dues,
    amountCents: 5000,
    idempotencyKey: 'shared-payment',
  );
  return harness;
}

Future<_EconomicHarness> _harnessWithPublisher() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.ownerActorId,
    communityId: harness.community.communityId,
    permission: 'content.publish',
    grantedBy: 'system',
    idempotencyKey: 'grant-a4b-publish',
  );
  return harness;
}

Future<_EconomicHarness> _harnessWithDocumentWriter() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.ownerActorId,
    communityId: harness.community.communityId,
    permission: 'documents.write',
    grantedBy: 'system',
    idempotencyKey: 'grant-a4b-documents',
  );
  return harness;
}

class _EconomicHarness {
  const _EconomicHarness({
    required this.foundation,
    required this.registry,
    required this.experience,
    required this.ops,
    required this.economic,
    required this.community,
  });

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;
  final CommunityOpsServicesFakeBackend ops;
  final CommunityEconomicServicesFakeBackend economic;
  final CommunityProfile community;
}
