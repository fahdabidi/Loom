import 'dart:async';
import 'dart:convert';
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
  final queueOfferHoldWindows = _queueOfferHoldWindows(
    environment['LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS'],
  );

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
  // Queue entries are core workflow-service state, not object storage. Migrate
  // them independently so an installation without document storage can still
  // run the equipment-loan queue API.
  final itemQueueRepository = PostgresItemQueueRepository(postgres.connection);
  await itemQueueRepository.migrate();
  // Document storage is optional. A deployment without MinIO configured still
  // serves every workflow endpoint; only the document endpoints answer 503.
  // Requiring it would make a service that has run for months refuse to start
  // over a feature most of its traffic never touches.
  DocumentRepository? documentRepository;
  DocumentObjectStore? documentObjectStore;
  ExportBundleRepository? exportBundleRepository;
  final minioEndpoint = environment['LOOM_MINIO_ENDPOINT'];
  final minioAccessKey = environment['LOOM_MINIO_ACCESS_KEY'];
  final minioSecretKey = environment['LOOM_MINIO_SECRET_KEY'];
  if (minioEndpoint != null &&
      minioEndpoint.isNotEmpty &&
      minioAccessKey != null &&
      minioAccessKey.isNotEmpty &&
      minioSecretKey != null &&
      minioSecretKey.isNotEmpty) {
    final store = MinioDocumentObjectStore.fromConfiguration(
      // A host, never a URL: the client takes the scheme separately, so
      // "http://minio" here becomes a literal hostname and a DNS failure.
      endpoint: minioEndpoint,
      port: int.parse(environment['LOOM_MINIO_PORT'] ?? '9000'),
      accessKey: minioAccessKey,
      secretKey: minioSecretKey,
      bucket: environment['LOOM_MINIO_BUCKET'] ?? 'loom-documents',
      useSsl: environment['LOOM_MINIO_USE_SSL'] == 'true',
    );
    // Both at startup, so a bad endpoint or a missing table fails the boot
    // rather than the first member who tries to upload something.
    await store.ensureBucket();
    final repository = PostgresDocumentRepository(postgres.connection);
    await repository.migrate();
    final exportRepository = PostgresExportBundleRepository(
      postgres.connection,
    );
    await exportRepository.migrate();
    documentObjectStore = store;
    documentRepository = repository;
    exportBundleRepository = exportRepository;
    stdout.writeln('Document storage ready on $minioEndpoint.');
  } else {
    stdout.writeln('LOOM_MINIO_* not set: document endpoints will answer 503.');
  }

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
    documentRepository: documentRepository,
    documentObjectStore: documentObjectStore,
    exportBundleRepository: exportBundleRepository,
    itemQueueRepository: itemQueueRepository,
    queueOfferHoldWindows: queueOfferHoldWindows,
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

Map<String, Duration> _queueOfferHoldWindows(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) {
    throw StateError('LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS is required');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(encoded);
  } on FormatException {
    throw StateError(
      'LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS must be a JSON object.',
    );
  }
  if (decoded is! Map<String, dynamic> || decoded.isEmpty) {
    throw StateError(
      'LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS must be a non-empty JSON object.',
    );
  }

  final result = <String, Duration>{};
  for (final entry in decoded.entries) {
    final seconds = entry.value;
    if (entry.key.trim().isEmpty || seconds is! int || seconds <= 0) {
      throw StateError(
        'Each queue offer hold window must have a community id and positive '
        'integer seconds.',
      );
    }
    result[entry.key] = Duration(seconds: seconds);
  }
  return result;
}
