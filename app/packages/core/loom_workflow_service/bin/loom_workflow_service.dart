import 'dart:async';
import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final environment = Platform.environment;
  final postgresPassword = environment['LOOM_POSTGRES_PASSWORD'];
  if (postgresPassword == null || postgresPassword.isEmpty) {
    throw StateError('LOOM_POSTGRES_PASSWORD is required');
  }
  final communityGroupIds = environment['LOOM_COMMUNITY_GROUP_IDS'];
  if (communityGroupIds == null || communityGroupIds.isEmpty) {
    throw StateError('LOOM_COMMUNITY_GROUP_IDS is required');
  }
  final keycloakTokenUrl = environment['LOOM_KEYCLOAK_TOKEN_URL'];
  if (keycloakTokenUrl == null || keycloakTokenUrl.isEmpty) {
    throw StateError('LOOM_KEYCLOAK_TOKEN_URL is required');
  }
  final appAccessClientId = environment['LOOM_APP_ACCESS_CLIENT_ID'];
  if (appAccessClientId == null || appAccessClientId.isEmpty) {
    throw StateError('LOOM_APP_ACCESS_CLIENT_ID is required');
  }
  final appAccessClientSecret = environment['LOOM_APP_ACCESS_CLIENT_SECRET'];
  if (appAccessClientSecret == null || appAccessClientSecret.isEmpty) {
    throw StateError('LOOM_APP_ACCESS_CLIENT_SECRET is required');
  }
  final jwtJwksUri = environment['JWT_JWKS_URI'];
  if (jwtJwksUri == null || jwtJwksUri.isEmpty) {
    throw StateError('JWT_JWKS_URI is required');
  }
  final jwtIssuer = environment['JWT_ISSUER'];
  if (jwtIssuer == null || jwtIssuer.isEmpty) {
    throw StateError('JWT_ISSUER is required');
  }

  final postgres = await WorkflowPostgresConnection.open(
    host:
        environment['LOOM_POSTGRES_HOST'] ?? 'postgres.loom.svc.cluster.local',
    port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '5432'),
    databaseName: environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access',
    username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
    password: postgresPassword,
  );
  final appAccessClient = HttpAppAccessDecisionClient(
    baseUri: Uri.parse(
      environment['LOOM_APP_ACCESS_BASE_URL'] ??
          'http://app-access.loom.svc.cluster.local:8080',
    ),
    tokenUri: Uri.parse(keycloakTokenUrl),
    clientId: appAccessClientId,
    clientSecret: appAccessClientSecret,
  );
  final identityExtractor = JwtWorkflowIdentityExtractor(
    jwksUri: Uri.parse(jwtJwksUri),
    expectedIssuer: jwtIssuer,
  );
  final service = WorkflowService(
    database: postgres.database,
    identityExtractor: identityExtractor,
    appAccessClient: appAccessClient,
    communityGroupIdResolver: MapCommunityGroupIdResolver.fromJson(
      communityGroupIds,
    ),
  );
  final server = await shelf_io.serve(
    service.handler,
    environment['LOOM_WORKFLOW_ADDRESS'] ?? '0.0.0.0',
    int.parse(environment['LOOM_WORKFLOW_PORT'] ?? '8080'),
  );

  final shutdown = Completer<void>();
  late final StreamSubscription<ProcessSignal> sigintSubscription;
  late final StreamSubscription<ProcessSignal> sigtermSubscription;
  Future<void> stop(ProcessSignal _) async {
    if (shutdown.isCompleted) return;
    shutdown.complete();
  }

  sigintSubscription = ProcessSignal.sigint.watch().listen(stop);
  sigtermSubscription = ProcessSignal.sigterm.watch().listen(stop);
  await shutdown.future;
  await sigintSubscription.cancel();
  await sigtermSubscription.cancel();
  await server.close(force: true);
  identityExtractor.close(force: true);
  appAccessClient.close(force: true);
  await postgres.close();
}
