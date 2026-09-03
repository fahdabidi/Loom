import 'dart:io';

import 'package:loom_workflow_service/src/definition_publisher.dart';
import 'package:loom_workflow_service/src/postgres_connection.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: dart run bin/publish_workflow_definitions.dart [--write]',
    );
    stdout.writeln(
      'Reads shipped Community JSONC assets. Dry-run is the default.',
    );
    return;
  }
  if (arguments.any((argument) => argument != '--write')) {
    throw ArgumentError(
      'Unknown argument. Usage: '
      'dart run bin/publish_workflow_definitions.dart [--write]',
    );
  }
  final write = arguments.contains('--write');

  final assetsDirectory = locateShippedCommunityPackagesDirectory(
    Directory.current,
  );
  final readResult = await readCommunityWorkflowPackages(assetsDirectory);
  for (final error in readResult.errors) {
    stdout.writeln('PACKAGE ERROR ${error.fileName}: ${error.reason}');
  }
  if (readResult.hasErrors) {
    throw StateError(
      'Refusing to publish while one or more shipped community packages are invalid.',
    );
  }

  final environment = Platform.environment;
  final password = environment['LOOM_POSTGRES_PASSWORD'];
  if (password == null || password.isEmpty) {
    throw StateError('LOOM_POSTGRES_PASSWORD is required.');
  }
  final postgres = await WorkflowPostgresConnection.open(
    host:
        environment['LOOM_POSTGRES_HOST'] ?? 'postgres.loom.svc.cluster.local',
    port: int.parse(environment['LOOM_POSTGRES_PORT'] ?? '5432'),
    databaseName: workflowPostgresDatabaseName(environment),
    username: environment['LOOM_POSTGRES_USERNAME'] ?? 'loom',
    password: password,
  );
  try {
    // This command is intentionally a cross-community publisher, but it
    // writes only the global workflow_definitions table. Running the service
    // schema migration first ensures the tenant tables it creates incidentally
    // receive their forced RLS policies before any service starts.
    await postgres.migrateWorkflowSchema();
    await WorkflowDefinitionPublisher(
      database: postgres.database,
      report: stdout.writeln,
    ).publish(readResult.packages, write: write);
  } finally {
    await postgres.close();
  }
}
