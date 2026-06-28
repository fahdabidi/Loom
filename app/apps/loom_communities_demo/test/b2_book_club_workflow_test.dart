import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_book-club-headline', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'book-club',
      displayName: 'Neighborhood Book Club',
      category: 'book',
      extensionId: 'ext_book_club',
      cardAssetId: 'asset_card_book_club',
      logoAssetId: 'asset_logo_book_club',
      accentColor: '#246B62',
    );
    await harness.grant('content.publish');

    final nomination = await harness.experience.formsVoting.submitForm(
      formId: 'book_nomination',
      passportId: harness.memberId,
      answers: {'book': 'Parable of the Sower'},
      sensitiveFields: const [],
      idempotencyKey: 'b2-nomination',
    );
    final poll = await harness.experience.formsVoting.submitVote(
      pollId: 'book_vote',
      passportId: harness.memberId,
      optionId: 'parable',
      idempotencyKey: 'b2-vote',
    );
    final meeting = await harness.experience.events.createEvent(
      communityId: harness.communityId,
      title: 'Discuss Parable of the Sower',
      capacity: 24,
      idempotencyKey: 'b2-event',
    );
    final rsvp = await harness.experience.events.rsvp(
      eventId: meeting.eventId,
      passportId: harness.memberId,
      state: CommunityRsvpState.going,
      idempotencyKey: 'b2-rsvp',
    );
    final post = await harness.experience.publishing.publishPost(
      communityId: harness.communityId,
      authorPassportId: harness.ownerId,
      title: 'January selection',
      body: 'Parable of the Sower won this month.',
      visibility: CommunityContentVisibility.public,
      idempotencyKey: 'b2-post',
    );
    await harness.experience.messaging.sendMessage(
      threadId: 'book_discussion',
      senderPassportId: harness.memberId,
      body: 'I can bring discussion questions.',
      idempotencyKey: 'b2-message',
    );
    final indexed = await harness.economic.indexing.indexRecord(
      communityId: harness.communityId,
      title: post.title,
      body: post.body,
      visibility: 'public',
      sourceComponent: 'publishing-service',
      idempotencyKey: 'b2-index',
    );
    final answer = await harness.economic.aiGateway.answerQuestion(
      communityId: harness.communityId,
      question: 'Parable',
      actorPassportId: harness.memberId,
      idempotencyKey: 'b2-ai',
    );
    final digest = await harness.economic.digest.createDigest(
      communityId: harness.communityId,
      answer: answer,
      idempotencyKey: 'b2-digest',
    );
    harness.shell.openExtension('local:ext_book_club@latest');

    expect(nomination.answers['book'], 'Parable of the Sower');
    expect(poll.optionCounts['parable'], 1);
    expect(rsvp.ticketCode, isNotNull);
    expect(indexed.sourceComponent, 'publishing-service');
    expect(digest.citationRecordIds, contains(indexed.recordId));
    expect(
      bindCommunityCard(harness.shell.cards.single).displayName,
      'Neighborhood Book Club',
    );
    expect(harness.shell.openExtensionId, 'local:ext_book_club@latest');
  });
}
