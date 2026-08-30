import 'package:postgres/postgres.dart' as pg;

/// One member's durable place in an equipment-loan item queue.
///
/// Queue positions are deliberately derived from [sequence], rather than
/// stored. This makes every observed position one-based and contiguous after a
/// removal without a second update that can leave a gap behind.
class StoredItemQueueEntry {
  const StoredItemQueueEntry({
    required this.sequence,
    required this.communityId,
    required this.instanceId,
    required this.fanId,
    required this.joinedAt,
    this.offeredAt,
    this.offerExpiresAt,
  });

  final int sequence;
  final String communityId;
  final String instanceId;
  final String fanId;
  final DateTime joinedAt;
  final DateTime? offeredAt;
  final DateTime? offerExpiresAt;

  StoredItemQueueEntry withOffer({
    required DateTime offeredAt,
    required DateTime offerExpiresAt,
  }) => StoredItemQueueEntry(
    sequence: sequence,
    communityId: communityId,
    instanceId: instanceId,
    fanId: fanId,
    joinedAt: joinedAt,
    offeredAt: offeredAt,
    offerExpiresAt: offerExpiresAt,
  );

  Map<String, dynamic> toJson({required int position}) => <String, dynamic>{
    'fanId': fanId,
    'position': position,
    'joinedAt': joinedAt.toUtc().toIso8601String(),
    if (offeredAt != null) 'offeredAt': offeredAt!.toUtc().toIso8601String(),
    if (offerExpiresAt != null)
      'offerExpiresAt': offerExpiresAt!.toUtc().toIso8601String(),
  };
}

/// The result of identity-based queue insertion.
///
/// A duplicate identity is a successful no-op, not a new entry. The caller
/// needs [created] to choose the contract's 201 versus 200 response.
class ItemQueueJoinResult {
  const ItemQueueJoinResult({required this.entry, required this.created});

  final StoredItemQueueEntry entry;
  final bool created;
}

/// Durable item-queue storage.
///
/// The queue is intentionally not instance data. It has an independent
/// lifetime, records join time, and supports the cross-item membership query
/// without reading every listing in a community.
abstract interface class ItemQueueRepository {
  Future<ItemQueueJoinResult> join({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime joinedAt,
  });

  Future<List<StoredItemQueueEntry>> listForItem({
    required String communityId,
    required String instanceId,
  });

  Future<List<StoredItemQueueEntry>> listForFan({
    required String communityId,
    required String fanId,
  });

  Future<void> remove({
    required String communityId,
    required String instanceId,
    required String fanId,
  });

  Future<void> recordOffer({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime offeredAt,
    required DateTime offerExpiresAt,
  });
}

/// PostgreSQL item-queue storage used by the deployed workflow service.
class PostgresItemQueueRepository implements ItemQueueRepository {
  PostgresItemQueueRepository(this._connection);

  final pg.Session _connection;

  Future<void> migrate() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS workflow_item_queue_entries (
        entry_id BIGSERIAL PRIMARY KEY,
        community_id TEXT NOT NULL,
        instance_id TEXT NOT NULL,
        fan_id TEXT NOT NULL,
        joined_at BIGINT NOT NULL,
        offered_at BIGINT,
        offer_expires_at BIGINT,
        UNIQUE (community_id, instance_id, fan_id)
      );
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_queue_entries_item
        ON workflow_item_queue_entries (community_id, instance_id, entry_id);
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_item_queue_entries_fan
        ON workflow_item_queue_entries (community_id, fan_id, entry_id);
    ''');
  }

  @override
  Future<ItemQueueJoinResult> join({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime joinedAt,
  }) async {
    final inserted = await _connection.execute(
      pg.Sql.named('''
        INSERT INTO workflow_item_queue_entries (
          community_id, instance_id, fan_id, joined_at
        ) VALUES (@communityId, @instanceId, @fanId, @joinedAt)
        ON CONFLICT (community_id, instance_id, fan_id) DO NOTHING
        RETURNING $_columns
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'instanceId': instanceId,
        'fanId': fanId,
        'joinedAt': joinedAt.toUtc().millisecondsSinceEpoch,
      },
    );
    if (inserted.isNotEmpty) {
      return ItemQueueJoinResult(
        entry: _fromRow(inserted.single.toColumnMap()),
        created: true,
      );
    }

    final existing = await _findByIdentity(
      communityId: communityId,
      instanceId: instanceId,
      fanId: fanId,
    );
    if (existing == null) {
      throw StateError('Queue entry disappeared after an identity conflict.');
    }
    return ItemQueueJoinResult(entry: existing, created: false);
  }

  @override
  Future<List<StoredItemQueueEntry>> listForItem({
    required String communityId,
    required String instanceId,
  }) => _list(
    '''
      SELECT $_columns FROM workflow_item_queue_entries
      WHERE community_id = @communityId AND instance_id = @instanceId
      ORDER BY entry_id ASC
    ''',
    <String, dynamic>{'communityId': communityId, 'instanceId': instanceId},
  );

  @override
  Future<List<StoredItemQueueEntry>> listForFan({
    required String communityId,
    required String fanId,
  }) => _list(
    '''
      SELECT $_columns FROM workflow_item_queue_entries
      WHERE community_id = @communityId AND fan_id = @fanId
      ORDER BY entry_id ASC
    ''',
    <String, dynamic>{'communityId': communityId, 'fanId': fanId},
  );

  @override
  Future<void> remove({
    required String communityId,
    required String instanceId,
    required String fanId,
  }) async {
    await _connection.execute(
      pg.Sql.named('''
        DELETE FROM workflow_item_queue_entries
        WHERE community_id = @communityId
          AND instance_id = @instanceId
          AND fan_id = @fanId
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'instanceId': instanceId,
        'fanId': fanId,
      },
    );
  }

  @override
  Future<void> recordOffer({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime offeredAt,
    required DateTime offerExpiresAt,
  }) async {
    await _connection.execute(
      pg.Sql.named('''
        UPDATE workflow_item_queue_entries
        SET offered_at = @offeredAt, offer_expires_at = @offerExpiresAt
        WHERE community_id = @communityId
          AND instance_id = @instanceId
          AND fan_id = @fanId
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'instanceId': instanceId,
        'fanId': fanId,
        'offeredAt': offeredAt.toUtc().millisecondsSinceEpoch,
        'offerExpiresAt': offerExpiresAt.toUtc().millisecondsSinceEpoch,
      },
    );
  }

  Future<StoredItemQueueEntry?> _findByIdentity({
    required String communityId,
    required String instanceId,
    required String fanId,
  }) async {
    final rows = await _connection.execute(
      pg.Sql.named('''
        SELECT $_columns FROM workflow_item_queue_entries
        WHERE community_id = @communityId
          AND instance_id = @instanceId
          AND fan_id = @fanId
      '''),
      parameters: <String, dynamic>{
        'communityId': communityId,
        'instanceId': instanceId,
        'fanId': fanId,
      },
    );
    return rows.isEmpty ? null : _fromRow(rows.single.toColumnMap());
  }

  Future<List<StoredItemQueueEntry>> _list(
    String statement,
    Map<String, dynamic> parameters,
  ) async {
    final rows = await _connection.execute(
      pg.Sql.named(statement),
      parameters: parameters,
    );
    return rows.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  static const _columns =
      'entry_id, community_id, instance_id, fan_id, joined_at, offered_at, '
      'offer_expires_at';

  static StoredItemQueueEntry _fromRow(Map<String, dynamic> row) =>
      StoredItemQueueEntry(
        sequence: (row['entry_id'] as num).toInt(),
        communityId: row['community_id'] as String,
        instanceId: row['instance_id'] as String,
        fanId: row['fan_id'] as String,
        joinedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['joined_at'] as num).toInt(),
          isUtc: true,
        ),
        offeredAt: row['offered_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (row['offered_at'] as num).toInt(),
                isUtc: true,
              ),
        offerExpiresAt: row['offer_expires_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (row['offer_expires_at'] as num).toInt(),
                isUtc: true,
              ),
      );
}

/// In-memory queue storage for endpoint tests.
class InMemoryItemQueueRepository implements ItemQueueRepository {
  final Map<String, StoredItemQueueEntry> _entries =
      <String, StoredItemQueueEntry>{};
  var _nextSequence = 1;

  @override
  Future<ItemQueueJoinResult> join({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime joinedAt,
  }) async {
    final key = _key(communityId, instanceId, fanId);
    final existing = _entries[key];
    if (existing != null) {
      return ItemQueueJoinResult(entry: existing, created: false);
    }
    final entry = StoredItemQueueEntry(
      sequence: _nextSequence++,
      communityId: communityId,
      instanceId: instanceId,
      fanId: fanId,
      joinedAt: joinedAt.toUtc(),
    );
    _entries[key] = entry;
    return ItemQueueJoinResult(entry: entry, created: true);
  }

  @override
  Future<List<StoredItemQueueEntry>> listForItem({
    required String communityId,
    required String instanceId,
  }) async => _sorted(
    _entries.values.where(
      (entry) =>
          entry.communityId == communityId && entry.instanceId == instanceId,
    ),
  );

  @override
  Future<List<StoredItemQueueEntry>> listForFan({
    required String communityId,
    required String fanId,
  }) async => _sorted(
    _entries.values.where(
      (entry) => entry.communityId == communityId && entry.fanId == fanId,
    ),
  );

  @override
  Future<void> remove({
    required String communityId,
    required String instanceId,
    required String fanId,
  }) async {
    _entries.remove(_key(communityId, instanceId, fanId));
  }

  @override
  Future<void> recordOffer({
    required String communityId,
    required String instanceId,
    required String fanId,
    required DateTime offeredAt,
    required DateTime offerExpiresAt,
  }) async {
    final key = _key(communityId, instanceId, fanId);
    final entry = _entries[key];
    if (entry == null) {
      throw StateError('Cannot offer a missing queue entry.');
    }
    _entries[key] = entry.withOffer(
      offeredAt: offeredAt.toUtc(),
      offerExpiresAt: offerExpiresAt.toUtc(),
    );
  }

  static List<StoredItemQueueEntry> _sorted(
    Iterable<StoredItemQueueEntry> entries,
  ) => entries.toList()..sort((a, b) => a.sequence.compareTo(b.sequence));

  static String _key(String communityId, String instanceId, String fanId) =>
      '$communityId/$instanceId/$fanId';
}
