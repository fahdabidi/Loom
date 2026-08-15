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

  final postgres = await WorkflowPostgresConnection.open(
    host:
        environment['LOOM_POSTGRES_HOST'] ?? 'postgres.loom.svc.cluster.local',
    port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '5432'),
    databaseName: environment['LOOM_POSTGRES_DATABASE'] ?? 'loom_app_access',
    username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
    password: postgresPassword,
  );
  final service = WorkflowService(
    database: postgres.database,
    identityExtractor: const HeaderWorkflowIdentityExtractor(),
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
  await postgres.close();
}
