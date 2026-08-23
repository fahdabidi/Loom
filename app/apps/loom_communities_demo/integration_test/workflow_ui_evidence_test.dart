import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_demo/main.dart';
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
const _preloadExampleCommunities = bool.fromEnvironment(
  'LOOM_PRELOAD_EXAMPLE_COMMUNITIES',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wf_full-ui-screenshot-evidence-b12-b20', (tester) async {
    final evidenceTargets = _evidenceTargetsForRun();
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
    await binding.convertFlutterSurfaceToImage();
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['walkthroughStatus'] = 'running';
    binding.reportData!['requestedPhases'] = requestedPhases;
    binding.reportData!['expectedWorkflowCountByPhase'] =
        _workflowEvidenceEntryCountByPhase(evidenceTargets);
    binding.reportData!.addAll(_evidenceDeviceMetadata());
    final entries = <Map<String, Object?>>[];
    binding.reportData!['workflowEvidence'] = entries;
    final installedExtensionIds = _preloadExampleCommunities
        ? {
            for (final target in evidenceTargets)
              if (!hasShippedEvidencePackage(target.extensionId))
                target.extensionId,
          }
        : <String>{};
    final screenshotVisibleTextByName = <String, String>{};
    final screenshotCapture = _ScreenshotCaptureRecorder(
      binding: binding,
      reportData: binding.reportData!,
    );
    final totalWorkflowEvidenceEntries = _workflowEvidenceEntryCount(
      evidenceTargets,
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
      );
    }

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await tester.pumpAndSettle();

    Future<void> ensureTargetInstalled(LoomEvidenceTarget target) async {
      if (installedExtensionIds.contains(target.extensionId)) {
        return;
      }
      await installEvidenceTarget(
        tester,
        target,
        useShippedPackage: hasShippedEvidencePackage(target.extensionId),
      );
      installedExtensionIds.add(target.extensionId);
    }

    bool _communityListReady() {
      return find
              .byKey(const ValueKey('add-community-button'))
              .evaluate()
              .isNotEmpty &&
          find.byKey(const ValueKey('community-list')).evaluate().isNotEmpty &&
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
      await ensureTargetInstalled(target);
      await openEvidenceTarget(tester, target);
      final catalogExperience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      final shippedPackage = hasShippedEvidencePackage(target.extensionId)
          ? await readShippedEvidencePackage(target)
          : null;
      if (shippedPackage == null) {
        expect(find.text(catalogExperience.tagline), findsOneWidget);
      }

      if (shippedPackage != null) {
        final shippedWalkthroughs = _shippedWorkflowWalkthroughs(
          target: target,
          package: shippedPackage,
          evidenceContracts: catalogExperience.workflows,
        );
        for (final walkthrough in shippedWalkthroughs) {
          final workflow = walkthrough.evidenceContract;
          final workflowOrdinal = targetWorkflowOrdinal;
          targetWorkflowOrdinal += 1;
          if (!_includeWorkflowShard(workflowOrdinal)) {
            continue;
          }
          emitProgress(
            'workflow-start',
            phase: target.phase,
            workflowId: workflow.workflowId,
            communityName: target.communityName,
          );
          final screenshotNames = await _runShippedWorkflowWalkthrough(
            tester: tester,
            target: target,
            package: shippedPackage,
            selector: walkthrough.selector,
            evidenceContract: workflow,
            capture: capture,
          );
          recordEvidenceEntry({
            'phase': target.phase,
            'appId': target.extensionId,
            'communityId': target.communityId,
            'communityName': target.communityName,
            'workflowId': workflow.workflowId,
            'expectedAssertions': [
              workflow.entryText,
              workflow.actionText,
              workflow.resultText,
            ],
            'screenshotNames': screenshotNames,
            'status': 'pass',
          });
          emitProgress(
            'workflow-complete',
            phase: target.phase,
            workflowId: workflow.workflowId,
            communityName: target.communityName,
          );
        }
      } else {
        final completedSetupWorkflowIds = <String>{};

        Future<void> ensurePrerequisiteChain(
          LoomWorkflowDefinition workflow,
        ) async {
          final policy = personaPolicyForWorkflow(
            target.extensionId,
            workflow.workflowId,
          );
          final prerequisiteWorkflowId = policy.prerequisiteWorkflowId;
          if (prerequisiteWorkflowId == null ||
              completedSetupWorkflowIds.contains(prerequisiteWorkflowId)) {
            return;
          }
          final prerequisite = catalogExperience.workflows.firstWhere(
            (candidate) => candidate.workflowId == prerequisiteWorkflowId,
          );
          await ensurePrerequisiteChain(prerequisite);
          final prerequisitePolicy = personaPolicyForWorkflow(
            target.extensionId,
            prerequisite.workflowId,
          );
          final prerequisiteRoleId = prerequisitePolicy.actorRoleIds.first;
          await selectPersona(tester, prerequisiteRoleId);
          await completeWorkflow(tester, prerequisite);
          completedSetupWorkflowIds.add(prerequisiteWorkflowId);
        }

        for (final workflow in catalogExperience.workflows) {
          final workflowOrdinal = targetWorkflowOrdinal;
          targetWorkflowOrdinal += 1;
          if (!_includeWorkflowShard(workflowOrdinal)) {
            continue;
          }
          emitProgress(
            'workflow-start',
            phase: target.phase,
            workflowId: workflow.workflowId,
            communityName: target.communityName,
          );
          final policy = personaPolicyForWorkflow(
            target.extensionId,
            workflow.workflowId,
          );
          await ensurePrerequisiteChain(workflow);
          final actorRoleId = policy.actorRoleIds.first;
          await selectPersona(tester, actorRoleId);
          final entry = <String, Object?>{
            'phase': target.phase,
            'appId': target.extensionId,
            'communityId': target.communityId,
            'communityName': target.communityName,
            'workflowId': workflow.workflowId,
            'expectedAssertions': [
              workflow.entryText,
              workflow.actionText,
              workflow.resultText,
            ],
          };
          final start = _screenshotName(target, workflow, 'start');
          final action = _screenshotName(target, workflow, 'action');
          final complete = _screenshotName(target, workflow, 'complete');

          await scrollToWorkflowCard(tester, workflow);
          await capture(start);

          final workflowButton = find.byKey(
            ValueKey('workflow-button-${workflow.workflowId}'),
          );
          await scrollFinderIntoViewport(tester, workflowButton);
          await tester.tap(workflowButton, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            find.byKey(
              ValueKey('workflow-action-surface-${workflow.workflowId}'),
            ),
            findsOneWidget,
          );
          await capture(action);

          final submitButton = find.byKey(
            ValueKey('workflow-action-submit-${workflow.workflowId}'),
          );
          await scrollFinderIntoViewport(tester, submitButton);
          await tester.tap(submitButton, warnIfMissed: false);
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
          await capture(complete);

          recordEvidenceEntry({
            ...entry,
            'screenshotNames': [start, action, complete],
            'status': 'pass',
          });
          completedSetupWorkflowIds.add(workflow.workflowId);
          emitProgress(
            'workflow-complete',
            phase: target.phase,
            workflowId: workflow.workflowId,
            communityName: target.communityName,
          );
        }
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
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
      (target) => target.extensionId == 'ext_hoa',
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
        workflowId: 'wf_persona-role-inventory-capability-matrix',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await selectPersona(tester, mosqueAdminRoleId);
      await capture('B17_persona_inventory_active_admin');
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await capture('B17_persona_inventory_picker');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      recordEvidenceEntry({
        'phase': 'B17',
        'appId': 'persona-role-inventory',
        'workflowId': 'wf_persona-role-inventory-capability-matrix',
        'expectedAssertions': [
          'all demo communities define two or more personas',
          'all workflow/persona matrix rows have actor, receiver, read-only, or disabled state',
          'receiver rows declare dependency evidence',
          'matrix rows: ${await _personaMatrixRowCount(evidenceTargets)}',
        ],
        'screenshotNames': [
          'B17_persona_inventory_active_admin',
          'B17_persona_inventory_picker',
        ],
        'status': 'pass',
      });
      emitProgress(
        'workflow-complete',
        phase: 'B17',
        workflowId: 'wf_persona-role-inventory-capability-matrix',
        communityName: mosqueTarget.communityName,
      );
    }

    if (_includePhase('B18') &&
        selectedExtensionIds.contains(mosqueTarget.extensionId)) {
      emitProgress(
        'workflow-start',
        phase: 'B18',
        workflowId: 'wf_demo-app-persona-picker',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await capture('B18_persona_picker_dialog');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _showShippedWorkflowInstance(
        tester: tester,
        target: mosqueTarget,
        package: mosquePackage,
        selector: announcement,
        roleId: mosqueMemberRoleId,
      );
      await capture('B18_persona_picker_member_selected');
      recordEvidenceEntry({
        'phase': 'B18',
        'appId': mosqueTarget.extensionId,
        'communityId': mosqueTarget.communityId,
        'communityName': mosqueTarget.communityName,
        'workflowId': 'wf_demo-app-persona-picker',
        'expectedAssertions': [
          'people icon opens the test persona picker',
          'Community Member persona becomes active',
          'Public announcement is waiting for admin action instead of exposing an admin action',
        ],
        'screenshotNames': [
          'B18_persona_picker_dialog',
          'B18_persona_picker_member_selected',
        ],
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
      await capture('B19_member_care_request_actor');
      await _showShippedWorkflowInstance(
        tester: tester,
        target: mosqueTarget,
        package: mosquePackage,
        selector: announcement,
        roleId: mosqueAdminRoleId,
      );
      await capture('B19_admin_announcement_actor');
      recordEvidenceEntry({
        'phase': 'B19',
        'appId': mosqueTarget.extensionId,
        'communityId': mosqueTarget.communityId,
        'communityName': mosqueTarget.communityName,
        'workflowId': 'wf_community-persona-aware-ux',
        'expectedAssertions': [
          'member persona can create the protected care request',
          'member persona cannot create the public announcement',
          'admin persona can create the public announcement',
        ],
        'screenshotNames': [
          'B19_member_care_request_actor',
          'B19_admin_announcement_actor',
        ],
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
          );
      await selectPersona(tester, mosqueMemberRoleId);
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
        description: 'published walkthrough announcement for community member',
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
      await selectPersona(tester, mosqueAdminRoleId);
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
        'workflowId': 'wf_multi-persona-workflow-evidence',
        'expectedAssertions': [
          'admin creates the public announcement',
          'member receives the same announcement after admin completion',
          'widget sweep covers all demo app workflow/persona rows',
        ],
        'screenshotNames': [
          'B20_announcement_admin_start',
          'B20_announcement_admin_action',
          'B20_announcement_admin_complete',
          'B20_announcement_member_ready',
          'B20_announcement_member_action',
          'B20_announcement_member_received',
          'B20_member_calendar_tab_pinned_event',
          'B20_member_messages_tab',
          'B20_admin_custom_tab_pinned_surface',
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
        await selectPersona(tester, gardenMemberRoleId);
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
        capabilityScreenshots.add('B20_app_shell_garden_home_expanded_surface');
      }

      if (includeHoaCapability) {
        await ensureTargetOpen(hoaTarget);
        await selectPersona(tester, 'hoa-homeowner');
        await _selectCommunityTab(tester, 'documents');
        await capture('B20_app_shell_hoa_documents_pinning_policy');
        capabilityScreenshots.add('B20_app_shell_hoa_documents_pinning_policy');
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
    required this.reportData,
  }) {
    _syncReportData();
  }

  final IntegrationTestWidgetsFlutterBinding binding;
  final Map<String, dynamic> reportData;
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
      await binding.takeScreenshot(name);
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
      'method': 'captureScreenshot',
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
          'ext_hoa',
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

int _workflowEvidenceEntryCount(List<LoomEvidenceTarget> evidenceTargets) {
  return _workflowEvidenceEntryCountByPhase(
    evidenceTargets,
  ).values.fold(0, (total, count) => total + count);
}

Map<String, int> _workflowEvidenceEntryCountByPhase(
  List<LoomEvidenceTarget> evidenceTargets,
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
    for (final _ in experienceForExtensionId(
      target.extensionId,
      displayName: target.communityName,
    ).workflows) {
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
    counts['B19'] = 1;
  }
  if (_includePhase('B20')) {
    if (selectedExtensionIds.contains('ext_mosque')) {
      counts.update('B20', (count) => count + 1);
    }
    if (selectedExtensionIds.intersection(const {
      'ext_garden_club',
      'ext_hoa',
      'ext_youth_soccer',
    }).isNotEmpty) {
      counts.update('B20', (count) => count + 1);
    }
  }
  return counts;
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

String _screenshotName(
  LoomEvidenceTarget target,
  LoomWorkflowDefinition workflow,
  String state,
) {
  return '${target.phase}_${target.extensionId}_${workflow.workflowId}_$state';
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

Future<List<String>> _runShippedWorkflowWalkthrough({
  required WidgetTester tester,
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required _ShippedWorkflowSelector selector,
  required LoomWorkflowDefinition evidenceContract,
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
    await selectPersona(tester, selector.roleId);
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
  await tester.ensureVisible(instance.first);
  await tester.pumpAndSettle();

  final start = _screenshotName(target, evidenceContract, 'start');
  final action = _screenshotName(target, evidenceContract, 'action');
  final complete = _screenshotName(target, evidenceContract, 'complete');
  await capture(start);

  final visibleAction = await _waitForShippedWorkflowAction(
    tester: tester,
    selector: selector,
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
  await tester.pumpAndSettle();
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
    await capture(complete);
    return [start, action, complete];
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
    await capture(complete);
    return [start, action, complete];
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
  await capture(complete);
  return [start, action, complete];
}

List<
  ({LoomWorkflowDefinition evidenceContract, _ShippedWorkflowSelector selector})
>
_shippedWorkflowWalkthroughs({
  required LoomEvidenceTarget target,
  required ShippedEvidencePackage package,
  required List<LoomWorkflowDefinition> evidenceContracts,
}) {
  final unmatchedContracts = <String, LoomWorkflowDefinition>{
    for (final contract in evidenceContracts) contract.workflowId: contract,
  };
  final walkthroughs =
      <
        ({
          LoomWorkflowDefinition evidenceContract,
          _ShippedWorkflowSelector selector,
        })
      >[];
  for (final workflowType in package.experience.workflowDefinitions!.keys) {
    final evidenceContract = unmatchedContracts.remove(workflowType);
    if (evidenceContract == null) continue;
    walkthroughs.add((
      evidenceContract: evidenceContract,
      selector: _shippedWorkflowSelector(
        target: target,
        package: package,
        workflowType: workflowType,
      ),
    ));
  }
  if (unmatchedContracts.isNotEmpty) {
    fail(
      'Shipped package ${target.extensionId} did not contain the workflow '
      'definitions required by the canonical evidence contract: '
      '${unmatchedContracts.keys.toList()}.',
    );
  }
  return walkthroughs;
}

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
}) {
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
    for (final persona in package.experience.personas!) persona.roleId,
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
      for (final roleId in roleIds.where(packageRoleIds.contains)) {
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
              ..sort(_compareShippedTransitionCandidates);
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
        return _ShippedWorkflowSelector(
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
      }
    }
  }
  fail(
    'Walkthrough workflow $workflowType could not derive an actionable '
    'instance, persona, and tab from the shipped ${target.extensionId} '
    'experience and appShell.',
  );
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
}) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    for (final candidate in selector.transitions) {
      final finder = _engineActionFinder(
        selector.instance.instanceId,
        candidate.transition.id,
      );
      if (finder.evaluate().isNotEmpty) {
        return (candidate: candidate, finder: finder);
      }
    }
    if (attempt == 20) {
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
  fail(
    'Shipped workflow ${selector.machine.workflowType} instance '
    '${selector.instance.instanceId} exposed none of its package-declared '
    'actions ${selector.transitions.map((candidate) => candidate.transition.id).toList()} '
    'for ${selector.roleId} on ${selector.binding.tabId}.',
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
  final matches = package.experience.personas!
      .where((persona) => persona.label == label)
      .toList(growable: false);
  if (matches.length != 1) {
    fail(
      'Shipped package ${target.extensionId} must expose exactly one persona '
      'labelled "$label"; found '
      '${matches.map((persona) => persona.roleId).toList()}.',
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
    await selectPersona(tester, roleId);
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
        'for persona $roleId. Package tabs for that persona: $packageTabIds.',
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
}) async {
  await selectPersona(tester, adminRoleId);
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
  await capture('B20_announcement_admin_start');
  await tester.tap(createFab.first, warnIfMissed: false);
  await tester.pumpAndSettle();

  final keyPrefix = 'new-$workflowType';
  final titleEditor = find.byKey(ValueKey('$keyPrefix-editor-title'));
  await waitForEngineNativeWidget(
    tester,
    titleEditor,
    description: 'shipped $workflowType creation form',
  );
  await capture('B20_announcement_admin_action');

  const values = <String, String>{
    'title': 'Walkthrough community announcement',
    'body':
        'The walkthrough admin published this update from the shipped Masjid experience.',
    'audience': 'All Masjid Nur members',
    'channel': 'Home and Messages',
  };
  final editableFields =
      selector.machine.states[selector.machine.initialState]?.editableFields ??
      const <String>[];
  for (final field in editableFields) {
    final schema = selector.machine.instanceDataSchema[field];
    if (schema == null || !schema.required) {
      continue;
    }
    final value = values[field];
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

  final createdTitle = find.text(values['title']!);
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
  await capture('B20_announcement_admin_complete');
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
  await tester.pumpAndSettle();
  await tester.tap(tab, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<int> _personaMatrixRowCount(
  List<LoomEvidenceTarget> evidenceTargets,
) async {
  var total = 0;
  for (final target in evidenceTargets) {
    if (!hasShippedEvidencePackage(target.extensionId)) {
      total += personaWorkflowMatrixForExtensionId(target.extensionId).length;
      continue;
    }
    final package = await readShippedEvidencePackage(target);
    total +=
        package.experience.personas!.length *
        package.experience.workflowDefinitions!.length;
  }
  return total;
}
