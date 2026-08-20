import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  test('shared spec version matches docs/references/spec-version.json', () {
    final source = _repositoryFile('docs/references/spec-version.json');
    final decoded =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;

    expect(currentCommunitySpecVersion, decoded['current']);
  });
}

File _repositoryFile(String relativePath) {
  var directory = Directory.current;
  for (var depth = 0; depth < 8; depth++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Could not find $relativePath from ${Directory.current}.');
}
