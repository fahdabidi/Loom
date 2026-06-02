import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        AiSessionRecord,
        DemoLocalStore,
        PublicImportedReferenceRecord,
        ReceiptRecord,
        SearchIndexEntryRecord,
        TranscriptRecord,
        TranscriptSegmentRecord;

class AiGatewayFake implements AiGatewayApi {
  const AiGatewayFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<SummaryDraft> generateSummaryDraft({
    required String title,
    required String sourceNote,
  }) async {
    await Future<void>.delayed(latency);
    return SummaryDraft(
      title: title,
      summary:
          'A creator-approved draft summary for "$title" that explains the setup, audience value, and why the content is ready for discovery.',
    );
  }

  @override
  Future<ArchiveAnswer> askArchive({
    required String passportId,
    required String creatorId,
    required String question,
    required String policyRef,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final creator = await _store.creatorById(creatorId);
    if (creator == null) {
      throw StateError('No creator exists for $creatorId');
    }

    final transcripts = await _store.transcriptsForCreator(creatorId);
    if (transcripts.isEmpty) {
      throw StateError('No archive transcripts exist for $creatorId');
    }

    final citations = <Citation>[];
    for (final transcript in _bestTranscripts(question, transcripts).take(2)) {
      final content = await _store.contentById(transcript.contentId);
      final segment = _bestSegment(question, transcript);
      if (content == null || segment == null) {
        continue;
      }
      citations.add(
        Citation(
          contentId: content.id,
          creatorId: creator.id,
          creatorName: creator.displayName,
          title: content.title,
          segment: segment.text,
          startLabel: segment.startLabel,
          royaltyBasis: 'source-attribution:${content.id}',
        ),
      );
    }

    if (citations.isEmpty) {
      throw StateError('No cited archive segment could answer "$question"');
    }

    final answerText =
        '${creator.displayName} recommends starting with ${citations.first.title}: '
        '${citations.first.segment} The archive answer cites only the source '
        'segments used and follows $policyRef.';
    final session = await _store.createAiSession(
      passportId: passportId,
      creatorId: creatorId,
      question: question,
      answer: answerText,
      citationContentIds: citations.map((item) => item.contentId).toList(),
      idempotencyKey: idempotencyKey,
    );
    final receipts = await _store.ingestReceipts(
      records: _aiReceiptRecords(
        session: session,
        citations: citations,
        passportId: passportId,
      ),
      idempotencyKey: '$idempotencyKey-receipts',
    );

    return ArchiveAnswer(
      id: session.id,
      passportId: passportId,
      creatorId: creatorId,
      question: question,
      answer: answerText,
      confidenceLabel: 'Grounded in ${citations.length} cited sources',
      citations: citations,
      receipts: receipts.map(_mapReceipt).toList(growable: false),
      createdAt: session.createdAt,
    );
  }

  @override
  Future<SummaryRankResult> rankBySummary({
    required RankPreference preference,
    required List<FeedItem> candidates,
  }) async {
    await Future<void>.delayed(latency);
    if (!preference.summaryFirst) {
      return SummaryRankResult(
        preference: preference,
        items: candidates,
        candidateCount: candidates.length,
      );
    }

    final reranked = candidates.map(_summaryRankedItem).toList()
      ..sort((a, b) {
        final score = _summarySignalScore(b).compareTo(_summarySignalScore(a));
        if (score != 0) {
          return score;
        }
        return a.tile.title.compareTo(b.tile.title);
      });

    return SummaryRankResult(
      preference: preference,
      items: reranked,
      candidateCount: candidates.length,
    );
  }

  @override
  Future<AiSearchResult> runAiSearch({
    required String passportId,
    required String query,
    int limit = 10,
  }) async {
    await Future<void>.delayed(latency);
    final config = await _store.searchAgentConfig(passportId);
    if (!config.connected) {
      throw StateError('AI search agent is not connected for $passportId.');
    }

    final sourceConnections = await _store.externalSourceConnections(
      passportId,
    );
    final enabledPlatforms = config.externalSourcesEnabled
        ? sourceConnections
              .where((source) => source.connected)
              .map((source) => source.sourceType)
              .toList(growable: false)
        : const <String>[];
    final creatorLimit = config.preferCreators
        ? (limit * 0.7).ceil()
        : (limit / 2).ceil();
    final creatorRecords = await _store.searchIndex(
      query: query,
      limit: creatorLimit.clamp(1, limit),
    );
    final externalRecords = enabledPlatforms.isEmpty
        ? const <PublicImportedReferenceRecord>[]
        : await _store.externalContentCandidates(
            query: query,
            platforms: enabledPlatforms,
            aiQueryableOnly: true,
            limit: limit,
          );

    final items =
        <AiSearchItem>[
          ...creatorRecords.map(
            (record) => _aiCreatorItem(
              record,
              score: config.preferCreators ? 1.0 : 0.82,
            ),
          ),
          ...externalRecords.map(
            (record) => _aiExternalItem(
              record,
              score: config.preferCreators ? 0.72 : 0.9,
            ),
          ),
        ]..sort((a, b) {
          final score = b.score.compareTo(a.score);
          if (score != 0) {
            return score;
          }
          return a.originalTitle.compareTo(b.originalTitle);
        });

    final boundedItems = items.take(limit).toList(growable: false);
    final run = await _store.recordAiSearchRun(
      passportId: passportId,
      query: query,
      agentProvider: config.provider,
      resultRefs: boundedItems.map((item) => item.id).toList(growable: false),
      idempotencyKey:
          'ai-search-$passportId-${query.toLowerCase()}-${boundedItems.length}',
    );

    return AiSearchResult(
      runId: run.runId,
      query: query,
      neutralityLabel:
          'Ranked by your connected AI agent. No ads, boosts, or paid placement.',
      searchReceiptId: run.receiptId,
      items: boundedItems,
      generatedAt: run.createdAt,
    );
  }
}

AiSearchItem _aiCreatorItem(
  SearchIndexEntryRecord record, {
  required double score,
}) {
  final tile = ContentTile(
    contentId: record.contentId,
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    title: record.title,
    summary: record.summary,
    contentTypeLabel: _contentTypeLabel(record.contentType),
    thumbnailRef: record.thumbnailRef,
    createdAt: record.updatedAt,
  );
  return AiSearchItem(
    id: record.contentId,
    type: AiSearchItemType.creator,
    originalTitle: record.title,
    summary: record.summary,
    thumbnailRef: record.thumbnailRef,
    rankReason:
        'Creator-owned content matched the query and was preferred by your agent setting.',
    titleRiskSignals: _titleRiskSignals(record.title),
    sourceAttribution: record.creatorName,
    score: score,
    creatorTile: tile,
  );
}

AiSearchItem _aiExternalItem(
  PublicImportedReferenceRecord record, {
  required double score,
}) {
  return AiSearchItem(
    id: record.referenceId,
    type: AiSearchItemType.external,
    originalTitle: record.title,
    summary: record.description ?? record.title,
    thumbnailRef:
        record.thumbnailRef ?? 'seed://external/${record.referenceId}',
    rankReason:
        'External public reference matched the query; original title and thumbnail are preserved.',
    titleRiskSignals: _titleRiskSignals(record.title),
    sourceAttribution:
        record.sourceAttribution ?? _sourceAttributionLabel(record.platform),
    score: score,
    externalTargetRef: ExternalTargetRef(
      referenceId: record.referenceId,
      sourceType: _sourceType(record.platform),
      externalId: record.externalId,
    ),
    embedDescriptor: EmbedDescriptor(
      kind: _embedKind(record.embedKind),
      externalId: record.externalId,
      sourceUrl: record.sourceUrl ?? '',
    ),
    accurateMatchLabel:
        record.accurateMatchLabel ?? 'Accurate match from your AI agent',
    creatorNote: record.creatorNote,
  );
}

String _contentTypeLabel(String value) {
  switch (value) {
    case 'video':
      return 'Video';
    case 'post':
      return 'Post';
    case 'audio':
      return 'Audio';
  }
  return value;
}

List<String> _titleRiskSignals(String title) {
  final lower = title.toLowerCase();
  return [
    if (lower.contains('secret') || lower.contains('insane'))
      'Clickbait language checked',
    if (lower.contains('rage') || lower.contains('destroyed'))
      'Ragebait language checked',
  ];
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

Iterable<TranscriptRecord> _bestTranscripts(
  String question,
  List<TranscriptRecord> transcripts,
) {
  final terms = _terms(question);
  final ranked = transcripts.toList()
    ..sort(
      (a, b) =>
          _transcriptScore(b, terms).compareTo(_transcriptScore(a, terms)),
    );
  return ranked;
}

TranscriptSegmentRecord? _bestSegment(
  String question,
  TranscriptRecord transcript,
) {
  final terms = _terms(question);
  final segments = transcript.segments.toList()
    ..sort(
      (a, b) => _segmentScore(b, terms).compareTo(_segmentScore(a, terms)),
    );
  return segments.isEmpty ? null : segments.first;
}

int _transcriptScore(TranscriptRecord transcript, Set<String> terms) {
  return transcript.segments
      .map((segment) => _segmentScore(segment, terms))
      .fold(0, (total, score) => total + score);
}

int _segmentScore(TranscriptSegmentRecord segment, Set<String> terms) {
  final lower = segment.text.toLowerCase();
  return terms.where(lower.contains).length;
}

Set<String> _terms(String question) {
  return question
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((term) => term.length > 3)
      .toSet();
}

List<ReceiptRecord> _aiReceiptRecords({
  required AiSessionRecord session,
  required List<Citation> citations,
  required String passportId,
}) {
  final now = DateTime.now().toUtc();
  return [
    ReceiptRecord(
      id: 'receipt_ai_usage_${session.id}',
      type: 'aiUsage',
      passportId: passportId,
      contentId: citations.first.contentId,
      authorizationId: session.id,
      summary: 'AI archive answer generated with cited source segments.',
      createdAt: now,
    ),
    for (final citation in citations)
      ReceiptRecord(
        id: 'receipt_source_${session.id}_${citation.contentId}',
        type: 'sourceAttribution',
        passportId: passportId,
        contentId: citation.contentId,
        authorizationId: session.id,
        summary:
            'Source attribution royalty basis for ${citation.title}: ${citation.royaltyBasis}.',
        createdAt: now,
      ),
  ];
}

ReceiptView _mapReceipt(ReceiptRecord record) {
  return ReceiptView(
    id: record.id,
    type: _receiptType(record.type),
    passportId: record.passportId,
    contentId: record.contentId,
    authorizationId: record.authorizationId,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}

ReceiptType _receiptType(String value) {
  switch (value) {
    case 'playback':
      return ReceiptType.playback;
    case 'adImpression':
      return ReceiptType.adImpression;
    case 'aiUsage':
      return ReceiptType.aiUsage;
    case 'sourceAttribution':
      return ReceiptType.sourceAttribution;
    case 'payment':
      return ReceiptType.payment;
    case 'membership':
      return ReceiptType.membership;
    case 'premiumNoAd':
      return ReceiptType.premiumNoAd;
    case 'extensionHype':
      return ReceiptType.extensionHype;
    case 'discovery':
      return ReceiptType.discovery;
    case 'referral':
      return ReceiptType.referral;
    case 'campaignEntry':
      return ReceiptType.campaignEntry;
    case 'reward':
      return ReceiptType.reward;
  }
  return ReceiptType.playback;
}

FeedItem _summaryRankedItem(FeedItem item) {
  return FeedItem(
    tile: item.tile,
    score: item.score,
    providerId: item.providerId,
    providerLabel: item.providerLabel,
    isExternalCandidate: item.isExternalCandidate,
    trendingLabel: item.trendingLabel,
    explanation: ContentScoreExplanation(
      summary:
          'Summary-first BYO agent ranking used creator summaries and deemphasized clickbait title signals.',
      matchedSignals: [
        'Summary used for relevance',
        'Title deemphasized',
        ...item.explanation.matchedSignals,
      ],
      suppressedSignals: [
        ...item.explanation.suppressedSignals,
        'Clickbait title weighting',
      ],
      trendingVelocity: item.explanation.trendingVelocity,
    ),
  );
}

int _summarySignalScore(FeedItem item) {
  final summary = item.tile.summary.toLowerCase();
  final words = summary.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final howToBoost = summary.startsWith('how ') ? 100 : 0;
  final practicalBoost =
      [
        'checklist',
        'diagnose',
        'cues',
        'format',
        'fields',
        'workflow',
      ].where(summary.contains).length *
      18;
  final postBoost = item.tile.contentTypeLabel == 'Post' ? 12 : 0;
  return howToBoost + practicalBoost + postBoost + words.length;
}
