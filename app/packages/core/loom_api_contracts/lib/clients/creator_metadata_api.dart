import '../models/creator_metadata/content_summary_view.dart';
import '../models/shared/page.dart';

abstract class CreatorMetadataApi {
  Future<Page<ContentSummaryView>> getPublicCatalog(
    String channelId, {
    String? cursor,
    int limit = 10,
  });
}
