import '../models/external_content/external_content_models.dart';

abstract class ExternalContentSourceApi {
  Future<List<ExternalContentCandidate>> searchExternalContent({
    required String passportId,
    required String query,
    List<ExternalSourceType> sourceTypes = const [ExternalSourceType.youtube],
    int limit = 8,
  });

  Future<ExternalContentCandidate> getExternalContent({
    required String referenceId,
  });
}
