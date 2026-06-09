import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_messaging-ads-connections', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'platform-social',
      displayName: 'Platform Social Validation',
      category: 'platform',
      extensionId: 'ext_platform_social',
      cardAssetId: 'asset_card_platform_social',
      logoAssetId: 'asset_logo_platform_social',
      accentColor: '#315C8A',
    );

    final firstMessage = await harness.experience.messaging.sendMessage(
      threadId: 'community_general',
      senderPassportId: harness.memberId,
      body: 'Can anyone see the announcement?',
      idempotencyKey: 'b6-message-1',
    );
    await harness.experience.messaging.sendMessage(
      threadId: 'community_general',
      senderPassportId: harness.ownerId,
      body: 'Yes, the stream is working.',
      idempotencyKey: 'b6-message-2',
    );
    final messageStream = await harness.experience.messaging.renderStream(
      'community_general',
    );

    final invited = await harness.foundation.connections.invite(
      requesterPassportId: harness.memberId,
      targetPassportId: harness.ownerId,
      idempotencyKey: 'b6-invite-owner',
    );
    final blocked = await harness.foundation.connections.block(
      requesterPassportId: harness.memberId,
      targetPassportId: 'passport_blocked',
      idempotencyKey: 'b6-block-passport',
    );
    final canInviteBlocked = await harness.foundation.connections.canInvite(
      requesterPassportId: harness.memberId,
      targetPassportId: blocked.targetPassportId,
    );
    final connectionsShell = ConnectionsShellProps(
      blockedPassportIds: [blocked.targetPassportId],
    );

    await harness.economic.adCampaigns.createCampaign(
      communityId: harness.communityId,
      sponsorName: 'Neighborhood Sponsor',
      slot: 'stream.inline',
      idempotencyKey: 'b6-stream-campaign',
    );
    await harness.economic.adCampaigns.createCampaign(
      communityId: harness.communityId,
      sponsorName: 'Neighborhood Sponsor',
      slot: harness.shell.topAdSlot.slotId,
      idempotencyKey: 'b6-top-campaign',
    );
    final streamAdDecision = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: 'stream.inline',
      sensitiveContext: false,
      idempotencyKey: 'b6-stream-ad',
    );
    final topBannerDecision = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: harness.shell.topAdSlot.slotId,
      sensitiveContext: false,
      idempotencyKey: 'b6-top-banner-ad',
    );
    final sensitiveNoFill = await harness.economic.adDecisions.decide(
      communityId: harness.communityId,
      passportId: harness.memberId,
      slot: 'stream.inline',
      sensitiveContext: true,
      idempotencyKey: 'b6-sensitive-no-fill',
    );
    final adItem = renderAdStreamItem(
      title: 'Neighborhood Sponsor',
      body: 'Support community infrastructure.',
    );
    harness.shell.openExtension('local:ext_platform_social@latest');

    expect(harness.shell.hasRequiredStructure, isTrue);
    expect(harness.shell.navigation.exposesMessagesAndConnections, isTrue);
    expect(harness.shell.topAdSlot.required, isTrue);
    expect(harness.shell.topAdSlot.status, 'no-fill');
    expect(messageStream, hasLength(2));
    expect(messageStream.first.sourceId, firstMessage.messageId);
    expect(invited.state, CommunityConnectionState.invited);
    expect(canInviteBlocked, isFalse);
    expect(connectionsShell.canInvite(blocked.targetPassportId), isFalse);
    expect(streamAdDecision.status, CommunityAdDecisionStatus.fill);
    expect(topBannerDecision.status, CommunityAdDecisionStatus.fill);
    expect(sensitiveNoFill.status, CommunityAdDecisionStatus.noFill);
    expect(sensitiveNoFill.reason, 'sensitive-context');
    expect(adItem.kind, 'ad');
    expect(adItem.disclosure, 'Sponsored');
    expect(harness.shell.openExtensionId, 'local:ext_platform_social@latest');
  });
}
