import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart' hide ImportJob;

class MigrationExportFake implements MigrationExportApi {
  const MigrationExportFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<ImportJob> startImportJob({
    required String channelId,
    required String sourcePlatform,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.startImportJob(
      channelId: channelId,
      sourcePlatform: sourcePlatform,
      idempotencyKey: idempotencyKey,
    );
    return _mapImportJob(record);
  }

  @override
  Future<ImportJob> getImportJob(String jobId) async {
    await Future<void>.delayed(latency);
    final record = await _store.advanceImportJob(jobId);
    return _mapImportJob(record);
  }
}

ImportJob _mapImportJob(ImportJobRecord record) {
  return ImportJob(
    id: record.id,
    channelId: record.channelId,
    sourcePlatform: record.sourcePlatform,
    state: _mapState(record.state),
    references: record.references.map(_mapExternalRef).toList(growable: false),
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  );
}

ExternalContentReference _mapExternalRef(ExternalContentRefRecord record) {
  return ExternalContentReference(
    id: record.id,
    jobId: record.jobId,
    channelId: record.channelId,
    sourcePlatform: record.sourcePlatform,
    externalId: record.externalId,
    contentId: record.contentId,
    title: record.title,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}

ImportJobState _mapState(String value) {
  return switch (value) {
    'complete' => ImportJobState.complete,
    'queued' => ImportJobState.queued,
    _ => ImportJobState.processing,
  };
}
