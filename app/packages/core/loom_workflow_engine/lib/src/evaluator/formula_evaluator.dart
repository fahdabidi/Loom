/// Safe evaluator for the workflow engine's fixed computed-field vocabulary.
///
/// Formulas are parsed; they are never passed to a general purpose language
/// runtime.  Consequently, only the functions and operators in this file can
/// execute, and field resolution is limited to a workflow's declared schema.
class FormulaEvaluationException implements Exception {
  final String message;
  const FormulaEvaluationException(this.message);
  @override
  String toString() => 'FormulaEvaluationException: $message';
}

class FormulaAnalysis {
  final Set<String> referencedFields;
  final Set<String> functionNames;
  const FormulaAnalysis(this.referencedFields, this.functionNames);
}

const Set<String> formulaFunctionNames = {
  'count',
  'sum',
  'avg',
  'min',
  'max',
  'countDistinct',
  'groupCount',
  'sortBy',
  'argMaxKey',
  'topKeys',
  'size',
  'contains',
  'indexOf',
  'if',
  'now',
  'daysBetween',
  'daysUntil',
  'isBefore',
  'isAfter',
  'isPast',
  'subtractHours',
  'mapGet',
  'combineDateAndTime',
};

/// Reduces [values] with the aggregate vocabulary shared by formula fields and
/// the read-side aggregate API.  The caller is responsible for selecting a
/// column before calling this function.
dynamic aggregateValues(Iterable<dynamic> values, String op) {
  final items = values.toList();
  switch (op) {
    case 'count':
      return items.length;
    case 'sum':
      return items.fold<num>(0, (total, value) => total + _number(value));
    case 'avg':
      return items.isEmpty
          ? null
          : items.fold<num>(0, (total, value) => total + _number(value)) /
                items.length;
    case 'min':
      return items.isEmpty
          ? null
          : items.reduce((a, b) => _compare(a, b) <= 0 ? a : b);
    case 'max':
      return items.isEmpty
          ? null
          : items.reduce((a, b) => _compare(a, b) >= 0 ? a : b);
    case 'countDistinct':
      return items.toSet().length;
    default:
      throw FormulaEvaluationException('Unknown aggregate "$op"');
  }
}

/// Parses [formula] and reports direct field references and function calls.
/// Aggregate column arguments (for example `choice` in `groupCount(rows,
/// choice)`) are metadata, not field reads, so are deliberately excluded.
FormulaAnalysis analyzeFormula(String formula) {
  final expression = _Parser(formula).parse();
  final fields = <String>{};
  final functions = <String>{};
  _collect(expression, fields, functions);
  return FormulaAnalysis(fields, functions);
}

/// Evaluates all declared computed fields over [instanceData].  Stored values
/// for computed keys are ignored; computed values exist only on this read map.
Map<String, dynamic> evaluateComputedFields({
  required Map<String, dynamic> instanceData,
  required Map<String, String?> formulas,
  String? viewerId,
  String? actorId,
  DateTime Function()? clock,
}) {
  final result = Map<String, dynamic>.from(instanceData);
  final active = <String>{};
  final cache = <String, dynamic>{};
  final now = clock ?? DateTime.now;

  dynamic readField(String name) {
    final formula = formulas[name];
    if (formula == null) return result[name];
    if (cache.containsKey(name)) return cache[name];
    if (!active.add(name)) {
      throw FormulaEvaluationException(
        'Circular formula dependency at "$name"',
      );
    }
    try {
      final value = _evaluate(
        _Parser(formula).parse(),
        _Context(
          readField: readField,
          viewerId: viewerId,
          actorId: actorId,
          now: now,
        ),
      );
      cache[name] = value;
      result[name] = value;
      return value;
    } finally {
      active.remove(name);
    }
  }

  for (final key in formulas.keys) {
    readField(key);
  }
  return result;
}

dynamic evaluateFormula(
  String formula, {
  required Map<String, dynamic> instanceData,
  String? viewerId,
  String? actorId,
  DateTime Function()? clock,
}) => _evaluate(
  _Parser(formula).parse(),
  _Context(
    readField: (name) => instanceData[name],
    viewerId: viewerId,
    actorId: actorId,
    now: clock ?? DateTime.now,
  ),
);

class _Context {
  final dynamic Function(String) readField;
  final String? viewerId;
  final String? actorId;
  final DateTime Function() now;
  const _Context({
    required this.readField,
    required this.viewerId,
    required this.actorId,
    required this.now,
  });
}

sealed class _Expr {}

class _Literal extends _Expr {
  final dynamic value;
  _Literal(this.value);
}

class _Variable extends _Expr {
  final String name;
  _Variable(this.name);
}

class _Call extends _Expr {
  final String name;
  final List<_Expr> args;
  _Call(this.name, this.args);
}

class _Binary extends _Expr {
  final String op;
  final _Expr left, right;
  _Binary(this.op, this.left, this.right);
}

class _Unary extends _Expr {
  final String op;
  final _Expr value;
  _Unary(this.op, this.value);
}

void _collect(
  _Expr expr,
  Set<String> fields,
  Set<String> functions, {
  bool column = false,
}) {
  switch (expr) {
    case _Variable(:final name):
      if (!column && name != r'$viewer' && name != r'$actor') fields.add(name);
    case _Call(:final name, :final args):
      functions.add(name);
      for (var i = 0; i < args.length; i++) {
        _collect(
          args[i],
          fields,
          functions,
          column:
              (name == 'sum' ||
                  name == 'avg' ||
                  name == 'min' ||
                  name == 'max' ||
                  name == 'countDistinct' ||
                  name == 'groupCount' ||
                  name == 'sortBy') &&
              i == 1,
        );
      }
    case _Binary(:final left, :final right):
      _collect(left, fields, functions);
      _collect(right, fields, functions);
    case _Unary(:final value):
      _collect(value, fields, functions);
    case _Literal():
      break;
  }
}

dynamic _evaluate(_Expr expr, _Context context) {
  switch (expr) {
    case _Literal(:final value):
      return value;
    case _Variable(:final name):
      if (name == r'$viewer') return context.viewerId;
      if (name == r'$actor') return context.actorId;
      return context.readField(name);
    case _Unary(:final op, :final value):
      final v = _evaluate(value, context);
      return op == '-' ? -_number(v) : !_bool(v);
    case _Binary(:final op, :final left, :final right):
      if (op == '&&')
        return _bool(_evaluate(left, context)) &&
            _bool(_evaluate(right, context));
      if (op == '||')
        return _bool(_evaluate(left, context)) ||
            _bool(_evaluate(right, context));
      final a = _evaluate(left, context);
      final b = _evaluate(right, context);
      return switch (op) {
        '+' => _number(a) + _number(b),
        '-' => _number(a) - _number(b),
        '*' || '×' => _number(a) * _number(b),
        '/' || '÷' => _number(a) / _number(b),
        '>=' => _compare(a, b) >= 0,
        '>' => _compare(a, b) > 0,
        '==' => a == b,
        '<' => _compare(a, b) < 0,
        '<=' => _compare(a, b) <= 0,
        _ => throw FormulaEvaluationException('Unsupported operator "$op"'),
      };
    case _Call(:final name, :final args):
      return _call(name, args, context);
  }
}

dynamic _call(String name, List<_Expr> args, _Context context) {
  if (!formulaFunctionNames.contains(name))
    throw FormulaEvaluationException('Unknown function "$name"');
  dynamic arg(int i) {
    if (i >= args.length)
      throw FormulaEvaluationException('$name expects more arguments');
    return _evaluate(args[i], context);
  }

  List<dynamic> list(int i) {
    final value = arg(i);
    if (value is Iterable) return value.toList();
    throw FormulaEvaluationException('$name argument ${i + 1} must be a list');
  }

  String column(int i) {
    final node = args[i];
    if (node is _Variable) return node.name;
    final value = _evaluate(node, context);
    if (value is String) return value;
    throw FormulaEvaluationException(
      '$name column must be an identifier or string',
    );
  }

  List<dynamic> values(int listIndex, int columnIndex) => list(
    listIndex,
  ).map((row) => row is Map ? row[column(columnIndex)] : row).toList();
  switch (name) {
    case 'count':
      return aggregateValues(list(0), 'count');
    case 'sum':
      return aggregateValues(values(0, 1), 'sum');
    case 'avg':
      return aggregateValues(values(0, 1), 'avg');
    case 'min':
      return aggregateValues(values(0, 1), 'min');
    case 'max':
      return aggregateValues(values(0, 1), 'max');
    case 'countDistinct':
      return aggregateValues(values(0, 1), 'countDistinct');
    case 'groupCount':
      final result = <String, int>{};
      for (final v in values(0, 1)) {
        final key = '$v';
        result[key] = (result[key] ?? 0) + 1;
      }
      return result;
    case 'sortBy':
      final v = list(0);
      final col = column(1);
      final direction = arg(2);
      if (direction != 'asc' && direction != 'desc')
        throw const FormulaEvaluationException(
          'sortBy direction must be "asc" or "desc"',
        );
      v.sort((a, b) {
        final c = _compare((a as Map)[col], (b as Map)[col]);
        return direction == 'asc' ? c : -c;
      });
      return v;
    case 'argMaxKey':
      final map = arg(0);
      if (map is! Map || map.isEmpty) return null;
      final entries = Map<dynamic, dynamic>.from(map).entries;
      return entries
          .reduce((a, b) => _compare(a.value, b.value) >= 0 ? a : b)
          .key;
    case 'topKeys':
      final map = arg(0);
      if (map is! Map || map.isEmpty) return <dynamic>[];
      final normalized = Map<dynamic, dynamic>.from(map);
      final maximum = normalized.values.reduce(
        (a, b) => _compare(a, b) >= 0 ? a : b,
      );
      return normalized.entries
          .where((e) => _compare(e.value, maximum) == 0)
          .map((e) => e.key)
          .toList();
    case 'size':
      final value = arg(0);
      return value is Map || value is Iterable || value is String
          ? (value as dynamic).length
          : 0;
    case 'contains':
      final value = arg(0);
      return value is Iterable
          ? value.contains(arg(1))
          : value is Map
          ? value.containsKey(arg(1))
          : false;
    case 'indexOf':
      final value = arg(0);
      return value is List
          ? value.indexOf(arg(1))
          : value is String
          ? value.indexOf('${arg(1)}')
          : -1;
    case 'if':
      return _bool(arg(0)) ? arg(1) : arg(2);
    case 'now':
      return context.now().toUtc();
    case 'daysBetween':
      return _date(arg(1)).difference(_date(arg(0))).inDays;
    case 'daysUntil':
      return _date(arg(0)).difference(context.now()).inDays;
    case 'isBefore':
      return _date(arg(0)).isBefore(_date(arg(1)));
    case 'isAfter':
      return _date(arg(0)).isAfter(_date(arg(1)));
    case 'isPast':
      final date = arg(0);
      return date == null ? null : _date(date).isBefore(context.now());
    case 'subtractHours':
      final date = arg(0);
      return date == null
          ? null
          : _date(date).subtract(Duration(hours: _number(arg(1)).toInt()));
    case 'combineDateAndTime':
      final date = args.isEmpty ? null : arg(0);
      if (date == null) return null;
      final time = args.length > 1 ? arg(1) : null;
      return combineDateAndTimeValues(
        date is DateTime ? date.toIso8601String() : '$date',
        time == null
            ? null
            : (time is DateTime ? time.toIso8601String() : '$time'),
      );
    case 'mapGet':
      final map = arg(0);
      return map is Map ? (map[arg(1)] ?? 0) : 0;
  }
  throw FormulaEvaluationException('Unsupported function "$name"');
}

num _number(dynamic value) {
  if (value is num) return value;
  throw FormulaEvaluationException('Expected number, got $value');
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  throw FormulaEvaluationException('Expected bool, got $value');
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormulaEvaluationException('Expected ISO-8601 date, got $value');
}

/// Combines an ISO date and optional `HH:mm` time into a local timestamp.
/// Invalid or missing values return null so computed fields fail closed.
DateTime? combineDateAndTimeValues(String? dateValue, String? timeValue) {
  if (dateValue == null || dateValue.isEmpty) return null;
  final date = DateTime.tryParse(dateValue);
  if (date == null) return null;

  var hour = 0;
  var minute = 0;
  if (timeValue != null && timeValue.isNotEmpty) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeValue);
    if (match == null) return null;
    hour = int.parse(match.group(1)!);
    minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
  }

  return DateTime(date.year, date.month, date.day, hour, minute);
}

int _compare(dynamic a, dynamic b) {
  if (a is num && b is num) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  return '$a'.compareTo('$b');
}

class _Parser {
  final List<_Token> _tokens;
  int _at = 0;
  _Parser(String source) : _tokens = _Lexer(source).scan();
  _Expr parse() {
    final result = _or();
    if (!_is('eof'))
      throw FormulaEvaluationException('Unexpected token "${_current.text}"');
    return result;
  }

  _Expr _or() {
    var e = _and();
    while (_take('||')) {
      e = _Binary('||', e, _and());
    }
    return e;
  }

  _Expr _and() {
    var e = _comparison();
    while (_take('&&')) {
      e = _Binary('&&', e, _comparison());
    }
    return e;
  }

  _Expr _comparison() {
    var e = _term();
    while (_is('>=') || _is('>') || _is('==') || _is('<') || _is('<=')) {
      final op = _current.text;
      _at++;
      e = _Binary(op, e, _term());
    }
    return e;
  }

  _Expr _term() {
    var e = _factor();
    while (_is('+') || _is('-')) {
      final op = _current.text;
      _at++;
      e = _Binary(op, e, _factor());
    }
    return e;
  }

  _Expr _factor() {
    var e = _unary();
    while (_is('*') || _is('/') || _is('×') || _is('÷')) {
      final op = _current.text;
      _at++;
      e = _Binary(op, e, _unary());
    }
    return e;
  }

  _Expr _unary() {
    if (_take('-')) return _Unary('-', _unary());
    if (_take('!')) return _Unary('!', _unary());
    return _primary();
  }

  _Expr _primary() {
    final t = _current;
    if (_take('number')) return _Literal(num.parse(t.text));
    if (_take('string')) return _Literal(t.text);
    if (_take('true')) return _Literal(true);
    if (_take('false')) return _Literal(false);
    if (_take('null')) return _Literal(null);
    if (_take('(')) {
      final e = _or();
      _expect(')');
      return e;
    }
    if (_take('identifier')) {
      if (_take('(')) {
        final args = <_Expr>[];
        if (!_is(')')) {
          do {
            args.add(_or());
          } while (_take(','));
        }
        _expect(')');
        return _Call(t.text, args);
      }
      return _Variable(t.text);
    }
    throw FormulaEvaluationException('Expected expression at "${t.text}"');
  }

  bool _is(String type) => _current.type == type || _current.text == type;
  bool _take(String type) {
    if (!_is(type)) return false;
    _at++;
    return true;
  }

  void _expect(String type) {
    if (!_take(type))
      throw FormulaEvaluationException(
        'Expected "$type" at "${_current.text}"',
      );
  }

  _Token get _current => _tokens[_at];
}

class _Token {
  final String type, text;
  const _Token(this.type, this.text);
}

class _Lexer {
  final String source;
  int _at = 0;
  _Lexer(this.source);
  List<_Token> scan() {
    final result = <_Token>[];
    while (_at < source.length) {
      final c = source[_at];
      if (c.trim().isEmpty) {
        _at++;
        continue;
      }
      if ('()+-*/×÷,<>!=&|'.contains(c)) {
        final next = _at + 1 < source.length ? source[_at + 1] : '';
        if ((c == '>' || c == '<' || c == '=' || c == '!') && next == '=') {
          result.add(_Token('$c=', '$c='));
          _at += 2;
        } else if ((c == '&' || c == '|') && next == c) {
          result.add(_Token('$c$c', '$c$c'));
          _at += 2;
        } else {
          result.add(_Token(c, c));
          _at++;
        }
        continue;
      }
      if (c == '"' || c == "'") {
        final quote = c;
        _at++;
        final b = StringBuffer();
        while (_at < source.length && source[_at] != quote) {
          if (source[_at] == '\\' && _at + 1 < source.length) _at++;
          b.write(source[_at++]);
        }
        if (_at == source.length)
          throw const FormulaEvaluationException('Unterminated string');
        _at++;
        result.add(_Token('string', b.toString()));
        continue;
      }
      final start = _at;
      while (_at < source.length &&
          RegExp(r'[A-Za-z0-9_$\.]+').hasMatch(source[_at])) {
        _at++;
      }
      if (start == _at)
        throw FormulaEvaluationException('Unexpected character "$c"');
      final word = source.substring(start, _at);
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(word))
        result.add(_Token('number', word));
      else if (word == 'true' || word == 'false' || word == 'null')
        result.add(_Token(word, word));
      else
        result.add(_Token('identifier', word));
    }
    result.add(const _Token('eof', 'end of formula'));
    return result;
  }
}
