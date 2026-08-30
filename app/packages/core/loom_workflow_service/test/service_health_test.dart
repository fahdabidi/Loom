import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test(
    'healthz is unauthenticated and stays live while Postgres is unavailable',
    () async {
      final health = WorkflowServiceHealth();
      final router = WorkflowServiceProbeRouter(health: health);

      final response = await router.handler(
        Request('GET', Uri.parse('http://localhost/healthz')),
      );

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), {'status': 'live'});

      health.markPostgresConnected();
      health.markMigrationsComplete();
      health.markPostgresUnavailable();
      final unavailableResponse = await router.handler(
        Request('GET', Uri.parse('http://localhost/healthz')),
      );
      expect(unavailableResponse.statusCode, 200);
      expect(jsonDecode(await unavailableResponse.readAsString()), {
        'status': 'live',
      });
    },
  );

  test('readyz reports Postgres when the database is unavailable', () async {
    final router = WorkflowServiceProbeRouter(health: WorkflowServiceHealth());

    final response = await router.handler(
      Request('GET', Uri.parse('http://localhost/readyz')),
    );

    expect(response.statusCode, 503);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['status'], 'not_ready');
    expect(body['dependency'], 'postgres');
    expect(body['message'], contains('Postgres'));
  });

  test(
    'readyz is unauthenticated once Postgres and migrations are ready',
    () async {
      final health = WorkflowServiceHealth();
      final router = WorkflowServiceProbeRouter(health: health);
      health.markPostgresConnected();
      health.markMigrationsComplete();
      router.activate((_) => Response.ok('application route'));

      final response = await router.handler(
        Request('GET', Uri.parse('http://localhost/readyz')),
      );

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), {'status': 'ready'});
    },
  );

  test(
    'readyz follows database reachability and healthz never probes it',
    () async {
      var databaseReachable = true;
      var probeCalls = 0;
      final health = WorkflowServiceHealth();
      final router = WorkflowServiceProbeRouter(health: health);
      health.markPostgresConnected(
        readinessCheck: () async {
          probeCalls++;
          if (!databaseReachable) {
            throw StateError('Postgres is unavailable for this probe.');
          }
        },
      );
      health.markMigrationsComplete();
      router.activate((_) => Response.ok('application route'));

      final live = await router.handler(
        Request('GET', Uri.parse('http://localhost/healthz')),
      );
      expect(live.statusCode, 200);
      expect(probeCalls, 0);

      final initiallyReady = await router.handler(
        Request('GET', Uri.parse('http://localhost/readyz')),
      );
      expect(initiallyReady.statusCode, 200);
      expect(probeCalls, 1);

      databaseReachable = false;
      final unavailable = await router.handler(
        Request('GET', Uri.parse('http://localhost/readyz')),
      );
      expect(unavailable.statusCode, 503);
      expect(
        jsonDecode(await unavailable.readAsString()),
        containsPair('dependency', 'postgres'),
      );

      databaseReachable = true;
      final recovered = await router.handler(
        Request('GET', Uri.parse('http://localhost/readyz')),
      );
      expect(recovered.statusCode, 200);
      expect(probeCalls, 3);
    },
  );

  test(
    'both executable entrypoints use the workflow-service database default',
    () async {
      expect(
        workflowPostgresDatabaseName(const {}),
        workflowPostgresDefaultDatabaseName,
      );
      expect(workflowPostgresDefaultDatabaseName, 'loom_workflow_service');

      for (final entrypoint in [
        'bin/loom_workflow_service.dart',
        'bin/publish_workflow_definitions.dart',
      ]) {
        final source = await File(entrypoint).readAsString();
        expect(source, contains('workflowPostgresDatabaseName(environment)'));
        expect(source, isNot(contains("'loom_app_access'")));
      }
    },
  );
}
