import 'dart:convert';

import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    hide ExportJob, ImportJob;

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

  @override
  Future<ExportJob> createExportJob({
    required String creatorId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.startExportJob(
      creatorId: creatorId,
      idempotencyKey: idempotencyKey,
    );
    return _mapExportJob(record);
  }

  @override
  Future<ExportJob> getExportJob(String jobId) async {
    await Future<void>.delayed(latency);
    final current = await _store.exportJob(jobId);
    if (current == null) {
      throw StateError('Export job $jobId was not found.');
    }
    if (current.state == 'complete') {
      return _mapExportJob(current);
    }

    final willComplete = current.pollCount + 1 >= 2;
    final bundle = willComplete
        ? await _buildPortableBundle(
            creatorId: current.creatorId,
            bundleRef: 'bundle_${current.id}.json',
          )
        : null;
    final record = await _store.advanceExportJob(
      id: jobId,
      bundleRef: bundle?.bundleRef ?? '',
      bundleJson: bundle?.portableJson ?? '',
    );
    return _mapExportJob(record);
  }

  @override
  Future<void> resetDemo({required String idempotencyKey}) async {
    await Future<void>.delayed(latency);
    await _store.resetDemo();
  }

  Future<ExportBundle> _buildPortableBundle({
    required String creatorId,
    required String bundleRef,
  }) async {
    final creator = await _store.creatorById(creatorId);
    final content = await _store.publicCatalogForCreator(creatorId);
    final manifests = await _store.contentManifests(creatorId);
    final transcripts = await _store.transcriptsForCreator(creatorId);
    final adPolicy = await _store.creatorAdPolicy(creatorId);
    final payout = await _store.creatorPayoutStatement(creatorId);
    final receipts = <ReceiptRecord>[];
    for (final item in content) {
      receipts.addAll(await _store.receiptsForContent(item.id));
    }

    final creatorName = creator?.displayName ?? creatorId;
    final generatedAt = DateTime.utc(2026, 5, 31, 12);
    final portable = <String, Object?>{
      'schemaVersion': 1,
      'bundleRef': bundleRef,
      'generatedAt': generatedAt.toIso8601String(),
      'channel': {
        'creatorId': creatorId,
        'displayName': creatorName,
        'handle': creator?.handle ?? creatorId,
        'vertical': creator?.vertical ?? 'creator',
        'avatarRef': creator?.avatarRef,
      },
      'content': content.map(_contentToJson).toList(growable: false),
      'contentManifests': manifests
          .map(_manifestToJson)
          .toList(growable: false),
      'transcripts': transcripts.map(_transcriptToJson).toList(growable: false),
      'receipts': receipts.map(_receiptToJson).toList(growable: false),
      'settlementHistory': [_payoutToJson(payout)],
      'policies': {
        if (adPolicy != null) 'creatorAdPolicy': _adPolicyToJson(adPolicy),
      },
    };
    final portableJson = jsonEncode(portable);
    return _bundleFromJson(
      creatorId: creatorId,
      creatorName: creatorName,
      bundleRef: bundleRef,
      portableJson: portableJson,
    );
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

ExportJob _mapExportJob(ExportJobRecord record) {
  return ExportJob(
    id: record.id,
    creatorId: record.creatorId,
    state: _mapExportState(record.state),
    bundle: record.bundleJson.isEmpty
        ? null
        : _bundleFromJson(
            creatorId: record.creatorId,
            bundleRef: record.bundleRef,
            portableJson: record.bundleJson,
          ),
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  );
}

ExportJobState _mapExportState(String value) {
  return switch (value) {
    'complete' => ExportJobState.complete,
    'queued' => ExportJobState.queued,
    _ => ExportJobState.processing,
  };
}

ExportBundle _bundleFromJson({
  required String creatorId,
  required String bundleRef,
  required String portableJson,
  String? creatorName,
}) {
  final decoded = jsonDecode(portableJson) as Map<String, Object?>;
  final channel = decoded['channel'] as Map<String, Object?>? ?? const {};
  final content = decoded['content'] as List<dynamic>? ?? const [];
  final manifests = decoded['contentManifests'] as List<dynamic>? ?? const [];
  final receipts = decoded['receipts'] as List<dynamic>? ?? const [];
  final settlements =
      decoded['settlementHistory'] as List<dynamic>? ?? const [];
  final policies = decoded['policies'] as Map<String, Object?>? ?? const {};
  final generatedAt =
      DateTime.tryParse('${decoded['generatedAt']}') ??
      DateTime.utc(2026, 5, 31, 12);

  return ExportBundle(
    bundleRef: bundleRef,
    creatorId: creatorId,
    creatorName: creatorName ?? '${channel['displayName'] ?? creatorId}',
    generatedAt: generatedAt,
    portableJson: portableJson,
    contentCount: content.length + manifests.length,
    receiptCount: receipts.length,
    settlementCount: settlements.length,
    sections: [
      const ExportBundleSection(
        label: 'Channel profile',
        itemCount: 1,
        description:
            'Creator identity, handle, vertical, and avatar reference.',
      ),
      ExportBundleSection(
        label: 'Content catalog',
        itemCount: content.length,
        description: 'Portable public catalog entries and summaries.',
      ),
      ExportBundleSection(
        label: 'Content manifests',
        itemCount: manifests.length,
        description: 'Creator-published access and monetization manifests.',
      ),
      ExportBundleSection(
        label: 'Receipt ledger',
        itemCount: receipts.length,
        description: 'Playback, support, AI, referral, and campaign receipts.',
      ),
      ExportBundleSection(
        label: 'Settlement history',
        itemCount: settlements.length,
        description: 'Creator payout statements and reconciliation totals.',
      ),
      ExportBundleSection(
        label: 'Policy data',
        itemCount: policies.length,
        description: 'Portable creator policy records when configured.',
      ),
    ],
  );
}

Map<String, Object?> _contentToJson(ContentRecord record) {
  return {
    'id': record.id,
    'creatorId': record.creatorId,
    'contentType': record.contentType,
    'title': record.title,
    'summary': record.summary,
    'thumbnailRef': record.thumbnailRef,
    'createdAt': record.createdAt.toIso8601String(),
    'perfVelocity': record.perfVelocity,
  };
}

Map<String, Object?> _manifestToJson(ContentManifestRecord record) {
  return {
    'id': record.id,
    'channelId': record.channelId,
    'contentType': record.contentType,
    'title': record.title,
    'summary': record.summary,
    'accessMode': record.accessMode,
    'monetizationMode': record.monetizationMode,
    'thumbnailRef': record.thumbnailRef,
    'schemaVersion': record.schemaVersion,
    'createdAt': record.createdAt.toIso8601String(),
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

Map<String, Object?> _transcriptToJson(TranscriptRecord record) {
  return {
    'contentId': record.contentId,
    'segments': record.segments
        .map(
          (segment) => {'startLabel': segment.startLabel, 'text': segment.text},
        )
        .toList(growable: false),
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

Map<String, Object?> _receiptToJson(ReceiptRecord record) {
  return {
    'id': record.id,
    'type': record.type,
    'passportId': record.passportId,
    'contentId': record.contentId,
    'authorizationId': record.authorizationId,
    'summary': record.summary,
    'createdAt': record.createdAt.toIso8601String(),
  };
}

Map<String, Object?> _payoutToJson(CreatorPayoutStatementRecord record) {
  return {
    'id': record.id,
    'creatorId': record.creatorId,
    'creatorName': record.creatorName,
    'totalCents': record.totalCents,
    'bySource': record.bySource.map(_revenueBreakdownToJson).toList(),
    'byIntent': record.byIntent.map(_revenueBreakdownToJson).toList(),
    'recentReceipts': record.recentReceipts.map(_receiptToJson).toList(),
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}

Map<String, Object?> _revenueBreakdownToJson(RevenueBreakdownRecord record) {
  return {'label': record.label, 'amountCents': record.amountCents};
}

Map<String, Object?> _adPolicyToJson(CreatorAdPolicyRecord record) {
  return {
    'channelId': record.channelId,
    'allowedCategories': record.allowedCategories,
    'blockedCategories': record.blockedCategories,
    'formats': record.formats,
    'surfaces': record.surfaces,
    'updatedAt': record.updatedAt.toIso8601String(),
  };
}
