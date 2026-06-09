import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_mosque-headline', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'masjid-nur',
      displayName: 'Masjid Nur',
      category: 'mosque',
      extensionId: 'ext_mosque',
      cardAssetId: 'asset_card_mosque',
      logoAssetId: 'asset_logo_mosque',
      accentColor: '#2D6A4F',
    );
    await harness.grant('content.publish');
    await harness.grant('protected.read');

    final announcement = await harness.experience.publishing.publishPost(
      communityId: harness.communityId,
      authorPassportId: harness.ownerId,
      title: 'Ramadan community night',
      body: 'Iftar volunteer signup and donation drive are open.',
      visibility: CommunityContentVisibility.public,
      idempotencyKey: 'b5-announcement',
    );
    final event = await harness.experience.events.createEvent(
      communityId: harness.communityId,
      title: 'Community iftar',
      capacity: 80,
      idempotencyKey: 'b5-iftar-event',
    );
    final rsvp = await harness.experience.events.rsvp(
      eventId: event.eventId,
      passportId: harness.memberId,
      state: CommunityRsvpState.going,
      idempotencyKey: 'b5-iftar-rsvp',
    );
    final volunteer = await harness.experience.formsVoting.submitForm(
      formId: 'iftar_volunteer',
      passportId: harness.memberId,
      answers: {'shift': 'setup', 'phone': '555-0100'},
      sensitiveFields: const ['phone'],
      idempotencyKey: 'b5-volunteer',
    );
    final donorPreference = await harness.foundation.coreVault.setPreference(
      passportId: harness.memberId,
      key: 'donor_visibility',
      value: 'anonymous',
      idempotencyKey: 'b5-donor-visibility',
    );
    final donation = await harness.economic.wallet.recordPayment(
      communityId: harness.communityId,
      passportId: harness.memberId,
      kind: CommunityPaymentKind.donation,
      amountCents: 5000,
      idempotencyKey: 'b5-donation',
    );
    final careRequest = await harness.experience.formsVoting.submitForm(
      formId: 'care_request',
      passportId: harness.memberId,
      answers: {
        'summary': 'Meal support requested',
        'details': 'Please contact privately after Jummah.',
      },
      sensitiveFields: const ['details'],
      idempotencyKey: 'b5-care-request',
    );
    final protectedCare = await harness.foundation.protectedVault
        .readProtectedRecord(
          recordId: careRequest.protectedRecordIds.single,
          actorId: harness.ownerId,
          communityId: harness.communityId,
          requiredPermission: 'protected.read',
        );
    final notification = await harness.experience.notifications.deliver(
      passportId: harness.memberId,
      channel: 'push',
      subject: 'Your care request was received',
      dedupeKey: 'b5-care-notification',
    );
    final indexed = await harness.economic.indexing.indexRecord(
      communityId: harness.communityId,
      title: announcement.title,
      body: announcement.body,
      visibility: 'public',
      sourceComponent: 'publishing-service',
      idempotencyKey: 'b5-index-announcement',
    );
    final answer = await harness.economic.aiGateway.answerQuestion(
      communityId: harness.communityId,
      question: 'iftar',
      actorPassportId: harness.memberId,
      idempotencyKey: 'b5-ai-answer',
    );
    harness.shell.openExtension('local:ext_mosque@latest');

    expect(announcement.title, 'Ramadan community night');
    expect(rsvp.ticketCode, isNotNull);
    expect(volunteer.answers, isNot(contains('phone')));
    expect(volunteer.protectedRecordIds, isNotEmpty);
    expect(donorPreference.value, 'anonymous');
    expect(donation.kind, CommunityPaymentKind.donation);
    expect(donation.amountCents, 5000);
    expect(careRequest.answers['summary'], 'Meal support requested');
    expect(careRequest.answers, isNot(contains('details')));
    expect(protectedCare?.redactedValue, startsWith('P'));
    expect(notification.delivered, isTrue);
    expect(indexed.sourceComponent, 'publishing-service');
    expect(answer.citationRecordIds, contains(indexed.recordId));
    expect(harness.shell.openExtensionId, 'local:ext_mosque@latest');
  });
}
