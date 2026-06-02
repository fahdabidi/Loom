import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        DemoLocalStore,
        PublicImportedReferenceRecord,
        PublicMetadataImportJobRecord;

class ImportPublicMetadataFake implements ImportPublicMetadataApi {
  const ImportPublicMetadataFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<PublicMetadataImportJob> startImport({
    required String channelId,
    required String externalAccountLinkId,
    required String rightsBasis,
    int maxItems = 500,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapJob(
      await _store.startPublicMetadataImport(
        channelId: channelId,
        externalAccountLinkId: externalAccountLinkId,
        rightsBasis: rightsBasis,
        maxItems: maxItems,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<PublicMetadataImportJob> getImportJob({
    required String channelId,
    required String jobId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapJob(await _store.advancePublicMetadataImportJob(jobId));
  }

  @override
  Future<List<PublicImportedReference>> listImportedReferences({
    required String channelId,
    String? jobId,
  }) async {
    await Future<void>.delayed(latency);
    return (await _store.publicImportedReferences(
      channelId: channelId,
      jobId: jobId,
    )).map(_mapReference).toList(growable: false);
  }
}

PublicMetadataImportJob _mapJob(PublicMetadataImportJobRecord record) {
  return PublicMetadataImportJob(
    jobId: record.jobId,
    channelId: record.channelId,
    status: record.status,
    importedCount: record.importedCount,
    skippedCount: record.skippedCount,
    message: record.message,
  );
}

PublicImportedReference _mapReference(PublicImportedReferenceRecord record) {
  return PublicImportedReference(
    referenceId: record.referenceId,
    platform: record.platform,
    externalId: record.externalId,
    title: record.title,
    description: record.description,
    thumbnailRef: record.thumbnailRef,
    sourceUrl: record.sourceUrl,
    publishedAt: record.publishedAt,
    rightsBasis: record.rightsBasis,
    searchIndexable: record.searchIndexable,
    aiQueryable: record.aiQueryable,
  );
}
