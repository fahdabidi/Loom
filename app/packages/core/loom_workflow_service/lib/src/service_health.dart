import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Tracks the dependencies needed before workflow requests can be served.
///
/// The HTTP listener starts before PostgreSQL does so Kubernetes can distinguish
/// a live Dart process from a ready workflow service during startup.
class WorkflowServiceHealth {
  static const _jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };

  bool _postgresConnected = false;
  bool _migrationsComplete = false;

  bool get isReady => _postgresConnected && _migrationsComplete;

  void markPostgresConnected() {
    _postgresConnected = true;
  }

  void markMigrationsComplete() {
    if (!_postgresConnected) {
      throw StateError(
        'Postgres must be connected before migrations complete.',
      );
    }
    _migrationsComplete = true;
  }

  void markPostgresUnavailable() {
    _postgresConnected = false;
    _migrationsComplete = false;
  }

  Response livenessResponse() =>
      Response.ok(jsonEncode({'status': 'live'}), headers: _jsonHeaders);

  Response readinessResponse() {
    if (isReady) {
      return Response.ok(
        jsonEncode({'status': 'ready'}),
        headers: _jsonHeaders,
      );
    }

    final migrationsArePending = _postgresConnected;
    return Response(
      503,
      body: jsonEncode({
        'status': 'not_ready',
        'dependency': migrationsArePending ? 'postgres_migrations' : 'postgres',
        'message': migrationsArePending
            ? 'Postgres migrations have not completed.'
            : 'Postgres is not connected.',
      }),
      headers: _jsonHeaders,
    );
  }

  Response startingResponse() => Response(
    503,
    body: jsonEncode({
      'code': 'workflow_service_starting',
      'message': 'Workflow service is waiting for Postgres.',
    }),
    headers: _jsonHeaders,
  );
}

/// Routes unauthenticated probe requests while the application is starting.
///
/// Probe paths deliberately bypass the workflow HTTP handler: they have no
/// member identity or correlation-id contract. All other requests are held at
/// 503 until [activate] installs the fully initialized application handler.
class WorkflowServiceProbeRouter {
  WorkflowServiceProbeRouter({required this.health});

  final WorkflowServiceHealth health;
  Handler? _applicationHandler;

  Handler get handler => _handle;

  void activate(Handler applicationHandler) {
    if (_applicationHandler != null) {
      throw StateError('Workflow service probe router is already active.');
    }
    if (!health.isReady) {
      throw StateError('Cannot activate workflow service before it is ready.');
    }
    _applicationHandler = applicationHandler;
  }

  Future<Response> _handle(Request request) async {
    if (request.method == 'GET' && request.url.path == 'healthz') {
      return health.livenessResponse();
    }
    if (request.method == 'GET' && request.url.path == 'readyz') {
      return health.readinessResponse();
    }

    final applicationHandler = _applicationHandler;
    if (applicationHandler == null) return health.startingResponse();
    return applicationHandler(request);
  }
}
