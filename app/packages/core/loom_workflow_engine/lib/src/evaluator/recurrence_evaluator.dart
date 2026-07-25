/// A fully-resolved recurrence pattern.
class RecurrenceRule {
  final String freq;
  final int interval;
  final int count;
  final List<String>? byDayOfWeek;
  final int? byMonthDay;
  final String? bySetPos;

  const RecurrenceRule({
    required this.freq,
    this.interval = 1,
    required this.count,
    this.byDayOfWeek,
    this.byMonthDay,
    this.bySetPos,
  });

  /// Parses a recurrence map after all interpolation has been resolved.
  factory RecurrenceRule.fromResolvedJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw StateError('recurrenceRule.$key must be a non-empty string');
      }
      return value;
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final freq = requiredString('freq');
    if (!const {'daily', 'weekly', 'monthly'}.contains(freq)) {
      throw StateError('recurrenceRule.freq must be daily, weekly, or monthly');
    }
    final interval =
        json.containsKey('interval') ? parseInt(json['interval']) : 1;
    if (interval == null || interval < 1) {
      throw StateError('recurrenceRule.interval must be an integer >= 1');
    }
    final count = parseInt(json['count']);
    if (count == null || count < 1 || count > 366) {
      throw StateError('recurrenceRule.count must be an integer from 1 to 366');
    }

    List<String>? byDayOfWeek;
    if (json.containsKey('byDayOfWeek')) {
      final raw = json['byDayOfWeek'];
      if (raw is! List || raw.isEmpty || raw.any((item) => item is! String)) {
        throw StateError('recurrenceRule.byDayOfWeek must be a non-empty list');
      }
      byDayOfWeek = raw.cast<String>();
      const validCodes = {'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'};
      if (byDayOfWeek.any((code) => !validCodes.contains(code)) ||
          byDayOfWeek.toSet().length != byDayOfWeek.length) {
        throw StateError('recurrenceRule.byDayOfWeek contains an invalid code');
      }
    }

    int? byMonthDay;
    if (json.containsKey('byMonthDay')) {
      byMonthDay = parseInt(json['byMonthDay']);
      if (byMonthDay == null || byMonthDay < 1 || byMonthDay > 31) {
        throw StateError(
          'recurrenceRule.byMonthDay must be an integer from 1 to 31',
        );
      }
    }
    final bySetPos = json['bySetPos'];
    if (bySetPos != null &&
        (bySetPos is! String ||
            !const {'first', 'second', 'third', 'fourth', 'last'}
                .contains(bySetPos))) {
      throw StateError('recurrenceRule.bySetPos is invalid');
    }

    if (freq == 'daily' &&
        (byDayOfWeek != null || byMonthDay != null || bySetPos != null)) {
      throw StateError(
        'daily recurrence cannot use byDayOfWeek, byMonthDay, or bySetPos',
      );
    }
    if (freq == 'weekly' && (byMonthDay != null || bySetPos != null)) {
      throw StateError('weekly recurrence cannot use byMonthDay or bySetPos');
    }
    if (freq == 'monthly') {
      if (byMonthDay != null && bySetPos != null) {
        throw StateError('monthly byMonthDay and bySetPos are mutually exclusive');
      }
      if (bySetPos != null && byDayOfWeek?.length != 1) {
        throw StateError('monthly bySetPos requires exactly one byDayOfWeek');
      }
      if (bySetPos == null && byDayOfWeek != null) {
        throw StateError('monthly byDayOfWeek requires bySetPos');
      }
    }

    return RecurrenceRule(
      freq: freq,
      interval: interval,
      count: count,
      byDayOfWeek: byDayOfWeek,
      byMonthDay: byMonthDay,
      bySetPos: bySetPos as String?,
    );
  }
}

const _isoWeekdays = {
  'MO': DateTime.monday,
  'TU': DateTime.tuesday,
  'WE': DateTime.wednesday,
  'TH': DateTime.thursday,
  'FR': DateTime.friday,
  'SA': DateTime.saturday,
  'SU': DateTime.sunday,
};

/// Computes exactly [RecurrenceRule.count] occurrences, including [anchor].
List<DateTime> computeRecurrenceOccurrences(DateTime anchor, RecurrenceRule rule) {
  switch (rule.freq) {
    case 'daily':
      return List.generate(
        rule.count,
        (i) => anchor.add(Duration(days: rule.interval * i)),
      );
    case 'weekly':
      final byDay = rule.byDayOfWeek;
      if (byDay == null) {
        return List.generate(
          rule.count,
          (i) => anchor.add(Duration(days: 7 * rule.interval * i)),
        );
      }
      final weekdays = byDay.map((code) => _isoWeekdays[code]!).toList()
        ..sort();
      final result = <DateTime>[];
      final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
      for (var week = 0; result.length < rule.count; week++) {
        final weekMonday = monday.add(Duration(days: 7 * rule.interval * week));
        for (final weekday in weekdays) {
          final candidate = weekMonday.add(Duration(days: weekday - 1));
          if (!candidate.isBefore(anchor)) result.add(candidate);
          if (result.length == rule.count) break;
        }
      }
      return result;
    case 'monthly':
      return List.generate(rule.count, (i) {
        final monthOffset = rule.interval * i;
        final targetYear =
            anchor.year + (anchor.month - 1 + monthOffset) ~/ 12;
        final targetMonth = (anchor.month - 1 + monthOffset) % 12 + 1;
        final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
        final setPos = rule.bySetPos;
        late final int day;
        if (setPos == null) {
          final requestedDay = rule.byMonthDay ?? anchor.day;
          day = requestedDay < lastDay ? requestedDay : lastDay;
        } else {
          final weekday = _isoWeekdays[rule.byDayOfWeek!.single]!;
          if (setPos == 'last') {
            final lastOfMonth = DateTime(targetYear, targetMonth + 1, 0);
            day = lastOfMonth.day - ((lastOfMonth.weekday - weekday + 7) % 7);
          } else {
            final firstOfMonth = DateTime(targetYear, targetMonth, 1);
            final firstMatchDay =
                1 + ((weekday - firstOfMonth.weekday + 7) % 7);
            const ordinals = {
              'first': 0,
              'second': 1,
              'third': 2,
              'fourth': 3,
            };
            final requestedDay = firstMatchDay + 7 * ordinals[setPos]!;
            if (requestedDay <= lastDay) {
              day = requestedDay;
            } else {
              final lastOfMonth = DateTime(targetYear, targetMonth + 1, 0);
              day = lastOfMonth.day -
                  ((lastOfMonth.weekday - weekday + 7) % 7);
            }
          }
        }
        return DateTime(
          targetYear,
          targetMonth,
          day,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      });
    default:
      throw StateError('Unsupported recurrence frequency: ${rule.freq}');
  }
}
