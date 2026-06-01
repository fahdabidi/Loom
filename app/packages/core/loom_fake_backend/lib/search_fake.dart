import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, SearchIndexEntryRecord;

class SearchFake implements SearchApi {
  const SearchFake(
    this._store, {
    this.latency = const Duration(milliseconds: 80),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<Page<SearchResult>> search({
    required String passportId,
    required String query,
    String? cursor,
    int pageSize = 10,
  }) async {
    await Future<void>.delayed(latency);
    await _store.ensureDemoPassport(passportId: passportId);
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final records = await _store.searchIndex(
      query: query,
      limit: pageSize,
      offset: offset,
    );
    final nextOffset = offset + records.length;
    return Page(
      items: records
          .map((record) => _mapSearchResult(record, query))
          .toList(growable: false),
      nextCursor: records.length == pageSize ? '$nextOffset' : null,
    );
  }
}

SearchResult _mapSearchResult(SearchIndexEntryRecord record, String query) {
  final terms = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
  return SearchResult(
    tile: ContentTile(
      contentId: record.contentId,
      creatorId: record.creatorId,
      creatorName: record.creatorName,
      title: record.title,
      summary: record.summary,
      contentTypeLabel: record.contentType == 'video' ? 'Video' : 'Post',
      thumbnailRef: record.thumbnailRef,
      createdAt: record.updatedAt,
    ),
    matchedTerms: terms,
    neutralityLabel: 'Neutral search: no ads, boosts, or paid placement.',
  );
}
