import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'community_foundation_fake.dart';
import 'community_registry_fake.dart';

class CommunityExperienceServicesFakeBackend {
  CommunityExperienceServicesFakeBackend({
    required this.foundation,
    required this.registry,
  }) {
    publishing = CommunityPublishingFake(foundation.rolePolicy, foundation.eventBus);
    messaging = CommunityMessagingFake(foundation.eventBus);
    notifications = CommunityNotificationFake();
    events = CommunityEventsFake(foundation.eventBus);
    formsVoting = CommunityFormsVotingFake(
      foundation.protectedVault,
      foundation.eventBus,
    );
  }

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;

  late final CommunityPublishingFake publishing;
  late final CommunityMessagingFake messaging;
  late final CommunityNotificationFake notifications;
  late final CommunityEventsFake events;
  late final CommunityFormsVotingFake formsVoting;
}

class CommunityPublishingFake implements CommunityPublishingApi {
  CommunityPublishingFake(this._policy, this._events);

  final CommunityRolePolicyApi _policy;
  final CommunityEventBusApi _events;
  final List<CommunityPost> _posts = [];
  final Map<String, CommunityPost> _byIdempotency = {};

  @override
  Future<CommunityPost> publishPost({
    required String communityId,
    required String authorPassportId,
    required String title,
    required String body,
    required CommunityContentVisibility visibility,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final decision = await _policy.effectivePermission(
      actorId: authorPassportId,
      communityId: communityId,
      permission: 'content.publish',
    );
    if (!decision.allowed) {
      throw StateError('missing content.publish');
    }
    final post = CommunityPost(
      postId: 'post_${_posts.length + 1}',
      communityId: communityId,
      authorPassportId: authorPassportId,
      title: title,
      body: body,
      visibility: visibility,
      version: 1,
    );
    _posts.add(post);
    _byIdempotency[idempotencyKey] = post;
    await _events.publish(
      type: 'community.post.published',
      sourceComponent: 'publishing-service',
      subjectId: post.postId,
      payload: {'communityId': communityId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return post;
  }

  @override
  Future<List<CommunityPost>> visiblePosts({
    required String communityId,
    required bool includeMemberOnly,
  }) async {
    return _posts.where((post) {
      final sameCommunity = post.communityId == communityId;
      final visible =
          includeMemberOnly ||
          post.visibility == CommunityContentVisibility.public;
      return sameCommunity && visible;
    }).toList(growable: false);
  }
}

class CommunityMessagingFake implements CommunityMessagingApi {
  CommunityMessagingFake(this._events);

  final CommunityEventBusApi _events;
  final List<CommunityMessage> _messages = [];
  final Map<String, CommunityMessage> _byIdempotency = {};

  @override
  Future<CommunityMessage> sendMessage({
    required String threadId,
    required String senderPassportId,
    required String body,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final message = CommunityMessage(
      messageId: 'message_${_messages.length + 1}',
      threadId: threadId,
      senderPassportId: senderPassportId,
      body: body,
      version: 1,
    );
    _messages.add(message);
    _byIdempotency[idempotencyKey] = message;
    await _events.publish(
      type: 'community.message.sent',
      sourceComponent: 'messaging-stream-service',
      subjectId: message.messageId,
      payload: {'threadId': threadId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return message;
  }

  @override
  Future<List<CommunityStreamItem>> renderStream(String threadId) async {
    return _messages
        .where((message) => message.threadId == threadId)
        .map(
          (message) => CommunityStreamItem(
            itemId: 'stream_${message.messageId}',
            kind: 'message',
            title: message.senderPassportId,
            body: message.body,
            sourceId: message.messageId,
          ),
        )
        .toList(growable: false);
  }
}

class CommunityNotificationFake implements CommunityNotificationApi {
  final Map<String, CommunityNotification> _byDedupe = {};
  final List<CommunityNotification> _notifications = [];

  @override
  Future<CommunityNotification> deliver({
    required String passportId,
    required String channel,
    required String subject,
    required String dedupeKey,
  }) async {
    final existing = _byDedupe[dedupeKey];
    if (existing != null) {
      return existing;
    }
    final notification = CommunityNotification(
      notificationId: 'notification_${_notifications.length + 1}',
      passportId: passportId,
      channel: channel,
      subject: subject,
      dedupeKey: dedupeKey,
      delivered: true,
    );
    _notifications.add(notification);
    _byDedupe[dedupeKey] = notification;
    return notification;
  }

  @override
  Future<List<CommunityNotification>> listNotifications(
    String passportId,
  ) async {
    return _notifications
        .where((notification) => notification.passportId == passportId)
        .toList(growable: false);
  }
}

class CommunityEventsFake implements CommunityEventsApi {
  CommunityEventsFake(this._events);

  final CommunityEventBusApi _events;
  final Map<String, CommunityEvent> _eventsById = {};
  final Map<String, CommunityRsvp> _rsvps = {};
  final Map<String, CommunityEvent> _byIdempotency = {};

  @override
  Future<CommunityEvent> createEvent({
    required String communityId,
    required String title,
    required int capacity,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final event = CommunityEvent(
      eventId: 'event_meeting_${_eventsById.length + 1}',
      communityId: communityId,
      title: title,
      capacity: capacity,
      version: 1,
    );
    _eventsById[event.eventId] = event;
    _byIdempotency[idempotencyKey] = event;
    await _events.publish(
      type: 'community.event.created',
      sourceComponent: 'events-service',
      subjectId: event.eventId,
      payload: {'communityId': communityId},
      idempotencyKey: 'bus_$idempotencyKey',
    );
    return event;
  }

  @override
  Future<CommunityRsvp> rsvp({
    required String eventId,
    required String passportId,
    required CommunityRsvpState state,
    required String idempotencyKey,
  }) async {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('unknown event: $eventId');
    }
    final key = '$eventId::$passportId';
    final goingCount = _rsvps.values
        .where(
          (rsvp) =>
              rsvp.eventId == eventId && rsvp.state == CommunityRsvpState.going,
        )
        .length;
    if (state == CommunityRsvpState.going && goingCount >= event.capacity) {
      throw StateError('event capacity reached');
    }
    final rsvp = CommunityRsvp(
      rsvpId: 'rsvp_${_rsvps.length + 1}',
      eventId: eventId,
      passportId: passportId,
      state: state,
      ticketCode: state == CommunityRsvpState.going
          ? 'ticket_${eventId}_$passportId'
          : null,
    );
    _rsvps[key] = rsvp;
    return rsvp;
  }
}

class CommunityFormsVotingFake implements CommunityFormsVotingApi {
  CommunityFormsVotingFake(this._protectedVault, this._events);

  final CommunityProtectedVaultApi _protectedVault;
  final CommunityEventBusApi _events;
  final Map<String, CommunityFormSubmission> _submissionsByIdempotency = {};
  final Map<String, Map<String, int>> _pollCounts = {};
  final Set<String> _voteKeys = {};

  @override
  Future<CommunityFormSubmission> submitForm({
    required String formId,
    required String passportId,
    required Map<String, String> answers,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  }) async {
    final existing = _submissionsByIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final visibleAnswers = Map<String, String>.from(answers)
      ..removeWhere((key, value) => sensitiveFields.contains(key));
    final protectedIds = <String>[];
    for (final field in sensitiveFields) {
      final value = answers[field];
      if (value == null) {
        continue;
      }
      final protected = await _protectedVault.writeProtectedRecord(
        passportId: passportId,
        field: field,
        value: value,
        visibility: CommunityProtectedVisibility.permissionGated,
        actorId: passportId,
        idempotencyKey: 'protected_${idempotencyKey}_$field',
      );
      protectedIds.add(protected.recordId);
    }
    final submission = CommunityFormSubmission(
      submissionId: 'submission_${_submissionsByIdempotency.length + 1}',
      formId: formId,
      passportId: passportId,
      answers: Map<String, String>.unmodifiable(visibleAnswers),
      protectedRecordIds: List<String>.unmodifiable(protectedIds),
    );
    _submissionsByIdempotency[idempotencyKey] = submission;
    await _events.publish(
      type: 'community.form.submitted',
      sourceComponent: 'forms-voting-service',
      subjectId: submission.submissionId,
      payload: {'formId': formId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return submission;
  }

  @override
  Future<CommunityPollResult> submitVote({
    required String pollId,
    required String passportId,
    required String optionId,
    required String idempotencyKey,
  }) async {
    if (!_voteKeys.add(idempotencyKey)) {
      return CommunityPollResult(
        pollId: pollId,
        optionCounts: Map<String, int>.unmodifiable(_pollCounts[pollId] ?? {}),
      );
    }
    final counts = _pollCounts.putIfAbsent(pollId, () => <String, int>{});
    counts[optionId] = (counts[optionId] ?? 0) + 1;
    return CommunityPollResult(
      pollId: pollId,
      optionCounts: Map<String, int>.unmodifiable(counts),
    );
  }
}
