import 'package:postgres/postgres.dart' as pg;

import 'document_object_store.dart';

/// Metadata for one immutable export payload.
///
/// The payload itself stays in [DocumentObjectStore]. Keeping only its
/// identity, recorded digest and object key here means verification must read
/// the stored bytes rather than accidentally comparing a record to itself.
class StoredExportBundle {
  const StoredExportBundle({
    required this.exportId,
    required this.communityId,
    required this.instanceId,
    required this.checksum,
    required this.checksumAlgorithm,
    required this.byteSize,
    required this.recordCount,
    required this.redacted,
    required this.generatedAt,
    required this.objectKey,
  });

  final String exportId;
  final String communityId;
  final String instanceId;
  final String checksum;
  final String checksumAlgorithm;
  final int byteSize;
  final int recordCount;
  final bool redacted;
  final DateTime generatedAt;
  final String objectKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exportId': exportId,
    'communityId': communityId,
    'instanceId': instanceId,
    'checksum': checksum,
    'checksumAlgorithm': checksumAlgorithm,
    'byteSize': byteSize,
    'recordCount': recordCount,
    'redacted': redacted,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
  };
}

/// Persistent metadata for stored export bundles.
abstract interface class ExportBundleRepository {
  Future<void> insert(
    StoredExportBundle bundle, {
    required String idempotencyKey,
  });

  Future<StoredExportBundle?> findById({
    required String communityId,
    required String exportId,
  });

  Future<StoredExportBundle?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  });
}

/// PostgreSQL implementation used by the deployed workflow service.
class PostgresExportBundleRepository implements ExportBundleRepository {
  PostgresExportBundleRepository(this._connection);

  final pg.Session _connection;

  Future<void> migrate() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_export_bundles (
        export_id TEXT PRIMARY KEY,
        community_id TEXT NOT NULL,
        instance_id TEXT NOT NULL,
        checksum TEXT NOT NULL,
        checksum_algorithm TEXT NOT NULL,
        byte_size BIGINT NOT NULL,
        record_count INTEGER NOT NULL,
        redacted BOOLEAN NOT NULL,
        generated_at BIGINT NOT NULL,
        object_key TEXT NOT NULL,
        idempotency_key TEXT NOT NULL
      );
    ''');
    await _connection.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_export_bundles_idempotency
        ON workflow_export_bundles (community_id, idempotency_key);
    ''');
  }

  @override
  Future<void> insert(
    StoredExportBundle bundle, {
    required String idempotencyKey,
  }) async {
    await _connection.execute(
      pg.Sql.named('''
        INSERT INTO workflow_export_bundles (
          export_id, community_id, instance_id, checksum, checksum_algorithm,
          byte_size, record_count, redacted, generated_at, object_key,
          idempotency_key
        ) VALUES (
          @exportId, @communityId, @instanceId, @checksum, @checksumAlgorithm,
          @byteSize, @recordCount, @redacted, @generatedAt, @objectKey,
          @idempotencyKey
        )
      '''),
      parameters: <String, dynamic>{
        'exportId': bundle.exportId,
        'communityId': bundle.communityId,
        'instanceId': bundle.instanceId,
        'checksum': bundle.checksum,
        'checksumAlgorithm': bundle.checksumAlgorithm,
        'byteSize': bundle.byteSize,
        'recordCount': bundle.recordCount,
        'redacted': bundle.redacted,
        'generatedAt': bundle.generatedAt.millisecondsSinceEpoch,
        'objectKey': bundle.objectKey,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  @override
  Future<StoredExportBundle?> findById({
    required String communityId,
    required String exportId,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_columns FROM workflow_export_bundles
        WHERE community_id = @communityId AND export_id = @exportId
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'exportId': exportId,
      },
    );
    return rows.isEmpty ? null : _fromRow(rows.first.toColumnMap());
  }

  @override
  Future<StoredExportBundle?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_columns FROM workflow_export_bundles
        WHERE community_id = @communityId AND idempotency_key = @idempotencyKey
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'idempotencyKey': idempotencyKey,
      },
    );
    return rows.isEmpty ? null : _fromRow(rows.first.toColumnMap());
  }

  static const _columns =
      'export_id, community_id, instance_id, checksum, checksum_algorithm, '
      'byte_size, record_count, redacted, generated_at, object_key';

  static StoredExportBundle _fromRow(Map<String, dynamic> row) =>
      StoredExportBundle(
        exportId: row['export_id'] as String,
        communityId: row['community_id'] as String,
        instanceId: row['instance_id'] as String,
        checksum: row['checksum'] as String,
        checksumAlgorithm: row['checksum_algorithm'] as String,
        byteSize: (row['byte_size'] as num).toInt(),
        recordCount: (row['record_count'] as num).toInt(),
        redacted: row['redacted'] as bool,
        generatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['generated_at'] as num).toInt(),
          isUtc: true,
        ),
        objectKey: row['object_key'] as String,
      );
}

/// In-memory metadata repository for service tests.
class InMemoryExportBundleRepository implements ExportBundleRepository {
  final Map<String, StoredExportBundle> _bundles =
      <String, StoredExportBundle>{};
  final Map<String, String> _idempotencyKeys = <String, String>{};

  @override
  Future<void> insert(
    StoredExportBundle bundle, {
    required String idempotencyKey,
  }) async {
    _bundles['${bundle.communityId}/${bundle.exportId}'] = bundle;
    _idempotencyKeys['${bundle.communityId}/$idempotencyKey'] = bundle.exportId;
  }

  @override
  Future<StoredExportBundle?> findById({
    required String communityId,
    required String exportId,
  }) async => _bundles['$communityId/$exportId'];

  @override
  Future<StoredExportBundle?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  }) async {
    final exportId = _idempotencyKeys['$communityId/$idempotencyKey'];
    return exportId == null ? null : _bundles['$communityId/$exportId'];
  }
}

/// Key derived solely from server-owned identifiers, never member input.
String exportBundleObjectKey({
  required String communityId,
  required String instanceId,
  required String exportId,
}) => 'communities/$communityId/instances/$instanceId/exports/$exportId';
