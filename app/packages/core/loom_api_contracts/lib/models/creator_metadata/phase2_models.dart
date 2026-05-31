import 'content_summary_view.dart';

enum ContentAccessMode { public, membersOnly }

enum MonetizationMode { free, membership }

class ContentManifest {
  const ContentManifest({
    required this.id,
    required this.channelId,
    required this.title,
    required this.summary,
    required this.contentType,
    required this.accessMode,
    required this.monetizationMode,
    required this.thumbnailRef,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String title;
  final String summary;
  final ContentType contentType;
  final ContentAccessMode accessMode;
  final MonetizationMode monetizationMode;
  final String thumbnailRef;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MonetizationManifest {
  const MonetizationManifest({
    required this.channelId,
    required this.membershipsEnabled,
    required this.memberOnlyContentIds,
    required this.updatedAt,
  });

  final String channelId;
  final bool membershipsEnabled;
  final List<String> memberOnlyContentIds;
  final DateTime updatedAt;
}

class CreatorAdPolicy {
  const CreatorAdPolicy({
    required this.channelId,
    required this.allowedCategories,
    required this.blockedCategories,
    required this.formats,
    required this.surfaces,
    required this.updatedAt,
  });

  final String channelId;
  final List<String> allowedCategories;
  final List<String> blockedCategories;
  final List<String> formats;
  final List<String> surfaces;
  final DateTime updatedAt;
}

class MembershipTier {
  const MembershipTier({
    required this.id,
    required this.channelId,
    required this.name,
    required this.monthlyPriceCents,
    required this.benefits,
    required this.entitlementCode,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String name;
  final int monthlyPriceCents;
  final List<String> benefits;
  final String entitlementCode;
  final DateTime createdAt;
}

class AIContentPolicy {
  const AIContentPolicy({
    required this.channelId,
    required this.archiveQaEnabled,
    required this.summariesEnabled,
    required this.citationRequired,
    required this.updatedAt,
  });

  final String channelId;
  final bool archiveQaEnabled;
  final bool summariesEnabled;
  final bool citationRequired;
  final DateTime updatedAt;
}
