import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/validator_round_report.dart';

void main() {
  test(
    'ranks round-1 findings by distinct dispatches rather than raw count',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'validator-round-report-test-',
      );
      try {
        final log = File('${tempDirectory.path}/rounds.jsonl');
        await log.writeAsString(
          [
            _line(
              dispatch: 'dispatch-a',
              round: 1,
              status: 'fail',
              findingTypes: {'raw_heavy': 30, 'widespread': 1},
            ),
            _line(dispatch: 'dispatch-a', round: 2, status: 'pass'),
            _line(
              dispatch: 'dispatch-b',
              round: 1,
              status: 'pass',
              findingTypes: {'widespread': 1},
            ),
            _line(
              dispatch: 'dispatch-c',
              round: 1,
              status: 'fail',
              findingTypes: {'widespread': 1},
            ),
          ].join('\n'),
        );

        final output = StringBuffer();
        final errors = StringBuffer();
        final result = runValidatorRoundReport(
          ['--log', log.path, '--json'],
          output: output,
          errors: errors,
        );

        expect(result, 0);
        expect(errors.toString(), isEmpty);
        final json = jsonDecode(output.toString()) as Map<String, dynamic>;
        final ranking = json['round1FindingTypeRanking'] as List<dynamic>;
        expect(ranking, [
          {'findingType': 'widespread', 'dispatchCount': 3},
          {'findingType': 'raw_heavy', 'dispatchCount': 1},
        ]);
        expect(json['roundCountDistribution'], {'1': 2, '2': 1});

        final dispatches = json['dispatches'] as List<dynamic>;
        expect(dispatches.first, {
          'dispatch': 'dispatch-a',
          'rounds': 2,
          'round1FindingTypes': {'raw_heavy': 30, 'widespread': 1},
          'endedClean': true,
        });
      } finally {
        await tempDirectory.delete(recursive: true);
      }
    },
  );

  test('handles an empty log and malformed lines without crashing', () {
    final empty = summarizeValidatorRounds(const []);
    expect(empty.dispatches, isEmpty);
    expect(empty.round1FindingTypeRanking, isEmpty);
    expect(empty.roundCountDistribution, isEmpty);
    expect(empty.malformedLineCount, 0);

    final withMalformed = summarizeValidatorRounds([
      '',
      '{not json',
      '[]',
      _line(dispatch: 'valid', round: 1, status: 'pass'),
    ]);
    expect(withMalformed.dispatches, hasLength(1));
    expect(withMalformed.dispatches.single.dispatch, 'valid');
    expect(withMalformed.malformedLineCount, 2);
  });
}

String _line({
  required String dispatch,
  required int round,
  required String status,
  Map<String, int> findingTypes = const {},
}) => jsonEncode({
  'at': '2026-08-19T12:00:00.000Z',
  'dispatch': dispatch,
  'round': round,
  'status': status,
  'errorCount': status == 'pass' ? 0 : 1,
  'warningCount': 0,
  'findingTypes': findingTypes,
  'packageId': 'package-$dispatch',
  'communityId': 'community-$dispatch',
});
