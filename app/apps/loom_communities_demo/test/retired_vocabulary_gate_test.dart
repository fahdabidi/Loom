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
  'created_by_persona_id':
      'docs/Build Plan V2/Evidence/backend/create-instance-500-root-cause.md', // Identifier: created_by_persona_id.
};

void main() {
  test('Dart sources contain no retired identity vocabulary', () {
    final appDirectory = _findAppDirectory(Directory.current);
    final retiredToken = ['per', 'sona'].join();
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
          inspected = _removeAllowedLiteral(inspected, literal);
        }
        if (_containsRetiredIdentifier(inspected, retiredToken)) {
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

/// Whether [line] uses [token] as an **identifier component**, rather than
/// merely containing it as a substring of an ordinary English word.
///
/// The gate previously matched with a bare `RegExp(token)`, which flagged two
/// ordinary English words that merely contain the token as a substring — one
/// meaning "pretending to be someone else", the other "tailored to an
/// individual". Neither is retired identity vocabulary. That is precisely the
/// failure this project's own standing rule names: never match product
/// vocabulary by substring.
///
/// Note this comment deliberately describes its examples rather than spelling
/// them out. Writing them literally would make this file violate the very gate
/// it implements — which is why the token itself is assembled from fragments
/// at the top of the test rather than typed.
///
/// The rule applied here:
///
/// * preceded by a letter -> part of a larger word, unless the match itself
///   starts uppercase, which is a camelCase boundary and so still a component;
/// * followed by a lowercase letter -> part of a larger word;
/// * otherwise it is an identifier component and a genuine violation, whether
///   snake_cased, camelCased, capitalised, or bare.
bool _containsRetiredIdentifier(String line, String token) {
  final haystack = line.toLowerCase();
  final needle = token.toLowerCase();
  final letter = RegExp(r'[A-Za-z]');
  final lowercase = RegExp(r'[a-z]');

  var index = haystack.indexOf(needle);
  while (index >= 0) {
    final matched = line.substring(index, index + needle.length);
    final startsUppercase = matched[0] == matched[0].toUpperCase();

    final before = index > 0 ? line[index - 1] : '';
    final afterIndex = index + needle.length;
    final after = afterIndex < line.length ? line[afterIndex] : '';

    final continuesAWord =
        before.isNotEmpty && letter.hasMatch(before) && !startsUppercase;
    final isPrefixOfAWord = after.isNotEmpty && lowercase.hasMatch(after);

    if (!continuesAWord && !isPrefixOfAWord) return true;
    index = haystack.indexOf(needle, index + 1);
  }
  return false;
}

String _removeAllowedLiteral(String line, String literal) {
  final result = StringBuffer();
  var remainingStart = 0;
  var matchStart = line.indexOf(literal);

  while (matchStart >= 0) {
    final matchEnd = matchStart + literal.length;
    final hasIdentifierPrefix =
        matchStart > 0 && _isIdentifierCharacter(line[matchStart - 1]);
    final hasIdentifierSuffix =
        matchEnd < line.length && _isIdentifierCharacter(line[matchEnd]);
    if (hasIdentifierPrefix || hasIdentifierSuffix) {
      result.write(line.substring(remainingStart, matchEnd));
      remainingStart = matchEnd;
    } else {
      result.write(line.substring(remainingStart, matchStart));
      remainingStart = matchEnd;
    }
    matchStart = line.indexOf(literal, remainingStart);
  }

  result.write(line.substring(remainingStart));
  return result.toString();
}

bool _isIdentifierCharacter(String character) {
  final codeUnit = character.codeUnitAt(0);
  return codeUnit == 95 ||
      (codeUnit >= 48 && codeUnit <= 57) ||
      (codeUnit >= 65 && codeUnit <= 90) ||
      (codeUnit >= 97 && codeUnit <= 122);
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
