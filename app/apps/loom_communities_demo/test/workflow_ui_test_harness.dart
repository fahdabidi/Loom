import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show
        currentCommunitySpecVersion,
        LoomWorkflowStateMachine,
        LoomWorkflowTransition;

import 'b25_workflow_row_selection.dart';
import 'walkthrough_wait.dart';

typedef _ShippedCommunityPackageLocation = ({
  String repositoryPath,
  String assetPath,
});

const _shippedCommunityPackageLocationsByExtensionId =
    <String, _ShippedCommunityPackageLocation>{
      'ext_garden_club': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
      ),
      'ext_camera_club': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
      ),
      'ext_neighborhood_book_club': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_BookClub_Example.jsonc',
      ),
      'ext_chess_club': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
      ),
      'ext_youth_soccer': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc',
      ),
      'ext_mosque': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_Mosque_Example.jsonc',
      ),
      'ext_ad_free_community': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc',
      ),
      'ext_cedar_commons_hoa': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
      ),
      'ext_data_portability_community': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc',
      ),
      'ext_member_social_space': (
        repositoryPath:
            'docs/references/communities/'
            'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
        assetPath:
            'packages/loom_communities_app_shell/assets/'
            'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
      ),
    };

bool hasShippedEvidencePackage(String extensionId) =>
    _shippedCommunityPackageLocationsByExtensionId.containsKey(extensionId);

Set<String> get shippedEvidencePackageExtensionIds =>
    _shippedCommunityPackageLocationsByExtensionId.keys.toSet();

({String repositoryPath, String assetPath})?
shippedEvidencePackageLocationForExtensionId(String extensionId) =>
    _shippedCommunityPackageLocationsByExtensionId[extensionId];

File? _repositoryFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$relativePath');
    if (file.existsSync()) return file;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return null;
}

Future<String> _readShippedCommunityPackageSource(
  _ShippedCommunityPackageLocation location,
) async {
  final repositoryFile = _repositoryFile(location.repositoryPath);
  if (repositoryFile != null) {
    return repositoryFile.readAsStringSync();
  }
  try {
    return await rootBundle.loadString(location.assetPath);
  } catch (error) {
    throw StateError(
      'Fixture not found: ${location.repositoryPath}. Bundled Flutter asset '
      '${location.assetPath} could not be loaded: $error',
    );
  }
}

Future<void> installShippedEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target, {
  ValueKey<String> openButtonKey = const ValueKey('add-community-button'),
}) async {
  final fixture = await writeEvidencePackagePair(target);
  await _installEvidencePackagePair(
    tester,
    fixture,
    openButtonKey: openButtonKey,
  );
}

Future<void> installMetadataEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target, {
  ValueKey<String> openButtonKey = const ValueKey('add-community-button'),
}) async {
  await _installEvidencePackagePair(
    tester,
    _writeMetadataEvidencePackagePair(target),
    openButtonKey: openButtonKey,
  );
}

/// Scrolls [finder] into view and fails at the attempted tap if it cannot
/// receive the resulting pointer event.
///
/// Flutter's [WidgetTester.tap] reports a missed hit test only as a warning.
/// Walkthroughs need the failure at the action that missed, rather than at the
/// unrelated postcondition which would otherwise fail afterwards.
///
/// [isFinderReadyForTap] shares the non-mutating part of this check with
/// walkthrough action discovery. Discovery must not tap or scroll a candidate
/// merely to learn whether it is available.
Future<void> tapWhenVisible(
  WidgetTester tester,
  Finder finder, {
  required String description,
  DateTime Function()? now,
}) async {
  final initialMatches = finder.evaluate();
  if (initialMatches.length != 1) {
    fail(
      'Walkthrough tap target "$description" must resolve to exactly one '
      'widget before it can be made visible; finder "$finder" found '
      '${initialMatches.length}.',
    );
  }

  await tester.ensureVisible(finder);

  final budget = WalkthroughWaitBudget(now: now);
  late _MissedTapHitTest lastMiss;
  do {
    // A route's transition IgnorePointer clears on a later frame. Pump in
    // bounded increments rather than using pumpAndSettle: some walkthrough
    // screens deliberately keep an animation running.
    await tester.pump(const Duration(milliseconds: 50));

    final matches = finder.evaluate();
    if (matches.length != 1) {
      fail(
        'Walkthrough tap target "$description" must continue to resolve to '
        'exactly one widget while waiting to tap; finder "$finder" found '
        '${matches.length}.',
      );
    }

    // The transition frame can also change a scrollable's layout. Re-apply
    // visibility after the frame so the subsequent hit test does not retain a
    // coordinate that was visible before the transition but is now off-screen.
    await tester.ensureVisible(finder);
    final visibleMatches = finder.evaluate();
    if (visibleMatches.length != 1) {
      fail(
        'Walkthrough tap target "$description" must continue to resolve to '
        'exactly one widget after it is made visible; finder "$finder" found '
        '${visibleMatches.length}.',
      );
    }

    final targetElement = visibleMatches.single;
    final targetRenderObject = targetElement.renderObject;
    if (targetRenderObject is! RenderBox) {
      fail(
        'Walkthrough tap target "$description" has no RenderBox while '
        'waiting to tap; finder "$finder" resolved to $targetRenderObject.',
      );
    }

    final targetView = targetElement.findAncestorWidgetOfExactType<View>();
    if (targetView == null) {
      fail(
        'Walkthrough tap target "$description" has no Flutter view for hit '
        'testing; finder "$finder" resolved to $targetRenderObject.',
      );
    }

    final hitTest = _tapTargetHitTest(
      tester: tester,
      finder: finder,
      targetElement: targetElement,
    );
    if (hitTest.targetWasHit) {
      await tester.tap(finder, warnIfMissed: false);
      return;
    }

    lastMiss = hitTest.miss;
  } while (!budget.expired);

  final outcome = lastMiss.isOutOfBounds
      ? 'The target is off-screen: ${lastMiss.location} is outside the root '
            'render bounds ${lastMiss.rootRenderViewSize} after ensureVisible.'
      : 'The target is inside the root render bounds but did not receive the '
            'pointer. It is obscured or cannot receive pointer events.';
  fail(
    'Walkthrough tap missed "$description" at ${lastMiss.location}. '
    'Waited ${formatWaitDuration(budget.elapsed)} for the target to become '
    'tappable. $outcome Hit-test path: ${lastMiss.hitTestPath}.',
  );
}

/// The reason a rendered action is, or is not, ready for a walkthrough tap.
///
/// A disabled action is deliberately distinct from an enabled action that
/// cannot receive a pointer. The former is a product answer; the latter can be
/// a transient route transition or a real obstruction that merits polling.
enum FinderTapReadinessState { ready, absent, ambiguous, disabled, notHittable }

/// The non-mutating tap-readiness inspection for a [Finder].
class FinderTapReadiness {
  const FinderTapReadiness._({required this.state, this.hitTestPath});

  final FinderTapReadinessState state;
  final String? hitTestPath;

  bool get isReady => state == FinderTapReadinessState.ready;

  bool get isPresentAndDisabled => state == FinderTapReadinessState.disabled;

  /// Human-readable diagnostic wording for one candidate action.
  String get description => switch (state) {
    FinderTapReadinessState.ready => 'present, enabled, tappable',
    FinderTapReadinessState.absent => 'absent',
    FinderTapReadinessState.ambiguous => 'not uniquely present',
    FinderTapReadinessState.disabled => 'present, disabled',
    FinderTapReadinessState.notHittable =>
      'present, enabled, not hittable'
          '${hitTestPath == null ? '' : ' (hit-test path: $hitTestPath)'}',
  };
}

/// Inspects why [finder] is, or is not, ready for a tap.
///
/// This only inspects the rendered tree; it never scrolls, pumps, taps, or
/// otherwise changes the current UI surface.
FinderTapReadiness inspectFinderTapReadiness(
  WidgetTester tester,
  Finder finder,
) {
  final matches = finder.evaluate();
  if (matches.isEmpty) {
    return const FinderTapReadiness._(state: FinderTapReadinessState.absent);
  }
  if (matches.length != 1) {
    return const FinderTapReadiness._(state: FinderTapReadinessState.ambiguous);
  }
  if (!_finderHasEnabledTapHandler(finder)) {
    return const FinderTapReadiness._(state: FinderTapReadinessState.disabled);
  }
  final targetElement = matches.single;
  if (targetElement.renderObject is! RenderBox ||
      targetElement.findAncestorWidgetOfExactType<View>() == null) {
    return const FinderTapReadiness._(
      state: FinderTapReadinessState.notHittable,
      hitTestPath: 'target has no RenderBox or Flutter view',
    );
  }
  final hitTest = _tapTargetHitTest(
    tester: tester,
    finder: finder,
    targetElement: targetElement,
  );
  if (hitTest.targetWasHit) {
    return const FinderTapReadiness._(state: FinderTapReadinessState.ready);
  }
  return FinderTapReadiness._(
    state: FinderTapReadinessState.notHittable,
    hitTestPath: hitTest.miss.hitTestPath,
  );
}

/// Returns whether [finder] resolves to one enabled control that can receive
/// a pointer at its current location.
///
/// Kept as the boolean compatibility API for existing walkthrough callers;
/// new action-selection code should use [inspectFinderTapReadiness] when its
/// outcome must distinguish a disabled control from an obstruction.
bool isFinderReadyForTap(WidgetTester tester, Finder finder) =>
    inspectFinderTapReadiness(tester, finder).isReady;

/// Makes a speed-dial child creation FAB actionable when it is mounted but
/// still hidden behind the dial's [IgnorePointer].
///
/// A mounted child is deliberately not enough here: a closed dial keeps its
/// children in the tree at zero opacity, so an existence check would skip the
/// only required preparation step and the later tap would miss. This performs
/// at most one explicit opener tap. It does not poll or invent a recovery
/// path; either the visible opener is tappable and exposes this exact child,
/// or the caller gets a named failure at the preparation boundary.
Future<void> prepareCreatableFabForTap({
  required WidgetTester tester,
  required Finder createFab,
  required Finder speedDial,
  required String workflowType,
  required String roleId,
}) async {
  if (isFinderReadyForTap(tester, createFab)) {
    return;
  }

  final openerReadiness = inspectFinderTapReadiness(tester, speedDial);
  if (!openerReadiness.isReady) {
    fail(
      'Shipped $workflowType create FAB preparation failed for $roleId: '
      'target creatable-fab-$workflowType was not tappable and speed-dial '
      'opener creatable-fab-speed-dial was not tappable '
      '(${openerReadiness.hitTestPath}).',
    );
  }

  await tester.tap(speedDial, warnIfMissed: false);
  await tester.pumpAndSettle();

  final targetReadiness = inspectFinderTapReadiness(tester, createFab);
  if (!targetReadiness.isReady) {
    fail(
      'Shipped $workflowType create FAB preparation failed for $roleId: '
      'speed-dial opener creatable-fab-speed-dial was tapped once, but '
      'target creatable-fab-$workflowType did not become tappable '
      '(${targetReadiness.hitTestPath}).',
    );
  }
}

/// A named primary-action candidate and the precise finder scoped to its
/// current workflow surface.
class PrimaryActionCandidate<T> {
  const PrimaryActionCandidate({
    required this.value,
    required this.finder,
    required this.description,
  });

  final T value;
  final Finder finder;
  final String description;
}

/// One candidate's latest readiness result during a primary-action poll.
class PrimaryActionCandidateReadiness<T> {
  const PrimaryActionCandidateReadiness({
    required this.candidate,
    required this.readiness,
  });

  final PrimaryActionCandidate<T> candidate;
  final FinderTapReadiness readiness;

  String get description =>
      '${candidate.description}: ${readiness.description}';
}

/// The result of a bounded primary-action availability wait.
class PrimaryActionAvailability<T> {
  const PrimaryActionAvailability._({
    required this.candidateReadiness,
    required this.budget,
    this.candidate,
  });

  final List<PrimaryActionCandidateReadiness<T>> candidateReadiness;
  final WalkthroughWaitBudget budget;
  final PrimaryActionCandidate<T>? candidate;

  bool get hasReadyAction => candidate != null;

  /// Every expected primary control is visibly present and deliberately
  /// disabled. Waiting cannot make this product decision actionable.
  bool get allCandidatesPresentAndDisabled =>
      candidateReadiness.isNotEmpty &&
      candidateReadiness.every(
        (candidate) => candidate.readiness.isPresentAndDisabled,
      );

  String get candidateDescriptions =>
      candidateReadiness.map((candidate) => candidate.description).join(', ');
}

/// The two explicit Calendar preparation states that precede action polling.
///
/// An agenda row merely says the event is listed. Its detail card owns the
/// action controls, so it must be selected before an action finder can have a
/// meaningful absent/present result. This deliberately models only the
/// Calendar surface; callers must not use it as permission to tap an arbitrary
/// instance on a generic list or Marketplace surface.
class CalendarActionSurfacePreparation {
  const CalendarActionSurfacePreparation._({
    required this.instanceId,
    required this.isCalendarSurface,
    required this.agendaEntryMatchCount,
    required this.selectedDetailMatchCount,
  });

  final String instanceId;
  final bool isCalendarSurface;
  final int agendaEntryMatchCount;
  final int selectedDetailMatchCount;

  bool get agendaEntryPresent => agendaEntryMatchCount == 1;

  bool get selectedDetailPresent => selectedDetailMatchCount == 1;

  bool get isReadyForActionPolling =>
      !isCalendarSurface || (agendaEntryPresent && selectedDetailPresent);

  /// A per-instance diagnostic that keeps the three distinct Calendar states
  /// legible alongside the per-candidate readiness results.
  String get diagnosticDescription {
    if (!isCalendarSurface) return 'not a Calendar surface';
    return 'calendar instance $instanceId: agenda entry present? '
        '${agendaEntryPresent ? 'yes' : 'no (matches: $agendaEntryMatchCount)'}; '
        'selected detail present? '
        '${selectedDetailPresent ? 'yes' : 'no (matches: $selectedDetailMatchCount)'}';
  }

  /// A missing Calendar agenda entry is a shipped-surface finding, not an
  /// invitation to try a generic instance tap. It is not an unavailable
  /// action result: action polling has no prepared surface on which to make
  /// that product determination.
  String? get preparationFailureDescription {
    if (!isCalendarSurface || isReadyForActionPolling) return null;
    if (!agendaEntryPresent) {
      return 'calendar agenda entry is absent or '
          'ambiguous; action candidates were not polled and no blind instance '
          'tap was attempted. '
          '$diagnosticDescription.';
    }
    return 'tapping the calendar agenda entry did '
        'not produce its selected detail, so action candidates were not '
        'polled. $diagnosticDescription.';
  }
}

/// The explicit conclusion of a prepared action poll.
///
/// A preparation or action-load failure means the walkthrough did not receive
/// a product answer. Only a prepared surface whose action load finished
/// without an exception can establish that every declared action is absent.
enum PreparedActionPollingDecision { keepWaiting, unavailable, stall }

/// Makes the narrow product-answer distinction used by shipped walkthroughs.
///
/// Disabled controls and a ready supplementary action remain direct evidence
/// of a product answer. A wholly absent action set needs the stronger proof
/// that its surface was prepared and that the action request completed
/// successfully; without that proof, absence could simply be a loading or
/// surface failure.
PreparedActionPollingDecision classifyPreparedActionPolling({
  required bool surfacePrepared,
  required bool actionLoadSucceeded,
  required bool actionLoadFailed,
  required bool allPrimaryCandidatesPresentAndDisabled,
  required bool allActionCandidatesAbsent,
  required bool anyOtherTappable,
}) {
  if (!surfacePrepared || actionLoadFailed) {
    return PreparedActionPollingDecision.stall;
  }
  if (allPrimaryCandidatesPresentAndDisabled || anyOtherTappable) {
    return PreparedActionPollingDecision.unavailable;
  }
  if (actionLoadSucceeded && allActionCandidatesAbsent) {
    return PreparedActionPollingDecision.unavailable;
  }
  return PreparedActionPollingDecision.keepWaiting;
}

/// Whether every declared action finder is currently absent.
///
/// The caller supplies every transition in the action machine, not merely the
/// required primary. This makes an actionless result a fact about a completed
/// load rather than an inference from one missing button.
bool actionFindersAreAllAbsent(Iterable<Finder> actionFinders) =>
    actionFinders.isNotEmpty &&
    actionFinders.every((finder) => finder.evaluate().isEmpty);

/// Returns the Calendar agenda entry whose key is emitted by
/// `part28_engine_native_calendar_surface.dart`.
///
/// The final segment is the binding index, not an invariant `0`; matching the
/// `instanceId-` prefix derives that segment from the rendered Calendar rather
/// than hardcoding a fixture's key shape.
Finder calendarAgendaEntryFinder(String instanceId) =>
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('engine-native-calendar-agenda-$instanceId-');
    }, description: 'calendar agenda entry for $instanceId');

/// Returns the selected Calendar detail whose key is emitted for [instanceId].
Finder calendarSelectedDetailFinder(String instanceId) =>
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith(
            'engine-native-calendar-selected-detail-$instanceId-',
          );
    }, description: 'selected calendar detail for $instanceId');

/// Selects a Calendar agenda row before action polling and records both
/// preparation states for the eventual action diagnostic.
///
/// Selection is intentionally limited to the Calendar tab. A missing agenda
/// entry returns an explicit preparation finding without touching any other
/// instance-shaped widget. A present agenda entry is tapped through
/// [tapWhenVisible], then its selected detail is asserted by its own rendered
/// key before candidates are allowed to be inspected.
Future<CalendarActionSurfacePreparation>
prepareCalendarActionSurfaceForActionPolling({
  required WidgetTester tester,
  required Finder surface,
  required String tabId,
  required String instanceId,
}) async {
  if (tabId != 'calendar') {
    return CalendarActionSurfacePreparation._(
      instanceId: instanceId,
      isCalendarSurface: false,
      agendaEntryMatchCount: 0,
      selectedDetailMatchCount: 0,
    );
  }

  final agendaEntry = find.descendant(
    of: surface,
    matching: calendarAgendaEntryFinder(instanceId),
  );
  final agendaEntryMatchCount = agendaEntry.evaluate().length;
  if (agendaEntryMatchCount != 1) {
    return CalendarActionSurfacePreparation._(
      instanceId: instanceId,
      isCalendarSurface: true,
      agendaEntryMatchCount: agendaEntryMatchCount,
      selectedDetailMatchCount: find
          .descendant(
            of: surface,
            matching: calendarSelectedDetailFinder(instanceId),
          )
          .evaluate()
          .length,
    );
  }

  await tapWhenVisible(
    tester,
    agendaEntry,
    description: 'calendar agenda entry for $instanceId before action polling',
  );
  await tester.pump();

  final selectedDetailMatchCount = find
      .descendant(
        of: surface,
        matching: calendarSelectedDetailFinder(instanceId),
      )
      .evaluate()
      .length;
  return CalendarActionSurfacePreparation._(
    instanceId: instanceId,
    isCalendarSurface: true,
    agendaEntryMatchCount: agendaEntryMatchCount,
    selectedDetailMatchCount: selectedDetailMatchCount,
  );
}

/// The explicit Marketplace detail route owned by one action-polling pass.
///
/// Marketplace action controls live in an instance-qualified detail dialog,
/// while the controls inside that dialog intentionally omit the instance id.
/// Keeping the exact dialog finder here gives the caller a single surface to
/// poll and a matching close control to own during cleanup.
class MarketplaceActionSurfacePreparation {
  const MarketplaceActionSurfacePreparation._({
    required this.instanceId,
    required this.isMarketplaceSurface,
    required this.listingTapMatchCount,
    required this.detailDialogMatchCount,
    required this.actionSurface,
  });

  final String instanceId;
  final bool isMarketplaceSurface;
  final int listingTapMatchCount;
  final int detailDialogMatchCount;

  /// The marketplace dialog for this instance, or the unchanged caller
  /// surface when this is not a Marketplace tab.
  final Finder actionSurface;

  bool get listingTapPresent => listingTapMatchCount == 1;

  bool get detailDialogPresent => detailDialogMatchCount == 1;

  bool get isReadyForActionPolling =>
      !isMarketplaceSurface || (listingTapPresent && detailDialogPresent);

  /// Per-instance Marketplace preparation evidence. The action poll appends
  /// its per-candidate readiness to this exact prefix so a stall report can
  /// distinguish unopened detail from a genuinely actionless detail.
  String get diagnosticDescription {
    if (!isMarketplaceSurface) return 'not a Marketplace surface';
    return 'marketplace instance $instanceId: listing tap present? '
        '${listingTapPresent ? 'yes' : 'no (matches: $listingTapMatchCount)'}; '
        'detail dialog present? '
        '${detailDialogPresent ? 'yes' : 'no (matches: $detailDialogMatchCount)'}';
  }

  /// A failed Marketplace preparation is a surface finding, never permission
  /// to poll the tile behind it or classify a missing action as unavailable.
  String? get preparationFailureDescription {
    if (!isMarketplaceSurface || isReadyForActionPolling) return null;
    if (!listingTapPresent) {
      return 'marketplace listing tap is absent or ambiguous; action '
          'candidates were not polled and no blind instance tap was '
          'attempted. $diagnosticDescription.';
    }
    return 'tapping the marketplace listing did not produce its detail '
        'dialog, so action candidates were not polled. '
        '$diagnosticDescription.';
  }
}

/// The observed state of a Marketplace detail's action request.
enum MarketplaceActionLoadState { notApplicable, loading, succeeded, failed }

class MarketplaceActionLoadInspection {
  const MarketplaceActionLoadInspection._({
    required this.state,
    this.diagnostic,
  });

  final MarketplaceActionLoadState state;
  final String? diagnostic;

  bool get hasSucceeded => state == MarketplaceActionLoadState.succeeded;

  bool get hasFailed => state == MarketplaceActionLoadState.failed;
}

/// The exact instance-qualified listing control emitted by the native
/// Marketplace surface.
Finder marketplaceListingTapFinder(String instanceId) =>
    find.byKey(ValueKey('marketplace-listing-tap-$instanceId'));

/// The exact instance-qualified Marketplace dialog emitted after its listing
/// control is tapped.
Finder marketplaceDetailDialogFinder(String instanceId) =>
    find.byKey(ValueKey('marketplace-detail-dialog-$instanceId'));

/// The dialog-owned close control emitted by the native Marketplace surface.
Finder marketplaceDetailCloseFinder(String instanceId) =>
    find.byKey(ValueKey('marketplace-detail-close-$instanceId'));

/// Finds a detail action by its Marketplace key shape, never by the instance
/// id that only exists on the tile beneath the modal barrier.
///
/// Equipment-loan's contextual borrow control is intentionally distinct from
/// the normal `marketplace-action-<transition>` row key. Both forms are read
/// from `part36_engine_native_marketplace_surface.dart`.
Finder marketplaceDetailActionFinder(String transitionId) =>
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          (key.value == 'marketplace-action-$transitionId' ||
              (transitionId == 'borrow' &&
                  key.value == 'marketplace-transition-fab-borrow'));
    }, description: 'marketplace detail action $transitionId');

/// Returns a rendered action-load exception without changing the surface.
///
/// Calendar, Marketplace, and generic cards use existing visible error copy
/// rather than a harness-only key. Retaining the actual message in a stall
/// distinguishes a failed request from an empty successful action response.
String? visibleActionLoadDiagnostic(Finder surface) {
  final errors = find.descendant(
    of: surface,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data?.trim().startsWith('Could not load ') ?? false),
      description: 'rendered action-load diagnostic',
    ),
  );
  for (final element in errors.evaluate()) {
    final text = (element.widget as Text).data?.trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

/// Inspects the action request inside an exact Marketplace detail without
/// changing the surface. The rendered progress and error states are the
/// platform contract: a missing action means "guarded off" only after neither
/// state is present.
MarketplaceActionLoadInspection inspectMarketplaceActionLoad({
  required MarketplaceActionSurfacePreparation preparation,
}) {
  if (!preparation.isMarketplaceSurface ||
      !preparation.isReadyForActionPolling) {
    return const MarketplaceActionLoadInspection._(
      state: MarketplaceActionLoadState.notApplicable,
    );
  }
  final detail = preparation.actionSurface;
  final diagnostic = visibleActionLoadDiagnostic(detail);
  if (diagnostic != null) {
    return MarketplaceActionLoadInspection._(
      state: MarketplaceActionLoadState.failed,
      diagnostic: diagnostic,
    );
  }
  final progress = find.descendant(
    of: detail,
    matching: find.byKey(
      ValueKey('equipment-loan-progress-${preparation.instanceId}'),
    ),
  );
  if (progress.evaluate().isNotEmpty) {
    return const MarketplaceActionLoadInspection._(
      state: MarketplaceActionLoadState.loading,
    );
  }
  return const MarketplaceActionLoadInspection._(
    state: MarketplaceActionLoadState.succeeded,
  );
}

/// Explains the particular Giveaway denial whose formula says a member cannot
/// claim their own listing. The test harness has the package transition and
/// seeded identity in hand, so this is factual evidence rather than a guess
/// based on an absent button.
String? describeOwnedGiveawayFormulaDenial({
  required String transitionId,
  required Map<String, dynamic> instanceData,
  required String actorId,
  required String? guardFormula,
}) {
  final normalizedFormula = guardFormula?.replaceAll(RegExp(r'\s+'), '');
  if (transitionId != 'claim-giveaway' ||
      instanceData['ownerFanId']?.toString() != actorId ||
      normalizedFormula?.contains(r'ownerFanId==$actor') != true) {
    return null;
  }
  return 'claim-giveaway unavailable: the actor owns this giveaway '
      '(ownerFanId == \$actor), so the transition\'s guard formula denies it. '
      'Surface prepared, actions loaded.';
}

/// Opens the exact Marketplace listing before action polling.
///
/// This is deliberately narrower than Calendar selection: only the
/// Marketplace tab is allowed to use the listing's named detail affordance.
/// A missing listing or a listing that does not produce its exact dialog is a
/// loud shipped-surface failure, never permission to tap an arbitrary widget
/// that happens to contain an instance id.
Future<MarketplaceActionSurfacePreparation>
prepareMarketplaceActionSurfaceForActionPolling({
  required WidgetTester tester,
  required Finder surface,
  required String tabId,
  required String instanceId,
}) async {
  if (tabId != 'marketplace') {
    return MarketplaceActionSurfacePreparation._(
      instanceId: instanceId,
      isMarketplaceSurface: false,
      listingTapMatchCount: 0,
      detailDialogMatchCount: 0,
      actionSurface: surface,
    );
  }

  final listing = find.descendant(
    of: surface,
    matching: marketplaceListingTapFinder(instanceId),
  );
  final listingTapMatchCount = listing.evaluate().length;
  if (listingTapMatchCount != 1) {
    return MarketplaceActionSurfacePreparation._(
      instanceId: instanceId,
      isMarketplaceSurface: true,
      listingTapMatchCount: listingTapMatchCount,
      detailDialogMatchCount: marketplaceDetailDialogFinder(
        instanceId,
      ).evaluate().length,
      actionSurface: marketplaceDetailDialogFinder(instanceId),
    );
  }
  await tapWhenVisible(
    tester,
    listing,
    description: 'marketplace listing $instanceId before action polling',
  );
  await tester.pump();

  final dialog = marketplaceDetailDialogFinder(instanceId);
  return MarketplaceActionSurfacePreparation._(
    instanceId: instanceId,
    isMarketplaceSurface: true,
    listingTapMatchCount: listingTapMatchCount,
    detailDialogMatchCount: dialog.evaluate().length,
    actionSurface: dialog,
  );
}

/// Closes a detail dialog opened by
/// [prepareMarketplaceActionSurfaceForActionPolling] and proves that its
/// original community surface is current again.
///
/// A state-changing listing action may itself remove the detail route (for
/// example, a giveaway removed from the tile grid). That is not silently
/// recovered: the method still proves the dialog is gone and the original
/// surface is current. When the dialog remains, this walkthrough always uses
/// its own instance-qualified Close control rather than a generic back action.
Future<bool> closeMarketplaceActionSurfaceAfterActionPolling({
  required WidgetTester tester,
  required MarketplaceActionSurfacePreparation preparation,
  required Finder expectedSurface,
}) async {
  if (!preparation.isMarketplaceSurface) return false;

  final dialog = marketplaceDetailDialogFinder(preparation.instanceId);
  var closedWithOwnedControl = false;
  if (dialog.evaluate().isNotEmpty) {
    expect(
      dialog,
      findsOneWidget,
      reason:
          'Marketplace action polling for ${preparation.instanceId} left an '
          'ambiguous detail dialog before cleanup.',
    );
    final close = find.descendant(
      of: dialog,
      matching: marketplaceDetailCloseFinder(preparation.instanceId),
    );
    expect(
      close,
      findsOneWidget,
      reason:
          'Marketplace detail dialog ${preparation.instanceId} must expose '
          'its own marketplace-detail-close-${preparation.instanceId} '
          'control for walkthrough cleanup.',
    );
    await tapWhenVisible(
      tester,
      close,
      description:
          'marketplace detail close for ${preparation.instanceId} after '
          'action polling',
    );
    closedWithOwnedControl = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  expect(
    dialog,
    findsNothing,
    reason:
        'Marketplace detail dialog ${preparation.instanceId} remained open '
        'after its owned cleanup.',
  );
  final currentExpectedSurfaces = expectedSurface
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
      .toList(growable: false);
  expect(
    currentExpectedSurfaces,
    hasLength(1),
    reason:
        'Marketplace detail cleanup for ${preparation.instanceId} did not '
        'restore the expected community surface before its row returned.',
  );
  return closedWithOwnedControl;
}

/// Polls primary action candidates without turning a disabled product answer
/// into a three-minute stall.
///
/// An enabled but unhittable action retains the existing bounded polling path.
/// [timeout] and [now] exist for deterministic unit coverage; device
/// walkthroughs intentionally use the default inner wait budget.
Future<PrimaryActionAvailability<T>> waitForPrimaryActionAvailability<T>({
  required WidgetTester tester,
  required List<PrimaryActionCandidate<T>> candidates,
  Duration? timeout,
  DateTime Function()? now,
  void Function(PrimaryActionAvailability<T> availability)? onPoll,
  bool Function(PrimaryActionAvailability<T> availability)? shouldStopWaiting,
}) async {
  final budget = WalkthroughWaitBudget(timeout: timeout, now: now);
  late PrimaryActionAvailability<T> availability;
  do {
    final candidateReadiness = <PrimaryActionCandidateReadiness<T>>[];
    PrimaryActionCandidate<T>? readyCandidate;
    for (final candidate in candidates) {
      final readiness = PrimaryActionCandidateReadiness(
        candidate: candidate,
        readiness: await prepareFinderForTapReadiness(
          tester: tester,
          finder: candidate.finder,
        ),
      );
      candidateReadiness.add(readiness);
      if (readyCandidate == null && readiness.readiness.isReady) {
        readyCandidate = candidate;
      }
    }
    availability = PrimaryActionAvailability._(
      candidateReadiness: candidateReadiness,
      budget: budget,
      candidate: readyCandidate,
    );
    onPoll?.call(availability);
    if (availability.hasReadyAction ||
        availability.allCandidatesPresentAndDisabled) {
      return availability;
    }
    if (shouldStopWaiting?.call(availability) ?? false) {
      return availability;
    }

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  } while (!budget.expired);
  return availability;
}

/// Prepares one uniquely rendered candidate for a non-mutating readiness
/// inspection.
///
/// A hit test uses the target's current screen coordinates. A control below a
/// scrollable's fold is therefore preparable rather than unreachable. Both the
/// bounded primary poll and the one-shot fallback probe use this helper so a
/// missing primary does not skip viewport preparation for the actions that
/// remain. Callers deliberately invoke it inside their candidate loops: route
/// and scroll layout can move a control between inspections.
Future<FinderTapReadiness> prepareFinderForTapReadiness({
  required WidgetTester tester,
  required Finder finder,
}) async {
  if (finder.evaluate().length == 1) {
    await tester.ensureVisible(finder);
  }
  return inspectFinderTapReadiness(tester, finder);
}

/// Finds every candidate on [surface] that is enabled and can receive a
/// pointer after its viewport has been prepared.
///
/// This is deliberately not an existence check and it never taps or dismisses
/// anything. An empty result says no candidate was prepared and hittable; the
/// B25 caller must retain its explicit stall outcome rather than silently
/// classifying that fact as an actionless product state.
Future<List<PrimaryActionCandidate<T>>> findReadyActionCandidatesOnSurface<T>({
  required WidgetTester tester,
  required Finder surface,
  required Iterable<PrimaryActionCandidate<T>> candidates,
}) async {
  final readyCandidates = <PrimaryActionCandidate<T>>[];
  for (final candidate in candidates) {
    final onSurface = find.descendant(of: surface, matching: candidate.finder);
    final readiness = await prepareFinderForTapReadiness(
      tester: tester,
      finder: onSurface,
    );
    if (readiness.isReady) {
      readyCandidates.add(
        PrimaryActionCandidate(
          value: candidate.value,
          finder: onSurface,
          description: candidate.description,
        ),
      );
    }
  }
  return readyCandidates;
}

/// States the prepared fallback result without promoting it to semantic proof.
///
/// A non-empty result lets the caller report the action that was truly found.
/// An empty result deliberately returns null, leaving the caller to preserve
/// its bounded stall failure for the distinct "nothing was tappable" case.
String? describePreparedFallbackAvailability({
  required String primaryUnavailableDescription,
  required Iterable<String> preparedActionDescriptions,
  required String documentedPrimaryRequirementDescription,
}) {
  final actions = preparedActionDescriptions
      .map((description) => description.trim())
      .where((description) => description.isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (actions.isEmpty) return null;
  final actionList = switch (actions.length) {
    1 => actions.single,
    2 => '${actions.first} and ${actions.last}',
    _ => '${actions.take(actions.length - 1).join(', ')} and ${actions.last}',
  };
  return '$primaryUnavailableDescription Other available actions include '
      '$actionList. The $documentedPrimaryRequirementDescription was not '
      'exercised.';
}

/// Waits for [finder] to resolve to one enabled control that can receive a
/// pointer. The readiness predicate itself remains a one-shot inspection; this
/// caller owns the bounded pumping and visibility work needed at a transition
/// boundary.
///
/// A route transition can change both hit testing and scroll layout between
/// frames. Re-applying [WidgetTester.ensureVisible] after every bounded pump
/// therefore matters just as it does for [tapWhenVisible].
Future<({bool isReady, Duration elapsed})> waitForFinderReadyForTap(
  WidgetTester tester,
  Finder finder, {
  DateTime Function()? now,
  VoidCallback? onReadinessPoll,
}) async {
  final budget = WalkthroughWaitBudget(now: now);
  do {
    onReadinessPoll?.call();
    // Do not use pumpAndSettle here: the walkthrough intentionally permits
    // continuously animated screens, while this check needs a bounded wait.
    await tester.pump(const Duration(milliseconds: 50));

    // A route can still be constructing its control while it transitions. In
    // that case there is nothing to make visible on this frame; keep polling.
    if (finder.evaluate().length != 1) {
      continue;
    }

    await tester.ensureVisible(finder);
    if (isFinderReadyForTap(tester, finder)) {
      return (isReady: true, elapsed: budget.elapsed);
    }
  } while (!budget.expired);
  return (isReady: false, elapsed: budget.elapsed);
}

/// Finds the first action candidate that is both inside [surface] and ready to
/// receive a pointer. In particular, controls remaining in the tree behind a
/// modal route do not count as available actions.
Future<Finder?> firstReadyActionOnSurface({
  required WidgetTester tester,
  required Finder surface,
  required Iterable<Finder> candidates,
}) async {
  final readyCandidates = await findReadyActionCandidatesOnSurface(
    tester: tester,
    surface: surface,
    candidates: [
      for (final candidate in candidates)
        PrimaryActionCandidate(
          value: candidate,
          finder: candidate,
          description: candidate.describeMatch(Plurality.one),
        ),
    ],
  );
  return readyCandidates.isEmpty ? null : readyCandidates.first.finder;
}

/// Requires the expected community route and its actor picker at a B25 row
/// boundary. A dialog or a different route is a failed row, never something
/// the walkthrough silently dismisses.
Future<void> assertB25CommunityRowSurface({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required String workflowId,
  required String role,
  required String boundary,
  required Future<void> Function(String name) captureDiagnostic,
  DateTime Function()? now,
  VoidCallback? onReadinessPoll,
}) async {
  final expectedSurface = _evidenceTargetRoute(target);
  final picker = find.descendant(
    of: expectedSurface,
    matching: find.byKey(const ValueKey('actor-identity-picker-button')),
  );
  final entryGate = find.descendant(
    of: expectedSurface,
    matching: find.byKey(const ValueKey('community-entry-gate')),
  );
  final initialUnexpectedSurface = _currentUnexpectedB25SurfaceDescription(
    expectedExtensionId: target.extensionId,
  );
  if (initialUnexpectedSurface != null) {
    await _failB25SurfaceMismatch(
      target: target,
      workflowId: workflowId,
      role: role,
      boundary: boundary,
      foundSurface: initialUnexpectedSurface,
      captureDiagnostic: captureDiagnostic,
    );
  }

  // An engine-native community's known entry gate intentionally comes before
  // its actor picker. selectActorIdentity handles that state by creating the
  // evidence account, so a current expected route containing this scoped gate
  // is already a valid row-entry surface. This does not accept an unexpected
  // dialog or another community: those are rejected above before this return.
  if (_isExpectedB25CommunitySurfaceCurrent(expectedSurface) &&
      entryGate.evaluate().isNotEmpty) {
    return;
  }

  // The expected route is correct while a transition's IgnorePointer or
  // AnimatedOpacity briefly leaves its picker un-hittable. Poll that distinct
  // readiness condition instead of sampling a single transition frame.
  final pickerReadiness = await waitForFinderReadyForTap(
    tester,
    picker,
    now: now,
    onReadinessPoll: onReadinessPoll,
  );
  if (pickerReadiness.isReady &&
      _isExpectedB25CommunitySurfaceCurrent(expectedSurface)) {
    return;
  }

  final unexpectedSurface = _currentUnexpectedB25SurfaceDescription(
    expectedExtensionId: target.extensionId,
  );
  if (unexpectedSurface != null ||
      !_isExpectedB25CommunitySurfaceCurrent(expectedSurface)) {
    await _failB25SurfaceMismatch(
      target: target,
      workflowId: workflowId,
      role: role,
      boundary: boundary,
      foundSurface:
          unexpectedSurface ??
          _unexpectedCommunitySurfaceDescription(
            expectedExtensionId: target.extensionId,
            expectedSurface: expectedSurface,
            picker: picker,
          ),
      captureDiagnostic: captureDiagnostic,
    );
  }

  await _failB25PickerNeverBecameInteractable(
    target: target,
    workflowId: workflowId,
    role: role,
    boundary: boundary,
    waited: pickerReadiness.elapsed,
    hitTestPath: _hitTestPathForFinder(tester, picker),
    captureDiagnostic: captureDiagnostic,
  );
}

bool _isExpectedB25CommunitySurfaceCurrent(Finder expectedSurface) =>
    expectedSurface
        .evaluate()
        .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
        .length ==
    1;

/// Returns an immediately actionable surface mismatch. A keyed current dialog
/// or a different current community is not a healthy transition frame and
/// must never be waited out or dismissed by the walkthrough.
String? _currentUnexpectedB25SurfaceDescription({
  required String expectedExtensionId,
}) {
  final currentDialogKeys = find
      .byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.contains('dialog');
      }, description: 'current dialog surface')
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
      .map((element) => (element.widget.key! as ValueKey<String>).value)
      .toList(growable: false);
  if (currentDialogKeys.isNotEmpty) return currentDialogKeys.first;

  final unexpectedCommunitySurfaces = find
      .byType(LocalExtensionScreen)
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
      .map(
        (element) =>
            'local-extension-${(element.widget as LocalExtensionScreen).community.extensionId}',
      )
      .where((surface) => surface != 'local-extension-$expectedExtensionId')
      .toList(growable: false);
  if (unexpectedCommunitySurfaces.isNotEmpty) {
    return unexpectedCommunitySurfaces.first;
  }
  return null;
}

Future<void> _failB25SurfaceMismatch({
  required LoomEvidenceTarget target,
  required String workflowId,
  required String role,
  required String boundary,
  required String foundSurface,
  required Future<void> Function(String name) captureDiagnostic,
}) async {
  final diagnosticName =
      '${target.phase}_${target.extensionId}_${workflowId}_${role}_'
      'SURFACE_MISMATCH_${boundary.toUpperCase()}';
  try {
    await captureDiagnostic(diagnosticName);
  } catch (error) {
    fail(
      'B25 surface mismatch $boundary $workflowId/$role:\n'
      'expected community ${target.extensionId};\n'
      'found $foundSurface.\n'
      'Additionally failed to capture diagnostic frame $diagnosticName: '
      '$error',
    );
  }
  fail(
    'B25 surface mismatch $boundary $workflowId/$role:\n'
    'expected community ${target.extensionId};\n'
    'found $foundSurface.',
  );
}

Future<void> _failB25PickerNeverBecameInteractable({
  required LoomEvidenceTarget target,
  required String workflowId,
  required String role,
  required String boundary,
  required Duration waited,
  required String hitTestPath,
  required Future<void> Function(String name) captureDiagnostic,
}) async {
  const pickerName = 'actor-identity-picker-button';
  final diagnosticName =
      '${target.phase}_${target.extensionId}_${workflowId}_${role}_'
      'PICKER_NOT_INTERACTABLE_${boundary.toUpperCase()}';
  final message =
      'B25 actor identity picker never became interactable $boundary '
      '$workflowId/$role:\n'
      'community ${target.extensionId} remained current;\n'
      'picker $pickerName never became tappable.\n'
      'Waited ${formatWaitDuration(waited)} for the picker to become tappable.\n'
      'Hit-test path: $hitTestPath.';
  try {
    await captureDiagnostic(diagnosticName);
  } catch (error) {
    fail(
      '$message\n'
      'Additionally failed to capture diagnostic frame $diagnosticName: '
      '$error',
    );
  }
  fail(message);
}

/// Returns the final rendered hit-test path for a non-interactable finder.
///
/// The B25 picker diagnostic uses this after its bounded readiness poll has
/// expired, matching [tapWhenVisible]'s failure evidence. It deliberately
/// remains diagnostic-only: this inspection neither taps nor dismisses a
/// surface.
String _hitTestPathForFinder(WidgetTester tester, Finder finder) {
  final matches = finder.evaluate();
  if (matches.length != 1) {
    return 'picker resolved to ${matches.length} widgets';
  }
  return _tapTargetHitTest(
    tester: tester,
    finder: finder,
    targetElement: matches.single,
  ).miss.hitTestPath;
}

String _unexpectedCommunitySurfaceDescription({
  required String expectedExtensionId,
  required Finder expectedSurface,
  required Finder picker,
}) {
  final currentDialogKeys = find
      .byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.contains('dialog');
      }, description: 'current dialog surface')
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
      .map((element) => (element.widget.key! as ValueKey<String>).value)
      .toList(growable: false);
  if (currentDialogKeys.isNotEmpty) return currentDialogKeys.first;

  final currentCommunitySurfaces = find
      .byType(LocalExtensionScreen)
      .evaluate()
      .where((element) => ModalRoute.of(element)?.isCurrent ?? false)
      .map(
        (element) =>
            'local-extension-${(element.widget as LocalExtensionScreen).community.extensionId}',
      )
      .toList(growable: false);
  if (currentCommunitySurfaces.isNotEmpty) {
    return currentCommunitySurfaces.first;
  }
  if (find.byType(ModalBarrier).evaluate().isNotEmpty) {
    return 'modal-barrier';
  }
  if (expectedSurface.evaluate().isEmpty) {
    return 'no-local-extension-$expectedExtensionId';
  }
  if (picker.evaluate().isEmpty) {
    return 'actor-identity-picker-missing';
  }
  return 'unexpected-route-or-overlay';
}

bool _finderHasEnabledTapHandler(Finder finder) {
  if (finder.evaluate().any((element) => _isEnabledTapWidget(element.widget))) {
    return true;
  }
  return find
      .descendant(
        of: finder,
        matching: find.byWidgetPredicate(_isEnabledTapWidget),
      )
      .evaluate()
      .isNotEmpty;
}

bool _isEnabledTapWidget(Widget widget) {
  if (widget is ButtonStyleButton) return widget.onPressed != null;
  if (widget is IconButton) return widget.onPressed != null;
  if (widget is InputChip) return widget.onPressed != null;
  if (widget is RawMaterialButton) return widget.onPressed != null;
  if (widget is InkWell) {
    return widget.onTap != null || widget.onDoubleTap != null;
  }
  if (widget is GestureDetector) {
    return widget.onTap != null || widget.onDoubleTap != null;
  }
  if (widget is ListTile) return widget.onTap != null;
  return false;
}

_TapTargetHitTest _tapTargetHitTest({
  required WidgetTester tester,
  required Finder finder,
  required Element targetElement,
}) {
  final targetRenderObject = targetElement.renderObject;
  final targetView = targetElement.findAncestorWidgetOfExactType<View>();
  if (targetRenderObject is! RenderBox || targetView == null) {
    return const _TapTargetHitTest(
      targetWasHit: false,
      miss: _MissedTapHitTest(
        location: Offset.zero,
        rootRenderViewSize: Size.zero,
        isOutOfBounds: true,
        hitTestPath: 'target has no RenderBox or Flutter view',
      ),
    );
  }
  final location = tester.getCenter(finder, warnIfMissed: false);
  final hitTestResult = HitTestResult();
  tester.binding.hitTestInView(hitTestResult, location, targetView.view.viewId);
  final renderView = tester.binding.renderViews.firstWhere(
    (view) => view.flutterView.viewId == targetView.view.viewId,
  );
  return _TapTargetHitTest(
    targetWasHit: hitTestResult.path.any(
      (entry) => entry.target == targetRenderObject,
    ),
    miss: _MissedTapHitTest(
      location: location,
      rootRenderViewSize: renderView.size,
      isOutOfBounds: !(Offset.zero & renderView.size).contains(location),
      hitTestPath: hitTestResult.path.map((entry) => entry.target).join(' -> '),
    ),
  );
}

class _TapTargetHitTest {
  const _TapTargetHitTest({required this.targetWasHit, required this.miss});

  final bool targetWasHit;
  final _MissedTapHitTest miss;
}

class _MissedTapHitTest {
  const _MissedTapHitTest({
    required this.location,
    required this.rootRenderViewSize,
    required this.isOutOfBounds,
    required this.hitTestPath,
  });

  final Offset location;
  final Size rootRenderViewSize;
  final bool isOutOfBounds;
  final String hitTestPath;
}

Future<void> _installEvidencePackagePair(
  WidgetTester tester,
  EvidencePackagePair fixture, {
  required ValueKey<String> openButtonKey,
}) async {
  await tapWhenVisible(
    tester,
    find.byKey(openButtonKey),
    description: 'local community package installer open button',
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tapWhenVisible(
    tester,
    find.byKey(const ValueKey('load-local-community-button')),
    description: 'load local community button',
  );
  await tester.pumpAndSettle();
}

Future<void> openEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target,
) async {
  await _returnToCommunityList(tester);
  _expectCommunityListReady(tester);
  final card = find.byKey(ValueKey('community-card-${target.communityId}'));
  await _scrollToCardIfNeeded(tester, card);
  if (card.evaluate().isEmpty) {
    fail(
      'Could not find evidence target ${target.communityName} '
      '(${target.communityId}) from the community list.',
    );
  }
  await _centerCardInList(tester, card);
  final detail = find.byKey(ValueKey('local-extension-${target.extensionId}'));
  // Engine-native shipped packages first render their membership gate inside
  // the target LocalExtensionScreen. The route proves the card tap worked even
  // though the signed-in content marker is not available until entry succeeds.
  final targetRoute = _evidenceTargetRoute(target);
  final identity = find.byKey(
    ValueKey('community-card-identity-${target.communityId}'),
  );
  for (final tapTarget in [identity, card]) {
    if (tapTarget.evaluate().isEmpty) {
      continue;
    }
    await tester.tap(tapTarget, warnIfMissed: false);
    await _pumpEvidenceFrames(tester);
    if (detail.evaluate().isNotEmpty || targetRoute.evaluate().isNotEmpty) {
      return;
    }
    await _returnToCommunityList(tester);
    _expectCommunityListReady(tester);
    await _scrollToCardIfNeeded(tester, card);
    await _centerCardInList(tester, card);
  }
  final cardRect = tester.getRect(card);
  await tester.tapAt(cardRect.center);
  await _pumpEvidenceFrames(tester);
  if (detail.evaluate().isEmpty && targetRoute.evaluate().isEmpty) {
    fail(
      'Tapped evidence target ${target.communityName} '
      '(${target.communityId}) but ${target.extensionId} did not open. '
      '${_visibleScreenDescription()}',
    );
  }
}

Future<void> _pumpEvidenceFrames(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _evidenceTargetRoute(LoomEvidenceTarget target) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is LocalExtensionScreen &&
        widget.community.communityId == target.communityId &&
        widget.community.extensionId == target.extensionId,
    description:
        'LocalExtensionScreen for ${target.communityId} '
        '(${target.extensionId})',
  );
}

/// The exact installed community screen expected for [target]. Callers still
/// need [assertB25CommunityRowSurface] to prove that this finder is on the
/// current route rather than merely retained below an overlay.
Finder evidenceTargetRoute(LoomEvidenceTarget target) =>
    _evidenceTargetRoute(target);

/// Names the current B25 surface using the same dialog, community-route, and
/// overlay inspection used by the row-entry assertion.
///
/// This is diagnostic-only. In particular, it does not pop a dialog or try to
/// recover an unexpected surface.
String describeB25CommunitySurface(LoomEvidenceTarget target) {
  final expectedSurface = _evidenceTargetRoute(target);
  final picker = find.descendant(
    of: expectedSurface,
    matching: find.byKey(const ValueKey('actor-identity-picker-button')),
  );
  return _currentUnexpectedB25SurfaceDescription(
        expectedExtensionId: target.extensionId,
      ) ??
      _unexpectedCommunitySurfaceDescription(
        expectedExtensionId: target.extensionId,
        expectedSurface: expectedSurface,
        picker: picker,
      );
}

/// Leaves one B25 community after its row walkthrough has finished.
///
/// This checks the named Back affordance exactly once. An absent Back control
/// or an unexpected destination is a community finding; this helper never
/// attempts an unbounded pop sequence or dismisses an unknown overlay.
Future<void> tearDownB25CommunityWalkthrough({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required String? lastRowWalked,
  required Future<void> Function() pumpAfterBack,
}) async {
  final communityBackButton = find.byTooltip('Back');
  if (communityBackButton.evaluate().isEmpty) {
    throw StateError(
      buildB25CommunityTeardownFailureMessage(
        communityName: target.communityName,
        extensionId: target.extensionId,
        lastRowWalked: lastRowWalked,
        observedSurface: describeB25CommunitySurface(target),
      ),
    );
  }

  await tester.tap(communityBackButton.first);
  await pumpAfterBack();
  if (find.text('Loom Communities').evaluate().isEmpty) {
    throw StateError(
      buildB25CommunityTeardownFailureMessage(
        communityName: target.communityName,
        extensionId: target.extensionId,
        lastRowWalked: lastRowWalked,
        observedSurface: describeB25CommunitySurface(target),
        detail:
            'The Back tooltip was tapped, but Loom Communities did not '
            'become visible.',
      ),
    );
  }
}

/// Navigates from the current [LocalExtensionScreen] route to the known
/// community-list route without looking for a Back affordance.
///
/// The community entry Scaffold deliberately has no AppBar, and a Back
/// control retained below a covering surface is not a usable recovery path.
/// This performs one route pop only, then proves that the community list is
/// both present and interactable. It never dismisses a covering surface.
Future<void> returnToCommunityListDirectly(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (_communityListIsReady()) {
    _expectDirectCommunityListArrival(tester);
    return;
  }

  final currentCommunityRoute = find.byElementPredicate(
    (element) =>
        element.widget is LocalExtensionScreen &&
        (ModalRoute.of(element)?.isCurrent ?? false),
    description: 'current LocalExtensionScreen route',
  );
  final currentRouteCount = currentCommunityRoute.evaluate().length;
  if (currentRouteCount != 1) {
    fail(
      'Could not navigate directly to the community list: expected exactly '
      'one current LocalExtensionScreen route, found $currentRouteCount. '
      'Observed surface: ${_visibleScreenDescription()}',
    );
  }

  // Pop the known community route directly instead of asking pageBack() to
  // find a Back button that may be absent or retained below a covering
  // surface.
  final didPop = await Navigator.of(
    tester.element(currentCommunityRoute),
  ).maybePop();
  if (!didPop) {
    fail(
      'Could not navigate directly to the community list because the known '
      'LocalExtensionScreen route Navigator could not pop. '
      'Observed surface: ${_visibleScreenDescription()}',
    );
  }
  await tester.pumpAndSettle();
  _expectDirectCommunityListArrival(tester);
}

Future<void> _returnToCommunityList(WidgetTester tester) =>
    returnToCommunityListDirectly(tester);

void _expectDirectCommunityListArrival(WidgetTester tester) {
  final communityListTitle = find.text('Loom Communities');
  if (communityListTitle.evaluate().length != 1 || !_communityListIsReady()) {
    fail(
      'Direct navigation did not land on the community list. '
      'Observed surface: ${_visibleScreenDescription()}',
    );
  }

  final addCommunityButton = find.byKey(const ValueKey('add-community-button'));
  final readiness = inspectFinderTapReadiness(tester, addCommunityButton);
  if (!readiness.isReady) {
    fail(
      'Direct navigation reached the community-list widgets, but the known '
      'community-list route was not interactable: ${readiness.description}. '
      'Observed surface: ${_visibleScreenDescription()}',
    );
  }
}

bool _communityListIsReady() {
  return find
          .byKey(const ValueKey('add-community-button'))
          .evaluate()
          .isNotEmpty &&
      find.byKey(const ValueKey('community-list')).evaluate().isNotEmpty &&
      find.byType(Scrollable).evaluate().isNotEmpty;
}

Finder _communityListScrollable() {
  return find.byType(Scrollable).last;
}

Future<void> _scrollToCardIfNeeded(WidgetTester tester, Finder card) async {
  if (card.evaluate().isNotEmpty) {
    return;
  }
  if (find.byType(Scrollable).evaluate().isEmpty) {
    fail(
      'Community list scrollable was not available while opening a '
      'community card.',
    );
  }
  final scrollable = _communityListScrollable();
  for (final offset in const [Offset(0, 260), Offset(0, -260)]) {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.drag(scrollable, offset, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (card.evaluate().isNotEmpty) {
        return;
      }
    }
  }
}

Future<void> _centerCardInList(WidgetTester tester, Finder card) async {
  if (card.evaluate().isEmpty) {
    return;
  }
  await Scrollable.ensureVisible(
    tester.element(card),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

void _expectCommunityListReady(WidgetTester tester) {
  if (!_communityListIsReady()) {
    fail(
      'Community list was not ready. '
      'addButton=${find.byKey(const ValueKey('add-community-button')).evaluate().length}, '
      'communityList=${find.byKey(const ValueKey('community-list')).evaluate().length}, '
      'scrollables=${find.byType(Scrollable).evaluate().length}. '
      '${_visibleScreenDescription()}',
    );
  }
}

Future<void> selectActorIdentity(WidgetTester tester, String fanId) async {
  await _waitForCommunityEntryResolution(tester);
  // Shipped engine-native packages bind role policy to an active account, so
  // enter through the real account form. Metadata fixtures remain on the
  // legacy role-picker path below because they do not render this gate.
  if (find
      .byKey(const ValueKey('community-entry-gate'))
      .evaluate()
      .isNotEmpty) {
    await _createEvidenceAccount(tester, fanId);
    await _waitForEvidenceFinder(
      tester,
      find.byKey(const ValueKey('actor-identity-picker-button')),
      description: 'community content after signing up as $fanId',
    );
    return;
  }

  final pickerButton = find.byKey(
    const ValueKey('actor-identity-picker-button'),
  );
  await _waitForEvidenceFinder(
    tester,
    pickerButton,
    description: 'actor identity picker while selecting $fanId',
  );
  await tapWhenVisible(
    tester,
    pickerButton,
    description: 'actor identity picker while selecting $fanId',
  );
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('actor-identity-picker-dialog')),
    findsOneWidget,
  );

  final actorIdentityOption = find.byKey(
    ValueKey('actor-identity-option-$fanId'),
  );
  if (actorIdentityOption.evaluate().isEmpty) {
    fail(
      'Actor identity $fanId was not available in the actor identity picker. '
      '${_visibleScreenDescription()}',
    );
  }
  final selectedActorIdentity = tester
      .widget<ListTile>(actorIdentityOption)
      .selected;
  final signedInAccount = find.textContaining('Signed in as ');
  if (signedInAccount.evaluate().isEmpty || selectedActorIdentity) {
    await tapWhenVisible(
      tester,
      actorIdentityOption,
      description: 'actor identity option for $fanId',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('actor-identity-picker-dialog')),
      findsNothing,
    );
    return;
  }

  final specificPerson = find.byKey(
    const ValueKey('actor-identity-sign-in-specific-person'),
  );
  await tester.ensureVisible(specificPerson);
  await tester.tap(specificPerson);
  await tester.pumpAndSettle();
  await _waitForEvidenceFinder(
    tester,
    find.byKey(const ValueKey('open-signup-display-name')),
    description: 'account chooser while selecting $fanId',
  );

  final accountName = _evidenceAccountName(fanId);
  final existingAccount = find.ancestor(
    of: find.text(accountName),
    matching: find.byType(ListTile),
  );
  if (existingAccount.evaluate().isNotEmpty) {
    await tester.ensureVisible(existingAccount.first);
    await tester.tap(existingAccount.first, warnIfMissed: false);
  } else {
    await _createEvidenceAccount(tester, fanId);
  }
  await _waitForEvidenceFinder(
    tester,
    pickerButton,
    description: 'community content after signing in as $fanId',
  );
}

Future<void> seedEvidenceAccounts(
  WidgetTester tester,
  LoomEvidenceTarget target,
  List<LoomAccount> accounts,
) async {
  final route = _evidenceTargetRoute(target);
  await _waitForEvidenceFinder(
    tester,
    route,
    description: 'local extension route before seeding evidence accounts',
  );
  final screen = tester.widget<LocalExtensionScreen>(route);
  final authApi = screen.authApi;
  if (authApi is! LocalAuthApi) {
    fail(
      'Evidence accounts can only be seeded into the Demo App LocalAuthApi; '
      '${authApi.runtimeType} was provided for ${target.extensionId}.',
    );
  }
  authApi.seedAccounts(target.extensionId, accounts);

  // The entry screen may already have loaded its account list. Reopen the
  // community route so the real auth UI reads the newly seeded identities.
  await openEvidenceTarget(tester, target);
}

Future<void> signInEvidenceAccount(
  WidgetTester tester,
  String displayName,
) async {
  await _waitForCommunityEntryResolution(tester);
  if (find.byKey(const ValueKey('community-entry-gate')).evaluate().isEmpty) {
    final pickerButton = find.byKey(
      const ValueKey('actor-identity-picker-button'),
    );
    await _waitForEvidenceFinder(
      tester,
      pickerButton,
      description: 'actor identity picker before signing in as $displayName',
    );
    await tapWhenVisible(
      tester,
      pickerButton,
      description: 'actor identity picker before signing in as $displayName',
    );
    await tester.pumpAndSettle();
    final specificPerson = find.byKey(
      const ValueKey('actor-identity-sign-in-specific-person'),
    );
    await tester.ensureVisible(specificPerson);
    await tester.tap(specificPerson);
    await tester.pumpAndSettle();
    await _waitForEvidenceFinder(
      tester,
      find.byKey(const ValueKey('open-signup-display-name')),
      description: 'specific-person account chooser for $displayName',
    );
  }

  final accountRow = find.ancestor(
    of: find.text(displayName),
    matching: find.byType(ListTile),
  );
  await _waitForEvidenceFinder(
    tester,
    accountRow,
    description: 'seeded account $displayName',
  );
  await tester.ensureVisible(accountRow.first);
  await tester.tap(accountRow.first, warnIfMissed: false);
  await _waitForEvidenceFinder(
    tester,
    find.byKey(const ValueKey('actor-identity-picker-button')),
    description: 'community content after signing in as $displayName',
  );
}

Future<void> _waitForCommunityEntryResolution(
  WidgetTester tester, {
  Duration? timeout,
  String? lastCompletedStep,
  DateTime Function()? now,
}) async {
  final budget = WalkthroughWaitBudget(
    timeout: timeout ?? WalkthroughWaitBudget.defaultInnerWaitTimeout,
    now: now,
  );
  final finder = find.byKey(const ValueKey('community-entry-checking'));
  while (!budget.expired) {
    if (finder.evaluate().isEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw WalkthroughStallFailure(
    buildWalkthroughStallMessage(
      lastCompletedStep: lastCompletedStep,
      attemptedStep: 'wait for community membership checking to resolve',
      waitingFor:
          '${finder.describeMatch(Plurality.many)} to disappear. '
          '${_visibleScreenDescription()}',
      budget: budget,
    ),
  );
}

Future<void> _createEvidenceAccount(WidgetTester tester, String fanId) async {
  final displayName = find.byKey(const ValueKey('open-signup-display-name'));
  final roleDropdown = find.byKey(const ValueKey('open-signup-role-dropdown'));
  final submit = find.byKey(const ValueKey('open-signup-submit'));
  for (final finder in [displayName, roleDropdown, submit]) {
    if (finder.evaluate().isEmpty) {
      fail(
        'The community entry account form was incomplete while selecting '
        '$fanId. ${_visibleScreenDescription()}',
      );
    }
  }

  await tester.ensureVisible(roleDropdown);
  await tester.tap(roleDropdown);
  await tester.pumpAndSettle();
  final roleChoice = find.byKey(ValueKey('open-signup-role-$fanId'));
  if (roleChoice.evaluate().isEmpty) {
    fail(
      'Actor identity $fanId was not offered by the community entry account '
      'form. ${_visibleScreenDescription()}',
    );
  }
  // DropdownMenuItem renders the selected value in the button and another
  // copy in the open modal route. The overlay copy is last in paint order;
  // target it explicitly so selecting the initial actorIdentity is unambiguous.
  await tester.tap(roleChoice.last, warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.ensureVisible(displayName);
  await tester.enterText(displayName, _evidenceAccountName(fanId));
  await tester.ensureVisible(submit);
  await tester.tap(submit, warnIfMissed: false);
  await tester.pump();
}

String _evidenceAccountName(String fanId) => 'Evidence $fanId';

Future<void> _waitForEvidenceFinder(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration? timeout,
  String? lastCompletedStep,
  DateTime Function()? now,
}) async {
  final budget = WalkthroughWaitBudget(
    timeout: timeout ?? WalkthroughWaitBudget.defaultInnerWaitTimeout,
    now: now,
  );
  while (!budget.expired) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw WalkthroughStallFailure(
    buildWalkthroughStallMessage(
      lastCompletedStep: lastCompletedStep,
      attemptedStep: description,
      waitingFor: finder.describeMatch(Plurality.many),
      budget: budget,
    ),
  );
}

/// Waits for an engine-backed widget whose future may complete outside the
/// fake-async clock used by widget tests (for example, a SQLite query).
Future<void> waitForEngineNativeWidget(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration? timeout,
  String? lastCompletedStep,
  DateTime Function()? now,
}) async {
  final budget = WalkthroughWaitBudget(
    timeout: timeout ?? WalkthroughWaitBudget.defaultInnerWaitTimeout,
    now: now,
  );
  while (!budget.expired) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw WalkthroughStallFailure(
    buildWalkthroughStallMessage(
      lastCompletedStep: lastCompletedStep,
      attemptedStep: description,
      waitingFor: finder.describeMatch(Plurality.many),
      budget: budget,
    ),
  );
}

String _visibleScreenDescription() {
  final markers = <String>[];
  void addMarker(String label, Finder finder) {
    final count = finder.evaluate().length;
    if (count > 0) markers.add('$label=$count');
  }

  addMarker(
    'communityEntryGate',
    find.byKey(const ValueKey('community-entry-gate')),
  );
  addMarker(
    'communityEntryChecking',
    find.byKey(const ValueKey('community-entry-checking')),
  );
  addMarker(
    'localPackageLoader',
    find.byKey(const ValueKey('load-local-community-button')),
  );
  addMarker(
    'actorIdentityPicker',
    find.byKey(const ValueKey('actor-identity-picker-dialog')),
  );
  addMarker('localExtensionScreen', find.byType(LocalExtensionScreen));
  addMarker('alertDialog', find.byType(AlertDialog));
  addMarker('scaffold', find.byType(Scaffold));
  addMarker('scrollable', find.byType(Scrollable));

  final extensionIds = find
      .byType(LocalExtensionScreen)
      .evaluate()
      .map(
        (element) =>
            (element.widget as LocalExtensionScreen).community.extensionId,
      )
      .toSet()
      .toList(growable: false);
  final visibleTexts = <String>{};
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final value = (widget.data ?? widget.textSpan?.toPlainText())?.trim();
    if (value == null || value.isEmpty) continue;
    visibleTexts.add(
      value.length <= 100 ? value : '${value.substring(0, 97)}...',
    );
    if (visibleTexts.length == 16) break;
  }
  return 'Visible screen: markers=[${markers.join(', ')}], '
      'extensionIds=$extensionIds, texts=${visibleTexts.toList()}';
}

Future<void> selectWorkflowTab(
  WidgetTester tester, {
  required LoomExperienceDefinition experience,
  required String roleId,
  required LoomWorkflowDefinition workflow,
}) async {
  final tabs = appShellTabsFor(experience: experience, roleId: roleId);
  final targetTab = tabs.firstWhere(
    (tab) =>
        tab.tabId != 'home' &&
        tab.matchesWorkflow(
          extensionId: experience.extensionId,
          workflow: workflow,
        ),
    orElse: () =>
        tabs.firstWhere((tab) => tab.tabId == 'home', orElse: () => tabs.first),
  );
  final tabFinder = find.byKey(ValueKey('community-tab-${targetTab.tabId}'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  if (tabFinder.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> scrollToWorkflowCard(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  final workflowCard = find.byKey(ValueKey('workflow-${workflow.workflowId}'));
  if (workflowCard.evaluate().isNotEmpty) {
    await tester.ensureVisible(workflowCard);
    await tester.pumpAndSettle();
    return;
  }

  final scrollable = verticalScrollableFinder();
  expect(scrollable, findsWidgets);
  for (final offset in const [Offset(0, -240), Offset(0, 240)]) {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.drag(scrollable.last, offset, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (workflowCard.evaluate().isNotEmpty) {
        await tester.ensureVisible(workflowCard);
        await tester.pumpAndSettle();
        return;
      }
    }
  }

  final homeTab = find.byKey(const ValueKey('community-tab-home'));
  if (homeTab.evaluate().isNotEmpty) {
    await tester.ensureVisible(homeTab);
    await tester.pumpAndSettle();
    await tester.tap(homeTab);
    await tester.pumpAndSettle();
    if (workflowCard.evaluate().isNotEmpty) {
      await tester.ensureVisible(workflowCard);
      await tester.pumpAndSettle();
      return;
    }
  }

  fail('Could not find workflow card ${workflow.workflowId}');
}

Finder verticalScrollableFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
    description: 'vertical Scrollable',
  );
}

Future<void> completeWorkflow(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  await scrollToWorkflowCard(tester, workflow);
  final workflowButton = find.byKey(
    ValueKey('workflow-button-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, workflowButton);
  await tester.pumpAndSettle();
  await tapWhenVisible(
    tester,
    workflowButton,
    description: 'workflow action for ${workflow.workflowId}',
  );
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-action-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  final submitButton = find.byKey(
    ValueKey('workflow-action-submit-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, submitButton);
  await tester.pumpAndSettle();
  await tapWhenVisible(
    tester,
    submitButton,
    description: 'workflow submit action for ${workflow.workflowId}',
  );
  await tester.pumpAndSettle();
  await scrollToWorkflowCard(tester, workflow);
  expect(
    find.byKey(ValueKey('workflow-complete-${workflow.workflowId}')),
    findsOneWidget,
  );
  expect(
    find.byKey(ValueKey('workflow-result-${workflow.workflowId}')),
    findsOneWidget,
  );
}

Future<void> scrollFinderIntoViewport(
  WidgetTester tester,
  Finder finder,
) async {
  final scrollable = verticalScrollableFinder().last;
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: scrollable,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();

  for (var attempt = 0; attempt < 16; attempt += 1) {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: scrollable,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
    }
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(finder);
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    const safeTop = 112.0;
    final safeBottom = viewportHeight - 96.0;
    if (rect.top >= safeTop && rect.bottom <= safeBottom) {
      return;
    }
    final dragOffset = rect.top < safeTop
        ? const Offset(0, 220)
        : const Offset(0, -220);
    await tester.drag(scrollable, dragOffset, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

Future<void> completeWorkflowAsActor(
  WidgetTester tester, {
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) async {
  final policy = rolePolicyForWorkflow(extensionId, workflow.workflowId);
  await selectActorIdentity(tester, policy.actorRoleIds.first);
  await completeWorkflow(tester, workflow);
}

Future<void> receiveWorkflow(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  await scrollToWorkflowCard(tester, workflow);
  final receiveButton = find.byKey(
    ValueKey('workflow-receive-button-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, receiveButton);
  await tester.tap(receiveButton);
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-receive-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  final receiveSubmitButton = find.byKey(
    ValueKey('workflow-receive-submit-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, receiveSubmitButton);
  await tester.tap(receiveSubmitButton);
  await tester.pumpAndSettle();
  await scrollToWorkflowCard(tester, workflow);
  expect(
    find.byKey(ValueKey('workflow-received-${workflow.workflowId}')),
    findsOneWidget,
  );
  expect(
    find.byKey(ValueKey('workflow-received-result-${workflow.workflowId}')),
    findsOneWidget,
  );
}

Future<void> completeTargetWorkflows(
  WidgetTester tester,
  LoomEvidenceTarget target,
) async {
  await tester.pumpWidget(const LoomCommunitiesDemoApp());
  await installMetadataEvidenceTarget(tester, target);
  await openEvidenceTarget(tester, target);
  final experience = experienceForExtensionId(
    target.extensionId,
    displayName: target.communityName,
  );
  expect(find.text(experience.tagline), findsOneWidget);
  for (final workflow in experience.workflows) {
    await completeWorkflowAsActor(
      tester,
      extensionId: target.extensionId,
      workflow: workflow,
    );
  }
}

Future<EvidencePackagePair> writeEvidencePackagePair(
  LoomEvidenceTarget target,
) async {
  final shippedPackage = await readShippedEvidencePackage(target);
  final decoded = shippedPackage.source;
  final workflowDefinitions = shippedPackage.experience.workflowDefinitions!;

  final tempDir = Directory.systemTemp.createTempSync(
    'loom_${target.extensionId}_',
  );
  final extensionFile = File(
    '${tempDir.path}/${target.handle}.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/${target.handle}.loom-init.zip',
  );
  final initialization = Map<String, dynamic>.from(decoded)
    // Keep the package's genuine experience and appShell while hydrating the
    // demo catalog entry. The shipped soccer corpus uses a different
    // communityId; its existing package generator performs the same
    // normalization for local sideloads.
    ..['communityId'] = target.communityId;
  extensionFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'mode': 'local-demo',
      'extensionId': target.extensionId,
      'displayName': target.communityName,
      'version': '1.0.0',
      'permissions': [
        'community.install',
        'content.publish',
        'events.write',
        'forms.write',
        'payments.write',
        'export.read',
      ],
      'assets': {
        'logo': 'assets/brand/${target.handle}-logo.png',
        'cardImage': 'assets/brand/${target.handle}-card.png',
        'heroImage': 'assets/brand/${target.handle}-hero.png',
        'defaultCardImage': 'assets/brand/${target.handle}-default-card.png',
      },
      'routes': [
        {
          'routeId': 'home',
          'title': target.communityName,
          'surface': 'community-home',
        },
      ],
      'workflows': workflowDefinitions.keys.toList(growable: false),
    }),
  );
  initializationFile.writeAsStringSync(jsonEncode(initialization));
  return EvidencePackagePair(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

Future<ShippedEvidencePackage> readShippedEvidencePackage(
  LoomEvidenceTarget target,
) async {
  final packageLocation =
      _shippedCommunityPackageLocationsByExtensionId[target.extensionId];
  if (packageLocation == null) {
    throw StateError(
      'No shipped community package is registered for walkthrough target '
      '${target.communityName} (extensionId: ${target.extensionId}).',
    );
  }
  final decoded = jsonDecode(
    stripJsonComments(
      await _readShippedCommunityPackageSource(packageLocation),
    ),
  );
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Shipped community package must contain a JSON object.');
  }
  final packageExtensionId = decoded['extensionId'];
  if (packageExtensionId != target.extensionId) {
    throw StateError(
      'Shipped community package extensionId $packageExtensionId does not '
      'match evidence target ${target.extensionId}.',
    );
  }
  final experience = decoded['experience'];
  final appShell = decoded['appShell'];
  if (experience is! Map<String, dynamic> ||
      appShell is! Map<String, dynamic>) {
    throw StateError(
      'Shipped community package ${target.extensionId} must declare both '
      'experience and appShell.',
    );
  }
  final workflowDefinitions = experience['workflowDefinitions'];
  if (workflowDefinitions is! Map<String, dynamic>) {
    throw StateError(
      'Shipped community package ${target.extensionId} must declare '
      'experience.workflowDefinitions.',
    );
  }
  final packageSpecVersion = decoded['specVersion'];
  if (packageSpecVersion is! int) {
    throw StateError(
      'Shipped community package ${target.extensionId} must declare an '
      'integer specVersion.',
    );
  }
  final parsedExperience = experienceForExtensionId(
    target.extensionId,
    displayName: target.communityName,
    specVersion: packageSpecVersion,
    experienceConfiguration: Map<String, Object?>.from(experience),
  );
  if (parsedExperience.workflowDefinitions == null ||
      parsedExperience.workflowDefinitions!.isEmpty ||
      parsedExperience.workflowInstances == null ||
      parsedExperience.workflowInstances!.isEmpty ||
      parsedExperience.actorIdentities == null ||
      parsedExperience.actorIdentities!.isEmpty) {
    throw StateError(
      'Shipped community package ${target.extensionId} must parse genuine '
      'roles, workflow definitions, and workflow instances.',
    );
  }
  return ShippedEvidencePackage(
    source: Map<String, dynamic>.unmodifiable(decoded),
    experience: parsedExperience,
    appShellConfiguration: Map<String, Object?>.unmodifiable(
      Map<String, Object?>.from(appShell),
    ),
  );
}

class ShippedEvidencePackage {
  const ShippedEvidencePackage({
    required this.source,
    required this.experience,
    required this.appShellConfiguration,
  });

  final Map<String, dynamic> source;
  final LoomExperienceDefinition experience;
  final Map<String, Object?> appShellConfiguration;
}

EvidencePackagePair _writeMetadataEvidencePackagePair(
  LoomEvidenceTarget target,
) {
  final tempDir = Directory.systemTemp.createTempSync(
    'loom_${target.extensionId}_',
  );
  final extensionFile = File(
    '${tempDir.path}/${target.handle}.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/${target.handle}.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'mode': 'local-demo',
      'extensionId': target.extensionId,
      'displayName': target.communityName,
      'version': '1.0.0',
      'permissions': [
        'community.install',
        'content.publish',
        'events.write',
        'forms.write',
        'payments.write',
        'export.read',
      ],
      'assets': {
        'logo': 'assets/brand/${target.handle}-logo.png',
        'cardImage': 'assets/brand/${target.handle}-card.png',
        'heroImage': 'assets/brand/${target.handle}-hero.png',
        'defaultCardImage': 'assets/brand/${target.handle}-default-card.png',
      },
      'routes': [
        {
          'routeId': 'home',
          'title': target.communityName,
          'surface': 'community-home',
        },
      ],
      'workflows': <String>[],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'packageId': 'init_${target.communityId}',
      'communityId': target.communityId,
      'communityHandle': target.handle,
      'communityName': target.communityName,
      'displayName': target.communityName,
      'extensionId': target.extensionId,
      'seedDataFiles': target.seedDataFiles,
      'branding': {
        'cardAssetId': 'seed/assets/${target.handle}-card.png',
        'logoAssetId': 'seed/assets/${target.handle}-logo.png',
        'heroImageAssetId': 'seed/assets/${target.handle}-hero.png',
        'accentColor': target.accentColor,
      },
    }),
  );
  return EvidencePackagePair(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

class EvidencePackagePair {
  const EvidencePackagePair({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

/// Builds one engine-native render binding without admitting any of the
/// removed shallow-workflow fields used by the pre-v4 demo fixtures.
Map<String, Object?> engineNativeTestRenderBinding({
  required List<String> states,
  required String tabId,
  required String cardSurfaceFamily,
  String audience = 'any',
  String bindingKind = 'primary',
  Map<String, Object?>? responseTable,
}) {
  if (states.isEmpty) {
    throw ArgumentError.value(states, 'states', 'must not be empty');
  }
  return <String, Object?>{
    'states': states,
    'audience': audience,
    'tabId': tabId,
    'cardSurfaceFamily': cardSurfaceFamily,
    'bindingKind': bindingKind,
    if (responseTable != null) 'responseTable': responseTable,
  };
}

/// Builds a complete v4 state-machine definition for demo widget fixtures.
Map<String, Object?> engineNativeTestWorkflowDefinition({
  required String initialState,
  required Map<String, Object?> states,
  required List<Map<String, Object?>> transitions,
  required List<Map<String, Object?>> renderBindings,
  required Map<String, Object?> instanceDataSchema,
  Map<String, Object?>? visibility,
}) {
  if (!states.containsKey(initialState)) {
    throw ArgumentError.value(
      initialState,
      'initialState',
      'must name a declared state',
    );
  }
  if (transitions.isEmpty) {
    throw ArgumentError.value(
      transitions,
      'transitions',
      'fixture workflows must exercise a real transition',
    );
  }
  if (instanceDataSchema.isEmpty) {
    throw ArgumentError.value(
      instanceDataSchema,
      'instanceDataSchema',
      'must declare the seeded instance fields',
    );
  }
  return <String, Object?>{
    'initialState': initialState,
    'states': states,
    'transitions': transitions,
    'renderBindings': renderBindings,
    'instanceDataSchema': instanceDataSchema,
    if (visibility != null) 'visibility': visibility,
  };
}

/// Builds one real persisted workflow record for an engine-native fixture.
Map<String, Object?> engineNativeTestWorkflowInstance({
  required String instanceId,
  required String workflowType,
  required String currentState,
  required String createdByFanId,
  required Map<String, Object?> instanceData,
}) => <String, Object?>{
  'instanceId': instanceId,
  'workflowType': workflowType,
  'currentState': currentState,
  'createdByFanId': createdByFanId,
  'instanceData': instanceData,
};

/// One persisted loan listing for an engine-native Marketplace fixture.
class EngineNativeMarketplaceLoanSeed {
  const EngineNativeMarketplaceLoanSeed({
    required this.instanceId,
    required this.title,
    required this.category,
    required this.condition,
    required this.description,
    this.currentState = 'published',
    this.availabilityState = 'available',
    this.holderFanId,
    this.queuedFanIds = const <String>[],
    this.dueDate,
    this.createdByFanId,
  });

  final String instanceId;
  final String title;
  final String category;
  final String condition;
  final String description;
  final String currentState;
  final String availabilityState;
  final String? holderFanId;
  final List<String> queuedFanIds;
  final String? dueDate;
  final String? createdByFanId;
}

/// One persisted giveaway listing for an engine-native Marketplace fixture.
class EngineNativeMarketplaceGiveawaySeed {
  const EngineNativeMarketplaceGiveawaySeed({
    required this.instanceId,
    required this.title,
    required this.category,
    required this.condition,
    required this.description,
    this.currentState = 'available',
    this.claimedByFanId,
    this.createdByFanId,
  });

  final String instanceId;
  final String title;
  final String category;
  final String condition;
  final String description;
  final String currentState;
  final String? claimedByFanId;
  final String? createdByFanId;
}

/// Reusable Marketplace definitions and persisted rows for demo widget tests.
class EngineNativeMarketplaceTestFixture {
  const EngineNativeMarketplaceTestFixture({
    required this.workflowDefinitions,
    required this.workflowInstances,
  });

  final Map<String, Object?> workflowDefinitions;
  final List<Map<String, Object?>> workflowInstances;
}

/// Builds real v4 loan and optional giveaway state machines for Marketplace.
///
/// Availability and queue membership remain orthogonal instance data on the
/// published loan listing. Every action is an engine transition; optional dues
/// or other prerequisites are attached to the borrow transition's guard.
EngineNativeMarketplaceTestFixture engineNativeMarketplaceTestFixture({
  required String loanWorkflowType,
  required String memberRoleId,
  required String organizerRoleId,
  required String organizerFanId,
  required List<EngineNativeMarketplaceLoanSeed> loanSeeds,
  List<EngineNativeMarketplaceGiveawaySeed> giveawaySeeds =
      const <EngineNativeMarketplaceGiveawaySeed>[],
  String giveawayWorkflowType = 'equipment-giveaway',
  String tabId = 'marketplace',
  List<String> borrowRequiresWorkflowsComplete = const <String>[],
}) {
  if (loanSeeds.isEmpty && giveawaySeeds.isEmpty) {
    throw ArgumentError(
      'Marketplace fixtures need at least one persisted listing row.',
    );
  }
  final instanceIds = <String>{};
  for (final seed in loanSeeds) {
    if (!const <String>{'published', 'delisted'}.contains(seed.currentState)) {
      throw ArgumentError.value(
        seed.currentState,
        'loanSeeds.currentState',
        'must be published or delisted',
      );
    }
    if (!instanceIds.add(seed.instanceId)) {
      throw ArgumentError.value(
        seed.instanceId,
        'loanSeeds.instanceId',
        'must be unique',
      );
    }
  }
  for (final seed in giveawaySeeds) {
    if (!const <String>{
      'available',
      'claimed',
      'withdrawn',
    }.contains(seed.currentState)) {
      throw ArgumentError.value(
        seed.currentState,
        'giveawaySeeds.currentState',
        'must be available, claimed, or withdrawn',
      );
    }
    if (!instanceIds.add(seed.instanceId)) {
      throw ArgumentError.value(
        seed.instanceId,
        'giveawaySeeds.instanceId',
        'must be unique across Marketplace rows',
      );
    }
  }

  final loanDefinition = engineNativeTestWorkflowDefinition(
    initialState: 'published',
    states: <String, Object?>{
      'published': <String, Object?>{'label': 'In library'},
      'delisted': <String, Object?>{'label': 'Delisted', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'borrow',
        'label': 'Request loan',
        'icon': 'arrow_forward',
        'tone': 'primary',
        'from': <String>['published'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>[memberRoleId],
          'instanceDataEquals': <String, Object?>{
            'key': 'availabilityState',
            'value': 'available',
          },
          if (borrowRequiresWorkflowsComplete.isNotEmpty)
            'requiresWorkflowsComplete': borrowRequiresWorkflowsComplete,
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'availabilityState',
            'value': 'onLoan',
          },
          <String, Object?>{
            'op': 'set',
            'key': 'holderFanId',
            'value': r'$actor',
          },
        ],
      },
      <String, Object?>{
        'id': 'join-queue',
        'label': 'Join queue',
        'icon': 'add_circle_outline',
        'tone': 'secondary',
        'from': <String>['published'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>[memberRoleId],
          'actorInList': <String, Object?>{
            'key': 'queuedFanIds',
            'present': false,
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'appendUnique',
            'key': 'queuedFanIds',
            'value': r'$actor',
          },
        ],
      },
      <String, Object?>{
        'id': 'leave-queue',
        'label': 'Leave queue',
        'icon': 'remove_circle_outline',
        'tone': 'secondary',
        'from': <String>['published'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>[memberRoleId],
          'actorInList': <String, Object?>{
            'key': 'queuedFanIds',
            'present': true,
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'removeValue',
            'key': 'queuedFanIds',
            'value': r'$actor',
          },
        ],
      },
      <String, Object?>{
        'id': 'return',
        'label': 'Return',
        'icon': 'keyboard_return',
        'tone': 'primary',
        'from': <String>['published'],
        'to': null,
        'guard': <String, Object?>{
          'allowedRoleIds': <String>[memberRoleId, organizerRoleId],
          'instanceDataEquals': <String, Object?>{
            'key': 'availabilityState',
            'value': 'onLoan',
          },
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'availabilityState',
            'value': 'available',
          },
          <String, Object?>{'op': 'set', 'key': 'holderFanId', 'value': null},
          <String, Object?>{'op': 'set', 'key': 'dueDate', 'value': null},
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['published'],
        tabId: tabId,
        cardSurfaceFamily: 'equipment-loan',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'required': true,
        'storage': 'inline',
        'searchable': true,
        'labelTemplate': '{value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'category': <String, Object?>{
        'type': 'text',
        'required': true,
        'storage': 'inline',
        'displayContexts': <String>['tile', 'detail'],
      },
      'condition': <String, Object?>{
        'type': 'text',
        'required': true,
        'storage': 'inline',
        'labelTemplate': '{value}',
        'displayContexts': <String>['detail'],
      },
      'description': <String, Object?>{
        'type': 'textarea',
        'storage': 'inline',
        'searchable': true,
        'displayContexts': <String>['detail'],
      },
      'availabilityState': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'displayContexts': <String>['tile', 'detail'],
      },
      'holderFanId': <String, Object?>{
        'type': 'fanId?',
        'storage': 'inline',
        'labelTemplate': 'Holder: {value}',
        'hideWhenEmpty': true,
        'displayContexts': <String>['tile', 'detail'],
      },
      'queuedFanIds': <String, Object?>{
        'type': 'fanId[]',
        'storage': 'inline',
        'labelTemplate': 'Queue: {value.length}',
        'hideWhenEmpty': true,
        'displayContexts': <String>['tile', 'detail'],
      },
      'dueDate': <String, Object?>{
        'type': 'date?',
        'storage': 'inline',
        'labelTemplate': 'Due back {value}',
        'hideWhenEmpty': true,
        'displayContexts': <String>['tile', 'detail'],
      },
      'queueLength': <String, Object?>{
        'type': 'number',
        'formula': 'size(queuedFanIds)',
      },
    },
  );

  final definitions = <String, Object?>{loanWorkflowType: loanDefinition};
  if (giveawaySeeds.isNotEmpty) {
    definitions[giveawayWorkflowType] = engineNativeTestWorkflowDefinition(
      initialState: 'available',
      states: <String, Object?>{
        'available': <String, Object?>{'label': 'Free to a good home'},
        'claimed': <String, Object?>{'label': 'Claimed', 'isTerminal': true},
        'withdrawn': <String, Object?>{
          'label': 'Withdrawn',
          'isTerminal': true,
        },
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'claim',
          'label': 'Claim giveaway',
          'icon': 'check_circle',
          'tone': 'primary',
          'from': <String>['available'],
          'to': 'claimed',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>[memberRoleId],
          },
          'effects': <Object?>[
            <String, Object?>{
              'op': 'set',
              'key': 'claimedByFanId',
              'value': r'$actor',
            },
            <String, Object?>{'op': 'removeFromTileGrid'},
          ],
        },
        <String, Object?>{
          'id': 'withdraw-giveaway',
          'label': 'Withdraw giveaway',
          'icon': 'delete_outline',
          'tone': 'destructive',
          'from': <String>['available'],
          'to': 'withdrawn',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>[organizerRoleId],
          },
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['available'],
          tabId: tabId,
          cardSurfaceFamily: 'equipment-loan',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{
          'type': 'text',
          'required': true,
          'storage': 'inline',
          'searchable': true,
          'labelTemplate': '{value}',
          'displayContexts': <String>['tile', 'detail'],
        },
        'category': <String, Object?>{
          'type': 'text',
          'required': true,
          'storage': 'inline',
          'displayContexts': <String>['tile', 'detail'],
        },
        'condition': <String, Object?>{
          'type': 'text',
          'storage': 'inline',
          'labelTemplate': '{value}',
          'displayContexts': <String>['detail'],
        },
        'description': <String, Object?>{
          'type': 'textarea',
          'storage': 'inline',
          'searchable': true,
          'displayContexts': <String>['detail'],
        },
        'claimedByFanId': <String, Object?>{
          'type': 'fanId?',
          'storage': 'inline',
          'labelTemplate': 'Claimed by: {value}',
          'hideWhenEmpty': true,
          'displayContexts': <String>['tile', 'detail'],
        },
      },
    );
  }

  return EngineNativeMarketplaceTestFixture(
    workflowDefinitions: definitions,
    workflowInstances: <Map<String, Object?>>[
      for (final seed in loanSeeds)
        engineNativeTestWorkflowInstance(
          instanceId: seed.instanceId,
          workflowType: loanWorkflowType,
          currentState: seed.currentState,
          createdByFanId: seed.createdByFanId ?? organizerFanId,
          instanceData: <String, Object?>{
            'title': seed.title,
            'category': seed.category,
            'condition': seed.condition,
            'description': seed.description,
            'availabilityState': seed.availabilityState,
            'holderFanId': seed.holderFanId,
            'queuedFanIds': seed.queuedFanIds,
            'dueDate': seed.dueDate,
          },
        ),
      for (final seed in giveawaySeeds)
        engineNativeTestWorkflowInstance(
          instanceId: seed.instanceId,
          workflowType: giveawayWorkflowType,
          currentState: seed.currentState,
          createdByFanId: seed.createdByFanId ?? organizerFanId,
          instanceData: <String, Object?>{
            'title': seed.title,
            'category': seed.category,
            'condition': seed.condition,
            'description': seed.description,
            'claimedByFanId': seed.claimedByFanId,
          },
        ),
    ],
  );
}

/// Declares a Marketplace tab without forcing a renderer contract.
///
/// An exclusive `equipment-loan` render binding must remain the source of the
/// derived `MarketplaceTabSurface` selection in engine-native tests.
Map<String, Object?> engineNativeMarketplaceTestTab({
  String tabId = 'marketplace',
  String label = 'Marketplace',
  String iconKey = 'marketplace',
}) => <String, Object?>{'tabId': tabId, 'label': label, 'iconKey': iconKey};

/// Waits for the engine-native Marketplace product surface or its real empty
/// state after the dispatcher finishes all `queryInstances` cursor pages.
Future<void> waitForEngineNativeMarketplaceSurface(
  WidgetTester tester, {
  bool empty = false,
}) => waitForEngineNativeWidget(
  tester,
  find.byKey(
    ValueKey(
      empty
          ? 'engine-native-marketplace-empty'
          : 'engine-native-marketplace-root',
    ),
  ),
  description: empty
      ? 'engine-native Marketplace empty surface'
      : 'engine-native Marketplace browse surface',
);

/// A reusable real event plus its per-individual RSVP response state machine.
///
/// RSVP choices intentionally live on response instances rather than on the
/// shared event. This mirrors the shipped v4 Tabletop package and lets tests
/// prove that one member's choice is persisted independently.
class EngineNativeEventRsvpTestFixture {
  const EngineNativeEventRsvpTestFixture({
    required this.workflowDefinitions,
    required this.workflowInstances,
  });

  final Map<String, Object?> workflowDefinitions;
  final List<Map<String, Object?>> workflowInstances;
}

/// One persisted per-person response row for an engine-native event fixture.
class EngineNativeEventRsvpResponseSeed {
  const EngineNativeEventRsvpResponseSeed({
    required this.instanceId,
    required this.fanId,
    required this.currentState,
    this.createdByFanId,
    this.instanceData = const <String, Object?>{},
  });

  final String instanceId;
  final String fanId;
  final String currentState;
  final String? createdByFanId;
  final Map<String, Object?> instanceData;
}

EngineNativeEventRsvpTestFixture engineNativeEventRsvpTestFixture({
  required String eventWorkflowType,
  required String responseWorkflowType,
  required String eventInstanceId,
  required String title,
  required String eventDate,
  required String eventTime,
  required String location,
  required String organizerRoleId,
  required String organizerFanId,
  required String memberRoleId,
  int capacity = 20,
  String? host,
  bool includeWaitlist = false,
  bool includeReminderAction = false,
  List<EngineNativeEventRsvpResponseSeed> responseSeeds = const [],
  Map<String, Object?> additionalEventInstanceData = const {},
  Map<String, Object?> additionalEventSchema = const {},
  List<Map<String, Object?>> additionalEventBindings = const [],
}) {
  if (capacity <= 0) {
    throw ArgumentError.value(capacity, 'capacity', 'must be positive');
  }
  final responseStates = <String>[
    'pending',
    'going',
    'maybe',
    'declined',
    if (includeWaitlist) 'waitlisted',
  ];
  for (final seed in responseSeeds) {
    if (!responseStates.contains(seed.currentState)) {
      throw ArgumentError.value(
        seed.currentState,
        'responseSeeds.currentState',
        'must name a declared response state',
      );
    }
  }
  if (responseSeeds.map((seed) => seed.instanceId).toSet().length !=
      responseSeeds.length) {
    throw ArgumentError.value(
      responseSeeds,
      'responseSeeds',
      'must use unique instance ids',
    );
  }

  Map<String, Object?> responseGuard({
    Map<String, Object?>? relatedAggregate,
    String? formula,
  }) => <String, Object?>{
    'allowedRoleIds': <String>[memberRoleId],
    'actorEqualsField': <String, Object?>{'key': 'fanId'},
    if (relatedAggregate != null) 'relatedAggregate': relatedAggregate,
    if (formula != null) 'formula': formula,
  };

  Map<String, Object?> capacityGuard(String comparator) => <String, Object?>{
    'workflowType': responseWorkflowType,
    'filter': <String, Object?>{'eventId': '{eventId}', r'$state': 'going'},
    'op': 'count',
    'comparator': comparator,
    'compareTo': <String, Object?>{
      'relatedInstanceField': 'eventId',
      'field': 'capacity',
    },
  };

  Map<String, Object?> responseTransition({
    required String id,
    required String label,
    required String to,
    required String tone,
    required String icon,
    required String action,
    Map<String, Object?>? relatedAggregate,
    List<Map<String, Object?>> effects = const [],
  }) => <String, Object?>{
    'id': id,
    'action': action,
    'label': label,
    'icon': icon,
    'tone': tone,
    'from': <String>[
      for (final state in responseStates)
        if (state != to) state,
    ],
    'to': to,
    'guard': responseGuard(relatedAggregate: relatedAggregate),
    if (effects.isNotEmpty) 'effects': effects,
  };

  return EngineNativeEventRsvpTestFixture(
    workflowDefinitions: <String, Object?>{
      eventWorkflowType: engineNativeTestWorkflowDefinition(
        initialState: 'open',
        states: <String, Object?>{
          'open': <String, Object?>{'label': 'RSVP open', 'tone': 'positive'},
          'cancelled': <String, Object?>{
            'label': 'Cancelled',
            'tone': 'negative',
            'isTerminal': true,
          },
        },
        transitions: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'cancel-event',
            'action': 'cancel',
            'label': 'Cancel event',
            'icon': 'cancel',
            'tone': 'destructive',
            'from': <String>['open'],
            'to': 'cancelled',
            'guard': <String, Object?>{
              'allowedRoleIds': <String>[organizerRoleId],
            },
          },
        ],
        renderBindings: <Map<String, Object?>>[
          engineNativeTestRenderBinding(
            states: <String>['open'],
            tabId: 'calendar',
            cardSurfaceFamily: 'event-rsvp',
            responseTable: <String, Object?>{
              'workflowType': responseWorkflowType,
              'eventField': 'eventId',
              'pendingStates': <String>['pending'],
            },
          ),
          ...additionalEventBindings,
        ],
        instanceDataSchema: <String, Object?>{
          'title': <String, Object?>{
            'type': 'text',
            'required': true,
            'writableBy': 'formEntry',
            'storage': 'inline',
            'searchable': true,
            'labelTemplate': '{value}',
            'displayContexts': <String>['tile', 'detail'],
          },
          'eventDate': <String, Object?>{
            'type': 'date',
            'required': true,
            'writableBy': 'formEntry',
            'storage': 'inline',
            'sortable': true,
            'displayIcon': 'calendar_today',
            'labelTemplate': '{value}',
            'displayContexts': <String>['tile', 'detail'],
          },
          'eventTime': <String, Object?>{
            'type': 'time',
            'required': true,
            'writableBy': 'formEntry',
            'storage': 'inline',
            'displayIcon': 'schedule',
            'labelTemplate': '{value}',
            'displayContexts': <String>['tile', 'detail'],
          },
          'location': <String, Object?>{
            'type': 'text',
            'required': true,
            'writableBy': 'formEntry',
            'storage': 'inline',
            'displayIcon': 'location_on_outlined',
            'labelTemplate': '{value}',
            'displayContexts': <String>['detail'],
          },
          if (host != null)
            'host': <String, Object?>{
              'type': 'text',
              'writableBy': 'formEntry',
              'storage': 'inline',
              'displayIcon': 'person_outline',
              'labelTemplate': 'Host: {value}',
              'displayContexts': <String>['detail'],
            },
          'capacity': <String, Object?>{
            'type': 'number',
            'required': true,
            'writableBy': 'formEntry',
            'storage': 'inline',
            'sortable': true,
            'displayIcon': 'groups_outlined',
            'labelTemplate': '{value} seats',
          },
          'responses': <String, Object?>{
            'type': 'list',
            'source': 'query($responseWorkflowType where eventId == id)',
            'displayContexts': <String>[],
          },
          'responseCounts': <String, Object?>{
            'type': 'map',
            'formula': r"groupCount(responses, '$state')",
            'displayContexts': <String>[],
          },
          'goingCount': <String, Object?>{
            'type': 'number',
            'formula': "mapGet(responseCounts, 'going')",
            'displayIcon': 'groups_outlined',
            'labelTemplate': 'Going: {value}',
            'displayContexts': <String>['tile', 'detail'],
          },
          'waitlistedCount': <String, Object?>{
            'type': 'number',
            'formula': "mapGet(responseCounts, 'waitlisted')",
            'displayIcon': 'hourglass_empty',
            'labelTemplate': 'Waitlist: {value}',
            'hideWhenEmpty': true,
            'displayContexts': <String>['tile', 'detail'],
          },
          'seatsRemaining': <String, Object?>{
            'type': 'number',
            'formula': 'capacity - goingCount',
            'displayIcon': 'event_seat',
            'labelTemplate': '{value} seats left',
            'displayContexts': <String>['detail'],
          },
          'isFull': <String, Object?>{
            'type': 'bool',
            'formula': 'goingCount >= capacity',
          },
          'hasWaitlist': <String, Object?>{
            'type': 'bool',
            'formula': 'waitlistedCount > 0',
          },
          ...additionalEventSchema,
        },
      ),
      responseWorkflowType: engineNativeTestWorkflowDefinition(
        initialState: 'pending',
        states: <String, Object?>{
          'pending': <String, Object?>{'label': 'Awaiting response'},
          'going': <String, Object?>{'label': 'Going', 'tone': 'positive'},
          'maybe': <String, Object?>{'label': 'Maybe', 'tone': 'warning'},
          'declined': <String, Object?>{
            'label': 'Can\'t go',
            'tone': 'negative',
          },
          if (includeWaitlist)
            'waitlisted': <String, Object?>{
              'label': 'Waitlisted',
              'tone': 'warning',
            },
        },
        transitions: <Map<String, Object?>>[
          responseTransition(
            id: 'respond-going',
            label: 'Going',
            to: 'going',
            tone: 'primary',
            icon: 'event_available',
            action: 'respond',
            relatedAggregate: capacityGuard('<'),
          ),
          responseTransition(
            id: 'respond-maybe',
            label: 'Maybe',
            to: 'maybe',
            tone: 'secondary',
            icon: 'help_outline',
            action: 'respond',
          ),
          responseTransition(
            id: 'respond-declined',
            label: 'Can\'t go',
            to: 'declined',
            tone: 'destructive',
            icon: 'event_busy',
            action: 'respond',
          ),
          if (includeWaitlist)
            responseTransition(
              id: 'respond-waitlist',
              label: 'Join waitlist',
              to: 'waitlisted',
              tone: 'secondary',
              icon: 'groups',
              action: 'join_waitlist',
              relatedAggregate: capacityGuard('>='),
              effects: <Map<String, Object?>>[
                <String, Object?>{
                  'op': 'set',
                  'key': 'rsvpedAt',
                  'value': r'$timestamp',
                },
              ],
            ),
          if (includeReminderAction)
            <String, Object?>{
              'id': 'set-reminder',
              'action': 'set_reminder',
              'label': 'Add reminder',
              'icon': 'notifications_active',
              'tone': 'secondary',
              'from': <String>[
                for (final state in responseStates)
                  if (state != 'declined') state,
              ],
              'to': null,
              'guard': responseGuard(formula: 'reminderOffsetHours == null'),
              'inputs': <String, Object?>{
                'offsetHours': <String, Object?>{
                  'type': 'number',
                  'required': true,
                },
              },
              'effects': <Object?>[
                <String, Object?>{
                  'op': 'set',
                  'key': 'reminderOffsetHours',
                  'value': '{input.offsetHours}',
                },
              ],
            },
        ],
        renderBindings: const <Map<String, Object?>>[],
        instanceDataSchema: <String, Object?>{
          'eventId': <String, Object?>{
            'type': 'text',
            'required': true,
            'storage': 'inline',
          },
          'fanId': <String, Object?>{
            'type': 'fanId',
            'required': true,
            'storage': 'inline',
          },
          if (includeWaitlist)
            'rsvpedAt': <String, Object?>{
              'type': 'date?',
              'writableBy': 'effect',
              'storage': 'inline',
            },
          if (includeReminderAction)
            'reminderOffsetHours': <String, Object?>{
              'type': 'number',
              'writableBy': 'effect',
              'storage': 'inline',
            },
        },
      ),
    },
    workflowInstances: <Map<String, Object?>>[
      engineNativeTestWorkflowInstance(
        instanceId: eventInstanceId,
        workflowType: eventWorkflowType,
        currentState: 'open',
        createdByFanId: organizerFanId,
        instanceData: <String, Object?>{
          'title': title,
          'eventDate': eventDate,
          'eventTime': eventTime,
          'location': location,
          'capacity': capacity,
          if (host != null) 'host': host,
          ...additionalEventInstanceData,
        },
      ),
      for (final response in responseSeeds)
        engineNativeTestWorkflowInstance(
          instanceId: response.instanceId,
          workflowType: responseWorkflowType,
          currentState: response.currentState,
          createdByFanId: response.createdByFanId ?? organizerFanId,
          instanceData: <String, Object?>{
            'eventId': eventInstanceId,
            'fanId': response.fanId,
            ...response.instanceData,
          },
        ),
    ],
  );
}

/// Writes the common local extension/initialization pair used by engine-native
/// demo tests. The guard against `experience.workflows` makes a version-only
/// rename fail immediately instead of silently falling back at runtime.
EvidencePackagePair writeEngineNativeTestPackagePair({
  required String tempDirectoryPrefix,
  required String extensionId,
  required String communityId,
  required String displayName,
  required Map<String, Object?> experience,
  Map<String, Object?> appShell = const <String, Object?>{},
  List<String> permissions = const <String>[
    'content.publish',
    'events.write',
    'forms.write',
  ],
}) {
  if (experience.containsKey('workflows')) {
    throw ArgumentError(
      'Engine-native test experiences must not declare removed workflows.',
    );
  }
  final definitions = experience['workflowDefinitions'];
  final instances = experience['workflowInstances'];
  if (definitions is! Map || definitions.isEmpty) {
    throw ArgumentError(
      'Engine-native test experiences need workflowDefinitions.',
    );
  }
  if (instances is! List || instances.isEmpty) {
    throw ArgumentError(
      'Engine-native test experiences need workflowInstances.',
    );
  }

  final tempDir = Directory.systemTemp.createTempSync(tempDirectoryPrefix);
  final extensionFile = File('${tempDir.path}/$extensionId.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/$extensionId.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'specVersion': currentCommunitySpecVersion,
      'mode': 'local-demo',
      'extensionId': extensionId,
      'displayName': displayName,
      'version': '1.0.0',
      'permissions': permissions,
      'workflows': definitions.keys.toList(growable: false),
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'specVersion': currentCommunitySpecVersion,
      'communityId': communityId,
      'communityName': displayName,
      'extensionId': extensionId,
      'seedDataFiles': <String>['seed/community.json', 'seed/workflows.json'],
      'experience': experience,
      if (appShell.isNotEmpty) 'appShell': appShell,
    }),
  );
  return EvidencePackagePair(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

/// Selects a horizontally scrollable community tab and waits for its surface.
Future<void> tapCommunityTab(WidgetTester tester, String tabId) async {
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 12 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tabFinder, findsOneWidget, reason: 'community tab $tabId');
  await tester.ensureVisible(tabFinder);
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Resolves the transition ids a [roleId] can take for an `event-rsvp` bound
/// workflow, honoring both legal RSVP shapes.
///
/// - **Self shape**: member actions live directly on the bound workflow, so
///   the role's actions come from that workflow's transitions out of the
///   instance's current state.
/// - **Paired shape**: a binding declares `responseTable.workflowType` and the
///   member responses live in that separate workflow. The responding role's
///   actions come from the response workflow's declared `initialState`. The
///   workflow name is read from the binding and is never derived by appending
///   `-response`.
///
/// Both sets are unioned because the real card renders the bound workflow's
/// own eligible transitions alongside response-table actions. That also keeps
/// the organizer working in the paired shape (the event workflow's
/// `make-recurring`/`cancel-event` are organizer-only) while member actions
/// resolve through `responseTable` instead.
Set<String> resolvedRsvpActionIdsForRole({
  required LoomWorkflowStateMachine machine,
  required Map<String, LoomWorkflowStateMachine> definitions,
  required LoomWorkflowSeedInstance instance,
  required String roleId,
}) {
  final resolved = <String>{};

  for (final transition in _roleEligibleTransitions(
    machine,
    instance.currentState,
    roleId,
  )) {
    resolved.add(transition.id);
  }

  for (final binding in machine.renderBindings) {
    if (!binding.states.contains(instance.currentState)) {
      continue;
    }
    final responseWorkflowType = binding.responseTable?.workflowType;
    if (responseWorkflowType == null) {
      continue;
    }
    final responseMachine = definitions[responseWorkflowType];
    if (responseMachine == null) {
      throw StateError(
        'Bound workflow ${machine.workflowType} names response workflow '
        '$responseWorkflowType via responseTable, but that workflow is not '
        'declared.',
      );
    }
    for (final transition in _roleEligibleTransitions(
      responseMachine,
      responseMachine.initialState,
      roleId,
    )) {
      resolved.add(transition.id);
    }
  }

  return resolved;
}

List<LoomWorkflowTransition> _roleEligibleTransitions(
  LoomWorkflowStateMachine machine,
  String state,
  String roleId,
) {
  return machine.transitionsFrom(state).where((transition) {
    final allowedRoleIds = transition.guard.allowedRoleIds;
    return allowedRoleIds == null ||
        allowedRoleIds.isEmpty ||
        allowedRoleIds.contains(roleId);
  }).toList();
}

/// Normalises an action label, id, or term for B25 synonym matching: lower-
/// case, split kebab/snake on separators, collapse whitespace.
String b25NormalizeActionText(String value) => value
    .toLowerCase()
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The primary/alternate verdict for one workflow transition against a B25
/// row's two synonym sets.
class B25TransitionMatch {
  const B25TransitionMatch({required this.primary, required this.alternate});

  /// True when [primaryTerms] holds for any of the transition's searchable
  /// texts (label, id, action).
  final bool primary;

  /// True when [alternateTerms] holds for any of the transition's searchable
  /// texts.
  final bool alternate;
}

/// Classifies [transition] against a B25 row's primary and alternate synonym
/// sets using word-boundary matching.
///
/// Alternate terms are matched first and their spans are excluded from primary
/// matching within the same searchable text. A negation such as "Not
/// attending" therefore satisfies "not attending"/"decline" but never the
/// primary "attend"; likewise "Cancel RSVP" satisfies "cancel rsvp" but never
/// the primary "rsvp". This mirrors the judge's word-boundary semantics in
/// `loom_ux_judges` without reaching into its private implementation.
B25TransitionMatch matchB25TransitionAgainstTerms(
  LoomWorkflowTransition transition, {
  required List<String> primaryTerms,
  required List<String> alternateTerms,
}) {
  final texts = _b25TransitionSearchTexts(transition);

  var isPrimary = false;
  var isAlternate = false;
  for (final text in texts) {
    final alternateMatches = _b25TermMatches(text, alternateTerms);
    if (alternateMatches.isNotEmpty) isAlternate = true;
    final primaryMatches = _b25TermMatches(
      text,
      primaryTerms,
      excludedSpans: alternateMatches.map((match) => match.span).toList(),
    );
    if (primaryMatches.isNotEmpty) isPrimary = true;
  }
  return B25TransitionMatch(primary: isPrimary, alternate: isAlternate);
}

/// Selects the primary and alternate transitions to exercise for a B25 row
/// from an ordered [candidates] list.
///
/// The primary is the first candidate that satisfies [primaryTerms]; the
/// alternate is the first *distinct* candidate that satisfies
/// [alternateTerms]. This is device-free: callers hand over the already
/// role/state-filtered transition list and receive the two transition ids the
/// walkthrough should drive.
({LoomWorkflowTransition? primary, LoomWorkflowTransition? alternate})
selectB25WalkthroughActions({
  required List<LoomWorkflowTransition> candidates,
  required List<String> primaryTerms,
  required List<String> alternateTerms,
}) {
  LoomWorkflowTransition? primary;
  for (final candidate in candidates) {
    final match = matchB25TransitionAgainstTerms(
      candidate,
      primaryTerms: primaryTerms,
      alternateTerms: alternateTerms,
    );
    if (match.primary) {
      primary = candidate;
      break;
    }
  }
  LoomWorkflowTransition? alternate;
  for (final candidate in candidates) {
    if (identical(candidate, primary)) continue;
    final match = matchB25TransitionAgainstTerms(
      candidate,
      primaryTerms: primaryTerms,
      alternateTerms: alternateTerms,
    );
    if (match.alternate) {
      alternate = candidate;
      break;
    }
  }
  return (primary: primary, alternate: alternate);
}

/// Reports which [primaryTerms] and [alternateTerms] an exercised
/// [transition] satisfies, using the same word-boundary + alternates-excluded-
/// from-primary semantics as [matchB25TransitionAgainstTerms]. Used when the
/// walkthrough writes its own `visiblePrimaryActions`/`visibleAlternateActions`
/// manifest rather than trusting the judge's OCR pass.
({List<String> primary, List<String> alternate}) b25MatchedTermNames(
  LoomWorkflowTransition transition, {
  required List<String> primaryTerms,
  required List<String> alternateTerms,
}) {
  final texts = _b25TransitionSearchTexts(transition);

  final primary = <String>{};
  final alternate = <String>{};
  for (final text in texts) {
    final alternateMatches = _b25TermMatches(text, alternateTerms);
    alternate.addAll(alternateMatches.map((match) => match.term));
    final primaryMatches = _b25TermMatches(
      text,
      primaryTerms,
      excludedSpans: alternateMatches.map((match) => match.span).toList(),
    );
    primary.addAll(primaryMatches.map((match) => match.term));
  }
  return (
    primary: primary.toList()..sort(),
    alternate: alternate.toList()..sort(),
  );
}

List<String> _b25TransitionSearchTexts(LoomWorkflowTransition transition) {
  return <String>{
    b25NormalizeActionText(transition.label),
    b25NormalizeActionText(transition.id),
    if (transition.action case final action?) b25NormalizeActionText(action),
  }.where((text) => text.isNotEmpty).toList(growable: false);
}

class _B25TextSpan {
  const _B25TextSpan(this.start, this.end);

  final int start;
  final int end;

  bool contains(_B25TextSpan other) => start <= other.start && other.end <= end;
}

class _B25TermMatch {
  const _B25TermMatch({required this.term, required this.span});

  final String term;
  final _B25TextSpan span;
}

bool _b25IsWordCharacter(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a);
}

bool _b25IsWordBoundaryStart(String text, int index) {
  if (index == 0) return true;
  return !_b25IsWordCharacter(text.codeUnitAt(index - 1));
}

bool _b25IsWordBoundaryEnd(String text, int end) {
  if (end >= text.length) return true;
  return !_b25IsWordCharacter(text.codeUnitAt(end));
}

List<_B25TermMatch> _b25TermMatches(
  String text,
  List<String> terms, {
  List<_B25TextSpan> excludedSpans = const [],
}) {
  final lower = text.toLowerCase();
  final matches = <_B25TermMatch>[];
  for (final term in terms) {
    final needle = b25NormalizeActionText(term);
    if (needle.isEmpty) continue;
    var searchFrom = 0;
    while (searchFrom <= lower.length) {
      final index = lower.indexOf(needle, searchFrom);
      if (index < 0) break;
      final start = index;
      final end = index + needle.length;
      final boundaryOk =
          _b25IsWordBoundaryStart(lower, start) &&
          _b25IsWordBoundaryEnd(lower, end);
      final span = _B25TextSpan(start, end);
      if (boundaryOk &&
          !excludedSpans.any((excluded) => excluded.contains(span))) {
        matches.add(_B25TermMatch(term: term, span: span));
      }
      searchFrom = end;
    }
  }
  return matches;
}
