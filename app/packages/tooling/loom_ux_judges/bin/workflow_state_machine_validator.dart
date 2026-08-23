import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/src/models/workflow_models.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.isEmpty) {
    _usage();
    return;
  }

  final definitionsPath = _argValue(args, '--definitions');
  if (definitionsPath == null) {
    stderr.writeln('Missing required --definitions <json-file-or-directory>');
    _usage();
    exit(64);
  }

  final templatesPath = _argValue(args, '--templates');
  final tableConfigsPath = _argValue(args, '--table-configs');
  final outputPath = _argValue(args, '--output');

  // Load workflow definitions
  final WorkflowDefinitionsBundle definitionBundle;
  final Set<String> knownRoleIds;
  final Map<String, LoomWorkflowStateMachine> workflows;
  try {
    definitionBundle = _loadDefinitions(definitionsPath);
    workflows = definitionBundle.workflows;
    knownRoleIds = definitionBundle.knownRoleIds;
  } catch (e) {
    stderr.writeln('Failed to load definitions: $e');
    exit(1);
  }

  if (workflows.isEmpty) {
    stderr.writeln('No workflow definitions found in "$definitionsPath".');
    exit(1);
  }

  // Load optional templates
  Map<String, Map<String, dynamic>>? templates;
  if (templatesPath != null) {
    try {
      final raw = jsonDecode(File(templatesPath).readAsStringSync());
      templates = (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as Map<String, dynamic>),
      );
    } catch (e) {
      stderr.writeln('Failed to load templates: $e');
      exit(1);
    }
  }

  // Load optional table archetype configs
  Map<String, Map<String, dynamic>>? tableConfigs;
  if (tableConfigsPath != null) {
    try {
      final raw = jsonDecode(File(tableConfigsPath).readAsStringSync());
      tableConfigs = (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as Map<String, dynamic>),
      );
    } catch (e) {
      stderr.writeln('Failed to load table configs: $e');
      exit(1);
    }
  }

  // Run validation
  final validator = WorkflowValidator(
    templates: templates,
    tableArchetypeConfigs: tableConfigs,
    knownRoleIds: knownRoleIds,
  );
  final report = validator.validate(workflows);
  final json = const JsonEncoder.withIndent('  ').convert(report.toJson());

  if (outputPath != null) {
    File(outputPath).writeAsStringSync('$json\n');
  }
  stdout.writeln(json);

  if (!report.passed) {
    stderr.writeln(
      'workflow_state_machine_validator: fail '
      '(${report.errors.length} errors, ${report.warnings.length} warnings)',
    );
    for (final e in report.errors) {
      stderr.writeln('  ERROR: $e');
    }
    for (final w in report.warnings) {
      stderr.writeln('  WARNING: $w');
    }
    exit(1);
  }

  if (report.warnings.isNotEmpty) {
    stderr.writeln(
      'workflow_state_machine_validator: pass '
      '(${report.warnings.length} warnings)',
    );
    for (final w in report.warnings) {
      stderr.writeln('  WARNING: $w');
    }
  } else {
    stdout.writeln('workflow_state_machine_validator: pass (clean)');
  }
}

class WorkflowDefinitionsBundle {
  final Map<String, LoomWorkflowStateMachine> workflows;
  final Set<String> knownRoleIds;

  WorkflowDefinitionsBundle({
    required this.workflows,
    this.knownRoleIds = const <String>{},
  });
}

WorkflowDefinitionsBundle _loadDefinitions(String path) {
  final file = File(path);
  if (file.existsSync()) {
    return _parseDefinitionsFile(file);
  }

  final dir = Directory(path);
  if (dir.existsSync()) {
    final result = <String, LoomWorkflowStateMachine>{};
    final allRoles = <String>{};
    for (final entity in dir.listSync()) {
      if (entity is File &&
          (entity.path.endsWith('.json') || entity.path.endsWith('.jsonc'))) {
        final parsed = _parseDefinitionsFile(entity);
        result.addAll(parsed.workflows);
        allRoles.addAll(parsed.knownRoleIds);
      }
    }

    return WorkflowDefinitionsBundle(workflows: result, knownRoleIds: allRoles);
  }

  throw FileSystemException('Path not found', path);
}

WorkflowDefinitionsBundle _parseDefinitionsFile(File file) {
  final content = stripJsonComments(file.readAsStringSync());
  final json = jsonDecode(content) as Map<String, dynamic>;

  // Support both plain definitions map and the marketplace fixture's
  // {"workflowDefinitions": {...}, "workflowInstances": [...]} shape
  final defs = json['workflowDefinitions'] as Map<String, dynamic>? ?? json;
  final knownRoles = <String>{};
  if (json['roles'] is List<dynamic>) {
    for (final role in (json['roles'] as List<dynamic>)) {
      if (role is String && role.isNotEmpty) {
        knownRoles.add(role);
      }
    }
  }

  final workflows = defs.map((k, v) {
    final definition = v as Map<String, dynamic>;
    return MapEntry(k, LoomWorkflowStateMachine.fromJson(definition, k));
  });

  return WorkflowDefinitionsBundle(
    workflows: workflows,
    knownRoleIds: knownRoles,
  );
}

String? _argValue(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx == -1 || idx + 1 >= args.length) return null;
  final val = args[idx + 1];
  if (val.startsWith('--')) return null; // next arg is another flag
  return val;
}

void _usage() {
  stdout.writeln('''
workflow_state_machine_validator — validates LoomWorkflowStateMachine JSON
definitions against §7c checks (stuck states, unreachable states, dangling
references, dependency cycles, missing labels, binding cap, editableFields
constraints, action-button-row mandation, sortable-column backing).

Usage:
  dart run packages/tooling/loom_ux_judges/bin/workflow_state_machine_validator.dart \\
    --definitions <json-file-or-directory> \\
    [--templates <json>] \\
    [--table-configs <json>] \\
    [--output <json>]

Options:
  --definitions  Path to a single JSON/JSONC file or a directory of them.
                 Supports both plain {"workflowType": {...}} maps and the
                 marketplace fixture's {"workflowDefinitions": {...}} shape.
  --templates    Optional. JSON map of templateName → { "slots": [...] }.
                 Enables the action-button-row check (§7d).
  --table-configs Optional. JSON map of workflowType → { "columns": [...] }.
                 Enables the sortable-column check.
  --output       Optional. Write the JSON report to this file instead of stdout.

Exit codes: 0 = pass (no errors), 1 = fail (errors found).
''');
}
