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

  @override
  Future<ExternalContentCandidate> resolveExternalContentLink({
    required String channelId,
    required ExternalSourceType sourceType,
    required String input,
    required String creatorNote,
    required bool searchIndexable,
    required bool aiQueryable,
  }) async {
    await Future<void>.delayed(latency);
    return _candidateForInput(
      store: _store,
      channelId: channelId,
      sourceType: sourceType,
      input: input,
      creatorNote: creatorNote,
      searchIndexable: searchIndexable,
      aiQueryable: aiQueryable,
    );
  }

  @override
  Future<ExternalContentCandidate> linkCreatorExternalContent({
    required String channelId,
    required ExternalSourceType sourceType,
    required String input,
    required String creatorNote,
    required bool searchIndexable,
    required bool aiQueryable,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final preview = await _candidateForInput(
      store: _store,
      channelId: channelId,
      sourceType: sourceType,
      input: input,
      creatorNote: creatorNote,
      searchIndexable: searchIndexable,
      aiQueryable: aiQueryable,
    );
    final record = await _store.upsertExternalReference(
      channelId: channelId,
      platform: _sourceTypeName(sourceType),
      externalId: preview.targetRef.externalId,
      title: preview.originalTitle,
      description: preview.summary,
      thumbnailRef: preview.thumbnailRef,
      sourceUrl: preview.sourceUrl,
      rightsBasis: 'creator_linked_public_reference',
      searchIndexable: searchIndexable,
      aiQueryable: aiQueryable,
      sourceAttribution: preview.sourceAttribution,
      embedKind: _embedKindName(preview.embedDescriptor.kind),
      accurateMatchLabel: preview.accurateMatchLabel,
      creatorNote: creatorNote,
      idempotencyKey: idempotencyKey,
    );
    return _mapExternalCandidate(record);
  }
}

Future<ExternalContentCandidate> _candidateForInput({
  required DemoLocalStore store,
  required String channelId,
  required ExternalSourceType sourceType,
  required String input,
  required String creatorNote,
  required bool searchIndexable,
  required bool aiQueryable,
}) async {
  final sourceName = _sourceTypeName(sourceType);
  final parsed = _parseExternalInput(input, sourceType);
  final candidates = await store.externalContentCandidates(
    query: input,
    platforms: [sourceName],
    aiQueryableOnly: false,
    limit: 12,
  );
  final existing = candidates
      .where(
        (candidate) =>
            candidate.channelId == channelId ||
            candidate.externalId == parsed.externalId,
      )
      .firstOrNull;
  final title = existing?.title ?? _fallbackTitle(sourceType, parsed);
  final description =
      existing?.description ??
      'Creator-linked public reference from ${_sourceAttributionLabel(sourceName)}.';
  final thumbnailRef =
      existing?.thumbnailRef ??
      'seed://external/${channelId}_${parsed.externalId}';
  return ExternalContentCandidate(
    targetRef: ExternalTargetRef(
      referenceId:
          existing?.referenceId ?? 'preview_${channelId}_${parsed.externalId}',
      sourceType: sourceType,
      externalId: parsed.externalId,
    ),
    originalTitle: title,
    summary: description,
    thumbnailRef: thumbnailRef,
    sourceUrl: parsed.sourceUrl,
    sourceAttribution:
        existing?.sourceAttribution ?? _sourceAttributionLabel(sourceName),
    rightsBasis: 'creator_linked_public_reference',
    searchIndexable: searchIndexable,
    aiQueryable: aiQueryable,
    embedDescriptor: EmbedDescriptor(
      kind: _embedKindFor(sourceType),
      externalId: parsed.externalId,
      sourceUrl: parsed.sourceUrl,
    ),
    createdAt: DateTime.utc(2026, 5, 31, 12),
    creatorId: channelId,
    accurateMatchLabel:
        existing?.accurateMatchLabel ?? 'Creator-linked public reference',
    creatorNote: creatorNote,
  );
}

class _ParsedExternalInput {
  const _ParsedExternalInput({
    required this.externalId,
    required this.sourceUrl,
  });

  final String externalId;
  final String sourceUrl;
}

_ParsedExternalInput _parseExternalInput(
  String input,
  ExternalSourceType sourceType,
) {
  final trimmed = input.trim();
  if (sourceType == ExternalSourceType.youtube) {
    final watchMatch = RegExp(r'[?&]v=([^&#]+)').firstMatch(trimmed);
    final shortMatch = RegExp(r'youtu\.be/([^?&#/]+)').firstMatch(trimmed);
    final embedMatch = RegExp(
      r'youtube\.com/embed/([^?&#/]+)',
    ).firstMatch(trimmed);
    final id =
        watchMatch?.group(1) ??
        shortMatch?.group(1) ??
        embedMatch?.group(1) ??
        _slug(trimmed);
    return _ParsedExternalInput(
      externalId: id,
      sourceUrl: 'https://www.youtube.com/watch?v=$id',
    );
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return _ParsedExternalInput(externalId: _slug(trimmed), sourceUrl: trimmed);
  }
  final sourceName = _sourceTypeName(sourceType);
  return _ParsedExternalInput(
    externalId: _slug(trimmed),
    sourceUrl: 'https://$sourceName.example/${_slug(trimmed)}',
  );
}

String _fallbackTitle(
  ExternalSourceType sourceType,
  _ParsedExternalInput input,
) {
  return '${_sourceAttributionLabel(_sourceTypeName(sourceType))} reference: ${input.externalId}';
}

EmbedKind _embedKindFor(ExternalSourceType sourceType) {
  return sourceType == ExternalSourceType.youtube
      ? EmbedKind.youtubeIframe
      : EmbedKind.link;
}

String _embedKindName(EmbedKind kind) {
  switch (kind) {
    case EmbedKind.youtubeIframe:
      return 'youtube_iframe';
    case EmbedKind.link:
      return 'link';
  }
}

String _slug(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'external' : normalized;
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
