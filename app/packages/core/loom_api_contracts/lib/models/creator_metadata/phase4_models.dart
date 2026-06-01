import 'content_summary_view.dart';
import 'phase2_models.dart';

class ChannelHome {
  const ChannelHome({
    required this.creatorId,
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.avatarRef,
    required this.isFollowed,
    required this.isBlocked,
    required this.visibilityLabel,
    required this.content,
    required this.adPolicy,
  });

  final String creatorId;
  final String displayName;
  final String handle;
  final String vertical;
  final String avatarRef;
  final bool isFollowed;
  final bool isBlocked;
  final String visibilityLabel;
  final List<ContentSummaryView> content;
  final CreatorAdPolicy? adPolicy;
}

class ContentDetail {
  const ContentDetail({
    required this.id,
    required this.creatorId,
    required this.creatorDisplayName,
    required this.title,
    required this.summary,
    required this.body,
    required this.thumbnailRef,
    required this.contentType,
    required this.createdAt,
  });

  final String id;
  final String creatorId;
  final String creatorDisplayName;
  final String title;
  final String summary;
  final String body;
  final String thumbnailRef;
  final ContentType contentType;
  final DateTime createdAt;
}
