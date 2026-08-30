import 'dart:async';
import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );
  final skip = configuration == null
      ? 'Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL '
            'port-forward.'
      : false;

  test(
    'a pooled workflow query recovers after its borrowed connection is forced closed',
    () async {
      final postgres = await _openPool(configuration!);
      addTearDown(postgres.close);

      expect((await postgres.connection.execute('SELECT 1')).single.single, 1);
      await postgres.connection.withConnection((connection) async {
        await connection.close(force: true);
      });

      expect((await postgres.connection.execute('SELECT 1')).single.single, 1);
    },
    skip: skip,
  );

  test(
    'concurrent workflow requests stay within the configured pool bound',
    () async {
      final openedConnections = <pg.Connection>[];
      final postgres = await _openPool(
        configuration!,
        onConnectionOpen: (connection) async {
          openedConnections.add(connection);
        },
      );
      addTearDown(postgres.close);

      final allBoundSlotsAcquired = Completer<void>();
      final release = Completer<void>();
      var active = 0;
      final requests = <Future<void>>[];
      for (
        var index = 0;
        index < workflowPostgresPoolMaxConnectionCount + 2;
        index++
      ) {
        requests.add(
          postgres.connection.withConnection((_) async {
            active++;
            if (active == workflowPostgresPoolMaxConnectionCount) {
              allBoundSlotsAcquired.complete();
            }
            await release.future;
            active--;
          }),
        );
      }

      await allBoundSlotsAcquired.future.timeout(const Duration(seconds: 5));
      expect(active, workflowPostgresPoolMaxConnectionCount);
      expect(
        openedConnections.length,
        lessThanOrEqualTo(workflowPostgresPoolMaxConnectionCount),
      );

      release.complete();
      await Future.wait(requests);
      expect(
        openedConnections.length,
        lessThanOrEqualTo(workflowPostgresPoolMaxConnectionCount),
      );
    },
    skip: skip,
  );

  test('workflow pool close releases every opened connection', () async {
    final openedConnections = <pg.Connection>[];
    final postgres = await _openPool(
      configuration!,
      onConnectionOpen: (connection) async {
        openedConnections.add(connection);
      },
    );
    var closed = false;
    addTearDown(() async {
      if (!closed) await postgres.close();
    });

    await postgres.connection.execute('SELECT 1');
    await postgres.close().timeout(const Duration(seconds: 5));
    closed = true;

    expect(postgres.connection.isOpen, isFalse);
    await postgres.connection.closed.timeout(const Duration(seconds: 1));
    expect(openedConnections, isNotEmpty);
    expect(openedConnections.every((connection) => !connection.isOpen), isTrue);
  }, skip: skip);

  test(
    'workflow transactions keep FOR UPDATE locked when another pool borrower occupies the original connection',
    () async {
      final config = configuration!;
      final schema = _uniqueIdentifier('workflow_pool_transaction_test');
      final administrator = await _openDirectConnection(config);
      var schemaCreated = false;
      WorkflowPostgresConnection? postgres;
      final releaseTransaction = Completer<void>();
      Future<void>? firstTransaction;

      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        postgres = await _openPool(
          config,
          onConnectionOpen: (connection) async {
            await connection.execute('SET search_path TO $schema');
          },
        );
        await postgres.migrateWorkflowSchema();
        await postgres.database.insertInstance(
          instanceId: 'locked-instance',
          communityId: 'pool-transaction-community',
          workflowType: 'pool-transaction-workflow',
          currentState: 'draft',
          instanceData: const {'initial': true},
          createdByFanId: 'member',
        );

        final backgroundBorrowerAcquired = Completer<void>();
        final rowLocked = Completer<void>();
        firstTransaction = postgres.database.transaction(() async {
          // A statement-based BEGIN would release its first borrowed
          // connection before the action runs. This borrower then takes that
          // connection, forcing the following FOR UPDATE onto another one.
          // The transaction runner must instead keep the original connection
          // reserved, leaving this borrower to use a second connection.
          final backgroundBorrower = postgres!.connection.withConnection((
            connection,
          ) async {
            backgroundBorrowerAcquired.complete();
            await connection.execute('SELECT pg_sleep(1)');
          });
          await backgroundBorrowerAcquired.future.timeout(
            const Duration(seconds: 5),
          );

          final row = await postgres.database.readInstanceForUpdate(
            'locked-instance',
          );
          expect(row, isNotNull);
          rowLocked.complete();
          await releaseTransaction.future;
          await backgroundBorrower;
        });

        await rowLocked.future.timeout(const Duration(seconds: 5));
        var outsideUpdateCompleted = false;
        final outsideUpdate = administrator
            .execute(
              'UPDATE $schema.workflow_instances '
              "SET current_state = 'updated' WHERE instance_id = 'locked-instance'",
            )
            .then((_) {
              outsideUpdateCompleted = true;
            });

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(
          outsideUpdateCompleted,
          isFalse,
          reason:
              'SELECT FOR UPDATE must retain its row lock until the workflow '
              'transaction completes.',
        );

        releaseTransaction.complete();
        await Future.wait([firstTransaction, outsideUpdate]);
        expect(outsideUpdateCompleted, isTrue);
      } finally {
        if (!releaseTransaction.isCompleted) releaseTransaction.complete();
        if (firstTransaction != null) {
          try {
            await firstTransaction;
          } catch (_) {
            // Preserve the assertion or setup error that is already in flight.
          }
        }
        await postgres?.close();
        if (schemaCreated) {
          await administrator.execute('DROP SCHEMA $schema CASCADE');
        }
        await administrator.close();
      }
    },
    skip: skip,
  );
}

class _PostgresConfiguration {
  const _PostgresConfiguration({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.username,
    required this.password,
  });

  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String password;

  static _PostgresConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final password = environment['LOOM_POSTGRES_PASSWORD'];
    if (password == null || password.isEmpty) return null;
    return _PostgresConfiguration(
      host: environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
      port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '15432'),
      databaseName: workflowPostgresDatabaseName(environment),
      username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
      password: password,
    );
  }
}

Future<WorkflowPostgresConnection> _openPool(
  _PostgresConfiguration configuration, {
  Future<void> Function(pg.Connection connection)? onConnectionOpen,
}) {
  return WorkflowPostgresConnection.open(
    host: configuration.host,
    port: configuration.port,
    databaseName: configuration.databaseName,
    username: configuration.username,
    password: configuration.password,
    onConnectionOpen: onConnectionOpen,
  );
}

Future<pg.Connection> _openDirectConnection(
  _PostgresConfiguration configuration,
) {
  return pg.Connection.open(
    pg.Endpoint(
      host: configuration.host,
      port: configuration.port,
      database: configuration.databaseName,
      username: configuration.username,
      password: configuration.password,
    ),
    settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
  );
}

String _uniqueIdentifier(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$pid';
