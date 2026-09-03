import 'package:postgres/postgres.dart' as pg;

import 'postgres_connection.dart';

/// The record associated with an idempotent write and whether this caller made
/// it durable.
///
/// A replay is successful work: [record] is the original record and [created]
/// is false. Callers use that distinction when an endpoint has different
/// create and replay status codes.
class IdempotentWrite<T> {
  const IdempotentWrite({required this.record, required this.created});

  final T record;
  final bool created;
}

/// Atomically creates or reloads one record identified by an idempotency key.
///
/// [create] must issue one `INSERT ... ON CONFLICT DO NOTHING RETURNING`
/// statement and return null when another request won the uniqueness race.
/// All three callbacks run in the same community-scoped PostgreSQL
/// transaction. When the caller is already in a community transaction,
/// [runWithPostgresCommunity] reuses its session rather than opening another
/// transaction.
Future<IdempotentWrite<T>> runIdempotent<T>({
  required pg.SessionExecutor executor,
  required String communityId,
  required Future<T?> Function() lookup,
  required Future<T?> Function() create,
  required Future<T> Function() reload,
}) => runWithPostgresCommunity<IdempotentWrite<T>>(
  executor: executor,
  communityId: communityId,
  action: () async {
    final existing = await lookup();
    if (existing != null) {
      return IdempotentWrite<T>(record: existing, created: false);
    }

    final inserted = await create();
    if (inserted != null) {
      return IdempotentWrite<T>(record: inserted, created: true);
    }

    // A losing ON CONFLICT statement is expected under concurrent retries.
    // Read the winner in this transaction's next statement, which receives a
    // fresh READ COMMITTED snapshot after the winning transaction commits.
    return IdempotentWrite<T>(record: await reload(), created: false);
  },
);
