import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _workflowType = 'opaque-id-test';

LoomWorkflowStateMachine _machine({
  required String writableBy,
  required String platformSource,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'done': {'label': 'Done', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'finish',
      'label': 'Finish',
      'from': ['open'],
      'to': 'done',
    },
  ],
  'instanceDataSchema': {
    'platformValue': {
      'type': 'text?',
      'writableBy': writableBy,
      'platformSource': platformSource,
    },
  },
}, _workflowType);

ValidationReport _validate({
  required String writableBy,
  required String platformSource,
}) => WorkflowValidator().validate({
  _workflowType: _machine(
    writableBy: writableBy,
    platformSource: platformSource,
  ),
});

File _shippedMosquePackage() {
  const relativePath =
      'app/packages/core/loom_communities_app_shell/assets/'
      'Loom_Communities_Workflow_Engine_Mosque_Example.jsonc';
  var directory = Directory.current;
  for (var depth = 0; depth < 8; depth++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) return candidate;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw const FileSystemException('Shipped Mosque package not found');
}

void main() {
  group('platformSource declarations', () {
    test('requires writableBy platform instead of acting as a shorthand', () {
      final findings = _validate(
        writableBy: 'effect',
        platformSource: 'opaqueId',
      ).errors;

      expect(
        findings.where(
          (finding) =>
              finding.type == 'platform_source_requires_platform_writer',
        ),
        hasLength(1),
      );
      final finding = findings.singleWhere(
        (finding) => finding.type == 'platform_source_requires_platform_writer',
      );
      expect(finding.isWarning, isFalse);
      expect(
        finding.location,
        'experience/workflowDefinitions/$_workflowType/'
        'instanceDataSchema/platformValue/platformSource',
      );
      expect(finding.message, contains('not a shorthand'));
    });

    test('rejects an unknown platformSource mechanism', () {
      final findings = _validate(
        writableBy: 'platform',
        platformSource: 'inventedByThisPackage',
      ).errors;

      expect(
        findings.where((finding) => finding.type == 'unknown_platform_source'),
        hasLength(1),
      );
      final finding = findings.singleWhere(
        (finding) => finding.type == 'unknown_platform_source',
      );
      expect(finding.isWarning, isFalse);
      expect(finding.message, contains('checksum and opaqueId'));
      expect(finding.message, contains('grammar decision'));
    });

    test(
      'reports legacy platform fields in a shipped package without failing it',
      () async {
        final package = await ParsedCommunityPackage.fromFile(
          _shippedMosquePackage(),
        );
        final expectedCount = package.workflowDefinitions.values
            .expand((workflow) => workflow.instanceDataSchema.values)
            .where(
              (field) =>
                  field.writableBy == 'platform' &&
                  field.platformSource == null,
            )
            .length;

        expect(expectedCount, greaterThan(0));
        final report = WorkflowValidator().validate(
          package.workflowDefinitions,
        );
        final findings = report.warnings
            .where(
              (finding) =>
                  finding.type ==
                  'platform_writable_field_missing_platform_source',
            )
            .toList();

        expect(report.passed, isTrue);
        expect(findings, hasLength(1));
        expect(findings.single.message, contains('$expectedCount '));
        expect(
          findings.single.message,
          contains('regeneration is what closes it'),
        );
      },
    );
  });
}
