/// Keeps specVersion 4's committed capability snapshot in step with the three
/// implementation-derived capability manifests at the moment of baselining.
///
/// A capability added after the snapshot makes this test fail instead of
/// silently becoming implied by specVersion 4.
///
/// Regenerate the initial snapshot with:
///   dart run bin/generate_capability_baseline.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

import '../bin/generate_capability_baseline.dart' as generator;

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/${generator.specVersionOutputPath}',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Could not locate the repository root.');
}

File _repositoryFile(String path) => File('${_repositoryRoot().path}/$path');

void main() {
  group('generated capability baseline', () {
    test('committed spec snapshot matches the manifests byte-for-byte', () {
      final file = _repositoryFile(generator.specVersionOutputPath);
      final committed = file.readAsStringSync();

      expect(
        committed,
        generator.renderSpecVersion(committed),
        reason:
            'The committed capabilityBaseline has drifted from the capability '
            'manifests. Do not silently expand the specVersion 4 snapshot.',
      );
    });

    test('generated Dart baseline matches the same snapshot byte-for-byte', () {
      expect(
        _repositoryFile(generator.dartOutputPath).readAsStringSync(),
        generator.renderDartBaseline(),
      );
    });

    test('snapshot carries its version, date, and namespaced capabilities', () {
      final document =
          jsonDecode(
                _repositoryFile(
                  generator.specVersionOutputPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final baseline = document['capabilityBaseline'] as Map<String, dynamic>;
      final capabilities = (baseline['capabilities'] as List).cast<String>();

      expect(baseline, generator.buildCapabilityBaseline());
      expect(baseline['specVersion'], currentCommunitySpecVersion);
      expect(baseline['snapshotDate'], '2026-08-20');
      expect(capabilities, orderedEquals(capabilities.toList()..sort()));
      expect(
        capabilities,
        everyElement(
          matches(r'^(archetype|effect|guard|formula|field)\.[^\.]+$'),
        ),
      );
      expect(capabilities.toSet(), generator.buildCapabilityNames());
    });
  });
}
