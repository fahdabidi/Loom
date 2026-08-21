import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/docs/references/reference/effects.md',
    ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not locate the repository root.');
}

String _readRepositoryFile(String relativePath) =>
    File('${_repositoryRoot().path}/$relativePath').readAsStringSync();

Set<String> _documentedEffectOperations() {
  final source = _readRepositoryFile('docs/references/reference/effects.md');
  return {
    for (final line in source.split('\n'))
      if (line.startsWith('### '))
        for (final match in RegExp(r'`([a-z][A-Za-z0-9]*)`').allMatches(line))
          match.group(1)!,
  };
}

Set<String> _documentedGuardKinds() {
  final source = _readRepositoryFile('docs/references/reference/guards.md');
  return {
    for (final match in RegExp(
      r'^##\s+\d+\.\s+`([^`]+)`',
      multiLine: true,
    ).allMatches(source))
      match.group(1)!,
  };
}

Set<String> _documentedFormulaFunctions() {
  final source = _readRepositoryFile('docs/references/reference/formulas.md');
  final functions = <String>{};
  final row = RegExp(
    r'^\| `([A-Za-z][A-Za-z0-9]*)` \| `([A-Za-z][A-Za-z0-9]*)\(',
    multiLine: true,
  );
  for (final match in row.allMatches(source)) {
    if (match.group(1) == match.group(2)) functions.add(match.group(1)!);
  }
  return functions;
}

Set<String> _effectOperationsReferencedByImplementations() {
  final capabilitySource = _readRepositoryFile(
    'app/packages/core/loom_workflow_engine/lib/src/'
    'workflow_capabilities.dart',
  );
  final constants = <String, String>{
    for (final match in RegExp(
      r"const String (workflowEffect\w+)\s*=\s*'([^']+)';",
    ).allMatches(capabilitySource))
      match.group(1)!: match.group(2)!,
  };
  final implementationSources = [
    _readRepositoryFile(
      'app/packages/core/loom_workflow_engine/lib/src/evaluator/'
      'effect_evaluator.dart',
    ),
    _readRepositoryFile(
      'app/packages/core/loom_workflow_engine/lib/src/api/'
      'local_workflow_engine_api.dart',
    ),
  ];
  final referencedConstantNames = <String>{};
  final reference = RegExp(
    r'(?:case\s+|effect\.op\s*==\s*)(workflowEffect\w+)',
  );
  for (final source in implementationSources) {
    referencedConstantNames.addAll(
      reference.allMatches(source).map((match) => match.group(1)!),
    );
  }
  return {
    for (final name in referencedConstantNames)
      if (constants[name] case final value?) value,
  };
}

void main() {
  test('documented effect ops, guard kinds, and formulas are implemented', () {
    expect(supportedWorkflowEffectOperations, _documentedEffectOperations());
    expect(supportedWorkflowGuardKinds, _documentedGuardKinds());
    expect(supportedWorkflowFormulaFunctions, _documentedFormulaFunctions());

    expect(
      _effectOperationsReferencedByImplementations(),
      supportedWorkflowEffectOperations,
      reason:
          'Every declared effect op must be referenced by the evaluator or '
          'the transactional engine implementation.',
    );

    final parsedGuardKinds = <String>{...WorkflowGuard.jsonKeys}
      ..remove(workflowGuardRelatedInstanceFieldKey)
      ..remove(workflowGuardRelatedListFieldKey)
      ..add(workflowGuardRelatedListMembership);
    expect(parsedGuardKinds, supportedWorkflowGuardKinds);
    expect(supportedWorkflowFormulaFunctions, formulaFunctionNames);
  });

  test('no component owns a numeric specVersion literal', () {
    final root = _repositoryRoot();
    final literalPattern = RegExp(
      r'''specVersion[^\n]{0,8}[:=,]\s*['"]?(\d+)''',
    );
    final discrepancies = <String>[];
    final appDirectory = Directory('${root.path}/app');
    for (final entity in appDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path ==
          '${root.path}/app/packages/core/loom_workflow_engine/test/'
              'capability_conformance_test.dart') {
        continue;
      }
      if (entity.path.contains('/.dart_tool/') ||
          entity.path.contains('/build/')) {
        continue;
      }
      if (entity.path.endsWith('/lib/src/spec_version.dart')) continue;
      final relativePath = entity.path.substring(root.path.length + 1);
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final match = literalPattern.firstMatch(lines[index]);
        if (match == null) continue;
        discrepancies.add(
          '$relativePath:${index + 1} owns specVersion ${match.group(1)}',
        );
      }
    }
    expect(discrepancies, isEmpty, reason: discrepancies.join('\n'));
  });
}
