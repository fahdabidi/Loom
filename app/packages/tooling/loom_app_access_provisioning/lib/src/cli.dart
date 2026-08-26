import 'dart:convert';
import 'dart:io';

import 'applier.dart';
import 'deriver.dart';
import 'package_loader.dart';
import 'plan.dart';

typedef HttpProvisioningApplierFactory =
    HttpAppAccessProvisioningApplier Function(
      AppAccessProvisioningConfig config,
    );

/// Entrypoint for `derive_app_access_provisioning_plan.dart`.
Future<int> runDeriveAppAccessProvisioningPlan(
  List<String> arguments, {
  StringSink? stdoutSink,
  StringSink? stderrSink,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  try {
    final inputDir = _parseDeriveArguments(arguments);
    final packages = await const ShippedCommunityPackageLoader().loadDirectory(
      Directory(inputDir),
    );
    final plan = const AppAccessProvisioningDeriver().deriveAll(packages);
    out.writeln(plan.encode());
    return 0;
  } on FormatException catch (error) {
    err.writeln('ERROR: ${error.message}');
    return 65;
  } on ArgumentError catch (error) {
    err.writeln('ERROR: ${error.message}');
    return 64;
  } catch (error) {
    err.writeln('ERROR: $error');
    return 1;
  }
}

/// Entrypoint for `apply_app_access_provisioning.dart`.
///
/// This is dry-run-only unless `--apply` is explicit. The dry run does not
/// even construct an HTTP client, so it cannot reach a live cluster.
Future<int> runApplyAppAccessProvisioning(
  List<String> arguments, {
  Map<String, String>? environment,
  StringSink? stdoutSink,
  StringSink? stderrSink,
  HttpProvisioningApplierFactory? applierFactory,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  try {
    final args = _ApplyArguments.parse(arguments);
    final plan = AppAccessProvisioningPlan.fromJsonString(
      await File(args.planPath).readAsString(),
    );
    if (!args.apply) {
      _printDryRun(out, plan);
      return 0;
    }
    final config = _configFromEnvironment(environment ?? Platform.environment);
    final applier = (applierFactory ?? _defaultApplierFactory)(config);
    try {
      final result = await applier.apply(plan);
      _printRolesWithNoPermissions(out, result);
      out.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
      if (result.hasFailures) {
        _printInstallationFindings(err, result);
        return 1;
      }
    } finally {
      applier.close();
    }
    return 0;
  } on FormatException catch (error) {
    err.writeln('ERROR: ${error.message}');
    return 65;
  } on ArgumentError catch (error) {
    err.writeln('ERROR: ${error.message}');
    return 64;
  } catch (error) {
    // Neither request payloads nor configuration values (especially secrets)
    // are rendered here.
    err.writeln('ERROR: $error');
    return 1;
  }
}

HttpAppAccessProvisioningApplier _defaultApplierFactory(
  AppAccessProvisioningConfig config,
) => HttpAppAccessProvisioningApplier(config: config);

String _parseDeriveArguments(List<String> arguments) {
  if (arguments.length == 1 && !arguments.single.startsWith('--')) {
    return arguments.single;
  }
  throw const FormatException(
    'Usage: dart run bin/derive_app_access_provisioning_plan.dart '
    '<communities-directory>',
  );
}

AppAccessProvisioningConfig _configFromEnvironment(
  Map<String, String> environment,
) {
  String requiredValue(String name) {
    final value = environment[name];
    if (value == null || value.trim().isEmpty) {
      throw FormatException('--apply requires environment variable $name.');
    }
    return value.trim();
  }

  Uri requiredUri(String name) {
    final value = Uri.tryParse(requiredValue(name));
    if (value == null || !value.hasScheme || value.host.isEmpty) {
      throw FormatException('$name must be an absolute URL.');
    }
    return value;
  }

  return AppAccessProvisioningConfig(
    appAccessBaseUri: requiredUri('LOOM_APP_ACCESS_BASE_URL'),
    tokenUri: requiredUri('LOOM_KEYCLOAK_TOKEN_URL'),
    clientId: requiredValue('LOOM_APP_ACCESS_CLIENT_ID'),
    clientSecret: requiredValue('LOOM_APP_ACCESS_CLIENT_SECRET'),
    appId: requiredValue('LOOM_APP_ID'),
  );
}

void _printDryRun(StringSink out, AppAccessProvisioningPlan plan) {
  out.writeln('Dry run: 0 network calls made.');
  out.writeln(
    '--apply will POST the following App Access community-installation '
    'requests. No groups, roles, permissions, or catalog entries are written '
    'by this client.',
  );
  for (final community in plan.communities) {
    if (community.omittedWorkflowTypes.isNotEmpty) {
      out.writeln(
        'OMITS workflows with no resolved cardSurfaceFamily for '
        '${community.communityId}: '
        '${community.omittedWorkflowTypes.join(', ')}',
      );
    }
    out.writeln('WOULD POST installation for ${community.communityId}:');
    out.writeln(
      const JsonEncoder.withIndent('  ').convert(community.request.toJson()),
    );
  }
}

void _printRolesWithNoPermissions(
  StringSink out,
  AppAccessProvisioningResult result,
) {
  for (final installation in result.installations) {
    if (installation.rolesWithNoPermissions.isEmpty) continue;
    out.writeln(
      'WARNING: ${installation.communityId} rolesWithNoPermissions: '
      '${installation.rolesWithNoPermissions.join(', ')}',
    );
  }
}

void _printInstallationFindings(
  StringSink err,
  AppAccessProvisioningResult result,
) {
  for (final failure in result.failures) {
    err.writeln(
      'ERROR: App Access rejected installation for ${failure.communityId}:',
    );
    for (final finding in failure.findings) {
      // Do not summarize, translate, or discard a server derivation finding.
      err.writeln(jsonEncode(finding));
    }
  }
}

class _ApplyArguments {
  const _ApplyArguments({required this.planPath, required this.apply});

  final String planPath;
  final bool apply;

  static _ApplyArguments parse(List<String> arguments) {
    var apply = false;
    String? planPath;
    for (final argument in arguments) {
      switch (argument) {
        case '--apply':
          apply = true;
        case '--dry-run':
        // Dry-run is the default and is accepted only to make automation
        // intent obvious. It never counteracts an explicit --apply.
        default:
          if (argument.startsWith('--')) {
            throw FormatException('Unknown option $argument.');
          }
          if (planPath != null) {
            throw const FormatException('Pass exactly one plan JSON file.');
          }
          planPath = argument;
      }
    }
    if (planPath == null) {
      throw const FormatException(
        'Usage: dart run bin/apply_app_access_provisioning.dart '
        '<plan.json> [--apply]',
      );
    }
    return _ApplyArguments(planPath: planPath, apply: apply);
  }
}
