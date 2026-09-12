import 'dart:convert';
import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

/// Live-test requirements:
///
/// - `LOOM_POSTGRES_PASSWORD` for the PostgreSQL instance (with the existing
///   optional host, port, database, and username overrides);
/// - `LOOM_APP_ACCESS_BASE_URL` for the live App Access service;
/// - `LOOM_KEYCLOAK_TOKEN_URL` for the `loom` realm token endpoint;
/// - `LOOM_KEYCLOAK_ADMIN_URL` for the Keycloak base URL; and
/// - `LOOM_KEYCLOAK_ADMIN_USERNAME` and `LOOM_KEYCLOAK_ADMIN_PASSWORD` for
///   the bootstrap realm administrator.
///
/// The test skips with the first missing requirement rather than silently
/// substituting credentials or infrastructure addresses.
const _appId = 'loom_communities';
const _permissionId = 'event_rsvp.create';

/// The archetype whose `create` action derives [_permissionId].
///
/// `installCommunityPackage` discovers the permission from this workflow's
/// resolved family and its `createRoleIds`, so both must agree with
/// [_permissionId]: an `event-rsvp` family derives `event_rsvp.create`, and
/// any other family would derive a different permission and quietly stop
/// authorizing the create this test asserts.
const _cardSurfaceFamily = 'event-rsvp';
const _correlationId = '33333333-3333-4333-8333-333333333333';
const _keycloakRealm = 'loom';

/// The realm role `requireProvisioningPrincipal` checks for on the
/// community-installation and permission-export routes. Created out of band in
/// the cluster; this test only assigns it to its own throwaway client.
const _provisioningRealmRole = 'app-access-provisioner';

@Timeout(const Duration(minutes: 2))
void main() {
  final environment = Platform.environment;
  final password = environment['LOOM_POSTGRES_PASSWORD'];
  final appAccessBaseUrl = environment['LOOM_APP_ACCESS_BASE_URL'];
  final keycloakTokenUrl = environment['LOOM_KEYCLOAK_TOKEN_URL'];
  final keycloakAdminUrl = environment['LOOM_KEYCLOAK_ADMIN_URL'];
  final keycloakAdminUsername = environment['LOOM_KEYCLOAK_ADMIN_USERNAME'];
  final keycloakAdminPassword = environment['LOOM_KEYCLOAK_ADMIN_PASSWORD'];
  final skipReason = _liveTestSkipReason(environment);

  test(
    'live App Access authorizes create and Postgres rolls back an invalid batch',
    () async {
      final unique = '${DateTime.now().microsecondsSinceEpoch}-$pid';
      final communityId = 'community_workflow_b3_$unique';
      final communityHandle = 'b3-e2e-$unique';
      final groupId = 'loom_communities_$communityHandle';
      final roleId = 'b3-event-creator-$unique';
      final allowedFanId = 'fan-b3-allowed-$unique';
      final deniedFanId = 'fan-b3-denied-$unique';
      final workflowType = 'b3-event-$unique';
      final keycloakClientName = 'loom-workflow-service-test-$unique';
      final schema =
          'workflow_service_b3_test_'
          '${DateTime.now().microsecondsSinceEpoch}_$pid';

      final appAccessUri = Uri.parse(appAccessBaseUrl!);
      final keycloakTokenUri = Uri.parse(keycloakTokenUrl!);
      final keycloakAdminBaseUri = _normalizeBaseUri(
        Uri.parse(keycloakAdminUrl!),
      );
      final keycloakAdminClient = HttpClient();
      final seedClient = HttpClient();
      pg.Connection? connection;
      WorkflowDatabase? database;
      HttpAppAccessDecisionClient? appAccessClient;
      HttpServer? workflowServer;
      final workflowHttpClient = HttpClient();
      String? keycloakAdminToken;
      String? keycloakClientId;
      var schemaCreated = false;
      try {
        keycloakAdminToken = await _obtainKeycloakToken(
          client: keycloakAdminClient,
          tokenUri: keycloakAdminBaseUri.resolve(
            'realms/master/protocol/openid-connect/token',
          ),
          form: {
            'grant_type': 'password',
            'client_id': 'admin-cli',
            'username': keycloakAdminUsername!,
            'password': keycloakAdminPassword!,
          },
          purpose: 'bootstrap administrator',
        );
        keycloakClientId = await _createKeycloakClient(
          client: keycloakAdminClient,
          adminBaseUri: keycloakAdminBaseUri,
          adminToken: keycloakAdminToken,
          clientName: keycloakClientName,
        );
        // A freshly created client authenticates but is authorized for
        // nothing: `installCommunityPackage` is gated behind
        // `requireProvisioningPrincipal`, so without the realm role below this
        // test's `_seedAppAccess` install returns 403
        // `provisioning_principal_required` even though the token is valid.
        // Granting the throwaway client's own service-account user the
        // `app-access-provisioner` realm role is what closes that gap, and it
        // is the same procedure performed by hand to prove the chain works.
        await _grantProvisioningRealmRole(
          client: keycloakAdminClient,
          adminBaseUri: keycloakAdminBaseUri,
          adminToken: keycloakAdminToken,
          clientUuid: keycloakClientId,
        );
        final keycloakClientSecret = await _getKeycloakClientSecret(
          client: keycloakAdminClient,
          adminBaseUri: keycloakAdminBaseUri,
          adminToken: keycloakAdminToken,
          clientId: keycloakClientId,
        );
        final appAccessBearerToken = await _obtainKeycloakToken(
          client: keycloakAdminClient,
          tokenUri: keycloakTokenUri,
          form: {
            'grant_type': 'client_credentials',
            'client_id': keycloakClientName,
            'client_secret': keycloakClientSecret,
          },
          purpose: 'throwaway App Access service account',
        );
        await _seedAppAccess(
          client: seedClient,
          baseUri: appAccessUri,
          bearerToken: appAccessBearerToken,
          groupId: groupId,
          roleId: roleId,
          fanId: allowedFanId,
          unique: unique,
        );

        connection = await pg.Connection.open(
          pg.Endpoint(
            host: environment['LOOM_POSTGRES_HOST'] ?? '127.0.0.1',
            port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '15432'),
            database:
                environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access',
            username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
            password: password,
          ),
          settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
        );
        await connection.execute('CREATE SCHEMA $schema');
        schemaCreated = true;
        await connection.execute('SET search_path TO $schema');
        database = WorkflowDatabase.withExecutor(
          PgDatabase.opened(connection, enableMigrations: false),
          dialect: WorkflowSqlDialect.postgres,
        );
        appAccessClient = HttpAppAccessDecisionClient(
          baseUri: appAccessUri,
          tokenUri: keycloakTokenUri,
          clientId: keycloakClientName,
          clientSecret: keycloakClientSecret,
        );
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
            'specVersion': currentCommunitySpecVersion,
            'definitions': {workflowType: definition},
          },
          fanId: 'fan-b3-installer-$unique',
          idempotencyKey: 'b3-replace-$unique',
        );
        expect(replace.statusCode, HttpStatus.ok, reason: replace.body);

        final invalidBatch = await _sendJson(
          workflowHttpClient,
          'POST',
          workflowBaseUri.resolve(
            'v1/communities/${Uri.encodeComponent(communityId)}/'
            'instances/batch',
          ),
          body: {
            'workflowType': workflowType,
            'initialInstanceDataList': [
              {'title': 'Must be rolled back'},
              <String, dynamic>{},
            ],
          },
          fanId: allowedFanId,
          idempotencyKey: 'b3-create-batch-invalid-$unique',
        );
        expect(
          invalidBatch.statusCode,
          HttpStatus.badRequest,
          reason: invalidBatch.body,
        );
        expect(
          jsonDecode(invalidBatch.body),
          containsPair('code', 'invalid_request'),
        );
        final afterInvalidBatch = await LocalWorkflowEngineApi(
          db: database,
          communityId: communityId,
        ).queryInstances(tabId: 'home', fanId: allowedFanId);
        expect(
          afterInvalidBatch.items,
          isEmpty,
          reason:
              'The valid first item must be rolled back when the second item '
              'fails required-field validation.',
        );

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
        ).queryInstances(tabId: 'home', fanId: deniedFanId);
        expect(page.items, hasLength(1));
        expect(
          page.items.single.instanceData,
          containsPair('title', 'Allowed event'),
        );
      } finally {
        workflowHttpClient.close(force: true);
        await workflowServer?.close(force: true);
        appAccessClient?.close(force: true);
        database?.close();
        try {
          if (schemaCreated) {
            await connection?.execute('DROP SCHEMA $schema CASCADE');
          }
          await connection?.close();
        } finally {
          try {
            if (keycloakAdminToken != null && keycloakClientId != null) {
              await _deleteKeycloakClient(
                client: keycloakAdminClient,
                adminBaseUri: keycloakAdminBaseUri,
                adminToken: keycloakAdminToken,
                clientId: keycloakClientId,
              );
            }
          } finally {
            seedClient.close(force: true);
            keycloakAdminClient.close(force: true);
          }
        }
      }
    },
    skip: skipReason,
  );
}

Object _liveTestSkipReason(Map<String, String> environment) {
  const requirements = {
    'LOOM_POSTGRES_PASSWORD': 'the k3s PostgreSQL instance or port-forward',
    'LOOM_APP_ACCESS_BASE_URL': 'the live App Access service or port-forward',
    'LOOM_KEYCLOAK_TOKEN_URL': 'the live loom-realm token endpoint',
    'LOOM_KEYCLOAK_ADMIN_URL': 'the live Keycloak base URL',
    'LOOM_KEYCLOAK_ADMIN_USERNAME': 'the Keycloak bootstrap administrator',
    'LOOM_KEYCLOAK_ADMIN_PASSWORD': 'the Keycloak bootstrap administrator',
  };
  for (final requirement in requirements.entries) {
    final value = environment[requirement.key];
    if (value == null || value.isEmpty) {
      return 'Set ${requirement.key} to run against ${requirement.value}.';
    }
  }
  return false;
}

Future<String> _obtainKeycloakToken({
  required HttpClient client,
  required Uri tokenUri,
  required Map<String, String> form,
  required String purpose,
}) async {
  final request = await client.postUrl(tokenUri);
  request.headers.contentType = ContentType(
    'application',
    'x-www-form-urlencoded',
    charset: 'utf-8',
  );
  request.write(
    form.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}='
              '${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&'),
  );
  final response = await request.close();
  final body = await utf8.decoder.bind(response).join();
  expect(response.statusCode, HttpStatus.ok, reason: body);
  final decoded = jsonDecode(body);
  expect(
    decoded,
    isA<Map<String, dynamic>>().having(
      (value) => value['access_token'],
      'access_token for $purpose',
      isA<String>().having((value) => value.isNotEmpty, 'is not empty', isTrue),
    ),
  );
  return (decoded as Map<String, dynamic>)['access_token'] as String;
}

Future<String> _createKeycloakClient({
  required HttpClient client,
  required Uri adminBaseUri,
  required String adminToken,
  required String clientName,
}) async {
  final request = await client.postUrl(
    adminBaseUri.resolve('admin/realms/$_keycloakRealm/clients'),
  );
  request.headers.contentType = ContentType.json;
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
  request.write(
    jsonEncode({
      'clientId': clientName,
      'enabled': true,
      'protocol': 'openid-connect',
      'publicClient': false,
      'clientAuthenticatorType': 'client-secret',
      'serviceAccountsEnabled': true,
      'standardFlowEnabled': false,
      'directAccessGrantsEnabled': false,
    }),
  );
  final response = await request.close();
  final body = await utf8.decoder.bind(response).join();
  expect(response.statusCode, HttpStatus.created, reason: body);
  final location = response.headers.value(HttpHeaders.locationHeader);
  expect(location, isNotNull, reason: 'Keycloak omitted the client Location.');
  final pathSegments = Uri.parse(
    location!,
  ).pathSegments.where((segment) => segment.isNotEmpty).toList();
  expect(
    pathSegments,
    isNotEmpty,
    reason: 'Invalid client Location: $location',
  );
  return pathSegments.last;
}

/// Grants the throwaway client's service-account user the
/// `app-access-provisioner` realm role.
///
/// Three Keycloak admin-API steps, in this order, because each needs the
/// previous one's result:
///
///   1. `GET /admin/realms/{realm}/clients/{clientUuid}/service-account-user`
///      -- Keycloak provisions this user when `serviceAccountsEnabled` is set
///      on the client, and it is the identity a client-credentials token is
///      issued for. The client UUID from the client's `Location` header is used
///      here, not the human-readable `clientId`.
///   2. `GET /admin/realms/{realm}/roles/app-access-provisioner` -- the role
///      *definition*, not just its name.
///   3. `POST /admin/realms/{realm}/users/{userId}/role-mappings/realm` with a
///      JSON **array** containing that role object. Keycloak's realm
///      role-mappings endpoint takes a list, and it requires the full role
///      representation (id + name) rather than a bare string; posting
///      `["app-access-provisioner"]` is rejected.
///
/// `_deleteKeycloakClient` in the caller's `finally` removes the client and
/// with it this service-account user and every mapping it holds, so the grant
/// needs no separate cleanup.
Future<void> _grantProvisioningRealmRole({
  required HttpClient client,
  required Uri adminBaseUri,
  required String adminToken,
  required String clientUuid,
}) async {
  final serviceAccountUserRequest = await client.getUrl(
    adminBaseUri.resolve(
      'admin/realms/$_keycloakRealm/clients/'
      '${Uri.encodeComponent(clientUuid)}/service-account-user',
    ),
  );
  serviceAccountUserRequest.headers.set(
    HttpHeaders.authorizationHeader,
    'Bearer $adminToken',
  );
  final serviceAccountUserResponse = await serviceAccountUserRequest.close();
  final serviceAccountUserBody = await utf8.decoder
      .bind(serviceAccountUserResponse)
      .join();
  expect(
    serviceAccountUserResponse.statusCode,
    HttpStatus.ok,
    reason: serviceAccountUserBody,
  );
  final serviceAccountUser =
      jsonDecode(serviceAccountUserBody) as Map<String, dynamic>;
  final serviceAccountUserId = serviceAccountUser['id'];
  expect(
    serviceAccountUserId,
    isA<String>().having((value) => value.isNotEmpty, 'is not empty', isTrue),
    reason: 'Keycloak returned no service-account user id: '
        '$serviceAccountUserBody',
  );

  final roleRequest = await client.getUrl(
    adminBaseUri.resolve(
      'admin/realms/$_keycloakRealm/roles/'
      '${Uri.encodeComponent(_provisioningRealmRole)}',
    ),
  );
  roleRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
  final roleResponse = await roleRequest.close();
  final roleBody = await utf8.decoder.bind(roleResponse).join();
  expect(roleResponse.statusCode, HttpStatus.ok, reason: roleBody);
  final role = jsonDecode(roleBody);
  expect(
    role,
    isA<Map<String, dynamic>>().having(
      (value) => value['id'],
      'app-access-provisioner role id',
      isA<String>().having((value) => value.isNotEmpty, 'is not empty', isTrue),
    ),
    reason: 'The realm has no `$_provisioningRealmRole` role to grant. It is '
        'created out of band; this test cannot create it, only assign it.',
  );

  final mappingRequest = await client.postUrl(
    adminBaseUri.resolve(
      'admin/realms/$_keycloakRealm/users/'
      '${Uri.encodeComponent(serviceAccountUserId as String)}'
      '/role-mappings/realm',
    ),
  );
  mappingRequest.headers.contentType = ContentType.json;
  mappingRequest.headers.set(
    HttpHeaders.authorizationHeader,
    'Bearer $adminToken',
  );
  // A one-element JSON array of the full role representation.
  mappingRequest.write(jsonEncode([role]));
  final mappingResponse = await mappingRequest.close();
  final mappingBody = await utf8.decoder.bind(mappingResponse).join();
  expect(
    mappingResponse.statusCode,
    HttpStatus.noContent,
    reason: mappingBody,
  );
}

Future<String> _getKeycloakClientSecret({
  required HttpClient client,
  required Uri adminBaseUri,
  required String adminToken,
  required String clientId,
}) async {
  final request = await client.getUrl(
    adminBaseUri.resolve(
      'admin/realms/$_keycloakRealm/clients/'
      '${Uri.encodeComponent(clientId)}/client-secret',
    ),
  );
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
  final response = await request.close();
  final body = await utf8.decoder.bind(response).join();
  expect(response.statusCode, HttpStatus.ok, reason: body);
  final decoded = jsonDecode(body);
  expect(
    decoded,
    isA<Map<String, dynamic>>().having(
      (value) => value['value'],
      'client secret',
      isA<String>().having((value) => value.isNotEmpty, 'is not empty', isTrue),
    ),
  );
  return (decoded as Map<String, dynamic>)['value'] as String;
}

Future<void> _deleteKeycloakClient({
  required HttpClient client,
  required Uri adminBaseUri,
  required String adminToken,
  required String clientId,
}) async {
  final request = await client.deleteUrl(
    adminBaseUri.resolve(
      'admin/realms/$_keycloakRealm/clients/${Uri.encodeComponent(clientId)}',
    ),
  );
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $adminToken');
  final response = await request.close();
  final body = await utf8.decoder.bind(response).join();
  expect(response.statusCode, HttpStatus.noContent, reason: body);
}

Uri _normalizeBaseUri(Uri baseUri) {
  if (!baseUri.hasScheme || baseUri.host.isEmpty) {
    throw ArgumentError.value(baseUri, 'baseUri', 'must be an absolute URI');
  }
  final path = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
  return baseUri.replace(path: path, query: null, fragment: null);
}

/// The group id `installCommunityPackage` creates is derived, not supplied:
/// `loom_communities_<communityHandle>`. The rest of this test asserts against
/// the group id it chose, so the handle has to be read back out of it rather
/// than named independently and left to drift.
String _communityHandleFor(String groupId) {
  const prefix = 'loom_communities_';
  if (!groupId.startsWith(prefix) || groupId.length == prefix.length) {
    throw ArgumentError.value(
      groupId,
      'groupId',
      'must be the group id of a community package install ($prefix...)',
    );
  }
  return groupId.substring(prefix.length);
}

Future<void> _seedAppAccess({
  required HttpClient client,
  required Uri baseUri,
  required String bearerToken,
  required String groupId,
  required String roleId,
  required String fanId,
  required String unique,
}) async {
  final normalizedBase = baseUri.path.endsWith('/')
      ? baseUri
      : baseUri.replace(path: '${baseUri.path}/');

  // `installCommunityPackage` is the only sanctioned writer of grants. It
  // derives the package's permissions and reconciles each role to them, so it
  // creates the group AND the role AND grants `event_rsvp.create` in one call.
  //
  // The alternative this fixture used to take -- `POST /groups`, `POST /roles`,
  // then `PUT /roles/{roleId}/permissions` -- no longer exists: the App Access
  // P2 commit removed the public permission-assignment route, making
  // `role_permission` writable only through this installer path.
  final installation = await _sendJson(
    client,
    'POST',
    normalizedBase.resolve('v1/apps/$_appId/community-installations'),
    body: {
      'communityHandle': _communityHandleFor(groupId),
      'communityId': 'community_b3_$unique',
      'displayName': 'Workflow B.3 test $unique',
      'grammarVersion': currentCommunitySpecVersion,
      'roles': [
        {'roleId': roleId, 'label': 'Workflow B.3 event creator'},
      ],
      'workflows': [
        {
          // App Access has no business parsing render bindings, so the
          // derivation inputs travel in their resolved form: the caller states
          // the archetype and the create actions' byRoleIds.
          'workflowType': 'b3-event-$unique',
          'cardSurfaceFamily': _cardSurfaceFamily,
          'createRoleIds': [roleId],
          'transitions': [
            {
              'transitionId': 'cancel-event',
              'action': 'cancel',
              'tone': 'negative',
              'isTerminal': true,
              'allowedRoleIds': [roleId],
            },
          ],
        },
      ],
    },
    idempotencyKey: 'b3-installation-$unique',
    bearerToken: bearerToken,
  );
  expect(installation.statusCode, HttpStatus.ok, reason: installation.body);

  // The response is the evidence that the grant really happened, so assert it
  // rather than assuming the caller and the service agree. A `createRoleIds`
  // that derived nothing would otherwise leave this fixture passing while
  // authorizing nobody.
  final installationJson =
      jsonDecode(installation.body) as Map<String, dynamic>;
  expect(installationJson['groupId'], groupId);
  expect(
    installationJson['rolesRegistered'],
    contains(roleId),
    reason: installation.body,
  );
  expect(
    installationJson['permissionsGranted'],
    greaterThan(0),
    reason: installation.body,
  );
  expect(
    installationJson['rolesWithNoPermissions'],
    isEmpty,
    reason:
        'The role must hold $_permissionId, which the $_cardSurfaceFamily '
        'workflow derives from its create action. Empty means the derivation '
        'input no longer matches the permission this test asserts. '
        '${installation.body}',
  );
  expect(installationJson['findings'], isEmpty, reason: installation.body);

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
    bearerToken: bearerToken,
    // This call targets App Access, not workflow-service, so it needs App
    // Access's actor header (`X-Loom-Actor`) rather than the `fanId:`
    // parameter's `x-loom-fan-id`. Reusing `fanId:` here would set the wrong
    // header and 400 with the same `missing_actor` -- exactly what the install
    // call above hit before it was fixed.
    actorHeader: fanId,
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
      'audience': 'any',
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
  String? actorHeader,
  String? bearerToken,
}) async {
  final request = await client.openUrl(method, uri);
  request.headers.contentType = ContentType.json;
  request.headers.set('x-loom-correlation-id', _correlationId);
  request.headers.set('idempotency-key', idempotencyKey);
  if (bearerToken != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
  }
  if (fanId != null) {
    request.headers.set(
      HeaderWorkflowIdentityExtractor.defaultHeaderName,
      fanId,
    );
  }
  // App Access reads its actor from `X-Loom-Actor` (`CallerActor.ACTOR_HEADER`),
  // a different header from the workflow-service `x-loom-fan-id` set above.
  // This is deliberately a separate parameter: a Target that needs one never
  // needs the other, and conflating them 400s with `missing_actor`.
  if (actorHeader != null) {
    request.headers.set('X-Loom-Actor', actorHeader);
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
