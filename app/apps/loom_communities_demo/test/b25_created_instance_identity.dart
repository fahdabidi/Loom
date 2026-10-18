import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_workflow_row_selection.dart';
import 'walkthrough_wait.dart';

/// Harness copy of the shell's tab-surface reconciliation map.
///
/// Mirrors `appShellTabNativeRendererContractIdsByArchetype`
/// (`app_shell_capabilities.dart`): the archetypes with a dedicated
/// whole-tab surface. A tab whose bindings name exactly one family present
/// here renders on that dedicated surface; every other tab renders on the
/// generic list. Kept as a hand copy (not an import) so the parity test in
/// `b25_created_instance_identity_test.dart` fails if either side drifts.
const Map<String, String> b25TabNativeRendererContractIdsByArchetype =
    <String, String>{
      'calendar': 'calendar-agenda-event-detail',
      'event-rsvp': 'calendar-agenda-event-detail',
      'equipment-loan': 'marketplace-browse-listing-detail',
    };

/// Harness copy of `defaultAppShellTabRendererContractId`.
const String b25DefaultAppShellTabRendererContractId =
    'engine-native-generic-list';

/// Resolves a creation tab's renderer contract the same way the shell's
/// `_derivedRendererContractIdForTab` does: exactly one bound family present
/// in [b25TabNativeRendererContractIdsByArchetype] selects that dedicated
/// surface, and anything else (zero, several, or one unmapped family such as
/// `table`) falls back to the generic list.
String b25RendererContractIdForTabBoundFamilies(
  Set<String> boundSurfaceFamilies,
) {
  if (boundSurfaceFamilies.length != 1) {
    return b25DefaultAppShellTabRendererContractId;
  }
  return b25TabNativeRendererContractIdsByArchetype[boundSurfaceFamilies
          .single] ??
      b25DefaultAppShellTabRendererContractId;
}

/// Collects a tab's bound card-surface families the same way the shell does
/// (every `renderBinding` whose `tabId` matches, across all workflow
/// definitions), so callers pass the full set rather than just the created
/// workflow's own family. The full set is load-bearing: Garden's `home` tab
/// binds six families including `event-rsvp` and `equipment-loan`, so a
/// singleton would misresolve an `event-rsvp` creation there to the calendar
/// surface while the shell renders the generic list.
Set<String> b25TabBoundSurfaceFamilies(
  LoomExperienceDefinition experience,
  String tabId,
) => <String>{
  for (final definition
      in experience.workflowDefinitions?.values ??
          const <LoomWorkflowStateMachine>[])
    for (final binding in definition.renderBindings)
      if (binding.tabId == tabId) binding.cardSurfaceFamily,
};

/// Reads the identities exposed by engine-native row keys on a tab.
///
/// Which widget-key namespace carries the identity depends on the tab's
/// reconciled renderer ([b25RendererContractIdForTabBoundFamilies] applied to
/// [tabBoundSurfaceFamilies]):
///
/// * calendar surface: `engine-native-calendar-agenda-<instanceId>-<index>`
///   (`part28:1308`), excluding the `facts-` twin (`part28:1336`) and the
///   `$day`-keyed `group-`/`date-`/`today-` keys, which share the prefix.
/// * marketplace surface: `marketplace-listing-<instanceId>` (`part36:357`),
///   excluding the simultaneously-mounted `-tap-` twin (`part36:351`). The
///   remainder is the whole id: this namespace has NO trailing binding
///   index, so stripping one would truncate every id at its last dash.
/// * generic list (including `table`-family bindings, which the list surface
///   dispatches one level higher): `engine-native-list-item-<tabId>-<id>-<N>`
///   (`part32:179`) plus `workflow-table-row-<groupId>-<id>-<N>`
///   (`part32:551`), where `<groupId>` is `<tabId>-<workflowType>` and is
///   recovered from the mounted `engine-native-table-`/`workflow-table-data-`
///   group keys, keeping the per-tab guarantee for that namespace.
///
/// Only the list namespace carries the tab id, so the other namespaces drop
/// the per-tab filter. That relies on the shell mounting exactly one tab
/// surface at a time (`_TabNativeRenderer` builds only the selected tab) plus
/// the exactly-one guard in [waitForCreatedEngineNativeInstanceId], which
/// keeps any residual cross-talk a loud failure rather than a silent misread.
/// A dedicated-subtree scope (`find.descendant`) was not available: the
/// calendar and marketplace surfaces expose no stable tab-scoped ancestor key.
///
/// Every match is an anchored template, never a fragment: several of these
/// files also emit `*-detail-name-`, `*-list-field-` and similar keys
/// carrying the same instance id, so a loose match would count one card many
/// times. The binding index is the final component wherever one exists, so
/// instance ids may contain dashes.
Set<String> engineNativeInstanceIdsForTab(
  WidgetTester tester, {
  required String tabId,
  required Set<String> tabBoundSurfaceFamilies,
}) {
  final rendererContractId = b25RendererContractIdForTabBoundFamilies(
    tabBoundSurfaceFamilies,
  );
  switch (rendererContractId) {
    case 'calendar-agenda-event-detail':
      return _calendarAgendaInstanceIds(tester);
    case 'marketplace-browse-listing-detail':
      return _marketplaceListingInstanceIds(tester);
    default:
      return _genericListInstanceIds(tester, tabId: tabId);
  }
}

/// `engine-native-calendar-agenda-<instanceId>-<bindingIndex>`, minus the
/// `facts-` twin and the `$day`-keyed group/date keys sharing the prefix.
Set<String> _calendarAgendaInstanceIds(WidgetTester tester) {
  const prefix = 'engine-native-calendar-agenda-';
  const excludedRemainderPrefixes = <String>[
    'group-',
    'date-',
    'today-',
    'facts-',
  ];
  final ids = <String>{};
  for (final element in find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(prefix),
        description: 'engine-native calendar agenda tile',
      )
      .evaluate()) {
    final key = element.widget.key! as ValueKey<String>;
    final remainder = key.value.substring(prefix.length);
    if (excludedRemainderPrefixes.any(remainder.startsWith)) continue;
    final id = _stripTrailingBindingIndex(remainder);
    if (id != null) ids.add(id);
  }
  return ids;
}

/// `marketplace-listing-<instanceId>`, minus the simultaneously-mounted
/// `marketplace-listing-tap-<instanceId>` twin. The remainder is the whole
/// id: no trailing component is stripped here.
Set<String> _marketplaceListingInstanceIds(WidgetTester tester) {
  const prefix = 'marketplace-listing-';
  final ids = <String>{};
  for (final element in find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(prefix),
        description: 'marketplace listing card',
      )
      .evaluate()) {
    final key = element.widget.key! as ValueKey<String>;
    final remainder = key.value.substring(prefix.length);
    if (remainder.isEmpty || remainder.startsWith('tap-')) continue;
    ids.add(remainder);
  }
  return ids;
}

/// Generic-list union: tab-scoped `engine-native-list-item-` rows plus
/// `workflow-table-row-` rows whose group id opens with `<tabId>-`.
Set<String> _genericListInstanceIds(
  WidgetTester tester, {
  required String tabId,
}) {
  final ids = <String>{};
  final listPrefix = 'engine-native-list-item-$tabId-';
  final keys = find
      .byWidgetPredicate(
        (widget) => widget.key is ValueKey<String>,
        description: 'engine-native keyed widget on tab $tabId',
      )
      .evaluate()
      .map((element) => (element.widget.key! as ValueKey<String>).value)
      .toList(growable: false);

  for (final value in keys) {
    if (value.startsWith(listPrefix)) {
      final id = _stripTrailingBindingIndex(
        value.substring(listPrefix.length),
      );
      if (id != null) ids.add(id);
    }
  }

  // Table groups render one level higher in the same surface with
  // `<groupId> == <tabId>-<workflowType>` (`part32:275`), so the mounted
  // group keys disclose the exact group ids before any row key is parsed.
  const tableWidgetPrefix = 'engine-native-table-';
  const tableDataPrefix = 'workflow-table-data-';
  final groupIds = <String>{
    for (final value in keys)
      if (value.startsWith(tableWidgetPrefix) &&
          value.substring(tableWidgetPrefix.length).startsWith('$tabId-'))
        value.substring(tableWidgetPrefix.length),
    for (final value in keys)
      if (value.startsWith(tableDataPrefix) &&
          value.substring(tableDataPrefix.length).startsWith('$tabId-'))
        value.substring(tableDataPrefix.length),
  };
  const tableRowPrefix = 'workflow-table-row-';
  for (final value in keys) {
    if (!value.startsWith(tableRowPrefix)) continue;
    final remainder = value.substring(tableRowPrefix.length);
    final groupId = groupIds.firstWhere(
      (group) => remainder.startsWith('$group-'),
      orElse: () => '',
    );
    if (groupId.isEmpty) continue;
    final idAndIndex = remainder.substring(groupId.length + 1);
    final id = _stripTrailingBindingIndex(idAndIndex);
    if (id != null) ids.add(id);
  }
  return ids;
}

/// Strips the final `-<bindingIndex>` component, returning null when the
/// remainder is not `<non-empty>-<integer>`.
String? _stripTrailingBindingIndex(String encodedIdentity) {
  final separator = encodedIdentity.lastIndexOf('-');
  if (separator <= 0 ||
      int.tryParse(encodedIdentity.substring(separator + 1)) == null) {
    return null;
  }
  return encodedIdentity.substring(0, separator);
}

/// Waits for the engine-native identity key produced by a successful creation.
///
/// The instance ID is not inferred from rendered title text. Instead, this
/// compares the renderer-resolved row keys before and after submission and
/// accepts exactly one new identity. Zero or multiple candidates remain loud
/// result-verification failures because the creation call has already
/// returned successfully by the time this function is used.
Future<String> waitForCreatedEngineNativeInstanceId(
  WidgetTester tester, {
  required String workflowType,
  required String tabId,
  required Set<String> tabBoundSurfaceFamilies,
  required Set<String> existingInstanceIds,
  Duration? timeout,
  DateTime Function()? now,
}) async {
  final budget = WalkthroughWaitBudget(
    timeout: timeout ?? WalkthroughWaitBudget.defaultInnerWaitTimeout,
    now: now,
  );
  Set<String> candidateIds = const <String>{};

  do {
    candidateIds = engineNativeInstanceIdsForTab(
      tester,
      tabId: tabId,
      tabBoundSurfaceFamilies: tabBoundSurfaceFamilies,
    ).difference(existingInstanceIds);
    if (candidateIds.length == 1) {
      return candidateIds.single;
    }
    if (budget.expired) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  } while (!budget.expired);

  final rendererContractId = b25RendererContractIdForTabBoundFamilies(
    tabBoundSurfaceFamilies,
  );
  final orderedCandidateIds = candidateIds.toList()..sort();
  throw B25ResultFramePositioningFailure(
    'The shipped $workflowType creation completed, but the created instance '
    'did not expose its engine-native identity key.\n'
    'Expected: exactly one newly rendered engine-native identity key for tab '
    '"$tabId" (renderer "$rendererContractId") that was absent before '
    'creation.\n'
    'Actual: ${orderedCandidateIds.length} matching candidate(s): '
    '$orderedCandidateIds.',
  );
}
