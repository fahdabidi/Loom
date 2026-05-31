import 'package:loom_api_contracts/loom_api_contracts.dart';

class ContentTileViewModel {
  const ContentTileViewModel({
    required this.id,
    required this.creatorName,
    required this.title,
    required this.summary,
    required this.contentTypeLabel,
    required this.thumbnailRef,
  });

  final String id;
  final String creatorName;
  final String title;
  final String summary;
  final String contentTypeLabel;
  final String thumbnailRef;
}

ContentTileViewModel mapContentSummary(ContentSummaryView item) {
  return ContentTileViewModel(
    id: item.id,
    creatorName: item.creatorDisplayName,
    title: item.title,
    summary: item.summary,
    contentTypeLabel: switch (item.contentType) {
      ContentType.video => 'Video',
      ContentType.post => 'Post',
    },
    thumbnailRef: item.thumbnailRef,
  );
}
