/// Snapshots the capabilities implemented by the workflow engine, App Shell,
/// and validator into the spec-version metadata consumed by package authors.
///
/// The baseline is deliberately a snapshot. This generator is the one-time
/// bridge from implementation-derived manifests to that committed snapshot;
/// the artifact test makes a later manifest addition fail until it is handled
/// explicitly as a post-baseline capability.
///
///   dart run bin/generate_capability_baseline.dart          # write
///   dart run bin/generate_capability_baseline.dart --check  # verify only
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/validator_capabilities.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import '../../../core/loom_communities_app_shell/lib/src/app_shell_capabilities.dart';

/// Repo-relative path of the specification metadata receiving the snapshot.
const specVersionOutputPath = 'docs/references/spec-version.json';

/// Repo-relative path of the generated Dart view used by the validator.
const dartOutputPath =
    'app/packages/tooling/loom_ux_judges/lib/src/validator/'
    'generated_capability_baseline.dart';

/// The date on which specVersion 4's capability baseline was snapshotted.
const capabilityBaselineSnapshotDate = '2026-08-20';

Set<String> buildCapabilityNames() {
  final appShellArchetypes = <String>{
    ...supportedAppShellBespokeCardSurfaceFamilies,
    ...supportedAppShellGenericCardSurfaceFamilies,
  };
  _requireSameSet(
    'workflow engine and App Shell archetypes',
    knownWorkflowArchetypeIds,
    appShellArchetypes,
  );
  final validatorOnlyArchetypes = validatorCardSurfaceFamiliesRequiringAction
      .difference(appShellArchetypes);
  if (validatorOnlyArchetypes.isNotEmpty) {
    throw StateError(
      'Validator archetypes are missing from the App Shell manifest: '
      '${validatorOnlyArchetypes.toList()..sort()}.',
    );
  }

  return <String>{
    for (final name in appShellArchetypes) 'archetype.$name',
    for (final name in supportedWorkflowEffectOperations) 'effect.$name',
    for (final name in supportedWorkflowGuardKinds) 'guard.$name',
    for (final name in supportedWorkflowFormulaFunctions) 'formula.$name',
    for (final name in supportedInstanceDataFieldTypes) 'field.$name',
  };
}

Map<String, Object?> buildCapabilityBaseline() {
  final capabilities = buildCapabilityNames().toList()..sort();
  return <String, Object?>{
    'specVersion': currentCommunitySpecVersion,
    'snapshotDate': capabilityBaselineSnapshotDate,
    'capabilities': capabilities,
  };
}

String renderSpecVersion(String source) {
  final encodedBaseline = const JsonEncoder.withIndent(
    '  ',
  ).convert(buildCapabilityBaseline());
  final baselineLines = encodedBaseline.split('\n');
  final property = <String>[
    '  "capabilityBaseline": ${baselineLines.first}',
    for (final line in baselineLines.skip(1)) '  $line',
  ].join('\n');

  final existing = RegExp(
    r'\n  "capabilityBaseline": \{[\s\S]*\n  \}(?=\n\}\s*$)',
  );
  if (existing.hasMatch(source)) {
    return source.replaceFirst(existing, '\n$property');
  }

  final rootClose = source.lastIndexOf('}');
  if (rootClose < 0 || source.substring(rootClose + 1).trim().isNotEmpty) {
    throw const FormatException('spec-version.json is not a JSON object.');
  }
  final beforeClose = source.substring(0, rootClose).trimRight();
  final afterClose = source.substring(rootClose + 1);
  return '$beforeClose,\n$property\n}$afterClose';
}

String renderDartBaseline() {
  final baseline = buildCapabilityBaseline();
  final capabilities = (baseline['capabilities'] as List).cast<String>();
  final output = StringBuffer()
    ..writeln('// GENERATED — do not edit by hand.')
    ..writeln(
      '// Source: workflow_capabilities.dart, app_shell_capabilities.dart,',
    )
    ..writeln('//         and validator_capabilities.dart.')
    ..writeln('// Regenerate: dart run bin/generate_capability_baseline.dart')
    ..writeln('library;')
    ..writeln()
    ..writeln(
      'const int communityCapabilityBaselineSpecVersion = '
      '${baseline['specVersion']};',
    )
    ..writeln(
      "const String communityCapabilityBaselineSnapshotDate = "
      "'${baseline['snapshotDate']}';",
    )
    ..writeln()
    ..writeln('const Set<String> communityCapabilityBaseline = <String>{');
  for (final capability in capabilities) {
    output.writeln("  '$capability',");
  }
  output
    ..writeln('};')
    ..writeln();
  return output.toString();
}

int main(List<String> args) {
  final check = args.contains('--check');
  final root = _repositoryRoot();
  if (root == null) {
    stderr.writeln(
      'Could not locate the repo root from ${Directory.current.path}.',
    );
    return 2;
  }

  final specVersionFile = File('${root.path}/$specVersionOutputPath');
  final dartFile = File('${root.path}/$dartOutputPath');
  final renderedSpec = renderSpecVersion(specVersionFile.readAsStringSync());
  final renderedDart = renderDartBaseline();

  if (check) {
    final stale = <String>[];
    if (specVersionFile.readAsStringSync() != renderedSpec) {
      stale.add(specVersionOutputPath);
    }
    if (!dartFile.existsSync() || dartFile.readAsStringSync() != renderedDart) {
      stale.add(dartOutputPath);
    }
    if (stale.isNotEmpty) {
      stderr.writeln(
        'STALE: ${stale.join(', ')} no longer matches the capability manifests.\n'
        'Regenerate with:\n'
        '  dart run bin/generate_capability_baseline.dart',
      );
      return 1;
    }
    stdout.writeln('capabilityBaseline is up to date.');
    return 0;
  }

  specVersionFile.writeAsStringSync(renderedSpec);
  dartFile.parent.createSync(recursive: true);
  dartFile.writeAsStringSync(renderedDart);
  stdout.writeln('wrote $specVersionOutputPath');
  stdout.writeln('wrote $dartOutputPath');
  return 0;
}

Directory? _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${directory.path}/$specVersionOutputPath').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return null;
}

void _requireSameSet(String label, Set<String> left, Set<String> right) {
  final onlyLeft = left.difference(right).toList()..sort();
  final onlyRight = right.difference(left).toList()..sort();
  if (onlyLeft.isEmpty && onlyRight.isEmpty) return;
  throw StateError(
    '$label disagree. Only in first: $onlyLeft; only in second: $onlyRight.',
  );
}
