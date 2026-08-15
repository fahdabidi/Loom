import 'dart:convert';
import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

const _appId = 'loom_communities';
const _permissionId = 'event_rsvp.create';
const _correlationId = '33333333-3333-4333-8333-333333333333';

void main() {
  final password = Platform.environment['LOOM_POSTGRES_PASSWORD'];
  final appAccessBaseUrl = Platform.environment['LOOM_APP_ACCESS_BASE_URL'];
  final skipReason = password == null || password.isEmpty
      ? 'Set LOOM_POSTGRES_PASSWORD to run against the k3s PostgreSQL '
            'port-forward.'
      : appAccessBaseUrl == null || appAccessBaseUrl.isEmpty
      ? 'Set LOOM_APP_ACCESS_BASE_URL to run against the live App Access '
            'port-forward.'
      : false;

  test(
    'live App Access grant permits createInstance and no grant refuses it',
    () async {
      final unique = '${DateTime.now().microsecondsSinceEpoch}-$pid';
      final communityId = 'community_workflow_b3_$unique';
      final communityHandle = 'b3-e2e-$unique';
      final groupId = 'loom_communities_$communityHandle';
      final roleId = 'b3-event-creator-$unique';
      final allowedFanId = 'fan-b3-allowed-$unique';
      final deniedFanId = 'fan-b3-denied-$unique';
      final workflowType = 'b3-event-$unique';
      final schema =
          'workflow_service_b3_test_'
          '${DateTime.now().microsecondsSinceEpoch}_$pid';

      final appAccessUri = Uri.parse(appAccessBaseUrl!);
      final seedClient = HttpClient();
      await _seedAppAccess(
        client: seedClient,
        baseUri: appAccessUri,
        groupId: groupId,
        roleId: roleId,
        fanId: allowedFanId,
        unique: unique,
      );

      final connection = await pg.Connection.open(
        pg.Endpoint(
          host: Platform.environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
          port: int.parse(
            Platform.environment['LOOM_POSTGRES_PORT'] ?? '15432',
          ),
          database:
              Platform.environment['LOOM_POSTGRES_DATABASE'] ??
              'loom_app_access',
          username: Platform.environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
          password: password,
        ),
        settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );

      WorkflowDatabase? database;
      HttpAppAccessDecisionClient? appAccessClient;
      HttpServer? workflowServer;
      final workflowHttpClient = HttpClient();
      var schemaCreated = false;
      try {
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');
        database = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        appAccessClient = HttpAppAccessDecisionClient(baseUri: appAccessUri);
        final service = WorkflowService(
          database: database,
          identityExtractor: const HeaderWorkflowIdentityExtractor(),
          appAccessClient: appAccessClient,
          communityGroupIdResolver: MapCommunityGroupIdResolver({
            communityId: groupId,
          }),
        );
        workflowServer = await shelf_io.serve(
          service.handler,
          InternetAddress.loopbackIPv4,
          0,
        );
        final workflowBaseUri = Uri.parse(
          'http://${workflowServer.address.host}:${workflowServer.port}/',
        );

        final definition = _workflowDefinition(roleId);
        final replace = await _sendJson(
          workflowHttpClient,
          'PUT',
          workflowBaseUri.resolve(
            'v1/communities/${Uri.encodeComponent(communityId)}/'
            'workflow-definitions',
          ),
          body: {
            'specVersion': 4,
            'definitions': {workflowType: definition},
          },
          fanId: 'fan-b3-installer-$unique',
          idempotencyKey: 'b3-replace-$unique',
        );
        expect(replace.statusCode, HttpStatus.ok, reason: replace.body);

        final allowed = await _sendJson(
          workflowHttpClient,
          'POST',
          workflowBaseUri.resolve(
            'v1/communities/${Uri.encodeComponent(communityId)}/instances',
          ),
          body: {
            'workflowType': workflowType,
            'instanceData': {'title': 'Allowed event'},
          },
          fanId: allowedFanId,
          idempotencyKey: 'b3-create-allowed-$unique',
        );
        expect(allowed.statusCode, HttpStatus.created, reason: allowed.body);
        final allowedJson = jsonDecode(allowed.body) as Map<String, dynamic>;
        expect(allowedJson['workflowType'], workflowType);
        expect(allowedJson['currentState'], 'draft');
        expect(
          allowedJson['instanceData'],
          containsPair('title', 'Allowed event'),
        );

        final denied = await _sendJson(
          workflowHttpClient,
          'POST',
          workflowBaseUri.resolve(
            'v1/communities/${Uri.encodeComponent(communityId)}/instances',
          ),
          body: {
            'workflowType': workflowType,
            'instanceData': {'title': 'Denied event'},
          },
          fanId: deniedFanId,
          idempotencyKey: 'b3-create-denied-$unique',
        );
        expect(denied.statusCode, HttpStatus.forbidden, reason: denied.body);
        expect(
          jsonDecode(denied.body),
          containsPair('code', 'workflow_create_refused'),
        );
        expect(denied.body, isNot(contains(_permissionId)));
        expect(denied.body, isNot(contains(roleId)));

        final storedAllowed = await database.readInstance(
          allowedJson['instanceId'] as String,
        );
        expect(storedAllowed, isNotNull);
        final page = await LocalWorkflowEngineApi(
          db: database,
          communityId: communityId,
        ).queryInstances(tabId: 'home', personaId: deniedFanId);
        expect(page.items, hasLength(1));
        expect(
          page.items.single.instanceData,
          containsPair('title', 'Allowed event'),
        );
      } finally {
        workflowHttpClient.close(force: true);
        await workflowServer?.close(force: true);
        appAccessClient?.close(force: true);
        seedClient.close(force: true);
        database?.close();
        if (schemaCreated) {
          await connection.execute('DROP SCHEMA $schema CASCADE');
        }
        await connection.close();
      }
    },
    skip: skipReason,
  );
}

Future<void> _seedAppAccess({
  required HttpClient client,
  required Uri baseUri,
  required String groupId,
  required String roleId,
  required String fanId,
  required String unique,
}) async {
  final normalizedBase = baseUri.path.endsWith('/')
      ? baseUri
      : baseUri.replace(path: '${baseUri.path}/');
  final group = await _sendJson(
    client,
    'POST',
    normalizedBase.resolve('v1/apps/$_appId/groups'),
    body: {'groupId': groupId, 'displayName': 'Workflow B.3 test $unique'},
    idempotencyKey: 'b3-group-$unique',
  );
  expect(group.statusCode, HttpStatus.created, reason: group.body);

  final role = await _sendJson(
    client,
    'POST',
    normalizedBase.resolve('v1/apps/$_appId/roles'),
    body: {
      'roleId': roleId,
      'groupId': groupId,
      'displayName': 'Workflow B.3 event creator',
    },
    idempotencyKey: 'b3-role-$unique',
  );
  expect(role.statusCode, HttpStatus.created, reason: role.body);

  final permissions = await _sendJson(
    client,
    'PUT',
    normalizedBase.resolve(
      'v1/apps/$_appId/roles/${Uri.encodeComponent(roleId)}/permissions',
    ),
    body: {
      'permissionIds': [_permissionId],
    },
    idempotencyKey: 'b3-permissions-$unique',
  );
  expect(permissions.statusCode, HttpStatus.ok, reason: permissions.body);

  final membership = await _sendJson(
    client,
    'PUT',
    normalizedBase.resolve(
      'v1/apps/$_appId/groups/${Uri.encodeComponent(groupId)}/members/'
      '${Uri.encodeComponent(fanId)}',
    ),
    body: {
      'roleIds': [roleId],
      'state': 'active',
    },
    idempotencyKey: 'b3-membership-$unique',
  );
  expect(membership.statusCode, HttpStatus.ok, reason: membership.body);
}

Map<String, dynamic> _workflowDefinition(String roleId) => {
  'initialState': 'draft',
  'states': {
    'draft': {'label': 'Draft'},
    'cancelled': {'label': 'Cancelled', 'tone': 'negative', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'cancel-event',
      'label': 'Cancel event',
      'action': 'cancel',
      'from': ['draft'],
      'to': 'cancelled',
      'guard': {
        'allowedRoleIds': [roleId],
      },
      'effects': <Map<String, dynamic>>[],
    },
  ],
  'renderBindings': [
    {
      'states': ['draft'],
      'role': 'any',
      'tabId': 'calendar',
      'cardSurfaceFamily': 'event-rsvp',
      'bindingKind': 'primary',
      'actions': [
        {
          'kind': 'create',
          'label': 'Create event',
          'byRoleIds': [roleId],
          'scope': 'tab',
          'presentation': 'fab',
        },
      ],
    },
  ],
  'instanceDataSchema': {
    'title': {
      'type': 'text',
      'required': true,
      'writableBy': 'formEntry',
      'storage': 'inline',
    },
  },
};

Future<_HttpResult> _sendJson(
  HttpClient client,
  String method,
  Uri uri, {
  required Map<String, dynamic> body,
  required String idempotencyKey,
  String? fanId,
}) async {
  final request = await client.openUrl(method, uri);
  request.headers.contentType = ContentType.json;
  request.headers.set('x-loom-correlation-id', _correlationId);
  request.headers.set('idempotency-key', idempotencyKey);
  if (fanId != null) {
    request.headers.set(
      HeaderWorkflowIdentityExtractor.defaultHeaderName,
      fanId,
    );
  }
  request.write(jsonEncode(body));
  final response = await request.close();
  return _HttpResult(
    response.statusCode,
    await utf8.decoder.bind(response).join(),
  );
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
