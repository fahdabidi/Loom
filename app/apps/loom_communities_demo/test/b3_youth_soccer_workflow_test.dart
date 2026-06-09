import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_youth-soccer-headline', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'youth-soccer',
      displayName: 'Riverside Youth Soccer',
      category: 'sports',
      extensionId: 'ext_youth_soccer',
      cardAssetId: 'asset_card_youth_soccer',
      logoAssetId: 'asset_logo_youth_soccer',
      accentColor: '#1F7A5C',
    );
    await harness.grant('protected.read');

    final membership = await harness.registry.membership.requestJoin(
      communityId: harness.communityId,
      passportId: harness.memberId,
      idempotencyKey: 'b3-join',
    );
    final approved = await harness.registry.membership.approveJoin(
      membershipId: membership.membershipId,
      approvedBy: harness.ownerId,
      idempotencyKey: 'b3-approve',
    );
    final team = await harness.registry.spaces.createSpace(
      communityId: harness.communityId,
      parentSpaceId: null,
      name: 'U10 Falcons',
      idempotencyKey: 'b3-team-space',
    );
    final protectedMinor = await harness.foundation.protectedVault
        .writeProtectedRecord(
          passportId: harness.memberId,
          field: 'minor_birthdate',
          value: '2016-04-12',
          visibility: CommunityProtectedVisibility.permissionGated,
          actorId: harness.ownerId,
          idempotencyKey: 'b3-minor-data',
        );
    final protectedRead = await harness.foundation.protectedVault
        .readProtectedRecord(
          recordId: protectedMinor.recordId,
          actorId: harness.ownerId,
          communityId: harness.communityId,
          requiredPermission: 'protected.read',
        );
    final payment = await harness.economic.wallet.recordPayment(
      communityId: harness.communityId,
      passportId: harness.memberId,
      kind: CommunityPaymentKind.dues,
      amountCents: 12500,
      idempotencyKey: 'b3-registration-payment',
    );
    final practice = await harness.experience.events.createEvent(
      communityId: harness.communityId,
      title: 'Saturday practice',
      capacity: 18,
      idempotencyKey: 'b3-practice',
    );
    final notification = await harness.experience.notifications.deliver(
      passportId: harness.memberId,
      channel: 'push',
      subject: 'Practice starts at 9 AM',
      dedupeKey: 'b3-practice-reminder',
    );
    harness.shell.openExtension('local:ext_youth_soccer@latest');

    expect(approved.state, CommunityMembershipState.active);
    expect(team.name, 'U10 Falcons');
    expect(protectedRead?.redactedValue, '***');
    expect(payment.amountCents, 12500);
    expect(payment.kind, CommunityPaymentKind.dues);
    expect(practice.capacity, 18);
    expect(notification.delivered, isTrue);
    expect(harness.shell.openExtensionId, 'local:ext_youth_soccer@latest');
  });
}
