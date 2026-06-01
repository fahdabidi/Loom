import '../creator_metadata/content_summary_view.dart';

class PlaybackAsset {
  const PlaybackAsset({
    required this.assetId,
    required this.channelId,
    required this.contentType,
    required this.fileName,
    required this.thumbnailRef,
    required this.createdAt,
  });

  final String assetId;
  final String channelId;
  final ContentType contentType;
  final String fileName;
  final String thumbnailRef;
  final DateTime createdAt;
}

class ContentPerformanceMetadata {
  const ContentPerformanceMetadata({
    required this.contentId,
    required this.velocity,
    required this.completionRate,
    required this.saves,
    required this.shares,
    required this.updatedAt,
  });

  final String contentId;
  final double velocity;
  final double completionRate;
  final int saves;
  final int shares;
  final DateTime updatedAt;
}

class TrendingStats {
  const TrendingStats({
    required this.contentId,
    required this.velocity,
    required this.completionRate,
    required this.saves,
    required this.shares,
    required this.rankLabel,
    required this.updatedAt,
  });

  final String contentId;
  final double velocity;
  final double completionRate;
  final int saves;
  final int shares;
  final String rankLabel;
  final DateTime updatedAt;
}
