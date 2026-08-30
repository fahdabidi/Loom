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
    this.version = 1,
    DateTime? revisedAt,
    this.changeNote,
  }) : revisedAt = revisedAt ?? uploadedAt;

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

  /// Starts at one and advances only when the service stores new bytes.
  final int version;

  /// The timestamp for the bytes represented by this metadata row.
  final DateTime revisedAt;

  /// An optional explanation the uploader supplied for this revision.
  final String? changeNote;

  /// Where the bytes are read from, relative to the service root.
  ///
  /// Carries no token and grants nothing on its own, so it is safe to store in
  /// instance data -- which a signed URL would not be, since instance data is
  /// readable by everyone the workflow admits.
  String get contentUrl =>
      '/v1/communities/$communityId/documents/$documentId/content';

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
    'version': version,
    'revisedAt': revisedAt.toUtc().toIso8601String(),
    if (changeNote != null) 'changeNote': changeNote,
    'contentUrl': contentUrl,
  };

  StoredDocument withRevision({
    required int version,
    required String title,
    required String filename,
    required String contentType,
    required int byteSize,
    required String objectKey,
    required DateTime revisedAt,
    String? changeNote,
  }) => StoredDocument(
    documentId: documentId,
    communityId: communityId,
    instanceId: instanceId,
    workflowType: workflowType,
    fieldName: fieldName,
    title: title,
    filename: filename,
    contentType: contentType,
    byteSize: byteSize,
    ownerFanId: ownerFanId,
    objectKey: objectKey,
    uploadedAt: uploadedAt,
    version: version,
    revisedAt: revisedAt,
    changeNote: changeNote,
  );
}

/// One caller-owned set of facts about a shared document.
class StoredDocumentMemberState {
  const StoredDocumentMemberState({
    required this.documentId,
    required this.fanId,
    this.read = false,
    this.readAt,
    this.saved = false,
    this.savedAt,
    this.acknowledgedAt,
    this.acknowledgedVersion,
  });

  final String documentId;
  final String fanId;
  final bool read;
  final DateTime? readAt;
  final bool saved;
  final DateTime? savedAt;
  final DateTime? acknowledgedAt;
  final int? acknowledgedVersion;

  bool get acknowledged => acknowledgedVersion != null;

  Map<String, dynamic> toJson({required int currentVersion}) => {
    'documentId': documentId,
    'fanId': fanId,
    'currentVersion': currentVersion,
    'read': read,
    if (readAt != null) 'readAt': readAt!.toUtc().toIso8601String(),
    'saved': saved,
    if (savedAt != null) 'savedAt': savedAt!.toUtc().toIso8601String(),
    'acknowledged': acknowledged,
    if (acknowledgedAt != null)
      'acknowledgedAt': acknowledgedAt!.toUtc().toIso8601String(),
    if (acknowledgedVersion != null) 'acknowledgedVersion': acknowledgedVersion,
  };
}

/// An immutable acknowledgement, retained after later versions are published.
class StoredDocumentAcknowledgement {
  const StoredDocumentAcknowledgement({
    required this.documentId,
    required this.fanId,
    required this.version,
    required this.acknowledgedAt,
  });

  final String documentId;
  final String fanId;
  final int version;
  final DateTime acknowledgedAt;

  Map<String, dynamic> toJson({required int currentVersion}) => {
    'fanId': fanId,
    'version': version,
    'acknowledgedAt': acknowledgedAt.toUtc().toIso8601String(),
    'stale': version < currentVersion,
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

  /// Stores an immutable revision. [revision.version] is assigned by the
  /// service and must be exactly one later than the document it read.
  Future<void> addRevision(
    StoredDocument revision, {
    required String idempotencyKey,
  });

  Future<StoredDocument?> findRevision({
    required String communityId,
    required String documentId,
    required int version,
  });

  Future<StoredDocument?> findRevisionByIdempotencyKey({
    required String communityId,
    required String documentId,
    required String idempotencyKey,
  });

  Future<List<StoredDocument>> listRevisions({
    required String communityId,
    required String documentId,
  });

  Future<StoredDocumentMemberState?> findMemberState({
    required String communityId,
    required String documentId,
    required String fanId,
  });

  Future<void> saveMemberState({
    required String communityId,
    required StoredDocumentMemberState state,
  });

  Future<void> recordAcknowledgement({
    required String communityId,
    required StoredDocumentAcknowledgement acknowledgement,
  });

  Future<List<StoredDocumentAcknowledgement>> listAcknowledgements({
    required String communityId,
    required String documentId,
    required bool currentVersionOnly,
    required int currentVersion,
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
    // The original workflow_documents table remains untouched. Revisions are
    // append-only facts so existing deployments can migrate without changing
    // or rewriting any stored document.
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_document_revisions (
        community_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        title TEXT NOT NULL,
        filename TEXT NOT NULL,
        content_type TEXT NOT NULL,
        byte_size BIGINT NOT NULL,
        object_key TEXT NOT NULL,
        revised_at BIGINT NOT NULL,
        change_note TEXT,
        PRIMARY KEY (community_id, document_id, version)
      );
    ''');
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_document_revision_requests (
        community_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        version INTEGER NOT NULL,
        PRIMARY KEY (community_id, document_id, idempotency_key)
      );
    ''');
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_document_member_states (
        community_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        fan_id TEXT NOT NULL,
        is_read BOOLEAN NOT NULL,
        read_at BIGINT,
        is_saved BOOLEAN NOT NULL,
        saved_at BIGINT,
        acknowledged_at BIGINT,
        acknowledged_version INTEGER,
        PRIMARY KEY (community_id, document_id, fan_id)
      );
    ''');
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_document_acknowledgements (
        community_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        fan_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        acknowledged_at BIGINT NOT NULL,
        PRIMARY KEY (community_id, document_id, fan_id, version)
      );
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_document_acknowledgements_document
        ON workflow_document_acknowledgements (community_id, document_id, version);
    ''');
  }

  @override
  Future<void> insert(StoredDocument document, {String? idempotencyKey}) async {
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
    await _insertRevision(document);
  }

  @override
  Future<StoredDocument?> findById({
    required String communityId,
    required String documentId,
  }) async {
    final document = await _findBaseById(
      communityId: communityId,
      documentId: documentId,
    );
    if (document == null) return null;
    return _currentRevisionFor(document);
  }

  Future<StoredDocument?> _findBaseById({
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
    return _currentRevisionFor(_fromRow(rows.first.toColumnMap()));
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
    final documents = <StoredDocument>[];
    for (final row in rows) {
      documents.add(await _currentRevisionFor(_fromRow(row.toColumnMap())));
    }
    return documents;
  }

  @override
  Future<void> addRevision(
    StoredDocument revision, {
    required String idempotencyKey,
  }) async {
    await _insertRevision(revision);
    await _connection.execute(
      pg.Sql.named('''
        INSERT INTO workflow_document_revision_requests (
          community_id, document_id, idempotency_key, version
        ) VALUES (@communityId, @documentId, @idempotencyKey, @version)
      '''),
      parameters: <String, dynamic>{
        'communityId': revision.communityId,
        'documentId': revision.documentId,
        'idempotencyKey': idempotencyKey,
        'version': revision.version,
      },
    );
  }

  Future<void> _insertRevision(StoredDocument revision) => _connection.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_revisions (
        community_id, document_id, version, title, filename, content_type,
        byte_size, object_key, revised_at, change_note
      ) VALUES (
        @communityId, @documentId, @version, @title, @filename, @contentType,
        @byteSize, @objectKey, @revisedAt, @changeNote
      )
    '''),
    parameters: <String, dynamic>{
      'communityId': revision.communityId,
      'documentId': revision.documentId,
      'version': revision.version,
      'title': revision.title,
      'filename': revision.filename,
      'contentType': revision.contentType,
      'byteSize': revision.byteSize,
      'objectKey': revision.objectKey,
      'revisedAt': revision.revisedAt.millisecondsSinceEpoch,
      'changeNote': revision.changeNote,
    },
  );

  @override
  Future<StoredDocument?> findRevision({
    required String communityId,
    required String documentId,
    required int version,
  }) async {
    final base = await _findBaseById(
      communityId: communityId,
      documentId: documentId,
    );
    if (base == null) return null;
    final revision = await _revisionFor(
      communityId: communityId,
      documentId: documentId,
      version: version,
    );
    // Documents written before this additive migration have no v1 revision
    // row. Their existing metadata is still the immutable first revision.
    return revision == null
        ? (version == 1 ? base : null)
        : _applyRevision(base, revision);
  }

  @override
  Future<StoredDocument?> findRevisionByIdempotencyKey({
    required String communityId,
    required String documentId,
    required String idempotencyKey,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT version FROM workflow_document_revision_requests
        WHERE community_id = @communityId AND document_id = @documentId
          AND idempotency_key = @idempotencyKey
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'documentId': documentId,
        'idempotencyKey': idempotencyKey,
      },
    );
    if (rows.isEmpty) return null;
    return findRevision(
      communityId: communityId,
      documentId: documentId,
      version: (rows.first.toColumnMap()['version'] as num).toInt(),
    );
  }

  @override
  Future<List<StoredDocument>> listRevisions({
    required String communityId,
    required String documentId,
  }) async {
    final base = await _findBaseById(
      communityId: communityId,
      documentId: documentId,
    );
    if (base == null) return const <StoredDocument>[];
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_revisionColumns FROM workflow_document_revisions
        WHERE community_id = @communityId AND document_id = @documentId
        ORDER BY version ASC
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'documentId': documentId,
      },
    );
    if (rows.isEmpty) return <StoredDocument>[base];
    final revisions = rows
        .map((row) => _applyRevision(base, row.toColumnMap()))
        .toList();
    // A database populated before revisions existed has no stored v1 row.
    // Keep the original workflow_documents metadata addressable as that first
    // revision while newer, append-only rows supply the later ones.
    if (!revisions.any((revision) => revision.version == 1)) {
      revisions.insert(0, base);
    }
    return revisions;
  }

  Future<StoredDocument> _currentRevisionFor(StoredDocument base) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_revisionColumns FROM workflow_document_revisions
        WHERE community_id = @communityId AND document_id = @documentId
        ORDER BY version DESC LIMIT 1
      '''),
      parameters: <String, dynamic>{
        'communityId': base.communityId,
        'documentId': base.documentId,
      },
    );
    return rows.isEmpty ? base : _applyRevision(base, rows.first.toColumnMap());
  }

  Future<Map<String, dynamic>?> _revisionFor({
    required String communityId,
    required String documentId,
    required int version,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_revisionColumns FROM workflow_document_revisions
        WHERE community_id = @communityId AND document_id = @documentId
          AND version = @version
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'documentId': documentId,
        'version': version,
      },
    );
    return rows.isEmpty ? null : rows.first.toColumnMap();
  }

  static StoredDocument _applyRevision(
    StoredDocument base,
    Map<String, dynamic> row,
  ) => base.withRevision(
    version: (row['version'] as num).toInt(),
    title: row['title'] as String,
    filename: row['filename'] as String,
    contentType: row['content_type'] as String,
    byteSize: (row['byte_size'] as num).toInt(),
    objectKey: row['object_key'] as String,
    revisedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['revised_at'] as num).toInt(),
      isUtc: true,
    ),
    changeNote: row['change_note'] as String?,
  );

  @override
  Future<StoredDocumentMemberState?> findMemberState({
    required String communityId,
    required String documentId,
    required String fanId,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT document_id, fan_id, is_read, read_at, is_saved, saved_at,
          acknowledged_at, acknowledged_version
        FROM workflow_document_member_states
        WHERE community_id = @communityId AND document_id = @documentId
          AND fan_id = @fanId
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'documentId': documentId,
        'fanId': fanId,
      },
    );
    return rows.isEmpty ? null : _memberStateFromRow(rows.first.toColumnMap());
  }

  @override
  Future<void> saveMemberState({
    required String communityId,
    required StoredDocumentMemberState state,
  }) => _connection.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_member_states (
        community_id, document_id, fan_id, is_read, read_at, is_saved,
        saved_at, acknowledged_at, acknowledged_version
      ) VALUES (
        @communityId, @documentId, @fanId, @read, @readAt, @saved,
        @savedAt, @acknowledgedAt, @acknowledgedVersion
      ) ON CONFLICT (community_id, document_id, fan_id) DO UPDATE SET
        is_read = EXCLUDED.is_read,
        read_at = EXCLUDED.read_at,
        is_saved = EXCLUDED.is_saved,
        saved_at = EXCLUDED.saved_at,
        acknowledged_at = EXCLUDED.acknowledged_at,
        acknowledged_version = EXCLUDED.acknowledged_version
    '''),
    parameters: <String, dynamic>{
      'communityId': communityId,
      'documentId': state.documentId,
      'fanId': state.fanId,
      'read': state.read,
      'readAt': state.readAt?.millisecondsSinceEpoch,
      'saved': state.saved,
      'savedAt': state.savedAt?.millisecondsSinceEpoch,
      'acknowledgedAt': state.acknowledgedAt?.millisecondsSinceEpoch,
      'acknowledgedVersion': state.acknowledgedVersion,
    },
  );

  @override
  Future<void> recordAcknowledgement({
    required String communityId,
    required StoredDocumentAcknowledgement acknowledgement,
  }) => _connection.execute(
    pg.Sql.named('''
      INSERT INTO workflow_document_acknowledgements (
        community_id, document_id, fan_id, version, acknowledged_at
      ) VALUES (
        @communityId, @documentId, @fanId, @version, @acknowledgedAt
      ) ON CONFLICT (community_id, document_id, fan_id, version) DO NOTHING
    '''),
    parameters: <String, dynamic>{
      'communityId': communityId,
      'documentId': acknowledgement.documentId,
      'fanId': acknowledgement.fanId,
      'version': acknowledgement.version,
      'acknowledgedAt': acknowledgement.acknowledgedAt.millisecondsSinceEpoch,
    },
  );

  @override
  Future<List<StoredDocumentAcknowledgement>> listAcknowledgements({
    required String communityId,
    required String documentId,
    required bool currentVersionOnly,
    required int currentVersion,
  }) async {
    final parameters = <String, dynamic>{
      'communityId': communityId,
      'documentId': documentId,
      if (currentVersionOnly) 'currentVersion': currentVersion,
    };
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT fan_id, version, acknowledged_at
        FROM workflow_document_acknowledgements
        WHERE community_id = @communityId AND document_id = @documentId
          ${currentVersionOnly ? 'AND version = @currentVersion' : ''}
        ORDER BY acknowledged_at ASC, fan_id ASC
      '''),
      parameters: parameters,
    );
    return rows.map((row) {
      final values = row.toColumnMap();
      return StoredDocumentAcknowledgement(
        documentId: documentId,
        fanId: values['fan_id'] as String,
        version: (values['version'] as num).toInt(),
        acknowledgedAt: DateTime.fromMillisecondsSinceEpoch(
          (values['acknowledged_at'] as num).toInt(),
          isUtc: true,
        ),
      );
    }).toList();
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
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_document_revisions
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_document_revision_requests
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_document_member_states
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_document_acknowledgements
        WHERE community_id = @communityId AND document_id = @documentId
      '''),
      parameters: {'communityId': communityId, 'documentId': documentId},
    );
  }

  static const _columns =
      'document_id, community_id, instance_id, workflow_type, field_name, '
      'title, filename, content_type, byte_size, owner_fan_id, object_key, '
      'uploaded_at';

  static const _revisionColumns =
      'version, title, filename, content_type, byte_size, object_key, '
      'revised_at, change_note';

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

  static StoredDocumentMemberState _memberStateFromRow(
    Map<String, dynamic> row,
  ) => StoredDocumentMemberState(
    documentId: row['document_id'] as String,
    fanId: row['fan_id'] as String,
    read: row['is_read'] as bool,
    readAt: _dateOrNull(row['read_at']),
    saved: row['is_saved'] as bool,
    savedAt: _dateOrNull(row['saved_at']),
    acknowledgedAt: _dateOrNull(row['acknowledged_at']),
    acknowledgedVersion: (row['acknowledged_version'] as num?)?.toInt(),
  );

  static DateTime? _dateOrNull(Object? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          (value as num).toInt(),
          isUtc: true,
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
  final Map<String, Map<int, StoredDocument>> _revisions = {};
  final Map<String, int> _revisionRequests = {};
  final Map<String, StoredDocumentMemberState> _memberStates = {};
  final Map<String, StoredDocumentAcknowledgement> _acknowledgements = {};

  @override
  Future<void> insert(StoredDocument document, {String? idempotencyKey}) async {
    _documents['${document.communityId}/${document.documentId}'] = document;
    _revisions['${document.communityId}/${document.documentId}'] = {
      document.version: document,
    };
    if (idempotencyKey != null) {
      _idempotencyKeys['${document.communityId}/$idempotencyKey'] =
          document.documentId;
    }
  }

  @override
  Future<StoredDocument?> findById({
    required String communityId,
    required String documentId,
  }) async {
    final revisions = _revisions['$communityId/$documentId'];
    if (revisions == null || revisions.isEmpty) {
      return _documents['$communityId/$documentId'];
    }
    final version = revisions.keys.reduce((a, b) => a > b ? a : b);
    return revisions[version];
  }

  @override
  Future<StoredDocument?> findByIdempotencyKey({
    required String communityId,
    required String idempotencyKey,
  }) async {
    final documentId = _idempotencyKeys['$communityId/$idempotencyKey'];
    if (documentId == null) return null;
    return findById(communityId: communityId, documentId: documentId);
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
          .map(
            (document) =>
                _revisions['${document.communityId}/${document.documentId}']!
                    .values
                    .reduce((a, b) => a.version > b.version ? a : b),
          )
          .toList()
        ..sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));

  @override
  Future<void> addRevision(
    StoredDocument revision, {
    required String idempotencyKey,
  }) async {
    _revisions['${revision.communityId}/${revision.documentId}']![revision
            .version] =
        revision;
    _revisionRequests['${revision.communityId}/${revision.documentId}/$idempotencyKey'] =
        revision.version;
  }

  @override
  Future<StoredDocument?> findRevision({
    required String communityId,
    required String documentId,
    required int version,
  }) async => _revisions['$communityId/$documentId']?[version];

  @override
  Future<StoredDocument?> findRevisionByIdempotencyKey({
    required String communityId,
    required String documentId,
    required String idempotencyKey,
  }) async {
    final version =
        _revisionRequests['$communityId/$documentId/$idempotencyKey'];
    return version == null
        ? null
        : _revisions['$communityId/$documentId']?[version];
  }

  @override
  Future<List<StoredDocument>> listRevisions({
    required String communityId,
    required String documentId,
  }) async {
    final revisions = _revisions['$communityId/$documentId'];
    if (revisions == null) return const <StoredDocument>[];
    return revisions.values.toList()
      ..sort((a, b) => a.version.compareTo(b.version));
  }

  @override
  Future<StoredDocumentMemberState?> findMemberState({
    required String communityId,
    required String documentId,
    required String fanId,
  }) async => _memberStates['$communityId/$documentId/$fanId'];

  @override
  Future<void> saveMemberState({
    required String communityId,
    required StoredDocumentMemberState state,
  }) async {
    _memberStates['$communityId/${state.documentId}/${state.fanId}'] = state;
  }

  @override
  Future<void> recordAcknowledgement({
    required String communityId,
    required StoredDocumentAcknowledgement acknowledgement,
  }) async {
    _acknowledgements['$communityId/${acknowledgement.documentId}/${acknowledgement.fanId}/${acknowledgement.version}'] ??=
        acknowledgement;
  }

  @override
  Future<List<StoredDocumentAcknowledgement>> listAcknowledgements({
    required String communityId,
    required String documentId,
    required bool currentVersionOnly,
    required int currentVersion,
  }) async {
    final prefix = '$communityId/$documentId/';
    final acknowledgements =
        _acknowledgements.entries
            .where((entry) => entry.key.startsWith(prefix))
            .map((entry) => entry.value)
            .where(
              (acknowledgement) =>
                  !currentVersionOnly ||
                  acknowledgement.version == currentVersion,
            )
            .toList()
          ..sort((a, b) => a.acknowledgedAt.compareTo(b.acknowledgedAt));
    return acknowledgements;
  }

  @override
  Future<void> delete({
    required String communityId,
    required String documentId,
  }) async {
    final prefix = '$communityId/$documentId/';
    _documents.remove('$communityId/$documentId');
    _revisions.remove('$communityId/$documentId');
    _idempotencyKeys.removeWhere((_, value) => value == documentId);
    _revisionRequests.removeWhere((key, _) => key.startsWith(prefix));
    _memberStates.removeWhere((key, _) => key.startsWith(prefix));
    _acknowledgements.removeWhere((key, _) => key.startsWith(prefix));
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
