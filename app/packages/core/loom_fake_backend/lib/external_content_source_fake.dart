import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, PublicImportedReferenceRecord;

class ExternalContentSourceFake implements ExternalContentSourceApi {
  const ExternalContentSourceFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<ExternalContentCandidate>> searchExternalContent({
    required String passportId,
    required String query,
    List<ExternalSourceType> sourceTypes = const [ExternalSourceType.youtube],
    int limit = 8,
  }) async {
    await Future<void>.delayed(latency);
    final records = await _store.externalContentCandidates(
      query: query,
      platforms: sourceTypes.map(_sourceTypeName).toList(growable: false),
      aiQueryableOnly: true,
      limit: limit,
    );
    return records.map(_mapExternalCandidate).toList(growable: false);
  }

  @override
  Future<ExternalContentCandidate> getExternalContent({
    required String referenceId,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.publicImportedReferenceById(referenceId);
    if (record == null) {
      throw StateError('No external content exists for $referenceId');
    }
    return _mapExternalCandidate(record);
  }
}

ExternalContentCandidate _mapExternalCandidate(
  PublicImportedReferenceRecord record,
) {
  return ExternalContentCandidate(
    targetRef: ExternalTargetRef(
      referenceId: record.referenceId,
      sourceType: _sourceType(record.platform),
      externalId: record.externalId,
    ),
    originalTitle: record.title,
    summary: record.description ?? record.title,
    thumbnailRef:
        record.thumbnailRef ?? 'seed://external/${record.referenceId}',
    sourceUrl: record.sourceUrl ?? '',
    sourceAttribution:
        record.sourceAttribution ?? _sourceAttributionLabel(record.platform),
    rightsBasis: record.rightsBasis,
    searchIndexable: record.searchIndexable,
    aiQueryable: record.aiQueryable,
    embedDescriptor: EmbedDescriptor(
      kind: _embedKind(record.embedKind),
      externalId: record.externalId,
      sourceUrl: record.sourceUrl ?? '',
    ),
    createdAt: record.publishedAt ?? DateTime.utc(2026, 5, 31, 12),
    creatorId: record.channelId,
    creatorName: null,
    accurateMatchLabel: record.accurateMatchLabel,
    creatorNote: record.creatorNote,
  );
}

String _sourceTypeName(ExternalSourceType sourceType) {
  switch (sourceType) {
    case ExternalSourceType.youtube:
      return 'youtube';
    case ExternalSourceType.twitch:
      return 'twitch';
    case ExternalSourceType.discord:
      return 'discord';
    case ExternalSourceType.blog:
      return 'blog';
    case ExternalSourceType.webpage:
      return 'webpage';
  }
}

ExternalSourceType _sourceType(String value) {
  switch (value) {
    case 'twitch':
      return ExternalSourceType.twitch;
    case 'discord':
      return ExternalSourceType.discord;
    case 'blog':
      return ExternalSourceType.blog;
    case 'webpage':
      return ExternalSourceType.webpage;
  }
  return ExternalSourceType.youtube;
}

EmbedKind _embedKind(String? value) {
  switch (value) {
    case 'youtube_iframe':
      return EmbedKind.youtubeIframe;
  }
  return EmbedKind.link;
}

String _sourceAttributionLabel(String platform) {
  switch (platform) {
    case 'youtube':
      return 'YouTube';
    case 'twitch':
      return 'Twitch';
    case 'discord':
      return 'Discord';
    case 'blog':
      return 'Creator blog';
    case 'webpage':
      return 'Open web';
  }
  return platform;
}
