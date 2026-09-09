import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _communityId = 'reminder-at-serialization';
const _groupId = 'loom_communities_reminder-at-serialization';
const _ungatedWorkflowType = 'ungated-reminder';
const _gatedWorkflowType = 'gated-reminder';
const _correlationId = 'd0e8f0ae-2cf0-44b2-9bcb-972d7dd0e34d';

void main() {
  final configuration = _PostgresConfiguration.fromEnvironment(
    Platform.environment,
  );
  final skip = configuration == null
      ? 'Set LOOM_POSTGRES_PASSWORD, LOOM_POSTGRES_APP_USERNAME, and '
            'LOOM_POSTGRES_APP_PASSWORD to run PostgreSQL reminder '
            'serialization coverage.'
      : false;

  test(
    'PostgreSQL listings serialize ungated reminderAt and retain an unset gated reminder',
    () async {
      final config = configuration!;
      final schema = _uniqueIdentifier('workflow_reminder_serialization_test');
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
        await migrationConnection.close();
        migrationConnection = null;
        await _grantRuntimeAccess(administrator, schema, config);

        postgres = await _openRuntimePool(config, schema);
        await postgres.runWithCommunity(_communityId, () async {
          await postgres!.database.upsertDefinition(
            definitionId: '${_communityId}_$_ungatedWorkflowType',
            workflowType: _ungatedWorkflowType,
            definitionJson: jsonEncode(_reminderDefinition()),
            version: currentCommunitySpecVersion,
          );
          await postgres.database.upsertDefinition(
            definitionId: '${_communityId}_$_gatedWorkflowType',
            workflowType: _gatedWorkflowType,
            definitionJson: jsonEncode(_reminderDefinition(enabledField: true)),
            version: currentCommunitySpecVersion,
          );
          await postgres.database.insertInstance(
            instanceId: 'ungated-reminder-instance',
            communityId: _communityId,
            workflowType: _ungatedWorkflowType,
            currentState: 'scheduled',
            instanceData: const <String, dynamic>{
              'eventDate': '2026-03-10',
              'eventTime': '18:00',
            },
            createdByFanId: 'fan-reader',
          );
          await postgres.database.insertInstance(
            instanceId: 'gated-reminder-instance',
            communityId: _communityId,
            workflowType: _gatedWorkflowType,
            currentState: 'scheduled',
            instanceData: const <String, dynamic>{
              'eventDate': '2026-03-10',
              'eventTime': '18:00',
            },
            createdByFanId: 'fan-reader',
          );
        });

        final service = WorkflowService(
          database: postgres.database,
          communityTransactionRunner: postgres.runWithCommunity,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: const _ReaderAppAccessClient(),
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            _communityId: _groupId,
          }),
        );

        final ungatedResponse = await service.handler(
          _listRequest(workflowType: _ungatedWorkflowType),
        );
        final ungatedBody = await ungatedResponse.readAsString();
        expect(ungatedResponse.statusCode, 200, reason: ungatedBody);
        final ungatedItems =
            (jsonDecode(ungatedBody) as Map<String, dynamic>)['items'] as List;
        expect(ungatedItems, hasLength(1));
        final ungatedData =
            (ungatedItems.single as Map<String, dynamic>)['instanceData']
                as Map<String, dynamic>;
        expect(ungatedData['reminderAt'], '2026-03-09T18:00:00.000Z');
        expect(ungatedData['formulaDueAt'], '2026-03-10T16:00:00.000Z');

        final allResponse = await service.handler(_listRequest());
        final allBody = await allResponse.readAsString();
        expect(allResponse.statusCode, 200, reason: allBody);
        final allItems =
            (jsonDecode(allBody) as Map<String, dynamic>)['items'] as List;
        expect(allItems, hasLength(2));

        final gatedResponse = await service.handler(
          _listRequest(workflowType: _gatedWorkflowType),
        );
        final gatedBody = await gatedResponse.readAsString();
        expect(gatedResponse.statusCode, 200, reason: gatedBody);
        final gatedItems =
            (jsonDecode(gatedBody) as Map<String, dynamic>)['items'] as List;
        expect(gatedItems, hasLength(1));
        final gatedData =
            (gatedItems.single as Map<String, dynamic>)['instanceData']
                as Map<String, dynamic>;
        expect(gatedData.containsKey('reminderAt'), isFalse);
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

Map<String, dynamic> _reminderDefinition({bool enabledField = false}) => {
  'initialState': 'scheduled',
  'visibility': <String, dynamic>{'default': 'public'},
  'states': <String, dynamic>{
    'scheduled': <String, dynamic>{'label': 'Scheduled'},
  },
  'transitions': const <Map<String, dynamic>>[],
  'reminder': <String, dynamic>{
    'anchorDateField': 'eventDate',
    'anchorTimeField': 'eventTime',
    'leadHours': 24,
    if (enabledField) 'enabledField': 'reminderEnabled',
  },
  'instanceDataSchema': <String, dynamic>{
    'eventDate': <String, dynamic>{'type': 'date', 'required': true},
    'eventTime': <String, dynamic>{'type': 'time', 'required': true},
    'formulaDueAt': <String, dynamic>{
      'type': 'date',
      'formula': 'subtractHours(combineDateAndTime(eventDate, eventTime), 2)',
    },
    if (enabledField) 'reminderEnabled': <String, dynamic>{'type': 'boolean'},
  },
};

Request _listRequest({String? workflowType}) => Request(
  'GET',
  Uri.parse(
    'http://localhost/v1/communities/$_communityId/instances'
    '${workflowType == null ? '' : '?workflowType=$workflowType'}',
  ),
  headers: const <String, String>{
    'x-loom-correlation-id': _correlationId,
    HeaderWorkflowIdentityExtractor.defaultHeaderName: 'fan-reader',
  },
);

class _ReaderAppAccessClient implements AppAccessDecisionClient {
  const _ReaderAppAccessClient();

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
  }) async => const <String>{};
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
