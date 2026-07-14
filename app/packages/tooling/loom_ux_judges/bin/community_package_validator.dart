import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help')) {
    _usage();
    return;
  }
  final path = _argValue(args, '--package');
  if (path == null) {
    stderr.writeln('Missing required --package <json-file-or-directory>');
    _usage();
    exit(64);
  }
  final findings = <ValidationFinding>[];
  try {
    for (final file in _files(path)) {
      findings.addAll(
        CommunityPackageValidator()
            .validate(
              jsonDecode(stripJsonComments(file.readAsStringSync()))
                  as Map<String, dynamic>,
            )
            .findings,
      );
    }
  } catch (error) {
    stderr.writeln('Failed to load package: $error');
    exit(1);
  }
  final report = ValidationReport(findings);
  final output = const JsonEncoder.withIndent('  ').convert(report.toJson());
  final outputPath = _argValue(args, '--output');
  if (outputPath != null) File(outputPath).writeAsStringSync('$output\n');
  stdout.writeln(output);
  final warningsAsErrors = args.contains('--warnings-as-errors');
  if (!report.passed || (warningsAsErrors && report.warnings.isNotEmpty)) {
    for (final finding in report.findings) {
      stderr.writeln('  ${finding.isWarning ? 'WARNING' : 'ERROR'}: $finding');
    }
    exit(1);
  }
}

Iterable<File> _files(String path) {
  final file = File(path);
  if (file.existsSync()) return [file];
  final dir = Directory(path);
  if (dir.existsSync())
    return dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json') || f.path.endsWith('.jsonc'),
    );
  throw FileSystemException('Path not found', path);
}

String? _argValue(List<String> args, String flag) {
  final i = args.indexOf(flag);
  return i < 0 || i + 1 >= args.length || args[i + 1].startsWith('--')
      ? null
      : args[i + 1];
}

void _usage() => stdout.writeln(
  'Usage: dart run loom_ux_judges:community_package_validator --package <file-or-dir> [--output <json>] [--warnings-as-errors]',
);
