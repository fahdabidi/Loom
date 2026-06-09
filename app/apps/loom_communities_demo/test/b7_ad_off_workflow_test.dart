import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_ad-off', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'ad-off-demo',
      displayName: 'Ad-Off Demo Community',
      category: 'platform',
      extensionId: 'ext_ad_off',
      cardAssetId: 'asset_card_ad_off',
      logoAssetId: 'asset_logo_ad_off',
      accentColor: '#5B5F97',
    );

    const memberCheckout = PaymentSurfaceProps(
      surfaceId: 'ad-off-member-checkout',
      shellOwned: true,
      amountCents: 299,
    );
    await harness.economic.adCampaigns.createCampaign(
      communityId: harness.communityId,
      sponsorName: 'Community Sponsor',
      slot: harness.shell.topAdSlot.slotId,
      idempotencyKey: 'b7-top-banner-campaign',
    );
    await harness.economic.adCampaigns.createCampaign(
      communityId: harness.communityId,
      sponsorName: 'Community Sponsor',
      slot: 'stream.inline',
      idempotencyKey: 'b7-stream-campaign',
    );

    final beforeAdOff = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: harness.shell.topAdSlot.slotId,
      sensitiveContext: false,
      idempotencyKey: 'b7-before-ad-off',
    );
    final memberEntitlement = await harness.economic.wallet.purchaseAdOff(
      scopeId: harness.communityId,
      passportId: harness.memberId,
      amountCents: memberCheckout.amountCents,
      idempotencyKey: 'b7-member-ad-off',
    );
    final memberHasAdOff = await harness.economic.wallet.hasAdOff(
      scopeId: harness.communityId,
      passportId: harness.memberId,
    );
    final afterMemberAdOff = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: harness.shell.topAdSlot.slotId,
      sensitiveContext: false,
      idempotencyKey: 'b7-after-member-ad-off',
    );
    final sensitiveNoFill = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: 'stream.inline',
      sensitiveContext: true,
      idempotencyKey: 'b7-sensitive-no-fill',
    );
    final memberReceipts = await harness.foundation.receiptLedger.listReceipts(
      harness.memberId,
    );

    const communityCheckout = PaymentSurfaceProps(
      surfaceId: 'ad-off-community-checkout',
      shellOwned: true,
      amountCents: 1999,
    );
    final ownerBeforeCommunity = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.ownerId,
      slot: 'stream.inline',
      sensitiveContext: false,
      idempotencyKey: 'b7-owner-before-community-ad-off',
    );
    final communityEntitlement = await harness.economic.wallet.purchaseAdOff(
      scopeId: harness.communityId,
      passportId: 'community',
      amountCents: communityCheckout.amountCents,
      idempotencyKey: 'b7-community-ad-off',
    );
    final ownerAfterCommunity = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.ownerId,
      slot: 'stream.inline',
      sensitiveContext: false,
      idempotencyKey: 'b7-owner-after-community-ad-off',
    );
    final communityReceipts = await harness.foundation.receiptLedger
        .listReceipts('community');

    final memberSettlement = await harness.economic.settlement.runSettlement(
      communityId: harness.communityId,
      passportId: harness.memberId,
      adjustmentCents: 0,
      idempotencyKey: 'b7-member-settlement',
    );
    final communitySettlement = await harness.economic.settlement.runSettlement(
      communityId: harness.communityId,
      passportId: 'community',
      adjustmentCents: 0,
      idempotencyKey: 'b7-community-settlement',
    );
    final utility = await harness.economic.utilityFunding.calculate(
      settlement: communitySettlement,
      basisPoints: 1000,
      idempotencyKey: 'b7-utility-funding',
    );
    harness.shell.openExtension('local:ext_ad_off@latest');

    expect(memberCheckout.shellOwned, isTrue);
    expect(communityCheckout.shellOwned, isTrue);
    expect(beforeAdOff.status, CommunityAdDecisionStatus.fill);
    expect(memberEntitlement.active, isTrue);
    expect(memberHasAdOff, isTrue);
    expect(afterMemberAdOff.status, CommunityAdDecisionStatus.noFill);
    expect(afterMemberAdOff.reason, 'ad-off-entitlement');
    expect(sensitiveNoFill.status, CommunityAdDecisionStatus.noFill);
    expect(sensitiveNoFill.reason, 'sensitive-context');
    expect(memberReceipts.single.receiptId, memberEntitlement.receiptId);
    expect(ownerBeforeCommunity.status, CommunityAdDecisionStatus.fill);
    expect(communityEntitlement.active, isTrue);
    expect(communityEntitlement.passportId, 'community');
    expect(ownerAfterCommunity.status, CommunityAdDecisionStatus.noFill);
    expect(ownerAfterCommunity.reason, 'ad-off-entitlement');
    expect(communityReceipts.single.receiptId, communityEntitlement.receiptId);
    expect(memberSettlement.netCents, 299);
    expect(communitySettlement.netCents, 1999);
    expect(utility.utilityCents, 199);
    expect(utility.ownerCents, 1800);
    expect(harness.shell.openExtensionId, 'local:ext_ad_off@latest');
  });
}
