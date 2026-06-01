import '../models/migration_export/import_models.dart';

abstract class MigrationExportApi {
  Future<ImportJob> startImportJob({
    required String channelId,
    required String sourcePlatform,
    required String idempotencyKey,
  });

  Future<ImportJob> getImportJob(String jobId);

  Future<ExportJob> createExportJob({
    required String creatorId,
    required String idempotencyKey,
  });

  Future<ExportJob> getExportJob(String jobId);

  Future<void> resetDemo({required String idempotencyKey});
}
