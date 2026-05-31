enum ContentType { video, post }

class ContentSummaryView {
  const ContentSummaryView({
    required this.id,
    required this.creatorId,
    required this.creatorDisplayName,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.contentType,
  });

  final String id;
  final String creatorId;
  final String creatorDisplayName;
  final String title;
  final String summary;
  final String thumbnailRef;
  final ContentType contentType;
}
