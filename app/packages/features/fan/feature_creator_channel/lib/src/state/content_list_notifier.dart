import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

import '../mappers/content_view_mapper.dart';

class ContentListState {
  const ContentListState({
    required this.items,
    required this.isLoading,
    required this.nextCursor,
    required this.errorMessage,
  });

  const ContentListState.initial()
    : items = const [],
      isLoading = false,
      nextCursor = null,
      errorMessage = null;

  final List<ContentTileViewModel> items;
  final bool isLoading;
  final String? nextCursor;
  final String? errorMessage;

  bool get canLoadMore => nextCursor != null && !isLoading;

  ContentListState copyWith({
    List<ContentTileViewModel>? items,
    bool? isLoading,
    String? nextCursor,
    bool clearNextCursor = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContentListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ContentListNotifier extends ChangeNotifier {
  ContentListNotifier({
    required CreatorMetadataApi api,
    required String channelId,
    this.pageSize = 3,
  }) : _api = api,
       _channelId = channelId;

  final CreatorMetadataApi _api;
  final String _channelId;
  final int pageSize;

  ContentListState _state = const ContentListState.initial();

  ContentListState get state => _state;

  Future<void> loadInitial() async {
    _state = const ContentListState.initial().copyWith(isLoading: true);
    notifyListeners();
    await _load(cursor: null, replace: true);
  }

  Future<void> loadMore() async {
    if (!_state.canLoadMore) {
      return;
    }
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();
    await _load(cursor: _state.nextCursor, replace: false);
  }

  Future<void> _load({required String? cursor, required bool replace}) async {
    try {
      final page = await _api.getPublicCatalog(
        _channelId,
        cursor: cursor,
        limit: pageSize,
      );
      final mapped = page.items.map(mapContentSummary).toList(growable: false);
      _state = ContentListState(
        items: replace ? mapped : [..._state.items, ...mapped],
        isLoading: false,
        nextCursor: page.nextCursor,
        errorMessage: null,
      );
    } on ApiError catch (error) {
      _state = _state.copyWith(isLoading: false, errorMessage: error.message);
    } on Object catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
    notifyListeners();
  }
}
