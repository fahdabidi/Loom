import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    RecommendationReferralApi? recommendationApi,
    SearchApi? searchApi,
    FanVaultApi? fanVaultApi,
    AiGatewayApi? aiGatewayApi,
    this.passportId = 'passport_demo_fan',
  }) : _recommendationApi =
           recommendationApi ?? resolveRecommendationReferralApi(),
       _searchApi = searchApi ?? resolveSearchApi(),
       _fanVaultApi = fanVaultApi ?? resolveFanVaultApi(),
       _aiGatewayApi = aiGatewayApi ?? resolveAiGatewayApi();

  final RecommendationReferralApi _recommendationApi;
  final SearchApi _searchApi;
  final FanVaultApi _fanVaultApi;
  final AiGatewayApi _aiGatewayApi;
  final String passportId;

  bool loading = false;
  bool loadingMore = false;
  bool selectingIntent = false;
  String? errorMessage;
  List<PlatformIntent> startupTiles = const [];
  SessionIntent? sessionIntent;
  List<FeedItem> feedItems = const [];
  String? _nextCursor;
  List<SearchResult> searchResults = const [];
  AiSearchResult? aiSearchResult;
  String searchQuery = '';
  bool searchLoading = false;
  String? searchErrorMessage;
  RankPreference? rankPreference;
  int? summaryRankCandidateCount;
  DiscoveryReceipt? latestDiscoveryReceipt;
  String? recommendationMessage;

  bool get hasMore => _nextCursor != null;

  Future<void> bootstrap() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      startupTiles = await _recommendationApi.getStartupTiles(
        passportId: passportId,
      );
      rankPreference = await _fanVaultApi.getRankPreference(passportId);
      if (startupTiles.isNotEmpty) {
        await selectIntent(startupTiles.first);
      }
    } catch (error) {
      errorMessage = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectIntent(PlatformIntent intent) async {
    if (selectingIntent) {
      return;
    }
    selectingIntent = true;
    notifyListeners();
    try {
      final current = sessionIntent;
      if (current == null) {
        sessionIntent = await _recommendationApi.createSessionIntent(
          passportId: passportId,
          platformIntentId: intent.id,
          idempotencyKey: 'p3-session-${intent.id}',
        );
      } else {
        sessionIntent = await _recommendationApi.switchSessionIntent(
          sessionIntentId: current.id,
          platformIntentId: intent.id,
          idempotencyKey: 'p3-switch-${current.id}-${intent.id}',
        );
      }
      await refreshFeed();
    } finally {
      selectingIntent = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeed() async {
    final session = sessionIntent;
    if (session == null) {
      return;
    }
    final page = await _recommendationApi.getFeed(
      sessionIntentId: session.id,
      pageSize: 5,
    );
    final ranked = await _applySummaryPreference(page.items);
    feedItems = ranked.items;
    summaryRankCandidateCount = ranked.candidateCount;
    _nextCursor = page.nextCursor;
    notifyListeners();
  }

  Future<void> loadMore() async {
    final session = sessionIntent;
    if (session == null || _nextCursor == null || loadingMore) {
      return;
    }
    loadingMore = true;
    notifyListeners();
    try {
      final page = await _recommendationApi.getFeed(
        sessionIntentId: session.id,
        cursor: _nextCursor,
        pageSize: 5,
      );
      final ranked = await _applySummaryPreference(page.items);
      feedItems = [...feedItems, ...ranked.items];
      summaryRankCandidateCount =
          (summaryRankCandidateCount ?? 0) + ranked.candidateCount;
      _nextCursor = page.nextCursor;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> submitFeedback(
    FeedItem item,
    FeedbackAction action, {
    bool refresh = true,
  }) async {
    final session = sessionIntent;
    if (session == null) {
      return;
    }
    await _recommendationApi.submitFeedback(
      sessionIntentId: session.id,
      contentId: item.tile.contentId,
      action: action,
      idempotencyKey:
          'p3-feedback-${session.id}-${item.tile.contentId}-$action',
    );
    // Likes never refresh (they boost ranking on the next fetch).
    // refresh:false lets the Hover-mode swipe-to-dismiss remove the tile
    // optimistically without collapsing the grid to a fresh pageSize-5 page.
    if (refresh && action != FeedbackAction.like) {
      await refreshFeed();
    }
  }

  /// Removes [item] from the visible feed in place (optimistic Hover-mode
  /// dismiss). The grid reflows on the next rebuild.
  void removeFeedItem(FeedItem item) {
    feedItems = [...feedItems]
      ..removeWhere((e) => e.tile.contentId == item.tile.contentId);
    notifyListeners();
  }

  /// Re-inserts [item] at [index] (undo of a dismiss). Clamps to valid range.
  void insertFeedItem(FeedItem item, int index) {
    final next = [...feedItems];
    next.insert(index.clamp(0, next.length), item);
    feedItems = next;
    notifyListeners();
  }

  /// Fetches the next ranked page and appends only items not already shown.
  /// Called after a like commit so a like-boosted item can surface at the end
  /// of the grid without disturbing existing tiles.
  Future<void> pullAdditionalContent() async {
    final session = sessionIntent;
    if (session == null || _nextCursor == null) {
      return;
    }
    final page = await _recommendationApi.getFeed(
      sessionIntentId: session.id,
      cursor: _nextCursor,
      pageSize: 5,
    );
    final ranked = await _applySummaryPreference(page.items);
    final seen = feedItems.map((e) => e.tile.contentId).toSet();
    final fresh = ranked.items
        .where((e) => !seen.contains(e.tile.contentId))
        .toList(growable: false);
    if (fresh.isNotEmpty) {
      feedItems = [...feedItems, ...fresh];
      summaryRankCandidateCount =
          (summaryRankCandidateCount ?? 0) + fresh.length;
    }
    _nextCursor = page.nextCursor;
    notifyListeners();
  }

  Future<void> recordRecommendedDiscovery(FeedItem item) async {
    if (!item.providerLabel.startsWith('Recommended by ')) {
      return;
    }
    latestDiscoveryReceipt = await _recommendationApi.recordDiscovery(
      manifestId: item.providerId,
      passportId: passportId,
      idempotencyKey: 'p8-discovery-${item.providerId}-$passportId',
    );
    recommendationMessage = '${item.providerLabel} receipt recorded.';
    notifyListeners();
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    searchQuery = normalizedQuery;
    if (normalizedQuery.isEmpty) {
      searchResults = const [];
      aiSearchResult = null;
      searchErrorMessage = null;
      notifyListeners();
      return;
    }
    searchLoading = true;
    searchErrorMessage = null;
    notifyListeners();
    try {
      final config = await _fanVaultApi.getSearchAgentConfig(passportId);
      if (config.connected) {
        aiSearchResult = await _aiGatewayApi.runAiSearch(
          passportId: passportId,
          query: normalizedQuery,
        );
        searchResults = const [];
      } else {
        final page = await _searchApi.search(
          passportId: passportId,
          query: normalizedQuery,
        );
        searchResults = page.items;
        aiSearchResult = null;
      }
    } catch (error) {
      searchErrorMessage = '$error';
      searchResults = const [];
      aiSearchResult = null;
    } finally {
      searchLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSummaryFirst(bool enabled) async {
    rankPreference = await _fanVaultApi.putRankPreference(
      passportId: passportId,
      summaryFirst: enabled,
      idempotencyKey: 'p5-rank-$passportId-$enabled',
    );
    await refreshFeed();
  }

  Future<SummaryRankResult> _applySummaryPreference(
    List<FeedItem> items,
  ) async {
    final preference =
        rankPreference ??
        RankPreference(
          passportId: passportId,
          summaryFirst: false,
          updatedAt: DateTime.now().toUtc(),
        );
    if (!preference.summaryFirst) {
      return SummaryRankResult(
        preference: preference,
        items: items,
        candidateCount: items.length,
      );
    }
    return _aiGatewayApi.rankBySummary(
      preference: preference,
      candidates: items,
    );
  }
}
