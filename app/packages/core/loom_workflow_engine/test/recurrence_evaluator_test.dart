import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

RecurrenceRule _rule(Map<String, dynamic> json) =>
    RecurrenceRule.fromResolvedJson(json);

void main() {
  group('computeRecurrenceOccurrences', () {
    test('computes daily occurrences at the requested interval', () {
      final dates = computeRecurrenceOccurrences(
        DateTime(2026, 7, 10, 9, 30),
        _rule({'freq': 'daily', 'interval': 2, 'count': 3}),
      );

      expect(dates, [
        DateTime(2026, 7, 10, 9, 30),
        DateTime(2026, 7, 12, 9, 30),
        DateTime(2026, 7, 14, 9, 30),
      ]);
    });

    test('defaults weekly recurrence to the anchor weekday', () {
      final dates = computeRecurrenceOccurrences(
        DateTime(2026, 7, 10),
        _rule({'freq': 'weekly', 'interval': 2, 'count': 3}),
      );

      expect(dates, [
        DateTime(2026, 7, 10),
        DateTime(2026, 7, 24),
        DateTime(2026, 8, 7),
      ]);
    });

    test('walks weekly BYDAY blocks and drops earlier week-zero weekdays', () {
      final dates = computeRecurrenceOccurrences(
        DateTime(2026, 7, 8), // Wednesday
        _rule({
          'freq': 'weekly',
          'count': 5,
          'byDayOfWeek': ['WE', 'MO'],
        }),
      );

      expect(dates, [
        DateTime(2026, 7, 8),
        DateTime(2026, 7, 13),
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 22),
      ]);
    });

    test('clamps monthly byMonthDay including February leap years', () {
      final nonLeap = computeRecurrenceOccurrences(
        DateTime(2025, 1, 31),
        _rule({'freq': 'monthly', 'count': 3, 'byMonthDay': 31}),
      );
      final leap = computeRecurrenceOccurrences(
        DateTime(2024, 1, 31),
        _rule({'freq': 'monthly', 'count': 3, 'byMonthDay': '31'}),
      );

      expect(nonLeap, [
        DateTime(2025, 1, 31),
        DateTime(2025, 2, 28),
        DateTime(2025, 3, 31),
      ]);
      expect(leap, [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29),
        DateTime(2024, 3, 31),
      ]);
    });

    test('computes the last requested weekday of every month', () {
      final dates = computeRecurrenceOccurrences(
        DateTime(2026, 1, 1, 13, 45, 12),
        _rule({
          'freq': 'monthly',
          'count': 3,
          'byDayOfWeek': ['FR'],
          'bySetPos': 'last',
        }),
      );

      expect(dates, [
        DateTime(2026, 1, 30, 13, 45, 12),
        DateTime(2026, 2, 27, 13, 45, 12),
        DateTime(2026, 3, 27, 13, 45, 12),
      ]);
    });

    test('computes an ordinal monthly weekday', () {
      final dates = computeRecurrenceOccurrences(
        DateTime(2026, 1, 1),
        _rule({
          'freq': 'monthly',
          'count': 2,
          'byDayOfWeek': ['MO'],
          'bySetPos': 'fourth',
        }),
      );

      expect(dates, [DateTime(2026, 1, 26), DateTime(2026, 2, 23)]);
    });
  });

  test('parses stringly typed numeric literals and rejects out-of-range values', () {
    final parsed = _rule({'freq': 'weekly', 'interval': '2', 'count': '3'});
    expect(parsed.interval, 2);
    expect(parsed.count, 3);
    expect(
      () => _rule({'freq': 'weekly', 'count': 5000}),
      throwsA(isA<StateError>()),
    );
  });
}
