import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'workflow-transaction-rollback';
const _groupId = 'loom_communities_workflow-transaction-rollback';
const _queueWorkflowType = 'transaction-queue-item';
const _queueInstanceId = 'transaction-queue-item-one';
const _createWorkflowType = 'transaction-creatable-item';
const _correlationId = '99999999-9999-4999-8999-999999999999';
const _queueMember = 'fan-queue-member';
const _successfulQueueMember = 'fan-queue-success';
const _queueEffectFailureMember = 'fan-queue-effect-failure';
const _creator = 'fan-instance-creator';
const _queueEffectsInstanceId = 'transaction-queue-effects-item';
const _queueEffectsFailureInstanceId = 'transaction-queue-effects-failure';

const _queueDefinition = <String, dynamic>{
  'initialState': 'published',
  'visibility': <String, dynamic>{'default': 'public'},
  'states': <String, dynamic>{
    'published': <String, dynamic>{'label': 'Published'},
  },
  'transitions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'join-queue',
      'label': 'Join queue',
      'action': 'join_queue',
      'from': <String>['published'],
      'to': null,
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['queue-member'],
      },
      'effects': <Map<String, dynamic>>[
        <String, dynamic>{
          'op': 'append',
          'key': 'libraryActivityAudit',
          'value': <String, dynamic>{
            'event': 'joined-queue',
            'fanId': r'$actor',
            'at': r'$timestamp',
          },
        },
        <String, dynamic>{
          'op': 'appendUnique',
          'key': 'queuedFanIds',
          'value': r'$actor',
        },
      ],
    },
    <String, dynamic>{
      'id': 'leave-queue',
      'label': 'Leave queue',
      'action': 'leave_queue',
      'from': <String>['published'],
      'to': null,
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['queue-member'],
      },
      'effects': <Map<String, dynamic>>[
        <String, dynamic>{
          'op': 'append',
          'key': 'libraryActivityAudit',
          'value': <String, dynamic>{
            'event': 'left-queue',
            'fanId': r'$actor',
            'at': r'$timestamp',
          },
        },
        <String, dynamic>{
          'op': 'removeValue',
          'key': 'queuedFanIds',
          'value': r'$actor',
        },
      ],
    },
  ],
  'renderBindings': <Map<String, dynamic>>[
    <String, dynamic>{
      'states': <String>['published'],
      'audience': 'any',
      'tabId': 'marketplace',
      'cardSurfaceFamily': 'equipment-loan',
      'bindingKind': 'primary',
    },
  ],
  'instanceDataSchema': <String, dynamic>{
    'title': <String, dynamic>{'type': 'text', 'writableBy': 'formEntry'},
    'libraryActivityAudit': <String, dynamic>{
      'type': 'list',
      'writableBy': 'effect',
    },
    'queuedFanIds': <String, dynamic>{
      'type': 'fanId[]',
      'writableBy': 'effect',
    },
  },
};

const _createDefinition = <String, dynamic>{
  'initialState': 'draft',
  'states': <String, dynamic>{
    'draft': <String, dynamic>{'label': 'Draft'},
    'cancelled': <String, dynamic>{'label': 'Cancelled'},
  },
  'transitions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'cancel',
      'label': 'Cancel',
      'action': 'cancel',
      'from': <String>['draft'],
      'to': 'cancelled',
    },
  ],
  'renderBindings': <Map<String, dynamic>>[
    <String, dynamic>{
      'states': <String>['draft'],
      'audience': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': 'event-rsvp',
      'bindingKind': 'primary',
      'actions': <Map<String, dynamic>>[
        <String, dynamic>{
          'kind': 'create',
          'label': 'Create event',
          'byRoleIds': <String>['event-organizer'],
          'scope': 'tab',
          'presentation': 'fab',
        },
      ],
    },
  ],
  'instanceDataSchema': <String, dynamic>{
    'title': <String, dynamic>{
      'type': 'text',
      'required': true,
      'writableBy': 'formEntry',
    },
  },
};

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );
  final skip = configuration == null
      ? 'Set LOOM_POSTGRES_PASSWORD, LOOM_POSTGRES_APP_USERNAME, and '
            'LOOM_POSTGRES_APP_PASSWORD to run PostgreSQL rollback coverage.'
      : false;

  test(
    'PostgreSQL rolls back post-write item-queue and instance-creation failures while successful controls commit',
    () async {
      final config = configuration!;
      final schema = _uniqueIdentifier('workflow_transaction_rollback_test');
      final administrator = await _openDirectConnection(config);
      WorkflowPostgresConnection? migrationConnection;
      WorkflowPostgresConnection? postgres;
      var schemaCreated = false;

      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await administrator.execute('SET search_path TO $schema');
        migrationConnection = await _openAdminPool(config, schema);
        await migrationConnection.migrateWorkflowSchema();
        await PostgresItemQueueRepository(
          migrationConnection.connection,
        ).migrate();
        await migrationConnection.close();
        migrationConnection = null;
        await _grantRuntimeAccess(administrator, schema, config);

        postgres = await _openRuntimePool(config, schema);
        final queueRepository = PostgresItemQueueRepository(
          postgres.connection,
        );
        await postgres.runWithCommunity(_communityId, () async {
          await postgres!.database.upsertDefinition(
            definitionId: '${_communityId}_$_queueWorkflowType',
            workflowType: _queueWorkflowType,
            definitionJson: jsonEncode(_queueDefinition),
            version: currentCommunitySpecVersion,
          );
          await postgres.database.upsertDefinition(
            definitionId: '${_communityId}_$_createWorkflowType',
            workflowType: _createWorkflowType,
            definitionJson: jsonEncode(_createDefinition),
            version: currentCommunitySpecVersion,
          );
          await postgres.database.insertInstance(
            instanceId: _queueInstanceId,
            communityId: _communityId,
            workflowType: _queueWorkflowType,
            currentState: 'published',
            instanceData: const <String, dynamic>{
              'title': 'PostgreSQL transaction camera',
            },
            createdByFanId: 'fan-admin',
          );
        });

        final failingQueueService = _service(
          postgres,
          queueRepository,
          failAfter: 'item_queue_join',
        );
        final failedQueueResponse = await failingQueueService.handler(
          _queueJoinRequest(_queueMember),
        );
        expect(failedQueueResponse.statusCode, 500);
        expect(jsonDecode(await failedQueueResponse.readAsString()), {
          'code': 'workflow_service_error',
          'message': 'The item queue request could not be completed.',
          'correlationId': _correlationId,
        });
        await postgres.runWithCommunity(_communityId, () async {
          expect(
            await queueRepository.listForItem(
              communityId: _communityId,
              instanceId: _queueInstanceId,
            ),
            isEmpty,
            reason: 'the post-join failure must roll back its queue insert',
          );
        });

        final successfulQueueResponse = await _service(
          postgres,
          queueRepository,
        ).handler(_queueJoinRequest(_successfulQueueMember));
        expect(successfulQueueResponse.statusCode, 201);
        await postgres.runWithCommunity(_communityId, () async {
          final entries = await queueRepository.listForItem(
            communityId: _communityId,
            instanceId: _queueInstanceId,
          );
          expect(entries, hasLength(1));
          expect(entries.single.fanId, _successfulQueueMember);
        });

        final failingCreateService = _service(
          postgres,
          queueRepository,
          failAfter: 'create_instance',
        );
        final failedCreateResponse = await failingCreateService.handler(
          _createRequest('Fail after create'),
        );
        expect(failedCreateResponse.statusCode, 500);
        expect(jsonDecode(await failedCreateResponse.readAsString()), {
          'code': 'workflow_service_error',
          'message': 'The workflow instance could not be created.',
          'correlationId': _correlationId,
        });
        await postgres.runWithCommunity(_communityId, () async {
          expect(
            (await postgres!.database.queryCommunityInstancesByUpdatedAt(
              communityId: _communityId,
            )).where((row) => row.workflowType == _createWorkflowType),
            isEmpty,
            reason:
                'the post-create failure must roll back its instance insert',
          );
        });

        final successfulCreateResponse = await _service(
          postgres,
          queueRepository,
        ).handler(_createRequest('Committed after control'));
        expect(successfulCreateResponse.statusCode, 201);
        final successfulCreateBody =
            jsonDecode(await successfulCreateResponse.readAsString())
                as Map<String, dynamic>;
        await postgres.runWithCommunity(_communityId, () async {
          final created = await postgres!.database.readInstance(
            successfulCreateBody['instanceId'] as String,
          );
          expect(created, isNotNull);
          expect(created!.workflowType, _createWorkflowType);
        });
      } finally {
        await migrationConnection?.close();
        await postgres?.close();
        if (schemaCreated) {
          await administrator.execute('DROP SCHEMA $schema CASCADE');
        }
        await administrator.close();
      }
    },
    skip: skip,
  );

  test(
    'PostgreSQL queue membership changes compose declared effects without reviving legacy queue data',
    () async {
      final config = configuration!;
      final schema = _uniqueIdentifier('workflow_queue_effects_test');
      final administrator = await _openDirectConnection(config);
      WorkflowPostgresConnection? migrationConnection;
      WorkflowPostgresConnection? postgres;
      var schemaCreated = false;

      try {
        await administrator.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await administrator.execute('SET search_path TO $schema');
        migrationConnection = await _openAdminPool(config, schema);
        await migrationConnection.migrateWorkflowSchema();
        await PostgresItemQueueRepository(
          migrationConnection.connection,
        ).migrate();
        await migrationConnection.close();
        migrationConnection = null;
        await _grantRuntimeAccess(administrator, schema, config);

        postgres = await _openRuntimePool(config, schema);
        final queueRepository = PostgresItemQueueRepository(
          postgres.connection,
        );
        await postgres.runWithCommunity(_communityId, () async {
          await postgres!.database.upsertDefinition(
            definitionId: '${_communityId}_$_queueWorkflowType',
            workflowType: _queueWorkflowType,
            definitionJson: jsonEncode(_queueDefinition),
            version: currentCommunitySpecVersion,
          );
          for (final instanceId in const <String>[
            _queueEffectsInstanceId,
            _queueEffectsFailureInstanceId,
          ]) {
            await postgres.database.insertInstance(
              instanceId: instanceId,
              communityId: _communityId,
              workflowType: _queueWorkflowType,
              currentState: 'published',
              instanceData: <String, dynamic>{
                'title': 'Queue effects $instanceId',
                'libraryActivityAudit': <dynamic>[],
              },
              createdByFanId: 'fan-admin',
            );
          }
        });

        final service = _service(postgres, queueRepository);
        final joined = await service.handler(
          _queueJoinRequest(_queueMember, instanceId: _queueEffectsInstanceId),
        );
        expect(joined.statusCode, 201);
        await postgres.runWithCommunity(_communityId, () async {
          final entries = await queueRepository.listForItem(
            communityId: _communityId,
            instanceId: _queueEffectsInstanceId,
          );
          expect(entries, hasLength(1));
          expect(entries.single.fanId, _queueMember);
          final data = await _instanceData(postgres!, _queueEffectsInstanceId);
          final audit = _auditEntries(data);
          expect(audit, hasLength(1));
          expect(audit.single['event'], 'joined-queue');
          expect(audit.single['fanId'], _queueMember);
          expect(audit.single['at'], isA<String>());
          expect(data, isNot(contains('queuedFanIds')));
        });

        final replay = await service.handler(
          _queueJoinRequest(_queueMember, instanceId: _queueEffectsInstanceId),
        );
        expect(replay.statusCode, 200);
        await postgres.runWithCommunity(_communityId, () async {
          final data = await _instanceData(postgres!, _queueEffectsInstanceId);
          expect(
            _auditEntries(data),
            hasLength(1),
            reason: 'an idempotent join must not append a second audit event',
          );
        });

        final absentLeave = await service.handler(
          _queueLeaveRequest(
            _successfulQueueMember,
            instanceId: _queueEffectsInstanceId,
          ),
        );
        expect(absentLeave.statusCode, 204);
        await postgres.runWithCommunity(_communityId, () async {
          final data = await _instanceData(postgres!, _queueEffectsInstanceId);
          expect(
            _auditEntries(data),
            hasLength(1),
            reason: 'a no-op leave must not append an audit event',
          );
        });

        final left = await service.handler(
          _queueLeaveRequest(_queueMember, instanceId: _queueEffectsInstanceId),
        );
        expect(left.statusCode, 204);
        await postgres.runWithCommunity(_communityId, () async {
          expect(
            await queueRepository.listForItem(
              communityId: _communityId,
              instanceId: _queueEffectsInstanceId,
            ),
            isEmpty,
          );
          final audit = _auditEntries(
            await _instanceData(postgres!, _queueEffectsInstanceId),
          );
          expect(audit, hasLength(2));
          expect(audit.last['event'], 'left-queue');
          expect(audit.last['fanId'], _queueMember);
          expect(audit.last['at'], isA<String>());
        });

        final failed =
            await _service(
              postgres,
              queueRepository,
              failAfter: 'item_queue_join',
            ).handler(
              _queueJoinRequest(
                _queueEffectFailureMember,
                instanceId: _queueEffectsFailureInstanceId,
              ),
            );
        expect(failed.statusCode, 500);
        await postgres.runWithCommunity(_communityId, () async {
          expect(
            await queueRepository.listForItem(
              communityId: _communityId,
              instanceId: _queueEffectsFailureInstanceId,
            ),
            isEmpty,
            reason: 'the failing request must roll back the queue insert',
          );
          expect(
            _auditEntries(
              await _instanceData(postgres!, _queueEffectsFailureInstanceId),
            ),
            isEmpty,
            reason: 'the failing request must roll back the audit append',
          );
        });
      } finally {
        await migrationConnection?.close();
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

WorkflowService _service(
  WorkflowPostgresConnection postgres,
  ItemQueueRepository queueRepository, {
  String? failAfter,
}) => WorkflowService(
  database: postgres.database,
  communityTransactionRunner: postgres.runWithCommunity,
  identityExtractor: const HeaderWorkflowIdentityExtractor(),
  appAccessClient: const _AllowedAppAccessClient(),
  communityGroupIdResolver: MapCommunityGroupIdResolver({
    _communityId: _groupId,
  }),
  itemQueueRepository: queueRepository,
  postWriteFailureInjectorForTest: failAfter == null
      ? null
      : (phase) async {
          if (phase == failAfter) {
            throw StateError('Forced post-write $phase failure.');
          }
        },
);

Request _queueJoinRequest(
  String fanId, {
  String instanceId = _queueInstanceId,
}) => Request(
  'POST',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/'
    '$instanceId/queue',
  ),
  headers: <String, String>{
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);

Request _queueLeaveRequest(
  String fanId, {
  String instanceId = _queueInstanceId,
}) => Request(
  'DELETE',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances/'
    '$instanceId/queue',
  ),
  headers: <String, String>{
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: fanId,
  },
);

Future<Map<String, dynamic>> _instanceData(
  WorkflowPostgresConnection postgres,
  String instanceId,
) async {
  final row = await postgres.database.readInstance(instanceId);
  if (row == null) throw StateError('Missing instance $instanceId');
  return Map<String, dynamic>.from(jsonDecode(row.instanceData) as Map);
}

List<Map<String, dynamic>> _auditEntries(Map<String, dynamic> data) =>
    (data['libraryActivityAudit'] as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);

Request _createRequest(String title) => Request(
  'POST',
  Uri.parse('http://localhost/v1/communities/$_communityId/instances'),
  headers: const <String, String>{
    'content-type': 'application/json',
    'x-loom-correlation-id': _correlationId,
    'idempotency-key': 'transaction-rollback-create',
    HeaderWorkflowIdentityExtractor.defaultHeaderName: _creator,
  },
  body: jsonEncode(<String, dynamic>{
    'workflowType': _createWorkflowType,
    'instanceData': <String, dynamic>{'title': title},
  }),
);

class _AllowedAppAccessClient implements AppAccessDecisionClient {
  const _AllowedAppAccessClient();

  @override
  Future<bool> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    required String groupId,
    required String correlationId,
  }) async => true;

  @override
  Future<bool> hasActiveMembership({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => true;

  @override
  Future<List<GroupMember>> listGroupMembers({
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => const <GroupMember>[];

  @override
  Future<Set<String>> resolveRoleIds({
    required String fanId,
    required String appId,
    required String groupId,
    required String correlationId,
  }) async => switch (fanId) {
    _queueMember ||
    _successfulQueueMember ||
    _queueEffectFailureMember => const <String>{'queue-member'},
    _creator => const <String>{'event-organizer'},
    _ => const <String>{},
  };
}

class _PostgresConfiguration {
  const _PostgresConfiguration({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.adminUsername,
    required this.adminPassword,
    required this.appUsername,
    required this.appPassword,
  });

  final String host;
  final int port;
  final String databaseName;
  final String adminUsername;
  final String adminPassword;
  final String appUsername;
  final String appPassword;

  static _PostgresConfiguration? fromEnvironment(
    Map<String, String> environment,
  ) {
    final adminPassword = environment['LOOM_POSTGRES_PASSWORD'];
    final appUsername = environment['LOOM_POSTGRES_APP_USERNAME'];
    final appPassword = environment['LOOM_POSTGRES_APP_PASSWORD'];
    if (adminPassword == null ||
        adminPassword.isEmpty ||
        appUsername == null ||
        appUsername.isEmpty ||
        appPassword == null ||
        appPassword.isEmpty) {
      return null;
    }
    return _PostgresConfiguration(
      host: environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
      port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '15432'),
      databaseName: workflowPostgresDatabaseName(environment),
      adminUsername: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
      adminPassword: adminPassword,
      appUsername: appUsername,
      appPassword: appPassword,
    );
  }
}

Future<pg.Connection> _openDirectConnection(
  _PostgresConfiguration configuration,
) => pg.Connection.open(
  pg.Endpoint(
    host: configuration.host,
    port: configuration.port,
    database: configuration.databaseName,
    username: configuration.adminUsername,
    password: configuration.adminPassword,
  ),
  settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
);

Future<WorkflowPostgresConnection> _openAdminPool(
  _PostgresConfiguration configuration,
  String schema,
) => WorkflowPostgresConnection.open(
  host: configuration.host,
  port: configuration.port,
  databaseName: configuration.databaseName,
  username: configuration.adminUsername,
  password: configuration.adminPassword,
  onConnectionOpen: (connection) =>
      connection.execute('SET search_path TO $schema'),
);

Future<WorkflowPostgresConnection> _openRuntimePool(
  _PostgresConfiguration configuration,
  String schema,
) => WorkflowPostgresConnection.open(
  host: configuration.host,
  port: configuration.port,
  databaseName: configuration.databaseName,
  username: configuration.appUsername,
  password: configuration.appPassword,
  onConnectionOpen: (connection) =>
      connection.execute('SET search_path TO $schema'),
  migrationsManagedExternally: true,
);

Future<void> _grantRuntimeAccess(
  pg.Connection administrator,
  String schema,
  _PostgresConfiguration configuration,
) async {
  final role = _quoteIdentifier(configuration.appUsername);
  await administrator.execute('GRANT USAGE ON SCHEMA $schema TO $role');
  await administrator.execute(
    'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA $schema '
    'TO $role',
  );
  await administrator.execute(
    'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $schema TO $role',
  );
}

String _uniqueIdentifier(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$pid';

String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';
