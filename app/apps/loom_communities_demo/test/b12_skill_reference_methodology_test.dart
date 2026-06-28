import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wf_skill-reference-methodology-planning', () {
    final skill = _readText('docs/Build Plan V2/Skill/SKILL.md');
    final walkthrough = _readText(
      'docs/Build Plan V2/Skill/using-loom-to-build-an-extension.md',
    );

    final requiredReferences = [
      'loom-reference-implementation-methodology.md',
      'extension-creation-process.md',
      'workflow-api-mapping-template.md',
      'ux-methodology-template.md',
      'source-dependency-model.md',
    ];

    for (final reference in requiredReferences) {
      expect(skill, contains('references/$reference'));
      expect(
        File(
          '$_repoRoot/docs/Build Plan V2/Skill/references/$reference',
        ).existsSync(),
        isTrue,
        reason: reference,
      );
    }

    expect(walkthrough, contains('Research the Target Community'));
    expect(walkthrough, contains('Create Product Workflow Docs'));
    expect(
      walkthrough,
      contains('Map Workflows To Loom APIs, Rules, Events, And Tests'),
    );
    expect(walkthrough, contains('Create UX Guidelines And UX Decisions'));
    expect(
      walkthrough,
      contains('Create Extension Build Tracker And Phase Docs'),
    );
    expect(walkthrough, contains('Stop for owner approval'));

    final process = _readText(
      'docs/Build Plan V2/Skill/references/extension-creation-process.md',
    );
    expect(process, contains('planning-only'));
    expect(process, contains('build-and-validate'));
    expect(process, contains('Stop for owner approval'));

    final apiMap = _readText(
      'docs/Build Plan V2/Skill/references/workflow-api-mapping-template.md',
    );
    expect(apiMap, contains('Loom API'));
    expect(apiMap, contains('Event emitted/consumed'));
    expect(apiMap, contains('Validation'));

    final sourceModel = _readText(
      'docs/Build Plan V2/Skill/references/source-dependency-model.md',
    );
    expect(sourceModel, contains('Built Into The Skill'));
    expect(sourceModel, contains('Fetched From The Loom Repo'));
  });
}

String _readText(String path) {
  return File('$_repoRoot/$path').readAsStringSync();
}

String get _repoRoot {
  final candidates = [
    Directory.current.parent.path,
    Directory.current.parent.parent.parent.path,
  ];
  for (final candidate in candidates) {
    if (File('$candidate/docs/Build Plan V2/Skill/SKILL.md').existsSync()) {
      return candidate;
    }
  }
  fail('Could not find repo root from ${Directory.current.path}');
}
