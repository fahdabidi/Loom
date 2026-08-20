/// Runs the docs-sync gate over the real reference tree, and proves the gate
/// itself catches drift.
///
/// The second half matters as much as the first: a checker that never fails is
/// indistinguishable from no checker, which is the state this repo was already
/// in — `docs-sync-checker.md` specified the tool, nothing built it, and three
/// separate drifts followed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/docs_sync_checker.dart';
import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${dir.path}/docs/references').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not locate the repo root from ${Directory.current.path}.',
  );
}

/// A throwaway copy of the reference tree, so drift can be injected without
/// touching the real docs.
Directory _sandbox() {
  final root = _repoRoot();
  final temp = Directory.systemTemp.createTempSync('docs_sync_');
  final refs = Directory('${temp.path}/docs/references')
    ..createSync(recursive: true);
  for (final entity in Directory(
    '${root.path}/docs/references',
  ).listSync(recursive: true)) {
    final relative = entity.path.substring(
      '${root.path}/docs/references'.length + 1,
    );
    if (entity is Directory) {
      Directory('${refs.path}/$relative').createSync(recursive: true);
    } else if (entity is File) {
      final target = File('${refs.path}/$relative');
      target.parent.createSync(recursive: true);
      entity.copySync(target.path);
    }
  }
  return temp;
}

void main() {
  group('docs-sync checker', () {
    test('the real reference tree is in sync', () {
      final report = DocsSyncChecker(_repoRoot()).check();
      expect(
        report.findings.map((f) => f.toString()).toList(),
        isEmpty,
        reason: 'docs/references has drifted from spec-version.json.',
      );
      expect(report.docsChecked, greaterThan(20));
    });

    test('catches a doc left on an older version', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      final doc = File('${sandbox.path}/docs/references/reference/guards.md');
      doc.writeAsStringSync(
        doc.readAsStringSync().replaceFirst(
          RegExp(r'^spec: \d+$', multiLine: true),
          'spec: 3',
        ),
      );

      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(findings.map((f) => f.type), contains('doc_version_drift'));
    });

    test('catches the legacy three-number frontmatter', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      final doc = File('${sandbox.path}/docs/references/reference/guards.md');
      doc.writeAsStringSync(
        doc.readAsStringSync().replaceFirst(
          RegExp(r'^spec: \d+$', multiLine: true),
          'spec: { envelope: 1, experience: 2, grammar: 2 }',
        ),
      );

      final findings = DocsSyncChecker(sandbox).check().findings;
      final drift = findings.where((f) => f.type == 'doc_version_drift');
      expect(drift, isNotEmpty);
      expect(drift.first.message, contains('legacy three-number form'));
    });

    test('catches a doc that no manifest entry tracks', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      File(
        '${sandbox.path}/docs/references/reference/untracked.md',
      ).writeAsStringSync('---\nspec: 4\n---\n\n# Untracked\n');

      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(findings.map((f) => f.type), contains('unmanifested_doc'));
    });

    test('catches a derivedFrom source that has moved or been deleted', () {
      // The CommunityVoteApi failure in one test: docs outliving their source.
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      final manifestFile = File(
        '${sandbox.path}/docs/references/_meta/doc-manifest.json',
      );
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
      final docs = (manifest['docs'] as List).cast<Map<String, Object?>>();
      docs.firstWhere((d) => d['status'] != 'planned')['derivedFrom'] = [
        'app/packages/core/deleted_thing.dart',
      ];
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(findings.map((f) => f.type), contains('derived_from_missing'));
    });

    test('catches a manifest entry whose file is gone', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      File('${sandbox.path}/docs/references/reference/guards.md').deleteSync();

      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(findings.map((f) => f.type), contains('manifest_orphan'));
    });

    test('rejects a reverted three-number spec-version.json', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      final file = File('${sandbox.path}/docs/references/spec-version.json');
      final spec = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      spec['current'] = {'envelope': 1, 'experience': 2, 'grammar': 3};
      file.writeAsStringSync(jsonEncode(spec));

      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(findings.map((f) => f.type), contains('bad_spec_version'));
    });

    test('migrated fixtures no longer need a pendingMigration exemption', () {
      final sandbox = _sandbox();
      addTearDown(() => sandbox.deleteSync(recursive: true));

      // Every shipped fixture now carries specVersion: 4, so the historical
      // exemption is no longer what keeps this check clean.
      final findings = DocsSyncChecker(sandbox).check().findings;
      expect(
        findings.map((f) => f.type),
        isNot(contains('fixture_missing_spec_version')),
        reason: 'The v4 fixtures must remain clean without an exemption.',
      );
    });
  });
}
