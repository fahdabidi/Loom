import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _workflowType = 'opaque-id-test';

LoomWorkflowStateMachine _machine({
  required String writableBy,
  String? platformSource,
  String fieldName = 'platformValue',
  String fieldType = 'text?',
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
    fieldName: {
      'type': fieldType,
      'writableBy': writableBy,
      if (platformSource != null) 'platformSource': platformSource,
    },
  },
}, _workflowType);

ValidationReport _validate({
  required String writableBy,
  String? platformSource,
  String fieldName = 'platformValue',
  String fieldType = 'text?',
}) => WorkflowValidator().validate({
  _workflowType: _machine(
    writableBy: writableBy,
    platformSource: platformSource,
    fieldName: fieldName,
    fieldType: fieldType,
  ),
});

Iterable<ValidationFinding> _missingPlatformSourceFindings(
  ValidationReport report,
) => report.findings.where(
  (finding) =>
      finding.type == 'platform_writable_field_missing_platform_source',
);

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
    test('accepts an opaque-id field that a generic dispatcher resolves', () {
      final report = _validate(
        writableBy: 'platform',
        platformSource: 'opaqueId',
      );

      expect(_missingPlatformSourceFindings(report), isEmpty);
    });

    test(
      'does not require a source for handler-owned platform bookkeeping',
      () {
        final checksumVerified = _validate(
          writableBy: 'platform',
          fieldName: 'checksumVerified',
          fieldType: 'bool',
        );
        final readFanIds = _validate(
          writableBy: 'platform',
          fieldName: 'readFanIds',
          fieldType: 'fanId[]',
        );

        expect(_missingPlatformSourceFindings(checksumVerified), isEmpty);
        expect(_missingPlatformSourceFindings(readFanIds), isEmpty);
      },
    );

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
      'does not require sources for bookkeeping in a shipped package',
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
        final bookkeepingFields = package.workflowDefinitions.values
            .expand((workflow) => workflow.instanceDataSchema.entries)
            .where(
              (entry) =>
                  entry.value.writableBy == 'platform' &&
                  entry.value.platformSource == null,
            )
            .map((entry) => entry.key)
            .toSet();

        expect(expectedCount, greaterThan(0));
        expect(
          bookkeepingFields,
          containsAll(['readFanIds', 'reminderHistory']),
        );
        final report = WorkflowValidator().validate(
          package.workflowDefinitions,
        );
        final findings = _missingPlatformSourceFindings(report).toList();

        expect(report.passed, isTrue);
        expect(findings, isEmpty);
      },
    );
  });
}
