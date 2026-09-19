// Regression guard for the return-vs-`return await` cleanup-ordering defect
// fixed in `_runB25ShippedWorkflowWalkthrough`
// (integration_test/workflow_ui_evidence_test.dart, commit 6c05ef0c).
//
// `b25_marketplace_finish_ordering_test.dart` proves the MECHANISM -- that an
// unawaited return lets a guarded `finally` start concurrently with it -- but
// it defines its own stand-in function and never calls the real one. A/B
// testing that file with all three real `await`s removed leaves it green
// (2/2), because the real call sites are simply never exercised. This file
// reads the real source as text and asserts the fixed shape is still there,
// so removing an `await` at any of those sites turns this test red.
//
// Two independent checks:
//
// 1. Exact-identifier: every call to `_finishB25WalkthroughAfterPrimary` is
//    `return await`-ed, and at least one such call exists (so deleting the
//    call sites cannot make this pass vacuously).
//
// 2. General shape, deliberately narrower than "any return in a try/finally
//    anywhere at any depth": a bare (non-awaited) `return <identifier>(...)`
//    that sits as a DIRECT statement of a `try` block -- not nested inside a
//    further `if`/`for`/closure within it -- where that `try` is (eventually,
//    across zero or more `catch`/`on` clauses) followed by a `finally`. This
//    is a real structural scan (brace-depth tracking over the file with
//    comments and string literals stripped out first), not a hand-picked
//    line match, so it would catch a future regression with a *different*
//    function name at that same shape.
//
//    It deliberately does NOT flag a bare `return <identifier>(` nested
//    inside an `if`/`for`/closure inside the try (two of the three real call
//    sites are nested exactly that way) -- distinguishing "this identifier's
//    return type is a Future that must be awaited" from "this identifier
//    returns a plain value" at that depth needs real type information a text
//    scan does not have. Concretely: this file also contains a bare
//    `return _throwShippedWorkflowActionStall(...)` nested inside an `if`
//    inside the same try/finally, and `_throwShippedWorkflowActionStall`
//    genuinely returns a `Future`; a depth-unaware version of this check
//    would flag that pre-existing, out-of-scope call alongside (or instead
//    of) the one this guard exists to protect. Restricting the general
//    check to depth-0-within-the-try avoids that false lead. Coverage of the
//    nested sites is left to check 1's exact-identifier match instead, which
//    is unambiguous because it names the function.
//
//    So: the general check is real, but it is not a full Dart parser and
//    does not claim to catch every shape of this bug -- only the case where
//    the offending `return` is a direct statement of the try body.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _targetFunction = '_finishB25WalkthroughAfterPrimary';
const _sourceRelativePath =
    'apps/loom_communities_demo/integration_test/workflow_ui_evidence_test.dart';

void main() {
  test(
    'every call to $_targetFunction is return-awaited, never a bare return',
    () {
      final file = _findSourceFile();
      final lines = file.readAsLinesSync();

      final awaitedPattern = RegExp(
        r'^return\s+await\s+' + RegExp.escape(_targetFunction) + r'\s*\(',
      );
      final barePattern = RegExp(
        r'^return\s+' + RegExp.escape(_targetFunction) + r'\s*\(',
      );

      final bareLines = <int>[];
      final awaitedLines = <int>[];
      for (var i = 0; i < lines.length; i += 1) {
        final trimmed = lines[i].trimLeft();
        if (awaitedPattern.hasMatch(trimmed)) {
          awaitedLines.add(i + 1);
        } else if (barePattern.hasMatch(trimmed)) {
          bareLines.add(i + 1);
        }
      }

      expect(
        bareLines,
        isEmpty,
        reason:
            '${file.path} returns $_targetFunction without awaiting it at '
            'line(s) ${bareLines.join(', ')}. That call sits inside a `try` '
            'whose `finally` does guarded cleanup work '
            '(_runB25ShippedWorkflowWalkthrough); a bare `return` starts the '
            'call and lets `finally` begin before it completes, running the '
            'two concurrently. If the call errors after this try/catch has '
            'already exited, the error reaches the zone\'s unhandled-error '
            'handler instead of any row-scope catch, and one row\'s cleanup '
            'aborts the whole walkthrough -- exactly the defect fixed in '
            '6c05ef0c. Restore `return await $_targetFunction(`.',
      );
      expect(
        awaitedLines,
        isNotEmpty,
        reason:
            'No `return await $_targetFunction(` call sites were found in '
            '${file.path}. Either the fixed call sites were deleted -- which '
            'would make the check above pass vacuously -- or the function '
            'was renamed; update this guard to match rather than let it go '
            'silent.',
      );
    },
  );

  test(
    'no bare `return <identifier>(` sits as a direct statement of a `try` '
    'that is (eventually) followed by a `finally`',
    () {
      final file = _findSourceFile();
      final rawLines = file.readAsLinesSync();
      final violations = _findUnawaitedDirectTryReturns(rawLines);

      expect(
        violations,
        isEmpty,
        reason: violations
            .map(
              (v) =>
                  '${file.path}:${v.line}: `${rawLines[v.line - 1].trim()}` '
                  'returns without awaiting it, as a direct statement of the '
                  '`try` opened at line ${v.tryLine} -- which is followed by '
                  'a `finally` at line ${v.finallyLine}. An unawaited return '
                  'here starts that call and lets `finally`\'s guarded '
                  'cleanup run concurrently with it; if the call errors '
                  'after this try/catch has already exited, the error '
                  'bypasses every row-scope catch and reaches the zone\'s '
                  'unhandled-error handler instead. Add `await`.',
            )
            .join('\n'),
      );
    },
  );
}

File _findSourceFile() {
  var dir = Directory.current;
  while (true) {
    final candidate = File('${dir.path}/$_sourceRelativePath');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not locate $_sourceRelativePath from '
        '${Directory.current.path}.',
      );
    }
    dir = parent;
  }
}

class _UnawaitedTryReturn {
  _UnawaitedTryReturn({
    required this.line,
    required this.tryLine,
    required this.finallyLine,
  });

  final int line;
  final int tryLine;
  final int finallyLine;
}

/// Best-effort structural scan, not a Dart parser -- see the file header for
/// exactly what this does and does not cover.
List<_UnawaitedTryReturn> _findUnawaitedDirectTryReturns(
  List<String> rawLines,
) {
  final index = _SourceIndex.build(rawLines);
  final text = index.text;
  final violations = <_UnawaitedTryReturn>[];

  final tryOpenPattern = RegExp(r'(^|[^A-Za-z0-9_$])try\s*\{');
  final returnCallPattern = RegExp(
    r'\breturn\s+(await\s+)?([A-Za-z_$][\w$]*)\s*\(',
  );

  for (final match in tryOpenPattern.allMatches(text)) {
    final tryOpenOffset = match.end - 1;
    final tryCloseOffset = _matchingClose(text, tryOpenOffset);
    if (tryCloseOffset == null) continue;
    final finallyOpenOffset = _finallyOpenOffsetForTry(text, tryOpenOffset);
    if (finallyOpenOffset == null) continue;

    var depth = 0;
    var i = tryOpenOffset + 1;
    while (i < tryCloseOffset) {
      final ch = text[i];
      if (ch == '{') {
        depth += 1;
        i += 1;
        continue;
      }
      if (ch == '}') {
        depth -= 1;
        i += 1;
        continue;
      }
      if (depth == 0 &&
          text.startsWith('return', i) &&
          (i == 0 || !_isIdentifierChar(text[i - 1]))) {
        final callMatch = returnCallPattern.matchAsPrefix(text, i);
        if (callMatch != null) {
          final isAwaited = callMatch.group(1) != null;
          if (!isAwaited) {
            violations.add(
              _UnawaitedTryReturn(
                line: index.lineOf(i) + 1,
                tryLine: index.lineOf(tryOpenOffset) + 1,
                finallyLine: index.lineOf(finallyOpenOffset) + 1,
              ),
            );
          }
          i = callMatch.end;
          continue;
        }
      }
      i += 1;
    }
  }
  return violations;
}

/// Follows the chain after a `try` block's own close brace through zero or
/// more `catch (...)`/`on Type catch (...)`/`on Type` clauses, and returns
/// the offset of a trailing `finally {` block's own opening brace, or `null`
/// if the chain does not end in one.
int? _finallyOpenOffsetForTry(String text, int tryOpenOffset) {
  final firstClose = _matchingClose(text, tryOpenOffset);
  if (firstClose == null) return null;
  var closeOffset = firstClose;

  while (true) {
    var i = closeOffset + 1;
    var nextOpen = -1;
    while (i < text.length) {
      final ch = text[i];
      if (ch == '{') {
        nextOpen = i;
        break;
      }
      if (ch == ';' || ch == '}') break;
      i += 1;
    }
    if (nextOpen == -1) return null;

    final header = text
        .substring(closeOffset + 1, nextOpen)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (header == 'finally') return nextOpen;

    final isCatchClause =
        RegExp(r'^catch\s*\([^()]*\)$').hasMatch(header) ||
        RegExp(r'^on\s+[\w<>.,\s]+(\s+catch\s*\([^()]*\))?$').hasMatch(header);
    if (!isCatchClause) return null;

    final nextCatchClose = _matchingClose(text, nextOpen);
    if (nextCatchClose == null) return null;
    closeOffset = nextCatchClose;
  }
}

/// Given the offset of an opening `{`, returns the offset of its matching
/// `}`, tracking nesting depth over the whole remaining text.
int? _matchingClose(String text, int openOffset) {
  var depth = 0;
  for (var i = openOffset; i < text.length; i += 1) {
    final ch = text[i];
    if (ch == '{') {
      depth += 1;
    } else if (ch == '}') {
      depth -= 1;
      if (depth == 0) return i;
    }
  }
  return null;
}

bool _isIdentifierChar(String character) {
  final codeUnit = character.codeUnitAt(0);
  return codeUnit == 0x5f /* _ */ ||
      codeUnit == 0x24 /* $ */ ||
      (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a);
}

/// Concatenation of every source line with `//` comments and string-literal
/// contents blanked out (so a brace mentioned in a comment or inside a
/// string/interpolation can never desync the depth count), plus a map from
/// character offset back to the original (0-based) line number.
class _SourceIndex {
  _SourceIndex(this.text, this._lineStarts);

  final String text;
  final List<int> _lineStarts;

  static _SourceIndex build(List<String> rawLines) {
    final buffer = StringBuffer();
    final lineStarts = <int>[];
    for (final rawLine in rawLines) {
      lineStarts.add(buffer.length);
      buffer.write(_stripCommentsAndStrings(rawLine));
      buffer.write('\n');
    }
    return _SourceIndex(buffer.toString(), lineStarts);
  }

  int lineOf(int offset) {
    var lo = 0;
    var hi = _lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// Removes a trailing `//` comment and blanks the contents of single- and
/// double-quoted string literals (including `${...}` interpolation, which is
/// blanked along with the rest of the string it lives in). This is a
/// heuristic, not a Dart lexer: it does not model triple-quoted or raw
/// strings specially. Neither occurs in the file this guard reads today
/// (checked directly), so this is adequate for that file without claiming to
/// be a general-purpose Dart string scanner.
String _stripCommentsAndStrings(String line) {
  final buffer = StringBuffer();
  var i = 0;
  String? quote;
  while (i < line.length) {
    final ch = line[i];
    if (quote != null) {
      if (ch == r'\' && i + 1 < line.length) {
        i += 2;
        continue;
      }
      if (ch == quote) quote = null;
      i += 1;
      continue;
    }
    if (ch == "'" || ch == '"') {
      quote = ch;
      i += 1;
      continue;
    }
    if (ch == '/' && i + 1 < line.length && line[i + 1] == '/') {
      break;
    }
    buffer.write(ch);
    i += 1;
  }
  return buffer.toString();
}
