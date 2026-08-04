import 'dart:io';

import 'package:loom_ux_judges/src/validator/validator_http_server.dart';

Future<void> main(List<String> args) async {
  final port =
      _intArg(args, '--port') ??
      int.tryParse(Platform.environment['PORT'] ?? '') ??
      8787;

  await startValidatorServer(port: port);
  stdout.writeln('Loom community package validator listening on port $port');
  stdout.writeln('  GET  /health');
  stdout.writeln('  POST /validate   (body: community package JSON or JSONC)');
}

int? _intArg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i < 0 || i + 1 >= args.length) return null;
  return int.tryParse(args[i + 1]);
}
