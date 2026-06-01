enum ImportJobState { queued, processing, complete }

enum ExportJobState { queued, processing, complete }

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

class ExportBundleSection {
  const ExportBundleSection({
    required this.label,
    required this.itemCount,
    required this.description,
  });

  final String label;
  final int itemCount;
  final String description;
}

class ExportBundle {
  const ExportBundle({
    required this.bundleRef,
    required this.creatorId,
    required this.creatorName,
    required this.generatedAt,
    required this.portableJson,
    required this.contentCount,
    required this.receiptCount,
    required this.settlementCount,
    required this.sections,
  });

  final String bundleRef;
  final String creatorId;
  final String creatorName;
  final DateTime generatedAt;
  final String portableJson;
  final int contentCount;
  final int receiptCount;
  final int settlementCount;
  final List<ExportBundleSection> sections;
}

class ExportJob {
  const ExportJob({
    required this.id,
    required this.creatorId,
    required this.state,
    required this.bundle,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final ExportJobState state;
  final ExportBundle? bundle;
  final DateTime createdAt;
  final DateTime updatedAt;
}
