/// Every shipped community package validates clean, checked through the
/// validator's HTTP API — the same endpoint the Skill calls when authoring.
///
/// Why this did not exist, and why its absence mattered:
///
/// The validator gained rules after the corpus was authored (`visibility.fields`
/// typing, render-binding reachability, `sharedWith` cardinality). Each new rule
/// was tested against fixtures, never re-run across the packages already on
/// disk. So packages authored under an older, laxer validator kept shipping, and
/// the only thing that would have noticed is a check nobody had written.
///
/// This runs the API against the real corpus. It goes red on any package the
/// current validator rejects, whenever that package was written.
///
/// The server is started here on an ephemeral port rather than assumed to be
/// running on 8787: the API path is what we want to exercise, an external
/// service dependency is not.
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/validator_http_server.dart';
import 'package:test/test.dart';

const _corpusDirectory = 'docs/references/communities';

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${directory.path}/$_corpusDirectory').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the repository root from ${Directory.current.path}.',
  );
}

List<File> _corpusFiles() {
  final directory = Directory('${_repositoryRoot().path}/$_corpusDirectory');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.jsonc'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _shortName(File file) {
  final name = file.uri.pathSegments.last;
  return name
      .replaceAll('Loom_Communities_Workflow_Engine_', '')
      .replaceAll('_Example.jsonc', '');
}

void main() {
  late HttpServer server;
  late Uri base;
  late HttpClient client;
  late Directory temporaryDirectory;

  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'loom-corpus-validation-',
    );
    // port: 0 -> OS-assigned, so this never collides with a dev server on 8787.
    server = await startValidatorServer(
      address: InternetAddress.loopbackIPv4,
      port: 0,
      validatorLogPath: '${temporaryDirectory.path}/rounds.jsonl',
    );
    base = Uri.parse('http://127.0.0.1:${server.port}');
    client = HttpClient();
  });

  tearDownAll(() async {
    client.close(force: true);
    await server.close(force: true);
    await temporaryDirectory.delete(recursive: true);
  });

  Future<Map<String, dynamic>> validate(File file) async {
    final request = await client.postUrl(base.replace(path: '/validate'));
    request.headers.contentType = ContentType.json;
    // Posted as raw JSONC: the endpoint strips comments itself, so this is
    // byte-for-byte what ships rather than a re-serialised approximation.
    request.write(file.readAsStringSync());
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      fail(
        'Validator API returned ${response.statusCode} for '
        '${_shortName(file)}: $body',
      );
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  test('the corpus is non-empty', () {
    // Without this, a bad path would make every package test silently vanish
    // and the suite would pass by validating nothing.
    expect(
      _corpusFiles(),
      isNotEmpty,
      reason: 'No .jsonc packages found under $_corpusDirectory.',
    );
  });

  group('shipped community packages validate clean', () {
    for (final file in _corpusFiles()) {
      test(_shortName(file), () async {
        final report = await validate(file);
        final findings = (report['findings'] as List)
            .cast<Map<String, dynamic>>();
        final errors = findings
            .where((finding) => finding['isWarning'] != true)
            .toList();

        expect(
          errors,
          isEmpty,
          reason:
              '${_shortName(file)} fails the current validator with '
              '${errors.length} error(s):\n'
              '${errors.map((e) => '  [${e['type']}] ${e['location']}: ${e['message']}').join('\n')}\n\n'
              'Fix by regenerating the package through the Skill — never by '
              'hand-editing the JSON, and never by weakening this gate.',
        );
      });
    }
  });
}
