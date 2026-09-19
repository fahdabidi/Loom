import 'package:loom_communities_app_shell/loom_communities_app_shell.dart'
    show renderWorkflowFactLabel, renderWorkflowFactValue;
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// Describes the declared visibility of source-instance data changed by a
/// B25 action. The capture harness supplies actual viewport text separately.
class B25DataChangeVisibility {
  const B25DataChangeVisibility({
    required this.changedKeys,
    required this.renderableKeys,
    required this.excludedDisplayContextsByKey,
    required this.undeclaredKeys,
    required this.emptyResultKeys,
    required this.renderedTextCandidatesByKey,
  });

  final List<String> changedKeys;
  final List<String> renderableKeys;
  final Map<String, List<String>> excludedDisplayContextsByKey;
  final List<String> undeclaredKeys;
  final List<String> emptyResultKeys;
  final Map<String, List<String>> renderedTextCandidatesByKey;

  bool get everyChangedKeyIsExcludedByDisplayContext =>
      changedKeys.isNotEmpty &&
      excludedDisplayContextsByKey.length == changedKeys.length;
}

B25DataChangeVisibility b25DataChangeVisibility({
  required Map<String, dynamic> sourceInstanceData,
  required Map<String, dynamic> resultInstanceData,
  required Map<String, InstanceDataField> instanceDataSchema,
  required String displayContext,
}) {
  final changedKeys =
      <String>{...sourceInstanceData.keys, ...resultInstanceData.keys}
          .where(
            (key) =>
                !_sameValue(sourceInstanceData[key], resultInstanceData[key]),
          )
          .toList()
        ..sort();
  final renderableKeys = <String>[];
  final excludedDisplayContextsByKey = <String, List<String>>{};
  final undeclaredKeys = <String>[];
  final emptyResultKeys = <String>[];
  final renderedTextCandidatesByKey = <String, List<String>>{};

  for (final key in changedKeys) {
    final field = instanceDataSchema[key];
    if (field == null) {
      undeclaredKeys.add(key);
      continue;
    }
    final contexts = field.displayContexts;
    if (contexts != null && !contexts.contains(displayContext)) {
      excludedDisplayContextsByKey[key] = List<String>.of(contexts);
      continue;
    }
    final value = resultInstanceData[key];
    if (field.hideWhenEmpty && _isEmpty(value)) {
      emptyResultKeys.add(key);
      continue;
    }
    renderableKeys.add(key);
    final candidate = _renderedValueCandidate(field, value);
    if (candidate.isNotEmpty) {
      renderedTextCandidatesByKey[key] = <String>[candidate];
    }
  }

  return B25DataChangeVisibility(
    changedKeys: changedKeys,
    renderableKeys: renderableKeys,
    excludedDisplayContextsByKey: excludedDisplayContextsByKey,
    undeclaredKeys: undeclaredKeys,
    emptyResultKeys: emptyResultKeys,
    renderedTextCandidatesByKey: renderedTextCandidatesByKey,
  );
}

/// Every exact string a workflow could legitimately render for a declared
/// state label: the bare label itself, plus the label composed through any
/// declared field's `labelTemplate` that has a `{value}` placeholder.
///
/// A workflow may surface a terminal state's label only through a computed
/// field rather than the bare label -- Garden Club's `given` state is
/// labelled `"Ownership transferred"`, but the giveaway card only ever shows
/// that string via `transferSummary`'s `"Transfer: {value}"` template, i.e.
/// as `"Transfer: Ownership transferred"`. Nothing declares which field (if
/// any) does this, so every declared template is tried and the caller
/// matches on exact string equality against the resulting set. This must
/// never be loosened to a substring match: product vocabulary collides on
/// substrings (`"Not attending"` contains `attend`, `"Join waitlist"`
/// contains `wait`), so a superstring decoy must not satisfy it.
Set<String> b25StateLabelRenderCandidates(
  String stateLabel,
  Map<String, InstanceDataField> instanceDataSchema,
) {
  final candidates = <String>{stateLabel};
  for (final field in instanceDataSchema.values) {
    final template = field.labelTemplate?.trim();
    if (template == null ||
        template.isEmpty ||
        !template.contains('{value}')) {
      continue;
    }
    candidates.add(renderWorkflowFactLabel(template, stateLabel));
  }
  return candidates;
}

/// A postcondition that must be visible in the viewport before B25 captures
/// the receiver/result frame.
class B25VisiblePostcondition {
  const B25VisiblePostcondition.stateChange(this.stateLabelCandidates)
    : dataChange = null;

  const B25VisiblePostcondition.sourceInstanceEffect(this.dataChange)
    : stateLabelCandidates = null;

  /// Every exact string that would prove the state change, as computed by
  /// [b25StateLabelRenderCandidates]. Deliberately a set of exact strings
  /// rather than one label: see that function for why more than one can be
  /// legitimate.
  final Set<String>? stateLabelCandidates;
  final B25DataChangeVisibility? dataChange;

  bool isSatisfiedBy(
    Iterable<String> viewportTexts, {
    bool explicitSuccessAcknowledgement = false,
  }) {
    if (explicitSuccessAcknowledgement) return true;
    final expectedLabels = stateLabelCandidates;
    if (expectedLabels != null) {
      return viewportTexts.any(
        (text) => expectedLabels.contains(text.trim()),
      );
    }
    final changedData = dataChange;
    if (changedData == null ||
        changedData.everyChangedKeyIsExcludedByDisplayContext) {
      return false;
    }
    for (final candidates in changedData.renderedTextCandidatesByKey.values) {
      for (final candidate in candidates) {
        if (viewportTexts.any((text) => text.trim() == candidate)) {
          return true;
        }
      }
    }
    return false;
  }
}

bool _sameValue(Object? left, Object? right) {
  if (identical(left, right) || left == right) return true;
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && _sameValue(left[key], right[key]),
        );
  }
  if (left is Iterable && right is Iterable) {
    final leftValues = left.toList(growable: false);
    final rightValues = right.toList(growable: false);
    if (leftValues.length != rightValues.length) return false;
    for (var index = 0; index < leftValues.length; index += 1) {
      if (!_sameValue(leftValues[index], rightValues[index])) return false;
    }
    return true;
  }
  return false;
}

bool _isEmpty(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is Iterable && value.isEmpty) ||
    (value is Map && value.isEmpty);

String _renderedValueCandidate(InstanceDataField field, Object? value) {
  final template = field.labelTemplate?.trim();
  final valueText = renderWorkflowFactValue(value);
  if (template == null || template.isEmpty) return valueText;
  if (template.contains('{value.length}')) {
    return renderWorkflowFactLabel(template, value);
  }
  if (template.contains('{value}')) {
    return renderWorkflowFactLabel(template, value);
  }
  // A label without a value placeholder cannot prove that the value changed.
  return valueText;
}
