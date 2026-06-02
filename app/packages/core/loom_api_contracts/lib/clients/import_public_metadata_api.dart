import '../models/launch/launch_models.dart';

abstract class ImportPublicMetadataApi {
  Future<PublicMetadataImportJob> startImport({
    required String channelId,
    required String externalAccountLinkId,
    required String rightsBasis,
    int maxItems = 500,
    required String idempotencyKey,
  });

  Future<PublicMetadataImportJob> getImportJob({
    required String channelId,
    required String jobId,
  });

  Future<List<PublicImportedReference>> listImportedReferences({
    required String channelId,
    String? jobId,
  });
}
