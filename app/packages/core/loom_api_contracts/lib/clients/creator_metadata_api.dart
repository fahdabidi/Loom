import '../models/creator_metadata/content_summary_view.dart';
import '../models/creator_metadata/creator_channel_manifest.dart';
import '../models/creator_metadata/hosting_contract.dart';
import '../models/creator_metadata/phase2_models.dart';
import '../models/creator_metadata/phase4_models.dart';
import '../models/shared/page.dart';

abstract class CreatorMetadataApi {
  Future<Page<ContentSummaryView>> getPublicCatalog(
    String channelId, {
    String? cursor,
    int limit = 10,
  });

  Future<ChannelHome> getChannelHome({
    required String channelId,
    required String passportId,
  });

  Future<ContentDetail> getContentDetail(String contentId);

  Future<CreatorChannelManifest> createChannelProfile({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required String idempotencyKey,
  });

  Future<HostingContract> attachHostingContract({
    required String channelId,
    required String provider,
    required String termsVersion,
    required String idempotencyKey,
  });

  Future<ContentManifest> publishContent({
    required String channelId,
    required ContentType contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required ContentAccessMode accessMode,
    required MonetizationMode monetizationMode,
    required String idempotencyKey,
  });

  Future<MonetizationManifest> updateMonetizationManifest({
    required String channelId,
    required bool membershipsEnabled,
    required List<String> memberOnlyContentIds,
    required String idempotencyKey,
  });

  Future<List<MembershipTier>> defineMembershipTiers({
    required String channelId,
    required List<MembershipTierDraft> tiers,
    required String idempotencyKey,
  });

  Future<CreatorAdPolicy> setCreatorAdPolicy({
    required String channelId,
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    required List<String> formats,
    required List<String> surfaces,
    required String idempotencyKey,
  });

  Future<AIContentPolicy> setAIContentPolicy({
    required String channelId,
    required bool archiveQaEnabled,
    required bool summariesEnabled,
    required bool citationRequired,
    required String idempotencyKey,
  });

  Future<List<ContentManifest>> contentManifests(String channelId);

  Future<List<MembershipTier>> membershipTiers(String channelId);

  Future<CreatorAdPolicy?> creatorAdPolicy(String channelId);

  Future<AIContentPolicy?> aiContentPolicy(String channelId);
}

class MembershipTierDraft {
  const MembershipTierDraft({
    required this.name,
    required this.monthlyPriceCents,
    required this.benefits,
    required this.entitlementCode,
  });

  final String name;
  final int monthlyPriceCents;
  final List<String> benefits;
  final String entitlementCode;
}
