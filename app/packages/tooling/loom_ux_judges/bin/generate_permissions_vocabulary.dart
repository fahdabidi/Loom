/// Emits the machine-readable permissions vocabulary consumed by both the
/// community-package validator (Dart) and the App Access installer (Java).
///
/// Derivation runs in the App Access service, but the archetype rules are
/// defined once here in `ArchetypeResolver`; the per-community governance
/// family below is intentionally not archetype-derived. Without a shared
/// artifact the Java side would re-implement the archetype classification and
/// all vocabulary entries by hand — and this repo has already been broken
/// twice by the same rules living in two places and drifting apart. A
/// derivation that disagreed with the validator would grant permissions for a
/// package the validator had passed.
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

import 'package:crypto/crypto.dart';
import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:loom_workflow_engine/src/spec_version.dart';

/// Repo-relative output path.
const outputPath = 'docs/references/generated/permissions-vocabulary.json';

Map<String, Object?> buildVocabulary({
  Map<String, Set<ArchetypeAction>>? bespokeActionRecords,
  Set<ArchetypeAction>? genericActionRecords,
  Set<ArchetypeAction>? governanceActionRecords,
}) {
  final bespokeRecords =
      bespokeActionRecords ?? ArchetypeResolver.bespokeActionRecords;
  final genericRecords =
      genericActionRecords ?? ArchetypeResolver.genericActionRecords;
  final governanceRecords =
      governanceActionRecords ?? ArchetypeResolver.governanceActions;
  const governancePermissionPrefix =
      ArchetypeResolver.governancePermissionPrefix;
  final governanceActions = governanceRecords.toList();
  final governancePermissions = [
    for (final action in governanceActions)
      '$governancePermissionPrefix.${action.id}',
  ];
  final allCatalogEntries = <Map<String, String>>[];

  final bespoke = <String, Object?>{};
  for (final family in (bespokeRecords.keys.toList()..sort())) {
    final actions = _sortedActions(bespokeRecords[family]!);
    final prefix = ArchetypeResolver.permissionPrefixes[family]!;
    final catalog = _catalogEntries(
      permissionPrefix: prefix,
      category: family,
      actions: actions,
    );
    allCatalogEntries.addAll(catalog);
    bespoke[family] = {
      'permissionPrefix': prefix,
      'actions': [for (final action in actions) action.id],
      'permissions': [for (final action in actions) '$prefix.${action.id}'],
      'catalog': catalog,
    };
  }

  final generic = <String, Object?>{};
  final genericActions = _sortedActions(genericRecords);
  for (final family in (ArchetypeResolver.genericFamilies.toList()..sort())) {
    final prefix = ArchetypeResolver.permissionPrefixes[family]!;
    final catalog = _catalogEntries(
      permissionPrefix: prefix,
      category: family,
      actions: genericActions,
    );
    allCatalogEntries.addAll(catalog);
    generic[family] = {
      'permissionPrefix': prefix,
      'actions': [for (final action in genericActions) action.id],
      'permissions': [
        for (final action in genericActions) '$prefix.${action.id}',
      ],
      'catalog': catalog,
    };
  }

  final governanceCatalog = _catalogEntries(
    permissionPrefix: governancePermissionPrefix,
    category: 'governance',
    actions: governanceActions,
  );
  allCatalogEntries.addAll(governanceCatalog);

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
      'Source: ArchetypeResolver.',
      'Regenerate: dart run bin/generate_permissions_vocabulary.dart',
      '',
      'Consumed by the community-package validator (Dart) and the App Access',
      'installer (Java), so that the derivation rules defined in',
      'docs/references/reference/permissions.md exist in exactly one place.',
    ],
    'specVersion': currentCommunitySpecVersion,
    'catalogVersion': _catalogVersion(allCatalogEntries),
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
    'governance': {
      'permissionPrefix': governancePermissionPrefix,
      'actions': [for (final action in governanceActions) action.id],
      'permissions': governancePermissions,
      'catalog': governanceCatalog,
      'adminRole': {
        'isSystemDefault': true,
        'idTemplate': '<communityHandle>-admin',
        'grantedPermissions': governancePermissions,
      },
    },
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

List<ArchetypeAction> _sortedActions(Iterable<ArchetypeAction> actions) =>
    actions.toList()..sort((left, right) => left.id.compareTo(right.id));

List<Map<String, String>> _catalogEntries({
  required String permissionPrefix,
  required String category,
  required Iterable<ArchetypeAction> actions,
}) => [
  for (final action in actions)
    {
      'permissionId': '$permissionPrefix.${action.id}',
      'displayName': action.displayName,
      'description': action.description,
      'category': category,
    },
];

String _catalogVersion(Iterable<Map<String, String>> catalogEntries) {
  final canonicalEntries = [
    for (final entry in catalogEntries)
      [
        entry['permissionId']!,
        entry['displayName']!,
        entry['description']!,
        entry['category']!,
      ].join('\u0000'),
  ]..sort();
  final digest = sha256.convert(utf8.encode(canonicalEntries.join('\n')));
  return '$currentCommunitySpecVersion-$digest';
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
