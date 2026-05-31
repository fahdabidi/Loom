import '../models/migration_export/import_models.dart';

abstract class MigrationExportApi {
  Future<ImportJob> startImportJob({
    required String channelId,
    required String sourcePlatform,
    required String idempotencyKey,
  });

  Future<ImportJob> getImportJob(String jobId);
}
