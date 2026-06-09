enum CommunityContentVisibility { members, public }

enum CommunityRsvpState { going, maybe, declined }

class CommunityPost {
  const CommunityPost({
    required this.postId,
    required this.communityId,
    required this.authorPassportId,
    required this.title,
    required this.body,
    required this.visibility,
    required this.version,
  });

  final String postId;
  final String communityId;
  final String authorPassportId;
  final String title;
  final String body;
  final CommunityContentVisibility visibility;
  final int version;
}

class CommunityStreamItem {
  const CommunityStreamItem({
    required this.itemId,
    required this.kind,
    required this.title,
    required this.body,
    required this.sourceId,
  });

  final String itemId;
  final String kind;
  final String title;
  final String body;
  final String sourceId;
}

class CommunityMessage {
  const CommunityMessage({
    required this.messageId,
    required this.threadId,
    required this.senderPassportId,
    required this.body,
    required this.version,
  });

  final String messageId;
  final String threadId;
  final String senderPassportId;
  final String body;
  final int version;
}

class CommunityNotification {
  const CommunityNotification({
    required this.notificationId,
    required this.passportId,
    required this.channel,
    required this.subject,
    required this.dedupeKey,
    required this.delivered,
  });

  final String notificationId;
  final String passportId;
  final String channel;
  final String subject;
  final String dedupeKey;
  final bool delivered;
}

class CommunityEvent {
  const CommunityEvent({
    required this.eventId,
    required this.communityId,
    required this.title,
    required this.capacity,
    required this.version,
  });

  final String eventId;
  final String communityId;
  final String title;
  final int capacity;
  final int version;
}

class CommunityRsvp {
  const CommunityRsvp({
    required this.rsvpId,
    required this.eventId,
    required this.passportId,
    required this.state,
    required this.ticketCode,
  });

  final String rsvpId;
  final String eventId;
  final String passportId;
  final CommunityRsvpState state;
  final String? ticketCode;
}

class CommunityFormSubmission {
  const CommunityFormSubmission({
    required this.submissionId,
    required this.formId,
    required this.passportId,
    required this.answers,
    required this.protectedRecordIds,
  });

  final String submissionId;
  final String formId;
  final String passportId;
  final Map<String, String> answers;
  final List<String> protectedRecordIds;
}

class CommunityPollResult {
  const CommunityPollResult({
    required this.pollId,
    required this.optionCounts,
  });

  final String pollId;
  final Map<String, int> optionCounts;
}

abstract class CommunityPublishingApi {
  Future<CommunityPost> publishPost({
    required String communityId,
    required String authorPassportId,
    required String title,
    required String body,
    required CommunityContentVisibility visibility,
    required String idempotencyKey,
  });

  Future<List<CommunityPost>> visiblePosts({
    required String communityId,
    required bool includeMemberOnly,
  });
}

abstract class CommunityMessagingApi {
  Future<CommunityMessage> sendMessage({
    required String threadId,
    required String senderPassportId,
    required String body,
    required String idempotencyKey,
  });

  Future<List<CommunityStreamItem>> renderStream(String threadId);
}

abstract class CommunityNotificationApi {
  Future<CommunityNotification> deliver({
    required String passportId,
    required String channel,
    required String subject,
    required String dedupeKey,
  });

  Future<List<CommunityNotification>> listNotifications(String passportId);
}

abstract class CommunityEventsApi {
  Future<CommunityEvent> createEvent({
    required String communityId,
    required String title,
    required int capacity,
    required String idempotencyKey,
  });

  Future<CommunityRsvp> rsvp({
    required String eventId,
    required String passportId,
    required CommunityRsvpState state,
    required String idempotencyKey,
  });
}

abstract class CommunityFormsVotingApi {
  Future<CommunityFormSubmission> submitForm({
    required String formId,
    required String passportId,
    required Map<String, String> answers,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  });

  Future<CommunityPollResult> submitVote({
    required String pollId,
    required String passportId,
    required String optionId,
    required String idempotencyKey,
  });
}
