import '../models/search/search_models.dart';
import '../models/shared/page.dart';

abstract class SearchApi {
  Future<Page<SearchResult>> search({
    required String passportId,
    required String query,
    String? cursor,
    int pageSize = 10,
  });
}
