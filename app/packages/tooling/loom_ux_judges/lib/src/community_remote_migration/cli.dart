import 'dart:convert';
import 'dart:io';

import 'derivation.dart';
import 'live_executor.dart';
import 'package_parser.dart';

typedef LiveMigrationExecutorFactory =
    LiveMigrationExecutor Function(MigrationExecutionConfig config);

Future<int> runCommunityRemoteMigration(
  List<String> arguments, {
  Map<String, String>? environment,
  StringSink? stdoutSink,
  StringSink? stderrSink,
  LiveMigrationExecutorFactory? liveExecutorFactory,
}) async {
  final out = stdoutSink ?? stdout;
  final err = stderrSink ?? stderr;
  final env = environment ?? Platform.environment;
  late final _CliArguments args;
  try {
    args = _CliArguments.parse(arguments);
  } on FormatException catch (error) {
    err.writeln('ERROR: ${error.message}');
    err.writeln(_usage);
    return 64;
  }
  if (args.help) {
    out.writeln(_usage);
    return 0;
  }

  try {
    final package = await ParsedCommunityPackage.fromFile(File(args.filePath));
    final plan = const CommunityMigrationDeriver().derive(package);
    _printJsonSection(
      out,
      'installCommunityPackage payload',
      plan.installCommunityPackagePayload,
    );
    _printJsonSection(
      out,
      'replaceWorkflowDefinitions payload',
      plan.replaceWorkflowDefinitionsPayload,
    );
    _printJsonSection(
      out,
      'findings report',
      plan.findingsReport(networkCallsMade: 0),
    );

    // This early return is the dry-run safety boundary. Neither execution
    // configuration nor a network-capable executor is constructed above it.
    if (!args.execute) return 0;

    if (plan.findings.isNotEmpty) {
      err.writeln(
        'ERROR: --execute refused because ${plan.findings.length} '
        'persona-to-role finding(s) require a human decision.',
      );
      return 2;
    }

    final config = _executionConfig(args, env);
    final executor = (liveExecutorFactory ?? _defaultExecutorFactory)(config);
    try {
      final result = await executor.execute(package, plan);
      _printJsonSection(
        out,
        'installCommunityPackage response',
        result.installCommunityPackageResponse,
      );
      _printJsonSection(
        out,
        'replaceWorkflowDefinitions response',
        result.replaceWorkflowDefinitionsResponse,
      );
    } finally {
      if (executor is HttpLiveMigrationExecutor) executor.close();
    }
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

LiveMigrationExecutor _defaultExecutorFactory(
  MigrationExecutionConfig config,
) => HttpLiveMigrationExecutor(config: config);

MigrationExecutionConfig _executionConfig(
  _CliArguments args,
  Map<String, String> environment,
) {
  String requiredValue(String option, String environmentName) {
    final value = args.options[option] ?? environment[environmentName];
    if (value == null || value.trim().isEmpty) {
      throw FormatException(
        '--execute requires --$option or $environmentName.',
      );
    }
    return value.trim();
  }

  Uri requiredUri(String option, String environmentName) {
    final raw = requiredValue(option, environmentName);
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw FormatException('--$option must be an absolute URL.');
    }
    return uri;
  }

  return MigrationExecutionConfig(
    appAccessBaseUri: requiredUri(
      'app-access-base-url',
      'LOOM_APP_ACCESS_BASE_URL',
    ),
    workflowServiceBaseUri: requiredUri(
      'workflow-service-base-url',
      'LOOM_WORKFLOW_SERVICE_BASE_URL',
    ),
    tokenUri: requiredUri('token-url', 'LOOM_KEYCLOAK_TOKEN_URL'),
    clientId: requiredValue('client-id', 'LOOM_APP_ACCESS_CLIENT_ID'),
    clientSecret: requiredValue(
      'client-secret',
      'LOOM_APP_ACCESS_CLIENT_SECRET',
    ),
    workflowBearerToken: requiredValue(
      'workflow-bearer-token',
      'LOOM_WORKFLOW_BEARER_TOKEN',
    ),
    appId: requiredValue('app-id', 'LOOM_APP_ID'),
  );
}

void _printJsonSection(StringSink sink, String title, Object? value) {
  sink.writeln('=== $title ===');
  sink.writeln(const JsonEncoder.withIndent('  ').convert(value));
}

class _CliArguments {
  const _CliArguments({
    required this.filePath,
    required this.execute,
    required this.help,
    required this.options,
  });

  final String filePath;
  final bool execute;
  final bool help;
  final Map<String, String> options;

  static const _valueOptions = {
    'app-access-base-url',
    'workflow-service-base-url',
    'token-url',
    'client-id',
    'client-secret',
    'workflow-bearer-token',
    'app-id',
  };

  static _CliArguments parse(List<String> arguments) {
    var execute = false;
    var help = false;
    String? filePath;
    final options = <String, String>{};

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--execute') {
        execute = true;
        continue;
      }
      if (argument == '--help' || argument == '-h') {
        help = true;
        continue;
      }
      if (argument.startsWith('--')) {
        final equals = argument.indexOf('=');
        final name = argument.substring(2, equals == -1 ? null : equals);
        if (!_valueOptions.contains(name)) {
          throw FormatException('Unknown option --$name.');
        }
        final value = equals == -1
            ? (index + 1 < arguments.length ? arguments[++index] : null)
            : argument.substring(equals + 1);
        if (value == null || value.isEmpty || value.startsWith('--')) {
          throw FormatException('--$name requires a value.');
        }
        options[name] = value;
        continue;
      }
      if (filePath != null) {
        throw const FormatException('Pass exactly one community JSON file.');
      }
      filePath = argument;
    }

    if (!help && filePath == null) {
      throw const FormatException('A community JSON file is required.');
    }
    return _CliArguments(
      filePath: filePath ?? '',
      execute: execute,
      help: help,
      options: Map.unmodifiable(options),
    );
  }
}

const _usage = '''
Usage:
  dart run bin/community_remote_migration.dart <community.jsonc>
  dart run bin/community_remote_migration.dart <community.jsonc> --execute \\
    --app-access-base-url <url> --workflow-service-base-url <url> \\
    --token-url <url> --client-id <id> --client-secret <secret> \\
    --workflow-bearer-token <fan-jwt> --app-id <id>

Without --execute, the tool is always a dry run and makes zero network calls.

Execute-mode values may instead come from LOOM_APP_ACCESS_BASE_URL,
LOOM_WORKFLOW_SERVICE_BASE_URL, LOOM_KEYCLOAK_TOKEN_URL,
LOOM_APP_ACCESS_CLIENT_ID, LOOM_APP_ACCESS_CLIENT_SECRET,
LOOM_WORKFLOW_BEARER_TOKEN, and LOOM_APP_ID. The workflow token must contain
the fanId claim required by workflow-service's existing JWT identity extractor.
Execution is refused while any persona-to-role finding remains unresolved.
''';
