enum ImportJobState { queued, processing, complete }

class ExternalContentReference {
  const ExternalContentReference({
    required this.id,
    required this.jobId,
    required this.channelId,
    required this.sourcePlatform,
    required this.externalId,
    required this.contentId,
    required this.title,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String channelId;
  final String sourcePlatform;
  final String externalId;
  final String contentId;
  final String title;
  final String summary;
  final DateTime createdAt;
}

class ImportJob {
  const ImportJob({
    required this.id,
    required this.channelId,
    required this.sourcePlatform,
    required this.state,
    required this.references,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String sourcePlatform;
  final ImportJobState state;
  final List<ExternalContentReference> references;
  final DateTime createdAt;
  final DateTime updatedAt;
}
