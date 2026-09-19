import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show
        ArchetypeResolver,
        LoomWorkflowStateMachine,
        LoomWorkflowTransition,
        RenderBinding,
        WorkflowEffect,
        WorkflowInstance,
        applyEffects,
        workflowEffectAppend,
        workflowEffectAppendUnique,
        workflowEffectBranch,
        workflowEffectCreateInstance,
        workflowEffectDecrement,
        workflowEffectGenerateRecurringInstances,
        workflowEffectIncrement,
        workflowEffectRemoveValue,
        workflowEffectSet,
        workflowEffectTransitionRelated;

import '../test/b25_visible_postcondition.dart';
import '../test/b25_actor_audience_resolution.dart';
import '../test/b25_created_instance_identity.dart';
import '../test/b25_formula_guard_reachability.dart';
import '../test/b25_product_doc_role_resolution.dart';
import '../test/b25_shipped_state_postcondition.dart';
import '../test/b25_workflow_row_selection.dart';
import '../test/workflow_ui_test_harness.dart';
import '../test/walkthrough_wait.dart';

const _phaseFilterText = String.fromEnvironment('LOOM_EVIDENCE_PHASE_FILTER');
final Set<String> _phaseFilter = _phaseFilterText
    .split(',')
    .map((phase) => phase.trim())
    .where((phase) => phase.isNotEmpty)
    .toSet();
const _communityFilterText = String.fromEnvironment(
  'LOOM_EVIDENCE_COMMUNITY_FILTER',
);
final Set<String> _communityFilter = _communityFilterText
    .split(',')
    .map((extensionId) => extensionId.trim())
    .where((extensionId) => extensionId.isNotEmpty)
    .toSet();
const _workflowShardCount = int.fromEnvironment(
  'LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT',
  defaultValue: 1,
);
const _workflowShardIndex = int.fromEnvironment(
  'LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX',
);
const _externalAndroidScreenshots = bool.fromEnvironment(
  'LOOM_EVIDENCE_EXTERNAL_ANDROID_SCREENSHOTS',
);
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wf_full-ui-screenshot-evidence-b12-b20', (tester) async {
    final bodyWatch = WalkthroughBodyWatch(
      lastCompletedStep: 'setup phase, no step completed yet',
      attemptedStep: 'initializing the walkthrough capture harness',
      waitingFor:
          'the demo app, evidence targets, and interaction catalog to load',
    );
    Future<void> runWalkthrough() async {
      final evidenceTargets = _evidenceTargetsForRun();
      final b25InteractionCatalog =
          B25ProductDocInteractionCatalog.fromAssetJson(
            await rootBundle.loadString(b25InteractionModelFlutterAssetPath),
          );
      final selectedExtensionIds = {
        for (final target in evidenceTargets) target.extensionId,
      };
      final requestedPhases = _requestedEvidencePhases(evidenceTargets);
      if (_communityFilter.isNotEmpty && requestedPhases.isEmpty) {
        final requestedCommunities = _communityFilter.toList()..sort();
        final requestedPhaseFilter = _phaseFilter.toList()..sort();
        throw StateError(
          'LOOM_EVIDENCE_COMMUNITY_FILTER and LOOM_EVIDENCE_PHASE_FILTER '
          'selected no walkthrough coverage: communities=$requestedCommunities, '
          'phases=$requestedPhaseFilter.',
        );
      }
      if (!_externalAndroidScreenshots) {
        await binding.convertFlutterSurfaceToImage();
      }
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['walkthroughStatus'] = 'running';
      binding.reportData!['requestedPhases'] = requestedPhases;
      binding.reportData!['expectedWorkflowCountByPhase'] =
          _workflowEvidenceEntryCountByPhase(
            evidenceTargets,
            b25InteractionCatalog,
          );
      binding.reportData!.addAll(_evidenceDeviceMetadata());
      final entries = <Map<String, Object?>>[];
      binding.reportData!['workflowEvidence'] = entries;
      final communityTraversals = <B25CommunityTraversalRecord>[];
      binding.reportData!['b25CommunityTraversals'] = <Map<String, Object?>>[];
      // Only becomes true once the walkthrough reaches its own finalisation
      // below. An aborted run leaves this false, so the writer can tell "no
      // communities were incomplete" apart from "the run never got far
      // enough to know" instead of printing a ratio that reads as complete.
      binding.reportData!['b25TraversalFinalised'] = false;
      // Preloaded demo-catalog entries are not evidence that a shipped package
      // was installed. Every walkthrough target must be installed from its
      // registered shipped package during this run.
      final installedExtensionIds = <String>{};
      final screenshotVisibleTextByName = <String, String>{};
      final screenshotCapture = _ScreenshotCaptureRecorder(
        binding: binding,
        tester: tester,
        reportData: binding.reportData!,
        externalAndroidScreenshots: _externalAndroidScreenshots,
      );
      final totalWorkflowEvidenceEntries = _workflowEvidenceEntryCount(
        evidenceTargets,
        b25InteractionCatalog,
      );
      var completedWorkflowEvidenceEntries = 0;
      var blockedByAudienceWorkflowEvidenceEntries = 0;
      var blockedBySelectorSetupWorkflowEvidenceEntries = 0;
      var blockedByPrerequisiteWorkflowEvidenceEntries = 0;
      var actionSucceededResultUnverifiedWorkflowEvidenceEntries = 0;
      var productFindingWorkflowEvidenceEntries = 0;
      var rowExecutionFailedWorkflowEvidenceEntries = 0;

      // Frames `capture` has written for the row currently in flight.
      // Cleared at the start of every `runB25WorkflowRowScope` call so a
      // failing row can hand its own already-captured frames to
      // `_b25RowScopedFailureFor` as diagnostic evidence -- see CLAUDE.md
      // "B25: a row that captures frames and then fails must not discard
      // them". Frames captured outside a row scope (the B12 harness) are
      // simply overwritten by the next clear and never read.
      final currentRowScreenshotNames = <String>[];

      void recordEvidenceEntry(Map<String, Object?> entry) {
        entries.add(entry);
        binding.reportData!['workflowEvidence'] = List<Map<String, Object?>>.of(
          entries,
        );
      }

      void recordCommunityTraversal(B25CommunityTraversalRecord traversal) {
        communityTraversals.add(traversal);
        binding.reportData!['b25CommunityTraversals'] = [
          for (final recordedTraversal in communityTraversals)
            recordedTraversal.toReportData(),
        ];
      }

      void emitProgress(
        String status, {
        required String phase,
        required String workflowId,
        String? communityName,
        String? screenshotName,
        String? blockedRowOutcome,
      }) {
        if (status == 'workflow-complete') {
          switch (blockedRowOutcome) {
            case 'blocked_by_audience':
              blockedByAudienceWorkflowEvidenceEntries += 1;
            case 'blocked_by_selector_setup':
              blockedBySelectorSetupWorkflowEvidenceEntries += 1;
            case 'blocked_by_prerequisite':
              blockedByPrerequisiteWorkflowEvidenceEntries += 1;
            case 'action_succeeded_result_unverified':
              actionSucceededResultUnverifiedWorkflowEvidenceEntries += 1;
            case 'product_finding':
              productFindingWorkflowEvidenceEntries += 1;
            case 'row_execution_failed':
              rowExecutionFailedWorkflowEvidenceEntries += 1;
            case null:
              completedWorkflowEvidenceEntries += 1;
            default:
              throw StateError(
                'Unexpected blocked walkthrough row outcome '
                '`$blockedRowOutcome` for $workflowId.',
              );
          }
          bodyWatch.beat(
            lastCompletedStep:
                'phase $phase, community ${communityName ?? '(unknown)'}, '
                'workflow $workflowId',
            attemptedStep: 'advancing to the next workflow phase',
            waitingFor: 'the next workflow to start',
          );
        } else if (status == 'workflow-start') {
          bodyWatch.beat(
            attemptedStep:
                'starting workflow $workflowId (phase $phase'
                '${communityName != null ? ', community $communityName' : ''})',
            waitingFor:
                'the first screenshot for workflow $workflowId to be captured',
          );
        }
        _emitCaptureProgress({
          'status': status,
          'phase': phase,
          'workflowId': workflowId,
          if (communityName != null) 'communityName': communityName,
          if (screenshotName != null) 'screenshotName': screenshotName,
          'completedWorkflows': completedWorkflowEvidenceEntries,
          'blockedByAudienceWorkflows':
              blockedByAudienceWorkflowEvidenceEntries,
          'blockedBySelectorSetupWorkflows':
              blockedBySelectorSetupWorkflowEvidenceEntries,
          'blockedByPrerequisiteWorkflows':
              blockedByPrerequisiteWorkflowEvidenceEntries,
          'actionSucceededResultUnverifiedWorkflows':
              actionSucceededResultUnverifiedWorkflowEvidenceEntries,
          'productFindingWorkflows': productFindingWorkflowEvidenceEntries,
          'rowExecutionFailedWorkflows':
              rowExecutionFailedWorkflowEvidenceEntries,
          'totalWorkflows': totalWorkflowEvidenceEntries,
        });
      }

      Future<void> capture(String name) {
        _emitCaptureProgress({
          'status': 'screenshot-start',
          'phase': _phaseForScreenshotName(name),
          'screenshotName': name,
          'completedWorkflows': completedWorkflowEvidenceEntries,
          'blockedByAudienceWorkflows':
              blockedByAudienceWorkflowEvidenceEntries,
          'blockedBySelectorSetupWorkflows':
              blockedBySelectorSetupWorkflowEvidenceEntries,
          'blockedByPrerequisiteWorkflows':
              blockedByPrerequisiteWorkflowEvidenceEntries,
          'actionSucceededResultUnverifiedWorkflows':
              actionSucceededResultUnverifiedWorkflowEvidenceEntries,
          'productFindingWorkflows': productFindingWorkflowEvidenceEntries,
          'rowExecutionFailedWorkflows':
              rowExecutionFailedWorkflowEvidenceEntries,
          'totalWorkflows': totalWorkflowEvidenceEntries,
        });
        return _capture(
          screenshotCapture,
          tester,
          screenshotVisibleTextByName,
          name,
        ).then((_) {
          currentRowScreenshotNames.add(name);
          bodyWatch.beat(
            lastCompletedStep: 'screenshot $name captured',
            attemptedStep: 'continuing the walkthrough after $name',
            waitingFor: 'the next walkthrough step to become ready',
          );
        });
      }

      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _pumpB25Frames(tester);

      Future<void> ensureTargetInstalled(LoomEvidenceTarget target) async {
        if (installedExtensionIds.contains(target.extensionId)) {
          return;
        }
        await installShippedEvidenceTarget(tester, target);
        installedExtensionIds.add(target.extensionId);
      }

      Future<void> returnToCommunityList() async {
        await returnToCommunityListDirectly(tester);
        expect(find.text('Loom Communities'), findsOneWidget);
        expect(find.byKey(const ValueKey('community-list')), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
      }

      Future<void> ensureTargetOpen(LoomEvidenceTarget target) async {
        if (find
            .byKey(ValueKey('local-extension-${target.extensionId}'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
        await returnToCommunityList();
        await ensureTargetInstalled(target);
        await openEvidenceTarget(tester, target);
      }

      if (_includePhase('B12')) {
        emitProgress(
          'workflow-start',
          phase: 'B12',
          workflowId: 'workflow-ui-evidence-harness',
        );
        final harnessEntry = <String, Object?>{
          'phase': 'B12',
          'appId': 'workflow-ui-evidence-harness',
          'workflowId': 'workflow-ui-evidence-harness',
          'expectedAssertions': [
            'empty state is visible',
            'local package dialog opens',
            'screenshot callback completes',
          ],
        };
        await capture('B12_harness_start');
        await tester.tap(find.byKey(const ValueKey('add-community-button')));
        await tester.pumpAndSettle();
        await capture('B12_harness_action');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await capture('B12_harness_complete');
        recordEvidenceEntry({
          ...harnessEntry,
          'screenshotNames': [
            'B12_harness_start',
            'B12_harness_action',
            'B12_harness_complete',
          ],
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B12',
          workflowId: 'workflow-ui-evidence-harness',
        );
      }

      var targetWorkflowOrdinal = 0;
      for (final target in evidenceTargets.where(
        (target) => _includePhase(target.phase),
      )) {
        final productDocRows = b25InteractionCatalog.models
            .where(
              (row) =>
                  row.communityId == target.communityId &&
                  !_b25RowUsesDedicatedRoleWalkthrough(row),
            )
            .toList(growable: false);
        final selectedProductDocRows = <B25ProductDocInteractionModel>[];
        for (final productDocRow in productDocRows) {
          final workflowOrdinal = targetWorkflowOrdinal;
          targetWorkflowOrdinal += 1;
          if (_includeWorkflowShard(workflowOrdinal)) {
            selectedProductDocRows.add(productDocRow);
          }
        }
        if (selectedProductDocRows.isEmpty) {
          continue;
        }

        String? lastRowWalked;
        final communityScope = await runB25CommunityScope(() async {
          _assertB25AssetCoversTargets(
            catalog: b25InteractionCatalog,
            evidenceTargets: [target],
          );
          await ensureTargetInstalled(target);
          await openEvidenceTarget(tester, target);
          final shippedPackage = await readShippedEvidencePackage(target);
          for (final productDocRow in selectedProductDocRows) {
            lastRowWalked = '${productDocRow.workflowId}/${productDocRow.role}';
            emitProgress(
              'workflow-start',
              phase: target.phase,
              workflowId: productDocRow.workflowId,
              communityName: target.communityName,
            );
            currentRowScreenshotNames.clear();
            final rowScope = await runB25WorkflowRowScope(
              () async {
                late final _B25WalkthroughResult walkthroughResult;
                if (!shippedPackage.experience.workflowDefinitions!.containsKey(
                  productDocRow.workflowId,
                )) {
                  walkthroughResult = await _captureMissingB25PackageWorkflow(
                    tester: tester,
                    target: target,
                    package: shippedPackage,
                    bodyWatch: bodyWatch,
                    b25Model: productDocRow,
                    capture: capture,
                  );
                } else {
                  final rowSelection = selectB25WorkflowRow(
                    () => _shippedWorkflowSelector(
                      target: target,
                      package: shippedPackage,
                      workflowType: productDocRow.workflowId,
                      b25Model: productDocRow,
                    ),
                  );
                  final selector = rowSelection.selector;
                  walkthroughResult = selector == null
                      ? rowSelection.isBlockedByAudience
                            ? await _recordB25AudienceBlockedWorkflow(
                                tester: tester,
                                target: target,
                                b25Model: productDocRow,
                                reason: rowSelection.blockedReason!,
                                cause: rowSelection.blockedCause!,
                                capture: capture,
                              )
                            : await _recordB25SelectorSetupBlockedWorkflow(
                                tester: tester,
                                target: target,
                                b25Model: productDocRow,
                                reason: rowSelection.blockedReason!,
                                cause: rowSelection.blockedCause!,
                                capture: capture,
                              )
                      : await _runB25ShippedWorkflowWalkthrough(
                          tester: tester,
                          target: target,
                          package: shippedPackage,
                          bodyWatch: bodyWatch,
                          selector: selector,
                          b25Model: productDocRow,
                          capture: capture,
                        );
                }
                await assertB25CommunityRowSurface(
                  tester: tester,
                  target: target,
                  workflowId: productDocRow.workflowId,
                  role: productDocRow.role,
                  boundary: 'after',
                  captureDiagnostic: capture,
                );
                return walkthroughResult;
              },
              capturedScreenshotNames: () =>
                  List<String>.of(currentRowScreenshotNames),
            );
            final walkthroughResult =
                rowScope.value ?? _recordB25RowScopedFailure(rowScope.failure!);
            recordEvidenceEntry({
              'phase': target.phase,
              'appId': target.extensionId,
              'communityId': target.communityId,
              'communityName': target.communityName,
              'workflowId': productDocRow.workflowId,
              'role': productDocRow.role,
              'productDocPath': productDocRow.productDocPath,
              'requiredPrimaryActions': productDocRow.requiredPrimaryActions,
              'requiredAlternateActions':
                  productDocRow.requiredAlternateActions,
              'expectedAssertions': [
                productDocRow.expectedDecision,
                productDocRow.requiredPrimaryActions.join(', '),
                productDocRow.requiredAlternateActions.join(', '),
                productDocRow.resultAndReceiverState,
              ],
              'screenshotNames': walkthroughResult.screenshotNames,
              'diagnosticScreenshotNames':
                  walkthroughResult.diagnosticScreenshotNames,
              'b25RowOutcome': walkthroughResult.rowOutcome,
              if (walkthroughResult.blockedByAudienceReason != null)
                'blockedByAudienceReason':
                    walkthroughResult.blockedByAudienceReason,
              if (walkthroughResult.blockedByAudienceCause != null)
                'blockedByAudienceCause':
                    walkthroughResult.blockedByAudienceCause,
              if (walkthroughResult.blockedBySelectorSetupReason != null)
                'blockedBySelectorSetupReason':
                    walkthroughResult.blockedBySelectorSetupReason,
              if (walkthroughResult.blockedBySelectorSetupCause != null)
                'blockedBySelectorSetupCause':
                    walkthroughResult.blockedBySelectorSetupCause,
              if (walkthroughResult.actionSucceededResultUnverifiedReason !=
                  null)
                'actionSucceededResultUnverifiedReason':
                    walkthroughResult.actionSucceededResultUnverifiedReason,
              if (walkthroughResult.rowExecutionFailureReason != null)
                'rowExecutionFailureReason':
                    walkthroughResult.rowExecutionFailureReason,
              if (walkthroughResult.actionExecutionEvidence.isNotEmpty)
                'b25ActionExecutionEvidence': [
                  for (final evidence
                      in walkthroughResult.actionExecutionEvidence)
                    evidence.toReportData(),
                ],
              'b25ActionProofStatus': walkthroughResult.actionProofStatus,
              'visiblePrimaryActions': walkthroughResult.visiblePrimaryActions,
              'visibleAlternateActions':
                  walkthroughResult.visibleAlternateActions,
              'availableSupplementaryActions':
                  walkthroughResult.availableSupplementaryActions,
              'productFindings': walkthroughResult.productFindings,
              'status': walkthroughResult.isRecordedFailure
                  ? walkthroughResult.rowOutcome
                  : 'pass',
              'actionProofFramePairs': walkthroughResult.actionProofFramePairs,
              'actionProofFramePairsRequired':
                  walkthroughResult.actionProofFramePairsRequired,
              if (walkthroughResult.alternateUnavailableReason != null)
                'alternateUnavailableReason':
                    walkthroughResult.alternateUnavailableReason,
              ...walkthroughResult.extraFields,
            });
            emitProgress(
              'workflow-complete',
              phase: target.phase,
              workflowId: productDocRow.workflowId,
              communityName: target.communityName,
              blockedRowOutcome: walkthroughResult.isRecordedFailure
                  ? walkthroughResult.rowOutcome
                  : null,
            );
          }

          await tearDownB25CommunityWalkthrough(
            tester: tester,
            target: target,
            lastRowWalked: lastRowWalked,
            pumpAfterBack: () => _pumpB25Frames(tester),
          );
        });
        final communityTraversal = B25CommunityTraversalRecord.fromScope(
          scope: communityScope,
          phase: target.phase,
          communityId: target.communityId,
          communityName: target.communityName,
          extensionId: target.extensionId,
          lastRowWalked: lastRowWalked,
        );
        recordCommunityTraversal(communityTraversal);
        if (communityTraversal.isIncomplete) {
          bodyWatch.beat(
            lastCompletedStep:
                'community ${target.communityName} ended incompletely after '
                '${lastRowWalked ?? 'no row'}',
            attemptedStep:
                'continuing to the next community after recording '
                'the community-scoped failure',
            waitingFor: 'the next community walkthrough to start',
          );
        }
      }

      _B25WalkthroughResult dedicatedPass({
        required List<String> screenshotNames,
        String actionProofStatus = 'pass',
        List<String> visiblePrimaryActions = const <String>[],
        List<String> visibleAlternateActions = const <String>[],
        List<String> productFindings = const <String>[],
        List<B25ActionExecutionEvidence> actionExecutionEvidence =
            const <B25ActionExecutionEvidence>[],
        Map<String, Object?> extraFields = const <String, Object?>{},
      }) {
        if (actionProofStatus != 'pass' && productFindings.isEmpty) {
          throw StateError(
            'A dedicated B25 row cannot report $actionProofStatus without a '
            'verbatim product finding.',
          );
        }
        return _B25WalkthroughResult(
          screenshotNames: screenshotNames,
          actionProofStatus: actionProofStatus,
          visiblePrimaryActions: visiblePrimaryActions,
          visibleAlternateActions: visibleAlternateActions,
          availableSupplementaryActions: const <String>[],
          productFindings: productFindings,
          rowOutcome: actionProofStatus == 'pass'
              ? 'attempted'
              : 'product_finding',
          actionExecutionEvidence: actionExecutionEvidence,
          extraFields: extraFields,
        );
      }

      Map<String, Object?> dedicatedResultFields(
        _B25WalkthroughResult result,
      ) => <String, Object?>{
        'screenshotNames': result.screenshotNames,
        'diagnosticScreenshotNames': result.diagnosticScreenshotNames,
        'b25RowOutcome': result.rowOutcome,
        if (result.blockedByAudienceReason != null)
          'blockedByAudienceReason': result.blockedByAudienceReason,
        if (result.blockedByAudienceCause != null)
          'blockedByAudienceCause': result.blockedByAudienceCause,
        if (result.blockedBySelectorSetupReason != null)
          'blockedBySelectorSetupReason': result.blockedBySelectorSetupReason,
        if (result.blockedBySelectorSetupCause != null)
          'blockedBySelectorSetupCause': result.blockedBySelectorSetupCause,
        if (result.blockedByPrerequisiteReason != null)
          'blockedByPrerequisiteReason': result.blockedByPrerequisiteReason,
        if (result.actionSucceededResultUnverifiedReason != null)
          'actionSucceededResultUnverifiedReason':
              result.actionSucceededResultUnverifiedReason,
        if (result.rowExecutionFailureReason != null)
          'rowExecutionFailureReason': result.rowExecutionFailureReason,
        if (result.actionExecutionEvidence.isNotEmpty)
          'b25ActionExecutionEvidence': [
            for (final evidence in result.actionExecutionEvidence)
              evidence.toReportData(),
          ],
        'b25ActionProofStatus': result.actionProofStatus,
        'visiblePrimaryActions': result.visiblePrimaryActions,
        'visibleAlternateActions': result.visibleAlternateActions,
        'productFindings': result.productFindings,
        'status': result.isRecordedFailure ? result.rowOutcome : 'pass',
        'actionProofFramePairs': result.actionProofFramePairs,
        'actionProofFramePairsRequired': result.actionProofFramePairsRequired,
        if (result.alternateUnavailableReason != null)
          'alternateUnavailableReason': result.alternateUnavailableReason,
        ...result.extraFields,
      };

      if (isB25DedicatedCommunitySelected(
        selectedExtensionIds: selectedExtensionIds,
        extensionId: 'ext_mosque',
        phases: const <String>['B17', 'B18', 'B19', 'B20'],
        includesPhase: _includePhase,
      )) {
        final mosqueTarget = evidenceTargets.firstWhere(
          (target) => target.extensionId == 'ext_mosque',
        );
        String? mosqueLastRowWalked;
        String mosqueLastRole = 'admin';
        final mosqueScope = await runB25CommunityScope(() async {
          _assertB25AssetCoversTargets(
            catalog: b25InteractionCatalog,
            evidenceTargets: [mosqueTarget],
          );
          await ensureTargetInstalled(mosqueTarget);
          final mosquePackage = await readShippedEvidencePackage(mosqueTarget);
          final mosqueAdminRoleId = _packageRoleId(
            target: mosqueTarget,
            package: mosquePackage,
            label: 'Masjid Admin',
          );
          final mosqueMemberRoleId = _packageRoleId(
            target: mosqueTarget,
            package: mosquePackage,
            label: 'Community Member',
          );
          final announcement = _shippedWorkflowSelector(
            target: mosqueTarget,
            package: mosquePackage,
            workflowType: 'mosque-announcement',
          );
          final careRequest = _shippedWorkflowSelector(
            target: mosqueTarget,
            package: mosquePackage,
            workflowType: 'mosque-care-request',
          );
          B25ProductDocInteractionModel mosqueB25Row(
            String workflowId,
            String role,
          ) => b25InteractionCatalog.requireModel(
            communityId: mosqueTarget.communityId,
            communityName: mosqueTarget.communityName,
            workflowId: workflowId,
            role: role,
          );
          Map<String, Object?> productDocEntry(
            B25ProductDocInteractionModel row,
          ) => <String, Object?>{
            'appId': mosqueTarget.extensionId,
            'communityId': mosqueTarget.communityId,
            'communityName': mosqueTarget.communityName,
            'workflowId': row.workflowId,
            'role': row.role,
            'productDocPath': row.productDocPath,
            'requiredPrimaryActions': row.requiredPrimaryActions,
            'requiredAlternateActions': row.requiredAlternateActions,
            'expectedAssertions': [
              row.expectedDecision,
              row.resultAndReceiverState,
            ],
          };

          Future<_B25WalkthroughResult> runMosqueRow({
            required String phase,
            required String workflowId,
            required String role,
            required Map<String, Object?> entry,
            required Future<_B25WalkthroughResult> Function() walk,
          }) async {
            mosqueLastRowWalked = '$workflowId/$role';
            mosqueLastRole = role;
            emitProgress(
              'workflow-start',
              phase: phase,
              workflowId: workflowId,
              communityName: mosqueTarget.communityName,
            );
            currentRowScreenshotNames.clear();
            final scoped = await runB25WorkflowRowScope(
              walk,
              capturedScreenshotNames: () =>
                  List<String>.of(currentRowScreenshotNames),
            );
            final result =
                scoped.value ?? _recordB25RowScopedFailure(scoped.failure!);
            recordEvidenceEntry({
              'phase': phase,
              ...entry,
              ...dedicatedResultFields(result),
            });
            emitProgress(
              'workflow-complete',
              phase: phase,
              workflowId: workflowId,
              communityName: mosqueTarget.communityName,
              blockedRowOutcome: result.isRecordedFailure
                  ? result.rowOutcome
                  : null,
            );
            return result;
          }

          if (_includePhase('B17')) {
            await runMosqueRow(
              phase: 'B17',
              workflowId: 'wf_actor-identity-inventory-capability-matrix',
              role: 'admin',
              entry: <String, Object?>{
                'appId': 'actor-identity-role-inventory',
                'communityId': mosqueTarget.communityId,
                'communityName': mosqueTarget.communityName,
                'expectedAssertions': [
                  'all demo communities define two or more actorIdentities',
                  'all workflow/actorIdentity matrix rows have actor, receiver, read-only, or disabled state',
                  'receiver rows declare dependency evidence',
                  'matrix rows: ${await _roleMatrixRowCount(evidenceTargets)}',
                ],
              },
              walk: () async {
                await ensureTargetOpen(mosqueTarget);
                await selectActorIdentity(tester, mosqueAdminRoleId);
                await capture('B17_actor_identity_inventory_active_admin');
                await tester.tap(
                  find.byKey(const ValueKey('actor-identity-picker-button')),
                );
                await tester.pumpAndSettle();
                await capture('B17_actor_identity_inventory_picker');
                await tester.tap(find.text('Cancel'));
                await tester.pumpAndSettle();
                return dedicatedPass(
                  screenshotNames: const [
                    'B17_actor_identity_inventory_active_admin',
                    'B17_actor_identity_inventory_picker',
                  ],
                  visiblePrimaryActions: const ['choose role'],
                  visibleAlternateActions: const ['cancel picker'],
                );
              },
            );
          }

          if (_includePhase('B18')) {
            final row = mosqueB25Row('wf_demo-app-persona-picker', 'member');
            await runMosqueRow(
              phase: 'B18',
              workflowId: row.workflowId,
              role: row.role,
              entry: productDocEntry(row),
              walk: () async {
                await ensureTargetOpen(mosqueTarget);
                await tester.tap(
                  find.byKey(const ValueKey('actor-identity-picker-button')),
                );
                await tester.pumpAndSettle();
                await capture('B18_member_actor_identity_picker_dialog');
                await tester.tap(find.text('Cancel'));
                await tester.pumpAndSettle();
                await _showShippedWorkflowInstance(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  selector: announcement,
                  roleId: mosqueMemberRoleId,
                );
                await capture('B18_actor_identity_picker_member_selected');
                return dedicatedPass(
                  screenshotNames: const [
                    'B18_member_actor_identity_picker_dialog',
                    'B18_actor_identity_picker_member_selected',
                  ],
                  visiblePrimaryActions: const ['choose role'],
                  visibleAlternateActions: const ['cancel picker'],
                );
              },
            );
          }

          if (_includePhase('B19')) {
            final memberRow = mosqueB25Row(
              'wf_community-persona-aware-ux',
              'member',
            );
            final adminRow = mosqueB25Row(
              'wf_community-persona-aware-ux',
              'admin',
            );
            await runMosqueRow(
              phase: 'B19',
              workflowId: memberRow.workflowId,
              role: memberRow.role,
              entry: productDocEntry(memberRow),
              walk: () async {
                await ensureTargetOpen(mosqueTarget);
                await seedEvidenceAccounts(tester, mosqueTarget, [
                  LoomAccount(
                    accountId: mosqueMemberRoleId,
                    displayName: 'Walkthrough community member',
                    roleId: mosqueMemberRoleId,
                  ),
                ]);
                await signInEvidenceAccount(
                  tester,
                  'Walkthrough community member',
                );
                await _showShippedWorkflowInstance(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  selector: careRequest,
                  roleId: mosqueMemberRoleId,
                  selectRole: false,
                );
                await capture('B19_member_primary_member_workflow');
                final beforeCancelVisibleText = _visibleTextFor(tester);
                await tester.tap(
                  find.byKey(const ValueKey('actor-identity-picker-button')),
                );
                await tester.pumpAndSettle();
                await capture('B19_member_alternate_leave_unchanged');
                await tester.tap(find.text('Cancel'));
                await tester.pumpAndSettle();
                // The cancel round-trip is DESIGNED to restore the screen
                // exactly, so a third screenshot here would only reproduce
                // `B19_member_primary_member_workflow` byte-for-byte -- not
                // evidence, a manufactured duplicate. Check the actual
                // postcondition in-walk instead: this is strictly stronger,
                // because it is a checked assertion rather than a shipped
                // file the byte-integrity guard could only flag as
                // suspicious without being able to say why.
                final afterCancelVisibleText = _visibleTextFor(tester);
                final resultUnchangedVerified =
                    afterCancelVisibleText == beforeCancelVisibleText;
                expect(
                  resultUnchangedVerified,
                  isTrue,
                  reason:
                      'B19 member cancel round-trip: canceling the actor '
                      'identity picker was expected to restore the screen '
                      'exactly, but the visible text changed.\nbefore: '
                      '$beforeCancelVisibleText\nafter: $afterCancelVisibleText',
                );
                return dedicatedPass(
                  screenshotNames: const [
                    'B19_member_primary_member_workflow',
                    'B19_member_alternate_leave_unchanged',
                  ],
                  visiblePrimaryActions: const ['view member workflow'],
                  visibleAlternateActions: const ['leave unchanged'],
                  extraFields: <String, Object?>{
                    'resultUnchangedVerified': resultUnchangedVerified,
                  },
                );
              },
            );
            await runMosqueRow(
              phase: 'B19',
              workflowId: adminRow.workflowId,
              role: adminRow.role,
              entry: productDocEntry(adminRow),
              walk: () async {
                await ensureTargetOpen(mosqueTarget);
                final publication = await _createAndPublishShippedAnnouncement(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  selector: announcement,
                  adminRoleId: mosqueAdminRoleId,
                  capture: capture,
                  screenshotPrefix: 'B19_role_aware',
                  announcementTitle: 'B19 admin receiver-target announcement',
                );
                return dedicatedPass(
                  screenshotNames: const [
                    'B19_role_aware_admin_start',
                    'B19_role_aware_admin_action',
                    'B19_role_aware_admin_alternate_action',
                    'B19_role_aware_admin_alternate_result',
                    'B19_role_aware_admin_primary_action',
                    'B19_role_aware_admin_complete',
                  ],
                  actionProofStatus: publication.productFinding == null
                      ? 'pass'
                      : 'fail',
                  visiblePrimaryActions: const ['publish/update'],
                  visibleAlternateActions: const ['save draft'],
                  productFindings: publication.productFinding == null
                      ? const <String>[]
                      : [publication.productFinding!],
                  actionExecutionEvidence: [
                    publication.actionExecutionEvidence,
                  ],
                );
              },
            );
          }

          if (_includePhase('B20')) {
            final adminRow = mosqueB25Row(
              'wf_multi-persona-workflow-evidence',
              'admin',
            );
            final memberRow = mosqueB25Row(
              'wf_multi-persona-workflow-evidence',
              'member',
            );
            String? publishedAnnouncementId;
            final adminResult = await runMosqueRow(
              phase: 'B20',
              workflowId: adminRow.workflowId,
              role: adminRow.role,
              entry: productDocEntry(adminRow),
              walk: () async {
                await ensureTargetOpen(mosqueTarget);
                final publication = await _createAndPublishShippedAnnouncement(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  selector: announcement,
                  adminRoleId: mosqueAdminRoleId,
                  capture: capture,
                  screenshotPrefix: 'B20_announcement',
                  announcementTitle: 'Walkthrough community announcement',
                );
                publishedAnnouncementId = publication.instanceId;
                return dedicatedPass(
                  screenshotNames: const [
                    'B20_announcement_admin_start',
                    'B20_announcement_admin_action',
                    'B20_announcement_admin_alternate_action',
                    'B20_announcement_admin_alternate_result',
                    'B20_announcement_admin_primary_action',
                    'B20_announcement_admin_complete',
                  ],
                  actionProofStatus: publication.productFinding == null
                      ? 'pass'
                      : 'fail',
                  visiblePrimaryActions: const ['publish announcement'],
                  visibleAlternateActions: const ['save draft'],
                  productFindings: publication.productFinding == null
                      ? const <String>[]
                      : [publication.productFinding!],
                  actionExecutionEvidence: [
                    publication.actionExecutionEvidence,
                  ],
                );
              },
            );
            await runMosqueRow(
              phase: 'B20',
              workflowId: memberRow.workflowId,
              role: memberRow.role,
              entry: productDocEntry(memberRow),
              walk: () async {
                if (publishedAnnouncementId == null) {
                  throw B25DependentReceiverBlockedFailure(
                    'B20 member receiver is blocked by the named prerequisite '
                    'B20 admin publication: no published announcement id was '
                    'produced. Admin outcome ${adminResult.rowOutcome}; '
                    'reason ${adminResult.productFindings.firstOrNull ?? '(none recorded)'}.',
                  );
                }
                await ensureTargetOpen(mosqueTarget);
                await selectActorIdentity(tester, mosqueMemberRoleId);
                await _selectPackageTab(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  roleId: mosqueMemberRoleId,
                  tabId: 'home',
                );
                final publishedAnnouncement = find.text(
                  'Walkthrough community announcement',
                );
                await waitForEngineNativeWidget(
                  tester,
                  publishedAnnouncement,
                  description:
                      'published walkthrough announcement for community member',
                );
                await capture('B20_announcement_member_ready');
                final markRead = _packageTransitionByLabel(
                  target: mosqueTarget,
                  machine: announcement.machine,
                  label: 'Mark read',
                );
                final announcementReceiveButton = _engineActionFinder(
                  publishedAnnouncementId!,
                  markRead.id,
                );
                await waitForEngineNativeWidget(
                  tester,
                  announcementReceiveButton,
                  description: 'shipped member announcement receipt action',
                );
                await tester.ensureVisible(announcementReceiveButton.first);
                await capture('B20_announcement_member_action');
                await tester.tap(
                  announcementReceiveButton.first,
                  warnIfMissed: false,
                );
                for (var attempt = 0; attempt < 8; attempt += 1) {
                  await tester.runAsync(
                    () => Future<void>.delayed(const Duration(milliseconds: 5)),
                  );
                  await tester.pump(const Duration(milliseconds: 100));
                }
                expect(
                  announcementReceiveButton,
                  findsNothing,
                  reason:
                      'The shipped member receipt action did not mark the '
                      'published announcement as read.',
                );
                // Nothing acts between this capture and the one just above
                // it, so a second capture named `_alternate_unavailable`
                // here would only reproduce `_member_received` byte-for-byte
                // -- the same manufactured-duplicate shape as the B25 row
                // sites this ticket fixes, found by sweeping this file for
                // any other adjacent `capture()` pair with nothing between.
                await capture('B20_announcement_member_received');
                await _selectPackageTab(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  roleId: mosqueMemberRoleId,
                  tabId: 'calendar',
                );
                await capture('B20_member_calendar_tab_pinned_event');
                await _selectPackageTab(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  roleId: mosqueMemberRoleId,
                  tabId: 'messages',
                );
                await capture('B20_member_messages_tab');
                await selectActorIdentity(tester, mosqueAdminRoleId);
                await _selectPackageTab(
                  tester: tester,
                  target: mosqueTarget,
                  package: mosquePackage,
                  roleId: mosqueAdminRoleId,
                  tabId: 'admin',
                );
                await capture('B20_admin_custom_tab_pinned_surface');
                return dedicatedPass(
                  screenshotNames: const [
                    'B20_announcement_member_ready',
                    'B20_announcement_member_action',
                    'B20_announcement_member_received',
                    'B20_member_calendar_tab_pinned_event',
                    'B20_member_messages_tab',
                    'B20_admin_custom_tab_pinned_surface',
                  ],
                  actionProofStatus: 'fail',
                  visiblePrimaryActions: const [
                    'receive announcement',
                    'mark read',
                  ],
                  productFindings: [
                    '${memberRow.communityName} / ${memberRow.workflowId} / '
                        '${memberRow.role}: the shipped announcement offers '
                        '`Mark read` to a member, but no member-visible '
                        '`Archive`, `Request follow-up`, or `Keep unread` action.',
                  ],
                );
              },
            );
          }

          await assertB25CommunityRowSurface(
            tester: tester,
            target: mosqueTarget,
            workflowId: mosqueLastRowWalked?.split('/').first ?? 'setup',
            role: mosqueLastRole,
            boundary: 'dedicated-after',
            captureDiagnostic: capture,
          );
          await tearDownB25CommunityWalkthrough(
            tester: tester,
            target: mosqueTarget,
            lastRowWalked: mosqueLastRowWalked,
            pumpAfterBack: () => _pumpB25Frames(tester),
          );
        });
        recordCommunityTraversal(
          B25CommunityTraversalRecord.fromScope(
            scope: mosqueScope,
            phase: const <String>[
              'B20',
              'B19',
              'B18',
              'B17',
            ].firstWhere(_includePhase),
            communityId: mosqueTarget.communityId,
            communityName: mosqueTarget.communityName,
            extensionId: mosqueTarget.extensionId,
            lastRowWalked: mosqueLastRowWalked,
          ),
        );
      }

      final capabilityTargets = <String, LoomEvidenceTarget>{
        for (final target in evidenceTargets) target.extensionId: target,
      };
      var capturedCapabilityCommunityList = false;
      Future<void> runCapabilitySegment<T>({
        required LoomEvidenceTarget target,
        required String workflowId,
        required String role,
        required Future<T> Function() setup,
        required Future<_B25WalkthroughResult> Function(T setup) prepare,
      }) async {
        final scope = await runB25CommunityScope(() async {
          _assertB25AssetCoversTargets(
            catalog: b25InteractionCatalog,
            evidenceTargets: [target],
          );
          await ensureTargetInstalled(target);
          final segmentSetup = await setup();
          emitProgress(
            'workflow-start',
            phase: 'B20',
            workflowId: workflowId,
            communityName: target.communityName,
          );
          currentRowScreenshotNames.clear();
          final rowScope = await runB25WorkflowRowScope(
            () async {
              if (!capturedCapabilityCommunityList) {
                await returnToCommunityList();
                await capture('B20_app_shell_main_community_list_states');
                capturedCapabilityCommunityList = true;
              }
              return prepare(segmentSetup);
            },
            capturedScreenshotNames: () =>
                List<String>.of(currentRowScreenshotNames),
          );
          final result =
              rowScope.value ?? _recordB25RowScopedFailure(rowScope.failure!);
          recordEvidenceEntry({
            'phase': 'B20',
            'appId': 'app-shell-capability-evidence',
            'workflowId': workflowId,
            'capabilitySegment': target.extensionId,
            'role': role,
            'communityId': target.communityId,
            'communityName': target.communityName,
            ...dedicatedResultFields(result),
          });
          emitProgress(
            'workflow-complete',
            phase: 'B20',
            workflowId: workflowId,
            communityName: target.communityName,
            blockedRowOutcome: result.isRecordedFailure
                ? result.rowOutcome
                : null,
          );
          await assertB25CommunityRowSurface(
            tester: tester,
            target: target,
            workflowId: workflowId,
            role: role,
            boundary: 'capability-after',
            captureDiagnostic: capture,
          );
          await tearDownB25CommunityWalkthrough(
            tester: tester,
            target: target,
            lastRowWalked: '$workflowId/$role',
            pumpAfterBack: () => _pumpB25Frames(tester),
          );
        });
        recordCommunityTraversal(
          B25CommunityTraversalRecord.fromScope(
            scope: scope,
            phase: 'B20',
            communityId: target.communityId,
            communityName: target.communityName,
            extensionId: target.extensionId,
            lastRowWalked: '$workflowId/$role',
          ),
        );
      }

      if (_includePhase('B20') &&
          capabilityTargets.containsKey('ext_garden_club')) {
        final target = capabilityTargets['ext_garden_club']!;
        await runCapabilitySegment(
          target: target,
          workflowId: 'wf_app-shell-capability-evidence',
          role: 'member',
          setup: () async {
            final package = await readShippedEvidencePackage(target);
            final memberRoleId = _packageRoleId(
              target: target,
              package: package,
              label: 'Member',
            );
            final rsvp = _shippedWorkflowSelector(
              target: target,
              package: package,
              workflowType: 'garden-event-rsvp',
            );
            return (package: package, memberRoleId: memberRoleId, rsvp: rsvp);
          },
          prepare: (setup) async {
            final package = setup.package;
            final memberRoleId = setup.memberRoleId;
            final rsvp = setup.rsvp;
            await ensureTargetOpen(target);
            await selectActorIdentity(tester, memberRoleId);
            await _selectPackageTab(
              tester: tester,
              target: target,
              package: package,
              roleId: memberRoleId,
              tabId: 'home',
            );
            final instance = _engineInstanceFinder(rsvp.instance.instanceId);
            await waitForEngineNativeWidget(
              tester,
              instance,
              description:
                  'shipped Garden RSVP summary on the package Home binding',
            );
            await tester.ensureVisible(instance.first);
            await capture('B20_app_shell_garden_home_medium_minimized_stack');
            await _selectPackageTab(
              tester: tester,
              target: target,
              package: package,
              roleId: memberRoleId,
              tabId: 'calendar',
            );
            await _prepareCalendarExpandedShippedWorkflowDetail(
              tester: tester,
              selector: rsvp,
            );
            await capture('B20_app_shell_garden_home_expanded_surface');
            return dedicatedPass(
              screenshotNames: const [
                'B20_app_shell_main_community_list_states',
                'B20_app_shell_garden_home_medium_minimized_stack',
                'B20_app_shell_garden_home_expanded_surface',
              ],
            );
          },
        );
      }

      if (_includePhase('B20') &&
          capabilityTargets.containsKey('ext_cedar_commons_hoa')) {
        final target = capabilityTargets['ext_cedar_commons_hoa']!;
        await runCapabilitySegment(
          target: target,
          workflowId: 'wf_app-shell-capability-evidence',
          role: 'member',
          setup: () => readShippedEvidencePackage(target),
          prepare: (_) async {
            await ensureTargetOpen(target);
            await selectActorIdentity(tester, 'hoa-member');
            await _selectCommunityTab(tester, 'documents');
            await capture('B20_app_shell_hoa_documents_pinning_policy');
            return dedicatedPass(
              screenshotNames: const [
                'B20_app_shell_hoa_documents_pinning_policy',
              ],
            );
          },
        );
      }

      if (_includePhase('B20') &&
          capabilityTargets.containsKey('ext_youth_soccer')) {
        final target = capabilityTargets['ext_youth_soccer']!;
        await runCapabilitySegment(
          target: target,
          workflowId: 'wf_app-shell-capability-evidence',
          role: 'coach',
          setup: () async {
            final package = await readShippedEvidencePackage(target);
            final coachRoleId = _packageRoleId(
              target: target,
              package: package,
              label: 'Coach',
            );
            final roster = _shippedWorkflowSelector(
              target: target,
              package: package,
              workflowType: 'soccer-team-roster',
            );
            return (package: package, coachRoleId: coachRoleId, roster: roster);
          },
          prepare: (setup) async {
            final package = setup.package;
            final coachRoleId = setup.coachRoleId;
            final roster = setup.roster;
            await ensureTargetOpen(target);
            await _showShippedWorkflowInstance(
              tester: tester,
              target: target,
              package: package,
              selector: roster,
              roleId: coachRoleId,
            );
            await capture('B20_app_shell_soccer_roster_renderer_medium');
            await _expandShippedWorkflowSurface(
              tester: tester,
              selector: roster,
            );
            await capture('B20_app_shell_soccer_roster_renderer_expanded');
            await _closeExpandedShippedWorkflowSurface(
              tester: tester,
              selector: roster,
            );
            return dedicatedPass(
              screenshotNames: const [
                'B20_app_shell_soccer_roster_renderer_medium',
                'B20_app_shell_soccer_roster_renderer_expanded',
              ],
            );
          },
        );
      }

      if (communityTraversals.isEmpty) {
        await returnToCommunityList();
      } else {
        final lastTraversalIndex = communityTraversals.length - 1;
        final finalCleanup = await runB25CommunityScope(returnToCommunityList);
        if (!finalCleanup.completed) {
          communityTraversals[lastTraversalIndex] =
              communityTraversals[lastTraversalIndex].withFinalCleanupFailure(
                'B25 final cleanup failed after '
                '${communityTraversals[lastTraversalIndex].lastRowWalked ?? 'no row'}:\n'
                '${finalCleanup.failure!.reason}',
              );
          binding.reportData!['b25CommunityTraversals'] = [
            for (final traversal in communityTraversals)
              traversal.toReportData(),
          ];
          bodyWatch.beat(
            lastCompletedStep:
                'final cleanup failed for ${communityTraversals[lastTraversalIndex].communityName}',
            attemptedStep:
                'finalising the walkthrough report after cleanup failure',
            waitingFor: 'report finalisation',
          );
        }
      }

      screenshotCapture.finish();
      binding.reportData!['workflowEvidenceSchemaVersion'] = 2;
      binding.reportData!['workflowEvidence'] = entries;
      binding.reportData!['b25CommunityTraversals'] = [
        for (final traversal in communityTraversals) traversal.toReportData(),
      ];
      binding.reportData!['b25TraversalFinalised'] = true;
      binding.reportData!['b25WalkthroughSummary'] =
          _summarizeB25WalkthroughRows(entries);
      binding.reportData!['screenshotVisibleTextByName'] =
          screenshotVisibleTextByName;
      binding.reportData!['walkthroughStatus'] =
          communityTraversals.any((traversal) => traversal.isIncomplete)
          ? 'fail'
          : 'pass';
      _emitCaptureProgress({
        'status': 'run-complete',
        'completedWorkflows': completedWorkflowEvidenceEntries,
        'blockedByAudienceWorkflows': blockedByAudienceWorkflowEvidenceEntries,
        'blockedBySelectorSetupWorkflows':
            blockedBySelectorSetupWorkflowEvidenceEntries,
        'blockedByPrerequisiteWorkflows':
            blockedByPrerequisiteWorkflowEvidenceEntries,
        'actionSucceededResultUnverifiedWorkflows':
            actionSucceededResultUnverifiedWorkflowEvidenceEntries,
        'productFindingWorkflows': productFindingWorkflowEvidenceEntries,
        'rowExecutionFailedWorkflows':
            rowExecutionFailedWorkflowEvidenceEntries,
        'totalWorkflows': totalWorkflowEvidenceEntries,
      });
    }

    await watchWalkthroughBodyWith<void>(runWalkthrough(), bodyWatch);
  });
}

Future<void> _capture(
  _ScreenshotCaptureRecorder screenshotCapture,
  WidgetTester tester,
  Map<String, String> screenshotVisibleTextByName,
  String name,
) async {
  await tester.pump();
  screenshotVisibleTextByName[name] = _visibleTextFor(tester);
  await screenshotCapture.capture(name);
}

class _ScreenshotCaptureRecorder {
  _ScreenshotCaptureRecorder({
    required this.binding,
    required this.tester,
    required this.reportData,
    required this.externalAndroidScreenshots,
  }) {
    _syncReportData();
  }

  final IntegrationTestWidgetsFlutterBinding binding;
  final WidgetTester tester;
  final Map<String, dynamic> reportData;
  final bool externalAndroidScreenshots;
  final List<String> _requestedNames = <String>[];
  final List<String> _completedNames = <String>[];
  final List<String> _unavailableNames = <String>[];
  String? _unavailableReason;
  bool _finished = false;

  Future<void> capture(String name) async {
    _requestedNames.add(name);
    if (_unavailableReason != null) {
      _unavailableNames.add(name);
      _syncReportData();
      return;
    }

    try {
      if (externalAndroidScreenshots) {
        // The host capture CLI starts adb screencap when it receives the
        // screenshot-start progress event. Hold this exact rendered state
        // long enough for the host-side PNG write to finish before the
        // walkthrough can advance.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 8)),
        );
      } else {
        await binding.takeScreenshot(name);
      }
      _completedNames.add(name);
    } on MissingPluginException catch (error) {
      _unavailableReason = error.toString();
      _unavailableNames.add(name);
      debugPrint(
        'SCREENSHOT_CAPTURE_UNAVAILABLE '
        'platform=${defaultTargetPlatform.name} method=captureScreenshot '
        'screenshot=$name error=$_unavailableReason. '
        'Walkthrough assertions will continue, but completion evidence remains blocked.',
        wrapWidth: 2048,
      );
    }
    _syncReportData();
  }

  void finish() {
    _finished = true;
    _syncReportData();
    debugPrint(
      'SCREENSHOT_CAPTURE_SUMMARY '
      'status=${_unavailableReason == null ? 'complete' : 'unavailable'} '
      'platform=${defaultTargetPlatform.name} '
      'requested=${_requestedNames.length} completed=${_completedNames.length} '
      'unavailable=${_unavailableNames.length}',
      wrapWidth: 2048,
    );
  }

  void _syncReportData() {
    reportData['screenshotCapture'] = <String, Object?>{
      'status': _unavailableReason != null
          ? 'unavailable'
          : _finished
          ? 'complete'
          : 'in-progress',
      'platform': defaultTargetPlatform.name,
      'method': externalAndroidScreenshots
          ? 'host-adb-screencap'
          : 'captureScreenshot',
      'requestedCount': _requestedNames.length,
      'completedCount': _completedNames.length,
      'unavailableCount': _unavailableNames.length,
      'requestedScreenshotNames': List<String>.of(_requestedNames),
      'unavailableScreenshotNames': List<String>.of(_unavailableNames),
      if (_unavailableReason != null) 'reason': _unavailableReason,
    };
  }
}

String _visibleTextFor(WidgetTester tester) {
  final seen = <String>{};
  final chunks = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final raw = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty || !seen.add(clean)) {
      continue;
    }
    chunks.add(clean);
    if (chunks.length >= 80) {
      break;
    }
  }
  return chunks.join(' | ');
}

void _emitCaptureProgress(Map<String, Object?> event) {
  debugPrint(
    'B25_CAPTURE_PROGRESS ${jsonEncode({'emittedAt': DateTime.now().toUtc().toIso8601String(), ...event})}',
    wrapWidth: 2048,
  );
}

String _phaseForScreenshotName(String name) {
  final separator = name.indexOf('_');
  return separator == -1 ? 'unknown' : name.substring(0, separator);
}

List<String> _requestedEvidencePhases(
  List<LoomEvidenceTarget> evidenceTargets,
) {
  const orderedPhases = <String>[
    'B12',
    'B13',
    'B14',
    'B15',
    'B16',
    'B17',
    'B18',
    'B19',
    'B20',
  ];
  final selectedExtensionIds = {
    for (final target in evidenceTargets) target.extensionId,
  };
  final requestedPhases = <String>{
    if (_includePhase('B12')) 'B12',
    for (final target in evidenceTargets)
      if (_includePhase(target.phase)) target.phase,
    if (selectedExtensionIds.contains('ext_mosque'))
      for (final phase in const ['B17', 'B18', 'B19', 'B20'])
        if (_includePhase(phase)) phase,
    if (selectedExtensionIds.intersection(const {
          'ext_garden_club',
          'ext_cedar_commons_hoa',
          'ext_youth_soccer',
        }).isNotEmpty &&
        _includePhase('B20'))
      'B20',
  };
  return orderedPhases.where(requestedPhases.contains).toList(growable: false);
}

Map<String, Object?> _evidenceDeviceMetadata() {
  final platform = defaultTargetPlatform.name;
  return <String, Object?>{
    'platform': platform,
    'deviceName': switch (defaultTargetPlatform) {
      TargetPlatform.android => 'emulator-5554',
      TargetPlatform.linux => 'linux-desktop',
      _ => '$platform-device',
    },
    'emulatorName': switch (defaultTargetPlatform) {
      TargetPlatform.android => 'emulator-5554',
      TargetPlatform.linux => 'linux-desktop',
      _ => '$platform-device',
    },
    'deviceClass': switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android emulator',
      TargetPlatform.linux => 'Linux desktop',
      _ => '${platform[0].toUpperCase()}${platform.substring(1)} device',
    },
    if (defaultTargetPlatform == TargetPlatform.android)
      'apiLevel': 'Android 16 API 36',
  };
}

int _workflowEvidenceEntryCount(
  List<LoomEvidenceTarget> evidenceTargets,
  B25ProductDocInteractionCatalog b25InteractionCatalog,
) {
  return _workflowEvidenceEntryCountByPhase(
    evidenceTargets,
    b25InteractionCatalog,
  ).values.fold(0, (total, count) => total + count);
}

Map<String, int> _workflowEvidenceEntryCountByPhase(
  List<LoomEvidenceTarget> evidenceTargets,
  B25ProductDocInteractionCatalog b25InteractionCatalog,
) {
  final counts = <String, int>{
    for (final phase in _requestedEvidencePhases(evidenceTargets)) phase: 0,
  };
  if (_includePhase('B12')) {
    counts['B12'] = 1;
  }
  var targetWorkflowOrdinal = 0;
  for (final target in evidenceTargets.where(
    (target) => _includePhase(target.phase),
  )) {
    for (final _ in b25InteractionCatalog.models.where(
      (row) =>
          row.communityId == target.communityId &&
          !_b25RowUsesDedicatedRoleWalkthrough(row),
    )) {
      final workflowOrdinal = targetWorkflowOrdinal;
      targetWorkflowOrdinal += 1;
      if (_includeWorkflowShard(workflowOrdinal)) {
        counts.update(target.phase, (count) => count + 1);
      }
    }
  }
  final selectedExtensionIds = {
    for (final target in evidenceTargets) target.extensionId,
  };
  if (_includePhase('B17') && selectedExtensionIds.contains('ext_mosque')) {
    counts['B17'] = 1;
  }
  if (_includePhase('B18') && selectedExtensionIds.contains('ext_mosque')) {
    counts['B18'] = 1;
  }
  if (_includePhase('B19') && selectedExtensionIds.contains('ext_mosque')) {
    counts['B19'] = 2;
  }
  if (_includePhase('B20')) {
    if (selectedExtensionIds.contains('ext_mosque')) {
      counts.update('B20', (count) => count + 2);
    }
    final capabilitySegmentCount = selectedExtensionIds.intersection(const {
      'ext_garden_club',
      'ext_cedar_commons_hoa',
      'ext_youth_soccer',
    }).length;
    if (capabilitySegmentCount > 0) {
      counts.update('B20', (count) => count + capabilitySegmentCount);
    }
  }
  return counts;
}

void _assertB25AssetCoversTargets({
  required B25ProductDocInteractionCatalog catalog,
  required List<LoomEvidenceTarget> evidenceTargets,
}) {
  expect(catalog.models, hasLength(kB25ProductDocInteractionRowCount));
  final rowCommunityIds = {for (final row in catalog.models) row.communityId};
  for (final target in evidenceTargets) {
    expect(
      rowCommunityIds,
      contains(target.communityId),
      reason:
          'The bundled B25 interaction-model asset contains no product-doc '
          'rows for ${target.communityName} (${target.communityId}).',
    );
  }
}

bool _b25RowUsesDedicatedRoleWalkthrough(B25ProductDocInteractionModel row) {
  return row.communityId == 'community_mosque' &&
      const <String>{
        'wf_demo-app-persona-picker',
        'wf_community-persona-aware-ux',
        'wf_multi-persona-workflow-evidence',
      }.contains(row.workflowId);
}

List<LoomEvidenceTarget> _evidenceTargetsForRun() {
  final availableExtensionIds = {
    for (final target in loomEvidenceTargets) target.extensionId,
  };
  final unknownExtensionIds = _communityFilter.difference(
    availableExtensionIds,
  );
  final filterWasSet = _communityFilterText.trim().isNotEmpty;
  if ((filterWasSet && _communityFilter.isEmpty) ||
      unknownExtensionIds.isNotEmpty) {
    final requested = _communityFilter.toList()..sort();
    final unknown = unknownExtensionIds.toList()..sort();
    final available = availableExtensionIds.toList()..sort();
    throw StateError(
      'Invalid LOOM_EVIDENCE_COMMUNITY_FILTER: '
      'requested=${requested.isEmpty ? '[${_communityFilterText.trim()}]' : requested}, '
      'unknown=$unknown, available=$available.',
    );
  }
  if (_communityFilter.isEmpty) {
    return loomEvidenceTargets;
  }
  return loomEvidenceTargets
      .where((target) => _communityFilter.contains(target.extensionId))
      .toList(growable: false);
}

String _b25ScreenshotName(
  LoomEvidenceTarget target,
  B25ProductDocInteractionModel model,
  String state,
) {
  return '${target.phase}_${target.extensionId}_${model.workflowId}_${model.role}_$state';
}

bool _includePhase(String phase) {
  return _phaseFilter.isEmpty || _phaseFilter.contains(phase);
}

bool _includeWorkflowShard(int workflowOrdinal) {
  if (_workflowShardCount <= 1) {
    return true;
  }
  if (_workflowShardIndex < 0 || _workflowShardIndex >= _workflowShardCount) {
    return true;
  }
  return workflowOrdinal % _workflowShardCount == _workflowShardIndex;
}

Map<String, Object?> _summarizeB25WalkthroughRows(
  Iterable<Map<String, Object?>> entries,
) {
  const blockedOutcomes = <String>{
    'blocked_by_audience',
    'blocked_by_selector_setup',
    'blocked_by_prerequisite',
  };
  final rows = entries
      .where((entry) => entry['b25RowOutcome'] is String)
      .toList(growable: false);
  final blockedRows = rows
      .where((entry) => blockedOutcomes.contains(entry['b25RowOutcome']))
      .toList(growable: false);
  final blockedByAudienceRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_audience')
      .toList(growable: false);
  final blockedBySelectorSetupRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_selector_setup')
      .toList(growable: false);
  final blockedByPrerequisiteRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_prerequisite')
      .toList(growable: false);
  final primaryUnavailableRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'primary_action_unavailable')
      .toList(growable: false);
  final actionSucceededResultUnverifiedRows = rows
      .where(
        (entry) =>
            entry['b25RowOutcome'] == 'action_succeeded_result_unverified',
      )
      .toList(growable: false);
  final productFindingRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'product_finding')
      .toList(growable: false);
  final rowExecutionFailedRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'row_execution_failed')
      .toList(growable: false);
  final provenRows = rows
      .where(
        (entry) =>
            entry['b25RowOutcome'] == 'attempted' &&
            entry['b25ActionProofStatus'] == 'pass',
      )
      .toList(growable: false);
  final completedRows = rows
      .where((entry) => !blockedOutcomes.contains(entry['b25RowOutcome']))
      .toList(growable: false);

  Map<String, int> countByCommunity(Iterable<Map<String, Object?>> blocked) {
    final counts = <String, int>{};
    for (final row in blocked) {
      final communityName = row['communityName'] as String? ?? '(unknown)';
      counts.update(communityName, (count) => count + 1, ifAbsent: () => 1);
    }
    return <String, int>{
      for (final communityName in counts.keys.toList()..sort())
        communityName: counts[communityName]!,
    };
  }

  List<Map<String, Object?>> reasonGroups(
    Iterable<Map<String, Object?>> blocked, {
    required String causeField,
    required String reasonField,
  }) {
    final rowsByCause = <String, List<Map<String, Object?>>>{};
    for (final row in blocked) {
      final cause = row[causeField] as String? ?? '(unknown)';
      rowsByCause.putIfAbsent(cause, () => <Map<String, Object?>>[]).add(row);
    }
    return <Map<String, Object?>>[
      for (final cause in rowsByCause.keys.toList()..sort())
        <String, Object?>{
          'cause': cause,
          'count': rowsByCause[cause]!.length,
          'rows': <Map<String, Object?>>[
            for (final row in rowsByCause[cause]!)
              <String, Object?>{
                'communityName': row['communityName'],
                'workflowId': row['workflowId'],
                'role': row['role'],
                'reason': row[reasonField],
              },
          ],
        },
    ];
  }

  String nonProvenReason(Map<String, Object?> row) {
    String? reason;
    switch (row['b25RowOutcome']) {
      case 'blocked_by_audience':
        reason = row['blockedByAudienceReason'] as String?;
        break;
      case 'blocked_by_selector_setup':
        reason = row['blockedBySelectorSetupReason'] as String?;
        break;
      case 'blocked_by_prerequisite':
        reason = row['blockedByPrerequisiteReason'] as String?;
        break;
      case 'action_succeeded_result_unverified':
        reason = row['actionSucceededResultUnverifiedReason'] as String?;
        break;
      case 'row_execution_failed':
        reason = row['rowExecutionFailureReason'] as String?;
        break;
    }
    if (reason == null) {
      final findings = row['productFindings'];
      if (findings is Iterable) {
        reason = findings.whereType<String>().firstOrNull;
      }
    }
    if (reason == null || reason.isEmpty) {
      throw StateError(
        'B25 non-proven row ${row['workflowId']}/${row['role']} has no '
        'verbatim recorded reason.',
      );
    }
    return reason;
  }

  final explicitBlockedRows =
      <Map<String, Object?>>[
        for (final row in blockedRows)
          <String, Object?>{
            'outcome': row['b25RowOutcome'],
            'communityName': row['communityName'],
            'workflowId': row['workflowId'],
            'role': row['role'],
            'reason': row['b25RowOutcome'] == 'blocked_by_audience'
                ? row['blockedByAudienceReason']
                : row['b25RowOutcome'] == 'blocked_by_selector_setup'
                ? row['blockedBySelectorSetupReason']
                : row['blockedByPrerequisiteReason'],
          },
      ]..sort(
        (
          left,
          right,
        ) => '${left['outcome']}/${left['communityName']}/${left['workflowId']}/${left['role']}'
            .compareTo(
              '${right['outcome']}/${right['communityName']}/${right['workflowId']}/${right['role']}',
            ),
      );
  final explicitNonProvenRows =
      <Map<String, Object?>>[
        for (final row in rows)
          if (row['b25ActionProofStatus'] != 'pass')
            <String, Object?>{
              'outcome': row['b25RowOutcome'],
              'communityName': row['communityName'],
              'workflowId': row['workflowId'],
              'role': row['role'],
              'reason': nonProvenReason(row),
            },
      ]..sort(
        (
          left,
          right,
        ) => '${left['outcome']}/${left['communityName']}/${left['workflowId']}/${left['role']}'
            .compareTo(
              '${right['outcome']}/${right['communityName']}/${right['workflowId']}/${right['role']}',
            ),
      );
  return <String, Object?>{
    'recordedRows': rows.length,
    'provenRows': provenRows.length,
    'completedRows': completedRows.length,
    'primaryActionUnavailableRows': primaryUnavailableRows.length,
    'blockedRows': explicitBlockedRows,
    'nonProvenRows': explicitNonProvenRows,
    'blockedByAudienceRows': blockedByAudienceRows.length,
    'blockedByAudienceRowsByCommunity': countByCommunity(blockedByAudienceRows),
    'blockedByAudienceReasonGroups': reasonGroups(
      blockedByAudienceRows,
      causeField: 'blockedByAudienceCause',
      reasonField: 'blockedByAudienceReason',
    ),
    'blockedBySelectorSetupRows': blockedBySelectorSetupRows.length,
    'blockedBySelectorSetupRowsByCommunity': countByCommunity(
      blockedBySelectorSetupRows,
    ),
    'blockedBySelectorSetupReasonGroups': reasonGroups(
      blockedBySelectorSetupRows,
      causeField: 'blockedBySelectorSetupCause',
      reasonField: 'blockedBySelectorSetupReason',
    ),
    'blockedByPrerequisiteRows': blockedByPrerequisiteRows.length,
    'blockedByPrerequisiteRowsByCommunity': countByCommunity(
      blockedByPrerequisiteRows,
    ),
    'blockedByPrerequisiteReasonGroups': reasonGroups(
      blockedByPrerequisiteRows,
      causeField: 'b25RowOutcome',
      reasonField: 'blockedByPrerequisiteReason',
    ),
    'actionSucceededResultUnverifiedRows':
        actionSucceededResultUnverifiedRows.length,
    'actionSucceededResultUnverifiedRowsByCommunity': countByCommunity(
      actionSucceededResultUnverifiedRows,
    ),
    'productFindingRows': productFindingRows.length,
    'productFindingRowsByCommunity': countByCommunity(productFindingRows),
    'rowExecutionFailedRows': rowExecutionFailedRows.length,
    'rowExecutionFailedRowsByCommunity': countByCommunity(
      rowExecutionFailedRows,
    ),
  };
}

Future<_B25WalkthroughResult> _recordB25AudienceBlockedWorkflow({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required B25ProductDocInteractionModel b25Model,
  required String reason,
  required String cause,
  required Future<void> Function(String name) capture,
}) async {
  // There is deliberately no screenshot here. The package cannot render this
  // row for the selected role, so capturing a neighbouring screen would be
  // false evidence. The before and after boundary assertions instead prove the
  // walkthrough stayed on the expected community and moved on.
  await assertB25CommunityRowSurface(
    tester: tester,
    target: target,
    workflowId: b25Model.workflowId,
    role: b25Model.role,
    boundary: 'blocked-by-audience',
    captureDiagnostic: capture,
  );
  return _B25WalkthroughResult(
    screenshotNames: const <String>[],
    actionProofStatus: 'blocked_by_audience',
    visiblePrimaryActions: const <String>[],
    visibleAlternateActions: const <String>[],
    availableSupplementaryActions: const <String>[],
    productFindings: <String>[reason],
    rowOutcome: 'blocked_by_audience',
    blockedByAudienceReason: reason,
    blockedByAudienceCause: cause,
  );
}

Future<_B25WalkthroughResult> _recordB25SelectorSetupBlockedWorkflow({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required B25ProductDocInteractionModel b25Model,
  required String reason,
  required String cause,
  required Future<void> Function(String name) capture,
}) async {
  // As for an audience block, a selector-setup block has no row-specific
  // screen to capture. A neighbouring frame would falsely imply that this row
  // rendered or completed, so boundary assertions prove safe continuation.
  await assertB25CommunityRowSurface(
    tester: tester,
    target: target,
    workflowId: b25Model.workflowId,
    role: b25Model.role,
    boundary: 'blocked-by-selector-setup',
    captureDiagnostic: capture,
  );
  return _B25WalkthroughResult(
    screenshotNames: const <String>[],
    actionProofStatus: 'blocked_by_selector_setup',
    visiblePrimaryActions: const <String>[],
    visibleAlternateActions: const <String>[],
    availableSupplementaryActions: const <String>[],
    productFindings: <String>[reason],
    rowOutcome: 'blocked_by_selector_setup',
    blockedBySelectorSetupReason: reason,
    blockedBySelectorSetupCause: cause,
  );
}

Future<_B25WalkthroughResult> _runB25ShippedWorkflowWalkthrough({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required WalkthroughBodyWatch bodyWatch,
  required _ShippedWorkflowSelector selector,
  required B25ProductDocInteractionModel b25Model,
  required Future<void> Function(String name) capture,
}) async {
  await assertB25CommunityRowSurface(
    tester: tester,
    target: target,
    workflowId: b25Model.workflowId,
    role: b25Model.role,
    boundary: 'before',
    captureDiagnostic: capture,
  );
  final communitySurface = evidenceTargetRoute(target);
  void beatSubstep(
    WalkthroughSubstep substep, {
    String? account,
    String? role,
    String? tabId,
  }) {
    final progress = buildWalkthroughSubstepProgress(
      substep,
      account: account,
      role: role,
      tabId: tabId,
      workflow: selector.machine.workflowType,
      phase: target.phase,
      community: target.communityName,
    );
    bodyWatch.beat(
      attemptedStep: progress.attemptedStep,
      waitingFor: progress.waitingFor,
    );
  }

  if (selector.accountId case final accountId?) {
    final displayName = 'Shipped $accountId';
    beatSubstep(
      WalkthroughSubstep.seedingEvidenceAccounts,
      account: accountId,
      role: selector.roleId,
    );
    await seedEvidenceAccounts(tester, target, [
      LoomAccount(
        accountId: accountId,
        displayName: displayName,
        roleId: selector.roleId,
      ),
    ]);
    beatSubstep(
      WalkthroughSubstep.signingInEvidenceAccount,
      account: displayName,
    );
    await signInEvidenceAccount(tester, displayName);
  } else {
    beatSubstep(
      WalkthroughSubstep.selectingActorIdentity,
      role: selector.roleId,
    );
    await selectActorIdentity(tester, selector.roleId);
  }
  beatSubstep(WalkthroughSubstep.verifyingExperienceTagline);
  expect(find.text(package.experience.tagline), findsOneWidget);

  final resolvedTabs = appShellTabsFor(
    experience: package.experience,
    roleId: selector.roleId,
    appShellConfiguration: package.appShellConfiguration,
  );
  expect(
    resolvedTabs.map((tab) => tab.tabId),
    contains(selector.binding.tabId),
    reason:
        'Shipped package ${target.extensionId} selected workflow '
        '${selector.machine.workflowType} on tab ${selector.binding.tabId}, '
        'but that same package did not expose the tab for '
        '${selector.roleId}.',
  );
  beatSubstep(
    WalkthroughSubstep.selectingCommunityTab,
    tabId: selector.binding.tabId,
  );
  await _selectCommunityTab(tester, selector.binding.tabId);

  final instance = _engineInstanceFinder(selector.instance.instanceId);
  beatSubstep(
    WalkthroughSubstep.waitingForEngineNativeWidget,
    tabId: selector.binding.tabId,
  );
  await waitForEngineNativeWidget(
    tester,
    instance,
    description:
        'shipped ${selector.machine.workflowType} instance '
        '${selector.instance.instanceId} on ${selector.binding.tabId}',
  );
  await _pumpB25Frames(tester);

  final start = _b25ScreenshotName(target, b25Model, 'start');
  final action = _b25ScreenshotName(target, b25Model, 'primary_action');
  final primaryResult = _b25ScreenshotName(target, b25Model, 'primary_result');
  await capture(start);

  final lastCompletedStep =
      'phase ${target.phase}, community ${target.communityName}, '
      'workflow ${b25Model.workflowId}, role ${b25Model.role}, '
      'screenshot $start';
  final attemptedStep =
      'waiting for a tappable shipped workflow action for '
      '${b25Model.workflowId} instance ${selector.instance.instanceId} '
      'on the ${selector.binding.tabId} tab';
  final stallDiagnosticName =
      '${target.phase}_${target.extensionId}_'
      '${b25Model.workflowId}_${b25Model.role}_STALL_DIAGNOSTIC';

  final primaryCandidates = selector.transitions
      .where(
        (candidate) => matchB25TransitionAgainstTerms(
          candidate.transition,
          primaryTerms: b25Model.requiredPrimaryActions,
          alternateTerms: b25Model.requiredAlternateActions,
        ).primary,
      )
      .toList(growable: false);
  if (primaryCandidates.isEmpty) {
    // `start` is captured at the top of the tab and may not show the
    // instance itself (see positionUnavailableInstanceEvidence). This frame
    // does not prove an action -- no tap sits between it and `start`, and
    // the actionProof closure rule in _b25WalkthroughResult only applies to
    // rowOutcome == 'attempted', which this row never becomes -- it exists
    // only to put the instance in view for the reader.
    final unavailableFrame = _b25ScreenshotName(
      target,
      b25Model,
      'primary_action_unavailable',
    );
    await positionUnavailableInstanceEvidence(
      tester: tester,
      instanceId: selector.instance.instanceId,
    );
    await _pumpB25Frames(tester);
    await capture(unavailableFrame);
    return _b25WalkthroughResult(
      model: b25Model,
      selector: selector,
      screenshotNames: [start, unavailableFrame],
      primaryUnavailableReason:
          'primary_action_unavailable: no primary action candidates were '
          'selected for this workflow row.',
    );
  }
  MarketplaceActionSurfacePreparation? marketplacePreparation;
  Object? originalFailure;
  try {
    final preparedMarketplace =
        await prepareMarketplaceActionSurfaceForActionPolling(
          tester: tester,
          surface: communitySurface,
          tabId: selector.binding.tabId,
          instanceId: selector.instance.instanceId,
        );
    marketplacePreparation = preparedMarketplace;
    if (!preparedMarketplace.isReadyForActionPolling) {
      return _throwShippedWorkflowActionStall(
        bodyWatch: bodyWatch,
        lastCompletedStep: lastCompletedStep,
        attemptedStep: attemptedStep,
        waitingFor:
            'Marketplace action surface preparation did not complete: '
            '${preparedMarketplace.preparationFailureDescription}',
        budget: WalkthroughWaitBudget(),
        diagnosticFrameName: stallDiagnosticName,
        captureDiagnostic: capture,
      );
    }
    final actionWait = await _waitForShippedWorkflowAction(
      tester: tester,
      bodyWatch: bodyWatch,
      selector: selector,
      surface: communitySurface,
      actionSurface: preparedMarketplace.actionSurface,
      marketplacePreparation: preparedMarketplace,
      useMarketplaceDetailActionFinder:
          preparedMarketplace.isMarketplaceSurface,
      candidates: primaryCandidates,
      b25Model: b25Model,
      lastCompletedStep: lastCompletedStep,
      attemptedStep: attemptedStep,
      diagnosticFrameName: stallDiagnosticName,
      captureDiagnostic: capture,
    );
    if (actionWait.action == null) {
      // The wait returned null because nothing became tappable. See the
      // sibling `primaryCandidates.isEmpty` branch above for why this frame
      // does not prove an action. For a marketplace row, preparation has
      // already opened the detail dialog above; positionUnavailableInstanceEvidence
      // leaves it open rather than scrolling the tile behind it, since the
      // open dialog IS the instance view at this point.
      final unavailableFrame = _b25ScreenshotName(
        target,
        b25Model,
        'primary_action_unavailable',
      );
      await positionUnavailableInstanceEvidence(
        tester: tester,
        instanceId: selector.instance.instanceId,
        marketplacePreparation: marketplacePreparation,
      );
      await _pumpB25Frames(tester);
      await capture(unavailableFrame);
      return _b25WalkthroughResult(
        model: b25Model,
        selector: selector,
        screenshotNames: [start, unavailableFrame],
        primaryUnavailableReason: actionWait.unavailableReason,
        availableSupplementaryActions: actionWait.otherAvailableActions,
      );
    }
    final visibleAction = actionWait.action!;
    final sourceInstance = identical(selector.actionMachine, selector.machine)
        ? await _readShippedInstance(
            tester: tester,
            target: target,
            package: package,
            selector: selector,
          )
        : null;
    await tester.ensureVisible(visibleAction.finder.first);
    await _pumpB25Frames(tester);
    await capture(action);

    await tester.tap(visibleAction.finder.first, warnIfMissed: false);
    await tester.pump();
    await _completeShippedTransitionInputs(
      tester: tester,
      transition: visibleAction.candidate.transition,
      roleId: selector.roleId,
    );
    for (var attempt = 0; attempt < 8; attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }

    final transition = visibleAction.candidate.transition;
    final primaryActionExecutionEvidence = _observeB25ActionExecutionAfterTap(
      action: visibleAction.finder,
      transitionId: transition.id,
    );
    final transitionCategory =
        identical(selector.actionMachine, selector.machine)
        ? _classifyShippedTransition(
            transition: transition,
            sourceState: selector.actionSourceState,
            archetypeFamily: selector.actionArchetypeFamily,
            instanceData:
                sourceInstance?.instanceData ?? selector.instance.instanceData,
            actorId: selector.accountId ?? selector.roleId,
            roleId: selector.roleId,
          )
        : visibleAction.candidate.category;
    final targetState = transition.to ?? selector.actionSourceState;
    final targetStateLabel = selector.actionMachine.states[targetState]?.label;
    if (identical(selector.actionMachine, selector.machine) &&
        transitionCategory.requiresSourceInstanceDataChange &&
        sourceInstance != null) {
      final persisted = await _expectShippedInstanceDataChanged(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        sourceInstance: sourceInstance,
      );
      final confirmedPrimaryAction = primaryActionExecutionEvidence
          .withPostcondition('instance_data_changed');
      await _positionConfirmedShippedResultForCapture(
        tester: tester,
        selector: selector,
        transition: transition,
        sourceInstance: sourceInstance,
        persistedInstance: persisted,
      );
      await _expectVisibleShippedAlternateDataPostcondition(
        tester: tester,
        selector: selector,
        transition: transition,
        sourceInstance: sourceInstance,
        persistedInstance: persisted,
      );
      await capture(primaryResult);
      return await _finishB25WalkthroughAfterPrimary(
        tester: tester,
        target: target,
        package: package,
        model: b25Model,
        selector: selector,
        executedPrimary: visibleAction.candidate.transition,
        screenshotNames: [start, action, primaryResult],
        primaryActionProofPair: [action, primaryResult],
        capture: capture,
        actionSurface: marketplacePreparation.actionSurface,
        useMarketplaceDetailActionFinder:
            marketplacePreparation.isMarketplaceSurface,
        actionExecutionEvidence: [confirmedPrimaryAction],
      );
    }
    if (identical(selector.actionMachine, selector.machine) &&
        transitionCategory == _ShippedTransitionCategory.stateChanging) {
      final confirmedPrimaryAction = await _expectShippedInstanceState(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        targetState: targetState,
        transitionId: transition.id,
        actionExecutionEvidence: [primaryActionExecutionEvidence],
      );
      expect(
        visibleAction.finder,
        findsNothing,
        reason:
            'After the state check observed target state $targetState for '
            '${selector.instance.instanceId}, the shipped '
            '${selector.machine.workflowType} surface still offered source '
            'action ${transition.id} from '
            '${selector.actionSourceState}.',
      );
      await _positionConfirmedShippedResultForCapture(
        tester: tester,
        selector: selector,
        transition: transition,
        targetState: targetState,
      );
      await _expectVisibleShippedAlternateStatePostcondition(
        tester: tester,
        selector: selector,
        transition: transition,
        targetState: targetState,
      );
      await capture(primaryResult);
      return await _finishB25WalkthroughAfterPrimary(
        tester: tester,
        target: target,
        package: package,
        model: b25Model,
        selector: selector,
        executedPrimary: visibleAction.candidate.transition,
        screenshotNames: [start, action, primaryResult],
        primaryActionProofPair: [action, primaryResult],
        capture: capture,
        actionSurface: marketplacePreparation.actionSurface,
        useMarketplaceDetailActionFinder:
            marketplacePreparation.isMarketplaceSurface,
        actionExecutionEvidence: [confirmedPrimaryAction],
      );
    }

    bool resultIsVisible() {
      final sourceActionIsUnavailable = visibleAction.finder.evaluate().isEmpty;
      final nextActionVisible = selector.actionMachine
          .transitionsFrom(targetState)
          .any(
            (transition) =>
                transition.id != visibleAction.candidate.transition.id &&
                _engineActionFinder(
                  selector.instance.instanceId,
                  transition.id,
                ).evaluate().isNotEmpty,
          );
      return sourceActionIsUnavailable ||
          (targetStateLabel != null &&
              find.text(targetStateLabel).evaluate().isNotEmpty) ||
          nextActionVisible ||
          instance.evaluate().isEmpty;
    }

    for (var attempt = 0; attempt < 80 && !resultIsVisible(); attempt += 1) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      resultIsVisible(),
      isTrue,
      reason:
          'Shipped workflow ${selector.machine.workflowType} ran '
          '${visibleAction.candidate.transition.id}, but the UI showed neither target '
          'state "$targetStateLabel", a target-state action, nor removal from '
          'the source-state surface.',
    );
    await _positionShippedFallbackResultForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
      targetStateLabel: targetStateLabel,
    );
    await capture(primaryResult);
    return await _finishB25WalkthroughAfterPrimary(
      tester: tester,
      target: target,
      package: package,
      model: b25Model,
      selector: selector,
      executedPrimary: visibleAction.candidate.transition,
      screenshotNames: [start, action, primaryResult],
      primaryActionProofPair: [action, primaryResult],
      capture: capture,
      actionSurface: marketplacePreparation.actionSurface,
      useMarketplaceDetailActionFinder:
          marketplacePreparation.isMarketplaceSurface,
      actionExecutionEvidence: [primaryActionExecutionEvidence],
    );
  } catch (error) {
    originalFailure = error;
    rethrow;
  } finally {
    try {
      if (marketplacePreparation?.isReadyForActionPolling ?? false) {
        await closeMarketplaceActionSurfaceAfterActionPolling(
          tester: tester,
          preparation: marketplacePreparation!,
          expectedSurface: communitySurface,
        );
      }
    } catch (cleanupError, cleanupStackTrace) {
      // Cleanup must never replace the failure that made the walkthrough
      // leave its owned dialog early. The original error is the useful
      // work.
      if (originalFailure == null) {
        Error.throwWithStackTrace(cleanupError, cleanupStackTrace);
      }
    }
  }
}

Future<void> _pumpB25Frames(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Positions the exact rendered postcondition that the next result frame must
/// prove. This deliberately does not scroll an entire instance card: a tall
/// card can be technically visible while its state badge or changed value is
/// still outside the viewport.
Future<void> _positionConfirmedShippedResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  String? targetState,
  WorkflowInstance? sourceInstance,
  WorkflowInstance? persistedInstance,
}) async {
  try {
    await _positionShippedResultForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
      targetState: targetState,
      sourceInstance: sourceInstance,
      persistedInstance: persistedInstance,
    );
  } on B25ResultFramePositioningFailure {
    rethrow;
  } catch (error) {
    throw B25ResultFramePositioningFailure(
      error is StateError ? error.message.toString() : error.toString(),
    );
  }
}

Future<void> _positionShippedResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  String? targetState,
  WorkflowInstance? sourceInstance,
  WorkflowInstance? persistedInstance,
}) async {
  if (targetState != null) {
    await _positionShippedStateResultForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
      targetState: targetState,
    );
    return;
  }
  if (sourceInstance != null && persistedInstance != null) {
    await _positionShippedDataResultForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
      sourceInstance: sourceInstance,
      persistedInstance: persistedInstance,
    );
    return;
  }
  throw B25ResultFramePositioningFailure(
    'Shipped workflow ${selector.machine.workflowType} ran '
    '${transition.id}, but B25 has no persisted semantic postcondition to '
    'position before its result frame.',
  );
}

Future<void> _positionShippedStateResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required String targetState,
}) async {
  final stateLabel = selector.machine.states[targetState]?.label;
  if (stateLabel == null) {
    throw B25ResultFramePositioningFailure(
      'Shipped workflow ${selector.machine.workflowType} transitioned '
      '${selector.instance.instanceId} with ${transition.id} to undeclared '
      'state $targetState, so B25 cannot position its visible result.',
    );
  }
  final stateBadge = find.byKey(
    ValueKey('generic-instance-state-${selector.instance.instanceId}'),
  );
  final stateLabelFinder = find.descendant(
    of: _shippedResultCardFinder(selector),
    matching: find.text(stateLabel),
  );
  var positionedBadge = false;
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (!positionedBadge && stateBadge.evaluate().isNotEmpty) {
      await tester.ensureVisible(stateBadge.first);
      await _pumpB25Frames(tester);
      positionedBadge = true;
    }
    if (stateLabelFinder.evaluate().isNotEmpty) {
      await tester.ensureVisible(stateLabelFinder.first);
      await tester.pump();
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw B25ResultFramePositioningFailure(
    'Shipped workflow ${selector.machine.workflowType} persisted target '
    'state $targetState after ${transition.id}, but B25 could not locate its '
    'declared state label "$stateLabel" on source instance '
    '${selector.instance.instanceId} to position the result frame.',
  );
}

Future<void> _positionShippedDataResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required WorkflowInstance sourceInstance,
  required WorkflowInstance persistedInstance,
}) async {
  final acknowledgement = _shippedSuccessAcknowledgementFinder(
    selector: selector,
    transition: transition,
  );
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (acknowledgement.evaluate().isNotEmpty) {
      await tester.ensureVisible(acknowledgement.first);
      await tester.pump();
      return;
    }
    for (final card in _shippedResultCardFinder(selector).evaluate()) {
      final cardWidget = card.widget as EngineNativeArchetypeCard;
      final visibility = b25DataChangeVisibility(
        sourceInstanceData: sourceInstance.instanceData,
        resultInstanceData: persistedInstance.instanceData,
        instanceDataSchema: selector.machine.instanceDataSchema,
        displayContext: cardWidget.displayContext,
      );
      // The visible-postcondition gate immediately below this helper owns the
      // detailed failure for a package that excludes every changed key.
      if (visibility.everyChangedKeyIsExcludedByDisplayContext) {
        return;
      }
      final cardFinder = _shippedResultCardElementFinder(card, cardWidget);
      for (final candidates in visibility.renderedTextCandidatesByKey.values) {
        for (final candidate in candidates) {
          final renderedValue = find.descendant(
            of: cardFinder,
            matching: find.text(candidate),
          );
          if (renderedValue.evaluate().isEmpty) continue;
          await tester.ensureVisible(renderedValue.first);
          await tester.pump();
          return;
        }
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw B25ResultFramePositioningFailure(
    'Shipped workflow ${selector.machine.workflowType} changed source '
    'instance data after ${transition.id}, but B25 could not locate a changed '
    'rendered value or explicit success acknowledgement for '
    '${selector.instance.instanceId} to position the result frame.',
  );
}

/// Positions a result that is proved by the rendered response path rather
/// than by a source-instance state or data mutation. This is intentionally
/// loud when no semantic result can be named: an unanchored result frame is
/// not evidence.
Future<void> _positionShippedFallbackResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required String? targetStateLabel,
}) async {
  if (_engineInstanceFinder(selector.instance.instanceId).evaluate().isEmpty) {
    await _positionShippedRemovedResultForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
    );
    return;
  }
  if (targetStateLabel != null) {
    await _positionShippedResultTextForCapture(
      tester: tester,
      selector: selector,
      transition: transition,
      resultText: targetStateLabel,
    );
    return;
  }
  final nextState = transition.to ?? selector.actionSourceState;
  for (final nextTransition in selector.actionMachine.transitionsFrom(
    nextState,
  )) {
    if (nextTransition.id == transition.id) continue;
    final nextAction = _engineActionFinder(
      selector.instance.instanceId,
      nextTransition.id,
    );
    if (nextAction.evaluate().isEmpty) continue;
    await tester.ensureVisible(nextAction.first);
    await tester.pump();
    return;
  }
  fail(
    'Shipped workflow ${selector.machine.workflowType} ran ${transition.id}, '
    'but B25 could not name a persisted state label, receiver action, or '
    'source-instance removal to position its result frame.',
  );
}

Future<void> _positionShippedResultTextForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required String resultText,
}) async {
  final resultTextFinder = find.descendant(
    of: _shippedResultCardFinder(selector),
    matching: find.text(resultText),
  );
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (resultTextFinder.evaluate().isNotEmpty) {
      await tester.ensureVisible(resultTextFinder.first);
      await tester.pump();
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail(
    'Shipped workflow ${selector.machine.workflowType} ran ${transition.id}, '
    'but B25 could not locate "$resultText" on source instance '
    '${selector.instance.instanceId} to position its result frame.',
  );
}

Future<void> _positionShippedRemovedResultForCapture({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
}) async {
  final source = _engineInstanceFinder(selector.instance.instanceId);
  expect(
    source,
    findsNothing,
    reason:
        'Shipped workflow ${selector.machine.workflowType} ran '
        '${transition.id}, but its source instance still rendered while B25 '
        'was preparing a removal-shaped result frame.',
  );
  final enclosingSurface = find.byKey(
    Key('engine-native-bindings-${selector.binding.tabId}'),
  );
  expect(
    enclosingSurface,
    findsWidgets,
    reason:
        'Shipped workflow ${selector.machine.workflowType} removed source '
        'instance ${selector.instance.instanceId}, but B25 could not locate '
        'the ${selector.binding.tabId} list surface to capture that absence.',
  );
  await tester.ensureVisible(enclosingSurface.first);
  await _pumpB25Frames(tester);
}

/// Waits for a rendered, on-screen state label rather than accepting the
/// persisted engine state as evidence of a visible result.
Future<void> _expectVisibleShippedAlternateStatePostcondition({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required String targetState,
}) async {
  final stateLabel = selector.machine.states[targetState]?.label;
  if (stateLabel == null) {
    fail(
      'Shipped workflow ${selector.machine.workflowType} transitioned '
      '${selector.instance.instanceId} with ${transition.id} to undeclared '
      'state $targetState, so B25 cannot verify a visible state result.',
    );
  }
  final postcondition = B25VisiblePostcondition.stateChange(stateLabel);
  for (var attempt = 0; attempt < 80; attempt += 1) {
    for (final surface in _visibleShippedResultSurfaces(tester, selector)) {
      if (postcondition.isSatisfiedBy(surface.viewportTexts)) return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail(
    'Shipped workflow ${selector.machine.workflowType} persisted target '
    'state $targetState after ${transition.id}, but its declared state label '
    '"$stateLabel" was not visible in the captured viewport for source '
    'instance ${selector.instance.instanceId}.',
  );
}

/// Waits for a changed value or an explicitly keyed success acknowledgement
/// in the rendered viewport after the engine has persisted a source effect.
Future<void> _expectVisibleShippedAlternateDataPostcondition({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
  required WorkflowInstance sourceInstance,
  required WorkflowInstance persistedInstance,
}) async {
  B25DataChangeVisibility? latestVisibility;
  String? latestDisplayContext;
  for (var attempt = 0; attempt < 80; attempt += 1) {
    final explicitSuccessAcknowledgement =
        _hasVisibleShippedSuccessAcknowledgement(
          selector: selector,
          transition: transition,
        );
    for (final surface in _visibleShippedResultSurfaces(tester, selector)) {
      final visibility = b25DataChangeVisibility(
        sourceInstanceData: sourceInstance.instanceData,
        resultInstanceData: persistedInstance.instanceData,
        instanceDataSchema: selector.machine.instanceDataSchema,
        displayContext: surface.displayContext,
      );
      latestVisibility = visibility;
      latestDisplayContext = surface.displayContext;
      if (visibility.everyChangedKeyIsExcludedByDisplayContext) {
        final excluded = visibility.excludedDisplayContextsByKey.entries
            .map((entry) => '${entry.key} displayContexts=${entry.value}')
            .join(', ');
        fail(
          'Shipped workflow ${selector.machine.workflowType} changed source '
          'instance data keys ${visibility.changedKeys} after '
          '${transition.id}, but every changed key is excluded from active '
          '${surface.displayContext} display context: $excluded. Render a '
          'changed value or an explicit success acknowledgement on this '
          'captured surface.',
        );
      }
      final postcondition = B25VisiblePostcondition.sourceInstanceEffect(
        visibility,
      );
      if (postcondition.isSatisfiedBy(
        surface.viewportTexts,
        explicitSuccessAcknowledgement: explicitSuccessAcknowledgement,
      )) {
        return;
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  final changedKeys = latestVisibility?.changedKeys ?? const <String>[];
  final displayContext = latestDisplayContext ?? 'no visible source surface';
  final detail = latestVisibility == null
      ? 'The source instance was not rendered in the captured viewport.'
      : 'renderable=${latestVisibility.renderableKeys}, '
            'excluded=${latestVisibility.excludedDisplayContextsByKey}, '
            'undeclared=${latestVisibility.undeclaredKeys}, '
            'emptyResult=${latestVisibility.emptyResultKeys}.';
  fail(
    'Shipped workflow ${selector.machine.workflowType} changed source '
    'instance data keys $changedKeys after ${transition.id}, but no changed '
    'value or explicit success acknowledgement was visible in the active '
    '$displayContext viewport. $detail',
  );
}

class _VisibleShippedResultSurface {
  const _VisibleShippedResultSurface({
    required this.displayContext,
    required this.viewportTexts,
  });

  final String displayContext;
  final List<String> viewportTexts;
}

List<_VisibleShippedResultSurface> _visibleShippedResultSurfaces(
  WidgetTester tester,
  _ShippedWorkflowSelector selector,
) {
  final surfaces = <_VisibleShippedResultSurface>[];
  for (final card in _shippedResultCardFinder(selector).evaluate()) {
    final cardWidget = card.widget as EngineNativeArchetypeCard;
    final cardFinder = _shippedResultCardElementFinder(card, cardWidget);
    final viewportTexts = _visibleTextValuesWithin(cardFinder);
    if (viewportTexts.isEmpty) continue;
    surfaces.add(
      _VisibleShippedResultSurface(
        displayContext: cardWidget.displayContext,
        viewportTexts: viewportTexts,
      ),
    );
  }
  return surfaces;
}

Finder _shippedResultCardFinder(_ShippedWorkflowSelector selector) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is EngineNativeArchetypeCard &&
        widget.resolved.instance.instanceId == selector.instance.instanceId,
    description: 'rendered result surface for ${selector.instance.instanceId}',
  );
}

Finder _shippedResultCardElementFinder(
  Element card,
  EngineNativeArchetypeCard cardWidget,
) {
  return find.byElementPredicate(
    (candidate) => identical(candidate, card),
    description:
        'rendered ${cardWidget.displayContext} surface for '
        '${cardWidget.resolved.instance.instanceId}',
  );
}

List<String> _visibleTextValuesWithin(Finder scope) {
  return find
      .descendant(of: scope, matching: find.byType(Text))
      .hitTestable()
      .evaluate()
      .map((element) {
        final text = element.widget as Text;
        return text.data ?? text.textSpan?.toPlainText() ?? '';
      })
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
}

bool _hasVisibleShippedSuccessAcknowledgement({
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
}) {
  // This is intentionally a semantic result key, not the action key: a
  // still-visible action must never be mistaken for proof that it succeeded.
  final acknowledgement = _shippedSuccessAcknowledgementFinder(
    selector: selector,
    transition: transition,
  );
  return acknowledgement.hitTestable().evaluate().isNotEmpty;
}

Finder _shippedSuccessAcknowledgementFinder({
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition transition,
}) {
  return find.byKey(
    ValueKey('b25-success-${selector.instance.instanceId}-${transition.id}'),
  );
}

Future<_B25WalkthroughResult> _finishB25WalkthroughAfterPrimary({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required B25ProductDocInteractionModel model,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition executedPrimary,
  required List<String> screenshotNames,
  required List<String> primaryActionProofPair,
  required Future<void> Function(String name) capture,
  required Finder actionSurface,
  required bool useMarketplaceDetailActionFinder,
  required List<B25ActionExecutionEvidence> actionExecutionEvidence,
}) async {
  final alternate = await _waitForB25AlternateAction(
    tester: tester,
    selector: selector,
    surface: actionSurface,
    useMarketplaceDetailActionFinder: useMarketplaceDetailActionFinder,
    primaryTerms: model.requiredPrimaryActions,
    alternateTerms: model.requiredAlternateActions,
    excludedTransitionId: executedPrimary.id,
  );
  if (alternate == null) {
    // The `start`/`action`/`primaryResult` proof is already complete: the
    // primary transition fired and its target state was verified. No
    // alternate was found ready within the wait budget, so there is no
    // result to receive -- capturing `alternate_action_unavailable` and
    // `result_receiver` here would only reproduce `primaryResult`
    // byte-for-byte, since nothing acts on the screen between them.
    return _b25WalkthroughResult(
      model: model,
      selector: selector,
      executedPrimary: executedPrimary,
      screenshotNames: screenshotNames,
      actionExecutionEvidence: actionExecutionEvidence,
      actionProofFramePairs: [primaryActionProofPair],
    );
  }

  final alternateAction = _b25ScreenshotName(target, model, 'alternate_action');
  await tester.ensureVisible(alternate.finder.first);
  await _pumpB25Frames(tester);
  await capture(alternateAction);
  final sourceInstance = identical(selector.actionMachine, selector.machine)
      ? await _readShippedInstance(
          tester: tester,
          target: target,
          package: package,
          selector: selector,
        )
      : null;
  await tester.tap(alternate.finder.first, warnIfMissed: false);
  await tester.pump();
  await _completeShippedTransitionInputs(
    tester: tester,
    transition: alternate.transition,
    roleId: selector.roleId,
  );
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }
  var observedAlternateAction = _observeB25ActionExecutionAfterTap(
    action: alternate.finder,
    transitionId: alternate.transition.id,
  );

  var resultPositioned = false;
  if (identical(selector.actionMachine, selector.machine) &&
      sourceInstance != null) {
    final category = _classifyShippedTransition(
      transition: alternate.transition,
      sourceState: sourceInstance.currentState,
      archetypeFamily: selector.actionArchetypeFamily,
      instanceData: sourceInstance.instanceData,
      actorId: selector.accountId ?? selector.roleId,
      roleId: selector.roleId,
    );
    final targetState = alternate.transition.to;
    if (category == _ShippedTransitionCategory.stateChanging &&
        targetState != null) {
      observedAlternateAction = await _expectShippedInstanceState(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        targetState: targetState,
        transitionId: alternate.transition.id,
        actionExecutionEvidence: [
          ...actionExecutionEvidence,
          observedAlternateAction,
        ],
      );
      await _positionConfirmedShippedResultForCapture(
        tester: tester,
        selector: selector,
        transition: alternate.transition,
        targetState: targetState,
      );
      await _expectVisibleShippedAlternateStatePostcondition(
        tester: tester,
        selector: selector,
        transition: alternate.transition,
        targetState: targetState,
      );
      resultPositioned = true;
    } else if (category.requiresSourceInstanceDataChange) {
      final persisted = await _expectShippedInstanceDataChanged(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        sourceInstance: sourceInstance,
      );
      observedAlternateAction = observedAlternateAction.withPostcondition(
        'instance_data_changed',
      );
      await _positionConfirmedShippedResultForCapture(
        tester: tester,
        selector: selector,
        transition: alternate.transition,
        sourceInstance: sourceInstance,
        persistedInstance: persisted,
      );
      await _expectVisibleShippedAlternateDataPostcondition(
        tester: tester,
        selector: selector,
        transition: alternate.transition,
        sourceInstance: sourceInstance,
        persistedInstance: persisted,
      );
      resultPositioned = true;
    }
  }

  if (!resultPositioned) {
    await _positionShippedFallbackResultForCapture(
      tester: tester,
      selector: selector,
      transition: alternate.transition,
      targetStateLabel:
          selector.actionMachine.states[alternate.transition.to]?.label,
    );
  }
  final result = _b25ScreenshotName(target, model, 'result_receiver');
  await capture(result);
  return _b25WalkthroughResult(
    model: model,
    selector: selector,
    executedPrimary: executedPrimary,
    executedAlternate: alternate.transition,
    screenshotNames: [...screenshotNames, alternateAction, result],
    actionExecutionEvidence: [
      ...actionExecutionEvidence,
      observedAlternateAction,
    ],
    actionProofFramePairs: [
      primaryActionProofPair,
      [alternateAction, result],
    ],
  );
}

Future<({LoomWorkflowTransition transition, Finder finder})?>
_waitForB25AlternateAction({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required Finder surface,
  required bool useMarketplaceDetailActionFinder,
  required List<String> primaryTerms,
  required List<String> alternateTerms,
  required String excludedTransitionId,
}) async {
  if (alternateTerms.isEmpty) return null;
  final candidates = selector.actionMachine.transitions
      .where(
        (transition) =>
            transition.id != excludedTransitionId &&
            matchB25TransitionAgainstTerms(
              transition,
              primaryTerms: primaryTerms,
              alternateTerms: alternateTerms,
            ).alternate,
      )
      .toList(growable: false);
  for (var attempt = 0; attempt < 80; attempt += 1) {
    for (final transition in candidates) {
      final finder = _shippedWorkflowActionFinder(
        selector: selector,
        transitionId: transition.id,
        useMarketplaceDetailActionFinder: useMarketplaceDetailActionFinder,
      );
      final readyFinder = await firstReadyActionOnSurface(
        tester: tester,
        surface: surface,
        candidates: [finder],
      );
      if (readyFinder != null) {
        return (transition: transition, finder: readyFinder);
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  return null;
}

class _B25WalkthroughResult {
  const _B25WalkthroughResult({
    required this.screenshotNames,
    required this.actionProofStatus,
    required this.visiblePrimaryActions,
    required this.visibleAlternateActions,
    required this.availableSupplementaryActions,
    required this.productFindings,
    this.rowOutcome = 'attempted',
    this.blockedByAudienceReason,
    this.blockedByAudienceCause,
    this.blockedBySelectorSetupReason,
    this.blockedBySelectorSetupCause,
    this.blockedByPrerequisiteReason,
    this.actionSucceededResultUnverifiedReason,
    this.rowExecutionFailureReason,
    this.actionExecutionEvidence = const <B25ActionExecutionEvidence>[],
    this.actionProofFramePairs = const <List<String>>[],
    this.actionProofFramePairsRequired = false,
    this.alternateUnavailableReason,
    this.extraFields = const <String, Object?>{},
    this.diagnosticScreenshotNames = const <String>[],
  });

  final List<String> screenshotNames;

  /// Frames captured before this row failed, carrying no action-proof
  /// weight -- audit-only. Never summed into `screenshotNames` or anything
  /// downstream that counts proof-bearing evidence. See CLAUDE.md "B25: a
  /// row that captures frames and then fails must not discard them".
  final List<String> diagnosticScreenshotNames;
  final String actionProofStatus;
  final List<String> visiblePrimaryActions;
  final List<String> visibleAlternateActions;
  final List<String> availableSupplementaryActions;
  final List<String> productFindings;
  final String rowOutcome;
  final String? blockedByAudienceReason;
  final String? blockedByAudienceCause;
  final String? blockedBySelectorSetupReason;
  final String? blockedBySelectorSetupCause;
  final String? blockedByPrerequisiteReason;
  final String? actionSucceededResultUnverifiedReason;
  final String? rowExecutionFailureReason;
  final List<B25ActionExecutionEvidence> actionExecutionEvidence;

  /// Pairs of screenshot NAMES (not paths) that have a declared tap between
  /// them. `b25_capture_integrity.dart` fails the row only when one of
  /// THESE pairs is byte-identical -- a duplicate anywhere else in
  /// `screenshotNames` carries no proof weight and is recorded for audit
  /// only. See CLAUDE.md "B25 capture: byte-distinctness must prove an
  /// action, not merely differ".
  final List<List<String>> actionProofFramePairs;

  /// True only for rows produced by [_b25WalkthroughResult] when a primary
  /// transition actually fired (`rowOutcome == 'attempted'`). This is the
  /// closure rule: a row in that population cannot dodge enforcement by
  /// declaring no pairs -- the integrity check fails it instead of silently
  /// passing. Dedicated/capability rows (`dedicatedPass`) never set this;
  /// they were not built around a primary/alternate action-proof pair and
  /// are out of scope for this rule.
  final bool actionProofFramePairsRequired;
  final String? alternateUnavailableReason;

  /// Extra keys merged verbatim into the recorded manifest entry, for
  /// fields that don't fit the named properties above (e.g.
  /// `resultUnchangedVerified`).
  final Map<String, Object?> extraFields;

  bool get isBlockedByAudience => rowOutcome == 'blocked_by_audience';
  bool get isBlockedBySelectorSetup =>
      rowOutcome == 'blocked_by_selector_setup';
  bool get isBlockedByPrerequisite => rowOutcome == 'blocked_by_prerequisite';
  bool get isBlocked =>
      isBlockedByAudience ||
      isBlockedBySelectorSetup ||
      isBlockedByPrerequisite;
  bool get isRecordedFailure =>
      isBlocked ||
      rowOutcome == 'action_succeeded_result_unverified' ||
      rowOutcome == 'product_finding' ||
      rowOutcome == 'row_execution_failed';
}

_B25WalkthroughResult _recordB25RowScopedFailure(B25RowScopedFailure failure) {
  return _B25WalkthroughResult(
    screenshotNames: const <String>[],
    diagnosticScreenshotNames: failure.screenshotNames,
    actionProofStatus: failure.actionProofStatus,
    visiblePrimaryActions: const <String>[],
    visibleAlternateActions: const <String>[],
    availableSupplementaryActions: const <String>[],
    productFindings: <String>[failure.reason],
    rowOutcome: failure.rowOutcome,
    blockedByAudienceReason: failure.rowOutcome == 'blocked_by_audience'
        ? failure.reason
        : null,
    blockedByAudienceCause: failure.rowOutcome == 'blocked_by_audience'
        ? B25ActorAudienceResolutionFailure.absentActorEqualsFieldCause
        : null,
    blockedBySelectorSetupReason:
        failure.rowOutcome == 'blocked_by_selector_setup'
        ? failure.reason
        : null,
    blockedBySelectorSetupCause:
        failure.rowOutcome == 'blocked_by_selector_setup'
        ? failure.selectorSetupCause ?? B25SelectorSetupFailure.defaultCause
        : null,
    blockedByPrerequisiteReason: failure.rowOutcome == 'blocked_by_prerequisite'
        ? failure.reason
        : null,
    actionSucceededResultUnverifiedReason:
        failure.actionSucceededButResultUnverified ? failure.reason : null,
    rowExecutionFailureReason: failure.rowOutcome == 'row_execution_failed'
        ? failure.reason
        : null,
    actionExecutionEvidence: failure.actionExecutionEvidence,
  );
}

_B25WalkthroughResult _b25WalkthroughResult({
  required B25ProductDocInteractionModel model,
  required _ShippedWorkflowSelector selector,
  LoomWorkflowTransition? executedPrimary,
  LoomWorkflowTransition? executedAlternate,
  Iterable<LoomWorkflowTransition> availableSupplementaryActions =
      const <LoomWorkflowTransition>[],
  required List<String> screenshotNames,
  String? primaryUnavailableReason,
  List<B25ActionExecutionEvidence> actionExecutionEvidence =
      const <B25ActionExecutionEvidence>[],
  List<List<String>> actionProofFramePairs = const <List<String>>[],
}) {
  final primaryTermMatch = executedPrimary == null
      ? const (primary: <String>[], alternate: <String>[])
      : b25MatchedTermNames(
          executedPrimary,
          primaryTerms: model.requiredPrimaryActions,
          alternateTerms: model.requiredAlternateActions,
        );
  final alternateTermMatch = executedAlternate == null
      ? const (primary: <String>[], alternate: <String>[])
      : b25MatchedTermNames(
          executedAlternate,
          primaryTerms: model.requiredPrimaryActions,
          alternateTerms: model.requiredAlternateActions,
        );
  final visiblePrimary = primaryTermMatch.primary;
  final visibleAlternate = alternateTermMatch.alternate;
  final supplementaryActions = availableSupplementaryActions
      .map((transition) => transition.label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList(growable: false);
  final offeredActions =
      selector.transitions
          .map((candidate) => candidate.transition.id)
          .toSet()
          .toList()
        ..sort();
  final rowOutcome = primaryUnavailableReason == null
      ? 'attempted'
      : 'primary_action_unavailable';
  // Computed once and reused below as `alternateUnavailableReason`, so a
  // reader does not have to pick it out of the combined findings list.
  final noAlternateExercisedFinding =
      '${model.communityName} / ${model.workflowId} / ${model.role}: '
      'the walkthrough exercised no documented '
      'alternate/change/reject action ${model.requiredAlternateActions.isEmpty ? 'because the product doc declares `${model.alternateRequirementNote}`' : model.requiredAlternateActions}.';
  final findings = <String>[
    if (primaryUnavailableReason != null) primaryUnavailableReason,
    if (supplementaryActions.isNotEmpty)
      '${model.communityName} / ${model.workflowId} / ${model.role}: '
          'prepared but unexercised supplementary actions '
          '[${supplementaryActions.join(', ')}] are recorded separately from '
          'documented primary and alternate action proof.',
    if (visiblePrimary.isEmpty)
      '${model.communityName} / ${model.workflowId} / ${model.role}: '
          '${executedPrimary == null ? 'no documented primary package action was exercised' : 'the exercised package action `${executedPrimary.label}` does not match any documented primary action'} '
          '${model.requiredPrimaryActions}; the package offers '
          '[${offeredActions.join(', ')}] to this role.',
    if (visibleAlternate.isEmpty) noAlternateExercisedFinding,
  ];
  final alternateUnavailableReason = visibleAlternate.isEmpty
      ? noAlternateExercisedFinding
      : null;
  if (rowOutcome == 'attempted' && actionProofFramePairs.isEmpty) {
    throw StateError(
      'A row with rowOutcome "attempted" must declare its primary '
      'action-proof frame pair (the [action, result] screenshot names a '
      'tap sits between). ${model.communityName} / ${model.workflowId} / '
      '${model.role} declared none -- this is exactly the closure rule '
      'CLAUDE.md "B25 capture: byte-distinctness must prove an action, not '
      'merely differ" exists to catch, caught here at capture time instead '
      'of at combine time.',
    );
  }
  return _B25WalkthroughResult(
    screenshotNames: screenshotNames,
    actionProofStatus: findings.isEmpty ? 'pass' : 'fail',
    visiblePrimaryActions: visiblePrimary,
    visibleAlternateActions: visibleAlternate,
    availableSupplementaryActions: supplementaryActions,
    productFindings: findings,
    rowOutcome: rowOutcome,
    actionExecutionEvidence: actionExecutionEvidence,
    actionProofFramePairs: actionProofFramePairs,
    actionProofFramePairsRequired: rowOutcome == 'attempted',
    alternateUnavailableReason: alternateUnavailableReason,
  );
}

Future<_B25WalkthroughResult> _captureMissingB25PackageWorkflow({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required WalkthroughBodyWatch bodyWatch,
  required B25ProductDocInteractionModel b25Model,
  required Future<void> Function(String name) capture,
}) async {
  await assertB25CommunityRowSurface(
    tester: tester,
    target: target,
    workflowId: b25Model.workflowId,
    role: b25Model.role,
    boundary: 'before',
    captureDiagnostic: capture,
  );
  void beatSubstep(WalkthroughSubstep substep, {String? role, String? tabId}) {
    final progress = buildWalkthroughSubstepProgress(
      substep,
      role: role,
      tabId: tabId,
      workflow: b25Model.workflowId,
      phase: target.phase,
      community: target.communityName,
    );
    bodyWatch.beat(
      attemptedStep: progress.attemptedStep,
      waitingFor: progress.waitingFor,
    );
  }

  final roleId = requireSingleActorIdentityB25Walkthrough(
    extensionId: package.experience.extensionId,
    resolution: resolveB25ProductDocRole(
      extensionId: package.experience.extensionId,
      role: b25Model.role,
      actorIdentities: package.experience.actorIdentities!,
    ),
  );
  beatSubstep(WalkthroughSubstep.selectingActorIdentity, role: roleId);
  await selectActorIdentity(tester, roleId);
  final preferredTab = _tabForMissingB25Workflow(b25Model.workflowId);
  final tabs = appShellTabsFor(
    experience: package.experience,
    roleId: roleId,
    appShellConfiguration: package.appShellConfiguration,
  );
  if (tabs.any((tab) => tab.tabId == preferredTab)) {
    beatSubstep(WalkthroughSubstep.selectingCommunityTab, tabId: preferredTab);
    await _selectCommunityTab(tester, preferredTab);
  }

  // The package has no definition for this workflow at all, so nothing on
  // screen can change between successive captures: three more frames here
  // would only reproduce `start` byte-for-byte. One frame is the complete
  // evidence for "the row could not be attempted".
  final screenshotNames = <String>[_b25ScreenshotName(target, b25Model, 'start')];
  for (final screenshotName in screenshotNames) {
    await capture(screenshotName);
  }
  final offered = package.experience.workflowDefinitions!.keys.toList()..sort();
  return _B25WalkthroughResult(
    screenshotNames: screenshotNames,
    actionProofStatus: 'fail',
    visiblePrimaryActions: const <String>[],
    visibleAlternateActions: const <String>[],
    availableSupplementaryActions: const <String>[],
    productFindings: <String>[
      '${target.communityName} / ${b25Model.workflowId} / '
          '${b25Model.role}: the shipped package has no workflow '
          'definition for this B25 row. It offers these workflow definitions '
          'instead: ${offered.join(', ')}.',
    ],
  );
}

String _tabForMissingB25Workflow(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.contains('message')) return 'messages';
  if (id.contains('connection') || id.contains('invite')) {
    return 'connections';
  }
  return 'home';
}

Future<WorkflowInstance?> _readShippedInstance({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  String? instanceId,
}) async {
  final screen = tester.widget<LocalExtensionScreen>(
    find.byType(LocalExtensionScreen),
  );
  final fanId = screen.authApi?.currentSession?.account.accountId;
  if (fanId == null) return null;
  final engine = (await tester.runAsync(
    () => workflowEngineForExtensionId(target.extensionId),
  ))!;
  final tabs = <String>{
    for (final binding in selector.machine.renderBindings) binding.tabId,
    ...appShellTabsFor(
      experience: package.experience,
      roleId: selector.roleId,
      appShellConfiguration: package.appShellConfiguration,
    ).map((tab) => tab.tabId),
  };
  for (final tabId in tabs) {
    final page = (await tester.runAsync(
      () => engine.queryInstances(tabId: tabId, fanId: fanId, limit: 100),
    ))!;
    for (final instance in page.items) {
      if (instance.instanceId == (instanceId ?? selector.instance.instanceId)) {
        return instance;
      }
    }
  }
  return null;
}

/// Captures only action-stage signals the rendered surface already exposes.
///
/// A disabled action control reflects the mutation-in-flight state used by
/// engine-native cards. The harness has no completion trace from the engine,
/// so it records that gap explicitly instead of treating a returned tap as a
/// successful dispatch or call.
B25ActionExecutionEvidence _observeB25ActionExecutionAfterTap({
  required Finder action,
  required String transitionId,
}) {
  final actionControls = action
      .evaluate()
      .map((element) => element.widget)
      .whereType<ButtonStyleButton>();
  final handlerEntry =
      actionControls.any((control) => control.onPressed == null)
      ? 'action_control_disabled_after_tap'
      : 'not_observable';
  final errorSurface =
      find
          .text('Could not save this change. Please try again.')
          .evaluate()
          .isNotEmpty
      ? 'generic_save_error_visible'
      : 'not_observed';
  return B25ActionExecutionEvidence(
    transitionId: transitionId,
    tapReturned: 'returned',
    handlerEntry: handlerEntry,
    engineCallCompletion: 'not_observable',
    errorSurface: errorSurface,
    postcondition: 'not_checked',
  );
}

/// Confirms the engine-native postcondition before classifying a surface that
/// still shows a completed action. This keeps a failed transition distinct
/// from a shipped UI that failed to retire an action after the transition.
Future<B25ActionExecutionEvidence> _expectShippedInstanceIdState({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required String instanceId,
  required String targetState,
  required String transitionId,
  required B25ActionExecutionEvidence actionExecutionEvidence,
}) async {
  final stopwatch = Stopwatch()..start();
  final postcondition = await waitForB25ShippedTargetState(
    targetState: targetState,
    readCurrentState: () async => (await _readShippedInstance(
      tester: tester,
      target: target,
      package: package,
      selector: selector,
      instanceId: instanceId,
    ))?.currentState,
    waitForRetry: () async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    },
    elapsed: () => stopwatch.elapsed,
    maximumAttempts: 80,
  );
  stopwatch.stop();
  final settledAction = actionExecutionEvidence.withPostcondition(
    postcondition.targetStateObserved
        ? 'target_state_observed'
        : 'target_state_not_observed',
  );
  if (postcondition.targetStateObserved) return settledAction;
  throw B25PostconditionNotObservedFailure(
    postcondition.failureReason(
      workflowType: selector.machine.workflowType,
      transitionId: transitionId,
      instanceId: instanceId,
    ),
    actionExecutionEvidence: [settledAction],
  );
}

Future<WorkflowInstance> _expectShippedInstanceDataChanged({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required WorkflowInstance sourceInstance,
}) async {
  WorkflowInstance? persisted;
  for (var attempt = 0; attempt < 80; attempt += 1) {
    persisted = await _readShippedInstance(
      tester: tester,
      target: target,
      package: package,
      selector: selector,
    );
    if (persisted != null &&
        jsonEncode(persisted.instanceData) !=
            jsonEncode(sourceInstance.instanceData)) {
      return persisted;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail(
    'Shipped workflow ${selector.machine.workflowType} ran a visible '
    'orthogonal package action for ${selector.instance.instanceId}, but the '
    'shared engine instance data did not change.',
  );
}

Future<B25ActionExecutionEvidence> _expectShippedInstanceState({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required String targetState,
  required String transitionId,
  required List<B25ActionExecutionEvidence> actionExecutionEvidence,
}) async {
  final screen = tester.widget<LocalExtensionScreen>(
    find.byType(LocalExtensionScreen),
  );
  final fanId = screen.authApi?.currentSession?.account.accountId;
  if (fanId == null) {
    fail(
      'Could not resolve the signed-in shipped-package account while '
      'verifying ${selector.instance.instanceId}.',
    );
  }
  final engine = (await tester.runAsync(
    () => workflowEngineForExtensionId(target.extensionId),
  ))!;
  final tabs = selector.machine.renderBindings
      .where((binding) => binding.states.contains(targetState))
      .map((binding) => binding.tabId)
      .toSet();
  if (tabs.isEmpty) {
    tabs.addAll(
      appShellTabsFor(
        experience: package.experience,
        roleId: selector.roleId,
        appShellConfiguration: package.appShellConfiguration,
      ).map((tab) => tab.tabId),
    );
  }

  final stopwatch = Stopwatch()..start();
  final postcondition = await waitForB25ShippedTargetState(
    targetState: targetState,
    readCurrentState: () async {
      for (final tabId in tabs) {
        final page = (await tester.runAsync(
          () => engine.queryInstances(tabId: tabId, fanId: fanId, limit: 100),
        ))!;
        for (final instance in page.items) {
          if (instance.instanceId == selector.instance.instanceId) {
            return instance.currentState;
          }
        }
      }
      return null;
    },
    waitForRetry: () async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    },
    elapsed: () => stopwatch.elapsed,
    maximumAttempts: 80,
  );
  stopwatch.stop();
  final settledAction = actionExecutionEvidence.last.withPostcondition(
    postcondition.targetStateObserved
        ? 'target_state_observed'
        : 'target_state_not_observed',
  );
  if (postcondition.targetStateObserved) return settledAction;
  throw B25PostconditionNotObservedFailure(
    postcondition.failureReason(
      workflowType: selector.machine.workflowType,
      transitionId: transitionId,
      instanceId: selector.instance.instanceId,
    ),
    actionExecutionEvidence: [
      ...actionExecutionEvidence.take(actionExecutionEvidence.length - 1),
      settledAction,
    ],
  );
}

_ShippedWorkflowSelector _shippedWorkflowSelector({
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required String workflowType,
  B25ProductDocInteractionModel? b25Model,
}) {
  _ShippedWorkflowSelector? b25FallbackSelector;
  final machine = package.experience.workflowDefinitions?[workflowType];
  if (machine == null) {
    throw B25SelectorSetupFailure(
      'Walkthrough workflow $workflowType is absent from the shipped '
      '${target.extensionId} experience.workflowDefinitions.',
      cause: B25SelectorSetupFailure.missingWorkflowDefinitionCause,
    );
  }
  final instances = package.experience.workflowInstances!
      .where((instance) => instance.workflowType == workflowType)
      .toList(growable: false);
  if (instances.isEmpty) {
    throw B25SelectorSetupFailure(
      'Walkthrough workflow $workflowType has no selector source in the '
      'shipped ${target.extensionId} experience.workflowInstances.',
      cause: B25SelectorSetupFailure.noSelectorSourceCause,
    );
  }
  final packageRoleIds = {
    for (final actorIdentity in package.experience.actorIdentities!)
      actorIdentity.roleId,
  };
  final b25RoleResolution = b25Model == null
      ? null
      : resolveB25ProductDocRole(
          extensionId: package.experience.extensionId,
          role: b25Model.role,
          actorIdentities: package.experience.actorIdentities!,
        );
  final preferredRoleIds = b25RoleResolution == null
      ? packageRoleIds
      : <String>{
          requireSingleActorIdentityB25Walkthrough(
            extensionId: package.experience.extensionId,
            resolution: b25RoleResolution,
          ),
        };
  final rawExperience = package.source['experience'] as Map<String, dynamic>;
  final rawWorkflowDefinitions = Map<String, Object?>.from(
    rawExperience['workflowDefinitions'] as Map,
  );
  final resolvedArchetypes = const ArchetypeResolver().resolveAll(
    rawWorkflowDefinitions,
  );

  for (final instance in instances) {
    final bindings =
        machine.renderBindings
            .where((binding) => binding.states.contains(instance.currentState))
            .toList(growable: false)
          ..sort((left, right) {
            int score(RenderBinding binding) =>
                (binding.responseTable == null ? 4 : 0) +
                (binding.actions.isEmpty ? 1 : 0) +
                (binding.bindingKind == 'primary' ? 0 : 2) +
                (binding.role == 'any' ? 0 : 1);
            return score(left).compareTo(score(right));
          });
    for (final binding in bindings) {
      final responseWorkflowType = binding.responseTable?.workflowType;
      final actionMachine = responseWorkflowType == null
          ? machine
          : package.experience.workflowDefinitions?[responseWorkflowType];
      if (actionMachine == null) {
        throw B25SelectorSetupFailure(
          'Shipped workflow $workflowType binding on ${binding.tabId} names '
          'missing response workflow $responseWorkflowType.',
          cause: B25SelectorSetupFailure.missingResponseWorkflowCause,
        );
      }
      final actionSourceState = responseWorkflowType == null
          ? instance.currentState
          : actionMachine.initialState;
      final actionArchetypeFamily =
          resolvedArchetypes[actionMachine.workflowType]?.family;
      final transitions = actionMachine.transitionsFrom(actionSourceState);
      final roleIds = <String>{
        for (final transition in transitions)
          ...?transition.guard.allowedRoleIds,
        ...?machine.visibility.readGuard?.allowedRoleIds,
        for (final action in binding.actions) ...?action.byRoleIds,
        ...packageRoleIds,
      };
      for (final roleId in roleIds.where(preferredRoleIds.contains)) {
        final bindingAccountId = binding.role == 'actor'
            ? requireB25ActorBindingAudience(
                workflowId: machine.workflowType,
                instance: WorkflowInstance(
                  instanceId: instance.instanceId,
                  workflowType: instance.workflowType,
                  currentState: instance.currentState,
                  instanceData: instance.instanceData,
                  createdByFanId: instance.createdByFanId ?? '',
                ),
                roleId: roleId,
                candidates: package.experience.actorIdentities!
                    .where((identity) => identity.roleId == roleId)
                    .map(
                      (identity) => B25ActorAudienceCandidate(
                        fanId: identity.fanId,
                        roleId: identity.roleId,
                      ),
                    ),
                machine: machine,
              )
            : null;
        final tabs = appShellTabsFor(
          experience: package.experience,
          roleId: roleId,
          appShellConfiguration: package.appShellConfiguration,
        );
        if (!tabs.any((tab) => tab.tabId == binding.tabId)) {
          continue;
        }
        final actionableTransitions =
            transitions
                .where(
                  (transition) => _transitionCanBeSelectedForRole(
                    transition: transition,
                    instance: instance,
                    roleId: roleId,
                    allowViewerResponse: responseWorkflowType != null,
                  ),
                )
                .map(
                  (transition) => _ShippedTransitionCandidate(
                    transition: transition,
                    category: _classifyShippedTransition(
                      transition: transition,
                      sourceState: actionSourceState,
                      archetypeFamily: actionArchetypeFamily,
                      instanceData: instance.instanceData,
                      actorId:
                          _transitionAccountId(
                            transition: transition,
                            instance: instance,
                            roleId: roleId,
                            allowViewerResponse: responseWorkflowType != null,
                          ) ??
                          roleId,
                      roleId: roleId,
                    ),
                  ),
                )
                .toList(growable: false)
              ..sort((left, right) {
                if (b25Model != null) {
                  final semantic = _compareB25TransitionCandidates(
                    left,
                    right,
                    b25Model,
                  );
                  if (semantic != 0) return semantic;
                }
                return _compareShippedTransitionCandidates(left, right);
              });
        if (actionableTransitions.isEmpty) {
          continue;
        }
        final accountId =
            bindingAccountId ??
            _transitionAccountId(
              transition: actionableTransitions.first.transition,
              instance: instance,
              roleId: roleId,
              allowViewerResponse: responseWorkflowType != null,
            );
        final accountTransitions = actionableTransitions
            .where((candidate) {
              final transitionAccountId = _transitionAccountId(
                transition: candidate.transition,
                instance: instance,
                roleId: roleId,
                allowViewerResponse: responseWorkflowType != null,
              );
              return transitionAccountId == null ||
                  transitionAccountId == accountId;
            })
            .toList(growable: false);
        final selector = _ShippedWorkflowSelector(
          machine: machine,
          actionMachine: actionMachine,
          actionSourceState: actionSourceState,
          actionArchetypeFamily: actionArchetypeFamily,
          instance: instance,
          binding: binding,
          roleId: roleId,
          accountId: accountId,
          transitions: accountTransitions,
        );
        if (b25Model != null &&
            !b25PrimaryMatchIsReachable(
              candidates: accountTransitions.map(
                (candidate) => candidate.transition,
              ),
              matchesPrimaryTerm: (candidateTransition) =>
                  matchB25TransitionAgainstTerms(
                    candidateTransition,
                    primaryTerms: b25Model.requiredPrimaryActions,
                    alternateTerms: b25Model.requiredAlternateActions,
                  ).primary,
              // A candidate's formula guard is evaluated in isolation, never
              // through the shared engine guard evaluator -- see
              // b25_formula_guard_reachability.dart for why.
              formulaVerdict: (candidateTransition) =>
                  formulaGuardVerdictForTransition(
                    transition: candidateTransition,
                    instanceData: instance.instanceData,
                    actorId:
                        _transitionAccountId(
                          transition: candidateTransition,
                          instance: instance,
                          roleId: roleId,
                          allowViewerResponse: responseWorkflowType != null,
                        ) ??
                        roleId,
                    allowViewerResponse: responseWorkflowType != null,
                  ),
            )) {
          b25FallbackSelector ??= selector;
          continue;
        }
        return selector;
      }
    }
  }
  if (b25FallbackSelector != null) return b25FallbackSelector;
  throw B25SelectorSetupFailure(
    'Walkthrough workflow $workflowType could not derive an actionable '
    'instance, actorIdentity, and tab from the shipped ${target.extensionId} '
    'experience and appShell${b25Model == null ? '.' : ' for B25 product-doc role `${b25Model.role}` from `${b25Model.productDocPath}`.'}',
    cause: B25SelectorSetupFailure.defaultCause,
  );
}

int _compareB25TransitionCandidates(
  _ShippedTransitionCandidate left,
  _ShippedTransitionCandidate right,
  B25ProductDocInteractionModel model,
) {
  int semanticPriority(LoomWorkflowTransition transition) {
    final match = matchB25TransitionAgainstTerms(
      transition,
      primaryTerms: model.requiredPrimaryActions,
      alternateTerms: model.requiredAlternateActions,
    );
    if (match.primary) {
      return 0;
    }
    if (match.alternate) {
      return 1;
    }
    return 2;
  }

  return semanticPriority(
    left.transition,
  ).compareTo(semanticPriority(right.transition));
}

enum _ShippedTransitionCategory {
  stateChanging,
  sourceInstanceEffect,
  eligibleArchetypeBookkeeping,
  relatedOrNewInstanceOnly,
  noOp,
}

extension on _ShippedTransitionCategory {
  bool get requiresSourceInstanceDataChange =>
      this == _ShippedTransitionCategory.sourceInstanceEffect ||
      this == _ShippedTransitionCategory.eligibleArchetypeBookkeeping;

  int get selectionPriority => switch (this) {
    _ShippedTransitionCategory.sourceInstanceEffect => 0,
    _ShippedTransitionCategory.eligibleArchetypeBookkeeping => 1,
    _ShippedTransitionCategory.stateChanging => 2,
    _ShippedTransitionCategory.relatedOrNewInstanceOnly => 3,
    _ShippedTransitionCategory.noOp => 4,
  };
}

class _ShippedTransitionCandidate {
  const _ShippedTransitionCandidate({
    required this.transition,
    required this.category,
  });

  final LoomWorkflowTransition transition;
  final _ShippedTransitionCategory category;
}

int _compareShippedTransitionCandidates(
  _ShippedTransitionCandidate left,
  _ShippedTransitionCandidate right,
) {
  final category = left.category.selectionPriority.compareTo(
    right.category.selectionPriority,
  );
  if (category != 0) return category;

  int inputScore(LoomWorkflowTransition transition) =>
      transition.inputs == null || transition.inputs!.isEmpty ? 0 : 1;
  final inputs = inputScore(
    left.transition,
  ).compareTo(inputScore(right.transition));
  if (inputs != 0) return inputs;

  int destructiveScore(LoomWorkflowTransition transition) =>
      transition.tone == 'destructive' ? 1 : 0;
  return destructiveScore(
    left.transition,
  ).compareTo(destructiveScore(right.transition));
}

const Map<String, Map<String, (String, bool)>>
_shippedArchetypeBookkeepingByAction = {
  'documentLibrary': {
    'open': ('openedFanIds', true),
    'acknowledge': ('acknowledgedFanIds', true),
    'save': ('savedFanIds', true),
    'unsave': ('savedFanIds', false),
    'download': ('downloadedFanIds', true),
    'request_access': ('accessRequestedFanIds', true),
    'withdraw_access_request': ('accessRequestedFanIds', false),
  },
  'equipment-loan': {
    'join_queue': ('queuedFanIds', true),
    'leave_queue': ('queuedFanIds', false),
  },
  'event-rsvp': {'set_reminder': ('reminderFanIds', true)},
};

_ShippedTransitionCategory _classifyShippedTransition({
  required LoomWorkflowTransition transition,
  required String sourceState,
  required String? archetypeFamily,
  required Map<String, dynamic> instanceData,
  required String actorId,
  required String roleId,
}) {
  if (transition.to != null && transition.to != sourceState) {
    return _ShippedTransitionCategory.stateChanging;
  }

  final sourceOutcomes = _shippedSourceEffectOutcomes(
    transition: transition,
    instanceData: instanceData,
    actorId: actorId,
    roleId: roleId,
  );
  final finalOutcomes = <Map<String, dynamic>>[];
  var bookkeepingAlwaysChanges = sourceOutcomes.isNotEmpty;
  for (final outcome in sourceOutcomes) {
    final bookkept = _applyShippedArchetypeBookkeeping(
      transition: transition,
      archetypeFamily: archetypeFamily,
      instanceData: outcome,
      actorId: actorId,
    );
    finalOutcomes.add(bookkept);
    bookkeepingAlwaysChanges =
        bookkeepingAlwaysChanges && !_sameInstanceData(outcome, bookkept);
  }

  final sourceEffectsAlwaysChange =
      sourceOutcomes.isNotEmpty &&
      sourceOutcomes.every(
        (outcome) => !_sameInstanceData(instanceData, outcome),
      );
  final finalDataAlwaysChanges =
      finalOutcomes.isNotEmpty &&
      finalOutcomes.every(
        (outcome) => !_sameInstanceData(instanceData, outcome),
      );
  if (sourceEffectsAlwaysChange && finalDataAlwaysChanges) {
    return _ShippedTransitionCategory.sourceInstanceEffect;
  }
  if (bookkeepingAlwaysChanges && finalDataAlwaysChanges) {
    return _ShippedTransitionCategory.eligibleArchetypeBookkeeping;
  }
  if (_effectsMutateRelatedOrNewInstance(transition.effects)) {
    return _ShippedTransitionCategory.relatedOrNewInstanceOnly;
  }
  return _ShippedTransitionCategory.noOp;
}

List<Map<String, dynamic>> _shippedSourceEffectOutcomes({
  required LoomWorkflowTransition transition,
  required Map<String, dynamic> instanceData,
  required String actorId,
  required String roleId,
}) {
  final inputValues = <String, dynamic>{
    for (final entry in (transition.inputs ?? const {}).entries.where(
      (entry) => entry.value.required,
    ))
      entry.key: entry.value.options != null && entry.value.options!.isNotEmpty
          ? entry.value.options!.first
          : _shippedTransitionInputValue(entry.key, entry.value.type, roleId),
  };

  List<Map<String, dynamic>> applyList(
    List<WorkflowEffect> effects,
    List<Map<String, dynamic>> sources,
  ) {
    var outcomes = sources;
    for (final effect in effects) {
      if (effect.op == workflowEffectBranch) {
        outcomes = [
          for (final outcome in outcomes) ...[
            ...applyList(effect.thenEffects, [outcome]),
            ...applyList(effect.elseEffects, [outcome]),
          ],
        ];
        continue;
      }
      if (effect.op == workflowEffectGenerateRecurringInstances) {
        outcomes = [
          for (final outcome in outcomes)
            Map<String, dynamic>.from(outcome)
              ..['seriesId'] = _seriesIdDifferentFrom(outcome['seriesId']),
        ];
        continue;
      }
      if (!_effectDirectlyMutatesSourceInstance(effect)) continue;
      outcomes = [
        for (final outcome in outcomes)
          applyEffects([effect], actorId, outcome, inputValues: inputValues),
      ];
    }
    return outcomes;
  }

  return applyList(transition.effects, [instanceData]);
}

bool _effectDirectlyMutatesSourceInstance(WorkflowEffect effect) {
  if (effect.key == null || effect.relatedInstance != null) return false;
  return switch (effect.op) {
    workflowEffectSet ||
    workflowEffectAppend ||
    workflowEffectAppendUnique ||
    workflowEffectRemoveValue ||
    workflowEffectIncrement ||
    workflowEffectDecrement => true,
    _ => false,
  };
}

bool _effectsMutateRelatedOrNewInstance(List<WorkflowEffect> effects) {
  for (final effect in effects) {
    if (effect.op == workflowEffectCreateInstance ||
        effect.op == workflowEffectTransitionRelated ||
        effect.op == workflowEffectGenerateRecurringInstances ||
        effect.relatedInstance != null ||
        _effectsMutateRelatedOrNewInstance(effect.thenEffects) ||
        _effectsMutateRelatedOrNewInstance(effect.elseEffects) ||
        _effectsMutateRelatedOrNewInstance(
          effect.onSuccessEffects ?? const [],
        )) {
      return true;
    }
  }
  return false;
}

Map<String, dynamic> _applyShippedArchetypeBookkeeping({
  required LoomWorkflowTransition transition,
  required String? archetypeFamily,
  required Map<String, dynamic> instanceData,
  required String actorId,
}) {
  final action = transition.action;
  final rule = archetypeFamily == null || action == null
      ? null
      : _shippedArchetypeBookkeepingByAction[archetypeFamily]?[action];
  if (rule == null) return instanceData;

  final (field, addsActor) = rule;
  final existing = instanceData[field];
  final values = existing is List ? List<dynamic>.from(existing) : <dynamic>[];
  final actorCount = values.where((value) => value == actorId).length;
  if (addsActor) {
    if (actorCount == 1) return instanceData;
    return Map<String, dynamic>.from(instanceData)
      ..[field] = <dynamic>[
        ...values.where((value) => value != actorId),
        actorId,
      ];
  }
  if (actorCount == 0) return instanceData;
  return Map<String, dynamic>.from(instanceData)
    ..[field] = values
        .where((value) => value != actorId)
        .toList(growable: false);
}

bool _sameInstanceData(Map<String, dynamic> left, Map<String, dynamic> right) =>
    jsonEncode(left) == jsonEncode(right);

String _seriesIdDifferentFrom(dynamic current) {
  const base = '__walkthrough-generated-series__';
  if (current != base) return base;
  return '${base}next';
}

bool _transitionCanBeSelectedForRole({
  required LoomWorkflowTransition transition,
  required LoomWorkflowSeedInstance instance,
  required String roleId,
  required bool allowViewerResponse,
}) {
  final guard = transition.guard;
  final allowedRoleIds = guard.allowedRoleIds;
  if (allowedRoleIds != null &&
      allowedRoleIds.isNotEmpty &&
      !allowedRoleIds.contains(roleId)) {
    return false;
  }

  if (!allowViewerResponse &&
      (guard.actorEqualsField != null || guard.actorInList?.present == true) &&
      _transitionAccountId(
            transition: transition,
            instance: instance,
            roleId: roleId,
            allowViewerResponse: false,
          ) ==
          null) {
    return false;
  }
  final dataEquals = guard.instanceDataEquals;
  if (dataEquals != null &&
      instance.instanceData[dataEquals.key] != dataEquals.value) {
    return false;
  }
  return true;
}

String? _transitionAccountId({
  required LoomWorkflowTransition transition,
  required LoomWorkflowSeedInstance instance,
  required String roleId,
  required bool allowViewerResponse,
}) {
  if (allowViewerResponse) return null;
  final guard = transition.guard;
  final actorField = guard.actorEqualsField;
  if (actorField != null) {
    final fanId = instance.instanceData[actorField.key];
    return fanId is String && _fanIdMatchesRole(fanId, roleId) ? fanId : null;
  }
  final actorList = guard.actorInList;
  if (actorList?.present == true) {
    final values = instance.instanceData[actorList!.key];
    if (values is List) {
      for (final fanId in values.whereType<String>()) {
        if (_fanIdMatchesRole(fanId, roleId)) return fanId;
      }
    }
  }
  return null;
}

bool _fanIdMatchesRole(String fanId, String roleId) =>
    fanId == roleId ||
    fanId.startsWith('$roleId-') ||
    fanId.startsWith('${roleId}_');

Future<void> _completeShippedTransitionInputs({
  required WidgetTester tester,
  required LoomWorkflowTransition transition,
  required String roleId,
}) async {
  final inputs = transition.inputs;
  if (inputs == null || inputs.isEmpty) return;

  final dialog = find.byKey(const ValueKey('generic-transition-input-dialog'));
  await waitForEngineNativeWidget(
    tester,
    dialog,
    description: 'input dialog for shipped action ${transition.id}',
  );

  for (final entry in inputs.entries.where((entry) => entry.value.required)) {
    final input = find.byKey(ValueKey('generic-transition-input-${entry.key}'));
    if (input.evaluate().isNotEmpty) {
      await tester.ensureVisible(input);
      await tester.enterText(
        input,
        _shippedTransitionInputValue(entry.key, entry.value.type, roleId),
      );
      continue;
    }

    final options = entry.value.options;
    if (options != null && options.isNotEmpty) {
      final option = find.byKey(
        ValueKey('generic-transition-input-${entry.key}-${options.first}'),
      );
      if (option.evaluate().isNotEmpty) {
        await tester.ensureVisible(option);
        await tester.tap(option, warnIfMissed: false);
        await tester.pump();
      }
    }
  }

  final confirm = find.byKey(
    const ValueKey('generic-transition-input-confirm'),
  );
  await tester.ensureVisible(confirm);
  await tester.tap(confirm, warnIfMissed: false);
  await tester.pump();
  expect(
    find.byKey(const ValueKey('generic-transition-input-validation-error')),
    findsNothing,
    reason:
        'Package-derived evidence inputs did not satisfy shipped action '
        '${transition.id}.',
  );
}

String _shippedTransitionInputValue(String key, String type, String roleId) {
  if (type == 'number') return '1';
  if (type == 'date' || key.toLowerCase().contains('date')) {
    return '2026-08-22';
  }
  if (type == 'fanId' || key.toLowerCase().endsWith('fanid')) {
    return roleId;
  }
  if (type == 'list') return 'evidence';
  return 'Evidence $key';
}

class _ShippedWorkflowActionWait {
  const _ShippedWorkflowActionWait._({
    this.action,
    this.unavailableReason,
    this.otherAvailableActions = const <LoomWorkflowTransition>[],
  });

  final ({_ShippedTransitionCandidate candidate, Finder finder})? action;
  final String? unavailableReason;
  final List<LoomWorkflowTransition> otherAvailableActions;
}

Future<_ShippedWorkflowActionWait> _waitForShippedWorkflowAction({
  required WidgetTester tester,
  required WalkthroughBodyWatch bodyWatch,
  required _ShippedWorkflowSelector selector,
  required Finder surface,
  required Finder actionSurface,
  required MarketplaceActionSurfacePreparation marketplacePreparation,
  required bool useMarketplaceDetailActionFinder,
  required List<_ShippedTransitionCandidate> candidates,
  required B25ProductDocInteractionModel b25Model,
  required String lastCompletedStep,
  required String attemptedStep,
  required String diagnosticFrameName,
  required Future<void> Function(String name) captureDiagnostic,
}) async {
  final calendarPreparation =
      await prepareCalendarActionSurfaceForActionPolling(
        tester: tester,
        surface: surface,
        tabId: selector.binding.tabId,
        instanceId: selector.instance.instanceId,
      );
  if (!calendarPreparation.isReadyForActionPolling) {
    return _throwShippedWorkflowActionStall(
      bodyWatch: bodyWatch,
      lastCompletedStep: lastCompletedStep,
      attemptedStep: attemptedStep,
      waitingFor:
          'Calendar action surface preparation did not complete: '
          '${calendarPreparation.preparationFailureDescription}',
      budget: WalkthroughWaitBudget(),
      diagnosticFrameName: diagnosticFrameName,
      captureDiagnostic: captureDiagnostic,
    );
  }
  final calendarDiagnostic = calendarPreparation.isCalendarSurface
      ? '${calendarPreparation.diagnosticDescription}. '
      : '';
  final marketplaceDiagnostic = marketplacePreparation.isMarketplaceSurface
      ? '${marketplacePreparation.diagnosticDescription}. '
      : '';
  final allActionFinders = <Finder>[
    for (final candidate in selector.transitions)
      find.descendant(
        of: actionSurface,
        matching: _shippedWorkflowActionFinder(
          selector: selector,
          transitionId: candidate.transition.id,
          useMarketplaceDetailActionFinder: useMarketplaceDetailActionFinder,
        ),
      ),
  ];
  var marketplaceActionLoad = inspectMarketplaceActionLoad(
    preparation: marketplacePreparation,
  );

  String pollingWaitingFor(
    PrimaryActionAvailability<_ShippedTransitionCandidate> availability,
  ) {
    marketplaceActionLoad = inspectMarketplaceActionLoad(
      preparation: marketplacePreparation,
    );
    final actionLoadDiagnostic =
        marketplaceActionLoad.diagnostic ??
        visibleActionLoadDiagnostic(actionSurface);
    return 'a tappable shipped workflow action on the '
        '${selector.binding.tabId} tab for ${selector.roleId}. '
        '$calendarDiagnostic'
        '$marketplaceDiagnostic'
        '${actionLoadDiagnostic == null ? '' : 'Action load diagnostic: $actionLoadDiagnostic. '}'
        'per-candidate readiness: [${availability.candidateDescriptions}].';
  }

  final actionAvailability = await waitForPrimaryActionAvailability(
    tester: tester,
    candidates: [
      for (final candidate in candidates)
        PrimaryActionCandidate(
          value: candidate,
          finder: find.descendant(
            of: actionSurface,
            matching: _shippedWorkflowActionFinder(
              selector: selector,
              transitionId: candidate.transition.id,
              useMarketplaceDetailActionFinder:
                  useMarketplaceDetailActionFinder,
            ),
          ),
          description:
              '${candidate.transition.id} (${candidate.transition.label})',
        ),
    ],
    onPoll: (availability) {
      // A 50ms poll is active work, not a stopped walkthrough. Beat before
      // the next awaited poll operation so the body watchdog still catches a
      // genuinely hung pump or platform call, while the bounded inner wait
      // owns its defined unavailable outcome.
      bodyWatch.beat(
        lastCompletedStep: lastCompletedStep,
        attemptedStep: attemptedStep,
        waitingFor: pollingWaitingFor(availability),
      );
    },
    shouldStopWaiting: (availability) {
      marketplaceActionLoad = inspectMarketplaceActionLoad(
        preparation: marketplacePreparation,
      );
      return classifyPreparedActionPolling(
            surfacePrepared: marketplacePreparation.isReadyForActionPolling,
            actionLoadSucceeded: marketplaceActionLoad.hasSucceeded,
            actionLoadFailed: marketplaceActionLoad.hasFailed,
            allPrimaryCandidatesPresentAndDisabled:
                availability.allCandidatesPresentAndDisabled,
            allActionCandidatesAbsent: actionFindersAreAllAbsent(
              allActionFinders,
            ),
            anyOtherTappable: false,
          ) !=
          PreparedActionPollingDecision.keepWaiting;
    },
  );
  final latestPollingWaitingFor = pollingWaitingFor(actionAvailability);
  if (actionAvailability.hasReadyAction) {
    final readyAction = actionAvailability.candidate!;
    return _ShippedWorkflowActionWait._(
      action: (candidate: readyAction.value, finder: readyAction.finder),
    );
  }
  if (actionAvailability.allCandidatesPresentAndDisabled) {
    // The engine intentionally withholds disabled transitions, such as an
    // RSVP whose capacity guard has become false. Waiting cannot change that
    // answer: record the unavailable branch immediately instead of consuming
    // the inner three-minute budget.
    return _ShippedWorkflowActionWait._(
      unavailableReason:
          'primary_action_unavailable: every primary candidate is present '
          'but disabled. $latestPollingWaitingFor',
    );
  }
  marketplaceActionLoad = inspectMarketplaceActionLoad(
    preparation: marketplacePreparation,
  );
  final allActionCandidatesAbsent = actionFindersAreAllAbsent(allActionFinders);
  final primaryPollingDecision = classifyPreparedActionPolling(
    surfacePrepared: marketplacePreparation.isReadyForActionPolling,
    actionLoadSucceeded: marketplaceActionLoad.hasSucceeded,
    actionLoadFailed: marketplaceActionLoad.hasFailed,
    allPrimaryCandidatesPresentAndDisabled:
        actionAvailability.allCandidatesPresentAndDisabled,
    allActionCandidatesAbsent: allActionCandidatesAbsent,
    anyOtherTappable: false,
  );
  if (primaryPollingDecision == PreparedActionPollingDecision.unavailable) {
    if (!allActionCandidatesAbsent) {
      throw StateError(
        'Unavailable primary-action decision for '
        '${selector.instance.instanceId} had neither disabled primary '
        'actions nor a fully absent action set.',
      );
    }
    return _ShippedWorkflowActionWait._(
      unavailableReason:
          'primary_action_unavailable: '
          '${_describePrimaryUnavailability(selector: selector, availability: actionAvailability, surface: actionSurface, surfacePrepared: marketplacePreparation.isReadyForActionPolling, actionLoadSucceeded: marketplaceActionLoad.hasSucceeded)} '
          '$latestPollingWaitingFor',
    );
  }
  if (primaryPollingDecision == PreparedActionPollingDecision.stall) {
    return _throwShippedWorkflowActionStall(
      bodyWatch: bodyWatch,
      lastCompletedStep: lastCompletedStep,
      attemptedStep: attemptedStep,
      waitingFor: latestPollingWaitingFor,
      budget: actionAvailability.budget,
      diagnosticFrameName: diagnosticFrameName,
      captureDiagnostic: captureDiagnostic,
    );
  }
  final preparedOtherActions = await findReadyActionCandidatesOnSurface(
    tester: tester,
    surface: actionSurface,
    candidates: [
      for (final candidate in selector.transitions)
        if (!candidates.any(
          (primaryCandidate) =>
              primaryCandidate.transition.id == candidate.transition.id,
        ))
          PrimaryActionCandidate(
            value: candidate,
            finder: _shippedWorkflowActionFinder(
              selector: selector,
              transitionId: candidate.transition.id,
              useMarketplaceDetailActionFinder:
                  useMarketplaceDetailActionFinder,
            ),
            description: candidate.transition.label,
          ),
    ],
  );
  if (preparedOtherActions.isNotEmpty) {
    final namedOtherActions =
        preparedOtherActions
            .map((candidate) => candidate.value.transition)
            .toList(growable: false)
          ..sort((left, right) {
            int priority(LoomWorkflowTransition transition) {
              final match = matchB25TransitionAgainstTerms(
                transition,
                primaryTerms: b25Model.requiredPrimaryActions,
                alternateTerms: b25Model.requiredAlternateActions,
              );
              // A real action outside the documented primary/alternate terms is
              // supplementary evidence. Lead with it rather than silently
              // presenting it as the documented alternate path.
              return match.alternate ? 1 : 0;
            }

            return priority(left).compareTo(priority(right));
          });
    final fallbackOutcome = describePreparedFallbackAvailability(
      primaryUnavailableDescription: _describePrimaryUnavailability(
        selector: selector,
        availability: actionAvailability,
        surface: actionSurface,
        surfacePrepared: marketplacePreparation.isReadyForActionPolling,
        actionLoadSucceeded: marketplaceActionLoad.hasSucceeded,
      ),
      preparedActionDescriptions: namedOtherActions.map(
        (candidate) => candidate.label,
      ),
      documentedPrimaryRequirementDescription:
          _documentedPrimaryRequirementDescription(b25Model),
    );
    // A non-empty prepared-action result always has a diagnostic. Keep the
    // guard explicit so an accidental helper regression cannot turn a real
    // alternative into an unnamed unavailable outcome.
    if (fallbackOutcome == null) {
      throw StateError(
        'Prepared fallback actions for ${selector.instance.instanceId} were '
        'non-empty but had no diagnostic description.',
      );
    }
    // The instance is live and offers other actions, but none of the
    // required primary actions is offered to this role in this state. The
    // prepared alternatives are evidence of that state, never a substitute
    // for the required primary proof.
    return _ShippedWorkflowActionWait._(
      unavailableReason:
          'primary_action_unavailable: $fallbackOutcome '
          '$latestPollingWaitingFor',
      otherAvailableActions: namedOtherActions,
    );
  }
  return _throwShippedWorkflowActionStall(
    bodyWatch: bodyWatch,
    lastCompletedStep: lastCompletedStep,
    attemptedStep: attemptedStep,
    waitingFor: latestPollingWaitingFor,
    budget: actionAvailability.budget,
    diagnosticFrameName: diagnosticFrameName,
    captureDiagnostic: captureDiagnostic,
  );
}

Future<Never> _throwShippedWorkflowActionStall({
  required WalkthroughBodyWatch bodyWatch,
  required String lastCompletedStep,
  required String attemptedStep,
  required String waitingFor,
  required WalkthroughWaitBudget budget,
  required String diagnosticFrameName,
  required Future<void> Function(String name) captureDiagnostic,
}) async {
  bodyWatch.beat(
    lastCompletedStep: lastCompletedStep,
    attemptedStep: attemptedStep,
    waitingFor: 'capturing $diagnosticFrameName after $waitingFor',
  );
  await captureDiagnostic(diagnosticFrameName);
  throw WalkthroughStallFailure(
    buildWalkthroughStallMessage(
      lastCompletedStep: lastCompletedStep,
      attemptedStep: attemptedStep,
      waitingFor: waitingFor,
      budget: budget,
      diagnosticFrameName: diagnosticFrameName,
    ),
  );
}

String _documentedPrimaryRequirementDescription(
  B25ProductDocInteractionModel model,
) {
  final primaryTerms = model.requiredPrimaryActions
      .map(b25NormalizeActionText)
      .toSet();
  final isAttendanceRequirement = primaryTerms.any(
    (term) =>
        term.contains('rsvp') ||
        term.contains('attend') ||
        term.contains('going') ||
        term.contains('reserve spot'),
  );
  return isAttendanceRequirement
      ? 'documented primary attendance action'
      : 'documented primary action';
}

String _describePrimaryUnavailability({
  required _ShippedWorkflowSelector selector,
  required PrimaryActionAvailability<_ShippedTransitionCandidate> availability,
  required Finder surface,
  required bool surfacePrepared,
  required bool actionLoadSucceeded,
}) {
  if (surfacePrepared && actionLoadSucceeded) {
    for (final candidate in availability.candidateReadiness) {
      if (candidate.readiness.state != FinderTapReadinessState.absent) {
        continue;
      }
      final denial = describeOwnedGiveawayFormulaDenial(
        transitionId: candidate.candidate.value.transition.id,
        instanceData: selector.instance.instanceData,
        actorId: selector.accountId ?? selector.roleId,
        guardFormula: candidate.candidate.value.transition.guard.formula,
      );
      if (denial != null) return denial;
    }
  }
  final goingIsAbsent = availability.candidateReadiness.any(
    (candidate) =>
        candidate.readiness.state == FinderTapReadinessState.absent &&
        b25NormalizeActionText(candidate.candidate.value.transition.label) ==
            'going',
  );
  final capacityText = find
      .descendant(of: surface, matching: find.byType(Text))
      .evaluate()
      .map((element) {
        final text = element.widget as Text;
        return text.data ?? text.textSpan?.toPlainText() ?? '';
      })
      .map((text) => text.trim())
      .firstWhere(
        (text) => RegExp(r'^\d+\s*/\s*\d+\s+going$').hasMatch(text),
        orElse: () => '',
      );
  final capacity = RegExp(
    r'^(\d+)\s*/\s*(\d+)\s+going$',
  ).firstMatch(capacityText);
  if (goingIsAbsent &&
      capacity != null &&
      capacity.group(1) == capacity.group(2)) {
    final title = selector.instance.instanceData['title']?.toString().trim();
    final eventName = title == null || title.isEmpty
        ? selector.instance.instanceId
        : title;
    return 'Going unavailable: $eventName is full, '
        '${capacity.group(1)}/${capacity.group(2)}.';
  }
  final absentPrimaryLabels = availability.candidateReadiness
      .where(
        (candidate) =>
            candidate.readiness.state == FinderTapReadinessState.absent,
      )
      .map((candidate) => candidate.candidate.value.transition.label)
      .toSet()
      .toList(growable: false);
  return absentPrimaryLabels.isEmpty
      ? 'The required primary action was not tappable.'
      : '${absentPrimaryLabels.join(' and ')} unavailable.';
}

Finder _engineInstanceFinder(String instanceId) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.contains(instanceId);
  }, description: 'engine-native widget for $instanceId');
}

Finder _engineActionFinder(String instanceId, String transitionId) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.contains(instanceId) &&
        (key.value.endsWith('-action-$transitionId') ||
            key.value.endsWith('-$transitionId-$instanceId'));
  }, description: '$instanceId action $transitionId');
}

/// Marketplace detail controls intentionally omit their listing instance id.
/// Their caller supplies the exact opened dialog as the surrounding finder so
/// a same-shaped tile action behind the modal barrier can never satisfy this
/// lookup.
Finder _shippedWorkflowActionFinder({
  required _ShippedWorkflowSelector selector,
  required String transitionId,
  required bool useMarketplaceDetailActionFinder,
}) => useMarketplaceDetailActionFinder
    ? marketplaceDetailActionFinder(transitionId)
    : _engineActionFinder(selector.instance.instanceId, transitionId);

class _ShippedWorkflowSelector {
  const _ShippedWorkflowSelector({
    required this.machine,
    required this.actionMachine,
    required this.actionSourceState,
    required this.actionArchetypeFamily,
    required this.instance,
    required this.binding,
    required this.roleId,
    required this.accountId,
    required this.transitions,
  });

  final LoomWorkflowStateMachine machine;
  final LoomWorkflowStateMachine actionMachine;
  final String actionSourceState;
  final String? actionArchetypeFamily;
  final LoomWorkflowSeedInstance instance;
  final RenderBinding binding;
  final String roleId;
  final String? accountId;
  final List<_ShippedTransitionCandidate> transitions;
}

String _packageRoleId({
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required String label,
}) {
  final matches = package.experience.actorIdentities!
      .where((actorIdentity) => actorIdentity.label == label)
      .toList(growable: false);
  if (matches.length != 1) {
    fail(
      'Shipped package ${target.extensionId} must expose exactly one actor identity '
      'labelled "$label"; found '
      '${matches.map((actorIdentity) => actorIdentity.roleId).toList()}.',
    );
  }
  return matches.single.roleId;
}

Future<void> _showShippedWorkflowInstance({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required String roleId,
  bool selectRole = true,
}) async {
  if (selectRole) {
    await selectActorIdentity(tester, roleId);
  }
  final tabs = appShellTabsFor(
    experience: package.experience,
    roleId: roleId,
    appShellConfiguration: package.appShellConfiguration,
  );
  final tabIds = tabs.map((tab) => tab.tabId).toSet();
  final bindings =
      selector.machine.renderBindings
          .where(
            (binding) =>
                binding.states.contains(selector.instance.currentState) &&
                tabIds.contains(binding.tabId),
          )
          .toList(growable: false)
        ..sort((left, right) {
          int score(RenderBinding binding) =>
              (binding.bindingKind == 'primary' ? 0 : 2) +
              (binding.role == 'any' ? 0 : 1);
          return score(left).compareTo(score(right));
        });
  if (bindings.isEmpty) {
    fail(
      'Shipped workflow ${selector.machine.workflowType} instance '
      '${selector.instance.instanceId} has no package-declared binding visible '
      'to $roleId in ${target.extensionId}.',
    );
  }
  final binding = bindings.first;
  await _selectPackageTab(
    tester: tester,
    target: target,
    package: package,
    roleId: roleId,
    tabId: binding.tabId,
  );
  final instance = _engineInstanceFinder(selector.instance.instanceId);
  await waitForEngineNativeWidget(
    tester,
    instance,
    description:
        'shipped ${selector.machine.workflowType} instance '
        '${selector.instance.instanceId} for $roleId',
  );
  await tester.ensureVisible(instance.first);
  await tester.pumpAndSettle();
}

Future<void> _selectPackageTab({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required String roleId,
  required String tabId,
}) async {
  final packageTabIds = appShellTabsFor(
    experience: package.experience,
    roleId: roleId,
    appShellConfiguration: package.appShellConfiguration,
  ).map((tab) => tab.tabId).toSet();
  expect(
    packageTabIds,
    contains(tabId),
    reason:
        'Shipped package ${target.extensionId} did not declare tab $tabId '
        'for role $roleId. Package tabs for that role: $packageTabIds.',
  );
  await _selectCommunityTab(tester, tabId);
}

class _PublishedShippedAnnouncement {
  const _PublishedShippedAnnouncement({
    required this.instanceId,
    required this.productFinding,
    required this.actionExecutionEvidence,
  });

  final String instanceId;
  final String? productFinding;
  final B25ActionExecutionEvidence actionExecutionEvidence;
}

Future<_PublishedShippedAnnouncement> _createAndPublishShippedAnnouncement({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required String adminRoleId,
  required Future<void> Function(String name) capture,
  required String screenshotPrefix,
  required String announcementTitle,
}) async {
  await selectActorIdentity(tester, adminRoleId);
  final creationBindings = selector.machine.renderBindings.where(
    (binding) =>
        binding.states.contains(selector.machine.initialState) &&
        binding.actions.any(
          (action) =>
              action.kind == 'create' &&
              (action.byRoleIds == null ||
                  action.byRoleIds!.contains(adminRoleId)),
        ),
  );
  if (creationBindings.isEmpty) {
    fail(
      'Shipped workflow ${selector.machine.workflowType} did not declare a '
      'create binding for $adminRoleId.',
    );
  }
  final creationBinding = creationBindings.first;
  await _selectPackageTab(
    tester: tester,
    target: target,
    package: package,
    roleId: adminRoleId,
    tabId: creationBinding.tabId,
  );

  final workflowType = selector.machine.workflowType;
  final createFab = find.byKey(ValueKey('creatable-fab-$workflowType'));
  final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
  await prepareCreatableFabForTap(
    tester: tester,
    createFab: createFab,
    speedDial: speedDial,
    workflowType: workflowType,
    roleId: adminRoleId,
  );
  await waitForEngineNativeWidget(
    tester,
    createFab,
    description: 'shipped $workflowType create action for $adminRoleId',
  );
  await tester.ensureVisible(createFab.first);
  await tester.pumpAndSettle();
  expect(
    createFab.hitTestable(),
    findsOneWidget,
    reason:
        'Shipped $workflowType declared a create FAB for $adminRoleId, but '
        'the package surface did not make it interactive.',
  );
  await capture('${screenshotPrefix}_admin_start');
  await tester.tap(createFab.first, warnIfMissed: false);
  await tester.pumpAndSettle();

  final keyPrefix = 'new-$workflowType';
  final titleEditor = find.byKey(ValueKey('$keyPrefix-editor-title'));
  await waitForEngineNativeWidget(
    tester,
    titleEditor,
    description: 'shipped $workflowType creation form',
  );
  await capture('${screenshotPrefix}_admin_action');

  const values = <String, String>{
    'body':
        'The walkthrough admin published this update from the shipped Masjid experience.',
    'audience': 'All Masjid Nur members',
    'channel': 'Home and Messages',
  };
  final fieldValues = <String, String>{...values, 'title': announcementTitle};
  final editableFields =
      selector.machine.states[selector.machine.initialState]?.editableFields ??
      const <String>[];
  for (final field in editableFields) {
    final schema = selector.machine.instanceDataSchema[field];
    if (schema == null || !schema.required) {
      continue;
    }
    final value = fieldValues[field];
    if (value == null) {
      fail(
        'Shipped $workflowType added required creation field "$field"; the '
        'canonical walkthrough needs a package-driven value for it.',
      );
    }
    final editor = find.byKey(ValueKey('$keyPrefix-editor-$field'));
    expect(
      editor,
      findsOneWidget,
      reason:
          'Shipped $workflowType declared required editable field "$field" '
          'but did not render its package-driven editor.',
    );
    await tester.enterText(editor, value);
  }
  final submit = find.byKey(ValueKey('$keyPrefix-submit'));
  await tester.ensureVisible(submit);
  final existingInstanceIds = engineNativeInstanceIdsForTab(
    tester,
    tabId: creationBinding.tabId,
  );
  await tester.tap(submit, warnIfMissed: false);
  final instanceId = await waitForCreatedEngineNativeInstanceId(
    tester,
    workflowType: workflowType,
    tabId: creationBinding.tabId,
    existingInstanceIds: existingInstanceIds,
  );

  final preview = _packageTransitionByLabel(
    target: target,
    machine: selector.machine,
    label: 'Preview announcement',
  );
  final publish = _packageTransitionByLabel(
    target: target,
    machine: selector.machine,
    label: 'Publish announcement',
  );
  final saveDraft = _packageTransitionByLabel(
    target: target,
    machine: selector.machine,
    label: 'Save draft',
  );
  final saveDraftAction = _engineActionFinder(instanceId, saveDraft.id);
  await waitForEngineNativeWidget(
    tester,
    saveDraftAction,
    description: 'created announcement Save draft alternate action',
  );
  await tester.ensureVisible(saveDraftAction.first);
  await capture('${screenshotPrefix}_admin_alternate_action');
  await tester.tap(saveDraftAction.first, warnIfMissed: false);
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await capture('${screenshotPrefix}_admin_alternate_result');
  final previewAction = _engineActionFinder(instanceId, preview.id);
  await waitForEngineNativeWidget(
    tester,
    previewAction,
    description: 'created announcement preview action',
  );
  await tester.ensureVisible(previewAction.first);
  await tester.tap(previewAction.first, warnIfMissed: false);
  final publishAction = _engineActionFinder(instanceId, publish.id);
  await waitForEngineNativeWidget(
    tester,
    publishAction,
    description: 'created announcement publish action',
  );
  await tester.ensureVisible(publishAction.first);
  await capture('${screenshotPrefix}_admin_primary_action');
  await tester.tap(publishAction.first, warnIfMissed: false);
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  final publishActionExecutionEvidence = _observeB25ActionExecutionAfterTap(
    action: publishAction,
    transitionId: publish.id,
  );
  final publishTargetState = publish.to;
  if (publishTargetState == null) {
    fail(
      'Shipped ${target.extensionId} ${selector.machine.workflowType} '
      'publish transition ${publish.id} has no target state.',
    );
  }
  final confirmedPublishAction = await _expectShippedInstanceIdState(
    tester: tester,
    target: target,
    package: package,
    selector: selector,
    instanceId: instanceId,
    targetState: publishTargetState,
    transitionId: publish.id,
    actionExecutionEvidence: publishActionExecutionEvidence,
  );
  final productFinding = publishAction.evaluate().isNotEmpty
      ? '${target.communityName} / ${selector.machine.workflowType} / '
            '$adminRoleId: ${publish.id} persisted ${publishTargetState} for '
            '$instanceId, but the shipped Admin surface still offers that '
            'completed action. The package declares ${publish.id} only from '
            '${publish.from.join(', ')}; it must not remain executable from '
            '$publishTargetState.'
      : null;
  await _selectPackageTab(
    tester: tester,
    target: target,
    package: package,
    roleId: adminRoleId,
    tabId: 'home',
  );
  await waitForEngineNativeWidget(
    tester,
    _engineInstanceFinder(instanceId),
    description: 'published announcement on shipped Home surface',
  );
  await capture('${screenshotPrefix}_admin_complete');
  return _PublishedShippedAnnouncement(
    instanceId: instanceId,
    productFinding: productFinding,
    actionExecutionEvidence: confirmedPublishAction,
  );
}

LoomWorkflowTransition _packageTransitionByLabel({
  required LoomEvidenceTarget target,
  required LoomWorkflowStateMachine machine,
  required String label,
}) {
  final matches = machine.transitions
      .where((transition) => transition.label == label)
      .toList(growable: false);
  if (matches.length != 1) {
    fail(
      'Shipped ${target.extensionId} workflow ${machine.workflowType} must '
      'declare exactly one transition labelled "$label"; found '
      '${matches.map((transition) => transition.id).toList()}.',
    );
  }
  return matches.single;
}

Future<void> _prepareCalendarExpandedShippedWorkflowDetail({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
}) async {
  final calendarSurface = find.byKey(
    const ValueKey('engine-native-calendar-root'),
  );
  await waitForEngineNativeWidget(
    tester,
    calendarSurface,
    description: 'shipped Calendar surface for ${selector.instance.instanceId}',
  );
  await prepareCalendarExpandedDetailForEvidence(
    tester: tester,
    surface: calendarSurface,
    instanceId: selector.instance.instanceId,
  );
}

Future<void> _expandShippedWorkflowSurface({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
}) async {
  final instanceId = selector.instance.instanceId;
  final tableRow = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('workflow-table-row-') &&
        key.value.contains(instanceId);
  }, description: 'shipped table row for $instanceId');
  if (tableRow.evaluate().isNotEmpty) {
    await tester.ensureVisible(tableRow.first);
    await tester.tap(tableRow.first, warnIfMissed: false);
    final detail = find.byKey(
      ValueKey('workflow-table-detail-dialog-$instanceId'),
    );
    await waitForEngineNativeWidget(
      tester,
      detail,
      description: 'expanded shipped table detail for $instanceId',
    );
    expect(detail, findsOneWidget);
    return;
  }

  final tile = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.contains(instanceId) &&
        (key.value.startsWith('engine-native-list-item-') ||
            key.value.startsWith('event-rsvp-card-') ||
            key.value.startsWith('generic-instance-card-'));
  }, description: 'shipped workflow tile for $instanceId');
  await waitForEngineNativeWidget(
    tester,
    tile,
    description: 'expandable shipped workflow tile for $instanceId',
  );
  await tester.ensureVisible(tile.first);
  await tester.tap(tile.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  final detail = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.contains(instanceId) &&
        (key.value.contains('detail') || key.value.contains('dialog'));
  }, description: 'expanded shipped workflow detail for $instanceId');
  expect(
    detail,
    findsWidgets,
    reason:
        'Shipped workflow ${selector.machine.workflowType} rendered its '
        'medium surface, but tapping it exposed no expanded/detail surface.',
  );
}

/// Closes the exact expanded table or marketplace surface that this
/// walkthrough opened. Calendar details are inline and intentionally have no
/// close control. This is not a generic overlay recovery: an unexpected
/// expanded surface fails by naming the missing owned close affordance.
Future<void> _closeExpandedShippedWorkflowSurface({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
}) async {
  final instanceId = selector.instance.instanceId;
  final closeControls = <Finder>[
    find.byKey(ValueKey('workflow-table-detail-close-$instanceId')),
    find.byKey(ValueKey('marketplace-detail-close-$instanceId')),
  ];
  final present = closeControls
      .where((control) => control.evaluate().isNotEmpty)
      .toList(growable: false);
  if (present.isEmpty) {
    final openDetail = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.contains(instanceId) &&
          (key.value.contains('detail') || key.value.contains('dialog'));
    });
    if (openDetail.evaluate().isEmpty) return;
    fail(
      'Shipped ${selector.machine.workflowType} expanded surface for '
      '$instanceId remained open but exposed no package-owned close control.',
    );
  }
  if (present.length != 1) {
    fail(
      'Shipped ${selector.machine.workflowType} expanded surface for '
      '$instanceId exposed ${present.length} package-owned close controls; '
      'expected exactly one.',
    );
  }
  await tester.tap(present.single, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _selectCommunityTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  await tester.scrollUntilVisible(
    tab,
    120,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('community-bottom-tabs')),
      matching: find.byType(Scrollable),
    ),
    maxScrolls: 16,
  );
  await _pumpB25Frames(tester);
  await tester.tap(tab, warnIfMissed: false);
  await _pumpB25Frames(tester);
}

Future<int> _roleMatrixRowCount(
  List<LoomEvidenceTarget> evidenceTargets,
) async {
  var total = 0;
  for (final target in evidenceTargets) {
    final package = await readShippedEvidencePackage(target);
    total +=
        package.experience.actorIdentities!.length *
        package.experience.workflowDefinitions!.length;
  }
  return total;
}
