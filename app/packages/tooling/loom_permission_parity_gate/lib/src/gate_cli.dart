import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'comparison.dart';
import 'export_client.dart';
import 'live_reader.dart';
import 'package_loader.dart';

/// Derives the exact request body the installer and the export both accept,
/// using the same client-side deriver `check_role_parity.sh` already uses.
///
/// The gate deliberately does not re-implement permission derivation: a second
/// implementation drifts, and the gate would then be diffing two guesses
/// against each other. What it submits is *derivation inputs* -- the same
/// `roles[]`/`workflows[]` shape `installCommunityPackage` takes -- and App
/// Access's real `CommunityPermissionDeriver` produces the expected sets.
typedef ExportRequestBuilder =
    Map<String, Object?> Function(ParsedCommunityPackage package);

/// Runs the parity gate over the shipped corpus.
///
/// Exit codes, matching the sibling gates' convention:
///   0 -- every community agrees.
///   1 -- drift, or a community that could not be compared.
///   64 -- bad invocation.
///   65 -- the corpus could not be read.
Future<int> runPermissionParityGate(
  List<String> arguments, {
  Map<String, String>? environment,
  StringSink? stdoutSink,
  StringSink? stderrSink,
  HttpPermissionExportClient? exportClient,
  LiveRoleGrantsReader? liveReader,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  final env = environment ?? Platform.environment;

  late final _GateArguments args;
  try {
    args = _GateArguments.parse(arguments);
  } on FormatException catch (error) {
    err.writeln('ERROR: ${error.message}');
    err.writeln(_usage);
    return 64;
  }
  if (args.help) {
    out.writeln(_usage);
    return 0;
  }

  final config = _configFromEnvironment(env, args);
  final client =
      exportClient ??
      HttpPermissionExportClient(
        baseUri: config.appAccessBaseUri,
        tokenUri: config.tokenUri,
        clientId: config.clientId,
        clientSecret: config.clientSecret,
        appId: config.appId,
      );
  final reader = liveReader ?? const LiveRoleGrantsReader();

  final unprocessed = <UnprocessedCommunity>[];
  final exports = <String, CommunityPermissionExport>{};

  // ── expected side: one read-only export call per shipped package ────────
  out.writeln('=== expected side: POST community-permission-exports ===');
  late final List<ParsedCommunityPackage> packages;
  try {
    packages = args.packagesFile != null
        ? [
            await const ShippedCommunityPackageLoader().loadFile(
              File(args.packagesFile!),
            ),
          ]
        : await const ShippedCommunityPackageLoader().loadDirectory(
            Directory(args.packagesDirectory),
          );
  } on Object catch (error) {
    err.writeln('ERROR: could not read the shipped packages: $error');
    return 65;
  }

  for (final package in packages) {
    final handle = package.communityHandle;
    if (!args.includeHandle(handle)) {
      out.writeln('SKIPPED (not selected): $handle');
      continue;
    }
    try {
      final body = _exportRequestBody(package);
      exports[handle] = await client.export(
        body,
        correlationId: _newUuidV4(),
      );
    } on FormatException catch (error) {
      unprocessed.add(
        UnprocessedCommunity(communityHandle: handle, reason: '${error.message}'),
      );
    } on Object catch (error) {
      // The live-infra case worth naming precisely: this endpoint is gated
      // behind `requireProvisioningPrincipal`, and the
      // `app-access-provisioner` realm role does not exist in this cluster
      // yet. An authentication failure here is an environment gap, not proof
      // the gate is broken.
      unprocessed.add(
        UnprocessedCommunity(
          communityHandle: handle,
          reason: _explainExportFailure(error),
        ),
      );
    }
  }

  out.writeln('expected sets received: ${exports.length}');
  for (final skipped in unprocessed) {
    out.writeln(
      'UNPROCESSED ${skipped.communityHandle}: ${skipped.reason}',
    );
  }

  // ── actual side: one read of live role_permission ──────────────────────
  out.writeln();
  out.writeln('=== actual side: live role_permission ===');
  late final Map<String, List<LiveRoleGrants>> live;
  try {
    live = reader.readAll();
  } on Object catch (error) {
    err.writeln('ERROR: could not read live role grants: $error');
    return 1;
  }
  final liveRoleCount = live.values.fold<int>(
    0,
    (total, rows) => total + rows.length,
  );
  out.writeln(
    'live groups read: ${live.length}; live role rows: $liveRoleCount',
  );

  // A control. If this role is missing the query is broken, not the corpus --
  // an empty diff from a broken query looks exactly like a clean bill of
  // health. Mirrors `check_role_parity.sh`'s own control row.
  const controlGroup = 'loom_communities_chess-club';
  const controlRole = 'chess-owner';
  final controlPresent = (live[controlGroup] ?? const <LiveRoleGrants>[])
      .any((row) => row.roleId == controlRole);
  if (!controlPresent) {
    err.writeln(
      'ERROR: control row `$controlGroup|$controlRole` is absent, so this '
      'read proves nothing about the rest.',
    );
    return 1;
  }
  out.writeln('control present: $controlGroup|$controlRole');

  // ── comparison ─────────────────────────────────────────────────────────
  final governance = _governanceSet(exports, packages);
  final comparer = PermissionParityComparer(
    governancePermissionIds: governance,
  );
  final result = comparer.compare(
    exportsByHandle: exports,
    liveByGroupId: live,
    unprocessed: unprocessed,
  );

  out.writeln();
  out.writeln('=== comparison (exact permission-id sets) ===');
  out.writeln('communities compared: ${result.communitiesCompared.length}');
  var status = 0;

  for (final entry in result.findings.entries) {
    out.writeln();
    out.writeln('DERIVATION FINDINGS for ${entry.key} (informational):');
    for (final finding in entry.value) {
      out.writeln('  $finding');
    }
  }

  if (result.drifts.isNotEmpty) {
    status = 1;
    out.writeln();
    out.writeln('DRIFT -- the live grants disagree with the derivation:');
    for (final drift in result.drifts) {
      out.writeln('  ${drift.sentence}');
    }
  }

  if (result.unprocessed.isNotEmpty) {
    status = 1;
    out.writeln();
    out.writeln('UNPROCESSED -- these communities were not compared at all:');
    for (final community in result.unprocessed) {
      out.writeln('  ${community.communityHandle}: ${community.reason}');
    }
    out.writeln(
      '  A community that could not be read is not a community that agreed.',
    );
  }

  // An empty comparison must never read as agreement. Running with zero
  // communities compared -- a filter that matched nothing, a corpus that
  // loaded nothing -- produces no drifts for exactly the same reason a clean
  // corpus does, and reporting "OK" over nothing is the guard-that-can-never-
  // fail shape this project has shipped three times.
  if (result.communitiesCompared.isEmpty) {
    status = 1;
    out.writeln();
    out.writeln(
      'NO COMMUNITIES COMPARED -- zero exports were received, so nothing was '
      'checked. This is not a clean result.',
    );
  } else if (status == 0) {
    out.writeln();
    out.writeln(
      'OK: every compared community\'s live grants equal its derived sets, '
      'by id.',
    );
  }
  if (exportClient == null) client.close(force: true);
  return status;
}

/// The derivation inputs for one package, in the shape both
/// `installCommunityPackage` and `community-permission-exports` accept.
Map<String, Object?> _exportRequestBody(ParsedCommunityPackage package) {
  final resolved = const ArchetypeResolver().resolveAll(
    package.rawWorkflowDefinitions,
  );
  final workflows = <Map<String, Object?>>[];
  for (final entry in package.rawWorkflowDefinitions.entries) {
    final workflowType = entry.key;
    final raw = entry.value;
    if (raw is! Map) continue;
    final family = resolved[workflowType]?.family;
    if (family == null) continue;
    final definition = package.workflowDefinitions[workflowType]!;
    final rawTransitions = raw['transitions'];
    if (rawTransitions is! List) continue;

    final transitions = <Map<String, Object?>>[];
    for (var index = 0; index < definition.transitions.length; index++) {
      final parsed = definition.transitions[index];
      final rawTransition = Map<String, Object?>.from(
        rawTransitions[index] as Map,
      );
      final target = parsed.to;
      transitions.add(<String, Object?>{
        'transitionId': parsed.id,
        if (rawTransition['action'] case final String action) 'action': action,
        'tone': parsed.tone,
        'isTerminal':
            target != null && (definition.states[target]?.isTerminal ?? false),
        'allowedRoleIds': List<String>.from(
          parsed.guard.allowedRoleIds ?? const <String>[],
        ),
      });
    }

    final createRoleIds = <String>{};
    for (final binding in definition.renderBindings) {
      for (final action in binding.actions) {
        if (action.kind != 'create') continue;
        createRoleIds.addAll(action.byRoleIds ?? const <String>[]);
      }
    }

    workflows.add(<String, Object?>{
      'workflowType': workflowType,
      'cardSurfaceFamily': family,
      'createRoleIds': createRoleIds.toList()..sort(),
      'transitions': transitions,
    });
  }

  return <String, Object?>{
    'communityHandle': package.communityHandle,
    'displayName': package.displayName,
    'grammarVersion': package.specVersion,
    'roles': [
      for (final role in package.roles)
        <String, Object?>{'roleId': role.roleId, 'label': role.roleLabel},
    ],
    'workflows': workflows,
  };
}

/// The vocabulary's governance set, read from any export that carried a
/// `systemAdminRole`. Falls back to the resolver's own action list, which is
/// the same generated vocabulary both sides consume.
Set<String> _governanceSet(
  Map<String, CommunityPermissionExport> exports,
  List<ParsedCommunityPackage> packages,
) {
  for (final export in exports.values) {
    final admin = export.systemAdminRole;
    if (admin != null && admin.permissionIds.isNotEmpty) {
      return admin.permissionIdSet;
    }
  }
  return {
    for (final action in ArchetypeResolver.governanceActionIds)
      '${ArchetypeResolver.governancePermissionPrefix}.$action',
  };
}

String _explainExportFailure(Object error) {
  final text = '$error';
  if (text.contains('401') || text.contains('403')) {
    return 'the export endpoint rejected the caller ($text). This cluster has '
        'no `app-access-provisioner` realm role yet (P1 introduced the '
        'requirement; nothing has created it), so this is the known pending '
        'Keycloak gap rather than a defect in the gate.';
  }
  return text;
}

class _GateConfig {
  const _GateConfig({
    required this.appAccessBaseUri,
    required this.tokenUri,
    required this.clientId,
    required this.clientSecret,
    required this.appId,
  });

  final Uri appAccessBaseUri;
  final Uri tokenUri;
  final String clientId;
  final String clientSecret;
  final String appId;
}

_GateConfig _configFromEnvironment(
  Map<String, String> environment,
  _GateArguments args,
) {
  String required(String name) {
    final value = environment[name];
    if (value == null || value.trim().isEmpty) {
      throw FormatException('$name is required.');
    }
    return value.trim();
  }

  Uri requiredUri(String name) {
    final uri = Uri.tryParse(required(name));
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('$name must be an absolute URL.');
    }
    return uri;
  }

  return _GateConfig(
    appAccessBaseUri: requiredUri('LOOM_APP_ACCESS_BASE_URL'),
    tokenUri: requiredUri('LOOM_KEYCLOAK_TOKEN_URL'),
    clientId: required('LOOM_APP_ACCESS_CLIENT_ID'),
    clientSecret: required('LOOM_APP_ACCESS_CLIENT_SECRET'),
    appId: environment['LOOM_APP_ID']?.trim().isNotEmpty == true
        ? environment['LOOM_APP_ID']!.trim()
        : 'loom_communities',
  );
}

class _GateArguments {
  const _GateArguments({
    required this.packagesDirectory,
    required this.packagesFile,
    required this.help,
    required this.handles,
  });

  final String packagesDirectory;

  /// When set, the gate compares exactly this one package instead of the
  /// whole directory. Used by the negative test against a disposable probe.
  final String? packagesFile;
  final bool help;
  final List<String> handles;

  bool includeHandle(String handle) =>
      handles.isEmpty || handles.contains(handle);

  static _GateArguments parse(List<String> arguments) {
    var help = false;
    String? directory;
    String? packagesFile;
    final handles = <String>[];
    for (final argument in arguments) {
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (argument.startsWith('--community=')) {
        handles.add(argument.substring('--community='.length));
        continue;
      }
      if (argument.startsWith('--packages-file=')) {
        packagesFile = argument.substring('--packages-file='.length);
        continue;
      }
      if (argument.startsWith('--')) {
        throw FormatException('Unknown option $argument.');
      }
      if (directory != null) {
        throw const FormatException('Pass exactly one packages directory.');
      }
      directory = argument;
    }
    if (!help && directory == null && packagesFile == null) {
      throw const FormatException(
        'A packages directory (or --packages-file) is required.',
      );
    }
    return _GateArguments(
      packagesDirectory: directory ?? '',
      packagesFile: packagesFile,
      help: help,
      handles: List.unmodifiable(handles),
    );
  }
}

String _newUuidV4() {
  final bytes = List<int>.generate(16, (_) => DateTime.now().microsecond % 256);
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

const _usage = '''
Usage:
  dart run bin/check_permission_parity.dart <packages-dir> \\
    [--community=<handle> ...]
  dart run bin/check_permission_parity.dart --packages-file=<path.jsonc>

`--packages-file` compares exactly one package instead of the shipped
directory. It exists for the negative test against a disposable probe, so the
probe never enters the shipped assets directory.

Compares every shipped community package's derived permission sets against
the live App Access grants, by exact permission id.

  expected side  POST /v1/apps/{appId}/community-permission-exports
  actual side    select ... from app_role join role_permission

Environment:
  LOOM_APP_ACCESS_BASE_URL      absolute URL of the App Access service
  LOOM_KEYCLOAK_TOKEN_URL       absolute URL of the Keycloak token endpoint
  LOOM_APP_ACCESS_CLIENT_ID     client-credentials client id
  LOOM_APP_ACCESS_CLIENT_SECRET matching client secret
  LOOM_APP_ID                   optional; defaults to loom_communities

Exit codes: 0 clean, 1 drift or an uncompared community, 64 bad invocation,
65 an unreadable corpus.

The gate DETECTS drift; it does not prevent it. Nothing stops a deployment
because of this gate unless the deployment depends on it passing.
''';
