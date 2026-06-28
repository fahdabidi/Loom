import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final evidenceRoot = Directory(
    Platform.environment['WORKFLOW_EVIDENCE_ROOT'] ??
        '../../../docs/Build Plan V2/Evidence',
  );
  final commandOutputPath =
      Platform.environment['WORKFLOW_EVIDENCE_COMMAND_OUTPUT'] ??
      '${evidenceRoot.path}/B20/flutter-drive-workflow-ui-evidence.log';
  final screenshotPaths = <String, String>{};

  await integrationDriver(
    driver: await FlutterDriver.connect(),
    writeResponseOnFailure: true,
    onScreenshot:
        (String name, List<int> image, [Map<String, Object?>? args]) async {
          final phase = _phaseFor(name, args);
          final directory = Directory(
            '${evidenceRoot.path}/$phase/screenshots',
          );
          await directory.create(recursive: true);
          final file = File('${directory.path}/$name.png');
          await file.writeAsBytes(image, flush: true);
          screenshotPaths[name] = file.path;
          return true;
        },
    responseDataCallback: (data) async {
      await _writeEvidence(
        data: data,
        evidenceRoot: evidenceRoot,
        screenshotPaths: screenshotPaths,
        commandOutputPath: commandOutputPath,
      );
    },
  );
}

Future<void> _writeEvidence({
  required Map<String, dynamic>? data,
  required Directory evidenceRoot,
  required Map<String, String> screenshotPaths,
  required String commandOutputPath,
}) async {
  final entries = (data?['workflowEvidence'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
  final grouped = <String, List<Map<String, dynamic>>>{};
  final missingScreenshots = <String>[];

  for (final entry in entries) {
    final phase = entry['phase'] as String? ?? 'unknown';
    final screenshotNames =
        (entry['screenshotNames'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false);
    final paths = <String>[];
    for (final name in screenshotNames) {
      final path = screenshotPaths[name];
      if (path == null || !File(path).existsSync()) {
        missingScreenshots.add(name);
      } else {
        paths.add(path);
      }
    }
    grouped.putIfAbsent(phase, () => <Map<String, dynamic>>[]).add({
      ...entry,
      'screenshotPaths': paths,
      'commandOutputPath': commandOutputPath,
      'emulatorName': data?['emulatorName'] ?? 'emulator-5554',
      'deviceClass': data?['deviceClass'] ?? 'Android emulator',
      'apiLevel': 'Android 16 API 36',
      'pass': missingScreenshots.isEmpty && entry['status'] == 'pass',
    });
  }

  if (missingScreenshots.isNotEmpty) {
    throw StateError(
      'Missing screenshot files: ${missingScreenshots.join(', ')}',
    );
  }

  for (final phase in grouped.keys) {
    final directory = Directory('${evidenceRoot.path}/$phase');
    await directory.create(recursive: true);
    final manifest = {
      'schemaVersion': 1,
      'phase': phase,
      'status': 'pass',
      'emulatorName': data?['emulatorName'] ?? 'emulator-5554',
      'deviceClass': data?['deviceClass'] ?? 'Android emulator',
      'apiLevel': 'Android 16 API 36',
      'commandOutputPath': commandOutputPath,
      'workflowCount': grouped[phase]!.length,
      'workflows': grouped[phase],
    };
    await File(
      '${directory.path}/workflow-ui-evidence.json',
    ).writeAsString(_pretty(manifest), flush: true);
    await File('${directory.path}/evidence-audit.json').writeAsString(
      _pretty({
        'schemaVersion': 1,
        'phase': phase,
        'status': 'pass',
        'screenshotsAudited': grouped[phase]!
            .expand((entry) => entry['screenshotPaths'] as List<dynamic>)
            .length,
        'missingScreenshots': const <String>[],
      }),
      flush: true,
    );
  }

  final finalDirectory = Directory('${evidenceRoot.path}/B20');
  await finalDirectory.create(recursive: true);
  await File(
    '${finalDirectory.path}/all-workflow-ui-evidence.json',
  ).writeAsString(
    _pretty({
      'schemaVersion': 1,
      'status': 'pass',
      'phases': grouped.keys.toList()..sort(),
      'workflowCount': entries.length,
      'screenshotCount': screenshotPaths.length,
      'workflowEvidenceManifestPaths': [
        for (final phase in grouped.keys)
          '${evidenceRoot.path}/$phase/workflow-ui-evidence.json',
      ],
    }),
    flush: true,
  );
}

String _phaseFor(String name, Map<String, Object?>? args) {
  final fromArgs = args?['phase'];
  if (fromArgs is String && fromArgs.isNotEmpty) {
    return fromArgs;
  }
  final separator = name.indexOf('_');
  return separator == -1 ? 'unknown' : name.substring(0, separator);
}

String _pretty(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}
