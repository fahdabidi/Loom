import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/loom_ux_judges.dart';
import 'package:test/test.dart';

void main() {
  late Directory evidenceRoot;

  setUp(() async {
    evidenceRoot = await Directory.systemTemp.createTemp(
      'loom-b25-accumulation-',
    );
  });

  tearDown(() async {
    await evidenceRoot.delete(recursive: true);
  });

  test(
    'a later partial/failed aggregate does not erase earlier phase evidence',
    () async {
      // First partial run banks phase A's evidence directly on disk.
      await _writePhaseManifest(
        evidenceRoot,
        phase: 'B13',
        workflowId: 'gear-loan-request',
        communityId: 'community_camera_club',
        communityName: 'Camera Club',
        role: 'member',
        screenshots: 5,
      );

      // Second partial run banks phase B's evidence on disk.
      await _writePhaseManifest(
        evidenceRoot,
        phase: 'B14',
        workflowId: 'book-vote',
        communityId: 'community_book_club',
        communityName: 'Neighborhood Book Club',
        role: 'member',
        screenshots: 5,
      );

      // The second partial run's schema-v2 writer then clobbers the canonical
      // aggregate and reports failure without carrying forward either phase.
      final aggregate = File(
        '${evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
      );
      await aggregate.parent.create(recursive: true);
      await aggregate.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schemaVersion': 2,
          'status': 'fail',
          'evidenceMode': 'failed',
          'walkthroughStatus': 'not-completed',
          'completionGateEligible': false,
          'phases': <String>[],
          'workflowCount': 0,
          'screenshotCount': 0,
          'workflowEvidenceManifestPaths': <String>[],
        }),
      );

      final repoRoot = Directory(
        '${evidenceRoot.path}/repo',
      )..createSync(recursive: true);

      final review = collectB25Evidence(
        evidenceRootPath: evidenceRoot.path,
        repoRootPath: repoRoot.path,
        runId: 'b25-accumulation-test',
      );

      final workflowIds = (review['screenRows'] as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map((row) => row['workflowId'])
          .toSet();
      expect(workflowIds, containsAll(<String>[
        'gear-loan-request',
        'book-vote',
      ]));

      final coverage =
          review['b25EvidenceCoverage'] as Map<String, Object?>;
      final capturedPhases = _strings(coverage['capturedPhases']).toSet();
      expect(capturedPhases, containsAll(<String>['B13', 'B14']));
      final neverRun = _strings(coverage['neverRunPhases']);
      expect(neverRun, isNot(contains('B13')));
      expect(neverRun, isNot(contains('B14')));
      expect(neverRun, contains('B12'));
    },
  );
}

Future<void> _writePhaseManifest(
  Directory evidenceRoot, {
  required String phase,
  required String workflowId,
  required String communityId,
  required String communityName,
  required String role,
  required int screenshots,
}) async {
  final phaseDir = Directory('${evidenceRoot.path}/$phase/screenshots')
    ..createSync(recursive: true);
  final screenshotPaths = <String>[];
  final screenshotNames = <String>[];
  final screenshotVisibleTexts = <String>[];
  for (var index = 0; index < screenshots; index += 1) {
    final name = '${phase}_$workflowId\u005f$index';
    final file = File('${phaseDir.path}/$name.png')..writeAsBytesSync(<int>[
      1,
      2,
      3,
    ]);
    screenshotPaths.add(file.path);
    screenshotNames.add(name);
    screenshotVisibleTexts.add(
      'primary action text plus alternate/change/reject action text',
    );
  }

  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'phase': phase,
    'status': 'pass',
    'emulatorName': 'test-device',
    'deviceClass': 'test',
    'apiLevel': 'test',
    'workflowCount': 1,
    'workflows': <Object?>[
      <String, Object?>{
        'workflowId': workflowId,
        'communityId': communityId,
        'communityName': communityName,
        'role': role,
        'screenshotPaths': screenshotPaths,
        'screenshotNames': screenshotNames,
        'screenshotVisibleTexts': screenshotVisibleTexts,
      },
    ],
  };
  await File(
    '${evidenceRoot.path}/$phase/workflow-ui-evidence.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
}

List<String> _strings(Object? value) => (value as List<Object?>? ?? const <Object?>[])
    .whereType<String>()
    .toList(growable: false);
