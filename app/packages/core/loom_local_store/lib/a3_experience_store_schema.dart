class A3OwnedTable {
  const A3OwnedTable({
    required this.componentId,
    required this.tableName,
    required this.ownedFields,
  });

  final String componentId;
  final String tableName;
  final List<String> ownedFields;
}

class A3ExperienceStoreSchema {
  static const tables = [
    A3OwnedTable(
      componentId: 'publishing-service',
      tableName: 'community_posts',
      ownedFields: ['postId', 'communityId', 'authorPassportId', 'visibility'],
    ),
    A3OwnedTable(
      componentId: 'messaging-stream-service',
      tableName: 'community_messages',
      ownedFields: ['messageId', 'threadId', 'senderPassportId', 'body'],
    ),
    A3OwnedTable(
      componentId: 'notification-service',
      tableName: 'community_notifications',
      ownedFields: ['notificationId', 'passportId', 'channel', 'dedupeKey'],
    ),
    A3OwnedTable(
      componentId: 'events-service',
      tableName: 'community_events_service',
      ownedFields: ['eventId', 'communityId', 'title', 'capacity'],
    ),
    A3OwnedTable(
      componentId: 'forms-voting-service',
      tableName: 'community_form_submissions',
      ownedFields: ['submissionId', 'formId', 'passportId', 'answers'],
    ),
  ];

  const A3ExperienceStoreSchema._();
}
