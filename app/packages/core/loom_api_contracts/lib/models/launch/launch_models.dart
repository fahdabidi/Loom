class CaptureLink {
  const CaptureLink({
    required this.token,
    required this.channelId,
    required this.url,
    required this.channel,
    required this.qrPayload,
    required this.starterPackEnabled,
    required this.createdAt,
    this.expiresAt,
  });

  final String token;
  final String channelId;
  final String url;
  final String channel;
  final String qrPayload;
  final bool starterPackEnabled;
  final DateTime createdAt;
  final DateTime? expiresAt;
}

class CaptureLandingView {
  const CaptureLandingView({
    required this.channelId,
    required this.handle,
    required this.displayName,
    required this.avatarRef,
    required this.tagline,
    required this.alreadyFollowing,
    this.starterPackToken,
  });

  final String channelId;
  final String handle;
  final String displayName;
  final String avatarRef;
  final String tagline;
  final bool alreadyFollowing;
  final String? starterPackToken;
}

enum ReFollowState { followed, alreadyFollowing }

class ReFollowResult {
  const ReFollowResult({
    required this.channelId,
    required this.followState,
    required this.pairwiseCreatorFanId,
    required this.auditReceiptId,
    required this.createdAt,
  });

  final String channelId;
  final ReFollowState followState;
  final String pairwiseCreatorFanId;
  final String auditReceiptId;
  final DateTime createdAt;
}

class AnnouncementTemplate {
  const AnnouncementTemplate({
    required this.templateId,
    required this.name,
    required this.channel,
    required this.body,
    required this.placeholders,
  });

  final String templateId;
  final String name;
  final String channel;
  final String body;
  final List<String> placeholders;
}

class RenderedAnnouncement {
  const RenderedAnnouncement({
    required this.announcementId,
    required this.channelId,
    required this.channel,
    required this.renderedBody,
    required this.captureLinkUrl,
    required this.qrPayload,
    required this.createdAt,
  });

  final String announcementId;
  final String channelId;
  final String channel;
  final String renderedBody;
  final String captureLinkUrl;
  final String qrPayload;
  final DateTime createdAt;
}

class LinkInBioLink {
  const LinkInBioLink({required this.label, required this.url});

  final String label;
  final String url;
}

class LinkInBioPage {
  const LinkInBioPage({
    required this.channelId,
    required this.handle,
    required this.displayName,
    required this.avatarRef,
    required this.captureLinkUrl,
    required this.qrPayload,
    required this.externalLinks,
  });

  final String channelId;
  final String handle;
  final String displayName;
  final String avatarRef;
  final String captureLinkUrl;
  final String qrPayload;
  final List<LinkInBioLink> externalLinks;
}

enum StarterPackMemberRole { source, recommended }

class StarterPackMember {
  const StarterPackMember({
    required this.channelId,
    required this.handle,
    required this.displayName,
    required this.avatarRef,
    required this.role,
    required this.defaultSelected,
    required this.alreadyFollowing,
    this.recommendationReason,
  });

  final String channelId;
  final String handle;
  final String displayName;
  final String avatarRef;
  final StarterPackMemberRole role;
  final bool defaultSelected;
  final bool alreadyFollowing;
  final String? recommendationReason;
}

class StarterPack {
  const StarterPack({
    required this.sourceChannelId,
    required this.members,
    this.starterPackToken,
  });

  final String sourceChannelId;
  final String? starterPackToken;
  final List<StarterPackMember> members;
}

class BulkFollowResult {
  const BulkFollowResult({
    required this.followed,
    required this.alreadyFollowing,
    required this.feedReady,
  });

  final List<String> followed;
  final List<String> alreadyFollowing;
  final bool feedReady;
}

class ConversionStage {
  const ConversionStage({
    required this.stage,
    required this.count,
    required this.conversionFromPrevious,
  });

  final String stage;
  final int count;
  final double? conversionFromPrevious;
}

class ConversionFunnel {
  const ConversionFunnel({
    required this.channelId,
    required this.aggregateOnly,
    required this.startsAt,
    required this.endsAt,
    required this.stages,
    required this.byChannelSource,
  });

  final String channelId;
  final bool aggregateOnly;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<ConversionStage> stages;
  final Map<String, int> byChannelSource;
}

class ExternalAccountLink {
  const ExternalAccountLink({
    required this.linkId,
    required this.channelId,
    required this.platform,
    required this.handle,
    required this.verificationState,
    required this.linkedAt,
    this.profileUrl,
  });

  final String linkId;
  final String channelId;
  final String platform;
  final String handle;
  final String? profileUrl;
  final String verificationState;
  final DateTime linkedAt;
}

class PublicMetadataImportJob {
  const PublicMetadataImportJob({
    required this.jobId,
    required this.channelId,
    required this.status,
    required this.importedCount,
    required this.skippedCount,
    this.message,
  });

  final String jobId;
  final String channelId;
  final String status;
  final int importedCount;
  final int skippedCount;
  final String? message;
}

class PublicImportedReference {
  const PublicImportedReference({
    required this.referenceId,
    required this.platform,
    required this.externalId,
    required this.title,
    required this.rightsBasis,
    required this.searchIndexable,
    required this.aiQueryable,
    this.description,
    this.thumbnailRef,
    this.sourceUrl,
    this.publishedAt,
  });

  final String referenceId;
  final String platform;
  final String externalId;
  final String title;
  final String rightsBasis;
  final bool searchIndexable;
  final bool aiQueryable;
  final String? description;
  final String? thumbnailRef;
  final String? sourceUrl;
  final DateTime? publishedAt;
}

class CrossPostTarget {
  const CrossPostTarget({
    required this.targetLinkId,
    required this.platform,
    required this.deliveryStatus,
    this.externalPostUrl,
    this.message,
  });

  final String targetLinkId;
  final String platform;
  final String deliveryStatus;
  final String? externalPostUrl;
  final String? message;
}

class CrossPost {
  const CrossPost({
    required this.crossPostId,
    required this.channelId,
    required this.message,
    required this.createdAt,
    required this.targets,
    this.announcementId,
    this.contentRef,
    this.captureLinkUrl,
  });

  final String crossPostId;
  final String channelId;
  final String message;
  final DateTime createdAt;
  final List<CrossPostTarget> targets;
  final String? announcementId;
  final String? contentRef;
  final String? captureLinkUrl;
}

class SelectedAd {
  const SelectedAd({
    required this.adId,
    required this.brand,
    required this.category,
    required this.disclosure,
    required this.selectionBasis,
  });

  final String adId;
  final String brand;
  final String category;
  final String disclosure;
  final String selectionBasis;
}

class AdDecision {
  const AdDecision({
    required this.decisionId,
    required this.contentId,
    required this.ads,
    this.policyVersion,
  });

  final String decisionId;
  final String contentId;
  final List<SelectedAd> ads;
  final String? policyVersion;
}

class AdImpressionResult {
  const AdImpressionResult({
    required this.adId,
    required this.recorded,
    this.receiptId,
  });

  final String adId;
  final bool recorded;
  final String? receiptId;
}

class PremiumNoAdStatus {
  const PremiumNoAdStatus({
    required this.fanId,
    required this.active,
    this.entitlementId,
    this.since,
    this.renewsAt,
  });

  final String fanId;
  final bool active;
  final String? entitlementId;
  final DateTime? since;
  final DateTime? renewsAt;
}

class PremiumNoAdViewResult {
  const PremiumNoAdViewResult({
    required this.contentId,
    required this.noAdApplied,
    this.receiptId,
  });

  final String contentId;
  final bool noAdApplied;
  final String? receiptId;
}
