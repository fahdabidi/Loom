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
//   POST /package      -> body: same shape as /validate. Validates first (a
//                         package with errorCount > 0 is refused, 422, with
//                         the validation report instead of a zip); on a
//                         clean package, returns a downloadable zip
//                         (application/zip) containing the two files the
//                         real Demo App's "Add Community" flow expects: a
//                         generated `<handle>.loom-extension.zip` manifest
//                         and a `<handle>.loom-init.zip` initialization
//                         package (the input, re-serialized). For direct
//                         HTTP/CLI use.
//   POST /package.json -> same validation, same two files, but returned as
//                         plain JSON (extensionManifest/initializationPackage
//                         inline as JSON objects, not zipped) instead of a
//                         binary response, PLUS a "downloadUrl" pointing at
//                         GET /download/<id> where the real zip (identical
//                         bytes to what /package would return) is held
//                         in-memory and can be fetched directly. Exists
//                         because a ChatGPT Action calling /package's binary
//                         response failed with a "client transport exception"
//                         on every attempt, while plain-JSON Action responses
//                         (/validate) have been reliable -- this is the
//                         endpoint the Action schema points at. The
//                         downloadUrl lets a human click straight to a real
//                         zip (the user's browser does a plain GET, never
//                         passing back through the Action's transport) rather
//                         than copy-pasting two JSON blocks into files by hand.
//   GET  /download/:id -> serves a zip previously built by /package.json,
//                         application/zip with Content-Disposition. IDs are
//                         random and held in an in-memory, size-bounded
//                         cache (oldest evicted past _maxStoredDownloads) --
//                         they do not survive a server restart and are not a
//                         durable storage mechanism.
//
// All three POST routes accept the same two request-body shapes: the raw
// package object directly, or {"packageJson": "<the package, JSON-encoded
// as a string>"}.
//
// No new dependencies beyond `package:archive` (for /package's zip output):
// pure dart:io otherwise, reusing the exact validator + JSONC stripping the
// CLI (community_package_validator.dart) already uses, so /validate results
// are identical to a local CLI run on the same input.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'community_package_validator.dart';
import 'jsonc.dart';
import 'package_builder.dart';
import 'workflow_validator.dart';

const _defaultValidatorLogPath = '/tmp/loom_validator_rounds.jsonl';

/// In-memory store for zips built by `/package.json`, fetched back via
/// `GET /download/:id`. Bounded and non-durable by design -- this is a local
/// dev tool, not a real storage layer; entries are evicted oldest-first past
/// [_maxStoredDownloads] and none of it survives a server restart.
final _downloadStore = <String, _StoredDownload>{};
const _maxStoredDownloads = 50;

class _StoredDownload {
  _StoredDownload(this.bytes, this.filename);
  final List<int> bytes;
  final String filename;
}

String _storeDownload(List<int> bytes, String filename) {
  final id = _randomId();
  _downloadStore[id] = _StoredDownload(bytes, filename);
  while (_downloadStore.length > _maxStoredDownloads) {
    _downloadStore.remove(_downloadStore.keys.first);
  }
  return id;
}

String _randomId() {
  final random = Random.secure();
  return List<int>.generate(
    16,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// Starts the validator HTTP server and returns the bound [HttpServer].
/// Pass `port: 0` to bind an OS-assigned ephemeral port (used by tests).
/// [validatorLogPath] overrides `LOOM_VALIDATOR_LOG` when supplied.
Future<HttpServer> startValidatorServer({
  InternetAddress? address,
  int port = 8787,
  String? validatorLogPath,
}) async {
  final server = await HttpServer.bind(
    address ?? InternetAddress.anyIPv4,
    port,
  );
  unawaited(
    _serve(
      server,
      validatorLogPath: validatorLogPath ?? _validatorLogPathFromEnvironment(),
    ),
  );
  return server;
}

String _validatorLogPathFromEnvironment() {
  final configured = Platform.environment['LOOM_VALIDATOR_LOG'];
  return configured == null || configured.isEmpty
      ? _defaultValidatorLogPath
      : configured;
}

Future<void> _serve(
  HttpServer server, {
  required String validatorLogPath,
}) async {
  await for (final request in server) {
    unawaited(
      handleValidatorRequest(request, validatorLogPath: validatorLogPath),
    );
  }
}

/// Handles a single request. Exposed separately from [startValidatorServer]
/// so it can also be exercised directly against a fake/real [HttpRequest] in
/// tests without needing a real socket.
Future<void> handleValidatorRequest(
  HttpRequest request, {
  String? validatorLogPath,
}) async {
  // Logged unconditionally, before any parsing/validation, so a live `tail`
  // on this process's stdout is ground truth for "did a request actually
  // arrive, and at what path" -- independent of anything a caller (e.g. an
  // LLM operating a ChatGPT Action) might self-report about what it thinks
  // it called.
  stdout.writeln(
    '${DateTime.now().toIso8601String()} '
    '${request.method} ${request.uri.path} '
    'host=${request.headers.host ?? "?"} '
    'ua=${request.headers.value('user-agent') ?? "?"} '
    'from=${request.connectionInfo?.remoteAddress.address ?? "?"}',
  );

  final response = request.response;
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

  try {
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/health') {
      response.headers.contentType = ContentType.json;
      response.statusCode = HttpStatus.ok;
      response.write(jsonEncode({'status': 'ok'}));
      await response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/validate') {
      response.headers.contentType = ContentType.json;
      Map<String, dynamic>? submittedPackage;
      ValidationReport? validationReport;
      var roundLogged = false;
      try {
        final body = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> package;
        try {
          package = _decodePackageFromBody(body);
          submittedPackage = package;
        } catch (error) {
          await _appendValidationRound(
            request: request,
            logPath: validatorLogPath ?? _validatorLogPathFromEnvironment(),
          );
          roundLogged = true;
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
        validationReport = report;
        await _appendValidationRound(
          request: request,
          logPath: validatorLogPath ?? _validatorLogPathFromEnvironment(),
          package: package,
          report: report,
        );
        roundLogged = true;
        response.statusCode = HttpStatus.ok;
        response.write(jsonEncode(report.toJson()));
        await response.close();
        return;
      } finally {
        if (!roundLogged) {
          await _appendValidationRound(
            request: request,
            logPath: validatorLogPath ?? _validatorLogPathFromEnvironment(),
            package: submittedPackage,
            report: validationReport,
          );
        }
      }
    }

    if (request.method == 'POST' && request.uri.path == '/package') {
      final body = await utf8.decoder.bind(request).join();
      final Map<String, dynamic> package;
      try {
        package = _decodePackageFromBody(body);
      } catch (error) {
        response.headers.contentType = ContentType.json;
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
      if (report.errors.isNotEmpty) {
        response.headers.contentType = ContentType.json;
        response.statusCode = HttpStatus.unprocessableEntity;
        response.write(
          jsonEncode({
            'error': 'package_has_errors',
            'message':
                'Refusing to package a community with unresolved validator '
                'errors. Fix every error and call /validate again until '
                'errorCount is 0, then call /package.',
            'validation': report.toJson(),
          }),
        );
        await response.close();
        return;
      }

      final BuiltExtensionPackage built;
      try {
        built = buildExtensionPackageZip(package);
      } on PackageBuilderError catch (error) {
        response.headers.contentType = ContentType.json;
        response.statusCode = HttpStatus.unprocessableEntity;
        response.write(
          jsonEncode({'error': 'package_build_failed', 'message': '$error'}),
        );
        await response.close();
        return;
      }

      response.headers.contentType = ContentType.parse(
        'application/zip',
      );
      response.headers.set(
        'Content-Disposition',
        'attachment; filename="${built.downloadFilename}"',
      );
      response.headers.set('X-Loom-Extension-Id', built.extensionId);
      response.headers.set(
        'X-Loom-Extension-Manifest-Filename',
        built.extensionManifestFilename,
      );
      response.headers.set(
        'X-Loom-Init-Package-Filename',
        built.initializationPackageFilename,
      );
      response.statusCode = HttpStatus.ok;
      response.add(built.zipBytes);
      await response.close();
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/package.json') {
      response.headers.contentType = ContentType.json;
      final body = await utf8.decoder.bind(request).join();
      final Map<String, dynamic> package;
      try {
        package = _decodePackageFromBody(body);
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
      if (report.errors.isNotEmpty) {
        response.statusCode = HttpStatus.unprocessableEntity;
        response.write(
          jsonEncode({
            'error': 'package_has_errors',
            'message':
                'Refusing to package a community with unresolved validator '
                'errors. Fix every error and call /validate again until '
                'errorCount is 0, then call /package.json.',
            'validation': report.toJson(),
          }),
        );
        await response.close();
        return;
      }

      final BuiltExtensionPackage built;
      try {
        built = buildExtensionPackageZip(package);
      } on PackageBuilderError catch (error) {
        response.statusCode = HttpStatus.unprocessableEntity;
        response.write(
          jsonEncode({'error': 'package_build_failed', 'message': '$error'}),
        );
        await response.close();
        return;
      }

      final downloadId = _storeDownload(
        built.zipBytes,
        built.downloadFilename,
      );
      // String-built rather than a Uri(host: ...) constructor: the Host
      // header can already contain "host:port" (e.g. local testing against
      // "localhost:8787"), which Uri's `host` parameter rejects as a bare
      // hostname. Scheme prefers X-Forwarded-Proto, which Cloudflare Tunnel
      // sets to "https" for traffic arriving over the public tunnel even
      // though the hop to this local server itself is plain HTTP.
      final scheme =
          request.headers.value('x-forwarded-proto') ??
          request.requestedUri.scheme;
      final host = request.headers.host ?? request.requestedUri.host;
      final downloadUrl = '$scheme://$host/download/$downloadId';

      response.statusCode = HttpStatus.ok;
      response.write(
        jsonEncode({...built.plan.toJson(), 'downloadUrl': downloadUrl}),
      );
      await response.close();
      return;
    }

    if (request.method == 'GET' &&
        request.uri.pathSegments.length == 2 &&
        request.uri.pathSegments.first == 'download') {
      final stored = _downloadStore[request.uri.pathSegments[1]];
      if (stored == null) {
        response.headers.contentType = ContentType.json;
        response.statusCode = HttpStatus.notFound;
        response.write(
          jsonEncode({
            'error': 'download_not_found',
            'message':
                'No stored download for this id. Downloads are held '
                'in-memory and do not survive a server restart, and are '
                'evicted oldest-first once more than $_maxStoredDownloads '
                'are stored -- call buildExtensionPackage again to get a '
                'fresh link.',
          }),
        );
        await response.close();
        return;
      }

      response.headers.contentType = ContentType.parse('application/zip');
      response.headers.set(
        'Content-Disposition',
        'attachment; filename="${stored.filename}"',
      );
      response.statusCode = HttpStatus.ok;
      response.add(stored.bytes);
      await response.close();
      return;
    }

    response.headers.contentType = ContentType.json;
    response.statusCode = HttpStatus.notFound;
    response.write(
      jsonEncode({
        'error': 'not_found',
        'message':
            'Unknown route ${request.method} ${request.uri.path}. Use '
            'GET /health, POST /validate, POST /package, POST '
            '/package.json, or GET /download/:id.',
      }),
    );
    await response.close();
  } catch (error, stackTrace) {
    stderr.writeln('Unhandled error: $error\n$stackTrace');
    try {
      response.headers.contentType = ContentType.json;
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

Future<void> _appendValidationRound({
  required HttpRequest request,
  required String logPath,
  Map<String, dynamic>? package,
  ValidationReport? report,
}) async {
  try {
    final findingTypes = <String, int>{};
    if (report != null) {
      for (final finding in report.findings) {
        findingTypes.update(
          finding.type,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final reportJson = report?.toJson();
    final entry = <String, dynamic>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'dispatch': request.headers.value('x-loom-dispatch') ?? 'unknown',
      'round': int.tryParse(request.headers.value('x-loom-round') ?? ''),
      'status': reportJson?['status'],
      'errorCount': reportJson?['errorCount'],
      'warningCount': reportJson?['warningCount'],
      'findingTypes': findingTypes,
      'packageId': package?['packageId'],
      'communityId': package?['communityId'],
    };

    final file = await File(logPath).open(mode: FileMode.append);
    try {
      await file.writeString('${jsonEncode(entry)}\n');
      await file.flush();
    } finally {
      await file.close();
    }
  } catch (_) {
    // Round logging is diagnostic only. A full disk, unwritable path, or any
    // other logging failure must never alter the validation response.
  }
}

/// Decodes a request body into the community package map. Two accepted
/// shapes: the raw package itself, or a single-field wrapper
/// `{"packageJson": "<the package, JSON-encoded as a string>"}` -- some
/// Action-calling clients handle a lone string parameter more reliably than
/// a large/open-ended nested object schema, so this collapses the request to
/// exactly one field for them.
Map<String, dynamic> _decodePackageFromBody(String body) {
  if (body.trim().isEmpty) {
    throw const FormatException('Request body is empty.');
  }
  final decoded = jsonDecode(stripJsonComments(body));
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Top-level JSON must be an object.');
  }
  final wrapped = decoded['packageJson'];
  if (wrapped is String && !decoded.containsKey('experience')) {
    final inner = jsonDecode(stripJsonComments(wrapped));
    if (inner is! Map<String, dynamic>) {
      throw const FormatException('packageJson must decode to a JSON object.');
    }
    return inner;
  }
  return decoded;
}
