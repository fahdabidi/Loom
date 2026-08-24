import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _lockedLiterals = <String, String>{
  'wf_demo-app-persona-picker':
      'docs/references/communities/masjid-nur-product-experience.md', // Identifier: wf_demo-app-persona-picker.
  'wf_community-persona-aware-ux':
      'docs/references/communities/masjid-nur-product-experience.md', // Identifier: wf_community-persona-aware-ux.
  'wf_multi-persona-workflow-evidence':
      'docs/references/communities/masjid-nur-product-experience.md', // Identifier: wf_multi-persona-workflow-evidence.
  'dangling_allowed_persona_id':
      'docs/references/guide/05-validation.md', // Identifier: dangling_allowed_persona_id.
  'transition_action_cannot_set_by_persona_ids':
      'docs/references/guide/05-validation.md', // Identifier: transition_action_cannot_set_by_persona_ids.
};

void main() {
  test('Dart sources contain no retired identity vocabulary', () {
    final appDirectory = _findAppDirectory(Directory.current);
    final retiredToken = ['per', 'sona'].join();
    final retiredPattern = RegExp(retiredToken, caseSensitive: false);
    final failures = <String>[];

    for (final entity in appDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      // File.path uses the platform separator; every path literal in this
      // test is written with forward slashes, so normalise or the allowlist
      // self-exclusion silently fails on Windows and the gate flags its own
      // allowlist entries.
      final relativePath = entity.path
          .substring(appDirectory.path.length + 1)
          .replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        if (_isAllowlistDeclaration(relativePath, line)) {
          continue;
        }
        var inspected = line;
        for (final literal in _lockedLiterals.keys) {
          inspected = inspected
              .replaceAll("'$literal'", "''")
              .replaceAll('"$literal"', '""');
        }
        if (retiredPattern.hasMatch(inspected)) {
          failures.add('$relativePath:${index + 1}: $line');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Rename every retired token according to whether it names a fan, '
          'a role, or an actor identity. Exact locked identifiers are the only '
          'exceptions.\n${failures.join('\n')}',
    );
  });
}

Directory _findAppDirectory(Directory start) {
  var candidate = start.absolute;
  while (candidate.parent.path != candidate.path) {
    if (Directory('${candidate.path}/apps').existsSync() &&
        Directory('${candidate.path}/packages').existsSync()) {
      return candidate;
    }
    candidate = candidate.parent;
  }
  throw StateError('Could not locate the app workspace from ${start.path}.');
}

bool _isAllowlistDeclaration(String relativePath, String line) {
  if (relativePath !=
      'apps/loom_communities_demo/test/retired_vocabulary_gate_test.dart') {
    return false;
  }
  return _lockedLiterals.entries.any(
    (entry) =>
        line.trim() == "'${entry.key}':" ||
        (line.contains("'${entry.value}'") &&
            line.endsWith('// Identifier: ${entry.key}.')),
  );
}
