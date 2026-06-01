import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    RecommendationReferralApi? recommendationApi,
    SearchApi? searchApi,
    this.passportId = 'passport_demo_fan',
  }) : _recommendationApi =
           recommendationApi ?? resolveRecommendationReferralApi(),
       _searchApi = searchApi ?? resolveSearchApi();

  final RecommendationReferralApi _recommendationApi;
  final SearchApi _searchApi;
  final String passportId;

  bool loading = false;
  bool loadingMore = false;
  String? errorMessage;
  List<PlatformIntent> startupTiles = const [];
  SessionIntent? sessionIntent;
  List<FeedItem> feedItems = const [];
  String? _nextCursor;
  List<SearchResult> searchResults = const [];
  String searchQuery = '';

  bool get hasMore => _nextCursor != null;

  Future<void> bootstrap() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      startupTiles = await _recommendationApi.getStartupTiles(
        passportId: passportId,
      );
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
    feedItems = page.items;
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
      feedItems = [...feedItems, ...page.items];
      _nextCursor = page.nextCursor;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> submitFeedback(FeedItem item, FeedbackAction action) async {
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
    if (action != FeedbackAction.like) {
      await refreshFeed();
    }
  }

  Future<void> search(String query) async {
    searchQuery = query;
    if (query.trim().isEmpty) {
      searchResults = const [];
      notifyListeners();
      return;
    }
    final page = await _searchApi.search(passportId: passportId, query: query);
    searchResults = page.items;
    notifyListeners();
  }
}
