import 'dart:convert';
import 'dart:io';

const _defaultLogPath = '/tmp/loom_validator_rounds.jsonl';

class DispatchRoundSummary {
  const DispatchRoundSummary({
    required this.dispatch,
    required this.rounds,
    required this.round1FindingTypes,
    required this.endedClean,
  });

  final String dispatch;
  final int rounds;
  final Map<String, int> round1FindingTypes;
  final bool endedClean;

  Map<String, Object?> toJson() => {
    'dispatch': dispatch,
    'rounds': rounds,
    'round1FindingTypes': round1FindingTypes,
    'endedClean': endedClean,
  };
}

class FindingTypeRanking {
  const FindingTypeRanking({
    required this.findingType,
    required this.dispatchCount,
  });

  final String findingType;
  final int dispatchCount;

  Map<String, Object?> toJson() => {
    'findingType': findingType,
    'dispatchCount': dispatchCount,
  };
}

class ValidatorRoundReport {
  const ValidatorRoundReport({
    required this.dispatches,
    required this.round1FindingTypeRanking,
    required this.roundCountDistribution,
    required this.malformedLineCount,
  });

  final List<DispatchRoundSummary> dispatches;
  final List<FindingTypeRanking> round1FindingTypeRanking;
  final Map<int, int> roundCountDistribution;
  final int malformedLineCount;

  Map<String, Object?> toJson() => {
    'dispatches': dispatches.map((summary) => summary.toJson()).toList(),
    'round1FindingTypeRanking': round1FindingTypeRanking
        .map((ranking) => ranking.toJson())
        .toList(),
    'roundCountDistribution': {
      for (final entry in roundCountDistribution.entries)
        '${entry.key}': entry.value,
    },
    'malformedLineCount': malformedLineCount,
  };
}

class _RoundEntry {
  const _RoundEntry({
    required this.dispatch,
    required this.round,
    required this.status,
    required this.findingTypes,
  });

  final String dispatch;
  final int? round;
  final String? status;
  final Map<String, int> findingTypes;
}

ValidatorRoundReport summarizeValidatorRounds(Iterable<String> lines) {
  final entriesByDispatch = <String, List<_RoundEntry>>{};
  var malformedLineCount = 0;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    final _RoundEntry? entry;
    try {
      final decoded = jsonDecode(line);
      entry = _parseEntry(decoded);
    } on FormatException {
      malformedLineCount++;
      continue;
    }
    if (entry == null) {
      malformedLineCount++;
      continue;
    }
    entriesByDispatch.putIfAbsent(entry.dispatch, () => []).add(entry);
  }

  final dispatchNames = entriesByDispatch.keys.toList()..sort();
  final dispatches = <DispatchRoundSummary>[];
  final dispatchesByFindingType = <String, Set<String>>{};
  final roundCountDistribution = <int, int>{};

  for (final dispatch in dispatchNames) {
    final entries = entriesByDispatch[dispatch]!;
    final round1FindingTypes = <String, int>{};
    for (final entry in entries.where((entry) => entry.round == 1)) {
      for (final finding in entry.findingTypes.entries) {
        round1FindingTypes.update(
          finding.key,
          (count) => count + finding.value,
          ifAbsent: () => finding.value,
        );
      }
    }
    final sortedRound1FindingTypes = <String, int>{
      for (final type in (round1FindingTypes.keys.toList()..sort()))
        type: round1FindingTypes[type]!,
    };

    for (final findingType in sortedRound1FindingTypes.keys) {
      dispatchesByFindingType
          .putIfAbsent(findingType, () => <String>{})
          .add(dispatch);
    }

    dispatches.add(
      DispatchRoundSummary(
        dispatch: dispatch,
        rounds: entries.length,
        round1FindingTypes: sortedRound1FindingTypes,
        endedClean: entries.last.status == 'pass',
      ),
    );
    roundCountDistribution.update(
      entries.length,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  final ranking =
      [
        for (final entry in dispatchesByFindingType.entries)
          FindingTypeRanking(
            findingType: entry.key,
            dispatchCount: entry.value.length,
          ),
      ]..sort((a, b) {
        final byDispatchCount = b.dispatchCount.compareTo(a.dispatchCount);
        return byDispatchCount != 0
            ? byDispatchCount
            : a.findingType.compareTo(b.findingType);
      });

  final sortedDistribution = <int, int>{
    for (final rounds in (roundCountDistribution.keys.toList()..sort()))
      rounds: roundCountDistribution[rounds]!,
  };

  return ValidatorRoundReport(
    dispatches: dispatches,
    round1FindingTypeRanking: ranking,
    roundCountDistribution: sortedDistribution,
    malformedLineCount: malformedLineCount,
  );
}

_RoundEntry? _parseEntry(Object? decoded) {
  if (decoded is! Map<String, dynamic>) return null;
  final dispatch = decoded['dispatch'];
  final round = decoded['round'];
  final status = decoded['status'];
  final rawFindingTypes = decoded['findingTypes'];
  if (dispatch is! String ||
      (round != null && round is! int) ||
      (status != null && status is! String) ||
      rawFindingTypes is! Map<String, dynamic>) {
    return null;
  }

  final findingTypes = <String, int>{};
  for (final entry in rawFindingTypes.entries) {
    final count = entry.value;
    if (count is! int || count < 0) return null;
    if (count > 0) findingTypes[entry.key] = count;
  }
  return _RoundEntry(
    dispatch: dispatch,
    round: round as int?,
    status: status as String?,
    findingTypes: findingTypes,
  );
}

String renderValidatorRoundReport(ValidatorRoundReport report) {
  final buffer = StringBuffer('Per dispatch:\n');
  if (report.dispatches.isEmpty) {
    buffer.writeln('  (none)');
  } else {
    for (final dispatch in report.dispatches) {
      final findings = dispatch.round1FindingTypes.isEmpty
          ? 'none'
          : dispatch.round1FindingTypes.entries
                .map((entry) => '${entry.key} (${entry.value})')
                .join(', ');
      buffer.writeln(
        '  ${dispatch.dispatch}: ${dispatch.rounds} '
        '${dispatch.rounds == 1 ? 'round' : 'rounds'}; '
        'round 1 findings: $findings; '
        'ended clean: ${dispatch.endedClean ? 'yes' : 'no'}',
      );
    }
  }

  buffer.writeln('Round 1 findings by distinct dispatches:');
  if (report.round1FindingTypeRanking.isEmpty) {
    buffer.writeln('  (none)');
  } else {
    for (
      var index = 0;
      index < report.round1FindingTypeRanking.length;
      index++
    ) {
      final ranking = report.round1FindingTypeRanking[index];
      buffer.writeln(
        '  ${index + 1}. ${ranking.findingType}: '
        '${ranking.dispatchCount} '
        '${ranking.dispatchCount == 1 ? 'dispatch' : 'dispatches'}',
      );
    }
  }

  buffer.writeln('Round-count distribution:');
  if (report.roundCountDistribution.isEmpty) {
    buffer.writeln('  (none)');
  } else {
    for (final entry in report.roundCountDistribution.entries) {
      buffer.writeln(
        '  ${entry.key} ${entry.key == 1 ? 'round' : 'rounds'}: '
        '${entry.value} '
        '${entry.value == 1 ? 'dispatch' : 'dispatches'}',
      );
    }
  }
  if (report.malformedLineCount > 0) {
    buffer.writeln('Malformed lines skipped: ${report.malformedLineCount}');
  }
  return buffer.toString();
}

int runValidatorRoundReport(
  List<String> args, {
  StringSink? output,
  StringSink? errors,
}) {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  if (args.contains('--help')) {
    _writeUsage(out);
    return 0;
  }

  String? logPath;
  var jsonOutput = false;
  for (var index = 0; index < args.length; index++) {
    switch (args[index]) {
      case '--json':
        jsonOutput = true;
        break;
      case '--log':
        if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
          err.writeln('Missing path after --log.');
          _writeUsage(err);
          return 64;
        }
        logPath = args[++index];
        break;
      default:
        err.writeln('Unknown argument: ${args[index]}');
        _writeUsage(err);
        return 64;
    }
  }

  final configuredPath = Platform.environment['LOOM_VALIDATOR_LOG'];
  logPath ??= configuredPath == null || configuredPath.isEmpty
      ? _defaultLogPath
      : configuredPath;

  final List<String> lines;
  try {
    lines = File(logPath).readAsLinesSync();
  } on FileSystemException catch (error) {
    err.writeln('Could not read validator log at $logPath: $error');
    return 1;
  }

  final report = summarizeValidatorRounds(lines);
  if (jsonOutput) {
    out.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    out.write(renderValidatorRoundReport(report));
  }
  return 0;
}

void _writeUsage(StringSink sink) {
  sink.writeln(
    'Usage: dart run bin/validator_round_report.dart '
    '[--log <path>] [--json]',
  );
}

void main(List<String> args) {
  exitCode = runValidatorRoundReport(args);
}
