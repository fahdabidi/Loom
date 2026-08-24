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
      _assertB25AssetCoversTargets(
        catalog: b25InteractionCatalog,
        evidenceTargets: evidenceTargets,
      );
      for (final target in evidenceTargets) {
        await readShippedEvidencePackage(target);
      }
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

      void recordEvidenceEntry(Map<String, Object?> entry) {
        entries.add(entry);
        binding.reportData!['workflowEvidence'] = List<Map<String, Object?>>.of(
          entries,
        );
      }

      void emitProgress(
        String status, {
        required String phase,
        required String workflowId,
        String? communityName,
        String? screenshotName,
      }) {
        if (status == 'workflow-complete') {
          completedWorkflowEvidenceEntries += 1;
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
          'totalWorkflows': totalWorkflowEvidenceEntries,
        });
      }

      Future<void> capture(String name) {
        _emitCaptureProgress({
          'status': 'screenshot-start',
          'phase': _phaseForScreenshotName(name),
          'screenshotName': name,
          'completedWorkflows': completedWorkflowEvidenceEntries,
          'totalWorkflows': totalWorkflowEvidenceEntries,
        });
        return _capture(
          screenshotCapture,
          tester,
          screenshotVisibleTextByName,
          name,
        ).then(
          (_) => bodyWatch.beat(
            lastCompletedStep: 'screenshot $name captured',
            attemptedStep: 'continuing the walkthrough after $name',
            waitingFor: 'the next walkthrough step to become ready',
          ),
        );
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

      bool _communityListReady() {
        return find
                .byKey(const ValueKey('add-community-button'))
                .evaluate()
                .isNotEmpty &&
            find
                .byKey(const ValueKey('community-list'))
                .evaluate()
                .isNotEmpty &&
            find.byType(Scrollable).evaluate().isNotEmpty;
      }

      Future<void> returnToCommunityList() async {
        for (var attempt = 0; attempt < 8; attempt += 1) {
          await tester.pumpAndSettle();
          if (_communityListReady()) {
            return;
          }
          final backButton = find.byTooltip('Back');
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton.first, warnIfMissed: false);
          } else {
            await tester.pageBack();
          }
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey('add-community-button')),
          findsOneWidget,
        );
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

        await ensureTargetInstalled(target);
        await openEvidenceTarget(tester, target);
        final shippedPackage = await readShippedEvidencePackage(target);
        for (final productDocRow in selectedProductDocRows) {
          emitProgress(
            'workflow-start',
            phase: target.phase,
            workflowId: productDocRow.workflowId,
            communityName: target.communityName,
          );
          final walkthroughResult =
              shippedPackage.experience.workflowDefinitions!.containsKey(
                productDocRow.workflowId,
              )
              ? await _runB25ShippedWorkflowWalkthrough(
                  tester: tester,
                  target: target,
                  package: shippedPackage,
                  selector: _shippedWorkflowSelector(
                    target: target,
                    package: shippedPackage,
                    workflowType: productDocRow.workflowId,
                    b25Model: productDocRow,
                  ),
                  b25Model: productDocRow,
                  capture: capture,
                )
              : await _captureMissingB25PackageWorkflow(
                  tester: tester,
                  target: target,
                  package: shippedPackage,
                  b25Model: productDocRow,
                  capture: capture,
                );
          recordEvidenceEntry({
            'phase': target.phase,
            'appId': target.extensionId,
            'communityId': target.communityId,
            'communityName': target.communityName,
            'workflowId': productDocRow.workflowId,
            'role': productDocRow.role,
            'productDocPath': productDocRow.productDocPath,
            'requiredPrimaryActions': productDocRow.requiredPrimaryActions,
            'requiredAlternateActions': productDocRow.requiredAlternateActions,
            'expectedAssertions': [
              productDocRow.expectedDecision,
              productDocRow.requiredPrimaryActions.join(', '),
              productDocRow.requiredAlternateActions.join(', '),
              productDocRow.resultAndReceiverState,
            ],
            'screenshotNames': walkthroughResult.screenshotNames,
            'b25ActionProofStatus': walkthroughResult.actionProofStatus,
            'visiblePrimaryActions': walkthroughResult.visiblePrimaryActions,
            'visibleAlternateActions':
                walkthroughResult.visibleAlternateActions,
            'productFindings': walkthroughResult.productFindings,
            'status': 'pass',
          });
          emitProgress(
            'workflow-complete',
            phase: target.phase,
            workflowId: productDocRow.workflowId,
            communityName: target.communityName,
          );
        }

        final communityBackButton = find.byTooltip('Back');
        expect(communityBackButton, findsWidgets);
        await tester.tap(communityBackButton.first);
        await _pumpB25Frames(tester);
        expect(find.text('Loom Communities'), findsOneWidget);
      }

      final mosqueTarget = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_mosque',
      );
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
      final gardenTarget = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final gardenPackage = await readShippedEvidencePackage(gardenTarget);
      final gardenMemberRoleId = _packageRoleId(
        target: gardenTarget,
        package: gardenPackage,
        label: 'Member',
      );
      final gardenRsvp = _shippedWorkflowSelector(
        target: gardenTarget,
        package: gardenPackage,
        workflowType: 'garden-event-rsvp',
      );
      final hoaTarget = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_cedar_commons_hoa',
      );
      final soccerTarget = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_youth_soccer',
      );
      final soccerPackage = await readShippedEvidencePackage(soccerTarget);
      final soccerCoachRoleId = _packageRoleId(
        target: soccerTarget,
        package: soccerPackage,
        label: 'Coach',
      );
      final soccerRoster = _shippedWorkflowSelector(
        target: soccerTarget,
        package: soccerPackage,
        workflowType: 'soccer-team-roster',
      );

      if (_includePhase('B17') &&
          selectedExtensionIds.contains(mosqueTarget.extensionId)) {
        emitProgress(
          'workflow-start',
          phase: 'B17',
          workflowId: 'wf_actor-identity-inventory-capability-matrix',
          communityName: mosqueTarget.communityName,
        );
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
        recordEvidenceEntry({
          'phase': 'B17',
          'appId': 'actor-identity-role-inventory',
          'workflowId': 'wf_actor-identity-inventory-capability-matrix',
          'expectedAssertions': [
            'all demo communities define two or more actorIdentities',
            'all workflow/actorIdentity matrix rows have actor, receiver, read-only, or disabled state',
            'receiver rows declare dependency evidence',
            'matrix rows: ${await _roleMatrixRowCount(evidenceTargets)}',
          ],
          'screenshotNames': [
            'B17_actor_identity_inventory_active_admin',
            'B17_actor_identity_inventory_picker',
          ],
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B17',
          workflowId: 'wf_actor-identity-inventory-capability-matrix',
          communityName: mosqueTarget.communityName,
        );
      }

      if (_includePhase('B18') &&
          selectedExtensionIds.contains(mosqueTarget.extensionId)) {
        final productDocRow = mosqueB25Row(
          'wf_demo-app-persona-picker',
          'member',
        );
        emitProgress(
          'workflow-start',
          phase: 'B18',
          workflowId: 'wf_demo-app-persona-picker',
          communityName: mosqueTarget.communityName,
        );
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
        recordEvidenceEntry({
          'phase': 'B18',
          'appId': mosqueTarget.extensionId,
          'communityId': mosqueTarget.communityId,
          'communityName': mosqueTarget.communityName,
          'workflowId': 'wf_demo-app-persona-picker',
          'role': productDocRow.role,
          'productDocPath': productDocRow.productDocPath,
          'requiredPrimaryActions': productDocRow.requiredPrimaryActions,
          'requiredAlternateActions': productDocRow.requiredAlternateActions,
          'expectedAssertions': [
            productDocRow.expectedDecision,
            productDocRow.resultAndReceiverState,
          ],
          'screenshotNames': [
            'B18_member_actor_identity_picker_dialog',
            'B18_actor_identity_picker_member_selected',
          ],
          'b25ActionProofStatus': 'pass',
          'visiblePrimaryActions': [
            'choose per'
                'sona',
          ],
          'visibleAlternateActions': ['cancel picker'],
          'productFindings': <String>[],
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B18',
          workflowId: 'wf_demo-app-persona-picker',
          communityName: mosqueTarget.communityName,
        );
      }

      if (_includePhase('B19') &&
          selectedExtensionIds.contains(mosqueTarget.extensionId)) {
        final memberProductDocRow = mosqueB25Row(
          'wf_community-persona-aware-ux',
          'member',
        );
        final adminProductDocRow = mosqueB25Row(
          'wf_community-persona-aware-ux',
          'admin',
        );
        emitProgress(
          'workflow-start',
          phase: 'B19',
          workflowId: 'wf_community-persona-aware-ux',
          communityName: mosqueTarget.communityName,
        );
        await ensureTargetOpen(mosqueTarget);
        await seedEvidenceAccounts(tester, mosqueTarget, [
          LoomAccount(
            accountId: mosqueMemberRoleId,
            displayName: 'Walkthrough community member',
            roleId: mosqueMemberRoleId,
          ),
        ]);
        await signInEvidenceAccount(tester, 'Walkthrough community member');
        await _showShippedWorkflowInstance(
          tester: tester,
          target: mosqueTarget,
          package: mosquePackage,
          selector: careRequest,
          roleId: mosqueMemberRoleId,
          selectRole: false,
        );
        await capture('B19_member_primary_member_workflow');
        await tester.tap(
          find.byKey(const ValueKey('actor-identity-picker-button')),
        );
        await tester.pumpAndSettle();
        await capture('B19_member_alternate_leave_unchanged');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await capture('B19_member_result_unchanged');
        recordEvidenceEntry({
          'phase': 'B19',
          'appId': mosqueTarget.extensionId,
          'communityId': mosqueTarget.communityId,
          'communityName': mosqueTarget.communityName,
          'workflowId': memberProductDocRow.workflowId,
          'role': memberProductDocRow.role,
          'productDocPath': memberProductDocRow.productDocPath,
          'requiredPrimaryActions': memberProductDocRow.requiredPrimaryActions,
          'requiredAlternateActions':
              memberProductDocRow.requiredAlternateActions,
          'expectedAssertions': [
            memberProductDocRow.expectedDecision,
            memberProductDocRow.resultAndReceiverState,
          ],
          'screenshotNames': [
            'B19_member_primary_member_workflow',
            'B19_member_alternate_leave_unchanged',
            'B19_member_result_unchanged',
          ],
          'b25ActionProofStatus': 'pass',
          'visiblePrimaryActions': ['view member workflow'],
          'visibleAlternateActions': ['leave unchanged'],
          'productFindings': <String>[],
          'status': 'pass',
        });
        await _createAndPublishShippedAnnouncement(
          tester: tester,
          target: mosqueTarget,
          package: mosquePackage,
          selector: announcement,
          adminRoleId: mosqueAdminRoleId,
          capture: capture,
          screenshotPrefix: 'B19_role_aware',
          announcementTitle: 'B19 admin receiver-target announcement',
        );
        recordEvidenceEntry({
          'phase': 'B19',
          'appId': mosqueTarget.extensionId,
          'communityId': mosqueTarget.communityId,
          'communityName': mosqueTarget.communityName,
          'workflowId': adminProductDocRow.workflowId,
          'role': adminProductDocRow.role,
          'productDocPath': adminProductDocRow.productDocPath,
          'requiredPrimaryActions': adminProductDocRow.requiredPrimaryActions,
          'requiredAlternateActions':
              adminProductDocRow.requiredAlternateActions,
          'expectedAssertions': [
            adminProductDocRow.expectedDecision,
            adminProductDocRow.resultAndReceiverState,
          ],
          'screenshotNames': [
            'B19_role_aware_admin_start',
            'B19_role_aware_admin_action',
            'B19_role_aware_admin_alternate_action',
            'B19_role_aware_admin_alternate_result',
            'B19_role_aware_admin_primary_action',
            'B19_role_aware_admin_complete',
          ],
          'b25ActionProofStatus': 'pass',
          'visiblePrimaryActions': ['publish/update'],
          'visibleAlternateActions': ['save draft'],
          'productFindings': <String>[],
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B19',
          workflowId: 'wf_community-persona-aware-ux',
          communityName: mosqueTarget.communityName,
        );
      }

      if (_includePhase('B20') &&
          selectedExtensionIds.contains(mosqueTarget.extensionId)) {
        final adminProductDocRow = mosqueB25Row(
          'wf_multi-persona-workflow-evidence',
          'admin',
        );
        final memberProductDocRow = mosqueB25Row(
          'wf_multi-persona-workflow-evidence',
          'member',
        );
        emitProgress(
          'workflow-start',
          phase: 'B20',
          workflowId: 'wf_multi-persona-workflow-evidence',
          communityName: mosqueTarget.communityName,
        );
        await ensureTargetOpen(mosqueTarget);
        final publishedAnnouncementId =
            await _createAndPublishShippedAnnouncement(
              tester: tester,
              target: mosqueTarget,
              package: mosquePackage,
              selector: announcement,
              adminRoleId: mosqueAdminRoleId,
              capture: capture,
              screenshotPrefix: 'B20_announcement',
              announcementTitle: 'Walkthrough community announcement',
            );
        recordEvidenceEntry({
          'phase': 'B20',
          'appId': mosqueTarget.extensionId,
          'communityId': mosqueTarget.communityId,
          'communityName': mosqueTarget.communityName,
          'workflowId': adminProductDocRow.workflowId,
          'role': adminProductDocRow.role,
          'productDocPath': adminProductDocRow.productDocPath,
          'requiredPrimaryActions': adminProductDocRow.requiredPrimaryActions,
          'requiredAlternateActions':
              adminProductDocRow.requiredAlternateActions,
          'expectedAssertions': [
            adminProductDocRow.expectedDecision,
            adminProductDocRow.resultAndReceiverState,
          ],
          'screenshotNames': [
            'B20_announcement_admin_start',
            'B20_announcement_admin_action',
            'B20_announcement_admin_alternate_action',
            'B20_announcement_admin_alternate_result',
            'B20_announcement_admin_primary_action',
            'B20_announcement_admin_complete',
          ],
          'b25ActionProofStatus': 'pass',
          'visiblePrimaryActions': ['publish announcement'],
          'visibleAlternateActions': ['save draft'],
          'productFindings': <String>[],
          'status': 'pass',
        });
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
          publishedAnnouncementId,
          markRead.id,
        );
        await waitForEngineNativeWidget(
          tester,
          announcementReceiveButton,
          description: 'shipped member announcement receipt action',
        );
        await tester.ensureVisible(announcementReceiveButton.first);
        await capture('B20_announcement_member_action');
        await tester.tap(announcementReceiveButton.first, warnIfMissed: false);
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
              'The shipped member receipt action did not mark the published '
              'announcement as read.',
        );
        await capture('B20_announcement_member_received');
        await capture('B20_announcement_member_alternate_unavailable');
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
        recordEvidenceEntry({
          'phase': 'B20',
          'appId': mosqueTarget.extensionId,
          'communityId': mosqueTarget.communityId,
          'communityName': mosqueTarget.communityName,
          'workflowId': memberProductDocRow.workflowId,
          'role': memberProductDocRow.role,
          'productDocPath': memberProductDocRow.productDocPath,
          'requiredPrimaryActions': memberProductDocRow.requiredPrimaryActions,
          'requiredAlternateActions':
              memberProductDocRow.requiredAlternateActions,
          'expectedAssertions': [
            memberProductDocRow.expectedDecision,
            memberProductDocRow.resultAndReceiverState,
          ],
          'screenshotNames': [
            'B20_announcement_member_ready',
            'B20_announcement_member_action',
            'B20_announcement_member_received',
            'B20_announcement_member_alternate_unavailable',
            'B20_member_calendar_tab_pinned_event',
            'B20_member_messages_tab',
            'B20_admin_custom_tab_pinned_surface',
          ],
          'b25ActionProofStatus': 'fail',
          'visiblePrimaryActions': ['receive announcement', 'mark read'],
          'visibleAlternateActions': <String>[],
          'productFindings': [
            '${memberProductDocRow.communityName} / '
                '${memberProductDocRow.workflowId} / '
                '${memberProductDocRow.role}: the shipped announcement '
                'offers `Mark read` to a member, but no member-visible '
                '`Archive`, `Request follow-up`, or `Keep unread` action.',
          ],
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B20',
          workflowId: 'wf_multi-persona-workflow-evidence',
          communityName: mosqueTarget.communityName,
        );
      }

      final includeGardenCapability = selectedExtensionIds.contains(
        gardenTarget.extensionId,
      );
      final includeHoaCapability = selectedExtensionIds.contains(
        hoaTarget.extensionId,
      );
      final includeSoccerCapability = selectedExtensionIds.contains(
        soccerTarget.extensionId,
      );
      if (_includePhase('B20') &&
          (includeGardenCapability ||
              includeHoaCapability ||
              includeSoccerCapability)) {
        emitProgress(
          'workflow-start',
          phase: 'B20',
          workflowId: 'wf_app-shell-capability-evidence',
          communityName: 'Loom Communities',
        );
        final capabilityScreenshots = <String>[];

        await returnToCommunityList();
        await capture('B20_app_shell_main_community_list_states');
        capabilityScreenshots.add('B20_app_shell_main_community_list_states');

        if (includeGardenCapability) {
          await ensureTargetOpen(gardenTarget);
          await selectActorIdentity(tester, gardenMemberRoleId);
          await _selectPackageTab(
            tester: tester,
            target: gardenTarget,
            package: gardenPackage,
            roleId: gardenMemberRoleId,
            tabId: 'home',
          );
          final gardenRsvpInstance = _engineInstanceFinder(
            gardenRsvp.instance.instanceId,
          );
          await waitForEngineNativeWidget(
            tester,
            gardenRsvpInstance,
            description:
                'shipped Garden RSVP summary on the package Home binding',
          );
          await tester.ensureVisible(gardenRsvpInstance.first);
          await capture('B20_app_shell_garden_home_medium_minimized_stack');
          capabilityScreenshots.add(
            'B20_app_shell_garden_home_medium_minimized_stack',
          );
          await _expandShippedWorkflowSurface(
            tester: tester,
            selector: gardenRsvp,
          );
          await capture('B20_app_shell_garden_home_expanded_surface');
          capabilityScreenshots.add(
            'B20_app_shell_garden_home_expanded_surface',
          );
        }

        if (includeHoaCapability) {
          await ensureTargetOpen(hoaTarget);
          await selectActorIdentity(tester, 'hoa-homeowner');
          await _selectCommunityTab(tester, 'documents');
          await capture('B20_app_shell_hoa_documents_pinning_policy');
          capabilityScreenshots.add(
            'B20_app_shell_hoa_documents_pinning_policy',
          );
        }

        if (includeSoccerCapability) {
          await ensureTargetOpen(soccerTarget);
          await _showShippedWorkflowInstance(
            tester: tester,
            target: soccerTarget,
            package: soccerPackage,
            selector: soccerRoster,
            roleId: soccerCoachRoleId,
          );
          await capture('B20_app_shell_soccer_roster_renderer_medium');
          capabilityScreenshots.add(
            'B20_app_shell_soccer_roster_renderer_medium',
          );
          await _expandShippedWorkflowSurface(
            tester: tester,
            selector: soccerRoster,
          );
          await capture('B20_app_shell_soccer_roster_renderer_expanded');
          capabilityScreenshots.add(
            'B20_app_shell_soccer_roster_renderer_expanded',
          );
        }

        recordEvidenceEntry({
          'phase': 'B20',
          'appId': 'app-shell-capability-evidence',
          'workflowId': 'wf_app-shell-capability-evidence',
          'communityId': 'loom-communities',
          'communityName': 'Loom Communities',
          'expectedAssertions': [
            'main community list shows themed launch cards with medium and minimized states',
            if (includeGardenCapability)
              'Garden Club Home tab proves medium/minimized workflow surfaces and tap-to-expanded behavior',
            if (includeHoaCapability)
              'HOA Documents tab proves an explicit pin-first-critical-surface policy with a pinned document/status surface',
            if (includeSoccerCapability)
              'Riverside Youth Soccer roster proves renderer selection by card-surface family in medium and expanded states',
          ],
          'screenshotNames': capabilityScreenshots,
          'status': 'pass',
        });
        emitProgress(
          'workflow-complete',
          phase: 'B20',
          workflowId: 'wf_app-shell-capability-evidence',
          communityName: 'Loom Communities',
        );
      }

      if (find
          .byKey(ValueKey('local-extension-${mosqueTarget.extensionId}'))
          .evaluate()
          .isNotEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      screenshotCapture.finish();
      binding.reportData!['workflowEvidenceSchemaVersion'] = 2;
      binding.reportData!['workflowEvidence'] = entries;
      binding.reportData!['screenshotVisibleTextByName'] =
          screenshotVisibleTextByName;
      binding.reportData!['walkthroughStatus'] = 'pass';
      _emitCaptureProgress({
        'status': 'run-complete',
        'completedWorkflows': completedWorkflowEvidenceEntries,
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
    if (selectedExtensionIds.intersection(const {
      'ext_garden_club',
      'ext_cedar_commons_hoa',
      'ext_youth_soccer',
    }).isNotEmpty) {
      counts.update('B20', (count) => count + 1);
    }
  }
  return counts;
}

void _assertB25AssetCoversTargets({
  required B25ProductDocInteractionCatalog catalog,
  required List<LoomEvidenceTarget> evidenceTargets,
}) {
  expect(catalog.models, hasLength(79));
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

Future<_B25WalkthroughResult> _runB25ShippedWorkflowWalkthrough({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required B25ProductDocInteractionModel b25Model,
  required Future<void> Function(String name) capture,
}) async {
  if (selector.accountId case final accountId?) {
    final displayName = 'Shipped $accountId';
    await seedEvidenceAccounts(tester, target, [
      LoomAccount(
        accountId: accountId,
        displayName: displayName,
        roleId: selector.roleId,
      ),
    ]);
    await signInEvidenceAccount(tester, displayName);
  } else {
    await selectActorIdentity(tester, selector.roleId);
  }
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
  await _selectCommunityTab(tester, selector.binding.tabId);

  final instance = _engineInstanceFinder(selector.instance.instanceId);
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

  final visibleAction = await _waitForShippedWorkflowAction(
    tester: tester,
    selector: selector,
    lastCompletedStep: lastCompletedStep,
    attemptedStep: attemptedStep,
    diagnosticFrameName: stallDiagnosticName,
    captureDiagnostic: capture,
  );
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

  if (!b25Model.requiredPrimaryActions.any(
    (term) =>
        _transitionMatchesB25Term(visibleAction.candidate.transition, term),
  )) {
    final alternateUnavailable = _b25ScreenshotName(
      target,
      b25Model,
      'alternate_action_unavailable',
    );
    final complete = _b25ScreenshotName(
      target,
      b25Model,
      'result_receiver_unavailable',
    );
    await capture(alternateUnavailable);
    await capture(complete);
    return _b25WalkthroughResult(
      model: b25Model,
      selector: selector,
      screenshotNames: [start, action, alternateUnavailable, complete],
    );
  }

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
  final transitionCategory = identical(selector.actionMachine, selector.machine)
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
  if (identical(selector.actionMachine, selector.machine) &&
      transitionCategory == _ShippedTransitionCategory.stateChanging) {
    expect(
      visibleAction.finder,
      findsNothing,
      reason:
          'Shipped workflow ${selector.machine.workflowType} exposed '
          '${transition.id} for ${selector.roleId}, but the '
          'action did not leave its package-declared source state '
          '${selector.actionSourceState}.',
    );
  }
  final targetState = transition.to ?? selector.actionSourceState;
  final targetStateLabel = selector.actionMachine.states[targetState]?.label;
  if (identical(selector.actionMachine, selector.machine) &&
      transitionCategory.requiresSourceInstanceDataChange &&
      sourceInstance != null) {
    await _expectShippedInstanceDataChanged(
      tester: tester,
      target: target,
      package: package,
      selector: selector,
      sourceInstance: sourceInstance,
    );
    await capture(primaryResult);
    return _finishB25WalkthroughAfterPrimary(
      tester: tester,
      target: target,
      package: package,
      model: b25Model,
      selector: selector,
      executedPrimary: visibleAction.candidate.transition,
      screenshotNames: [start, action, primaryResult],
      capture: capture,
    );
  }
  if (identical(selector.actionMachine, selector.machine) &&
      transitionCategory == _ShippedTransitionCategory.stateChanging) {
    await _expectShippedInstanceState(
      tester: tester,
      target: target,
      package: package,
      selector: selector,
      targetState: targetState,
    );
    await capture(primaryResult);
    return _finishB25WalkthroughAfterPrimary(
      tester: tester,
      target: target,
      package: package,
      model: b25Model,
      selector: selector,
      executedPrimary: visibleAction.candidate.transition,
      screenshotNames: [start, action, primaryResult],
      capture: capture,
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
  await capture(primaryResult);
  return _finishB25WalkthroughAfterPrimary(
    tester: tester,
    target: target,
    package: package,
    model: b25Model,
    selector: selector,
    executedPrimary: visibleAction.candidate.transition,
    screenshotNames: [start, action, primaryResult],
    capture: capture,
  );
}

Future<void> _pumpB25Frames(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_B25WalkthroughResult> _finishB25WalkthroughAfterPrimary({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required B25ProductDocInteractionModel model,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowTransition executedPrimary,
  required List<String> screenshotNames,
  required Future<void> Function(String name) capture,
}) async {
  final alternate = await _waitForB25AlternateAction(
    tester: tester,
    selector: selector,
    terms: model.requiredAlternateActions,
    excludedTransitionId: executedPrimary.id,
  );
  if (alternate == null) {
    final unavailable = _b25ScreenshotName(
      target,
      model,
      'alternate_action_unavailable',
    );
    final result = _b25ScreenshotName(target, model, 'result_receiver');
    await capture(unavailable);
    await capture(result);
    return _b25WalkthroughResult(
      model: model,
      selector: selector,
      executedPrimary: executedPrimary,
      screenshotNames: [...screenshotNames, unavailable, result],
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
      await _expectShippedInstanceState(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        targetState: targetState,
      );
    } else if (category.requiresSourceInstanceDataChange) {
      await _expectShippedInstanceDataChanged(
        tester: tester,
        target: target,
        package: package,
        selector: selector,
        sourceInstance: sourceInstance,
      );
    }
  }

  final result = _b25ScreenshotName(target, model, 'result_receiver');
  await capture(result);
  return _b25WalkthroughResult(
    model: model,
    selector: selector,
    executedPrimary: executedPrimary,
    executedAlternate: alternate.transition,
    screenshotNames: [...screenshotNames, alternateAction, result],
  );
}

Future<({LoomWorkflowTransition transition, Finder finder})?>
_waitForB25AlternateAction({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required List<String> terms,
  required String excludedTransitionId,
}) async {
  if (terms.isEmpty) return null;
  final candidates = selector.actionMachine.transitions
      .where(
        (transition) =>
            transition.id != excludedTransitionId &&
            terms.any((term) => _transitionMatchesB25Term(transition, term)),
      )
      .toList(growable: false);
  for (var attempt = 0; attempt < 80; attempt += 1) {
    for (final transition in candidates) {
      final finder = _engineActionFinder(
        selector.instance.instanceId,
        transition.id,
      );
      if (finder.evaluate().isNotEmpty) {
        return (transition: transition, finder: finder);
      }
    }
    if (attempt == 20) {
      final instance = _engineInstanceFinder(selector.instance.instanceId);
      if (instance.evaluate().isNotEmpty) {
        await tester.ensureVisible(instance.first);
        await tester.tap(instance.first, warnIfMissed: false);
        await _pumpB25Frames(tester);
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
    required this.productFindings,
  });

  final List<String> screenshotNames;
  final String actionProofStatus;
  final List<String> visiblePrimaryActions;
  final List<String> visibleAlternateActions;
  final List<String> productFindings;
}

_B25WalkthroughResult _b25WalkthroughResult({
  required B25ProductDocInteractionModel model,
  required _ShippedWorkflowSelector selector,
  LoomWorkflowTransition? executedPrimary,
  LoomWorkflowTransition? executedAlternate,
  required List<String> screenshotNames,
}) {
  final visiblePrimary = _matchingB25TransitionTerms(<LoomWorkflowTransition>[
    if (executedPrimary != null) executedPrimary,
  ], model.requiredPrimaryActions);
  final visibleAlternate = _matchingB25TransitionTerms(<LoomWorkflowTransition>[
    if (executedAlternate != null) executedAlternate,
  ], model.requiredAlternateActions);
  final findings = <String>[
    if (visiblePrimary.isEmpty)
      '${model.communityName} / ${model.workflowId} / ${model.role}: '
          '${executedPrimary == null ? 'no documented primary package action was exercised' : 'the exercised package action `${executedPrimary.label}` does not match any documented primary action'} '
          '${model.requiredPrimaryActions}.',
    if (visibleAlternate.isEmpty)
      '${model.communityName} / ${model.workflowId} / ${model.role}: '
          'the walkthrough exercised no documented '
          'alternate/change/reject action ${model.requiredAlternateActions.isEmpty ? 'because the product doc declares `${model.alternateRequirementNote}`' : model.requiredAlternateActions}.',
  ];
  return _B25WalkthroughResult(
    screenshotNames: screenshotNames,
    actionProofStatus: findings.isEmpty ? 'pass' : 'fail',
    visiblePrimaryActions: visiblePrimary,
    visibleAlternateActions: visibleAlternate,
    productFindings: findings,
  );
}

Future<_B25WalkthroughResult> _captureMissingB25PackageWorkflow({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required B25ProductDocInteractionModel b25Model,
  required Future<void> Function(String name) capture,
}) async {
  final roleId = _roleIdsForB25Role(package, b25Model.role).firstOrNull;
  if (roleId != null) {
    await selectActorIdentity(tester, roleId);
    final preferredTab = _tabForMissingB25Workflow(b25Model.workflowId);
    final tabs = appShellTabsFor(
      experience: package.experience,
      roleId: roleId,
      appShellConfiguration: package.appShellConfiguration,
    );
    if (tabs.any((tab) => tab.tabId == preferredTab)) {
      await _selectCommunityTab(tester, preferredTab);
    }
  }

  final screenshotNames = <String>[
    _b25ScreenshotName(target, b25Model, 'start'),
    _b25ScreenshotName(target, b25Model, 'primary_unavailable'),
    _b25ScreenshotName(target, b25Model, 'alternate_unavailable'),
    _b25ScreenshotName(target, b25Model, 'result_unavailable'),
  ];
  for (final screenshotName in screenshotNames) {
    await capture(screenshotName);
    await tester.pump(const Duration(milliseconds: 20));
  }
  final offered = package.experience.workflowDefinitions!.keys.toList()..sort();
  return _B25WalkthroughResult(
    screenshotNames: screenshotNames,
    actionProofStatus: 'fail',
    visiblePrimaryActions: const <String>[],
    visibleAlternateActions: const <String>[],
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

List<String> _matchingB25TransitionTerms(
  Iterable<LoomWorkflowTransition> transitions,
  List<String> terms,
) {
  return terms
      .where(
        (term) => transitions.any(
          (transition) => _transitionMatchesB25Term(transition, term),
        ),
      )
      .toSet()
      .toList()
    ..sort();
}

bool _transitionMatchesB25Term(LoomWorkflowTransition transition, String term) {
  final expected = _normalizeB25ActionText(term);
  return <String>{
        transition.label,
        transition.id,
        if (transition.action case final action?) action,
      }
      .map(_normalizeB25ActionText)
      .any(
        (candidate) =>
            candidate.contains(expected) || expected.contains(candidate),
      );
}

String _normalizeB25ActionText(String value) => value
    .toLowerCase()
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Future<WorkflowInstance?> _readShippedInstance({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
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
      if (instance.instanceId == selector.instance.instanceId) return instance;
    }
  }
  return null;
}

Future<void> _expectShippedInstanceDataChanged({
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
      return;
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

Future<void> _expectShippedInstanceState({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required String targetState,
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

  WorkflowInstance? persisted;
  for (var attempt = 0; attempt < 80 && persisted == null; attempt += 1) {
    for (final tabId in tabs) {
      final page = (await tester.runAsync(
        () => engine.queryInstances(tabId: tabId, fanId: fanId, limit: 100),
      ))!;
      for (final instance in page.items) {
        if (instance.instanceId == selector.instance.instanceId) {
          persisted = instance;
          break;
        }
      }
      if (persisted != null) break;
    }
    if (persisted == null) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  expect(
    persisted?.currentState,
    targetState,
    reason:
        'Shipped workflow ${selector.machine.workflowType} ran a visible '
        'package action for ${selector.instance.instanceId}, but the shared '
        'engine did not persist package target state $targetState.',
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
    fail(
      'Walkthrough workflow $workflowType is absent from the shipped '
      '${target.extensionId} experience.workflowDefinitions.',
    );
  }
  final instances = package.experience.workflowInstances!
      .where((instance) => instance.workflowType == workflowType)
      .toList(growable: false);
  if (instances.isEmpty) {
    fail(
      'Walkthrough workflow $workflowType has no selector source in the '
      'shipped ${target.extensionId} experience.workflowInstances.',
    );
  }
  final packageRoleIds = {
    for (final actorIdentity in package.experience.actorIdentities!)
      actorIdentity.roleId,
  };
  final preferredRoleIds = b25Model == null
      ? packageRoleIds
      : _roleIdsForB25Role(package, b25Model.role).toSet();
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
        fail(
          'Shipped workflow $workflowType binding on ${binding.tabId} names '
          'missing response workflow $responseWorkflowType.',
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
        final bindingAccountId = _bindingAudienceAccountId(
          machine: machine,
          instance: instance,
          binding: binding,
          roleId: roleId,
        );
        if (binding.role == 'actor' && bindingAccountId == null) {
          continue;
        }
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
            !accountTransitions.any(
              (candidate) => b25Model.requiredPrimaryActions.any(
                (term) => _transitionMatchesB25Term(candidate.transition, term),
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
  fail(
    'Walkthrough workflow $workflowType could not derive an actionable '
    'instance, actorIdentity, and tab from the shipped ${target.extensionId} '
    'experience and appShell${b25Model == null ? '.' : ' for B25 product-doc role `${b25Model.role}` from `${b25Model.productDocPath}`.'}',
  );
}

List<String> _roleIdsForB25Role(ShippedEvidencePackage package, String role) {
  final normalizedRole = _normalizeB25ActionText(role);
  bool identityMatches(LoomActorIdentity identity) {
    final identityText = _normalizeB25ActionText(
      '${identity.roleId} ${identity.label} ${identity.roleLabel}',
    );
    if (identityText.contains(normalizedRole)) return true;
    return switch (normalizedRole) {
      'donor' => identityText.contains('member'),
      'owner' =>
        identityText.contains('owner') ||
            identityText.contains('admin') ||
            identityText.contains('board') ||
            identityText.contains('coordinator'),
      'admin' =>
        identityText.contains('admin') || identityText.contains('owner'),
      'organizer' =>
        identityText.contains('organizer') ||
            identityText.contains('coordinator') ||
            identityText.contains('admin') ||
            identityText.contains('owner'),
      _ => false,
    };
  }

  final roleIds = package.experience.actorIdentities!
      .where(identityMatches)
      .map((identity) => identity.roleId)
      .toList(growable: false);
  if (roleIds.isEmpty) {
    fail(
      'Shipped package ${package.experience.extensionId} has no actor identity '
      'that can represent B25 product-doc role `$role`. Available identities: '
      '${package.experience.actorIdentities!.map((identity) => '${identity.roleId} (${identity.label})').join(', ')}.',
    );
  }
  return roleIds;
}

int _compareB25TransitionCandidates(
  _ShippedTransitionCandidate left,
  _ShippedTransitionCandidate right,
  B25ProductDocInteractionModel model,
) {
  int semanticPriority(LoomWorkflowTransition transition) {
    if (model.requiredPrimaryActions.any(
      (term) => _transitionMatchesB25Term(transition, term),
    )) {
      return 0;
    }
    if (model.requiredAlternateActions.any(
      (term) => _transitionMatchesB25Term(transition, term),
    )) {
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

String? _bindingAudienceAccountId({
  required LoomWorkflowStateMachine machine,
  required LoomWorkflowSeedInstance instance,
  required RenderBinding binding,
  required String roleId,
}) {
  if (binding.role != 'actor') return null;
  final fieldKeys = <String>{
    if (machine.visibility.readGuard?.actorEqualsField case final actorField?)
      actorField.key,
    for (final transition in machine.transitions)
      if (transition.guard.actorEqualsField case final actorField?)
        actorField.key,
  };
  for (final fieldKey in fieldKeys) {
    final fanId = instance.instanceData[fieldKey];
    if (fanId is String && _fanIdMatchesRole(fanId, roleId)) return fanId;
  }
  final creator = instance.createdByFanId;
  return creator != null && _fanIdMatchesRole(creator, roleId) ? creator : null;
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

Future<({_ShippedTransitionCandidate candidate, Finder finder})>
_waitForShippedWorkflowAction({
  required WidgetTester tester,
  required _ShippedWorkflowSelector selector,
  required String lastCompletedStep,
  required String attemptedStep,
  required String diagnosticFrameName,
  required Future<void> Function(String name) captureDiagnostic,
}) async {
  final budget = WalkthroughWaitBudget();
  final actionDescriptions = selector.transitions
      .map(
        (candidate) =>
            '${candidate.transition.id} (${candidate.transition.label})',
      )
      .join(', ');
  var attemptedExpansion = false;
  while (!budget.expired) {
    for (final candidate in selector.transitions) {
      final finder = _engineActionFinder(
        selector.instance.instanceId,
        candidate.transition.id,
      );
      if (finder.evaluate().isNotEmpty) {
        return (candidate: candidate, finder: finder);
      }
    }
    if (!attemptedExpansion && budget.elapsed >= const Duration(seconds: 1)) {
      attemptedExpansion = true;
      final instance = _engineInstanceFinder(selector.instance.instanceId);
      if (instance.evaluate().isNotEmpty) {
        await tester.ensureVisible(instance.first);
        await tester.tap(instance.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await captureDiagnostic(diagnosticFrameName);
  throw WalkthroughStallFailure(
    buildWalkthroughStallMessage(
      lastCompletedStep: lastCompletedStep,
      attemptedStep: attemptedStep,
      waitingFor:
          'a tappable shipped workflow action on the '
          '${selector.binding.tabId} tab for ${selector.roleId}. '
          'Polled action widgets: [$actionDescriptions].',
      budget: budget,
      diagnosticFrameName: diagnosticFrameName,
    ),
  );
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

Future<String> _createAndPublishShippedAnnouncement({
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
  if (createFab.evaluate().isEmpty) {
    final speedDial = find.byKey(const ValueKey('creatable-fab-speed-dial'));
    await waitForEngineNativeWidget(
      tester,
      speedDial,
      description: 'shipped $workflowType create speed dial for $adminRoleId',
    );
    await tester.tap(speedDial, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
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
  await tester.tap(submit, warnIfMissed: false);

  final createdTitle = find.text(fieldValues['title']!);
  await waitForEngineNativeWidget(
    tester,
    createdTitle,
    description: 'newly created shipped $workflowType instance',
  );
  final createdCard = find.ancestor(
    of: createdTitle,
    matching: find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('generic-instance-card-');
    }),
  );
  expect(
    createdCard,
    findsOneWidget,
    reason:
        'The shipped $workflowType creation completed, but the created '
        'instance did not expose its engine-native identity key.',
  );
  final cardKey = tester.widget(createdCard).key! as ValueKey<String>;
  final instanceId = cardKey.value.substring('generic-instance-card-'.length);

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
  expect(
    publishAction,
    findsNothing,
    reason: 'The shipped publish action did not leave the previewed state.',
  );
  await _selectPackageTab(
    tester: tester,
    target: target,
    package: package,
    roleId: adminRoleId,
    tabId: 'home',
  );
  await waitForEngineNativeWidget(
    tester,
    createdTitle,
    description: 'published announcement on shipped Home surface',
  );
  await capture('${screenshotPrefix}_admin_complete');
  return instanceId;
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
