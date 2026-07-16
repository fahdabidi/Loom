/// A parsed bounded source query (GAP-4).
///
/// Grammar:  `query(<workflowType> where <foreignField> == <localField>)`
/// Only single-equality (`==`) is supported — no compound conditions,
/// no nesting, no other operators.
class SourceQuery {
  final String workflowType;
  final String foreignField;
  final String localField;

  const SourceQuery({
    required this.workflowType,
    required this.foreignField,
    required this.localField,
  });

  /// Parses a query string or returns `null` if the string does not match
  /// the grammar.
  static SourceQuery? tryParse(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^query\((\w[\w-]*) where (\w+) == (\w+)\)$')
        .firstMatch(raw.trim());
    if (match == null) return null;
    return SourceQuery(
      workflowType: match.group(1)!,
      foreignField: match.group(2)!,
      localField: match.group(3)!,
    );
  }
}
