import 'dart:async';
import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:loom_workflow_service/src/queue_offer_hold_windows.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final environment = Platform.environment;
  final postgresPassword = environment['LOOM_POSTGRES_PASSWORD'];
  if (postgresPassword == null || postgresPassword.isEmpty) {
    throw StateError('LOOM_POSTGRES_PASSWORD is required');
  }
  final postgresUsername = environment['LOOM_POSTGRES_USERNAME'] ?? 'loom';
  final runtimeCredentials = _runtimePostgresCredentials(
    environment,
    adminUsername: postgresUsername,
    adminPassword: postgresPassword,
  );
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
  final queueOfferHoldWindows = _queueOfferHoldWindows(
    environment['LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS'],
  );

  final health = WorkflowServiceHealth();
  final probeRouter = WorkflowServiceProbeRouter(health: health);
  final server = await shelf_io.serve(
    probeRouter.handler,
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

  _StartedWorkflowService? startedService;
  try {
    startedService = await _startUntilReady(
      environment: environment,
      postgresUsername: postgresUsername,
      postgresPassword: postgresPassword,
      runtimeCredentials: runtimeCredentials,
      communityGroupIds: communityGroupIds,
      keycloakTokenUrl: keycloakTokenUrl,
      appAccessClientId: appAccessClientId,
      appAccessClientSecret: appAccessClientSecret,
      jwtJwksUri: jwtJwksUri,
      jwtIssuer: jwtIssuer,
      queueOfferHoldWindows: queueOfferHoldWindows,
      health: health,
      shutdown: shutdown,
    );
    if (startedService != null) {
      probeRouter.activate(startedService.service.handler);
    }
    await shutdown.future;
  } finally {
    await sigintSubscription.cancel();
    await sigtermSubscription.cancel();
    await server.close(force: true);
    await startedService?.close();
  }
}

Future<_StartedWorkflowService?> _startUntilReady({
  required Map<String, String> environment,
  required String postgresUsername,
  required String postgresPassword,
  required _PostgresCredentials runtimeCredentials,
  required String communityGroupIds,
  required String keycloakTokenUrl,
  required String appAccessClientId,
  required String appAccessClientSecret,
  required String jwtJwksUri,
  required String jwtIssuer,
  required Map<String, Duration> queueOfferHoldWindows,
  required WorkflowServiceHealth health,
  required Completer<void> shutdown,
}) async {
  while (!shutdown.isCompleted) {
    WorkflowPostgresConnection? administrator;
    WorkflowPostgresConnection? postgres;
    JwtWorkflowIdentityExtractor? identityExtractor;
    HttpAppAccessDecisionClient? appAccessClient;
    try {
      administrator = await WorkflowPostgresConnection.open(
        host:
            environment['LOOM_POSTGRES_HOST'] ??
            'postgres.loom.svc.cluster.local',
        port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '5432'),
        databaseName: workflowPostgresDatabaseName(environment),
        username: postgresUsername,
        password: postgresPassword,
      );
      await administrator.migrateWorkflowSchema();

      // Every DDL statement, including all forced-RLS policy migrations, runs
      // before the restricted runtime pool is opened. The repositories below
      // receive only that runtime pool and never perform schema work.
      await PostgresDocumentRepository(administrator.connection).migrate();
      await PostgresExportBundleRepository(administrator.connection).migrate();
      await PostgresItemQueueRepository(administrator.connection).migrate();
      await administrator.close();
      administrator = null;

      postgres = await WorkflowPostgresConnection.open(
        host:
            environment['LOOM_POSTGRES_HOST'] ??
            'postgres.loom.svc.cluster.local',
        port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '5432'),
        databaseName: workflowPostgresDatabaseName(environment),
        username: runtimeCredentials.username,
        password: runtimeCredentials.password,
        migrationsManagedExternally: true,
      );
      health.markPostgresConnected(readinessCheck: postgres.verifyReadiness);

      // Queue entries are core workflow-service state, not object storage.
      // Their schema is already migrated through the administrator connection.
      final itemQueueRepository = PostgresItemQueueRepository(
        postgres.connection,
      );
      final documentStorage = await _openOptionalDocumentStorage(
        environment: environment,
        postgres: postgres,
      );

      identityExtractor = JwtWorkflowIdentityExtractor(
        jwksUri: Uri.parse(jwtJwksUri),
        expectedIssuer: jwtIssuer,
      );
      appAccessClient = HttpAppAccessDecisionClient(
        baseUri: Uri.parse(
          environment['LOOM_APP_ACCESS_BASE_URL'] ??
              'http://app-access.loom.svc.cluster.local:8080',
        ),
        tokenUri: Uri.parse(keycloakTokenUrl),
        clientId: appAccessClientId,
        clientSecret: appAccessClientSecret,
      );
      final service = WorkflowService(
        database: postgres.database,
        communityTransactionRunner: postgres.runWithCommunity,
        identityExtractor: identityExtractor,
        appAccessClient: appAccessClient,
        communityGroupIdResolver: MapCommunityGroupIdResolver.fromJson(
          communityGroupIds,
        ),
        documentRepository: documentStorage.documentRepository,
        documentObjectStore: documentStorage.documentObjectStore,
        exportBundleRepository: documentStorage.exportBundleRepository,
        itemQueueRepository: itemQueueRepository,
        queueOfferHoldWindows: queueOfferHoldWindows,
      );
      health.markMigrationsComplete();
      return _StartedWorkflowService(
        postgres: postgres,
        identityExtractor: identityExtractor,
        appAccessClient: appAccessClient,
        service: service,
      );
    } catch (error, stackTrace) {
      health.markPostgresUnavailable();
      identityExtractor?.close(force: true);
      appAccessClient?.close(force: true);
      await administrator?.close();
      await postgres?.close();
      stderr.writeln(
        'Workflow service startup failed; retrying Postgres in 5 seconds: '
        '$error',
      );
      stderr.writeln(stackTrace);
      await Future.any<void>([
        shutdown.future,
        Future<void>.delayed(const Duration(seconds: 5)),
      ]);
    }
  }
  return null;
}

Future<_OptionalDocumentStorage> _openOptionalDocumentStorage({
  required Map<String, String> environment,
  required WorkflowPostgresConnection postgres,
}) async {
  final minioEndpoint = environment['LOOM_MINIO_ENDPOINT'];
  final minioAccessKey = environment['LOOM_MINIO_ACCESS_KEY'];
  final minioSecretKey = environment['LOOM_MINIO_SECRET_KEY'];
  final configurationValues = [minioEndpoint, minioAccessKey, minioSecretKey];
  final anyConfigured = configurationValues.any(
    (value) => value != null && value.isNotEmpty,
  );
  final allConfigured = configurationValues.every(
    (value) => value != null && value.isNotEmpty,
  );
  if (!anyConfigured) {
    stdout.writeln('LOOM_MINIO_* not set: document endpoints will answer 503.');
    return const _OptionalDocumentStorage();
  }
  if (!allConfigured) {
    throw StateError(
      'LOOM_MINIO_ENDPOINT, LOOM_MINIO_ACCESS_KEY, and '
      'LOOM_MINIO_SECRET_KEY must be set together.',
    );
  }

  final endpoint = minioEndpoint!;
  try {
    final store = MinioDocumentObjectStore.fromConfiguration(
      // A host, never a URL: the client takes the scheme separately, so
      // "http://minio" here becomes a literal hostname and a DNS failure.
      endpoint: endpoint,
      port: int.parse(environment['LOOM_MINIO_PORT'] ?? '9000'),
      accessKey: minioAccessKey!,
      secretKey: minioSecretKey!,
      bucket: environment['LOOM_MINIO_BUCKET'] ?? 'loom-documents',
      useSsl: environment['LOOM_MINIO_USE_SSL'] == 'true',
    );
    await store.ensureBucket();
    final repository = PostgresDocumentRepository(postgres.connection);
    final exportRepository = PostgresExportBundleRepository(
      postgres.connection,
    );
    stdout.writeln('Document storage ready on $endpoint.');
    return _OptionalDocumentStorage(
      documentRepository: repository,
      documentObjectStore: store,
      exportBundleRepository: exportRepository,
    );
  } catch (error, stackTrace) {
    // Documents and exports already have explicit 503 responses when storage
    // is absent. Do not make otherwise usable workflow traffic unavailable for
    // this optional dependency, but make the degradation explicit in logs.
    stderr.writeln(
      'Document storage initialization failed; document and export endpoints '
      'will answer 503: $error',
    );
    stderr.writeln(stackTrace);
    return const _OptionalDocumentStorage();
  }
}

class _OptionalDocumentStorage {
  const _OptionalDocumentStorage({
    this.documentRepository,
    this.documentObjectStore,
    this.exportBundleRepository,
  });

  final DocumentRepository? documentRepository;
  final DocumentObjectStore? documentObjectStore;
  final ExportBundleRepository? exportBundleRepository;
}

class _StartedWorkflowService {
  const _StartedWorkflowService({
    required this.postgres,
    required this.identityExtractor,
    required this.appAccessClient,
    required this.service,
  });

  final WorkflowPostgresConnection postgres;
  final JwtWorkflowIdentityExtractor identityExtractor;
  final HttpAppAccessDecisionClient appAccessClient;
  final WorkflowService service;

  Future<void> close() async {
    identityExtractor.close(force: true);
    appAccessClient.close(force: true);
    await postgres.close();
  }
}

Map<String, Duration> _queueOfferHoldWindows(String? encoded) {
  return parseQueueOfferHoldWindows(encoded);
}

class _PostgresCredentials {
  const _PostgresCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

_PostgresCredentials _runtimePostgresCredentials(
  Map<String, String> environment, {
  required String adminUsername,
  required String adminPassword,
}) {
  final appUsername = environment['LOOM_POSTGRES_APP_USERNAME'];
  final appPassword = environment['LOOM_POSTGRES_APP_PASSWORD'];
  if (appUsername != null &&
      appUsername.isNotEmpty &&
      appPassword != null &&
      appPassword.isNotEmpty) {
    return _PostgresCredentials(username: appUsername, password: appPassword);
  }
  if ((appUsername != null && appUsername.isNotEmpty) ||
      (appPassword != null && appPassword.isNotEmpty)) {
    throw StateError(
      'LOOM_POSTGRES_APP_USERNAME and LOOM_POSTGRES_APP_PASSWORD must be '
      'set together.',
    );
  }

  stderr.writeln(
    'WARNING: LOOM_POSTGRES_APP_USERNAME and LOOM_POSTGRES_APP_PASSWORD are '
    'unset; the workflow runtime pool is falling back to the administrator '
    'role, so PostgreSQL RLS is inert.',
  );
  return _PostgresCredentials(username: adminUsername, password: adminPassword);
}
