import 'dart:typed_data';

import 'package:postgres/postgres.dart' as pg;

import 'document_object_store.dart';

/// One stored document's metadata. The bytes live in object storage.
class StoredDocument {
  const StoredDocument({
    required this.documentId,
    required this.communityId,
    required this.instanceId,
    required this.workflowType,
    required this.fieldName,
    required this.title,
    required this.filename,
    required this.contentType,
    required this.byteSize,
    required this.ownerFanId,
    required this.objectKey,
    required this.uploadedAt,
  });

  final String documentId;
  final String communityId;
  final String instanceId;
  final String workflowType;
  final String fieldName;
  final String title;
  final String filename;
  final String contentType;
  final int byteSize;

  /// The fan whose upload created this document.
  ///
  /// Stored rather than read back from the instance's creator: the uploader and
  /// the instance's creator are not always the same fan, and a document's owner
  /// is the person who put the file there.
  final String ownerFanId;

  final String objectKey;
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'communityId': communityId,
    'instanceId': instanceId,
    'workflowType': workflowType,
    'fieldName': fieldName,
    'title': title,
    'filename': filename,
    'contentType': contentType,
    'byteSize': byteSize,
    'ownerFanId': ownerFanId,
    'uploadedAt': uploadedAt.toUtc().toIso8601String(),
    'contentUrl':
        '/v1/communities/$communityId/documents/$documentId/content',
  };
}

/// Where document metadata lives.
///
/// An interface so the endpoint tests can exercise authorization without a
/// database. Those tests decide who may read a document, and a suite that
/// skipped them whenever PostgreSQL was absent would be green exactly when it
/// had checked nothing -- the failure mode this project treats as worse than a
/// red suite.
abstract interface class DocumentRepository {
  Future<void> insert(StoredDocument document, {String? idempotencyKey});

  Future<StoredDocument?> findById({
    required String communityId,
    required String documentId,
  });

  Future<StoredDocument?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  });

  Future<List<StoredDocument>> listForInstance({
    required String communityId,
    required String instanceId,
  });

  Future<void> delete({
    required String communityId,
    required String documentId,
  });
}

/// Document metadata in PostgreSQL, alongside the engine's own tables.
class PostgresDocumentRepository implements DocumentRepository {
  PostgresDocumentRepository(this._connection);

  final pg.Connection _connection;

  /// Declares the schema, following the engine's `IF NOT EXISTS` convention so
  /// a redeploy against a populated database is a no-op rather than a wipe.
  Future<void> migrate() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_documents (
        document_id TEXT PRIMARY KEY,
        community_id TEXT NOT NULL,
        instance_id TEXT NOT NULL,
        workflow_type TEXT NOT NULL,
        field_name TEXT NOT NULL,
        title TEXT NOT NULL,
        filename TEXT NOT NULL,
        content_type TEXT NOT NULL,
        byte_size BIGINT NOT NULL,
        owner_fan_id TEXT NOT NULL,
        object_key TEXT NOT NULL,
        uploaded_at BIGINT NOT NULL,
        idempotency_key TEXT
      );
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_documents_instance
        ON workflow_documents (community_id, instance_id);
    ''');
    // Partial, because most rows carry no key and NULLs do not collide in a
    // plain unique index -- which would let a retry without a key duplicate
    // silently while a retry with one was correctly rejected.
    await _connection.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_documents_idempotency
        ON workflow_documents (community_id, idempotency_key)
        WHERE idempotency_key IS NOT NULL;
    ''');
  }

  @override
  Future<void> insert(
    StoredDocument document, {
    String? idempotencyKey,
  }) async {
    await _connection.execute(
      pg.Sql.named('''
        INSERT INTO workflow_documents (
          document_id, community_id, instance_id, workflow_type, field_name,
          title, filename, content_type, byte_size, owner_fan_id, object_key,
          uploaded_at, idempotency_key
        ) VALUES (
          @documentId, @communityId, @instanceId, @workflowType, @fieldName,
          @title, @filename, @contentType, @byteSize, @ownerFanId, @objectKey,
          @uploadedAt, @idempotencyKey
        )
      '''),
      parameters: {
        'documentId': document.documentId,
        'communityId': document.communityId,
        'instanceId': document.instanceId,
        'workflowType': document.workflowType,
        'fieldName': document.fieldName,
        'title': document.title,
        'filename': document.filename,
        'contentType': document.contentType,
        'byteSize': document.byteSize,
        'ownerFanId': document.ownerFanId,
        'objectKey': document.objectKey,
        'uploadedAt': document.uploadedAt.millisecondsSinceEpoch,
        'idempotencyKey': idempotencyKey,
      },
    );
  }

  @override
  Future<StoredDocument?> findById({
    required String communityId,
    required String documentId,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT ${_columns} FROM workflow_documents
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first.toColumnMap());
  }

  /// The document a previous request with this idempotency key created.
  ///
  /// Scoped to the community as well as the key, so two communities cannot
  /// collide on a client-chosen string -- and so a key leaked from one
  /// community cannot be used to read a document in another.
  @override
  Future<StoredDocument?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT ${_columns} FROM workflow_documents
        WHERE community_id = @communityId AND idempotency_key = @key
      '''),
      parameters: {'communityId': communityId, 'key': idempotencyKey},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first.toColumnMap());
  }

  @override
  Future<List<StoredDocument>> listForInstance({
    required String communityId,
    required String instanceId,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT ${_columns} FROM workflow_documents
        WHERE community_id = @communityId AND instance_id = @instanceId
        ORDER BY uploaded_at ASC, document_id ASC
      '''),
      parameters: {'communityId': communityId, 'instanceId': instanceId},
    );
    return rows.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  @override
  Future<void> delete({
    required String communityId,
    required String documentId,
  }) async {
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_documents
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
  }

  static const _columns =
      'document_id, community_id, instance_id, workflow_type, field_name, '
      'title, filename, content_type, byte_size, owner_fan_id, object_key, '
      'uploaded_at';

  static StoredDocument _fromRow(Map<String, dynamic> row) => StoredDocument(
    documentId: row['document_id'] as String,
    communityId: row['community_id'] as String,
    instanceId: row['instance_id'] as String,
    workflowType: row['workflow_type'] as String,
    fieldName: row['field_name'] as String,
    title: row['title'] as String,
    filename: row['filename'] as String,
    contentType: row['content_type'] as String,
    byteSize: (row['byte_size'] as num).toInt(),
    ownerFanId: row['owner_fan_id'] as String,
    objectKey: row['object_key'] as String,
    uploadedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['uploaded_at'] as num).toInt(),
      isUtc: true,
    ),
  );
}

/// Document metadata held in memory.
///
/// Used by the endpoint tests. Deliberately not a "fake backend": it stores and
/// returns exactly what it was given, and answers no authorization question --
/// every one of those is the engine's.
class InMemoryDocumentRepository implements DocumentRepository {
  final Map<String, StoredDocument> _documents = {};
  final Map<String, String> _idempotencyKeys = {};

  @override
  Future<void> insert(StoredDocument document, {String? idempotencyKey}) async {
    _documents['${document.communityId}/${document.documentId}'] = document;
    if (idempotencyKey != null) {
      _idempotencyKeys['${document.communityId}/$idempotencyKey'] =
          document.documentId;
    }
  }

  @override
  Future<StoredDocument?> findById({
    required String communityId,
    required String documentId,
  }) async => _documents['$communityId/$documentId'];

  @override
  Future<StoredDocument?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  }) async {
    final documentId = _idempotencyKeys['$communityId/$idempotencyKey'];
    if (documentId == null) return null;
    return _documents['$communityId/$documentId'];
  }

  @override
  Future<List<StoredDocument>> listForInstance({
    required String communityId,
    required String instanceId,
  }) async =>
      _documents.values
          .where(
            (document) =>
                document.communityId == communityId &&
                document.instanceId == instanceId,
          )
          .toList()
        ..sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));

  @override
  Future<void> delete({
    required String communityId,
    required String documentId,
  }) async {
    _documents.remove('$communityId/$documentId');
  }
}

/// Object bytes held in memory, for the same reason.
class InMemoryDocumentObjectStore implements DocumentObjectStore {
  final Map<String, List<int>> objects = {};

  @override
  Future<void> put({
    required String key,
    required List<int> bytes,
    required String contentType,
  }) async {
    objects[key] = bytes;
  }

  @override
  Future<Uint8List?> get(String key) async {
    final bytes = objects[key];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String key) async {
    objects.remove(key);
  }
}
