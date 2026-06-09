import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a3_experience_store_schema.dart';
import 'package:loom_seed_data/community_experience_seed_data.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A3 experience-service validation tests', () {
    test('vt_publishing_publish', () async {
      final harness = await _harness();
      await harness.foundation.rolePolicy.grantPermission(
        actorId: communityFoundationSeed.ownerActorId,
        communityId: harness.community.communityId,
        permission: 'content.publish',
        grantedBy: 'system',
        idempotencyKey: 'grant-publish',
      );
      final post = await harness.experience.publishing.publishPost(
        communityId: harness.community.communityId,
        authorPassportId: communityFoundationSeed.ownerActorId,
        title: 'January pick',
        body: 'Nominate books by Friday.',
        visibility: CommunityContentVisibility.public,
        idempotencyKey: 'publish-january',
      );
      final events = await harness.foundation.eventBus.replay(
        type: 'community.post.published',
      );

      expect(post.postId, startsWith('post_'));
      expect(events.map((event) => event.subjectId), contains(post.postId));
    });

    test('vt_publishing_visibility', () async {
      final harness = await _harnessWithPublisher();
      await harness.experience.publishing.publishPost(
        communityId: harness.community.communityId,
        authorPassportId: communityFoundationSeed.ownerActorId,
        title: 'Members only',
        body: 'Private reading notes.',
        visibility: CommunityContentVisibility.members,
        idempotencyKey: 'publish-members',
      );
      final publicPosts = await harness.experience.publishing.visiblePosts(
        communityId: harness.community.communityId,
        includeMemberOnly: false,
      );
      final memberPosts = await harness.experience.publishing.visiblePosts(
        communityId: harness.community.communityId,
        includeMemberOnly: true,
      );

      expect(publicPosts, isEmpty);
      expect(memberPosts, hasLength(1));
    });

    test('vt_messaging_stream-render', () async {
      final harness = await _harness();
      final message = await harness.experience.messaging.sendMessage(
        threadId: communityExperienceSeed.threadId,
        senderPassportId: communityFoundationSeed.memberPassportId,
        body: 'I vote for Octavia Butler.',
        idempotencyKey: 'message-1',
      );
      final stream = await harness.experience.messaging.renderStream(
        communityExperienceSeed.threadId,
      );

      expect(stream.single.kind, 'message');
      expect(stream.single.sourceId, message.messageId);
    });

    test('vt_messaging_direct-group', () async {
      final harness = await _harness();
      await harness.experience.messaging.sendMessage(
        threadId: 'dm_owner_member',
        senderPassportId: communityFoundationSeed.ownerActorId,
        body: 'Can you host next month?',
        idempotencyKey: 'dm-1',
      );
      await harness.experience.messaging.sendMessage(
        threadId: 'dm_owner_member',
        senderPassportId: communityFoundationSeed.memberPassportId,
        body: 'Yes.',
        idempotencyKey: 'dm-2',
      );
      final stream = await harness.experience.messaging.renderStream(
        'dm_owner_member',
      );

      expect(stream, hasLength(2));
    });

    test('vt_notification_deliver', () async {
      final harness = await _harness();
      final first = await harness.experience.notifications.deliver(
        passportId: communityFoundationSeed.memberPassportId,
        channel: 'push',
        subject: 'Book club starts soon',
        dedupeKey: 'event-reminder',
      );
      final repeated = await harness.experience.notifications.deliver(
        passportId: communityFoundationSeed.memberPassportId,
        channel: 'push',
        subject: 'Book club starts soon',
        dedupeKey: 'event-reminder',
      );
      final all = await harness.experience.notifications.listNotifications(
        communityFoundationSeed.memberPassportId,
      );

      expect(repeated.notificationId, first.notificationId);
      expect(all, hasLength(1));
      expect(first.delivered, isTrue);
    });

    test('vt_events_rsvp', () async {
      final harness = await _harness();
      final event = await harness.experience.events.createEvent(
        communityId: harness.community.communityId,
        title: 'Monthly discussion',
        capacity: 10,
        idempotencyKey: 'event-create',
      );
      final rsvp = await harness.experience.events.rsvp(
        eventId: event.eventId,
        passportId: communityFoundationSeed.memberPassportId,
        state: CommunityRsvpState.going,
        idempotencyKey: 'rsvp-going',
      );

      expect(rsvp.state, CommunityRsvpState.going);
    });

    test('vt_events_ticketing', () async {
      final harness = await _harness();
      final event = await harness.experience.events.createEvent(
        communityId: harness.community.communityId,
        title: 'Author talk',
        capacity: 1,
        idempotencyKey: 'ticket-event',
      );
      final rsvp = await harness.experience.events.rsvp(
        eventId: event.eventId,
        passportId: communityFoundationSeed.memberPassportId,
        state: CommunityRsvpState.going,
        idempotencyKey: 'ticket-rsvp',
      );

      expect(rsvp.ticketCode, isNotNull);
    });

    test('vt_forms-voting_submit', () async {
      final harness = await _harness();
      final submission = await harness.experience.formsVoting.submitForm(
        formId: communityExperienceSeed.formId,
        passportId: communityFoundationSeed.memberPassportId,
        answers: {
          'book': 'Parable of the Sower',
          'accessibilityNeed': 'large-print copy',
        },
        sensitiveFields: ['accessibilityNeed'],
        idempotencyKey: 'form-submit',
      );

      expect(submission.answers.keys, contains('book'));
      expect(submission.answers.keys, isNot(contains('accessibilityNeed')));
      expect(submission.protectedRecordIds, hasLength(1));
    });

    test('vt_forms-voting_poll-results', () async {
      final harness = await _harness();
      await harness.experience.formsVoting.submitVote(
        pollId: communityExperienceSeed.pollId,
        passportId: 'passport_a',
        optionId: 'option_1',
        idempotencyKey: 'vote-a',
      );
      final result = await harness.experience.formsVoting.submitVote(
        pollId: communityExperienceSeed.pollId,
        passportId: 'passport_b',
        optionId: 'option_1',
        idempotencyKey: 'vote-b',
      );

      expect(result.optionCounts['option_1'], 2);
      expect(
        A3ExperienceStoreSchema.tables.map((table) => table.componentId),
        contains('forms-voting-service'),
      );
    });
  });

  group('A3 built-counterpart consumer contract tests', () {
    test('ct_forms-voting__protected-vault_sensitive-fields', () async {
      final harness = await _harness();
      final submission = await harness.experience.formsVoting.submitForm(
        formId: communityExperienceSeed.formId,
        passportId: communityFoundationSeed.memberPassportId,
        answers: {'care': 'needs a ride'},
        sensitiveFields: ['care'],
        idempotencyKey: 'contract-sensitive-form',
      );

      final hidden = await harness.foundation.protectedVault.readProtectedRecord(
        recordId: submission.protectedRecordIds.single,
        actorId: 'volunteer_1',
        communityId: harness.community.communityId,
        requiredPermission: 'protected.read',
      );

      expect(hidden, isNull);
    });
  });

  group('A3 pending counterpart contract kits', () {
    test(
      'ct_publishing__search_index-visible-content',
      () {},
      skip: 'search-service is built in A4b',
    );
    test(
      'ct_publishing__stream-renderer_render-post',
      () {},
      skip: 'stream-renderer is built in A6',
    );
    test(
      'ct_messaging__stream-renderer_render-message-and-ad-item',
      () {},
      skip: 'stream-renderer is built in A6',
    );
    test(
      'ct_messaging__ad-decision_in-stream-insertion',
      () {},
      skip: 'ad-decision-service is built in A4b',
    );
    test(
      'ct_events__workflow-engine_event-registration',
      () {},
      skip: 'workflow-engine is built in A5',
    );
    test(
      'ct_notification__workflow-engine_delivery',
      () {},
      skip: 'workflow-engine is built in A5',
    );
  });
}

Future<_ExperienceHarness> _harness() async {
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
    idempotencyKey: 'a3-register-community',
  );
  final experience = CommunityExperienceServicesFakeBackend(
    foundation: foundation,
    registry: registry,
  );
  return _ExperienceHarness(
    foundation: foundation,
    registry: registry,
    experience: experience,
    community: community,
  );
}

Future<_ExperienceHarness> _harnessWithPublisher() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.ownerActorId,
    communityId: harness.community.communityId,
    permission: 'content.publish',
    grantedBy: 'system',
    idempotencyKey: 'grant-publish-shared',
  );
  return harness;
}

class _ExperienceHarness {
  const _ExperienceHarness({
    required this.foundation,
    required this.registry,
    required this.experience,
    required this.community,
  });

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;
  final CommunityProfile community;
}
