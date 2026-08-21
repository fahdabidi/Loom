import 'dart:io';

import 'package:loom_ux_judges/validator_capabilities.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/docs/references/guide/05-validation.md',
    ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the repository root.');
}

String _readRepositoryFile(String relativePath) =>
    File('${_repositoryRoot().path}/$relativePath').readAsStringSync();

Set<String> _implementedFindingCodes() {
  final sources = [
    _readRepositoryFile(
      'app/packages/tooling/loom_ux_judges/lib/src/validator/'
      'community_package_validator.dart',
    ),
    _readRepositoryFile(
      'app/packages/tooling/loom_ux_judges/lib/src/validator/'
      'workflow_validator.dart',
    ),
  ];
  final codes = <String>{};
  final directFinding = RegExp(
    r"_finding\(\s*'([a-z][a-z0-9_]*)'",
    multiLine: true,
  );
  final findingType = RegExp(r"type:\s*'([a-z][a-z0-9_]*)'");
  final conditionalFinding = RegExp(
    r"_finding\(\s*\w+\s*\?\s*'([a-z][a-z0-9_]*)'\s*"
    r":\s*'([a-z][a-z0-9_]*)'",
    multiLine: true,
  );
  for (final source in sources) {
    codes.addAll(directFinding.allMatches(source).map((m) => m.group(1)!));
    codes.addAll(findingType.allMatches(source).map((m) => m.group(1)!));
    for (final match in conditionalFinding.allMatches(source)) {
      codes.add(match.group(1)!);
      codes.add(match.group(2)!);
    }
  }
  return codes;
}

Set<String> _documentedFindingCodes() {
  final guide = _readRepositoryFile('docs/references/guide/05-validation.md');
  final codes = <String>{};
  for (final line in guide.split('\n')) {
    final firstCell = RegExp(r'^\|\s*([^|]+)\|').firstMatch(line)?.group(1);
    if (firstCell == null) continue;
    codes.addAll(
      RegExp(
        r'`([a-z][a-z0-9_]*)`',
      ).allMatches(firstCell).map((match) => match.group(1)!),
    );
  }
  return codes;
}

void main() {
  test('validator finding-code manifest matches every emission site', () {
    expect(communityPackageValidatorFindingCodes, _implementedFindingCodes());
    expect(
      validatorCardSurfaceFamiliesRequiringAction,
      ArchetypeResolver.bespokeFamilies,
    );
  });

  test(
    'every validator finding code is documented, and every documented code exists',
    () {
      final documented = _documentedFindingCodes();
      final implemented = communityPackageValidatorFindingCodes;
      final documentedButMissing = documented.difference(implemented).toList()
        ..sort();
      final emittedButUndocumented = implemented.difference(documented).toList()
        ..sort();

      expect(
        documentedButMissing.isEmpty && emittedButUndocumented.isEmpty,
        isTrue,
        reason:
            'Documented but not emitted: $documentedButMissing\n'
            'Emitted but undocumented: $emittedButUndocumented',
      );
    },
  );
}
