// A small local REST wrapper around CommunityPackageValidator, so an external
// caller (e.g. a ChatGPT Action) that can only speak HTTP -- not `dart run`
// -- can validate a Loom community package without local tooling access.
//
// Routes:
//   GET  /health    -> {"status": "ok"}
//   POST /validate  -> body: the full community package (JSON or JSONC text,
//                      same shape `--package` accepts on the CLI). Returns
//                      the same ValidationReport.toJson() shape the CLI
//                      prints: {status, errorCount, warningCount, findings}.
//
// No new dependencies: pure dart:io, reuses the exact validator + JSONC
// stripping the CLI (community_package_validator.dart) already uses, so
// server results are identical to a local CLI run on the same input.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'community_package_validator.dart';
import 'jsonc.dart';

/// Starts the validator HTTP server and returns the bound [HttpServer].
/// Pass `port: 0` to bind an OS-assigned ephemeral port (used by tests).
Future<HttpServer> startValidatorServer({
  InternetAddress? address,
  int port = 8787,
}) async {
  final server = await HttpServer.bind(
    address ?? InternetAddress.anyIPv4,
    port,
  );
  unawaited(_serve(server));
  return server;
}

Future<void> _serve(HttpServer server) async {
  await for (final request in server) {
    unawaited(handleValidatorRequest(request));
  }
}

/// Handles a single request. Exposed separately from [startValidatorServer]
/// so it can also be exercised directly against a fake/real [HttpRequest] in
/// tests without needing a real socket.
Future<void> handleValidatorRequest(HttpRequest request) async {
  final response = request.response;
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
  response.headers.contentType = ContentType.json;

  try {
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/health') {
      response.statusCode = HttpStatus.ok;
      response.write(jsonEncode({'status': 'ok'}));
      await response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/validate') {
      final body = await utf8.decoder.bind(request).join();
      Map<String, dynamic> package;
      try {
        if (body.trim().isEmpty) {
          throw const FormatException('Request body is empty.');
        }
        final decoded = jsonDecode(stripJsonComments(body));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Top-level JSON must be an object.');
        }
        package = decoded;
      } catch (error) {
        response.statusCode = HttpStatus.badRequest;
        response.write(
          jsonEncode({
            'error': 'invalid_json',
            'message': 'Request body is not valid JSON/JSONC: $error',
          }),
        );
        await response.close();
        return;
      }

      final report = CommunityPackageValidator().validate(package);
      response.statusCode = HttpStatus.ok;
      response.write(jsonEncode(report.toJson()));
      await response.close();
      return;
    }

    response.statusCode = HttpStatus.notFound;
    response.write(
      jsonEncode({
        'error': 'not_found',
        'message':
            'Unknown route ${request.method} ${request.uri.path}. '
            'Use GET /health or POST /validate.',
      }),
    );
    await response.close();
  } catch (error, stackTrace) {
    stderr.writeln('Unhandled error: $error\n$stackTrace');
    try {
      response.statusCode = HttpStatus.internalServerError;
      response.write(
        jsonEncode({'error': 'internal_error', 'message': '$error'}),
      );
      await response.close();
    } catch (_) {
      // Response already closed/broken; nothing more to do.
    }
  }
}
