/// Emits the machine-readable permissions vocabulary consumed by both the
/// community-package validator (Dart) and the App Access installer (Java).
///
/// Derivation runs in the App Access service, but its rules are defined once,
/// here, in `ArchetypeResolver`. Without a shared artifact the Java side would
/// re-implement the archetype classification and all ~70 vocabulary entries by
/// hand — and this repo has already been broken twice by the same rules living
/// in two places and drifting apart. A derivation that disagreed with the
/// validator would grant permissions for a package the validator had passed.
///
/// Only the *data* is shared. The resolution algorithm is small and is
/// implemented on each side; a conformance test over the real fixtures is what
/// keeps those two implementations honest.
///
///   dart run bin/generate_permissions_vocabulary.dart          # write
///   dart run bin/generate_permissions_vocabulary.dart --check  # verify only
///
/// `--check` is what CI and the sync test use: it exits non-zero if the checked-in
/// artifact has drifted from the resolver.
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:loom_workflow_engine/src/spec_version.dart';

/// Repo-relative output path.
const outputPath = 'docs/references/generated/permissions-vocabulary.json';

Map<String, Object?> buildVocabulary() {
  final bespoke = <String, Object?>{};
  for (final family
      in (ArchetypeResolver.bespokeVocabularies.keys.toList()..sort())) {
    final actions = ArchetypeResolver.bespokeVocabularies[family]!.toList()
      ..sort();
    bespoke[family] = {
      'permissionPrefix': ArchetypeResolver.permissionPrefixes[family],
      'actions': actions,
      'permissions': [
        for (final action in actions)
          '${ArchetypeResolver.permissionPrefixes[family]}.$action',
      ],
    };
  }

  final generic = <String, Object?>{};
  final genericActions = ArchetypeResolver.genericActions.toList()..sort();
  for (final family in (ArchetypeResolver.genericFamilies.toList()..sort())) {
    generic[family] = {
      'permissionPrefix': ArchetypeResolver.permissionPrefixes[family],
      'actions': genericActions,
      'permissions': [
        for (final action in genericActions)
          '${ArchetypeResolver.permissionPrefixes[family]}.$action',
      ],
    };
  }

  // The full per-archetype contract: what the archetype guarantees, as opposed
  // to what a community declares. The validator reads it today; the workflow
  // service reads it once it exists.
  const visibilityNames = {
    VisibilityModel.roles: 'roles',
    VisibilityModel.owner: 'owner',
    VisibilityModel.ownerAndShared: 'owner_and_shared',
    VisibilityModel.participants: 'participants',
    VisibilityModel.parties: 'parties',
    VisibilityModel.recipient: 'recipient',
  };
  const enforcementNames = {
    EnforcementBoundary.clientEngine: 'client_engine',
    EnforcementBoundary.server: 'server',
  };

  final contracts = <String, Object?>{};
  for (final family in (ArchetypeResolver.contracts.keys.toList()..sort())) {
    final contract = ArchetypeResolver.contracts[family]!;
    contracts[family] = {
      'isBespoke': contract.isBespoke,
      'visibility': visibilityNames[contract.visibility],
      'enforcement': enforcementNames[contract.enforcement],
      'allowsCustomActions': contract.allowsCustomActions,
      'bookkeeping': contract.bookkeeping.toList()..sort(),
      if (contract.placement.isNotEmpty)
        'placement': contract.placement.toList()..sort(),
      if (contract.sharingGrantable.isNotEmpty)
        'sharingGrantable': contract.sharingGrantable.toList()..sort(),
    };
  }

  return {
    '_comment': [
      'GENERATED — do not edit by hand.',
      'Source: app/packages/core/loom_workflow_engine/lib/src/archetypes/archetype_resolver.dart',
      'Regenerate: dart run bin/generate_permissions_vocabulary.dart',
      '',
      'Consumed by the community-package validator (Dart) and the App Access',
      'installer (Java), so that the derivation rules defined in',
      'docs/references/reference/permissions.md exist in exactly one place.',
    ],
    'specVersion': currentCommunitySpecVersion,
    'archetypeContracts': {
      '_comment':
          'What each archetype guarantees. `bookkeeping` is per-person state the '
          'archetype maintains itself -- a community declares none of these '
          'fields and writes no idempotence guard against them. '
          '`enforcement: client_engine` means the rule is evaluated on the '
          'device by LocalWorkflowEngineApi and is advisory, not a security '
          'boundary: there is no workflow service yet.',
      ...contracts,
    },
    'bespokeArchetypes': bespoke,
    'genericArchetypes': generic,
    'genericDerivation': {
      '_comment':
          'permissions.md §5. Generic families declare no action; it is derived '
          'from structure the transition already carries.',
      'rules': [
        {'when': 'a create action on a renderBinding', 'action': 'create'},
        {
          'when': 'tone == "destructive", or the target state isTerminal',
          'action': 'terminate',
        },
        {'when': 'any other state-changing transition', 'action': 'advance'},
        {'when': 'a read-only binding with no transition', 'action': 'view'},
      ],
    },
  };
}

int main(List<String> args) {
  final check = args.contains('--check');

  // Walk up to the repo root so this works from the package dir or the root.
  var dir = Directory.current;
  Directory? root;
  for (var i = 0; i < 8; i++) {
    if (Directory('${dir.path}/docs/references').existsSync()) {
      root = dir;
      break;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  if (root == null) {
    stderr.writeln(
      'Could not locate the repo root from ${Directory.current.path}.',
    );
    return 2;
  }

  const encoder = JsonEncoder.withIndent('  ');
  final rendered = '${encoder.convert(buildVocabulary())}\n';
  final file = File('${root.path}/$outputPath');

  if (check) {
    if (!file.existsSync()) {
      stderr.writeln('MISSING: $outputPath has never been generated.');
      return 1;
    }
    if (file.readAsStringSync() != rendered) {
      stderr.writeln(
        'STALE: $outputPath no longer matches ArchetypeResolver.\n'
        'Regenerate it with:\n'
        '  dart run bin/generate_permissions_vocabulary.dart',
      );
      return 1;
    }
    stdout.writeln('permissions-vocabulary.json is up to date.');
    return 0;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(rendered);
  stdout.writeln('wrote $outputPath');
  return 0;
}
