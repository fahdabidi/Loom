import '../models/creator_metadata/content_summary_view.dart';
import '../models/creator_metadata/creator_channel_manifest.dart';
import '../models/creator_metadata/hosting_contract.dart';
import '../models/shared/page.dart';

abstract class CreatorMetadataApi {
  Future<Page<ContentSummaryView>> getPublicCatalog(
    String channelId, {
    String? cursor,
    int limit = 10,
  });

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
}
